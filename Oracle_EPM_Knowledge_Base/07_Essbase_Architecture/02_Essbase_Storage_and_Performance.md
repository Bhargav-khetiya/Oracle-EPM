# Essbase Storage and Performance

> **Prerequisites:** [Essbase Overview](01_Essbase_Overview.md)  
> **Sources merged:** ChatGPT Essbase_Internal_Architecture (files 02-06, 11, 14-17), Claude 03_Essbase, Gemini equivalents  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## The Three Pillars of Essbase Storage

Essbase is **not** relational. It does not use tables, rows, or SQL. It uses a proprietary binary storage format based on three pillars:

```
OUTLINE (.OTL)     = The blueprint — dimensions, members, hierarchies, properties
INDEX (.IND files)  = The table of contents — maps sparse combinations to block locations
PAGE (.PAG files)   = The book pages — contains actual data blocks with cell values

To find data:
  1. Essbase reads the OUTLINE to understand the structure
  2. Searches the INDEX for the sparse combination
  3. Reads the BLOCK from the PAGE file at the indexed location
  4. Returns the specific cell from within the block
```

### Physical File Layout

```
$ARBORPATH/app/<ApplicationName>/<DatabaseName>/
  ├── <DbName>.otl          ← Outline (structure definition)
  ├── <DbName>.ind          ← Primary index file
  ├── <DbName>.pag          ← Primary page/data file
  ├── ess00001.ind           ← Index overflow file 1
  ├── ess00001.pag           ← Page overflow file 1
  ├── ...                    ← More overflow files as needed
  ├── <DbName>.esm           ← Security/metadata
  ├── <DbName>.tct           ← Transaction control table
  └── <DbName>.otl.keep      ← Outline backup (pre-restructure)
```

Each .IND and .PAG file has a maximum size (default ~2GB). When exceeded, Essbase creates overflow files.

`[Oracle Documented]`

---

## The Block — Fundamental Unit of Storage

A **block** is a fixed-size multidimensional array formed by all **Dense dimensions**:

```
Dense dimensions: Account (100 members) × Period (17 members)
Block = 100 × 17 = 1,700 cells
Each cell = 8 bytes (double-precision floating point)
Block size = 1,700 × 8 = 13,600 bytes ≈ 13.3 KB
```

### Dense = Block SHAPE, Sparse = WHICH Blocks Exist

```
┌─────────────────────────────────────────────────────────┐
│ Dense dimensions → Define the SHAPE (size) of each      │
│                    block (same for ALL blocks)           │
│                                                         │
│ Sparse dimensions → Define WHICH blocks exist           │
│                     (only combinations with data)        │
└─────────────────────────────────────────────────────────┘

Example sparse dimensions:
  Entity: 500 × Product: 200 × Scenario: 3 × Version: 2 × Year: 5
  Maximum possible blocks = 3,000,000

  But only ~10% may have data → 300,000 actual blocks
  Total storage = 300,000 × 13.3 KB ≈ 3.9 GB
```

### Block Explosion

**Block explosion** occurs when sparse dimension cardinality grows unchecked, creating millions of mostly empty blocks:

```
Adding 1 new sparse member to a dimension with 500 members
= potentially 500 × (existing combinations) new blocks

Each block consumes at minimum:
  - 8 bytes per dense cell
  - ~200 bytes of index overhead
```

> [!CAUTION]
> Block explosion is the #1 performance killer in Essbase. Always check the potential block count impact before adding sparse members. Disable members in cubes where they're not needed.

`[Recommendation]`

---

## The Hourglass Principle

The "hourglass" is the optimal dimension design pattern for BSO cubes:

```
          ┌────────────────────────┐
          │  Few Dense dimensions  │  ← Narrow (small block size)
          │  (Account, Period)     │
          ├────────────────────────┤
          │     DATA BLOCKS        │  ← The "neck" of the hourglass
          │     (compact, fast)    │
          ├────────────────────────┤
          │ Many Sparse dimensions │  ← Wide (but sparse = only filled combos exist)
          │ (Entity, Product,     │
          │  Scenario, Year...)    │
          └────────────────────────┘
```

**The principle:** Keep Dense dimensions small (tight block) and Sparse dimensions large but sparsely populated. This minimizes memory usage and maximizes retrieval speed.

**Anti-pattern:** Making a large dimension Dense inflates every block, even blocks where most of that dimension's cells are `#MISSING`.

`[Recommendation]`

---

## Index Architecture (.IND)

The index file contains a **B-tree** structure that maps sparse dimension member combinations to physical block locations:

```
INDEX ENTRY:
  Key: [Entity=US_East, Product=Widget_A, Scenario=Actual, Year=FY26]
  Value: Page file #3, Offset 0x1A2B00, Block size 13,600 bytes

Search: O(log n) — fast even for millions of blocks
```

### Index Cache

The index cache keeps frequently accessed index entries in memory:

| Setting | Purpose |
|:---|:---|
| `INDEXCACHESIZE` | Memory allocated for index caching (bytes) |
| Default | ~1MB (often too small for production) |
| Recommendation | Size to hold the entire index in memory if possible |

When the index doesn't fit in memory, Essbase must read from disk for each uncached block lookup — dramatically slowing queries.

`[Oracle Documented]`

---

## Data/Page File Architecture (.PAG)

Page files store the actual data blocks. Key concepts:

### Compression

Essbase uses **bitmap compression** to reduce storage:
- Cells containing `#MISSING` are not stored — they're marked in a bitmap
- A block with 90% missing cells stores only 10% of the theoretical cell count
- Compression ratio depends on data density within blocks

### Data Cache

| Setting | Purpose |
|:---|:---|
| `DATACACHESIZE` | Memory for caching data blocks |
| `DATAFILECACHESIZE` | Maximum number of .PAG files open simultaneously |

`[Oracle Documented]`

---

## Calculation Engine

### BSO Calculation Passes

When you run `CALC ALL` or a calculation script:

1. **Outline order pass:** Essbase processes blocks in outline member order
2. **Intra-block calculation:** Formulas and consolidation within each block (Dense dims)
3. **Cross-block aggregation:** Rolling up Sparse dimensions across blocks
4. **Two-pass recalculation:** Members marked for Two-Pass are recalculated

### Parallelism

Essbase can parallelize calculations across CPU cores:

| Setting | Purpose |
|:---|:---|
| `CALCPARALLEL` | Enable parallel calculation (1 = on) |
| `CALCTASKDIMS` | Number of threads / parallel tasks |

### Dynamic Calc Cache

Dynamic Calc members are computed in RAM at query time and cached:

| Setting | Purpose |
|:---|:---|
| `DYNCALCCACHESIZE` | Memory for dynamic calculation cache |
| Too small | Repeated recalculation of the same formulas on each query |
| Too large | Steals memory from other caches |

`[Oracle Documented]`

---

## ASO (Aggregate Storage) Differences

| Feature | BSO | ASO |
|:---|:---|:---|
| **Storage** | Blocks in .PAG files | Data slices + materialized views |
| **Data Input** | Direct cell writes | Load buffers only (no form input to ASO) |
| **Calculation** | Calc scripts, business rules | MDX only (no calc scripts) |
| **Aggregation** | Stored or dynamic | Always dynamic (with optional materialized views) |
| **Consolidation Operators** | All 7 (+, -, *, /, %, ~, ^) | Only + and ~ |
| **Best For** | Interactive planning, data entry | Large-scale reporting, ad hoc queries |
| **Restructure** | Dense = slow, Sparse = fast | Fast (outline changes don't move data) |

### ASO Load Buffers

Data is loaded into ASO via load buffers:
1. Open a buffer (`EssBeginLoadBuffer`)
2. Stream data rows into the buffer
3. Commit the buffer as a new data slice
4. Optionally merge slices for optimal query performance

`[Oracle Documented]`

---

## Hybrid BSO

Oracle introduced **Hybrid BSO** to combine BSO's data entry capabilities with ASO-like dynamic aggregation:

- Upper-level members are **dynamically aggregated** (like ASO)
- Level 0 data is still stored in blocks (like traditional BSO)
- Reduces storage and improves query performance without migrating to ASO
- Enabled per cube in application settings

`[Oracle Documented]`

---

## Fragmentation and Maintenance

Over time, data updates create **fragmentation** in .PAG files — blocks are scattered across disk, with gaps from deleted/moved blocks.

### Defragmentation

```
Dense restructure:  Triggered by Dense dimension changes → rewrites ALL blocks
Sparse restructure: Triggered by Sparse dimension changes → rebuilds index only (fast)
Export/Import:      Export all data → clear → import = clean files (most thorough)
```

> [!TIP]
> Schedule periodic exports and reimports during maintenance windows to eliminate fragmentation in production databases with heavy update activity.

`[Recommendation]`

---

## Performance Tuning Quick Reference

| Issue | Check | Action |
|:---|:---|:---|
| Slow queries | Index cache too small | Increase `INDEXCACHESIZE` to fit full index |
| Slow calculations | Single-threaded | Enable `CALCPARALLEL`, increase `CALCTASKDIMS` |
| High memory usage | Oversized blocks | Verify Dense dimension choices; move large dims to Sparse |
| Block explosion | Too many sparse combos | Review custom dimension cardinality; disable unused cubes |
| Fragmentation | Frequent data updates | Schedule export/import maintenance |
| Slow dynamic calcs | Cache too small | Increase `DYNCALCCACHESIZE` |

---

## Quick Recall

1. **What determines block size?**
   → The product of all Dense dimension member counts × 8 bytes per cell.

2. **What causes block explosion?**
   → Every unique combination of Sparse dimension members can create a block. Adding members to Sparse dimensions multiplies potential blocks.

3. **Why is the Hourglass Principle important?**
   → It keeps blocks small (few Dense members) while allowing many analysis dimensions (Sparse), optimizing both memory and query performance.

4. **What's the difference between BSO and ASO?**
   → BSO stores data in blocks with full calc script support and direct data entry. ASO uses load buffers and dynamic aggregation for large-scale reporting.

---

**See also:**
- [Essbase Overview](01_Essbase_Overview.md) — BSO vs ASO concepts
- [Dimension Fundamentals](../08_Dimensions_and_Metadata/01_Dimension_Fundamentals.md) — Dense vs Sparse classification

