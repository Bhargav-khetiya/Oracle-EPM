# Essbase Architecture

> Essbase is the multidimensional calculation engine underneath Oracle EPM Cloud Planning. Understanding how it stores, indexes, and calculates data is essential for performance tuning and troubleshooting.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | [Essbase Overview](01_Essbase_Overview.md) | BSO vs ASO vs Hybrid, sparse/dense, blocks, hourglass principle, retrieval flow |
| 2 | [Essbase Storage and Performance](02_Essbase_Storage_and_Performance.md) | .OTL/.IND/.PAG files, block architecture, index/data caches, ASO load buffers, calculation engine, fragmentation, tuning |

---

## Key Concept Diagram

```
                    ESSBASE DATABASE
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
      OUTLINE         INDEX           PAGE
      (.OTL)          (.IND)          (.PAG)
      Blueprint       B-tree          Data blocks
      of dims &       mapping         with 8-byte
      members         sparse →        cells per
                      block loc.      intersection
```

## BSO vs ASO at a Glance

| Feature | BSO | ASO |
|:---|:---:|:---:|
| Data entry via forms | ✅ | ❌ (load buffers only) |
| Calc scripts | ✅ | ❌ (MDX only) |
| All consolidation operators | ✅ | Only +, ~ |
| Large-scale ad hoc reporting | Moderate | ✅ Excellent |
| Block storage | ✅ | Slices + views |

---

**Provenance:** Merged from ChatGPT `Essbase_Internal_Architecture/` (17 files), Claude `03_Essbase/`, Gemini equivalents. See [MERGE_MAP.md](../MERGE_MAP.md).
