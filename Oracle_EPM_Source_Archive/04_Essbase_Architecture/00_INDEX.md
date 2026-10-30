# 📖 Essbase Internal Architecture — The Complete Bible

> **Purpose**: This folder is the definitive, deep-dive reference for understanding how Oracle Essbase works behind the scenes — from the physics of data storage to the logic behind sparse/dense design, block mechanics, index/page files, the Hourglass Principle, and how EPM components interact with Essbase at the lowest level.

---

## 📂 Document Index

| # | File | Topic | Level |
|---|------|-------|-------|
| 01 | [What Is Essbase](./01_What_Is_Essbase.md) | Essbase overview, history, purpose, MOLAP vs ROLAP vs HOLAP, where Essbase fits in EPM | Foundation |
| 02 | [Essbase Data Storage Architecture](./02_Essbase_Data_Storage_Architecture.md) | How Essbase physically stores data — not relational, multidimensional cubes, files on disk | Core |
| 03 | [Sparse vs Dense — The Complete Guide](./03_Sparse_vs_Dense_Complete_Guide.md) | Why dimensions are sparse or dense, the logic behind it, data population patterns, combinatorics | Core |
| 04 | [Block Storage Deep Dive](./04_Block_Storage_Deep_Dive.md) | What blocks are, how they form, fixed vs variable size, memory layout, compression | Deep |
| 05 | [Index Files and Page Files](./05_Index_and_Page_Files.md) | .IND and .PAG files, how Essbase locates data, kernel-level read/write, caching | Deep |
| 06 | [The Hourglass Principle](./06_Hourglass_Principle.md) | Optimal outline design, why hourglass shape matters, performance impact | Design |
| 07 | [Data Operations and Performance](./07_Data_Operations_and_Performance.md) | How retrieval, calculation, data load, and aggregation work internally | Advanced |
| 08 | [Sparse-Dense Interchange Impact](./08_Sparse_Dense_Interchange_Impact.md) | What happens when you swap sparse↔dense, block explosion, restructuring, real examples | Critical |
| 09 | [EPM Forms, Rules, and Data Storage](./09_EPM_Forms_Rules_Data_Storage.md) | Where forms/rules/scripts are saved, relational vs Essbase storage, Planning repository | Integration |
| 10 | [Behind the Scenes — Complete Walkthrough](./10_Behind_The_Scenes_Complete.md) | End-to-end trace of what happens when a user enters data, saves a form, runs a calc | Master |
| 11 | [Essbase Kernel and Memory Architecture](./11_Kernel_and_Memory_Architecture.md) | Cache settings, index cache, data cache, data file cache, memory mapping | Expert |
| 12 | [Quick Reference and Cheat Sheet](./12_Quick_Reference_Cheat_Sheet.md) | One-page summaries, formulas, decision trees, common mistakes | Reference |
| 13 | [Hybrid BSO Engine Internals](./13_Hybrid_BSO_Engine_Internals.md) | BSO storage + ASO dynamic calc accelerator, ASODYNAMICAGGINBSO, supported functions | Advanced Kernel |
| 14 | [Compression Algorithms & Bitmaps](./14_Compression_Algorithms_and_Bitmaps.md) | Byte-by-byte Bitmap encoding, RLE, ZLIB, decompress overhead, decision matrix | Deep Physical |
| 15 | [Fragmentation & Corruption Recovery](./15_Fragmentation_Defrag_and_Corruption_Recovery.md) | The physics of .PAG file holes, defragmentation methods, index corruption recovery | Systems Admin |
| 16 | [Dynamic Calc Cache & MDX Query Engine](./16_Dynamic_Calc_Cache_and_MDX_Query_Engine.md) | Dynamic Calc Cache allocation, MDX compilation pipeline, NON EMPTY pushdown pruning, DFS dependency trees | Advanced Kernel |
| 17 | [Calculation Engine Internals & Parallelism](./17_Calculation_Engine_Internals_and_Parallelism.md) | Calc engine AST pipeline, CALCCACHE sizing math, CALCPARALLEL vs FIXPARALLEL, BOTTOMUP vs TOPDOWN block thrashing | High Performance Calc |

---

## 🎯 How to Use This Guide

1. **If you're new to Essbase**: Start with files `01` → `02` → `03` → `06`
2. **If you're designing an outline**: Read `03` → `06` → `08` → `04` → `13`
3. **If you're troubleshooting performance**: Read `04` → `05` → `07` → `11` → `14` → `15` → `16` → `17`
4. **If you need to understand EPM integration**: Read `09` → `10`
5. **If you want the complete picture**: Read everything in order `01` → `17`

---

## 🔑 Key Concepts at a Glance

```
Essbase = Multi-Dimensional Database (OLAP)
├── NOT a relational database (no SQL tables/rows/columns)
├── Data stored in BLOCKS (dense intersections)
├── Blocks located via INDEX files
├── Block data stored in PAGE files
├── Dimensions are either SPARSE or DENSE
│   ├── Dense → defines the SHAPE of each block
│   └── Sparse → defines WHICH blocks exist
├── Hourglass = Sparse dimensions large, Dense dimensions small
└── EPM Forms/Rules → stored in RELATIONAL DB (Planning repository)
    └── But DATA itself → stored in Essbase .PAG files
```

---

> **Version**: 1.0  
> **Last Updated**: October 2026  
> **Scope**: Oracle Essbase (BSO — Block Storage Option) with references to ASO where relevant
