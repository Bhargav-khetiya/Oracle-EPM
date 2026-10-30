# ⚙️ Essbase Kernel — Calculation Engine Internals, Thread Scheduling & Parallelism

> **Purpose**: This technical manual details the internal C++ kernel architecture of the Essbase calculation engine, memory caching algorithms (`CALCCACHE`), thread scheduling mechanics, locking/latching concurrency, and parallel processing comparison (`CALCPARALLEL` vs `FIXPARALLEL`).

---

## 1. The Physics of the Calculation Execution Pipeline

When a calculation script or business rule executes against a Block Storage (BSO) database, the Essbase kernel (`ESSSVR`) executes a structured multi-stage compilation and execution pipeline:

```
[Calculation Script Text]
            │
            ▼
 [Stage 1: Lexical Analysis & AST Compilation]
 ├── Validates syntax, member existence, and dimensional hierarchy
 └── Compiles procedural script into an Abstract Syntax Tree (AST)
            │
            ▼
 [Stage 2: Dependency Graph & Execution Vector Planning]
 ├── Determines calculation order (Dense dimensions first, then Sparse)
 └── Selects execution mode: BOTTOMUP vs TOPDOWN
            │
            ▼
 [Stage 3: Worker Thread Dispatch & Slice Allocation]
 ├── Divides index tree into parallel chunks (FIXPARALLEL / CALCPARALLEL)
 └── Spawns OS worker threads (pthreads on Linux, Win32 threads on Windows)
            │
            ▼
 [Stage 4: Block Iteration Loop (Per Thread)]
 ├── 1. Probe .IND B-tree for next matching sparse key
 ├── 2. Acquire Block Header Lock (BHL)
 ├── 3. Load block into CALCCACHE Read Buffer
 ├── 4. Execute Dense Vector Math (8-byte IEEE 754 array operations)
 ├── 5. Mark block as DIRTY (Dirty Bit = 1)
 └── 6. Release Block Header Lock
            │
            ▼
 [Stage 5: Commit & Write-Ahead Logging (WAL)]
 ├── Flushes dirty blocks from CALCCACHE to .PAG file buffers
 └── Writes transaction commit record to .LOG / transaction journal
```

---

## 2. Calculation Memory Architecture (`CALCCACHE`)

The Calculation Cache is a dedicated RAM buffer that sits between the Essbase Kernel and the operating system disk subsystem. Its purpose is to batch block I/O operations, reading and writing contiguous clusters of blocks simultaneously.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CALCCACHE (e.g. 512 MB)                         │
│                                                                        │
│   ┌───────────────────────────────┐   ┌──────────────────────────────┐ │
│   │       READ BUFFER (70%)       │   │      WRITE BUFFER (30%)      │ │
│   │  Pre-fetches contiguous blocks│   │  Holds dirty modified blocks │ │
│   │  from .PAG based on .IND order│   │  Batches writes to disk      │ │
│   └───────────────▲───────────────┘   └──────────────┬───────────────┘ │
└───────────────────┼──────────────────────────────────┼─────────────────┘
                    │                                  │
                    │ Physical Block Read              │ Physical Block Write
                    ▼                                  ▼
      ┌───────────────────────────┐      ┌───────────────────────────┐
      │   ESSBASE .IND (Index)    │      │    ESSBASE .PAG (Data)    │
      └───────────────────────────┘      └───────────────────────────┘
```

### Calc Cache Sizing Mathematics

The calculation cache should be sized to hold at least **one complete sparse slice** of data blocks in memory:

$$\text{Minimum Calc Cache} = \text{Block Size (Bytes)} \times \text{Members in 1st Sparse Calc Dimension} \times 2$$

For example, if:
- Block Size = $131,072 \text{ bytes}$ (128 KB)
- The sparse dimension being calculated (`Entity`) has 500 members:

$$\text{Optimal Calc Cache} = 131,072 \times 500 \times 2 = 131,072,000 \text{ bytes} \approx 128 \text{ MB}$$

If `CALCCACHE` is sized smaller than this threshold, the engine will suffer from **cache thrashing**—continually evicting and re-reading the same blocks from disk as it rolls up parent entities.

---

## 3. Parallelism: `CALCPARALLEL` vs. `FIXPARALLEL`

Essbase provides two distinct methods for parallel calculation processing. Understanding their internal kernel differences is vital for performance engineering:

| Feature / Metric | `CALCPARALLEL` | `FIXPARALLEL` |
| :--- | :--- | :--- |
| **Architectural Layer** | Engine / Kernel Automated Multi-threading | Developer-Defined Explicit Script Slicing |
| **Control Mechanism** | Global command: `SET CALCPARALLEL n;` | Scoped block: `FIXPARALLEL (n, DimName) ... ENDFIXPARALLEL` |
| **Work Division** | Kernel automatically splits the entire sparse index tree. | Kernel creates $n$ dedicated sub-cubes sliced by the specified dimension members. |
| **Lock Contention Risk** | **High**: Worker threads frequently collide and wait when aggregating shared parent blocks. | **Zero**: Each thread works on an isolated, mutually exclusive slice of the database. |
| **Ideal Use Cases** | Full-database standard rollups (`CALC ALL;`, `AGG("Entity");`). | Complex procedural formulas, allocations, inter-company eliminations, driver calcs. |
| **Thread Scaling Efficiency** | Diminishing returns beyond 4–8 threads due to lock waits. | Linear scaling up to 16–32 threads (depending on hardware cores). |

### Low-Level Mechanism: Thread Collision in `CALCPARALLEL`

When multiple threads execute `CALCPARALLEL 8` on a parent rollup:

```
Thread 1 (calculating Entity "E101") ──┐
                                     ├──► Both attempt to lock Parent "E_Total"
Thread 2 (calculating Entity "E102") ──┘    (Thread 2 enters SPINLOCK WAIT state)
```

In `FIXPARALLEL`, by contrast, the developer slices on an independent dimension (such as `Entity` or `Product`), guaranteeing that each thread calculates independent data streams without competing for parent block locks:

```essbase
// High-Performance Parallel Allocation Script
SET CACHE HIGH;
FIXPARALLEL (8, @RELATIVE("Total_Entity", 0))
    FIX("Plan", "Working", "FY24", "Jan":"Dec")
        "Operating_Expense" = "Expense_Driver" * "Inflation_Rate" -> "No_Entity";
    ENDFIX
ENDFIXPARALLEL
```

---

## 4. Calculation Modes: `@CALCMODE(BOTTOMUP)` vs. `@CALCMODE(TOPDOWN)`

The calculation mode dictates how the Essbase kernel scans the database and traverses data blocks.

### 1. Bottom-Up Calculation (`@CALCMODE(BOTTOMUP)`)
- **Kernel Behavior**: The engine reads the `.IND` B-Tree and visits **only existing, physically populated blocks**.
- **Memory & I/O**: Zero wasted block lookups. Blocks that do not exist are never examined.
- **Speed**: $10\times$ to $100\times$ faster than Top-Down.
- **Default for**: Simple arithmetic formulas (e.g., `"AccountA" = "AccountB" * 1.05;`).

### 2. Top-Down Calculation (`@CALCMODE(TOPDOWN)`)
- **Kernel Behavior**: The engine traverses the entire potential Cartesian product of member combinations defined in the script outline, evaluating the formula for every combination regardless of whether a source block exists.
- **The Block Thrashing Disaster**:
  - If a formula contains cross-dimensional operators referencing sparse dimensions (e.g., `-> "Global_Assumptions"`), the engine cannot deduce which blocks will produce non-zero results from the index alone.
  - The kernel is forced to switch into Top-Down mode. It tests every possible sparse coordinate, attempting to load or create empty blocks in RAM.
  - **Result**: Millions of unnecessary I/O operations, generating severe disk bottlenecking and memory bloat.

### Forcing Bottom-Up Mode via Script Compiler Directive

```essbase
// Overriding an accidental Top-Down formula to force high-speed Bottom-Up execution
"Commission_Expense" @CALCMODE(BOTTOMUP) (
    "Revenue" * "Commission_Rate"->"No_Entity"->"Global_Assumptions";
)
```

---

## 5. Block Header Locking & Commit Levels

To maintain ACID consistency during concurrent calculations and data inputs, the kernel utilizes fine-grained locks:

1. **Block Header Lock (`BHL`)**:
   - A 64-bit atomic integer at the head of every in-memory data block.
   - When a thread modifies cells within a block, it acquires an exclusive `BHL`.
   - Other query or calc threads attempting to access that block must wait until the modifying thread releases the lock.
2. **Transaction Commit Points (`SET COMMITBLOCK`)**:
   - `SET COMMITBLOCK ONE;` — The kernel commits dirty blocks to `.PAG` after calculating each individual block. Safest for crash recovery, but slowest due to constant I/O sync.
   - `SET COMMITBLOCK ALL;` — Retains all modified blocks in `CALCCACHE` and writes them to `.PAG` in a single bulk flush at script termination. Provides maximum calculation speed.
