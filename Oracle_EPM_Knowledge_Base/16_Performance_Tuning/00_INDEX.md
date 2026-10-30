# Performance Tuning

> Identifying and resolving performance bottlenecks in EPM Cloud applications — from Essbase caching to form design to calculation optimization.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | Performance Tuning Guide (coming) | Essbase cache tuning, block optimization, form performance, calc script efficiency, ASO tuning |

---

## Performance Levers

| Area | Key Settings / Actions |
|:---|:---|
| **Essbase Caching** | INDEXCACHESIZE, DATACACHESIZE, DYNCALCCACHESIZE |
| **Block Size** | Dense/Sparse dimension assignment, Dynamic Calc on parents |
| **Calculation Speed** | CALCPARALLEL, CALCTASKDIMS, FIX scope reduction |
| **Form Performance** | Suppress missing data, limit row count, minimize Smart Push scope |
| **Data Load Speed** | Use Data Integration (bulk) over @XWRITE (per-cell) |
| **Fragmentation** | Periodic export/reimport, outline restructure |

---

**Provenance:** Source material from Claude `16_Performance/`, ChatGPT Essbase performance files, Gemini equivalents.
