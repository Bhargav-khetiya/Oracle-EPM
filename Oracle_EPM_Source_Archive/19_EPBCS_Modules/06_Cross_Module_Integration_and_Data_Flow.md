# 06 Cross-Module Integration, Data Maps, and Multi-Cube Orchestration

## 1. The Multi-Cube Enterprise Mesh Architecture

Oracle Enterprise Planning and Budgeting Cloud Service (EPBCS) achieves superior scalability by decomposing complex enterprise operations into **specialized, dedicated multidimensional cubes**. Rather than building a single monolithic, slow-calculating cube with 25 dimensions, EPBCS establishes a federated **Multi-Cube Mesh**:

```
+===================================================================================================+
|                                    EPBCS MULTI-CUBE ARCHITECTURE                                  |
+===================================================================================================+
|                                                                                                   |
|  +---------------------------+                         +----------------------------+             |
|  |     WORKFORCE (OEP_WFP)   |                         |      CAPITAL (OEP_CPX)     |             |
|  | Engine: BSO / Hybrid      |                         | Engine: BSO / Hybrid       |             |
|  | Dimensions: 10-12         |                         | Dimensions: 8-10           |             |
|  | (Employee, Job, Property) |                         | (Asset Class, Detail)      |             |
|  +---------------------------+                         +----------------------------+             |
|         |                  \                                 /                   |                |
|         |                   \ Employee Hourly Rates         / Capitalize CIP     |                |
|         |                    \                             /  Projects           |                |
|         |                     v                           v                      |                |
|         |                  +---------------------------------+                   |                |
|         |                  |        PROJECTS (OEP_PFP)       |                   |                |
|         |                  | Engine: BSO / Hybrid            |                   |                |
|         |                  | Dimensions: 9-11                |                   |                |
|         |                  | (Project, Element, Resource)    |                   |                |
|         |                  +---------------------------------+                   |                |
|         |                                   |                                    |                |
|         | Summary Payroll                   | Project Billing &                  | Asset Additions|
|         | & Benefits P&L                    | Operating Costs                    | & Depreciation |
|         v                                   v                                    v                |
|  +---------------------------------------------------------------------------------------------+  |
|  |                                  FINANCIALS CORE (OEP_FS)                                   |  |
|  | Engine: BSO / Hybrid                                                                        |  |
|  | Dimensions: 7-9 (Account, Entity, Period, Year, Scenario, Version, Currency, Plan Element)  |  |
|  | - Complete Income Statement (P&L)                                                           |  |
|  | - Comprehensive Balance Sheet                                                               |  |
|  | - Automated Cash Flow Statement                                                             |  |
|  +---------------------------------------------------------------------------------------------+  |
|         |                                                                           ^             |
|         | Push All Financial Data (Smart Push / Data Map)                           |             |
|         v                                                                           | Top-Down    |
|  +---------------------------+                         +----------------------------+             |
|  |      REPORTING (OEP_REP)  |                         |  STRATEGIC MODELING (HSF)  |             |
|  | Engine: ASO Kernel        |                         | Engine: Financial Model    |             |
|  | Dimensions: 13-16         |                         | - Long-Range 10-Yr Vision  |             |
|  | (High-Speed Aggregations) |                         | - Simultaneous Equations   |             |
|  +---------------------------+                         +----------------------------+             |
|                                                                                                   |
+===================================================================================================+
```

---

## 2. Exhaustive Seeded Data Maps Catalog

When modules are configured in EPBCS, Oracle automatically populates the relational repository with optimized, pre-mapped **Data Maps**:

| Data Map Name | Source Cube | Target Cube | Dimensional Mapping & Transformation Rules |
| :--- | :---: | :---: | :--- |
| **`Compensation to Financials`** | `OEP_WFP` | `OEP_FS` | Extracts Level 0 employees and jobs; drops `Employee` and `Job` dimensions; maps detailed payroll accounts to Financials SG&A (`OFS_Salaries`, `OFS_Bonus`, `OFS_Fringe_Benefits`, `OFS_Payroll_Taxes`) into `OFS_Calculated` in the `Plan Element` dimension. |
| **`Capital to Financials`** | `OEP_CPX` | `OEP_FS` | Drops `Asset Class` and `Asset Detail` dimensions; maps new capital additions to `14000_PP&E` (Balance Sheet), monthly depreciation to `61000_Depreciation_Expense` (P&L), and Capex cash outflows to Cash Flow. |
| **`Projects to Financials`** | `OEP_PFP` | `OEP_FS` | Drops `Project`, `Project Element`, and `Resource` dimensions; pushes billable client contract revenue to `41000_Service_Revenue` and direct internal project costs to operational expense lines. |
| **`Projects to Capital`** | `OEP_PFP` | `OEP_CPX` | Evaluates completed Capital Projects; capitalizes accumulated labor, material, and contractor costs into newly initialized Asset Details under designated Asset Classes in `OEP_CPX`. |
| **`Workforce to Projects`** | `OEP_WFP` | `OEP_PFP` | Pushes loaded employee hourly cost rates from Workforce into standard Projects labor rate matrices. |
| **`Financial to Reporting`** | `OEP_FS` | `OEP_REP` | Pushes all calculated BSO financial data to the high-speed Aggregate Storage Option (ASO) reporting cube for instant executive querying. |

---

## 3. Execution Topologies: Smart Push vs. Batch vs. Groovy Data Mover

Enterprise architects configure cross-module data movement using three distinct mechanisms depending on latency requirements:

```
+---------------------------------------------------------------------------------------------------+
|                               DATA SYNCHRONIZATION COMPARISON MATRIX                              |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  1. SMART PUSH (REAL-TIME ON WEB FORM SAVE)                                                       |
|     - Latency: Sub-second (100ms - 1.5s).                                                         |
|     - Scope: Micro-Slice constrained strictly to the active user's form context.                  |
|     - Configuration: Form Designer -> Smart Push tab -> Check "Run on Save" & "Use Form Context". |
|     - User Impact: Completely seamless; target cube reflects changes immediately upon save.       |
|                                                                                                   |
|  2. BATCH DATA MAPS (SCHEDULED NIGHTLY JOBS VIA EPM AUTOMATE)                                     |
|     - Latency: Minutes (15s - 10 minutes).                                                        |
|     - Scope: Macro-Slice across all entities, all years, and all scenarios.                       |
|     - Configuration: Application -> Data Maps -> Select Data Map -> Actions -> Push Data.         |
|     - User Impact: Executed during batch maintenance windows; avoids daytime resource contention. |
|                                                                                                   |
|  3. GROOVY EPM DATA MOVER (PROGRAMMATIC RUNTIME EXECUTION)                                        |
|     - Latency: Milliseconds to seconds.                                                           |
|     - Scope: Fully programmatic dynamic slicing based on edited grid rows or business conditions. |
|     - Configuration: Groovy Calculation Rule invoking EPM Data Mover API.                         |
|     - Capability: Allows custom conditional mappings, data transformations, and validation vetoes.|
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

### 3.1 Groovy EPM Data Mover API Code Pattern

```groovy
/* Groovy Rule: Dynamic Form-Context Data Map Execution with Override */
Cube sourceCube = operation.application.getCube("OEP_WFP")
Cube targetCube = operation.application.getCube("OEP_FS")

// Retrieve the seeded Data Map
DataMap compensationMap = operation.application.getDataMap("Compensation to Financials")

// Capture edited entities dynamically from the web form grid
Set<String> editedEntities = []
operation.grid.dataCellIterator({ DataCell cell -> cell.isEdited() }).each { cell ->
    editedEntities.add(cell.getMemberName("Entity"))
}

// Build dynamic override map targeting ONLY modified entities
if (!editedEntities.isEmpty()) {
    Map<String, String> overrideMap = [
        "Entity": editedEntities.join(",")
    ]
    
    // Execute data movement with dynamic micro-slice
    compensationMap.execute(overrideMap)
    println("Successfully pushed ${editedEntities.size()} entities from Workforce to Financials.")
}
```

---

## 4. Concurrency, Locking, and Collision Detection

When dozens of financial planners execute cross-module data pushes simultaneously, the architecture manages concurrency through strict isolation protocols:

```
+===================================================================================================+
|                              CROSS-MODULE CONCURRENCY PROTOCOLS                                   |
+===================================================================================================+
|                                                                                                   |
|  SCENARIO: User A and User B save forms simultaneously pushing to OEP_FS                          |
|                                                                                                   |
|  CASE 1: DIFFERENT ENTITIES (NON-OVERLAPPING COORDINATES)                                         |
|  - User A saves Entity 1001 (Sales East).                                                         |
|  - User B saves Entity 2002 (Marketing West).                                                     |
|  - Essbase BSO Engine: Allocates separate 64KB memory blocks in OEP_FS.                            |
|  - Result: ZERO contention. Both writes commit concurrently in parallel threads!                  |
|                                                                                                   |
|  CASE 2: IDENTICAL ENTITY (OVERLAPPING COORDINATE CONTENTION)                                     |
|  - User A and User B edit different line items within Entity 1001 simultaneously.                 |
|  - Essbase Block Lock: The first transaction to acquire the page lock updates the block.          |
|  - The second transaction waits briefly (Block Lock Timeout, typically 15 seconds).               |
|  - If "Use Form Context" is checked: Updates touch distinct cells without overwriting each other. |
|                                                                                                   |
|  CASE 3: PUSHING TO REPORTING CUBE (ASO LOAD BUFFER CONCURRENCY)                                  |
|  - When pushing to OEP_REP (ASO), the Essbase kernel assigns distinct Buffer IDs (e.g., 101, 102).|
|  - Both buffers write to isolated incremental slice files (slice_0004.dat, slice_0005.dat).       |
|  - Result: Absolute zero-locking concurrency! Neither user waits.                                 |
|                                                                                                   |
+===================================================================================================+
```

---

## 5. Preventing Enterprise Double-Counting: The Offset Accounting Framework

The most dangerous pitfall in multi-module implementations is **redundant cost or revenue counting**. EPBCS prevents this through pre-built **Contra-Accounts and Offset Frameworks**:

### 5.1 Project Labor Double-Counting Prevention
* **The Risk**: 
  1. An employee's full salary ($\$120,000$) is budgeted in **Workforce (`OEP_WFP`)** and pushed to Financials under `OFS_Salaries`.
  2. The same employee logs 800 hours on a contract project in **Projects (`OEP_PFP`)**, generating $\$60,000$ of project labor expense pushed to Financials.
  3. Total SG&A would mistakenly report $\$180,000$ ($\$60,000$ overstated!).
* **The Solution**: 
  The seeded data map posts a negative credit of $\$60,000$ to **`OFS_Project_Payroll_Offset`** (contra-expense account) in Financials:
  $$\text{Net P\&L Expense} = \$120,000 \text{ (Workforce)} + \$60,000 \text{ (Projects)} - \$60,000 \text{ (Offset)} = \mathbf{\$120,000.00}$$

### 5.2 Capital Project CIP Capitalization Offset
* **The Risk**:
  During construction, capital project costs accumulate in Projects. If pushed directly to operating expenses, they would improperly decrease current-year Net Income.
* **The Solution**:
  Capital project costs are flagged under `Capital CIP` and pushed directly to Balance Sheet `Construction in Progress` accounts in `OEP_CPX`, bypassing the Income Statement entirely until placed in service.

---

## 6. End-to-End Orchestrated Batch Runbook

During month-end close or annual budget rollups, administrators execute an orchestrated sequence via headless **EPM Automate** scripts:

```powershell
# ==============================================================================
# ENTERPRISE ORCHESTRATION RUNBOOK: MULTI-MODULE ROLLUP SEQUENCE
# ==============================================================================

# 1. Execute Workforce Calculations & Push to Financials
epmautomate runBusinessRule "Calculate Compensation"
epmautomate runDataMap "Compensation to Financials"

# 2. Execute Capital Depreciation & Push to Financials
epmautomate runBusinessRule "Calculate Depreciation"
epmautomate runDataMap "Capital to Financials"

# 3. Execute Projects Cost/Revenue Calculations & Cross-Pushes
epmautomate runBusinessRule "Calculate Project Costs"
epmautomate runBusinessRule "Calculate Project Revenue"
epmautomate runDataMap "Projects to Financials"
epmautomate runDataMap "Projects to Capital"

# 4. Final Financials Consolidation & Reporting Aggregation
epmautomate runBusinessRule "Rollup Financials"
epmautomate runDataMap "Financial to Reporting"

# 5. Execute ASO Slice Merge (Maintain Reporting Performance)
epmautomate mergeDataSlices "OEP_REP"
```

---

## 7. Top 10 Twisted Review & Interview Questions on Cross-Module Integration

### Q1: What is the single biggest performance risk when enabling Smart Push on a high-traffic web form?
**Answer**: Failing to check **"Use Form Context"**. When "Use Form Context" is omitted, Smart Push extracts and transfers the **entire dimensional scope** of the underlying Data Map (all entities, all years, all accounts) on every single form save! If 20 users click save, 20 massive macro-slice jobs spawn simultaneously, exhausting memory and hanging the application server. Always verify "Use Form Context" is checked.

### Q2: Why does EPBCS utilize separate BSO cubes for Workforce, Capital, and Projects rather than combining them into one single cube?
**Answer**: Dimensionality isolation and performance optimization. Workforce requires `Employee` and `Job`; Capital requires `Asset Class` and `Asset Detail`; Projects requires `Project`, `Project Element`, and `Resource`. If combined into a single cube, the cube would have 16–18 dimensions, creating massive sparsity, gigantic index files, slow block calculations, and catastrophic performance degradation. Isolating them into dedicated cubes keeps each cube compact and fast.

### Q3: How do you resolve the error: "Essbase Error: Target member not found" during a Data Map execution?
**Answer**: This error occurs when a metadata member exists in the source cube but is missing, renamed, or tagged as inactive/dynamic in the target cube. 
**Remediation**:
1. Check the Job Console details to identify the missing member name.
2. Add the member to the target cube's dimension or update member mapping in the Data Map interface.
3. Refresh the database (**Application -> Overview -> Actions -> Refresh Database**) and re-run the Data Map.

### Q4: Can a Data Map push data from an ASO cube to a BSO cube?
**Answer**: **Yes**. Data Maps support bidirectional movement: BSO to BSO, BSO to ASO, and ASO to BSO. However, pushing from ASO to BSO requires careful scoping (extracting only Level 0 data) because ASO does not store calculated formula logic that BSO blocks expect.

### Q5: What happens if two different Data Maps write to the same intersection in `OEP_FS`?
**Answer**: The outcome depends on the order of execution. If both write to the exact same cell, the second Data Map execution will **overwrite** the value written by the first. To preserve both, they must be mapped to distinct accounts or distinct members in the `Plan Element` dimension (e.g., `OFS_From_Workforce` vs `OFS_From_Projects`).

### Q6: What is the purpose of the `Plan Element` dimension in `OEP_FS`?
**Answer**: The `Plan Element` dimension tracks data provenance and calculation lineage in Financials:
* `OFS_Direct_Input`: Data keyed directly by financial analysts.
* `OFS_Calculated`: Data generated by internal BSO financial business rules.
* `OFS_From_Workforce`: Data pushed automatically from the Workforce module.
* `OFS_From_Capital`: Data pushed automatically from the Capital module.
* `OFS_From_Projects`: Data pushed automatically from the Projects module.
This segregation prevents automated module pushes from overwriting manual journal adjustments.

### Q7: How does Groovy EPM Data Mover outperform standard Smart Push in complex workflows?
**Answer**: Standard Smart Push only passes the active web form's grid coordinates. Groovy's EPM Data Mover API allows full programmatic control:
1. Dynamically filters only cells that were edited using `cell.isEdited()`.
2. Validates business data before pushing, throwing user-friendly `VetoExceptions` if numbers fail sanity checks.
3. Dynamically overrides target dimension mappings based on runtime conditions.

### Q8: What is the difference between "Push Data" and "Clear Data" in the Data Map interface?
**Answer**:
* **Push Data**: Extracts data from the source cube and writes/merges it into the target cube.
* **Clear Data**: Clears the corresponding target intersection prior to loading, ensuring that historical records or deleted lines in the source are not left as "ghost numbers" in the target cube.

### Q9: Why is ASO Slice Merging required after running frequent Data Maps to `OEP_REP`?
**Answer**: Every execution of a Data Map or Smart Push targeting an ASO cube creates a new incremental `.dat` storage slice on disk. While writing slices is instantaneous, queries against ASO must scan the B-tree indices of every active slice. If slices accumulate beyond 25–30, query latency degrades sharply. Merging slices combines incremental files into the main slice, restoring sub-second reporting speeds.

### Q10: How do you troubleshoot a Data Map that completes with status "Completed with Warnings"?
**Answer**:
1. Navigate to **Application -> Jobs** and click on the failed job.
2. Download the **Job Details / Error Log**.
3. Inspect unmapped member coordinates (e.g., source cost center missing in target hierarchy).
4. Correct the dimensional mapping or synchronize metadata across cubes, then re-execute.
