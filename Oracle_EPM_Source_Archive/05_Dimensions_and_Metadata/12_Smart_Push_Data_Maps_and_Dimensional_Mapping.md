# 🔄 Dimension Properties — Smart Push, Data Maps & Dimensional Mapping Mechanics

> **Purpose**: This technical manual details the internal architectural mechanics of **Data Maps** and **Smart Push** in Oracle EPM Cloud, covering the physical data pipeline between BSO calculation cubes and ASO reporting cubes, dimensional mapping topologies, unmapped/excluded dimension resolution, and ASO load buffer memory management.

---

## 1. Architectural Role: Bridging BSO and ASO

In modern enterprise Oracle EPM implementations, applications typically deploy a **Hybrid Multi-Cube Architecture**:
- **BSO Input/Calculation Cubes** (e.g., `Oep_FS`, `Plan1`): Block storage engine with dense/sparse design, optimized for procedural calculations, allocations, and driver-based forecasting.
- **ASO Reporting Cubes** (e.g., `Oep_REP`, `FinRep`): Aggregate storage engine with dynamic rollups, bitmap indexing, and sub-second query performance for millions of sparse intersections across hundreds of users.

**Data Maps** provide the relational definition of how members map between cubes. **Smart Push** is the runtime engine that executes the physical data movement.

```
┌─────────────────────────────────┐                       ┌─────────────────────────────────┐
│     BSO SOURCE CUBE (Plan1)     │                       │     ASO TARGET CUBE (FinRep)    │
│  - Dense/Sparse Block Storage   │                       │  - Bitmap Slice Aggregate Engine│
│  - Procedural Calc Scripts      │                       │  - Fast MDX Reporting & Web     │
└────────────────┬────────────────┘                       └────────────────▲────────────────┘
                 │                                                         │
                 │ 1. Extract Slice (MDX / GridAPI)                        │ 4. Commit Load Buffer
                 ▼                                                         │
┌──────────────────────────────────────────────────────────────────────────┴────────────────┐
│                         EPM APPLICATION SERVER PIPELINE                                   │
│                                                                                           │
│   [Data Map Transformation Engine]                                                        │
│   ├── Maps Source Dimensions ──► Target Dimensions via HSP_MAP_DEF                        │
│   ├── Injects static defaults for Unmapped Target Dimensions (e.g. "No_Project")          │
│   └── Strips Excluded Source Dimensions (aggregates to specified parent)                  │
│                                                                                           │
│   [ASO Load Buffer Dispatcher]                                                            │
│   ├── EssASOInitLoadBuffer(targetCube, bufferId = 1)                                      │
│   ├── EssASOLoadBufferAddSlice(streamBuffer, duplicateAction = OVERWRITE)                 │
│   └── EssASOCommitLoadBuffer(bufferId = 1, aggregateImmediately = FALSE)                  │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Dimensional Mapping Topologies in Data Maps

When configuring a Data Map under **Application → Data Exchange → Data Maps**, dimensions between source and target cubes fall into four architectural categories:

### 1. 1-to-1 Direct Mapping
- **Condition**: Dimension exists in both source and target cubes with identical or alias-matched member names (e.g., `Account` $\rightarrow$ `Account`, `Period` $\rightarrow$ `Period`).
- **Engine Behavior**: Direct member-to-member stream. If member names differ, the mapping engine cross-references the target alias or explicit mapping table.

### 2. Unmapped Dimensions (Present in Target, Absent in Source)
- **Condition**: The target ASO reporting cube has higher dimensionality than the BSO source cube (e.g., Target has `Project` and `Channel`, but Source BSO does not track these).
- **Resolution**: Every data cell transferred must have a valid coordinate for every target dimension. The administrator **must** assign a default static member in the Data Map definition (e.g., `Project` $\rightarrow$ `"No_Project"`, `Channel` $\rightarrow$ `"No_Channel"`).
- **Kernel Failure if Missing**: If an unmapped target dimension has no default member specified, Smart Push immediately halts with:
  ```
  EPM-52011: Data map validation failed. Target dimension [Project] is unmapped without a default member assignment.
  ```

### 3. Excluded Dimensions (Present in Source, Absent in Target)
- **Condition**: The source BSO cube contains a detailed planning dimension not needed in the ASO reporting cube (e.g., `Employee` in Workforce planning).
- **Resolution**: Detailed Level 0 source members cannot be written directly into a target cube that lacks that dimension. The Data Map requires selecting a specific parent or roll-up member (e.g., `"Total_Employee"` or `"No_Employee"`).
- **Execution Mechanism**: The engine aggregates the excluded dimension in BSO RAM before pushing, or extracts data strictly at the specified rollup intersection.

### 4. Split / Segment Mapping
- **Condition**: A concatenated source member represents two separate dimensions in the target cube (e.g., Source `Entity` = `E101_US` maps to Target `Entity` = `E101` and `Geography` = `US`).
- **Resolution**: Configured via EPM Groovy rules or specialized mapping rules in EPM Integration.

---

## 3. Physical Data Movement: ASO Load Buffer Mechanics

Writing data directly into an active ASO cube using conventional transactional cell writes degrades performance because each write updates aggregate views and creates micro-slices on disk.

Smart Push resolves this by utilizing the **Essbase ASO Load Buffer Kernel API**:

### The 3-Step ASO Load Buffer Lifecycle

1. **`EssASOInitLoadBuffer()`**:
   - The kernel allocates a dedicated temporary memory buffer in RAM.
   - Buffer properties:
     - `Buffer ID`: Integer identifier (e.g., `1`).
     - `Duplicate Action`: Set to `ESSASO_DUPLICATE_OVERWRITE` (newest source value replaces previous target value).
     - `Buffer Sizing`: Dynamically allocated based on the slice size extracted from BSO.
2. **`EssASOLoadBufferAddSlice()`**:
   - The transformed BSO data stream is piped directly into the ASO buffer in RAM.
   - Zero disk I/O occurs during this phase. Queries on the target ASO cube continue running without being locked or blocked.
3. **`EssASOCommitLoadBuffer()`**:
   - The kernel commits the memory buffer to disk as a single, contiguous **ASO Data Slice** file (`.DAT`).
   - The ASO slice table is updated atomically.
   - **Performance**: Pushing 100,000 data cells takes **< 0.5 seconds**, compared to 30+ seconds via traditional data import scripts.

---

## 4. Smart Push Execution Modes: Sync vs. Async

Smart Push can be executed through multiple architectural pathways:

| Execution Channel | Processing Mode | Lock Behavior | Best Use Cases |
| :--- | :--- | :--- | :--- |
| **Form Save (Synchronous)** | Foreground (Blocking HTTP request) | User browser waits until both BSO commit and ASO load buffer complete. | Immediate reporting updates where the user must view results in ASO reports right after saving. |
| **Groovy Targeted Push** | Foreground (Micro-slice) | User waits only for modified cells (< 200ms). | High-concurrency forms where full-slice Smart Push creates UI lag. |
| **EPM Automate `smartpush`** | Background / Asynchronous Batch | Non-blocking to interactive web users. | Scheduled batch data synchronization (e.g., hourly sync after ERP data loads). |
| **Pipeline Integration** | Orchestrated Step | Executes as part of multi-step enterprise ETL. | Nightly batch processing and financial close orchestration. |

---

## 5. Performance Optimization Matrix for Smart Push

| Strategy | Impact | Implementation Detail |
| :--- | :--- | :--- |
| **Check "Use Members on Form"** | **High** | In Form Settings → Smart Push, enable *Use Members on Form*. Restricts the push slice strictly to the current Page/POV/Row/Column members, rather than the entire database. |
| **Avoid Pushing Dynamic Calc Members** | **Critical** | Dynamic Calc members in BSO must be calculated on-the-fly before pushing. Pushing dense dynamic members causes BSO calculation overhead; push stored base members instead and let ASO calculate rollups dynamically. |
| **Schedule Periodic ASO Slice Merges** | **Maintenance** | Frequent Smart Push executions create dozens of micro-slices in ASO. Run an automated ASO slice merge (via EPM Automate `mergeDataSlices`) nightly to maintain sub-second query performance. |
