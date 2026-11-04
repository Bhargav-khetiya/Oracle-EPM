# 02 ASO Load Buffers, C++ Kernel APIs, and Storage Slice Internals

## 1. Low-Level ASO Ingestion Architecture

Aggregate Storage Option (ASO) cubes achieve blazing write speeds and near-instantaneous data ingestion because they **never perform random, in-place disk block updates**. Unlike Block Storage Option (BSO) cubes which locate, decompress, modify, and rewrite 64KB–256KB block files (`.pag`) via page tables (`.ind`), ASO writes incoming data sequentially into isolated **Storage Slices** (`.dat` files) using in-memory **Load Buffers**.

```
+===================================================================================================+
|                                 ASO LOAD BUFFER & SLICE ARCHITECTURE                              |
+===================================================================================================+
|                                                                                                   |
|  1. ESSBASE C++ API INVOCATION:                                                                   |
|     EssBeginLoadBuffer(hCtx, AppName, DbName, BufferId, DuplicateRule, SortOrder)                 |
|                                                                                                   |
|  2. MEMORY LOAD BUFFER INITIALIZATION:                                                            |
|     +-------------------------------------------------------------------------+                   |
|     | IN-MEMORY BUFFER (BufferId: 1001)                                       |                   |
|     | Allocates heap cache (e.g., 50MB)                                       |                   |
|     | Accepts un-sorted or sorted multidimensional coordinate tuples:         |                   |
|     | [Dim1_ID, Dim2_ID, Dim3_ID ... DimN_ID | Value]                         |                   |
|     +-------------------------------------------------------------------------+                   |
|                                         |                                                         |
|                                         | 3. EssWriteLoadBuffer(hCtx, RowsChunk)                  |
|                                         v                                                         |
|  4. BUFFER FLUSH & SLICE CREATION:                                                                |
|     EssUpdateFileASO(hCtx, BufferId, CommitMode)                                                  |
|                                         |                                                         |
|         +-------------------------------+-------------------------------+                         |
|         | Writes isolated incremental slice to disk                      |                         |
|         v                                                               v                         |
|     +--------------------------+                                    +--------------------------+  |
|     | MAIN STORAGE SLICE       |                                    | NEW INCREMENTAL SLICE    |  |
|     | File: slice_0000.dat     |                                    | File: slice_0001.dat     |  |
|     | 10,000,000 cells (Base)  |                                    | 15 cells (Smart Push)    |  |
|     +--------------------------+                                    +--------------------------+  |
|                   \                                                              /                |
|                    \                                                            /                 |
|                     +-----------------------------+----------------------------+                  |
|                                                   |                                               |
|                                                   v                                               |
|                                    +------------------------------+                               |
|                                    | ASO MDX QUERY RESOLVER       |                               |
|                                    | Dynamically sums slices:     |                               |
|                                    | Slice_0000 + Slice_0001      |                               |
|                                    +------------------------------+                               |
|                                                                                                   |
+===================================================================================================+
```

---

## 2. Essbase C++ Load Buffer APIs Explained

When Oracle EPM Cloud triggers a Data Map or Smart Push into an ASO cube, the platform application server issues low-level C++ API calls directly to the Essbase kernel (`libessbase.so` or `essbase.dll`):

### 2.1 `EssBeginLoadBuffer`
Initializes a temporary in-memory load buffer inside the Essbase server process space.
```c
ESS_STS_T EssBeginLoadBuffer(
    ESS_HCTX_T    hCtx,              /* Essbase Context Handle */
    ESS_STR_T     AppName,           /* Application Name (e.g., "Vision") */
    ESS_STR_T     DbName,            /* Database Name (e.g., "OEP_REP") */
    ESS_ULONG_T   BufferId,          /* Unique Integer Buffer ID (e.g., 101) */
    ESS_ULONG_T   DuplicateRule,     /* ESS_ASO_LOAD_DUPLICATES_ADD */
    ESS_ULONG_T   IgnoreMissing,     /* ESS_TRUE / ESS_FALSE */
    ESS_ULONG_T   IgnoreZeroes,      /* ESS_TRUE / ESS_FALSE */
    ESS_ULONG_T   SortOrder          /* ESS_ASO_LOAD_SORT_ORDER_ASCENDING */
);
```

#### Duplicate Aggregation Rules:
* `ESS_ASO_LOAD_DUPLICATES_ADD`: If multiple incoming records contain identical coordinate addresses, Essbase sums their values together. This is the **default and required setting** for EPM Cloud Data Maps to prevent data loss.
* `ESS_ASO_LOAD_DUPLICATES_OVERWRITE`: Replaces earlier records with the last encountered record in the stream.

### 2.2 `EssWriteLoadBuffer`
Streams data tuples from the application server memory directly into the initialized Essbase load buffer.
* The data stream transmits compressed integer member IDs (Tokens) rather than member name strings, maximizing network and bus bandwidth.
* Buffers are populated in streaming packets of 10,000 to 50,000 records.

### 2.3 `EssUpdateFileASO` (The Commit Phase)
Commits the in-memory load buffer directly to disk as a brand-new data slice.
```c
ESS_STS_T EssUpdateFileASO(
    ESS_HCTX_T    hCtx,              /* Essbase Context Handle */
    ESS_STR_T     AppName,
    ESS_STR_T     DbName,
    ESS_PULONG_T  pBufferIdList,     /* Pointer to array of Buffer IDs */
    ESS_ULONG_T   ulNumBuffers,      /* Number of buffers to commit in parallel */
    ESS_ULONG_T   CommitMode         /* ESS_ASO_LOAD_BUFFER_COMMIT_AS_INCREMENTAL */
);
```
* **Commit Mode**: By specifying `COMMIT_AS_INCREMENTAL`, the Essbase kernel avoids touching or locking the existing main database files. It generates a new `.dat` slice file on disk in milliseconds.

### 2.4 `EssDestroyLoadBuffer`
Frees all heap memory allocated to the buffer ID. This is called automatically after commit or immediately if an unhandled exception or network break occurs, preventing memory leaks in the Essbase server process.

---

## 3. C++ Kernel Data Structures & Pointer Arrays

Within the Essbase C++ engine, the load buffer is governed by internal kernel structures that maintain high-speed sorted pointer arrays:

```c
/* Low-Level Essbase ASO Ingestion Kernel Structs */

typedef struct ESS_COORD_TOKEN_T {
    ESS_ULONG_T      ulDimCount;         /* Number of dimensions (e.g., 14) */
    ESS_PULONG_T     pMemberTokens;      /* Array of 32-bit member integer tokens */
    ESS_DOUBLE_T     dCellValue;         /* 64-bit IEEE 754 floating point value */
} ESS_COORD_TOKEN_T, *PESS_COORD_TOKEN_T;

typedef struct ESS_ASO_LOAD_BUFFER_T {
    ESS_ULONG_T      ulBufferId;         /* Buffer identifier (e.g., 1001) */
    ESS_ULONG_T      ulState;            /* BUFFER_STATE_ALLOCATED / ACTIVE / COMMITTING */
    ESS_ULONG_T      ulDuplicateAction;  /* ADD (1) or OVERWRITE (2) */
    ESS_SIZE_T       stMaxCapacityBytes; /* Maximum memory limit (e.g., 209715200 for 200MB) */
    ESS_SIZE_T       stCurrentAllocBytes;/* Active heap memory allocated */
    ESS_ULONG_T      ulRecordCount;      /* Current number of buffered tuples */
    PESS_COORD_TOKEN_T pRecordsArray;    /* Contiguous sorted memory buffer */
} ESS_ASO_LOAD_BUFFER_T, *PESS_ASO_LOAD_BUFFER_T;

typedef struct ESS_ASO_SLICE_DESCRIPTOR_T {
    ESS_ULONG_T      ulSliceId;          /* Monotonically increasing slice index (e.g., 4) */
    ESS_CHAR_T       szDataFileName[256];/* Physical path: slice_0004.dat */
    ESS_CHAR_T       szIdxFileName[256]; /* Physical path: slice_0004.idx */
    ESS_UINT64_T     u64TotalCells;      /* Number of active cells stored */
    ESS_TIMESTAMP_T  tsCommitTimestamp;  /* Exact commit epoch timestamp */
} ESS_ASO_SLICE_DESCRIPTOR_T;
```

```
+---------------------------------------------------------------------------------------------------+
|                        ASO IN-MEMORY BUFFER POINTER ARRAY LAYOUT                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  LOAD BUFFER HEADER (BufferId: 1001)                                                              |
|  [Capacity: 50MB] | [Records: 1,250] | [SortState: SORTED_BY_TOKEN_ASC]                           |
|         |                                                                                         |
|         v                                                                                         |
|  POINTER ARRAY (Contiguous 64-bit Memory Pointers):                                               |
|  +--------------+--------------+--------------+--------------+ ... +--------------+               |
|  | Ptr -> Rec 0 | Ptr -> Rec 1 | Ptr -> Rec 2 | Ptr -> Rec 3 | ... | Ptr -> Rec N |               |
|  +--------------+--------------+--------------+--------------+ ... +--------------+               |
|         |              |              |                                                           |
|         v              v              v                                                           |
|  RECORD TUPLES IN HEAP:                                                                           |
|  Rec 0: [Token: 104, 209, 811, 402, 12 ... | Value: 14500.00]                                     |
|  Rec 1: [Token: 104, 209, 811, 402, 13 ... | Value: 8200.50]                                      |
|  Rec 2: [Token: 104, 215, 811, 402, 01 ... | Value: -350.00]                                      |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 4. Kernel State Transitions & Lifecycle

The Essbase load buffer transitions through strict, atomic kernel states:

```
+===================================================================================================+
|                               ASO LOAD BUFFER STATE MACHINE                                       |
+===================================================================================================+
|                                                                                                   |
|  [STATE 0: UNINITIALIZED]                                                                         |
|         |                                                                                         |
|         | API: EssBeginLoadBuffer()                                                               |
|         v                                                                                         |
|  [STATE 1: BUFFER_ALLOCATED]                                                                      |
|  - Heap memory reserved in Essbase address space.                                                 |
|  - Tokens and sort parameters registered.                                                         |
|         |                                                                                         |
|         | API: EssWriteLoadBuffer() (Streams chunks of data tuples)                               |
|         v                                                                                         |
|  [STATE 2: BUFFER_STREAMING]                                                                      |
|  - Binary quick-sort organizes incoming coordinate tokens in memory.                              |
|  - Duplicate records summed (ESS_ASO_LOAD_DUPLICATES_ADD) or replaced.                            |
|         |                                                                                         |
|         | API: EssUpdateFileASO()                                                                 |
|         v                                                                                         |
|  [STATE 3: BUFFER_COMMITTING]                                                                     |
|  - Sequential disk write generates new slice_NNNN.dat and slice_NNNN.idx.                         |
|  - Atomic registry write updates slice_index.xml.                                                 |
|  - Data becomes immediately visible to all query threads!                                         |
|         |                                                                                         |
|         | API: EssDestroyLoadBuffer()                                                             |
|         v                                                                                         |
|  [STATE 4: BUFFER_DESTROYED / HEAP FREED]                                                         |
|  - In-memory buffer pointers freed; zero residual memory leaks.                                   |
|                                                                                                   |
+===================================================================================================+
```

---

## 5. Micro-Slices vs. Macro-Slices

The operational impact of Data Maps depends heavily on whether the payload constitutes a **Micro-Slice** or a **Macro-Slice**:

| Attribute | Micro-Slice (Smart Push) | Macro-Slice (Full Data Map) |
| :--- | :--- | :--- |
| **Typical Payload Size** | $1 \text{ to } 5,000$ cells | $100,000 \text{ to } 50,000,000+$ cells |
| **Trigger Mechanism** | Web Form Save / Action Menu | EPM Automate / Nightly Job Scheduler |
| **Buffer Memory Used** | $< 2 \text{ MB}$ | $200 \text{ MB} - 2 \text{ GB}$ |
| **Commit Latency** | $100 \text{ ms} - 1.5 \text{ seconds}$ | $15 \text{ seconds} - 10 \text{ minutes}$ |
| **Slice File Impact** | Creates small 4KB–64KB `.dat` file | Creates substantial multi-megabyte `.dat` file |
| **User Experience Impact** | Imperceptible; web form unlocks immediately | Heavy background processing; requires batch window |

---

## 6. Physical Storage Internals on Disk

Within the Oracle Cloud infrastructure backing Essbase ASO cubes, data directory structures reflect slice isolation:

```
/u01/app/oracle/service/domains/EPMServer/data/essbase/app/Vision/OEP_REP/
  |-- default.opt               (Database metadata & options)
  |-- default.oti               (Outline token index file)
  |-- default.otm               (Outline member string metadata)
  |-- default.sel               (Security filter definitions)
  |-- slice_0000.dat            (Main data slice: 4.8 GB)
  |-- slice_0000.idx            (B-tree index for slice 0000)
  |-- slice_0001.dat            (Nightly batch slice: 120 MB)
  |-- slice_0002.dat            (Morning Smart Push slice: 16 KB)
  |-- slice_0003.dat            (Afternoon Smart Push slice: 32 KB)
  `-- slice_index.xml           (Slice registry listing active slices & timestamps)
```

### 6.1 Zero-Locking Concurrency
Because each Smart Push or Data Map generates an isolated `slice_NNNN.dat` file:
* **Readers are NEVER blocked by Writers**: End users querying reporting dashboards against `slice_0000.dat` experience zero lock waiting while a Smart Push writes to `slice_0003.dat`.
* **Atomic Visibility**: The moment `EssUpdateFileASO` finishes, `slice_index.xml` is updated atomically. The very next query executed by any user instantly reads all active slices simultaneously.

---

## 7. The Performance Cost: Slice Proliferation & Degradation Law

While writing incremental slices is instantaneous, reading across multiple slices introduces query-time aggregation overhead.

### Mathematical Query Degradation Law
When a reporting query requests an upper-level consolidated coordinate (e.g., `Total Company -> Net Income -> FY24`):
$$\text{Query Latency} \propto \sum_{i=1}^{S} \text{B-Tree Index Lookups}(\text{Slice}_i)$$
Where $S$ is the total count of active slices.
* If $S = 1$: Query executes in $50 \text{ ms}$.
* If $S = 25$: Query must perform 25 separate index traversals and merge 25 coordinate values in memory, causing query latency to escalate to $2 \text{ to } 5 \text{ seconds}$.
* If $S > 50$: Severe reporting lag, dashboard timeouts, and high server CPU utilization occur.

This phenomenon requires strict **ASO Slice Merge Maintenance**.

---

## 8. Top 5 Twisted Review & Interview Questions on ASO Load Buffers

### Q1: Why does loading data into an ASO cube never result in block fragmentation or index page splitting—
**Answer**: Because ASO does not use BSO page files (`.pag`) or block index tables (`.ind`). In ASO, all writes occur via load buffers that append sequentially into brand new physical slice files (`slice_NNNN.dat`). Existing slices on disk are completely read-only and immutable. Because existing data files are never modified in place, zero page splitting or block fragmentation occurs.

### Q2: What is the risk of having 100 Smart Push operations execute throughout the day without a slice merge—
**Answer**: Each Smart Push creates an incremental storage slice. With 100 Smart Pushes, Essbase creates 100 separate `.dat` and `.idx` files. When an executive runs an ad-hoc query or report in Smart View, the ASO retrieval engine must traverse 100 separate B-tree indexes and sum 100 values in memory for every cell displayed. This causes severe query latency degradation, report timeouts, and heavy CPU usage.

### Q3: What is the difference between `ESS_ASO_LOAD_DUPLICATES_ADD` and `ESS_ASO_LOAD_DUPLICATES_OVERWRITE`—
**Answer**:
* `ESS_ASO_LOAD_DUPLICATES_ADD`: If multiple rows in the load stream have identical dimension member coordinates, Essbase sums their values together. This is the mandatory setting for EPM Cloud financial data maps where multiple operational accounts map to a single reporting account.
* `ESS_ASO_LOAD_DUPLICATES_OVERWRITE`: If duplicates occur, the last record in the stream replaces any prior records.

### Q4: What happens if an Essbase server crashes while a load buffer is receiving data—
**Answer**: Absolute zero database corruption occurs. The load buffer resides purely in volatile memory. Because the commit API (`EssUpdateFileASO`) was never called, no entry was written to `slice_index.xml`. Upon reboot, the database remains in its clean, pre-load state.

### Q5: Can multiple users load data into the same ASO cube concurrently—
**Answer**: **Yes**. The Essbase kernel supports concurrent data loads by allocating distinct `BufferId` numbers (e.g., Buffer 101 and Buffer 102). Each buffer collects and sorts its data independently. When committed, they generate separate incremental slice files, ensuring full multi-user concurrency without database-level write locks.
