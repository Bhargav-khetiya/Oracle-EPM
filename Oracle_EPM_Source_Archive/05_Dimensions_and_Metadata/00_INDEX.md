# 📖 Oracle EPM Cloud — Dimension and Member Properties: Master Architecture Bible

> **Purpose**: This directory serves as the exhaustive, deep-dive reference for all member and dimension properties in Oracle EPM Cloud Planning (PBCS / EPBCS) and Essbase. Every property, dropdown option, UI state, Essbase storage mechanic, calculation effect, and business use case is documented at consultant depth based on actual production extractions.

---

## 📂 Document Index

| # | File | Topic & Focus Area | Technical Level |
|---|------|--------------------|-----------------|
| 00 | [00_INDEX.md](./00_INDEX.md) | Master directory index, taxonomy, and navigation guide | Overview |
| 01 | [01_Universal_Member_Properties.md](./01_Universal_Member_Properties.md) | Universal properties: Name, Alias, Storage types (`Store`, `Dynamic Calc`, `Never Share`, `Label Only`), Two-Pass Calc, Plan Type Enablement, 7 Consolidation Operators, Data Types, Dynamic Children, UDAs | Foundation & Core |
| 02 | [02_Account_Dimension_Deep_Dive.md](./02_Account_Dimension_Deep_Dive.md) | Account Dimension (`Net Profit` screen): 6 Account Types, Variance Reporting (`Expense` vs `Non-Expense`), Time Balance (`Flow`, `Balance`, `First`, `Average`), Skip options, Exchange Rate Types, Source Cubes | Core Financials |
| 03 | [03_Period_and_Scenario_Dimensions.md](./03_Period_and_Scenario_Dimensions.md) | Period & Scenario Dimensions (`Q1` and `Actual` screens): `Start/End Period`, `Start/End Year`, `Include BegBal as Time Period`, `Enabled for Approvals`, Hierarchy Types (`Not Set`, `Stored`, `Dynamic`), active data range binding | Core Planning |
| 04 | [04_Version_Dimension_and_Sandboxes.md](./04_Version_Dimension_and_Sandboxes.md) | Version Dimension (`Working` screen): `Standard Bottom Up` vs `Standard Target`, Target-based spreading, `Enable Sandboxes`, sandbox virtual block mechanics, publishing data | Advanced Workflow |
| 05 | [05_Currency_and_Custom_Dimensions.md](./05_Currency_and_Custom_Dimensions.md) | Currency & Custom Dimensions (`USD_Reporting`, `No Custom1`, `D10010:Catering`): Reporting Currencies, `Hsp_Rates`, the multi-cube "No Member" pattern, multi-cube plan type enablement matrix | Multi-Cube Architecture |
| 06 | [06_System_Approval_Dimensions_and_17_Metric_Types.md](./06_System_Approval_Dimensions_and_17_Metric_Types.md) | System & Approval Dimensions (`HSP_Approval Unit Hierarchy` & `Submission Group`): What `HSP_` means, exhaustive breakdown of all 17 Metric Types, Planning Unit Hierarchies (PUH), promotion lifecycles | Enterprise Governance |
| 07 | [07_Troubleshooting_Dos_and_Donts_and_Interview_Guide.md](./07_Troubleshooting_Dos_and_Donts_and_Interview_Guide.md) | Production troubleshooting matrix, golden Do's & Don'ts, 20 consultant interview questions and answers, deployment checklist | Best Practices & Reference |
| 08 | [08_Attribute_Dimensions_vs_UDAs_Deep_Dive.md](./08_Attribute_Dimensions_vs_UDAs_Deep_Dive.md) | Attribute Dimensions vs UDAs: Storage engine mechanics (0-byte footprint), `@ATTRIBUTE` vs `@ISUDA`, dynamic rollups, query performance | Advanced Metadata Architecture |
| 09 | [09_Relational_Schema_Internals_and_HSP_Tables.md](./09_Relational_Schema_Internals_and_HSP_Tables.md) | Relational Schema Internals: `HSP_OBJECT`, `HSP_MEMBER`, `HSP_ACCOUNT`, `HSP_MEMBER_TO_PLAN_TYPE`, SQL metadata persistence | Database Internals |
| 10 | [10_Advanced_Solve_Order_and_Formula_Execution.md](./10_Advanced_Solve_Order_and_Formula_Execution.md) | Advanced Solve Order & Formula Execution: Cell collisions, mathematical divergence proof, solve order hierarchy (0-127), ASO/BSO differences | Calculation Engine Architecture |
| 11 | [11_Member_Formula_Compilation_and_Execution_Internals.md](./11_Member_Formula_Compilation_and_Execution_Internals.md) | Member Formula Compilation & Execution: AST and bytecode generation, Dense vs Sparse execution physics, `@XREF` / `@XWRITE` socket streaming, DAG circular reference detection | Advanced Formula Architecture |
| 12 | [12_Smart_Push_Data_Maps_and_Dimensional_Mapping.md](./12_Smart_Push_Data_Maps_and_Dimensional_Mapping.md) | Smart Push & Data Maps: BSO-to-ASO bridge, Unmapped & Excluded dimensional topologies, `EssASOInitLoadBuffer` kernel lifecycle, slice merge optimization | Hybrid Multi-Cube Integration |

---

## 🎯 How to Use This Guide

1. **For Outline & Dimension Design**: Read `01` → `02` → `05`.
2. **For Financial Modeling & Balance Sheets**: Read `02` → `03`.
3. **For Workflow, Targets & Approvals**: Read `03` → `04` → `06`.
4. **For Multi-Cube Architecture**: Read `01` → `05` → `12`.
5. **For Metadata Attributes & SQL Catalogs**: Read `08` → `09`.
6. **For Dynamic Formula Resolution & Solve Orders**: Read `10` → `11`.
7. **For Production Troubleshooting & Interview Preparation**: Read `07`.

---

## 🔑 Key Concepts at a Glance

```
Oracle EPM Planning Member Configuration
├── RELATIONAL LAYER (Planning SQL DB):
│   ├── Validates unique names, aliases, and metadata constraints
│   ├── Stores form layouts, task lists, and approval units
│   └── Governs user security and role permissions
│
└── PHYSICAL LAYER (Essbase MOLAP Engine):
    ├── Dense Dimension Members → define 8-byte cell offsets in data blocks
    ├── Sparse Dimension Members → define B-tree index branches in .IND
    ├── Data Storage = Store → physical block cells in .PAG
    ├── Data Storage = Dynamic Calc → computed in RAM (0 bytes disk)
    ├── Two-Pass Calc → corrects ratio aggregations on dense dynamic members
    └── Consolidation Operators (+, -, *, /, %, ~, ^) → procedural rollup
```
