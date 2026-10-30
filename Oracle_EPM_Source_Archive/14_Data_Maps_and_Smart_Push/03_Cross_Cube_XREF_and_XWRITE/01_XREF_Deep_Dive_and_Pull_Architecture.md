# 01 @XREF Deep Dive, Location Aliases, and Pull Architecture

## 1. The `@XREF` Pull Mechanism

The `@XREF` function is Essbase's native, legacy calculation script function designed to retrieve (pull) a numeric data value from a remote database (cube) into the currently executing calculation context.

```
+---------------------------------------------------------------------------------------------------+
|                                      @XREF PULL ARCHITECTURE                                      |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  LOCAL APPLICATION (CUBE A - BSO)                  REMOTE APPLICATION (CUBE B - BSO/ASO)          |
|  Executing Calculation Script:                      Target Data Source:                            |
|                                                                                                   |
|  FIX("Actual", "FY24", "Jan")                                                                     |
|    "Sales_Revenue" =                                                                              |
|      @XREF(SalesApp, "Total_Units") * 10;                                                         |
|  ENDFIX                                                                                           |
|         |                                                        |                                |
|         | 1. Evaluates Cell coordinate                           |                                |
|         | 2. Identifies Location Alias: SalesApp                 |                                |
|         |                                                        |                                |
|         | 3. TCP Socket Connection / Essbase Agent Protocol      |                                |
|         +------------------------------------------------------->|                                |
|                                                                  | 4. Remote Lookup:              |
|                                                                  |    Locates block & cell        |
|                                                                  |    for "Total_Units"           |
|                                                                  |                                |
|         | 5. Return Value: 500.00 via Network Stream             |                                |
|         |<-------------------------------------------------------+                                |
|         |                                                                                         |
|         | 6. Compute: 500.00 * 10 = 5,000.00                                                      |
|         v 7. Store in Local Block (Sales_Revenue)                                                 |
|  [Local BSO Block Updated]                                                                        |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Syntax, Parameters, and Location Aliases

### 2.1 Function Signature
```sql
@XREF ( LocationAlias [, MemberList ] )
```

| Parameter | Type | Required? | Description |
| :--- | :--- | :--- | :--- |
| `LocationAlias` | Identifier | **Yes** | A predefined connection descriptor configured in Essbase that resolves the remote server, application, database, and authentication token. |
| `MemberList` | Member List | No | Optional comma-separated list of member names corresponding to dimensions in the remote cube that differ from the current local context. |

### 2.2 Location Alias Configuration
Before `@XREF` can be invoked, an administrator must create a **Location Alias** via EAS, MaxL, or EPM Cloud Calculation Manager Database Properties:
```sql
create or replace location alias 'SalesApp' 
  on server 'epm_remote_host' 
  app 'Sales' 
  database 'SalesData' 
  as user 'service_account' 
  identified by 'Encrypted_Password';
```

### 2.3 Context Inheritance Rules
* If a dimension exists in both local and remote cubes and is **omitted** from `MemberList`, `@XREF` automatically passes the **current member of that dimension** (`@CURRMBR`) to the remote cube.
* If a dimension exists in the remote cube but **does not exist** in the local cube, it **must** be explicitly defined in `MemberList`; otherwise, the query fails with: `Essbase Error: Missing member for dimension [DimName]`.

---

## 3. Dynamic Calc vs. Stored Batch Execution

One of the most dangerous design patterns in Hyperion/EPM history is embedding `@XREF` inside a **Dynamic Calc member formula**.

### 3.1 Why `@XREF` in Dynamic Calc is Toxic
When `@XREF` is placed inside a member formula tagged as **Dynamic Calc**:
1. Every time a user opens a web form, retrieves data in Smart View, or runs a Financial Report, the formula triggers for every visible cell.
2. For a simple grid displaying 50 rows and 12 columns (600 cells), the client initiates **600 distinct remote TCP network queries**.
3. Essbase cannot batch dynamic calculations across network sockets.
4. Result: Forms freeze for 30–90 seconds; concurrent users crash the Essbase network listener thread pool.

```
Smart View Retrieve (600 cells)
   |--> Cell 1  ===> Network Socket Open ===> Remote Query ===> Close Socket (40ms)
   |--> Cell 2  ===> Network Socket Open ===> Remote Query ===> Close Socket (40ms)
   |--> ...
   |--> Cell 600 ===> Network Socket Open ===> Remote Query ===> Close Socket (40ms)
TOTAL RETRIEVAL DURATION = 600 * 40ms = 24,000ms (24 SECONDS!)
```

### 3.2 Stored Batch Script Execution (Best Practice if `@XREF` is unavoidable)
If `@XREF` must be used, restrict it to an overnight batch calculation script focused exclusively on Level 0 blocks:
```sql
SET CACHE HIGH;
SET LOCKBLOCK HIGH;
SET MSG SUMMARY;

/* Fix only on existing sparse blocks to prevent empty block creation */
FIX("Actual", "FY24", "Final", @LEVMBRS("Entity", 0))
  FIX(@LEVMBRS("Product", 0))
    "External_Revenue" (
      "External_Revenue" = @XREF(SalesApp, "Gross_Sales", "Total_Cust");
    )
  ENDFIX
ENDFIX
```

---

## 4. Block Creation and Performance Hazards

1. **Failure to Create Target Blocks**: When pulling data via `@XREF` into a sparse intersection, if the local sparse block does not already exist, Essbase will **not** create the block unless:
   * The formula is written on a dense member within an existing block, OR
   * `SET CREATEBLOCKONEQ ON;` is declared before the calculation block.
2. **Exponential Dense Block Overhead**: If `SET CREATEBLOCKONEQ ON;` is enabled and the calculation FIX statement is too broad, Essbase will allocate millions of empty 100KB blocks in the local `.pag` file, causing immediate database size explosion.

