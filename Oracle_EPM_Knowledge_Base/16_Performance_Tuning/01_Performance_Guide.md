# Performance Tuning — Complete Guide

> **Section:** 16 — Performance Tuning  
> **File:** 01 — Performance Guide  
> **Difficulty:** Intermediate → Architect  
> **Prerequisites:** [01_Essbase_Overview](../07_Essbase_Architecture/01_Essbase_Overview.md), [02_Essbase_Storage_and_Performance](../07_Essbase_Architecture/02_Essbase_Storage_and_Performance.md)

---

## Why Performance Tuning Matters

A well-tuned EPM application delivers sub-second form opens and fast calculations. A poorly tuned one frustrates users with 30-second form loads and hour-long calculations. The difference is almost always in **design decisions**, not hardware.

---

## The Performance Stack

Performance in EPM Cloud depends on four layers:

```
Layer 1: Application Design (dimensions, hierarchies, storage)
  ↓
Layer 2: Calculation Design (FIX scope, rule structure)
  ↓
Layer 3: Form and Report Design (retrieval scope)
  ↓
Layer 4: Infrastructure (managed by Oracle in Cloud)
```

You control Layers 1–3. Oracle manages Layer 4.

---

## Layer 1: Application Design

### Sparse vs Dense Optimization

The most impactful design decision is which dimensions are sparse and which are dense:

| Dimension | Typical Storage | Why |
|-----------|----------------|-----|
| Account | **Dense** | Most accounts have values across entities |
| Period | **Dense** | All periods typically populated |
| Entity | **Sparse** | Not all entities have all data |
| Scenario | **Sparse** | Budget/Actual/Forecast are separate data sets |
| Version | **Sparse** | Working/Final are separate |
| Year | **Sparse** | Each year is independent |
| Product | **Sparse** | Not all products sold everywhere |

**Rule of thumb:** Dense dimensions define what's inside a block. Sparse dimensions define how many blocks exist.

### Block Size

The optimal block size depends on the BSO storage type:

| Block Size | Performance | Memory |
|------------|-------------|--------|
| < 10 KB | Overhead per block too high | Low |
| 10–100 KB | **Optimal range** | Moderate |
| 100 KB–1 MB | Acceptable | Higher |
| > 1 MB | Retrieval slows | May cause issues |

Block size = product of all dense dimension members. If Account has 500 members and Period has 12, block size = 500 × 12 × 8 bytes = ~47 KB (optimal).

> [!TIP]
> Check your block size: Navigator → Application → Overview → Database Properties. If it's > 1 MB, consider moving a dense dimension to sparse.

### Hierarchy Depth and Width

| Issue | Symptom | Fix |
|-------|---------|-----|
| Deep hierarchy (> 8 levels) | Slow aggregation | Flatten where possible |
| Wide hierarchy (> 100 children) | Slow outline operations | Use attribute dimensions for filtering |
| Too many sparse dimensions | Block explosion | Consolidate or use attribute dimensions |

---

## Layer 2: Calculation Optimization

### FIX Statement Best Practices

1. **Always FIX on sparse dimensions** — Scenario, Version, Year, Entity
2. **Fix on specific members**, not @DESCENDANTS of large parents
3. **Use @LEVMBRS(dim, 0)** to target only leaf members
4. **Avoid empty FIX** statements (zero members match)

### SET Commands for Performance

```
/* Recommended performance SET commands */
SET CALCPARALLEL 4;         /* Enable parallel (2-8 threads) */
SET CALCTASKDIMS 2;         /* Dimension split granularity */
SET LOCKBLOCK ON;           /* Lock blocks during calc */
SET UPDATECALC OFF;         /* Recalculate all, not just dirty */
```

### Calculation Patterns — Fast vs Slow

| Pattern | Speed | Why |
|---------|-------|-----|
| Calc script with tight FIX | ⚡ Fast | Processes only needed blocks |
| Groovy generating dynamic FIX | ⚡ Fast | Context-specific scope |
| Calc script without FIX | 🐌 Slow | Processes entire database |
| Groovy cell-by-cell iteration | 🐌 Slow | JVM overhead per cell |
| Nested IF statements (many) | 🐌 Slow | CPU-intensive |

### Aggregation Optimization

```
/* Fast: Aggregate specific dimension */
FIX("Budget", "Working", &CurrYear)
    AGG("Entity");
ENDFIX

/* Slow: Aggregate everything */
CALC ALL;
```

---

## Layer 3: Form Design

### Retrieval Optimization

| Setting | Impact | Recommendation |
|---------|--------|---------------|
| **Suppress missing rows** | Fewer rows retrieved | ✅ Always enable |
| **Suppress missing columns** | Fewer columns | ✅ Enable when appropriate |
| **Suppress missing blocks** | Skips empty blocks entirely | ✅ Enable in large applications |
| **Enable caching** | Reuses previous retrieval | ✅ Enable for static forms |
| **Row count** | Controls page size | Limit to < 500 visible rows |

### Smart View Performance

| Tip | Why |
|-----|-----|
| Use forms, not ad hoc, for regular tasks | Forms are pre-optimized |
| Limit ad hoc retrieval range | Don't expand entire hierarchies |
| Enable "Only submit modified rows" | Reduces network traffic |
| Close unused Smart View connections | Each holds server resources |

---

## BSO vs Hybrid vs ASO Performance

| Feature | BSO | Hybrid BSO | ASO |
|---------|-----|------------|-----|
| Retrieval speed (large) | Slow | Fast (queries) | Very fast |
| Calculation speed | Fast (write) | Fast | Fast (aggregation) |
| Write-back | ✅ Native | ✅ Native | ❌ Limited |
| Real-time aggregation | ❌ Pre-calculated | ✅ Dynamic | ✅ Dynamic |
| Data volume | Medium | Large | Very large |
| Best for | Input/planning | Mixed use | Reporting/analysis |

### Hybrid BSO — Best of Both Worlds

Hybrid BSO combines BSO's write-back capability with ASO's dynamic query performance:

- **Dense dimensions** can be set to "Dynamic Calc" — calculated on-the-fly during retrieval
- **Sparse intersections** still use traditional BSO storage
- **Result:** Dramatically faster form opens for large applications

> [!IMPORTANT]
> Converting from BSO to Hybrid is a one-way operation in EPM Cloud. Once converted, you cannot revert. [Oracle Documented]

---

## Common Performance Issues and Fixes

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| Form takes 30+ seconds to open | Too many rows/columns, no suppression | Enable suppress missing, reduce scope |
| Calculation runs for hours | No FIX statement, processing entire DB | Add targeted FIX on sparse dims |
| Database refresh very slow | Many sparse dimension changes | Batch changes, schedule off-hours |
| Block count exploding | SET CREATEBLOCKONEQ left ON globally | Only enable within targeted FIX |
| Smart View times out | Retrieving too much data | Use forms instead of ad hoc |
| Aggregation slow | Too many hierarchy levels | Use parallel AGG, flatten hierarchies |

---

## Performance Monitoring

| Tool | What It Shows |
|------|--------------|
| **Job Console** | Rule execution times, errors |
| **Application Audit** | Who did what, when |
| **Activity Reports** | User activity patterns |
| **Database Properties** | Block count, block size, data density |
| **EPM Automate `provideLog`** | Detailed server logs |

---

## Quick Recall

1. **What is the most impactful performance design decision?** → Sparse vs dense dimension assignment.
2. **What is the optimal block size?** → 10–100 KB.
3. **Why are FIX statements critical for performance?** → They limit which blocks Essbase loads from disk.
4. **What does Hybrid BSO provide?** → BSO write-back + ASO dynamic query performance.
5. **What's the fastest way to speed up slow forms?** → Enable suppress missing rows/columns/blocks.

**Teach-back prompt:** Explain to a colleague why a calculation that takes 2 seconds with `FIX("Budget", "FY26")` might take 45 seconds without any FIX statement.

---

## Source Provenance

| Source | Files |
|--------|-------|
| Claude | `16_Performance/` |
| ChatGPT | `Essbase_Internal_Architecture/` files 11, 14-17 (performance and tuning), `Calc Manager/05_Calculation_Engine_and_Performance/` |
| Gemini | Essbase performance files (mirrors ChatGPT) |
| Oracle | [Optimizing EPM Cloud Performance](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfadm/) |

