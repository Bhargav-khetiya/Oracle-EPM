# 02 @XWRITE Deep Dive, Push Mechanics, and Target Cube Locking

## 1. The `@XWRITE` Push Mechanism

While `@XREF` pulls remote data into the local calculation context, `@XWRITE` reverses the flow: it evaluates an expression locally on the source cube and **pushes (writes)** the resulting value directly into a remote database.

```
+---------------------------------------------------------------------------------------------------+
|                                      @XWRITE PUSH ARCHITECTURE                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  LOCAL SOURCE CUBE (FINANCIALS BSO)                REMOTE TARGET CUBE (REPORTING BSO)             |
|  Executing Calculation Script:                      Target Storage Engine:                         |
|                                                                                                   |
|  FIX("Plan", "FY25", "Working", "Sales_East")                                                     |
|    "Operating_Profit" (                                                                           |
|      @XWRITE("Operating_Profitâ”‚                    1. Open Network Stream                        |
|              RepApp,             -----------------> 2. Acquire Write Lock on Target Block         |
|              "Periodicâ”‚                            3. Check if Target Block Exists:              |
|              "Local_Curr");                            - If YES: Decompress & Write Cell          |
|    )                                                   - If NO:  Allocate & Format New Block      |
|  ENDFIX                                             4. Commit Block to Target Disk Cache          |
|                                                     5. Release Target Lock                        |
|                                  <----------------- 6. Return Acknowledge / Status Code           |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Syntax and Parameter Specifications

### 2.1 Function Signature
```sql
@XWRITE ( Expression, LocationAlias [, MemberList ] )
```

| Parameter | Type | Required— | Description |
| :--- | :--- | :--- | :--- |
| `Expression` | Math / Member | **Yes** | A constant, member name, or complex mathematical formula evaluated on the source cube whose result will be transmitted. |
| `LocationAlias` | Identifier | **Yes** | Predefined connection descriptor resolving remote host, application, database, and credentials. |
| `MemberList` | Member List | No | Optional comma-separated target coordinates that override or supplement the source context. |

### 2.2 Production Calculation Example
```sql
SET UPDATECALC OFF;
SET LOCKBLOCK HIGH;

FIX("Forecast", "FY25", "Working", @RELATIVE("Total_Department", 0))
  FIX(@RELATIVE("Total_Accounts", 0))
    "Amount" (
      /* Calculate 5% inflation markup and push to Consolidation Cube */
      @XWRITE("Amount" * 1.05, ConsolApp, "Base_Data", "Input_Currency");
    )
  ENDFIX
ENDFIX
```

---

## 3. Remote Target Locking and Transaction Boundaries

The primary architectural flaw of `@XWRITE` in multi-user enterprise environments is its **lock acquisition behavior on the target cube**.

### 3.1 Lock Contention Mechanics
When the source calculation issues an `@XWRITE` command:
1. It sends a write request across the network to the remote Essbase kernel.
2. The remote Essbase kernel must locate the corresponding sparse block on the target database.
3. If the target block is currently locked by another process (e.g., an end-user entering data, a report running, or another calculation script), the `@XWRITE` operation enters a **Lock Wait state**.
4. By default, Essbase waits up to `LOCKWAIT` seconds (configured in `essbase.cfg`, typically 60 seconds).
5. If the lock is not released, the entire source calculation terminates with:
   `Essbase Error (1200525): Transaction aborted due to lock timeout on target database.`

### 3.2 Block Creation on Remote BSO Cubes
Unlike `@XREF` (which only reads), `@XWRITE` **creates new sparse blocks on the target BSO cube automatically** if the targeted sparse coordinate combination does not exist.
* **The Danger**: If the source calculation loops across sparse dimensions with dense members, `@XWRITE` will rapidly instantiate tens of thousands of empty blocks on the target cube.
* If multiple source threads execute `@XWRITE` simultaneously targeting the same remote cube, they cause severe **deadlocks** as threads fight to acquire allocation locks on the target cube's index file (`.ind`).

---

## 4. Failure Modes and Recovery

1. **Partial Pushes on Network Disruption**:
   * `@XWRITE` commits data in batches based on the source script's commit threshold (`SET COMMITROWS`).
   * If a network blip occurs after 50,000 cells have been written out of 100,000, the calculation aborts. The target database is left in a **corrupt, half-loaded state**, requiring a full recalculation or manual rollback.
2. **ASO Target Limitations**:
   * While `@XWRITE` can technically write to modern ASO cubes, it creates excessive overhead because each `@XWRITE` transaction creates an isolated load stream rather than utilizing bulk load buffers.
3. **Password Expiration / Rotation**:
   * Location aliases store encrypted passwords. When service account passwords expire or rotate in enterprise Identity Providers (IDCS/OCI IAM), all scripts utilizing the location alias fail simultaneously.

