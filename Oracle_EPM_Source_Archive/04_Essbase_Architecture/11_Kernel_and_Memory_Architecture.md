# 11 — Essbase Kernel and Memory Architecture

---

## 11.1 The Three Essential Caches

Essbase performance is fundamentally governed by three caches:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    ESSBASE SERVER MEMORY MODEL                        │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │  ┌──────────────────┐  ┌──────────────────┐                    │  │
│  │  │  INDEX CACHE      │  │  DATA CACHE       │                    │  │
│  │  │                   │  │                    │                    │  │
│  │  │ Stores: Index     │  │ Stores: Uncompressed│                   │  │
│  │  │ pages from .IND   │  │ data blocks from    │                   │  │
│  │  │                   │  │ .PAG files           │                   │  │
│  │  │ Purpose: Fast     │  │                    │                    │  │
│  │  │ block location    │  │ Purpose: Fast data │                    │  │
│  │  │ lookups           │  │ access without disk│                    │  │
│  │  │                   │  │ I/O                │                    │  │
│  │  │ Config:           │  │                    │                    │  │
│  │  │ INDEXCACHESIZE    │  │ Config:            │                    │  │
│  │  │                   │  │ DATACACHESIZE      │                    │  │
│  │  └──────────────────┘  └──────────────────┘                    │  │
│  │                                                                │  │
│  │  ┌──────────────────────────────────────────────┐              │  │
│  │  │           DATA FILE CACHE                     │              │  │
│  │  │                                                │              │  │
│  │  │ Stores: File handles to .PAG and .IND files    │              │  │
│  │  │ Purpose: Avoid repeatedly opening/closing       │              │  │
│  │  │          file handles to database files          │              │  │
│  │  │ Config: DATAFILECACHESIZE                       │              │  │
│  │  │         (number of open file handles)            │              │  │
│  │  └──────────────────────────────────────────────┘              │  │
│  │                                                                │  │
│  │  ┌──────────────────────────────────────────────┐              │  │
│  │  │           OTHER MEMORY AREAS                   │              │  │
│  │  │                                                │              │  │
│  │  │ • Calculator memory (for calc operations)       │              │  │
│  │  │ • Outline in memory (full .OTL loaded)          │              │  │
│  │  │ • Sort buffers (for data load sorting)          │              │  │
│  │  │ • Query tracking (active user sessions)         │              │  │
│  │  │ • Transaction log buffers                       │              │  │
│  │  │ • Thread stacks (one per connection)             │              │  │
│  │  └──────────────────────────────────────────────┘              │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Total Memory = Index Cache + Data Cache + Data File Cache           │
│               + Outline + Calculator + Connections + OS overhead      │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 11.2 Index Cache — Deep Dive

### What It Stores

The Index Cache holds **pages from the .IND file** in memory. Each page contains multiple index entries (block key → location mappings).

```
Index Cache Structure:
┌──────────────────────────────────────────────────────────┐
│ Index Cache (configured size: 10 MB)                      │
│                                                          │
│ ┌────────────┐ ┌────────────┐ ┌────────────┐            │
│ │ Index Page │ │ Index Page │ │ Index Page │ ...          │
│ │  #0001     │ │  #0042     │ │  #0108     │             │
│ │            │ │            │ │            │             │
│ │ Entries:   │ │ Entries:   │ │ Entries:   │             │
│ │ K100→Loc1  │ │ K4200→Loc5 │ │ K10800→L9  │             │
│ │ K101→Loc2  │ │ K4201→Loc6 │ │ K10801→L10 │             │
│ │ K102→Loc3  │ │ K4202→Loc7 │ │ K10802→L11 │             │
│ │ ...        │ │ ...        │ │ ...        │             │
│ └────────────┘ └────────────┘ └────────────┘             │
│                                                          │
│ LRU eviction: Least recently used pages evicted when     │
│ cache is full                                            │
└──────────────────────────────────────────────────────────┘
```

### Sizing Guidelines

```
RULE: Index Cache should be ≥ Total Index File Size

How to determine index size:
  1. Check file system:
     dir /s $ARBORPATH\app\<App>\<Db>\*.ind
     → Sum of all .IND file sizes
  
  2. Or via MaxL:
     query database <App>.<Db> get dbstats;
     → "Index File Size: XX MB"

Setting the cache:
  In essbase.cfg:
    INDEXCACHESIZE <AppName> <DbName> <SizeInBytes>
    
  Example:
    INDEXCACHESIZE FinPlan FinPlan 52428800    (50 MB)

  Or in EAS:
    Database Properties → Caches → Index Cache Size

WHAT HAPPENS IF TOO SMALL:
  - Index pages must be read from disk for each lookup
  - Every data retrieval requires a disk I/O before the actual data read
  - Cache hit ratio drops below 90%
  - Performance degrades significantly for retrievals and calculations

WHAT HAPPENS IF TOO LARGE:
  - Wastes RAM that could be used for Data Cache
  - No performance benefit beyond 100% cache (entire index in memory)
  - Diminishing returns
```

---

## 11.3 Data Cache — Deep Dive

### What It Stores

The Data Cache holds **uncompressed data blocks** in memory:

```
Data Cache Structure:
┌──────────────────────────────────────────────────────────┐
│ Data Cache (configured size: 200 MB)                      │
│                                                          │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│ │ Block 47832  │ │ Block 12001  │ │ Block 55019  │ ...  │
│ │ (US_East,    │ │ (US_West,    │ │ (Canada,     │      │
│ │  Widget,     │ │  Gadget,     │ │  Widget,     │      │
│ │  FY24,Act)   │ │  FY24,Act)   │ │  FY24,Bdg)   │      │
│ │              │ │              │ │              │      │
│ │ 20,400 bytes │ │ 20,400 bytes │ │ 20,400 bytes │      │
│ │ uncompressed │ │ uncompressed │ │ uncompressed │      │
│ │              │ │              │ │              │      │
│ │ Status:      │ │ Status:      │ │ Status:      │      │
│ │  DIRTY ✏️     │ │  CLEAN ✅     │ │  CLEAN ✅     │      │
│ └──────────────┘ └──────────────┘ └──────────────┘      │
│                                                          │
│ Blocks in cache: 200 MB / 20.4 KB ≈ 10,000 blocks       │
│                                                          │
│ Eviction policy: LRU (Least Recently Used)               │
│ Dirty blocks flushed to disk before eviction             │
└──────────────────────────────────────────────────────────┘
```

### How Data Cache Eviction Works

```
Cache is FULL, and a new block needs to be loaded:

1. Find the LEAST RECENTLY USED block in cache

2. Is it DIRTY— (has it been modified since last disk write—)
   ├── YES → Flush to disk first:
   │         Compress the block
   │         Write to .PAG file
   │         Update .IND if needed
   │         Then evict from cache
   └── NO → Simply evict (discard from memory)

3. Load the new block into the freed cache slot
   Read from .PAG
   Decompress
   Place in cache

This is why Data Cache size is CRITICAL:
  - Too small → constant eviction/loading → excessive disk I/O
  - Ideal → all working set blocks fit → minimal disk I/O
  - For CALC ALL → ideally fits ALL blocks (usually not possible)
```

### Sizing Guidelines

```
RULE: Data Cache should be as large as possible within available RAM

Sizing formula:
  Data Cache Size = Available_RAM 
                  - Index_Cache_Size
                  - Outline_Memory (~2× .OTL file size)
                  - OS_Overhead (~2 GB)
                  - Other_Applications
                  - Connection_Overhead (1-5 MB per user)

Example:
  Server RAM: 32 GB
  OS needs: 4 GB
  Index Cache: 50 MB
  Outline: 100 MB
  Other apps: 4 GB
  20 users × 3 MB: 60 MB
  ──────────────────
  Available for Data Cache: ~24 GB

Setting:
  DATACACHESIZE FinPlan FinPlan 25769803776    (24 GB)

IDEAL: Data Cache ≥ (total_blocks × uncompressed_block_size)
  If 200,000 blocks × 20 KB = 4 GB → Set Data Cache to 4+ GB
  This allows ALL blocks to be cached (no disk I/O during calc)
```

---

## 11.4 Data File Cache — Deep Dive

### What It Stores

The Data File Cache holds **open file handles** to .PAG and .IND files:

```
Data File Cache:
┌──────────────────────────────────────────────────────────┐
│ Data File Cache (configured: 32 file handles)             │
│                                                          │
│ ┌──────────────────┐ ┌──────────────────┐                │
│ │ File Handle #1   │ │ File Handle #2   │ ...            │
│ │ FinPlan.pag      │ │ FinPlan.ind      │                │
│ │ (open, seekable) │ │ (open, seekable) │                │
│ ├──────────────────┤ ├──────────────────┤                │
│ │ File Handle #3   │ │ File Handle #4   │                │
│ │ ess00001.pag     │ │ ess00001.ind     │                │
│ │ (open, seekable) │ │ (open, seekable) │                │
│ └──────────────────┘ └──────────────────┘                │
│                                                          │
│ Each handle = OS file descriptor + seek position         │
│ Opening/closing files is expensive → cache them          │
└──────────────────────────────────────────────────────────┘
```

### Why It Matters

```
WITHOUT file caching:
  For each block read:
    1. Open .PAG file (OS call — ~1ms)
    2. Seek to offset (~0.1ms)
    3. Read data (~0.5ms)
    4. Close .PAG file (OS call — ~0.5ms)
  Total: ~2.1ms per block read

WITH file caching:
  For each block read:
    1. File already open (skip open)
    2. Seek to offset (~0.1ms)
    3. Read data (~0.5ms)
    4. File stays open (skip close)
  Total: ~0.6ms per block read

3.5× faster per block read!
Over 200,000 blocks: saves ~5 minutes of I/O time
```

### Sizing Guidelines

```
DATAFILECACHESIZE = Number of open file handles to maintain

RULE: Set to the total number of .IND + .PAG files

Count your files:
  dir /s $ARBORPATH\app\<App>\<Db>\*.ind → N files
  dir /s $ARBORPATH\app\<App>\<Db>\*.pag → M files
  
  Set DATAFILECACHESIZE = N + M + some buffer

Example:
  3 .ind files + 5 .pag files = 8 files
  Set DATAFILECACHESIZE = 16 (2× for safety)

  DATAFILECACHESIZE FinPlan FinPlan 16

Note: OS may have limits on open file handles per process
      Check with: ulimit -n (Linux) or handle count (Windows)
```

---

## 11.5 Memory Layout — Complete Picture

```
ESSBASE SERVER PROCESS (ESSSVR) MEMORY MAP:

Total Process Memory
├── Code segment (~200 MB)
│   └── Essbase server binary code
│
├── Stack per thread (~1-2 MB per thread)
│   └── One thread per active user connection
│   └── Additional threads for calc, data load, etc.
│
├── Heap (dynamic allocation)
│   ├── Index Cache (configured)
│   │   └── B-tree index pages
│   │
│   ├── Data Cache (configured)
│   │   └── Uncompressed data blocks
│   │   └── Block headers and metadata
│   │
│   ├── Outline Memory
│   │   └── Full dimension/member tree in memory
│   │   └── Size ≈ 2-5× .OTL file size
│   │   └── Includes member properties, formulas, aliases
│   │
│   ├── Calculator Working Memory
│   │   └── Temporary arrays for calculations
│   │   └── Formula evaluation stacks
│   │   └── Parallel calc thread buffers
│   │
│   ├── Sort Buffers (for data load)
│   │   └── DATALOADBUFFERSIZE setting
│   │   └── Used to sort records by sparse key
│   │
│   ├── Query/Session Management
│   │   └── Active session tracking
│   │   └── Result set buffers
│   │   └── MDX query execution plans
│   │
│   └── Transaction Buffers
│       └── Transaction control data
│       └── Undo/redo information
│       └── Lock management tables
│
├── Memory-Mapped Files (optional)
│   └── OS may memory-map .PAG files for faster I/O
│
└── OS/Library Overhead
    └── C runtime, OS libraries, network buffers
```

---

## 11.6 Configuration Settings Reference

### essbase.cfg Key Settings

```
# ──────────────────────────────────────────────────────────────
# INDEX CACHE
# ──────────────────────────────────────────────────────────────
INDEXCACHESIZE <App> <Db> <bytes>
  Default: 1048576 (1 MB) ← Usually TOO SMALL!
  Recommended: ≥ total .IND file size
  Example: INDEXCACHESIZE FinPlan FinPlan 104857600  (100 MB)

# ──────────────────────────────────────────────────────────────
# DATA CACHE  
# ──────────────────────────────────────────────────────────────
DATACACHESIZE <App> <Db> <bytes>
  Default: 3145728 (3 MB) ← MUCH TOO SMALL for production!
  Recommended: As large as available RAM allows
  Example: DATACACHESIZE FinPlan FinPlan 8589934592  (8 GB)

# ──────────────────────────────────────────────────────────────
# DATA FILE CACHE
# ──────────────────────────────────────────────────────────────
DATAFILECACHESIZE <App> <Db> <files>
  Default: 8 (number of file handles)
  Recommended: Total .IND + .PAG files × 2
  Example: DATAFILECACHESIZE FinPlan FinPlan 32

# ──────────────────────────────────────────────────────────────
# CALCULATION SETTINGS
# ──────────────────────────────────────────────────────────────
CALCPARALLEL <value>
  Default: 1 (single-threaded calculation)
  Recommended: Number of CPU cores (e.g., 4 or 8)
  Example: CALCPARALLEL 4

CALCTASKDIMS <value>
  Default: 0 (Essbase decides)
  Specifies number of dimensions Essbase should split into parallel tasks
  
# ──────────────────────────────────────────────────────────────
# DATA LOAD SETTINGS
# ──────────────────────────────────────────────────────────────
DLTHREADSPREPARE <App> <Db> <threads>
  Default: 1
  Recommended: 2-4 for large data loads
  Example: DLTHREADSPREPARE FinPlan FinPlan 4

DATALOADBUFFERSIZE <App> <Db> <bytes>
  Default: system-dependent
  Larger = better sorting for data load
  Example: DATALOADBUFFERSIZE FinPlan FinPlan 104857600  (100 MB)

# ──────────────────────────────────────────────────────────────
# FILE SIZE LIMITS
# ──────────────────────────────────────────────────────────────
MAXDATAFILESIZE <bytes>
  Default: ~2 GB
  Maximum size per individual .PAG or .IND file before overflow

# ──────────────────────────────────────────────────────────────
# COMPRESSION
# ──────────────────────────────────────────────────────────────
DATACOMPRESSIONTYPE <App> <Db> <type>
  Options: BITMAP (default), RLE, ZLIB, NONE
  Example: DATACOMPRESSIONTYPE FinPlan FinPlan BITMAP

# ──────────────────────────────────────────────────────────────
# CONCURRENCY
# ──────────────────────────────────────────────────────────────
LOCKTIMEOUT <seconds>
  Default: 60 seconds
  How long to wait for a block lock before timing out
  
SERVERTHREADS <count>
  Default: system-dependent
  Maximum concurrent threads for the Essbase server
```

---

## 11.7 Cache Tuning Workflow

```
STEP-BY-STEP CACHE TUNING:

1. MEASURE current performance
   └── Run CALC ALL, note time
   └── Check application log for cache statistics
   └── Note: Data Cache hit ratio, Index Cache hit ratio

2. DETERMINE current file sizes
   └── Sum of all .IND files = Index File Size
   └── Sum of all .PAG files = Page File Size
   └── Blocks × uncompressed block size = Uncompressed Data Size

3. SET Index Cache = Index File Size (or larger)
   └── Goal: 99%+ hit ratio
   └── If index is 50 MB → set cache to 50-100 MB

4. SET Data Cache = as large as possible
   └── Goal: Maximum uncompressed data that fits in RAM
   └── Available RAM - Index Cache - OS - Other = Data Cache
   └── If 16 GB available → set Data Cache to 12-14 GB

5. SET Data File Cache = total files × 2
   └── Count .IND + .PAG files
   └── Set cache to 2× that count

6. RE-MEASURE performance
   └── Run same CALC ALL
   └── Compare time, cache ratios
   └── Iterate if needed

7. MONITOR ongoing
   └── Cache ratios should be:
       Index Cache: > 99%
       Data Cache: > 85% (higher is better)
   └── If ratios drop → increase cache or investigate growth
```

---

## 11.8 Memory Pressure and Out-of-Memory Scenarios

```
SYMPTOMS OF MEMORY PRESSURE:
─────────────────────────────
• Data Cache hit ratio < 70%
• Calculations take 5-10× longer than expected
• Essbase server becomes unresponsive
• "Unable to allocate memory" errors in log
• Operating system starts swapping (page file usage high)
• Server crashes during large calculations

COMMON CAUSES:
─────────────────
1. Data Cache too small for the working set
   Fix: Increase DATACACHESIZE

2. Block size too large (dense dimensions too big)
   Fix: Move dimensions from dense to sparse, or use Dynamic Calc

3. Too many concurrent users running calcs
   Fix: Schedule calcs during off-hours, limit concurrent users

4. Outline too large (100,000+ members)
   Fix: Consider ASO for reporting, reduce outline size

5. Parallel calc using too much memory (CALCPARALLEL too high)
   Fix: Reduce CALCPARALLEL value

EMERGENCY ACTIONS:
───────────────────
• Kill long-running calculations
• Disconnect users
• Reduce cache sizes and restart
• Add physical RAM to server
• Move to a larger server
```

---

## Summary

> **Essbase performance is governed by three caches: Index Cache (should hold entire index), Data Cache (as large as possible), and Data File Cache (covers all .PAG/.IND files). The Index Cache eliminates disk I/O for block lookups. The Data Cache eliminates disk I/O for block reads. The Data File Cache eliminates overhead of opening/closing files. Proper cache sizing can improve performance by 5-10×. The essbase.cfg file controls all cache and performance settings. Monitor cache hit ratios and adjust accordingly.**

---

**← Previous:** [10 — Behind the Scenes Complete](./10_Behind_The_Scenes_Complete.md)  
**Next →** [12 — Quick Reference and Cheat Sheet](./12_Quick_Reference_Cheat_Sheet.md)
