# 02 Field Mapping Topologies, Unmapped Dimensions, and Exclusion Logic

## 1. Dimensional Alignment Architectures

In multi-cube enterprise applications, dimensional structures between source and target cubes rarely match identically. Source cubes (e.g., Financials BSO, Workforce BSO, Projects BSO) frequently contain detailed operational granularity (Employee, Job Code, Project Task, Line Item Detail) that does not exist in target reporting or consolidation cubes (e.g., OEP_REP ASO, Reporting BSO). Conversely, reporting cubes often contain reporting-only dimensions (View, Currency, Reporting Unit) not tracked in operational models.

Data Maps solve these architectural discrepancies through four core mapping topologies:

```
+---------------------------------------------------------------------------------------------------+
|                                  DATA MAP DIMENSION TOPOLOGIES                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [1. Exact 1:1 Identity]           [2. Many-to-One Rollup]        [3. Unmapped Source Dim]        |
|  Source Dim ===> Target Dim        Source Dim ===> Target Dim     Source Dim ===> [DROPPED]       |
|  (Account   ===> Account)          (Dept_001..100 => Total_Dept)  (Source filtered to 1 member)  |
|                                                                                                   |
|  [4. Unmapped Target Dim]          [5. Cross-Dimension Mapping]   [6. Exclusion Filtering]        |
|  [FIXED MBR] ===> Target Dim       Source Dim A => Target Dim B   Include Descendants(Total_Exp)  |
|  ("Periodic" ===> View)            (Entity      => Cost_Center)   EXCLUDE Descendants(Stat_Exp)   |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Deep Dive: The 4 Primary Topologies

### Topology 1: Exact 1:1 Identity Mapping
* **Description**: The dimension exists in both source and target cubes with identical or largely overlapping member names.
* **Mechanism**: The data map extracts member tuples from the source cube and streams them directly into the target cube without dimensional re-indexing.
* **Member Selection Options**:
  * `Level 0 Descendants`: All base leaf members.
  * `Descendants / IDescendants`: Entire subtrees (if intermediate summary blocks exist and are needed).
  * `Children / IChildren`: Immediate hierarchy members.
  * `Member`: Individual explicit members.
* **Best Practice**: In ASO target cubes, **always map Level 0 descendants**. Pushing parent summary levels into an ASO target causes double-counting because ASO aggregates all upper levels on the fly at query time.

### Topology 2: Unmapped Source Dimensions (Dimensional Collapse)
* **Problem**: The Source cube has a dimension (e.g., `Plan Element` or `Project Task`) that does NOT exist in the Target reporting cube.
* **Failure Mode**: If unmapped source dimensions are left open without specifying a single source member, the extract would attempt to pump data from multiple source members into the identical target coordinate, causing collisions, overwrites, or multiplication errors.
* **Resolution**: The Data Map configuration forces the architect to select **one single member** from the source dimension (typically the top-level parent `Total Plan Element` or a specific base member `Final Output`).
* **Rule**:
  $$\text{Target Coordinate} = \sum(\text{Source Dimension Selected Member})$$
  Only data residing on the specified source member is extracted and pushed.

### Topology 3: Unmapped Target Dimensions (Dimensional Expansion)
* **Problem**: The Target cube has a dimension (e.g., `View` or `Currency`) that does NOT exist in the Source cube.
* **Failure Mode**: The target cube cannot write a data cell without having a valid coordinate for every single one of its dimensions.
* **Resolution**: The Data Map requires specifying a **fixed target member** for the missing dimension (e.g., `Periodic` for the View dimension, or `Local Currency` / `USD` for the Currency dimension).
* **Rule**: Every data tuple flowing from the source has the designated fixed target member appended to its target address coordinate.

### Topology 4: Many-to-One Dimension Mapping
* **Problem**: Source data contains granular entities or departments that must map into a consolidated parent or single default member in the target.
* **Resolution**: Map a source selection query (e.g., `ILvl0Descendants(Headquarters)`) directly to a single target member (`Corporate_Admin`).
* **Warning on Multiple Slices**: If multiple source cells map to the exact same target cell in a single batch, the load buffer behavior determines whether they **overwrite** or **accumulate**:
  * For ASO targets: `EssWriteLoadBuffer` can be configured to **Add Duplicate Cells** (summing the inputs) or **Ignore / Overwrite**. By default, EPM Data Maps sum duplicate inputs when loading into ASO.

---

## 3. Exclusion Logic and Hierarchy Slicing

Data Maps provide advanced filtering logic to eliminate unwanted members from the extracted slice, preventing unnecessary data movements, reducing network traffic, and protecting calculated targets.

### 3.1 Exclusion Syntax and Precedence
Exclusions always operate as a subtraction set from the parent inclusion set:

$$\text{Final Extract Set} = \text{Inclusion Query} \setminus \text{Exclusion Query}$$

```
+-------------------------------------------------------------+
| INCLUSION: IDescendants(Total_Operating_Expenses)           |
|   |-- Rent_Expense                                          |
|   |-- Utilities_Expense                                     |
|   |-- Salaries_Expense                                      |
|   |-- Depreciation_Expense <------------------+             |
|   |-- Amortization_Expense <----------------+ |             |
+---------------------------------------------|-|-------------+
                                              | |
+---------------------------------------------|-|-------------+
| EXCLUSION: IDescendants(Non_Cash_Expenses) -+ |             |
|   (Depreciation_Expense, Amortization_Expense)              |
+-------------------------------------------------------------+
                                              |
                                              v
+-------------------------------------------------------------+
| RESULTING DATA PUSH SLICE:                                  |
|   Rent_Expense, Utilities_Expense, Salaries_Expense         |
+-------------------------------------------------------------+
```

### 3.2 Common Production Exclusion Scenarios

| Business Scenario | Inclusion Query | Exclusion Query | Architectural Justification |
| :--- | :--- | :--- | :--- |
| **Statistical Account Exclusion** | `IDescendants(Total_Accounts)` | `IDescendants(Statistical_Accounts)` | Non-financial headcount and statistical metrics do not use financial currency conversion rules in the target. |
| **Elimination Entity Exclusion** | `IDescendants(Total_Geography)` | `IDescendants(Intercompany_Eliminations)` | Eliminations are dynamically calculated in FCCS or target reporting cubes; pushing raw inputs causes balance sheet imbalances. |
| **Historical Year Lockout** | `Years: FY20:FY26` | `Years: FY20:FY23` | Prevents accidental modification or overwrite of closed/audited prior period actuals in the target cube. |
| **System Calculation Accounts** | `IDescendants(Net_Income)` | `UDA(Account, "NoPush")` | Custom User Defined Attribute (UDA) dynamically tags calculated members that must remain untouched. |

---

## 4. Rollup on Target Cube Configuration

When pushing data from a detailed BSO cube into a target cube, upper-level summary blocks on the target may become out of sync with newly ingested leaf data.

### 4.1 Target Cube is ASO
* ASO cubes do not store upper-level aggregations unless pre-calculated aggregation views are built.
* If **Aggregate Data on Target** is enabled:
  * EPM Cloud automatically executes an **Incremental View Update** (`alter database [App].[Cube] aggregate views...`) on the target ASO cube immediately after committing the load buffer slice.
  * This ensures queries against upper-level parents on reporting dashboards return instantaneous, pre-aggregated values without query-time decompression lag.

### 4.2 Target Cube is BSO
* If target is BSO and **Aggregate Data on Target** is selected:
  * The platform executes a targeted internal calculation script:
    ```sql
    SET AGGSPARSESEL ON;
    CALC DIM(Entity, Department, Project);
    ```
  * Note: Aggregating large sparse dimensions on a BSO target during a Smart Push triggered by a form save will degrade user experience by causing save delays (e.g., 10–30 second freezes). Keep BSO target aggregation disabled for real-time Smart Push, scheduling it instead via nightly batch scripts.

---

## 5. Implementation Rules and Pitfalls

1. **Dynamic Calc Target Rule**: Never map data into a target member whose data storage property is set to **Dynamic Calc** or **Dynamic Calc and Store**. The Essbase ingestion engine will reject the record and throw a `Cannot write to dynamic member` fatal error.
2. **Missing Level 0 Qualification**: If an inclusion selection uses `Descendants(Total_Entity)`, both parent entities and leaf entities are extracted. When pushed to an ASO cube where upper levels calculate dynamically, the values will be double-counted. **Always enforce `Level 0 Descendants` for ASO destinations**.
3. **Data Type Mismatches**: Mapping Smart List text accounts from a BSO source to a standard numeric account in an ASO target without corresponding Smart List association will result in integer IDs (e.g., `100012`) being loaded as numeric dollar amounts.

