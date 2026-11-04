# 13 — Hybrid BSO Engine: Architecture, Mechanics, & Tuning

---

## 13.1 What is the Hybrid BSO Engine—

Historically, Oracle Essbase forced architects to make a painful architectural compromise:
* **Block Storage Option (BSO)**: Supported complex procedural calculations, member formulas, allocations, and cross-dimensional math, but suffered from **slow aggregation times** and **block explosion** when sparse dimensions had high member counts.
* **Aggregate Storage Option (ASO)**: Aggregated millions of sparse members in sub-seconds, but **did not support procedural calculation scripts**, write-back planning forms, or complex business logic.

The **Hybrid BSO Engine** merges both worlds into a single kernel:
```
┌────────────────────────────────────────────────────────────────────────┐
│                        HYBRID BSO ARCHITECTURE                         │
├──────────────────────────────────┬─────────────────────────────────────┤
│        BLOCK STORAGE CORE        │          ASO MDX QUERY ACCELERATOR  │
├──────────────────────────────────┼─────────────────────────────────────┤
│ • Stored Level 0 input blocks    │ • Dynamic Sparse rollups calculated │
│ • Full Calc Manager script       │   in RAM without creating blocks.   │
│   support (@VAR, @PRIOR, FIX).   │ • Sub-second aggregation across     │
│ • Write-back planning forms.     │   massive sparse dimensions.        │
│ • Transactional data integrity.  │ • Solves dimensions using MDX sets. │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 13.2 The Physics of Hybrid Aggregation

In traditional BSO, if `Entity` (5,000 members) and `Product` (10,000 members) are Sparse, aggregating the cube requires running `CALC ALL` or `AGG(Entity, Product)`. This creates **millions of physical upper-level blocks on disk (`.PAG`)**, bloating database size from 200 MB to 45 GB.

### In Hybrid BSO:
1. All upper-level sparse members are marked as **`Dynamic Calc`**.
2. **Zero physical blocks are created on disk** for summary parents.
3. When a user queries `Total Entity` $\times$ `Total Product`, Essbase invokes the internal **ASO aggregation engine** inside the BSO kernel.
4. The engine reads Level 0 input blocks into the **Data Cache**, performs in-memory parallel aggregation, and returns the result instantly without writing a single byte to disk.

```
Traditional BSO:
  Level 0 Blocks (Disk) ──Batch AGG──► Upper Level Blocks (Disk .PAG) [MASSIVE BLOAT]

Hybrid BSO:
  Level 0 Blocks (Disk) ──Query Time──► In-Memory ASO Aggregator (RAM) [ZERO DISK BLOAT]
```

---

## 13.3 Configuration: `ASODYNAMICAGGINBSO`

In the `essbase.cfg` configuration file, the Hybrid engine is governed by:

```ini
ASODYNAMICAGGINBSO [appname [dbname]] NONE | PARTIAL | FULL
```

* **`NONE`**: Standard legacy BSO calculation engine. All dynamic sparse members are evaluated procedurally.
* **`PARTIAL`**: Hybrid engine optimizes simple aggregations (`+`, `-`, `~`), but reverts to legacy BSO for complex member formulas.
* **`FULL`** *(Default in modern EPM Cloud)*: Full Hybrid optimization enabled. All dynamic sparse hierarchies and supported formulas are accelerated using the ASO kernel.

---

## 13.4 Supported vs. Unsupported Functions in Hybrid BSO

While Hybrid BSO supports most calculation functions, certain complex time-series and procedural loops cannot be solved by the ASO engine. When an unsupported function is encountered, Essbase triggers a **Hybrid Calculation Exception** and falls back to slow BSO evaluation.

### Optimization Matrix:

| Function Category | Hybrid Optimized (Fast) ✅ | Non-Optimized (Fallback to BSO) ⚠️ |
| :--- | :--- | :--- |
| **Consolidation** | `+`, `-`, `~`, `^` standard rollups | Cross-dimensional division inside sparse formulas |
| **Logical Checks** | `@ISMBR`, `@ISANCEST`, `@ISDESC` | Complex nested recursive loops |
| **Mathematical** | Simple arithmetic (`+`, `-`, `*`, `/`) | `@SPLINE`, `@TREND` |
| **Time Series** | `@YTD`, `@QTD`, `@MTD` | `@PRIOR`, `@NEXT` across dynamic sparse axes |
| **Member Sets** | `@RELATIVE`, `@CHILDREN`, `@DESCENDANTS`| `@ANCESTOR` with negative offsets |

---

## 13.5 Solve Order in Hybrid BSO

In Hybrid BSO, because multiple dimensions are dynamic calc (e.g., `Account` is dynamic ratio, `Entity` is dynamic rollup, and `Period` is dynamic variance), **Solve Order** dictates the evaluation sequence:

```
┌─────────────────────────────────────────────────────────────┐
│                 SOLVE ORDER PRECEDENCE (0 - 127)            │
├─────────────────────────────────────────────────────────────┤
│ Rule: Dimension or Member with HIGHER Solve Order evaluates │
│       LAST, overwriting earlier calculations.               │
│                                                             │
│ Recommended Hierarchy:                                      │
│   • Base Dimensions (Entity, Dept, Product): Solve Order 0  │
│   • Time / Period Aggregations (Q1, YTD):    Solve Order 10 │
│   • Financial Accounts (Gross Profit, EBITDA): Solve Order 20│
│   • Ratios / Percentages (Gross Margin %):   Solve Order 30 │
│   • Currency Conversions & Reporting Views:  Solve Order 40 │
│   • Variance & Variance % (Act vs Bud):      Solve Order 50 │
└─────────────────────────────────────────────────────────────┘
```

#### Why Variance Must Have Highest Solve Order:
If `Variance %` has Solve Order 10 and `Gross Margin %` has Solve Order 30:
* The system calculates Variance % first, then Gross Margin % calculates over it, producing invalid variance percentages.
* Giving `Variance %` the highest Solve Order (50) ensures that Gross Margin % is calculated for Actual, Gross Margin % is calculated for Budget, and then the true variance is calculated between them.
