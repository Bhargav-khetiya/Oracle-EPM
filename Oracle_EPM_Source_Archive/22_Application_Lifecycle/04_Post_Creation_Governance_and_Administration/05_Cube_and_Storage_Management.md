# 🗄️ Cube & Storage Management — Master Guide
## BSO Hybrid vs ASO Architecture, Data Clearing, Outline Compaction & Slice Optimization

> **Navigation:** `Home → Application → Overview → Cubes`  
> **Role Requirement:** Service Administrator  
> **Scope:** Managing Essbase multidimensional storage engines, database compaction, slice merging, and data cleanup operations

---

## 🏗️ Dual-Engine Architecture: BSO Hybrid vs ASO

Oracle Cloud EPM applications leverage two distinct Essbase storage engines, often within the same application:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   ORACLE CLOUD EPM DUAL-ENGINE ARCHITECTURE                 │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ BLOCK STORAGE OPTION (BSO HYBRID)    │ AGGREGATE STORAGE OPTION (ASO)       │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ 🎯 Purpose: Input, Modeling & Calcs  │ 🎯 Purpose: Fast High-Volume Reports │
│ • Cubes: `Plan1`, `OEP_FS`, `OEP_WFP`│ • Cubes: `OEP_REP`                   │
│ • Complex procedural business rules  │ • Massive dimensionality (>15 dims)  │
│ • Sparse dynamic calcs evaluated     │ • Aggregations computed dynamically  │
│   in-memory via Hybrid engine        │   over stored incremental data slices│
│ • Write-back, sandbox & data forms   │ • Read-heavy reporting & dashboards  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 🧹 Clearing Cube Data: The 4 Operational Modes

Periodically, administrators must wipe bad loads, test data, or archived history.

**Navigation:** `Application → Overview → Actions (▼) → Clear Data`

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Clear Data                                                            ✖ │
├─────────────────────────────────────────────────────────────────────────┤
│ Target Cube: [ OEP_FS                                               ▼ ] │
│                                                                         │
│ Clear Scope:                                                            │
│   🔘 Clear All Data                                                     │
│       ⚠️ Wipes 100% of data blocks in the cube. Metadata remains.       │
│                                                                         │
│   🔘 Partial Data (Slice Clear via Point of View)                       │
│       Target specific intersections (e.g., Scenario = "Draft_Budget",   │
│       Year = "FY26").                                                   │
│                                                                         │
│   🔘 Clear Supporting Detail                                            │
│       Clears user-entered supporting line-item breakdowns.              │
│                                                                         │
│   🔘 Clear Comments & Document Attachments                              │
│       Purges cell text notes, annotations, and attached files.          │
│                                                                         │
│                                           [ Clear ]        [ Cancel ]   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Scripted Partial Clear via Calc Script / Groovy
For regular automated batch processing, use a targeted calc script or EPM Automate rather than GUI clicks:

```essbase
/* Targeted Clear Script */
CLEARDATA "Draft_Budget"->"FY26"->"Plan";
```

Or via EPM Automate:
```bash
epmautomate clearcube "OEP_FS" clearMode="PARTIAL" pov="Scenario:Draft_Budget,Years:FY26"
```

---

## 📦 Compacting Outlines & Defragmentation

Over months of frequent metadata imports and dimension updates, Essbase `.otl` files accumulate soft-deleted member pointers, causing fragmentation.

**Navigation:** `Application → Overview → Actions (▼) → Compact Outline`

- **What it does:** Scans the Essbase outline file, purges tombstone records from deleted members, rebuilds internal pointers, and defragments disk allocation.
- **When to run:**
  - After major metadata restructuring (e.g., deleting a deprecated product line of 5,000 members).
  - Monthly during planned maintenance.
  - If outline open/save times slow down.

---

## ⚡ ASO Incremental Slice Management (Merging Slices)

Unlike BSO where data overwrites existing cells in blocks, ASO records every new data load or map push as an **incremental data slice**.

```
┌────────────────────────────────────────┐
│  ASO Storage Architecture              │
│  ├── Main Data Slice (Base Table)      │
│  ├── Incremental Slice 1 (Morning Load)│
│  ├── Incremental Slice 2 (Noon Push)   │
│  └── Incremental Slice 3 (Evening Load)│
└────────────────────────────────────────┘
```

### The Problem:
If an ASO cube accumulates more than 20–30 incremental slices, query retrieval performance degrades because Essbase must query across dozens of disparate memory tables simultaneously.

### The Solution: Merge Slices
**Navigation:** `Application → Overview → Cubes → [Click OEP_REP] → Actions → Merge Data Slices`

```
┌─────────────────────────────────────────────────────────────┐
│ Merge Data Slices — OEP_REP                               ✖ │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Current Slice Count: 14 slices                              │
│ Total Cells: 12,450,200                                     │
│                                                             │
│ Merge Method:                                               │
│   🔘 Merge all incremental slices into the main slice       │
│       Consolidates all slices into one baseline table.      │
│                                                             │
│   🔘 Merge all incremental slices into a single slice       │
│       Leaves the base slice intact; combines recent slices. │
│                                                             │
│   ☑ Purge cells with zero values                            │
│       Removes cells containing zeros to shrink disk memory. │
│                                                             │
│                                      [ Merge ]   [ Cancel ] │
└─────────────────────────────────────────────────────────────┘
```

---

## 📈 Monitoring Storage Statistics & Performance Health

**Navigation:** `Application → Overview → Cubes → [Select Cube] → Performance`

Key metrics to evaluate application health:

| Metric | Target Optimal Range | Warning Threshold | Remediation |
|:---|:---:|:---:|:---|
| **BSO Block Size** | 50 KB – 500 KB | > 2,000 KB (2 MB) | Make dense members sparse; reduce dense dimension count |
| **Block Density** | 10% – 50% | < 2% | Dimensions misconfigured; sparse dimension accidentally marked dense |
| **Number of Existing Blocks** | Depends on model | Uncontrolled growth | Purge historical years or clear empty upper-level blocks |
| **ASO Slice Count** | 1 – 5 slices | > 15 slices | Run **Merge Slices** job |
| **Index Size vs Data Size** | Index should be 10–20% of data | Index > Data size | Dense/sparse inverted; rebuild outline indexes |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: How does BSO Hybrid optimize sparse aggregations compared to Classic BSO?
**Answer:** In Classic BSO, calculating sparse parents required running batch calculation scripts (`CALC ALL` or `CALC DIM`) that physically created and stored consolidated data blocks on disk. In Hybrid BSO, sparse parents are marked as `Dynamic Calc`; the in-memory aggregation engine computes parent rollups on-the-fly at query time, drastically reducing database size and eliminating nightly batch calculation windows.

### Q2: Why does `clearcube` not reduce physical `.pag` file sizes on disk, and how do you reclaim disk space?
**Answer:** `clearcube` marks data blocks as empty in the internal allocation table, but does not shrink the operating system page files. To reclaim disk space, you must execute **Compact Outline** (`Application â†’ Overview â†’ Actions â†’ Compact Outline`) or trigger a full database restructure, which rebuilds page files from scratch.

### Q3: What is Aggregate Storage (ASO) Slice Merging, and when is it mandatory?
**Answer:** Every incremental data load into an ASO cube creates an independent physical data slice on disk. When slice count exceeds 20â€“30, query retrieval times degrade significantly because queries must scan across all slices. Running `epmautomate mergeDataSlices CubeName mergeOption=allSlices` consolidates slices into a single main slice, restoring sub-second performance.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [04_Database_Refresh.md](./04_Database_Refresh_Master_Operations.md) |
| **Next →** | [06_EPM_Automate_Application_Bible.md](./06_EPM_Automate_Application_CLI_Bible.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |
