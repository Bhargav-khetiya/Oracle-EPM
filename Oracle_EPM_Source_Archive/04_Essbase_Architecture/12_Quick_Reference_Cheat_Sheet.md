# 12 — Quick Reference and Cheat Sheet

---

## 12.1 One-Page Summary: How Essbase BSO Works

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    ESSBASE BSO — HOW IT WORKS                             │
│                                                                          │
│  1. DATA is stored in BLOCKS (not tables/rows)                            │
│  2. Each BLOCK = fixed-size array of cells defined by DENSE dimensions    │
│  3. SPARSE dimensions determine WHICH blocks exist                        │
│  4. BLOCKS are located via INDEX files (.IND) — B-tree                    │
│  5. BLOCKS are stored in PAGE files (.PAG) — compressed binary            │
│  6. Forms/Rules = RELATIONAL DB | Data = ESSBASE (.PAG)                   │
│  7. Optimal outline = HOURGLASS shape (large sparse → dense → small sparse)│
│  8. Block size sweet spot = 8 KB — 200 KB                                 │
│  9. Three caches: INDEX CACHE, DATA CACHE, DATA FILE CACHE                │
│ 10. Dense calc = fast (in-memory) | Sparse calc = slower (cross-block)    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 12.2 Key Formulas

```
BLOCK SIZE (bytes):
  = (Dense_Dim1_stored × Dense_Dim2_stored × ... × Dense_DimN_stored) × 8

POTENTIAL BLOCKS:
  = Sparse_Dim1_stored × Sparse_Dim2_stored × ... × Sparse_DimN_stored

ACTUAL BLOCKS:
  = Potential_Blocks × Data_Density%

ESTIMATED DATABASE SIZE:
  = Actual_Blocks × Avg_Compressed_Block_Size

INDEX FILE SIZE (estimate):
  ≈ Actual_Blocks × 40 bytes

CELLS PER BLOCK:
  = Block_Size / 8

BLOCK DENSITY:
  = (Cells_with_data_in_block / Total_cells_in_block) × 100%

DATABASE DENSITY:
  = (Actual_blocks / Potential_blocks) × 100%

DATA CACHE UTILIZATION:
  = Data_Cache_Size / (Actual_Blocks × Uncompressed_Block_Size) × 100%
```

---

## 12.3 Sparse vs Dense Decision Tree

```
Is the member count ≤ 30?
├── YES → Is data density > 50%?
│         ├── YES → Does making it dense keep block size < 200 KB?
│         │         ├── YES → ✅ DENSE
│         │         └── NO  → ⚠️ SPARSE (block would be too large)
│         └── NO  → Is it a calculation-heavy dimension (Account, Period)?
│                   ├── YES → ✅ DENSE (intra-block calc benefit outweighs density)
│                   └── NO  → ✅ SPARSE
└── NO  → ✅ SPARSE (almost always)
```

---

## 12.4 Hourglass Quick Reference

```
ORDER (top to bottom):
  1. LARGEST Sparse dimension
  2. 2nd largest Sparse
  3. ... (descending sparse by member count)
  ─── Dense border ───
  4. LARGEST Dense dimension
  5. 2nd largest Dense
  6. Smallest Dense
  ─── Dense border ───
  7. Smaller Sparse dimension
  8. SMALLEST Sparse dimension
```

---

## 12.5 File Types Quick Reference

| Extension | Name | Contents | Location |
|-----------|------|----------|----------|
| `.OTL` | Outline | Dimensions, members, hierarchies, formulas | Essbase server filesystem |
| `.IND` | Index | B-tree: sparse combos → block locations | Essbase server filesystem |
| `.PAG` | Page/Data | Compressed data blocks with cell values | Essbase server filesystem |
| `.ESM` | Metadata | Database config, security, properties | Essbase server filesystem |
| `.TCT` | Transaction Control | Transaction log, concurrency control | Essbase server filesystem |
| `.CSC` | Calc Script | Business rule/calculation script source | Essbase server filesystem |
| `.RUL` | Rules File | Data load/dimension build rules | Essbase server filesystem |
| `.OTL.KEEP` | Outline Backup | Pre-restructure outline backup | Essbase server filesystem |

---

## 12.6 Where Things Are Stored — Quick Map

| Component | Storage Location |
|-----------|-----------------|
| Cell data (numbers) | Essbase .PAG files |
| Dimension hierarchy | Essbase .OTL + Relational DB |
| Data forms | Relational DB (HSP_FORM_*) |
| Business rules | Relational DB + Essbase .CSC |
| Task lists | Relational DB (HSP_TASKLIST) |
| Smart Lists | Relational DB (HSP_SMARTLIST) |
| Security/access | Relational DB (HSP_ACCESS_*) |
| Substitution variables | Essbase (in-memory + .ESM) |
| Exchange rates | Relational DB (HSP_EXCHRATE) |
| Approval/workflow status | Relational DB (HSP_PM_STATUS) |
| Cell notes/text | Relational DB (HSP_TEXT) |
| Supporting details | Relational DB (HSP_SUPPORT_DET) |

---

## 12.7 Cache Configuration Quick Reference

| Cache | Config Setting | Default | Recommended |
|-------|---------------|---------|-------------|
| Index Cache | `INDEXCACHESIZE` | 1 MB | ≥ Total .IND file size |
| Data Cache | `DATACACHESIZE` | 3 MB | As large as RAM allows |
| Data File Cache | `DATAFILECACHESIZE` | 8 files | Total .IND + .PAG files × 2 |

### Target Hit Ratios

| Cache | Minimum Acceptable | Good | Excellent |
|-------|-------------------|------|-----------|
| Index Cache | > 90% | > 95% | > 99% |
| Data Cache | > 70% | > 85% | > 95% |

---

## 12.8 Performance Impact Matrix

| Factor | Performance Impact | Effort to Fix |
|--------|-------------------|--------------|
| Wrong sparse/dense assignment | ⚡⚡⚡⚡⚡ (Extreme) | HIGH (restructure) |
| Block size > 1 MB | ⚡⚡⚡⚡⚡ (Extreme) | HIGH (redesign outline) |
| Data Cache too small | ⚡⚡⚡⚡ (High) | LOW (config change) |
| Non-hourglass order | ⚡⚡⚡ (Medium) | MEDIUM (restructure) |
| Index Cache too small | ⚡⚡⚡ (Medium) | LOW (config change) |
| No FIX in calc scripts | ⚡⚡⚡ (Medium) | LOW (script change) |
| Unsorted data loads | ⚡⚡ (Moderate) | LOW (sort data) |
| Fragmented .PAG files | ⚡⚡ (Moderate) | MEDIUM (restructure) |
| Empty blocks not cleared | ⚡ (Low) | LOW (CLEARBLOCK) |
| Wrong compression type | ⚡ (Low) | LOW (config change) |

---

## 12.9 Common Mistakes and Fixes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Entity as dense | Blocks > 5 MB, slow everything | Change Entity to sparse |
| Account as sparse | Millions of tiny blocks, slow formulas | Change Account to dense |
| No Dynamic Calc on upper levels | Database too large, slow calc | Set upper-level accounts to Dynamic Calc |
| CALC ALL instead of targeted calc | Calculates everything, hours of calc time | Use FIX...ENDFIX with specific members |
| Data Cache = default (3 MB) | Constant disk I/O, slow everything | Increase to GB range |
| Loading unsorted data | Data load takes hours | Pre-sort data by sparse keys |
| Not running CLEARBLOCK | Empty blocks slow calculations | Run CLEARBLOCK regularly |
| Too many stored members | Block size too large | Use Dynamic Calc for calculated members |
| Not backing up before restructure | Corrupted database, data loss | Always export before structural changes |

---

## 12.10 Essbase Operations Impact Reference

| Operation | Blocks Read | Blocks Written | Blocks Created | Database Offline? |
|-----------|-------------|---------------|----------------|-------------------|
| Single cell retrieve | 1 | 0 | 0 | No |
| Form open (20 cells) | 1-5 | 0 | 0 | No |
| Form save (10 cells) | 1-3 | 1-3 | 0-1 | No |
| Data load (100K records) | 5K-50K | 5K-50K | 0-5K | No |
| CALC DIM (1 dimension) | All blocks | Modified blocks | Parent blocks | No |
| CALC ALL | All blocks | All blocks | All parent blocks | No |
| CLEARBLOCK | All blocks (scan) | 0 | 0 | No |
| Dense restructure | All blocks | All blocks | 0 | **YES** |
| Full restructure | All blocks | All blocks | 0 | **YES** |
| Export to file | All blocks | 0 | 0 | No |

---

## 12.11 Troubleshooting Quick Guide

```
PROBLEM: Form is slow to open
CHECK:
  □ How many blocks does the form need? (check member combinations)
  □ Is Data Cache large enough? (check hit ratio)
  □ Are there Dynamic Calc members on the form? (each one recalculates)
  □ Is the Essbase server under load? (check concurrent users)
  □ Is the network slow? (check latency)

PROBLEM: CALC ALL takes too long
CHECK:
  □ Is the outline in hourglass order? (check dimension ordering)
  □ Are there too many empty blocks? (run CLEARBLOCK)
  □ Is CALCPARALLEL enabled? (check essbase.cfg)
  □ Can you use FIX instead of CALC ALL? (target specific data)
  □ Is Data Cache large enough? (check hit ratio)
  □ Are there unnecessary stored members? (use Dynamic Calc)

PROBLEM: Data load is slow
CHECK:
  □ Is the data file sorted by sparse keys? (pre-sort!)
  □ Is the rules file doing too many transformations?
  □ Is DLTHREADSPREPARE set? (parallel loading)
  □ Is Data Cache large enough?
  □ Is the source local or over the network?

PROBLEM: Database is too large on disk
CHECK:
  □ Are there empty blocks? (CLEARBLOCK)
  □ Is compression enabled? (check DATACOMPRESSIONTYPE)
  □ Are .PAG files fragmented? (check actual vs expected size)
  □ Is the block size appropriate? (check dense member counts)
  □ Are there too many upper-level blocks? (Dynamic Calc upper levels)

PROBLEM: Essbase crashes / out of memory
CHECK:
  □ Is Data Cache + Index Cache > available RAM?
  □ Is CALCPARALLEL too high? (each thread uses memory)
  □ Are blocks too large? (large blocks = more memory per operation)
  □ Too many concurrent connections? (check SERVERTHREADS)
  □ Is the OS swapping? (check page file usage)
```

---

## 12.12 Glossary

| Term | Definition |
|------|-----------|
| **ASO** | Aggregate Storage Option — read-only OLAP storage, computes on-the-fly |
| **Block** | Fixed-size array of cells formed by dense dimension intersections |
| **BSO** | Block Storage Option — read-write OLAP storage with pre-aggregation |
| **CALC ALL** | Default calculation that aggregates all dimensions bottom-to-top |
| **Cell** | Single data point at the intersection of all dimensions |
| **Compression** | Reducing block size on disk (Bitmap, RLE, ZLIB) |
| **Data Cache** | RAM area holding uncompressed data blocks |
| **Data File Cache** | Cache of open file handles to .PAG/.IND files |
| **Dense Dimension** | Defines the internal structure of each block |
| **Dynamic Calc** | Member whose value is calculated on retrieval, not stored |
| **Fragmentation** | Gaps in .PAG files from deleted/moved blocks |
| **Generation** | Level counting from TOP of hierarchy (Gen 1 = top) |
| **Hourglass** | Optimal outline ordering principle |
| **Index Cache** | RAM area holding B-tree index pages from .IND |
| **Index File (.IND)** | B-tree mapping sparse combos to block locations |
| **Input Block** | Block containing Level 0 (user-entered) data |
| **Label Only** | Member that exists for hierarchy but stores no data |
| **Level** | Level counting from BOTTOM of hierarchy (Level 0 = leaf) |
| **Level 0** | Leaf-level member — no children, input level |
| **LRU** | Least Recently Used — cache eviction policy |
| **MaxL** | Essbase administrative scripting language |
| **MDDB** | Multi-Dimensional Database |
| **Member** | Single element within a dimension |
| **MOLAP** | Multi-dimensional OLAP (data stored in cubes) |
| **Outline (.OTL)** | Metadata file defining all dimensions and members |
| **Page File (.PAG)** | Physical file containing compressed data blocks |
| **POV** | Point of View — fixed dimension selections in a form |
| **Restructure** | Process of reorganizing blocks after outline change |
| **ROLAP** | Relational OLAP (data stored in RDBMS tables) |
| **Shared Member** | Member that points to another member's data |
| **Sparse Dimension** | Determines which blocks exist (not all combos have data) |
| **Stored Member** | Member whose data occupies space in each block |
| **UDA** | User-Defined Attribute — tag on a member |
| **Upper-Level Block** | Block for non-leaf sparse member, created during aggregation |

---

## 12.13 Key Takeaways — The Top 10 Rules

```
1. ✅ Essbase = multidimensional blocks, NOT relational tables
2. ✅ Dense dims = block shape (small & populated)
3. ✅ Sparse dims = which blocks exist (large & sparse)
4. ✅ Block size must be 8 KB – 200 KB
5. ✅ Hourglass order: Large sparse → Dense → Small sparse
6. ✅ Index Cache ≥ total .IND size
7. ✅ Data Cache = as large as RAM allows
8. ✅ Use FIX...ENDFIX for targeted calculations
9. ✅ Pre-sort data loads by sparse keys
10. ✅ Forms/Rules in RDBMS, Data in Essbase .PAG files
```

---

**← Previous:** [11 — Kernel and Memory Architecture](./11_Kernel_and_Memory_Architecture.md)  
**⬆ Back to Index:** [00 — INDEX](./00_INDEX.md)
