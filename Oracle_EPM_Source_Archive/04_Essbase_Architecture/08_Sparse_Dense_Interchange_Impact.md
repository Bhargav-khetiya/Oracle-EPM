# 08 — Sparse-Dense Interchange Impact: What Happens When You Swap

---

## 8.1 Why This Chapter Matters

Changing a dimension from **Sparse → Dense** or **Dense → Sparse** is one of the most **impactful and dangerous** operations in Essbase. It completely restructures how data is physically stored, and if done incorrectly, can:

- **Explode database size** by 100× or more
- **Crash the server** from memory exhaustion
- **Make calculations impossible** due to block count or block size
- **Take hours** for the restructure to complete
- **Corrupt data** if interrupted

Understanding the mechanics is critical before making this change.

---

## 8.2 What Physically Happens During Sparse → Dense Conversion

### Before: Dimension X is SPARSE

When X is sparse, it determines **which blocks exist**. Each unique value of X creates a separate block (if data exists).

```
Scenario: "Year" dimension is SPARSE with 5 members (FY20-FY24)

Dense dims: Account(100), Period(17)
Sparse dims: Entity(500), Product(200), Year(5)

Block size = 100 × 17 × 8 = 13,600 bytes ≈ 13.3 KB
Each Entity × Product × Year combo = one block

Blocks for Entity=US_East, Product=Widget:
  Block 1: Year=FY20 → [100 accounts × 17 periods] = 13.3 KB
  Block 2: Year=FY21 → [100 accounts × 17 periods] = 13.3 KB
  Block 3: Year=FY22 → [100 accounts × 17 periods] = 13.3 KB
  Block 4: Year=FY23 → [100 accounts × 17 periods] = 13.3 KB
  Block 5: Year=FY24 → [100 accounts × 17 periods] = 13.3 KB
  
  = 5 separate blocks, each 13.3 KB
```

### After: Dimension X Changed to DENSE

When X becomes dense, it becomes **part of every block's internal structure**. The Year dimension is now baked into each block.

```
Now: "Year" is DENSE

Dense dims: Account(100), Period(17), Year(5)
Sparse dims: Entity(500), Product(200)

Block size = 100 × 17 × 5 × 8 = 68,000 bytes ≈ 66.4 KB
Each Entity × Product combo = one block (Year is inside the block now!)

Block for Entity=US_East, Product=Widget:
  ONE block: [100 accounts × 17 periods × 5 years] = 66.4 KB
  
  = 1 block instead of 5, but 5× larger
```

### The Restructure Process: MERGE

```
SPARSE → DENSE: BLOCKS ARE MERGED

Before (5 separate blocks):
┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│ Block: FY20    │ │ Block: FY21    │ │ Block: FY22    │ │ Block: FY23    │ │ Block: FY24    │
│ Acct × Period  │ │ Acct × Period  │ │ Acct × Period  │ │ Acct × Period  │ │ Acct × Period  │
│ 13.3 KB each   │ │                │ │                │ │                │ │                │
└────────────────┘ └────────────────┘ └────────────────┘ └────────────────┘ └────────────────┘

After (1 merged block):
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ Block: (no Year in sparse key)                                                               │
│ Account × Period × Year (FY20 section + FY21 section + FY22 section + FY23 + FY24)           │
│ 66.4 KB                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────┘

5 blocks → 1 block (5× fewer blocks)
13.3 KB → 66.4 KB (5× larger per block)
Total data: Same (5 × 13.3 = 66.5 ≈ 66.4)
```

---

## 8.3 What Physically Happens During Dense → Sparse Conversion

### Before: Dimension X is DENSE

```
"Account" dimension is DENSE with 100 members

Dense dims: Account(100), Period(17)
Sparse dims: Entity(500), Product(200)

Block size = 100 × 17 × 8 = 13,600 bytes
Max blocks = 500 × 200 = 100,000
```

### After: Dimension X Changed to SPARSE

```
"Account" is now SPARSE

Dense dims: Period(17) only
Sparse dims: Entity(500), Product(200), Account(100)

Block size = 17 × 8 = 136 bytes ← TINY blocks!
Max blocks = 500 × 200 × 100 = 10,000,000 (10 MILLION!)
```

### The Restructure Process: SPLIT

```
DENSE → SPARSE: BLOCKS ARE SPLIT

Before (1 block for US_East, Widget):
┌──────────────────────────────────────────────────────────────┐
│ Block: Entity=US_East, Product=Widget                         │
│ ┌────────────────────────────────────────────────────────────┐│
│ │ Revenue:   [Jan=100, Feb=120, ..., Dec=200, Q1=350, ...]  ││
│ │ COGS:      [Jan=50,  Feb=60,  ..., Dec=100, Q1=170, ...]  ││
│ │ Headcount: [Jan=10,  Feb=10,  ..., Dec=12,  Q1=10, ...]   ││
│ │ ...                                                        ││
│ │ 100 accounts × 17 periods = 13.3 KB                       ││
│ └────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘

After (100 separate tiny blocks!):
┌───────────┐ ┌───────────┐ ┌───────────┐     ┌───────────┐
│ Revenue   │ │ COGS      │ │ Headcount │ ... │ Acct #100 │
│ 17 periods│ │ 17 periods│ │ 17 periods│     │ 17 periods│
│ 136 bytes │ │ 136 bytes │ │ 136 bytes │     │ 136 bytes │
└───────────┘ └───────────┘ └───────────┘     └───────────┘

1 block → 100 blocks (100× more blocks)
13.3 KB → 136 bytes (100× smaller per block)
But: 100 × 136 = 13,600 bytes ≈ same total data

HOWEVER: 100 INDEX ENTRIES instead of 1
         100 BLOCK HEADERS instead of 1
         Revenue - COGS = Gross Profit now requires reading 3 SEPARATE BLOCKS
```

---

## 8.4 The "Block Explosion" Problem

The most dangerous scenario is making a **large dimension dense** when it should be sparse:

### Case Study: Making Entity (1,000 members) Dense

```
BEFORE (Entity is Sparse — CORRECT):
  Dense: Account(100), Period(17)
  Sparse: Entity(1000), Product(200)
  
  Block size = 100 × 17 × 8 = 13.3 KB
  Max blocks = 1000 × 200 = 200,000
  Actual blocks (5% density) = 10,000
  Total data = 10,000 × 13.3 KB = 133 MB ✅

AFTER (Entity changed to Dense — WRONG!):
  Dense: Account(100), Period(17), Entity(1000)  ← Entity now dense!
  Sparse: Product(200)
  
  Block size = 100 × 17 × 1000 × 8 = 13,600,000 bytes = 13 MB PER BLOCK! ❌
  Max blocks = 200 (only Product is sparse)
  Actual blocks (90% density) = 180
  Total data = 180 × 13 MB = 2.3 GB

Problems:
  ❌ Each block is 13 MB → cannot fit many blocks in Data Cache
  ❌ Loading ONE block requires 13 MB of RAM
  ❌ Block density is < 5% → 95% of each block is #Missing
  ❌ Calculation within a 13 MB block is slow (huge array)
  ❌ Block compression is inefficient (too much #Missing)
  ❌ I/O for each block read/write is massive
  
  This would CRIPPLE the database performance.
```

### Case Study: Making Account (100 members) Sparse When It Should Be Dense

```
BEFORE (Account is Dense — CORRECT):
  Dense: Account(100), Period(17)
  Sparse: Entity(1000), Product(200)
  
  Block size = 100 × 17 × 8 = 13.3 KB
  Max blocks = 1000 × 200 = 200,000
  Actual blocks = 10,000

AFTER (Account changed to Sparse — WRONG!):
  Dense: Period(17) only
  Sparse: Entity(1000), Product(200), Account(100)
  
  Block size = 17 × 8 = 136 bytes ← TINY!
  Max blocks = 1000 × 200 × 100 = 20,000,000 (20 MILLION) ❌
  Actual blocks = 10,000 × 50 (avg accounts per entity/product) = 500,000

Problems:
  ❌ 500,000 blocks with 136 bytes each = huge index overhead
  ❌ Block header (~48 bytes) per block → 35% overhead on 136-byte blocks
  ❌ Index file becomes enormous (500K entries × 32 bytes = 16 MB)
  ❌ Revenue - COGS = Gross Profit requires reading 3 SEPARATE BLOCKS
     instead of calculating within 1 block (100× slower for account calcs!)
  ❌ Period aggregation (Jan+Feb+Mar=Q1) still works, but account formulas
     now cross blocks — turning fast intra-block calcs into slow inter-block calcs
```

---

## 8.5 Impact Comparison Matrix

| Metric | Account Dense (Correct) | Account Sparse (Wrong) | Impact Factor |
|--------|------------------------|----------------------|---------------|
| Block Size | 13,600 bytes | 136 bytes | 100× smaller |
| Total Blocks | 10,000 | 500,000 | 50× more |
| Index Size | ~400 KB | ~16 MB | 40× larger |
| Account Calc Time | ~2 seconds | ~200 seconds | 100× slower |
| Period Calc Time | ~2 seconds | ~2 seconds | Same |
| Data Load Time | ~5 minutes | ~30 minutes | 6× slower |
| CALC ALL Time | ~10 minutes | ~4 hours | 24× slower |
| Memory Usage | ~2 GB | ~4 GB | 2× more |

| Metric | Year Sparse (Correct) | Year Dense (Acceptable) | Impact Factor |
|--------|----------------------|------------------------|---------------|
| Block Size | 13,600 bytes | 68,000 bytes | 5× larger |
| Total Blocks | 50,000 | 10,000 | 5× fewer |
| Index Size | ~2 MB | ~400 KB | 5× smaller |
| Year Calc Time | ~30 seconds | ~5 seconds | 6× faster |
| Total CALC ALL | ~10 minutes | ~8 minutes | Slightly faster |

> **Key insight**: Making Year dense when it's currently sparse can IMPROVE performance if the block size stays in the sweet spot. But making Entity dense is ALWAYS wrong.

---

## 8.6 Decision Framework: When Is Interchange Acceptable—

### Acceptable: Sparse → Dense

```
✅ ACCEPTABLE when ALL of these are true:
  1. The dimension has < 20 members
  2. The resulting block size stays < 200 KB
  3. The dimension has high data density (>50%)
  4. You need intra-block calculations on this dimension
  5. Making it dense reduces total block count significantly

Example:
  Year (5 members): Sparse → Dense
  Before: 50,000 blocks × 13 KB = 650 MB, 5 years of data in separate blocks
  After:  10,000 blocks × 65 KB = 650 MB, year calculations are intra-block
  ✅ Acceptable — block size is fine, fewer blocks, faster year calcs
```

### Never Acceptable: Making a Large Dimension Dense

```
❌ NEVER ACCEPTABLE:
  1. Entity (100+ members) → Dense
  2. Product (50+ members) → Dense
  3. Employee (any size) → Dense
  4. Any dimension that would push block size > 200 KB
  5. Any dimension with < 10% data density

These would cause block explosion and cripple the database.
```

### Sometimes Acceptable: Dense → Sparse

```
⚠️ SOMETIMES ACCEPTABLE when:
  1. The dimension has grown beyond 100 members
  2. Block size has exceeded 200 KB
  3. Data density for this dimension has dropped below 30%
  4. You don't need intra-block calculations on this dimension

Example:
  Account has grown from 50 to 500 members over time.
  Block size: 500 × 17 × 8 = 68 KB per block
  But block density dropped to 5% (most accounts are #Missing for most entities)
  Consider: Keep dense but use Dynamic Calc for rare accounts
  Or: Split into two dimensions (measures vs calculations)
```

---

## 8.7 The Restructure Process for Sparse↔Dense Change

### What Essbase Does During This Restructure

```
SPARSE → DENSE CHANGE:

1. ████ LOCK DATABASE (exclusive)
2. ████ CALCULATE NEW BLOCK LAYOUT
   - New block size = old_block_size × members_in_newly_dense_dim
   - New sparse key = old sparse key WITHOUT the newly dense dimension
3. ████ GROUP EXISTING BLOCKS BY NEW SPARSE KEY
   - All blocks that only differ in the newly-dense dimension
     must be MERGED into a single block
   - Example: Blocks for FY20, FY21, FY22, FY23, FY24 (same Entity/Product)
     → merge into ONE block
4. ████ FOR EACH GROUP:
   a. Allocate new block (larger size)
   b. Initialize with #Missing
   c. Copy data from each old block into correct position in new block
   d. Delete old blocks
5. ████ REBUILD INDEX (.IND)
   - Fewer entries (blocks were merged)
   - New block keys (fewer sparse dims)
6. ████ REBUILD PAGE FILES (.PAG)
   - New block sizes
   - All data rewritten
7. ████ UNLOCK DATABASE

Duration: O(total_data_volume) — must read and rewrite ALL data
```

```
DENSE → SPARSE CHANGE:

1. ████ LOCK DATABASE (exclusive)
2. ████ CALCULATE NEW BLOCK LAYOUT
   - New block size = old_block_size / members_in_newly_sparse_dim
   - New sparse key = old sparse key PLUS the newly sparse dimension
3. ████ SPLIT EACH EXISTING BLOCK
   - Each old block produces N new blocks (N = members in newly sparse dim)
   - But only create blocks where data exists (skip all-#Missing)
4. ████ FOR EACH OLD BLOCK:
   a. For each member of newly-sparse dimension:
      - Extract cells for this member from old block
      - If ALL cells are #Missing → skip (don't create block)
      - Otherwise → create new block, write extracted cells
   b. Delete old block
5. ████ REBUILD INDEX (.IND)
   - Many more entries (blocks were split)
   - New block keys (more sparse dims)
6. ████ REBUILD PAGE FILES (.PAG)
   - New block sizes
   - All data rewritten
7. ████ UNLOCK DATABASE

Duration: O(total_data_volume) — must read and rewrite ALL data
         Plus index rebuild for potentially millions more entries
```

---

## 8.8 Risks and Mitigation

### Risk 1: Restructure Runs Out of Disk Space

```
Problem: During restructure, Essbase creates NEW files before deleting OLD files.
         This temporarily requires 2× the disk space.

Mitigation:
  - Ensure 2× current database size is available as free disk space
  - Export data before restructure (as backup)
  - Monitor disk space during restructure
```

### Risk 2: Restructure Takes Too Long

```
Problem: Restructure for a large database can take hours.
         Database is OFFLINE during restructure.

Mitigation:
  - Schedule during maintenance window
  - Export data first (so you can rebuild if needed)
  - Consider doing it in stages (partial changes)
  - For very large databases, consider:
    1. Export data to flat file
    2. Delete database
    3. Create new database with correct outline
    4. Load data
```

### Risk 3: Restructure Fails or Is Interrupted

```
Problem: If restructure fails mid-way, database may be corrupted.

Mitigation:
  - ALWAYS take a backup before restructure
  - Essbase keeps .OTL.KEEP (outline backup)
  - Export data to flat file before any structural change
  - Have a recovery plan:
    1. Restore from backup
    2. Or: Rebuild from exported data
```

### Risk 4: Post-Restructure Performance Issues

```
Problem: After restructure, performance may be different than expected.

Mitigation:
  - Test on a COPY of the database first
  - Compare block size, block count, and calc times before/after
  - Monitor cache usage after restructure
  - Be prepared to revert if necessary
```

---

## 8.9 Before-and-After Checklist

Before making any sparse↔dense change, answer these questions:

```
CHECKLIST:

□ What is the CURRENT block size—
  Current: ________ bytes

□ What will the NEW block size be—
  New: ________ bytes
  Is it between 8 KB and 200 KB— □ Yes □ No

□ What is the CURRENT block count—
  Current: ________ blocks

□ What will the ESTIMATED NEW block count be—
  New: ________ blocks
  Is this reasonable— □ Yes □ No

□ What is the CURRENT total database size—
  Current: ________ MB

□ What will the ESTIMATED NEW database size be—
  New: ________ MB
  Is there enough disk space (need 2× during restructure)— □ Yes □ No

□ How will calculations be affected—
  Dimension being changed: ________
  Will calculations on this dimension be intra-block or inter-block—
  □ Intra-block (dense) → faster calc on this dimension
  □ Inter-block (sparse) → slower calc on this dimension

□ Have you backed up the database—
  □ Outline exported
  □ Data exported
  □ Full backup taken

□ Is there a maintenance window available—
  Estimated restructure time: ________ hours
  Window available: ________ hours

□ Have you tested on a non-production copy—
  □ Yes, results: ________
  □ No → DO NOT PROCEED ON PRODUCTION
```

---

## Summary

> **Changing a dimension from Sparse → Dense MERGES blocks (fewer but larger blocks). Changing Dense → Sparse SPLITS blocks (more but smaller blocks). Both operations trigger a FULL RESTRUCTURE that reads and rewrites ALL data. Making a large dimension dense causes "block explosion" with massive blocks that cripple performance. Making a calculation-heavy dimension sparse forces cross-block calculations that are 100× slower. ALWAYS check block size (8-200 KB), block count, and test on a copy before making this change in production. Have a backup plan.**

---

**← Previous:** [07 — Data Operations and Performance](./07_Data_Operations_and_Performance.md)  
**Next →** [09 — EPM Forms, Rules, and Data Storage](./09_EPM_Forms_Rules_Data_Storage.md)
