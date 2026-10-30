# 07 — Data Operations and Performance: How Things Work Internally

---

## 7.1 Overview of Key Operations

Every operation in Essbase ultimately comes down to **reading blocks, modifying cells, and writing blocks**. But the specifics of HOW each operation works at the block level vary dramatically:

```
Operation            Block Impact                         I/O Pattern
─────────────────────────────────────────────────────────────────────────
Data Retrieval       Read blocks, extract cells           Random read
Data Input           Read block, modify cell, write back  Random read/write
Data Load            Create/update many blocks             Sequential write
CALC ALL             Read all blocks, create new blocks    Full scan + write
CALC DIM             Read blocks for one dimension         Partial scan + write
Business Rule        Read/write targeted blocks            Targeted read/write
Aggregation (AGG)    Read children, write parents           Bottom-up scan
DATACOPY             Read source, write target              Copy pattern
CLEARBLOCK           Remove blocks                          Index + page delete
Export               Read all blocks                        Sequential read
Restructure          Read all, rewrite all                  Full rewrite
```

---

## 7.2 Data Retrieval — What Happens When You Open a Form

When a user opens a Planning form or Smart View grid, here's the **complete internal flow**:

```
USER OPENS FORM
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│ PLANNING SERVER                                          │
│                                                          │
│ 1. Read form definition from RELATIONAL DB                │
│    - Which dimensions on rows/columns/POV                 │
│    - Which members selected                               │
│    - Data display properties (precision, scaling)         │
│                                                          │
│ 2. Apply SECURITY filters                                 │
│    - Which members can this user see?                     │
│    - Read/Write access at member level                    │
│                                                          │
│ 3. Build GRID of cell addresses                           │
│    Each cell = one intersection of all dimensions          │
│    e.g., (Revenue, Jan, FY24, Actual, Working,            │
│           US_East, Widget)                                 │
│                                                          │
│ 4. Send cell addresses to ESSBASE                         │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ ESSBASE SERVER — RETRIEVAL ENGINE                        │
│                                                          │
│ 5. Group cells by BLOCK                                   │
│    Cells from same sparse combo → same block request      │
│    This minimizes block reads                              │
│                                                          │
│    Cell group 1: (US_East, Widget, Actual, FY24)          │
│      → Revenue/Jan, Revenue/Feb, COGS/Jan, COGS/Feb      │
│    Cell group 2: (US_West, Widget, Actual, FY24)          │
│      → Revenue/Jan, Revenue/Feb, COGS/Jan, COGS/Feb      │
│                                                          │
│ 6. For each block needed:                                 │
│    a. Search INDEX for block location                     │
│    b. Check DATA CACHE for block                          │
│    c. If not cached → read from .PAG + decompress          │
│    d. Extract requested cells from block                  │
│    e. Handle DYNAMIC CALC members:                        │
│       - Don't look for stored value                       │
│       - CALCULATE on the fly                              │
│       - May need to read additional blocks for formula    │
│                                                          │
│ 7. Return cell values to Planning                         │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ PLANNING SERVER                                          │
│                                                          │
│ 8. Format values (precision, scaling, currency symbol)    │
│ 9. Apply form-level formatting (colors, read-only cells) │
│ 10. Apply Smart List mappings (if any)                   │
│ 11. Send formatted grid to USER                          │
└─────────────────────────────────────────────────────────┘
```

### Performance Factors in Retrieval

```
Factor                     Impact          How to Optimize
──────────────────────────────────────────────────────────────────
# of blocks to read        HIGH            Reduce form scope, use POV
Block size                  MEDIUM          Keep blocks 8-200 KB
# of Dynamic Calc members  HIGH            Limit dynamic calcs in forms
Data Cache size             HIGH            Increase if blocks don't fit
Index Cache size            MEDIUM          Should hold entire index
Compression method          LOW-MEDIUM      Bitmap is usually fine
Disk speed                  MEDIUM          SSD >> HDD
Network latency             LOW-MEDIUM      Form on same network
```

---

## 7.3 Data Input — What Happens When You Save a Form

```
USER CLICKS SAVE (with modified cells)
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│ PLANNING SERVER                                          │
│                                                          │
│ 1. Collect all modified cells                             │
│    [{cell: (Rev,Jan,FY24,Act,Wrk,USE,Wdg), value: 160}] │
│                                                          │
│ 2. Validate data                                         │
│    - Is the cell writable? (not read-only)                │
│    - Is the value valid? (numeric, in range)              │
│    - Does user have WRITE access?                         │
│                                                          │
│ 3. Send cell updates to ESSBASE                           │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ ESSBASE SERVER — UPDATE ENGINE                           │
│                                                          │
│ 4. Group updates by BLOCK (same as retrieval)             │
│                                                          │
│ 5. For each block:                                        │
│    a. ACQUIRE WRITE LOCK                                  │
│    b. Load block into Data Cache (if not already)         │
│    c. Update cell values in memory                        │
│    d. Mark block as DIRTY                                 │
│    e. RELEASE WRITE LOCK                                  │
│                                                          │
│ 6. Log transaction in .TCT file                           │
│                                                          │
│ 7. Return success/failure to Planning                     │
│                                                          │
│ 8. LATER: Flush dirty blocks to disk                      │
│    - When Data Cache is full                              │
│    - When commit interval fires                           │
│    - When database is stopped                             │
│    - When explicit commit is requested                    │
└─────────────────────────────────────────────────────────┘

                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ POST-SAVE ACTIONS (if configured)                        │
│                                                          │
│ 9. Run "On Save" business rule (if configured)            │
│    - Typically a calc script that aggregates data         │
│    - e.g., recalculate Q1 = Jan + Feb + Mar              │
│                                                          │
│ 10. Return updated values to the form                    │
│     - User sees recalculated totals immediately          │
└─────────────────────────────────────────────────────────┘
```

---

## 7.4 Data Load — Bulk Loading Data Into Essbase

### How a Data Load Works Internally

```
Data Source (CSV/SQL):
Entity,Product,Account,Period,Year,Scenario,Version,Value
US_East,Widget,Revenue,Jan,FY24,Actual,Working,100
US_East,Widget,Revenue,Feb,FY24,Actual,Working,120
US_East,Widget,COGS,Jan,FY24,Actual,Working,50
US_West,Gadget,Revenue,Jan,FY24,Actual,Working,200
...

ESSBASE DATA LOAD PROCESS:
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ 1. PARSE PHASE                                           │
│    Read each record from data source                      │
│    Apply rules file transformations (if any)              │
│    Map column values to dimension members                 │
│    Validate member names exist in outline                 │
│    Skip/reject invalid records                            │
│                                                          │
│ 2. SORT PHASE (optional but recommended)                  │
│    Sort records by sparse member combination              │
│    Records for same block are grouped together            │
│    This minimizes block load/unload cycles                │
│                                                          │
│    Sorted:                                                │
│    US_East,Widget → Revenue,Jan → 100                     │
│    US_East,Widget → Revenue,Feb → 120                     │
│    US_East,Widget → COGS,Jan → 50                         │
│    US_West,Gadget → Revenue,Jan → 200                     │
│                                                          │
│ 3. LOAD PHASE                                             │
│    For each record:                                       │
│    a. Compute sparse key                                  │
│    b. If different from current block → flush current      │
│    c. If block not in cache:                              │
│       - Search INDEX                                      │
│       - If exists → load from .PAG                        │
│       - If not exists → create new empty block             │
│    d. Write cell value into block                         │
│    e. Mark block dirty                                    │
│                                                          │
│ 4. COMMIT PHASE                                           │
│    Flush all dirty blocks to .PAG files                    │
│    Update .IND with any new/moved blocks                   │
│    Update .TCT with transaction log                        │
│    Report statistics (records loaded, rejected, etc.)      │
│                                                          │
│ Load Modes:                                               │
│  OVERWRITE: Replace existing cell values                   │
│  ADD:       Add to existing cell values                    │
│  SUBTRACT:  Subtract from existing values                  │
└─────────────────────────────────────────────────────────┘
```

### Data Load Performance Factors

```
Factor                        Impact          Optimization
──────────────────────────────────────────────────────────────────
Data sorted by sparse keys    CRITICAL        Pre-sort data files
Buffer size                   HIGH            Increase DATALOADBUFFERSIZE  
Data Cache size               HIGH            Must fit many blocks
Block locking                 MEDIUM          Use exclusive lock mode
Number of rules file ops      MEDIUM          Minimize transformations
Parallel load threads         HIGH            Use DLTHREADSPREPARE
Network (if SQL source)       LOW-MEDIUM      Local files are faster
```

---

## 7.5 Calculation (CALC ALL) — The Full Aggregation Process

### What CALC ALL Does

`CALC ALL` is the default calculation command that aggregates ALL dimensions in the outline, processing from bottom to top.

```
Outline (Hourglass order):
  1. Entity (Sparse)     ← Calculated LAST (largest)
  2. Product (Sparse)    ← Calculated 5th
  3. Account (Dense)     ← Calculated 4th ★
  4. Period (Dense)      ← Calculated 3rd ★
  5. Year (Dense)        ← Calculated 2nd ★
  6. Scenario (Sparse)   ← Calculated FIRST (smallest, at bottom)
```

### Step-by-Step CALC ALL Process

```
CALC ALL EXECUTION:

PHASE 1: Calculate Scenario (Sparse, bottom → first)
──────────────────────────────────────────────────────
For each unique (Entity, Product, Year) combination:
  For each Scenario parent:
    Create/load parent block
    Read child blocks (Actual, Budget, Forecast)
    Aggregate child blocks into parent
    Mark parent dirty

    Example:
    Block (US_East, Widget, FY24, "All_Scenarios")
      = Block (US_East, Widget, FY24, Actual)
      + Block (US_East, Widget, FY24, Budget)
      + Block (US_East, Widget, FY24, Forecast)

PHASE 2-4: Calculate Year, Period, Account (Dense → Intra-block)
──────────────────────────────────────────────────────
For each existing block:
  Load block into memory
  
  Year aggregation (within block):
    Year_Total = FY20 + FY21 + FY22 + FY23 + FY24
    (simple array addition within the block)
    
  Period aggregation (within block):
    Q1 = Jan + Feb + Mar
    Q2 = Apr + May + Jun
    ...
    Year = Q1 + Q2 + Q3 + Q4
    
  Account formulas (within block):
    Gross_Profit = Revenue - COGS
    Net_Income = Gross_Profit - OpEx - Tax
    Margin% = Net_Income / Revenue
    
  ALL done in memory, no disk I/O for each cell!
  Mark block dirty

PHASE 5: Calculate Product (Sparse)
──────────────────────────────────────────────────────
For each unique (Entity, Scenario, Year) combination:
  For each Product parent:
    Create/load parent block
    Read child product blocks
    Aggregate into parent
    Mark parent dirty

PHASE 6: Calculate Entity (Sparse, top → last)
──────────────────────────────────────────────────────
For each unique (Product, Scenario, Year) combination:
  For each Entity parent:
    Create/load parent block
    Read child entity blocks
    Aggregate into parent
    Mark parent dirty

FINAL: Flush all dirty blocks to disk
```

### Why Dense Calculations Are Fast

```
Dense calculation (within a block):

Block in memory (array of doubles):
┌─────────────────────────────────────────────────────────┐
│ Position 0-16:    Revenue    [Jan..Dec, Q1-Q4, Year]     │
│ Position 17-33:   COGS       [Jan..Dec, Q1-Q4, Year]     │
│ Position 34-50:   Gross_Pft  [Jan..Dec, Q1-Q4, Year]     │
│ ...                                                      │
└─────────────────────────────────────────────────────────┘

To calculate Gross_Profit = Revenue - COGS:
  for (i = 0; i < 17; i++) {
    block[34 + i] = block[0 + i] - block[17 + i];
  }

This is 17 subtract operations on consecutive memory locations.
CPU can do this in NANOSECONDS with cache-line optimization.
No disk I/O needed — block is already in RAM.

Compare to sparse calculation:
  Need to LOAD the Revenue block, LOAD the COGS block,
  compute the result, STORE the Gross_Profit block.
  That's 3 disk I/O operations minimum.
```

---

## 7.6 Specific Calc Commands and Their Block Impact

### FIX...ENDFIX

```
FIX ("Actual", "FY2024", "Working")
  CALC DIM ("Account");
ENDFIX

What happens:
  1. Essbase scans the INDEX for blocks matching:
     Scenario=Actual AND Year=FY2024 AND Version=Working
  2. Only those blocks are loaded and calculated
  3. All other blocks are UNTOUCHED
  
Benefit: Targeted calculation → fewer blocks → faster
```

### DATACOPY

```
DATACOPY "Actual" TO "Budget";

What happens:
  1. For each block with Scenario=Actual:
     a. Read the source block
     b. Check if target block (Scenario=Budget) exists
        - If yes → load target block
        - If no → CREATE new target block
     c. Copy all cell values from source to target
     d. Mark target block dirty
  
Blocks created: One new block for each existing Actual block
                where Budget block didn't exist
```

### AGG (Aggregation)

```
AGG ("Entity");

What happens:
  1. Process Entity hierarchy bottom-up:
     Level 0 members → Level 1 → Level 2 → ... → Top
  2. For each parent entity:
     a. Create/load parent block
     b. For each child entity:
        - Load child block
        - Add child values to parent
     c. Mark parent dirty
  
This ONLY aggregates Entity. Other dimensions untouched.
```

### CLEARBLOCK

```
CLEARBLOCK ALL;

What happens:
  1. Scan all blocks
  2. For each block:
     - Check if ALL cells are #Missing
     - If yes → remove block from INDEX
     - Deallocate space in PAGE file (mark as free)
  3. Update .IND and .PAG files
  
CLEARBLOCK does NOT clear data — it removes blocks that are entirely empty.
```

---

## 7.7 Performance Metrics and What They Mean

### Key Statistics from Essbase Logs

```
Statistic                      What It Means                              Good Value
──────────────────────────────────────────────────────────────────────────────────────
Total Calc Time                Wall clock time for calculation              < 30 min for daily
Calc Elapsed Time              CPU time for calculation                     Close to wall time
Blocks Read                    Number of blocks loaded from disk            Minimize
Blocks Written                 Number of blocks flushed to disk             Minimize
Blocks Created                 New blocks created during calc               Expected
Blocks Deleted                 Blocks removed during calc                   Expected
Index Page Reads               Times index was read from disk               Close to 0 (cached)
Data Cache Hit Ratio           % of block reads served from cache           > 90%
Index Cache Hit Ratio          % of index lookups served from cache         > 99%
Disk Read I/O                  Physical disk reads                          Minimize
Disk Write I/O                 Physical disk writes                         Minimize
```

### Reading the Essbase Log

```
Essbase Application Log entry after CALC ALL:

[Thu Oct 27 14:00:00 2026] Total Calc Elapsed Time for 
  [FinPlan].[FinPlan] : [720.500] seconds
  
  Total Block Created : [125,000]
  Total Block Read    : [450,000]  
  Total Block Written : [230,000]
  Total Block Deleted : [0]
  
  Dense Calc Time     : [180.200] seconds (25%)  ← Good: dense is fast
  Sparse Calc Time    : [540.300] seconds (75%)  ← Most time in sparse agg
  
  Data Cache Hit Ratio: [85.2%]  ← Below ideal, consider increasing cache
  Index Cache Hit Ratio: [99.8%] ← Excellent
```

---

## 7.8 Restructure Operations — The Most Disruptive Operation

### What Triggers a Restructure?

```
Change Type                      Restructure Type    Impact
──────────────────────────────────────────────────────────────────
Add dense member                 FULL (all blocks)   HIGH
Remove dense member              FULL (all blocks)   HIGH
Change sparse↔dense              FULL (all blocks)   VERY HIGH
Reorder dense members            FULL (all blocks)   MEDIUM
Add sparse member                IMPLICIT (index)    LOW
Remove sparse member             IMPLICIT (index)    LOW-MEDIUM
Change member formula            NONE                NONE
Change member consolidation      NONE                NONE
Change member alias              NONE                NONE
Add shared member                NONE                NONE
Change UDA                       NONE                NONE
```

### Full Restructure — Internal Process

```
FULL RESTRUCTURE:

1. ████ LOCK DATABASE (exclusive — all users disconnected)
2. ████ READ OUTLINE changes
3. ████ CALCULATE new block size
   └── New block size = new_dense_dim1 × new_dense_dim2 × ... × 8
4. ████ READ ALL EXISTING BLOCKS
   └── Load every block from .PAG files
   └── Decompress each block
5. ████ TRANSFORM EACH BLOCK
   ├── If dense member added:
   │   └── Expand block: insert cells at new member position
   │   └── Initialize new cells with #Missing
   ├── If dense member removed:
   │   └── Shrink block: remove cells at old member position
   │   └── Data in those cells is LOST
   ├── If sparse↔dense changed:
   │   └── COMPLETE REDISTRIBUTION (see Chapter 08)
   │   └── Blocks split or merged
   └── If member reordered:
       └── Rearrange cells within block to match new order
6. ████ WRITE NEW .PAG FILES
   └── Create temp .PAG files
   └── Write transformed blocks (compressed)
7. ████ WRITE NEW .IND FILES
   └── Create new B-tree index
   └── Map block keys to new locations
8. ████ SWAP FILES
   └── Backup old files (.keep)
   └── Replace with new files
9. ████ UNLOCK DATABASE
   └── Users can reconnect

Time: Minutes to HOURS depending on database size
Risk: If interrupted → database may be corrupted
      Always backup before restructure!
```

---

## 7.9 Performance Optimization Summary

```
┌──────────────────────────────────────────────────────────────────┐
│                PERFORMANCE OPTIMIZATION HIERARCHY                 │
│                (Most impactful to least impactful)                │
│                                                                  │
│  1. OUTLINE DESIGN                          ←── Most impactful   │
│     - Correct sparse/dense assignment                             │
│     - Optimal block size (8-200 KB)                               │
│     - Hourglass dimension ordering                                │
│     - Dynamic Calc for upper-level members                        │
│                                                                  │
│  2. CALCULATION DESIGN                                            │
│     - Targeted FIX statements (don't calc everything)             │
│     - Use CALC DIM instead of CALC ALL when possible              │
│     - Use SET AGGMISSG ON (skip #Missing in aggregation)          │
│     - Parallel calculation (SET CALCPARALLEL)                     │
│                                                                  │
│  3. CACHE CONFIGURATION                                          │
│     - Index Cache ≥ total index size                              │
│     - Data Cache = large as possible                              │
│     - Data File Cache = reasonable                                │
│                                                                  │
│  4. INFRASTRUCTURE                                               │
│     - SSD storage >> HDD                                          │
│     - More RAM = larger caches                                    │
│     - CPU cores for parallel calc                                 │
│     - Network bandwidth for client access                         │
│                                                                  │
│  5. MAINTENANCE                              ←── Least impactful │
│     - Regular CLEARBLOCK to remove empty blocks                   │
│     - Periodic restructure to defragment                          │
│     - Monitor and tune based on logs                              │
└──────────────────────────────────────────────────────────────────┘
```

---

## Summary

> **Every Essbase operation — retrieval, input, data load, calculation — works by reading, modifying, and writing BLOCKS. Dense calculations (within blocks) are blazing fast because they operate on contiguous arrays in RAM. Sparse calculations (across blocks) are slower because they require block I/O. CALC ALL processes dimensions bottom-to-top, which is why the Hourglass ordering matters. Data loads are fastest when pre-sorted by sparse keys. Restructures are the most disruptive operation and should be planned carefully with backups.**

---

**← Previous:** [06 — The Hourglass Principle](./06_Hourglass_Principle.md)  
**Next →** [08 — Sparse-Dense Interchange Impact](./08_Sparse_Dense_Interchange_Impact.md)
