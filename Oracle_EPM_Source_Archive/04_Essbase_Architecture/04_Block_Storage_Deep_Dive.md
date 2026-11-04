# 04 — Block Storage Deep Dive: The Physics of Essbase Data

---

## 4.1 Block Anatomy — What's Inside a Block

Every block in Essbase BSO has two parts:

```
┌──────────────────────────────────────────────────┐
│                    BLOCK                          │
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │           BLOCK HEADER (~48-64 bytes)         ││
│  │  ┌──────────────────────────────────────────┐ ││
│  │  │ Block Number (ID)                         │ ││
│  │  │ Status flags (dirty, locked, compressed)  │ ││
│  │  │ Timestamp (last modified)                 │ ││
│  │  │ Block size (compressed/uncompressed)       │ ││
│  │  │ Compression type                           │ ││
│  │  │ Pointer to next block (if linked)          │ ││
│  │  └──────────────────────────────────────────┘ ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │           BLOCK DATA (variable size)          ││
│  │  ┌────┬────┬────┬────┬────┬────┬────┬────┐   ││
│  │  │C[0]│C[1]│C[2]│C[3]│C[4]│C[5]│... │C[n]│   ││
│  │  │ 8B │ 8B │ 8B │ 8B │ 8B │ 8B │    │ 8B │   ││
│  │  └────┴────┴────┴────┴────┴────┴────┴────┘   ││
│  │  n = (Dense_Dim1 × Dense_Dim2 × ... ) - 1     ││
│  └──────────────────────────────────────────────┘│
│                                                  │
└──────────────────────────────────────────────────┘
```

### Block Header Fields

| Field | Size | Purpose |
|-------|------|---------|
| Block ID | 8 bytes | Unique identifier derived from sparse member combination |
| Status flags | 4 bytes | Dirty bit, lock status, compression flag |
| Timestamp | 8 bytes | Last modification time |
| Compressed size | 4 bytes | Size of block on disk (after compression) |
| Uncompressed size | 4 bytes | Full size of block in memory |
| Compression type | 2 bytes | Bitmap, RLE, ZLIB, or None |
| Reserved | ~18 bytes | Future use, alignment padding |

---

## 4.2 Block Creation — When and How Blocks Are Born

### When Is a Block Created—

A new block is created when:

1. **Data Load**: Loading data to a sparse combination that doesn't have a block yet
2. **Data Input**: User enters data in a form/Smart View for a new sparse combination
3. **Calculation**: A calc script writes to a new sparse combination (e.g., `DATACOPY`)
4. **Aggregation**: Upper-level sparse members get blocks during calculation

### The Block Creation Process

```
Event: User enters "100" at (Revenue, Jan, FY24, Actual, Working, US_East, Widget)

                    Sparse members: (FY24, Actual, Working, US_East, Widget)
                    Dense members:  (Revenue, Jan)

Step 1: Check INDEX for existing block
        └── Search .IND for (FY24, Actual, Working, US_East, Widget)
        └── Result: NOT FOUND

Step 2: ALLOCATE new block in PAGE file
        └── Find free space in .PAG file
        └── If no space → extend the .PAG file or create new overflow file
        └── Allocate: Block_Size bytes (uncompressed)

Step 3: INITIALIZE block
        └── Fill all cells with #Missing (default value)
        └── Set block header (ID, timestamp, flags)

Step 4: WRITE the data
        └── Calculate cell position for (Revenue, Jan)
        └── Write value 100.0 at that position

Step 5: CREATE INDEX entry
        └── Add to .IND: (FY24, Actual, Working, US_East, Widget) → Page file, Offset
        └── Update index tree

Step 6: MARK block as DIRTY
        └── Block needs to be flushed to disk

Step 7: FLUSH to disk (eventually)
        └── Compress block
        └── Write compressed block to .PAG
        └── Update .IND with final location and size
```

---

## 4.3 Block Types: Input Blocks vs. Upper-Level Blocks

### Input Blocks (Level 0)
- Created for **Level 0 (leaf) sparse member combinations**
- Contain data that was loaded or entered by users
- These are the "ground truth" data blocks

### Upper-Level Blocks
- Created for **upper-level sparse member combinations** during calculation
- Contain aggregated data from child blocks
- Created by `CALC ALL`, `CALC DIM`, `AGG`, or specific calc scripts

```
Entity hierarchy:
  Total_Company
  ├── Americas
  │   ├── US_East    ← Level 0 (Input block)
  │   ├── US_West    ← Level 0 (Input block)
  │   └── Canada     ← Level 0 (Input block)
  └── Europe
      ├── UK         ← Level 0 (Input block)
      └── Germany    ← Level 0 (Input block)

After calculation:
  - Americas block = US_East + US_West + Canada (new block created)
  - Europe block = UK + Germany (new block created)
  - Total_Company block = Americas + Europe (new block created)

So 5 input blocks → 3 upper-level blocks → 8 total blocks
```

---

## 4.4 Block Locking and Concurrency

Essbase uses **block-level locking** for concurrent access:

```
User A reads block (US_East, Widget, Actual, FY24):
  └── READ LOCK acquired (shared)
  └── Other users can also read this block
  └── No one can write to it

User B tries to write to same block:
  └── WRITE LOCK requested (exclusive)
  └── BLOCKED — must wait for User A to finish reading

User A finishes reading:
  └── READ LOCK released

User B gets WRITE LOCK:
  └── Writes data to the block
  └── No one else can read or write
  └── WRITE LOCK released when done

Deadlock prevention:
  └── Essbase uses timeout-based deadlock detection
  └── If a lock cannot be acquired within timeout → operation fails
  └── Configurable via LOCKTIMEOUT in essbase.cfg
```

### Lock Granularity

```
┌───────────────────────────────────────────────────────┐
│ Lock Level      │ What's Locked          │ Impact     │
├───────────────────────────────────────────────────────┤
│ Block-level     │ Single block           │ Minimal    │
│ (default)       │                        │ contention │
├───────────────────────────────────────────────────────┤
│ Database-level  │ Entire database        │ Maximum    │
│ (during         │                        │ contention │
│  restructure)   │                        │            │
├───────────────────────────────────────────────────────┤
│ Application     │ Entire application     │ Total      │
│ (during         │                        │ lockout    │
│  outline save)  │                        │            │
└───────────────────────────────────────────────────────┘
```

---

## 4.5 Block States and Lifecycle

A block goes through several states during its lifetime:

```
                    ┌──────────┐
           ┌───────►│  CLEAN   │◄──── Read from disk
           │        │(on disk) │      (compressed)
           │        └────┬─────┘
           │             │
           │    Load into cache
           │             │
           │             ▼
           │        ┌──────────┐
           │        │  CACHED  │◄──── In memory
           │        │ (clean)  │      (uncompressed)
           │        └────┬─────┘
           │             │
           │     User modifies data
           │             │
           │             ▼
           │        ┌──────────┐
           │        │  DIRTY   │◄──── Modified in memory
           │        │ (cached) │      (needs write-back)
           │        └────┬─────┘
           │             │
           │    Flush to disk
           │    (commit/sync)
           │             │
           └─────────────┘

Special states:
  ┌──────────┐
  │ LOCKED   │ ← Being accessed by a user/process
  └──────────┘
  ┌──────────┐
  │ PENDING  │ ← Waiting for commit (transaction)
  └──────────┘
  ┌──────────┐
  │ FRAGMENT │ ← Block was deleted, space not yet reclaimed
  └──────────┘
```

---

## 4.6 Data Block Fragmentation

Over time, as blocks are created, modified, and deleted, the .PAG files become **fragmented**:

```
Before fragmentation (clean state):
┌────────────────────────────────────────────────────────┐
│ Page File (.PAG)                                       │
│ ┌──────┬──────┬──────┬──────┬──────┬──────┬──────────┐│
│ │Blk 1 │Blk 2 │Blk 3 │Blk 4 │Blk 5 │Blk 6 │  Free  ││
│ │ 20KB │ 15KB │ 20KB │ 18KB │ 20KB │ 16KB │  Space  ││
│ └──────┴──────┴──────┴──────┴──────┴──────┴──────────┘│
└────────────────────────────────────────────────────────┘

After updates (blocks change size due to different compression ratios):
┌────────────────────────────────────────────────────────┐
│ Page File (.PAG)                                       │
│ ┌──────┬───┬──────┬─────┬──┬──────┬───┬──────┬───────┐│
│ │Blk 1 │GAP│Blk 3 │ GAP │  │Blk 5 │GAP│Blk 6 │ Free ││
│ │ 22KB │3KB│ 14KB │ 6KB │  │ 25KB │2KB│ 16KB │Space ││
│ └──────┴───┴──────┴─────┴──┴──────┴───┴──────┴───────┘│
│           ↑ Blk 2 was       ↑ Blk 4 was                │
│             deleted           deleted                   │
└────────────────────────────────────────────────────────┘

After MANY operations:
  - Gaps everywhere (wasted space)
  - New blocks may not fit in gaps
  - .PAG files grow larger than necessary
  - Read performance degrades (non-sequential I/O)
```

### How to Fix Fragmentation

1. **Export and reload data**: Clear all data, restructure, reload
2. **Dense restructure**: Re-orders blocks within pages (faster)
3. **Full restructure**: Rebuilds all .IND and .PAG files from scratch
4. **RESETDB + data load**: Nuclear option — clear everything and start fresh

---

## 4.7 Block Compression Deep Dive

### Bitmap Compression (Default)

This is the most common and usually best compression method for Essbase:

```
Uncompressed block (simplified to 16 cells):
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│100.0│ #M  │ #M  │200.0│ #M  │ #M  │150.0│ #M  │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ #M  │ #M  │ #M  │ #M  │ #M  │ #M  │ #M  │ #M  │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘

Uncompressed size: 16 × 8 = 128 bytes

Bitmap compressed:
┌────────────────────────────────────────────────────────────────┐
│ Bitmap: [1,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0] (2 bytes packed)   │
│ Data:   [100.0, 200.0, 150.0]  (3 × 8 = 24 bytes)             │
│ Total:  2 + 24 = 26 bytes                                      │
│ Ratio:  26/128 = 20.3% (79.7% compression!)                    │
└────────────────────────────────────────────────────────────────┘
```

### RLE Compression (Run-Length Encoding)

Best for blocks with many consecutive identical values:

```
Block data: [100, 100, 100, 100, 0, 0, 0, 200, 200, 0, 0, 0, 0, 0, 0, 0]

RLE encoded:
  (4, 100)  →  "100 appears 4 times"
  (3, 0)    →  "0 appears 3 times"
  (2, 200)  →  "200 appears 2 times"
  (7, 0)    →  "0 appears 7 times"

Compressed: 4 entries × 12 bytes = 48 bytes (vs 128 bytes uncompressed)
```

### ZLIB Compression

Uses the standard DEFLATE algorithm for maximum compression:

```
Compression ratios:
  Bitmap:  60-80% reduction (fast decompress)
  RLE:     50-70% reduction (fast decompress)
  ZLIB:    80-95% reduction (slower decompress)
  None:    0% reduction (fastest read)
```

### Choosing Compression Method

| Scenario | Best Method |
|----------|-------------|
| General purpose | Bitmap (default) |
| Low block density (many #Missing) | Bitmap |
| High block density (few #Missing) | RLE or ZLIB |
| Maximum read performance | None |
| Maximum space savings | ZLIB |
| Very large database, disk constrained | ZLIB |

---

## 4.8 Block Size Calculation — Advanced Scenarios

### Scenario: Multiple Dense Dimensions

```
Dense Dimensions:
  Account:  150 stored members
  Period:    17 stored members
  Year:       5 stored members (if dense)
  Measures:  20 stored members (if dense)

Block Size = 150 × 17 × 5 × 20 × 8 = 2,040,000 bytes ≈ 2 MB

❌ TOO LARGE! Move Year or Measures to Sparse.

Better: Keep only Account (150) and Period (17) as Dense
Block Size = 150 × 17 × 8 = 20,400 bytes ≈ 20 KB ✅
```

### Scenario: Dense Dimension with Many Shared/Dynamic Calc Members

```
Account dimension:
  Total members in outline:     500
  Shared members:               100 (not stored, point to originals)
  Dynamic Calc members:         150 (not stored, calculated on-the-fly)
  Label Only members:            50 (not stored)
  ────────────────────────────────
  STORED members:               200

Block Size = 200 × Period_stored × 8
           = 200 × 17 × 8 = 27,200 bytes ≈ 26.6 KB ✅
```

### The Stored Member Count Query

You can check stored member counts using MaxL or EAS:

```
-- MaxL to get outline statistics
query database [AppName].[DbName] get outline_info;

-- Or check in EAS:
-- Database Properties → Statistics → Block Size
```

---

## 4.9 Empty Blocks and Phantom Blocks

### Empty Blocks
An **empty block** is a block where ALL cells are #Missing. It exists in the index and page files but contains no useful data.

```
How empty blocks are created:
1. Data existed, then was cleared → block remains but is empty
2. Calculation wrote data, then data was cleared
3. Data load created block with one cell, then that cell was cleared

Impact:
- Wastes index space (one entry per empty block)
- Wastes page file space (compressed #Missing still takes some bytes)
- Slows down calculations (Essbase may still process empty blocks)
- Increases aggregation time
```

### Removing Empty Blocks

```
-- MaxL command to remove empty blocks
alter database [AppName].[DbName] 
  reset blocks all;

-- Or use the CLEARBLOCK calc command
CLEARBLOCK ALL;

-- Remove only specific empty blocks
CLEARBLOCK 
  "Entity"="US_East"
  AND "Product"="Widget";
```

---

## 4.10 How Blocks Relate to the Outline

The outline (.OTL file) directly controls block behavior:

```
Outline Change                    Impact on Blocks
─────────────────────────────────────────────────────────────────
Add dense member              →  ALL blocks grow (restructure required)
Remove dense member           →  ALL blocks shrink (restructure required)
Add sparse member             →  No block change (new blocks created when data arrives)
Remove sparse member          →  Associated blocks deleted (restructure)
Change Sparse→Dense           →  FULL RESTRUCTURE (see Chapter 08)
Change Dense→Sparse           →  FULL RESTRUCTURE (see Chapter 08)
Reorder members               →  Blocks restructured (cell positions change)
Change Store→Dynamic Calc     →  Block shrinks (restructure)
Change Dynamic Calc→Store     →  Block grows (restructure)
Add shared member             →  No block change
```

---

## 4.11 Understanding Block Numbers

Each block has a unique **Block Number** derived from the sparse member combination:

```
Block Number = f(sparse_member_1_position, sparse_member_2_position, ...)

This is essentially a hash of the sparse member positions in the outline.

For a database with sparse dimensions:
  Entity:   member US_East at position 5
  Product:  member Widget at position 12
  Scenario: member Actual at position 0

Block Number ≈ 5 × (Product_size × Scenario_size) + 12 × Scenario_size + 0
             = 5 × (200 × 3) + 12 × 3 + 0
             = 3,000 + 36 + 0
             = 3,036

This block number serves as the KEY in the index.
```

---

## Summary

> **A block is a fixed-size array of cells (one per dense dimension intersection), identified by its sparse member combination. Blocks are created on demand, can be locked for concurrent access, go through clean→cached→dirty→flushed lifecycle states, and are stored compressed in .PAG files. Block fragmentation degrades performance over time and requires periodic maintenance. Empty blocks waste resources and should be cleared. The block size is determined entirely by dense dimension stored member counts.**

---

**← Previous:** [03 — Sparse vs Dense Complete Guide](./03_Sparse_vs_Dense_Complete_Guide.md)  
**Next →** [05 — Index Files and Page Files](./05_Index_and_Page_Files.md)
