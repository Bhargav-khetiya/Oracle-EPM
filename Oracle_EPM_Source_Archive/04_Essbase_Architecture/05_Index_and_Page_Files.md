# 05 — Index Files (.IND) and Page Files (.PAG): The Filing System of Essbase

---

## 5.1 The Two-File System

Essbase uses a **two-file system** to store and locate data:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   INDEX (.IND) = "Where is the data—                           │
│     - Maps sparse member combinations → physical locations      │
│     - Like a book's TABLE OF CONTENTS                           │
│     - Stored as a B-tree structure                              │
│                                                                 │
│   PAGE (.PAG) = "The actual data"                               │
│     - Contains compressed data blocks                           │
│     - Like the actual PAGES of the book                         │
│     - Blocks stored sequentially (with possible gaps)           │
│                                                                 │
│   To read data:                                                 │
│     1. Search INDEX → find block location (file + offset)       │
│     2. Read PAGE → get the block at that location               │
│     3. Decompress → extract cell value                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5.2 Index File (.IND) — Deep Dive

### Structure

The index file uses a **B-tree** (balanced tree) data structure for fast lookups:

```
                            ┌──────────────────┐
                            │   ROOT NODE      │
                            │   Keys: K50      │
                            └────────┬─────────┘
                       ┌─────────────┴──────────────┐
                       │                            │
              ┌────────▼────────┐          ┌────────▼────────┐
              │  BRANCH NODE    │          │  BRANCH NODE    │
              │  Keys: K20,K35 │          │  Keys: K70,K85 │
              └───┬────┬────┬──┘          └───┬────┬────┬──┘
                  │    │    │                  │    │    │
           ┌──────┘    │    └──────┐    ┌──────┘    │    └──────┐
           ▼           ▼           ▼    ▼           ▼           ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
    │LEAF NODE │ │LEAF NODE │ │LEAF NODE │ │LEAF NODE │ │LEAF NODE │
    │ K1→Loc1  │ │K21→Loc5  │ │K36→Loc9  │ │K51→Loc13 │ │K71→Loc17 │
    │ K2→Loc2  │ │K22→Loc6  │ │K37→Loc10 │ │K52→Loc14 │ │K72→Loc18 │
    │ K5→Loc3  │ │K25→Loc7  │ │K40→Loc11 │ │K55→Loc15 │ │K80→Loc19 │
    │ K10→Loc4 │ │K30→Loc8  │ │K45→Loc12 │ │K60→Loc16 │ │K85→Loc20 │
    └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
    
    Key (K) = Block Number (derived from sparse member combination)
    Location (Loc) = {Page file number, Offset within page file, Block size}
```

### What Each Index Entry Contains

```
Index Entry Structure:
┌─────────────────────────────────────────────────────────────┐
│ Field              │ Size    │ Description                   │
├─────────────────────────────────────────────────────────────┤
│ Block Key          │ 8 bytes │ Hash of sparse member combo   │
│ Page File Number   │ 4 bytes │ Which .PAG file (0, 1, 2...) │
│ Offset             │ 8 bytes │ Byte offset within .PAG file  │
│ Compressed Size    │ 4 bytes │ Size of block on disk          │
│ Block Status       │ 2 bytes │ Flags (dirty, empty, etc.)    │
│ Reserved           │ 6 bytes │ Alignment/future use           │
├─────────────────────────────────────────────────────────────┤
│ TOTAL per entry    │ ~32 bytes│                               │
└─────────────────────────────────────────────────────────────┘

So 1 million blocks → 1,000,000 × 32 = ~32 MB index file
```

### How Index Lookup Works

```
User requests: Revenue, Jan, FY24, Actual, Working, US_East, Widget

Step 1: Extract sparse members
  → (FY24, Actual, Working, US_East, Widget)

Step 2: Compute Block Key
  → key = hash(FY24=pos3, Actual=pos0, Working=pos0, US_East=pos5, Widget=pos12)
  → key = 3 × 600 + 0 × 200 + 0 × 100 + 5 × 50 + 12
  → key = 1800 + 0 + 0 + 250 + 12 = 2062

Step 3: Search B-tree for key 2062
  → Root: 2062 > 50, go right
  → Branch: 2062 > 85, go rightmost
  → Leaf: scan for key 2062
  → FOUND: PageFile=ess00002.pag, Offset=0x1A3400, Size=1890

Step 4: Read block from ess00002.pag at offset 0x1A3400, read 1890 bytes
```

### Index File Sizing

```
Index file size depends on:
  1. Number of existing blocks (not potential blocks)
  2. B-tree overhead (branch nodes, balancing)
  3. Free space for growth

Approximate formula:
  Index Size ≈ Number_of_blocks × 40 bytes (entry + overhead)
             + B-tree_structure_overhead (~10-20%)

Examples:
  10,000 blocks   → ~400 KB index
  100,000 blocks  → ~4 MB index
  1,000,000 blocks → ~40 MB index
  10,000,000 blocks → ~400 MB index (performance concern!)
```

---

## 5.3 Page File (.PAG) — Deep Dive

### Structure

Page files store the actual compressed data blocks:

```
Page File Layout:
┌─────────────────────────────────────────────────────────────┐
│ PAGE FILE HEADER (first page)                                │
│ ┌───────────────────────────────────────────────────────────┐│
│ │ File magic number                                         ││
│ │ Version                                                    ││
│ │ Database ID                                                ││
│ │ File sequence number (0 = primary, 1+ = overflow)          ││
│ │ Free space bitmap                                          ││
│ └───────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│ DATA AREA                                                    │
│ ┌─────────┬─────────┬───┬─────────┬─────────┬───┬─────────┐│
│ │ Block A │ Block B │GAP│ Block D │ Block E │GAP│ Block G ││
│ │ (comp.) │ (comp.) │   │ (comp.) │ (comp.) │   │ (comp.) ││
│ │ 1.2 KB  │ 3.4 KB  │0.8│ 2.1 KB  │ 1.8 KB  │0.5│ 4.2 KB ││
│ └─────────┴─────────┴───┴─────────┴─────────┴───┴─────────┘│
│                                                              │
│ Blocks are stored contiguously but may have GAPS             │
│ (from deleted or resized blocks)                             │
└─────────────────────────────────────────────────────────────┘
```

### Page File Sizing

```
Page file size depends on:
  1. Number of blocks with data
  2. Block size (determined by dense dimensions)
  3. Compression ratio
  4. Fragmentation level (gaps from deleted blocks)

Approximate formula:
  Page Size ≈ Number_of_blocks × Average_compressed_block_size
            × (1 + Fragmentation_factor)

Example:
  100,000 blocks × 5 KB average compressed size × 1.2 fragmentation
  = 600 MB total page file(s)
```

### Page File Overflow

When a page file reaches its maximum size, Essbase creates overflow files:

```
Maximum single file size: Configurable (default ~2 GB per file)
  Set via: MAXDATAFILECACHESIZE in essbase.cfg

Primary files:     <DbName>.ind, <DbName>.pag
Overflow files:    ess00001.ind, ess00001.pag
                   ess00002.ind, ess00002.pag
                   ess00003.ind, ess00003.pag
                   ...

File numbering:
  .pag number    File name
  ──────────────────────────
  0              <DbName>.pag
  1              ess00001.pag
  2              ess00002.pag
  ...            ...
  n              ess<n formatted as 5 digits>.pag
```

---

## 5.4 The Index-Page Relationship Visualized

```
INDEX FILE (.IND)                       PAGE FILE (.PAG)
─────────────────                       ─────────────────

┌──────────────────────┐                ┌─────────────────────────────┐
│ Block Key: 1001      │                │ Offset 0x000:               │
│ → File: 0, Off: 0x000├───────────────►│ ┌─────────────────────────┐ │
│   Size: 2048         │                │ │ Block 1001              │ │
├──────────────────────┤                │ │ [100,200,#M,#M,150,...] │ │
│ Block Key: 1042      │                │ │ Compressed: 2048 bytes  │ │
│ → File: 0, Off: 0x800├──────┐        │ └─────────────────────────┘ │
│   Size: 1536         │      │        │                             │
├──────────────────────┤      │        │ Offset 0x800:               │
│ Block Key: 2062      │      └───────►│ ┌─────────────────────────┐ │
│ → File: 1, Off: 0x000├───┐          │ │ Block 1042              │ │
│   Size: 3072         │   │          │ │ [50,75,80,#M,#M,...]    │ │
├──────────────────────┤   │          │ │ Compressed: 1536 bytes  │ │
│ Block Key: 3500      │   │          │ └─────────────────────────┘ │
│ → File: 0, Off: 0xE00├─┐│          │                             │
│   Size: 1024         │ ││          │ Offset 0xE00:               │
└──────────────────────┘ ││     ┌───►│ ┌─────────────────────────┐ │
                         ││     │    │ │ Block 3500              │ │
                         │└─┐   │    │ │ [10,20,30,#M,...]       │ │
                         │  │   │    │ │ Compressed: 1024 bytes  │ │
                         └──┼───┘    │ └─────────────────────────┘ │
                            │        └─────────────────────────────┘
                            │
                            │        ess00001.pag
                            │        ┌─────────────────────────────┐
                            │        │ Offset 0x000:               │
                            └───────►│ ┌─────────────────────────┐ │
                                     │ │ Block 2062              │ │
                                     │ │ [500,600,#M,450,...]    │ │
                                     │ │ Compressed: 3072 bytes  │ │
                                     │ └─────────────────────────┘ │
                                     └─────────────────────────────┘
```

---

## 5.5 How Reading Data Works (Step by Step)

### Full Read Path — From User Request to Cell Value

```
                    User: "Give me Revenue, Jan, FY24, US_East, Widget, Actual"
                                            │
                                            ▼
                    ┌───────────────────────────────────────┐
                    │ 1. PARSE REQUEST                      │
                    │    Sparse: (FY24, Actual, US_East,     │
                    │            Widget)                     │
                    │    Dense:  (Revenue, Jan)              │
                    └───────────────┬───────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────────────┐
                    │ 2. CHECK INDEX CACHE                   │
                    │    Is the index page for this key      │
                    │    already in memory—                   │
                    │    ┌────────────────────────────────┐  │
                    │    │ Index Cache (RAM)              │  │
                    │    │ Recently accessed index pages  │  │
                    │    └────────────────────────────────┘  │
                    └───────────────┬───────────────────────┘
                              ┌─────┴─────┐
                         CACHE HIT    CACHE MISS
                              │           │
                              │           ▼
                              │    ┌──────────────────────┐
                              │    │ 2b. READ INDEX PAGE  │
                              │    │     from .IND file   │
                              │    │     (disk I/O)       │
                              │    │     Load into cache   │
                              │    └──────────┬───────────┘
                              │               │
                              └───────┬───────┘
                                      │
                                      ▼
                    ┌───────────────────────────────────────┐
                    │ 3. SEARCH INDEX for Block Key          │
                    │    B-tree traversal                     │
                    │    Result: File=ess00002.pag            │
                    │            Offset=0x1A3400              │
                    │            Size=1890 bytes              │
                    └───────────────┬───────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────────────┐
                    │ 4. CHECK DATA CACHE                    │
                    │    Is this block already in memory—     │
                    │    ┌────────────────────────────────┐  │
                    │    │ Data Cache (RAM)               │  │
                    │    │ Recently accessed data blocks  │  │
                    │    └────────────────────────────────┘  │
                    └───────────────┬───────────────────────┘
                              ┌─────┴─────┐
                         CACHE HIT    CACHE MISS
                              │           │
                              │           ▼
                              │    ┌──────────────────────────┐
                              │    │ 4b. READ BLOCK from .PAG │
                              │    │     Read 1890 bytes from  │
                              │    │     ess00002.pag          │
                              │    │     at offset 0x1A3400    │
                              │    │     (disk I/O)            │
                              │    └──────────────┬───────────┘
                              │                   │
                              │                   ▼
                              │    ┌──────────────────────────┐
                              │    │ 4c. DECOMPRESS BLOCK     │
                              │    │     1890 bytes → 20,400   │
                              │    │     bytes uncompressed     │
                              │    │     Load into Data Cache  │
                              │    └──────────────┬───────────┘
                              │                   │
                              └───────┬───────────┘
                                      │
                                      ▼
                    ┌───────────────────────────────────────┐
                    │ 5. LOCATE CELL WITHIN BLOCK            │
                    │    Revenue = member offset 0            │
                    │    Jan = member offset 0                │
                    │    Cell position = 0 × 17 + 0 = 0      │
                    │    Memory offset = 0 × 8 = 0 bytes     │
                    │    from block start                     │
                    └───────────────┬───────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────────────┐
                    │ 6. RETURN VALUE                         │
                    │    Value at byte 0-7 = 150000.00        │
                    │    → Send to user                       │
                    └───────────────────────────────────────┘
```

---

## 5.6 How Writing Data Works (Step by Step)

```
User writes: Revenue, Jan, FY24, US_East, Widget, Actual = 160000

Step 1: PARSE (same as read)
        Sparse key → Dense cell

Step 2: ACQUIRE WRITE LOCK on the block
        └── If another user has it locked → WAIT

Step 3: SEARCH INDEX for existing block
        ├── FOUND → Load block from .PAG into Data Cache
        └── NOT FOUND → Create new block (all #Missing) + new index entry

Step 4: MODIFY CELL in memory (Data Cache)
        └── Cell position (Revenue, Jan) = byte 0
        └── Write 160000.00 (8 bytes)

Step 5: MARK BLOCK as DIRTY
        └── Set dirty flag in block header
        └── Block stays in Data Cache

Step 6: RELEASE WRITE LOCK
        └── Other users can now access this block

Step 7: EVENTUALLY FLUSH (async, not immediate)
        └── When: Data cache is full, commit interval, or explicit commit
        └── Compress block
        └── Write to .PAG file
        └── If block size changed:
            └── May need to relocate block (fragmentation)
            └── Update .IND with new location
        └── Update .TCT (transaction control)
        └── Clear dirty flag
```

---

## 5.7 Index File Caching

The **Index Cache** is a dedicated area in RAM that holds frequently accessed index pages:

```
┌──────────────────────────────────────────────────────────┐
│                    ESSBASE SERVER MEMORY                   │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              INDEX CACHE                            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐           │  │
│  │  │Index Page│ │Index Page│ │Index Page│   ...      │  │
│  │  │  1-100   │ │ 201-300  │ │ 801-900  │           │  │
│  │  └──────────┘ └──────────┘ └──────────┘           │  │
│  │                                                    │  │
│  │  Size: Configured via INDEXCACHESIZE                │  │
│  │  Default: Varies by version (typically 1-10 MB)     │  │
│  │  Best practice: Large enough to hold ENTIRE index   │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              DATA CACHE                             │  │
│  │  (separate — see Chapter 11)                        │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │           DATA FILE CACHE                           │  │
│  │  (file handle cache — see Chapter 11)               │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Index Cache Sizing Guidelines

```
Index Cache Size Recommendation:

  IDEAL: Index Cache ≥ Total Index File Size
  
  This means the ENTIRE index fits in memory, and every lookup
  is a memory operation (no disk I/O for index access).
  
  If Index = 40 MB → Set INDEXCACHESIZE = 40 MB (or higher)
  
  If Index is too large to fit in memory:
    - Consider outline redesign (too many blocks)
    - Prioritize other cache sizes
    - Accept slower performance
```

---

## 5.8 Data Flow Through Caches

```
COMPLETE DATA FLOW:

                           ┌─────────────────┐
                           │   APPLICATION    │
                           │   (User Request) │
                           └────────┬────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │         INDEX CACHE            │
                    │  (RAM - index pages)            │
                    │  Hit— → Get block location      │
                    │  Miss— → Read .IND file         │
                    │          └→ Load into cache      │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │          DATA CACHE            │
                    │  (RAM - uncompressed blocks)    │
                    │  Hit— → Get block from memory   │
                    │  Miss— → Need to read .PAG      │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │       DATA FILE CACHE          │
                    │  (OS file handle cache)         │
                    │  Hit— → File already open       │
                    │  Miss— → Open .PAG file         │
                    │          └→ Add to file cache    │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │     OPERATING SYSTEM CACHE      │
                    │  (OS disk cache / buffer pool)  │
                    │  Hit— → Read from OS cache      │
                    │  Miss— → Physical disk I/O      │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │        PHYSICAL DISK           │
                    │  (.PAG file on disk)            │
                    │  Actual disk read               │
                    │  (slowest operation)             │
                    └───────────────────────────────┘

Performance hierarchy (fastest to slowest):
  1. Index Cache hit + Data Cache hit    → ~microseconds
  2. Index Cache hit + Data Cache miss   → ~milliseconds
  3. Index Cache miss + Data Cache miss  → ~10+ milliseconds
  4. Everything misses (cold start)       → ~100+ milliseconds
```

---

## 5.9 Page File Allocation and Growth

### How Essbase Allocates Space in Page Files

```
Initial state (empty database):
┌────────────────────────────────────────────────────┐
│ <DbName>.pag                                        │
│ ┌──────────────────────────────────────────────────┐│
│ │                                                  ││
│ │              EMPTY (header only)                  ││
│ │              Size: ~4 KB                          ││
│ │                                                  ││
│ └──────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────┘

After loading data (100 blocks):
┌────────────────────────────────────────────────────┐
│ <DbName>.pag                                        │
│ ┌────┬────┬────┬────┬────┬─────────────────────────┐│
│ │ B1 │ B2 │ B3 │... │B100│      Free Space         ││
│ └────┴────┴────┴────┴────┴─────────────────────────┘│
│ Size: ~500 KB                                        │
└────────────────────────────────────────────────────┘

After many operations (fragmented):
┌────────────────────────────────────────────────────┐
│ <DbName>.pag                                        │
│ ┌────┬──┬────┬────┬──┬────┬──┬────┬──┬─────────────┐│
│ │ B1 │  │ B3 │ B5 │  │ B8 │  │B12 │  │   Free      ││
│ └────┴──┴────┴────┴──┴────┴──┴────┴──┴─────────────┘│
│       ↑       ↑       ↑       ↑                      │
│      gaps from deleted/moved blocks                   │
│ Size: ~600 KB (100 KB wasted in gaps)                 │
└────────────────────────────────────────────────────┘

Growth to overflow:
Primary: <DbName>.pag  → 2 GB (full)
Overflow: ess00001.pag → growing
```

### When Overflow Files Are Created

```
Overflow file creation triggers:
  1. Primary .PAG exceeds DATAFILESIZE limit (default ~2GB)
  2. Primary .IND exceeds INDEXFILESIZE limit
  3. Operating system file size limit reached
  4. Configured maximum file count reached (MAXDATAFILECOUNT)
```

---

## 5.10 File Operations During Key Activities

### During Data Load

```
1. Parse data record (Entity=US_East, Product=Widget, Account=Revenue, Period=Jan, Value=100)
2. Compute sparse key (US_East, Widget, ...)
3. Search INDEX
   ├── Block exists → Load block, update cell, mark dirty
   └── Block not found → Create new block
       ├── Allocate space in .PAG (append or fill gap)
       ├── Initialize block (all #Missing)
       ├── Write cell value
       ├── Add INDEX entry
       └── Mark dirty
4. Periodically flush dirty blocks to disk
5. At end of load → flush all dirty blocks → update .TCT
```

### During Restructure

```
1. Lock database (exclusive)
2. Read entire INDEX into memory
3. Read all blocks from .PAG files
4. Recompute block sizes (if dense members changed)
5. Recompute block keys (if sparse members changed)
6. Redistribute data into new blocks
7. Write new .IND file(s)
8. Write new .PAG file(s)
9. Delete old files
10. Rename new files
11. Unlock database

Duration: Can take MINUTES to HOURS for large databases
Impact:  DATABASE IS OFFLINE during restructure
```

### During Calculation

```
1. For each block that needs calculation:
   a. Load block into Data Cache
   b. Execute calc formulas within the block (intra-block)
   c. Mark block dirty
2. For aggregation across sparse dimensions:
   a. Load child blocks
   b. Create or load parent block
   c. Add child values to parent
   d. Mark parent block dirty
3. Flush all dirty blocks to disk
```

---

## Summary

> **The INDEX file (.IND) is a B-tree that maps sparse member combinations to physical locations in PAGE files (.PAG). Reading data requires an index lookup followed by a page file read. Writing data modifies blocks in memory and eventually flushes them to disk. Three levels of caching (Index Cache, Data Cache, Data File Cache) minimize disk I/O. Page files grow over time and can fragment, requiring periodic maintenance. Overflow files are created when primary files exceed size limits.**

---

**← Previous:** [04 — Block Storage Deep Dive](./04_Block_Storage_Deep_Dive.md)  
**Next →** [06 — The Hourglass Principle](./06_Hourglass_Principle.md)
