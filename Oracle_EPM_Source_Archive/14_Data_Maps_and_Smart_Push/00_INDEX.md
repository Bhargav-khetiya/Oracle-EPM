# Oracle EPM Cloud: Master Data Maps & Data Exchange Engineering Guide

## 1. Directory Structure and Architectural Map

This directory contains the definitive, exhaustive technical documentation for data movement, cross-cube synchronization, real-time Smart Push, legacy Essbase cross-cube functions (`@XREF`/`@XWRITE`), and enterprise orchestration pipelines within Oracle Enterprise Performance Management (EPM) Cloud.

```
Data_Maps_and_Exchange/
|-- 00_INDEX.md                                                  (Master Architectural Index)
|-- 01_Data_Maps_Architecture_and_Design/
|   |-- 01_Data_Maps_Core_Architecture_and_HSP_Tables.md         (Relational schema, HSP_MAP_* tables, lifecycle)
|   |-- 02_Field_Mapping_Topologies_and_Exclusions.md            (1:1, Many:1, Unmapped dims, Exclusions, Rollups)
|   `-- 03_Data_Maps_Administration_and_Jobs.md                  (UI walkthrough, Validation, EPM Automate, REST)
|-- 02_Smart_Push_Internals/
|   |-- 01_Smart_Push_Architecture_and_Form_Sync.md              (Form integration, Run on Save, Micro-slices)
|   |-- 02_ASO_Load_Buffers_and_Slice_Internals.md               (C++ Essbase APIs, EssWriteLoadBuffer, slice files)
|   `-- 03_ASO_Slice_Merge_and_Compaction_Strategies.md          (Slice proliferation, zero-cell purge, compaction)
|-- 03_Cross_Cube_XREF_and_XWRITE/
|   |-- 01_XREF_Deep_Dive_and_Pull_Architecture.md               (@XREF syntax, Location Alias, TCP pull mechanics)
|   |-- 02_XWRITE_Deep_Dive_and_Push_Architecture.md             (@XWRITE syntax, Target locking, BSO block creation)
|   |-- 03_XREF_XWRITE_Network_Protocols_and_Security.md         (TCP Ports 1423/32768, OCI IAM, Pod isolation)
|   `-- 04_Performance_Bottlenecks_and_Tuning_Guide.md           (NxM penalty, 439x speedup benchmark, migration)
|-- 04_Data_Exchange_and_Pipelines/
|   |-- 01_Data_Exchange_Pipeline_Architecture.md                (Unified Data Integration, pipeline stages, traps)
|   `-- 02_REST_APIs_and_EPM_Automate_Orchestration.md           (REST catalog, Python orchestrator, CLI commands)
|-- 05_Groovy_Data_Mover/
|   |-- 01_Groovy_DataGridDefinition_and_DataGridBuilder.md      (In-memory grid builder, cell iterators, micro-push)
|   `-- 02_Groovy_ExecuteDataMap_and_Micro_Push.md               (Dynamic Data Map execution, POV overrides)
`-- 06_Diagnostics_and_Interview_Bible/
    |-- 01_Troubleshooting_Matrix_and_Log_Analysis.md            (Error codes, log correlation, emergency runbook)
    `-- 02_Comprehensive_Interview_Bible_and_Scenarios.md        (25+ Architect interview Q&A and scenario analyses)
```

---

## 2. High-Level Technology Comparison Matrix

| Technology | Execution Layer | Extraction Protocol | Ingestion Speed | Target Locking | Real-Time Sync? | Modern Recommendation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Smart Push** | Application UI / C++ Buffer | MDX Micro-Slice | **Instantaneous** ($< 1\text{s}$) | Zero (ASO slice append) | **Yes** (On Form Save) | **Primary Standard for Forms** |
| **Data Maps (Batch)** | Platform Engine | MDX Macro-Slice | **$200\text{k} - 500\text{k}$ cells/s** | Minimal (Buffer commit) | Scheduled / On-Demand | **Primary Standard for Batch** |
| **Groovy Data Mover** | JVM / In-Memory Grid | Dynamic Grid / Memory | **$50\text{k} - 100\text{k}$ cells/s** | Zero (ASO Buffer) | **Yes** (Algorithmic Logic) | **Best for Dynamic Logic** |
| **Data Integration Pipeline** | Web Agent / REST Engine | Multi-Job Sequence | Bulk File / JDBC | Varies by step | Scheduled Workflow | **Best for End-to-End ETL** |
| **`@XREF` (Legacy)** | Essbase Calc Kernel | Point-to-Point Socket | $500 - 2,500$ cells/s | High (Source block hold) | Batch / Dynamic Calc | **Deprecate / Modernize** |
| **`@XWRITE` (Legacy)** | Essbase Calc Kernel | Point-to-Point Socket | $300 - 1,500$ cells/s | **Severe** (Target lock) | Batch Calculation | **Deprecate Immediately** |

---

## 3. Quick Reference Navigation

- **For Architecture & Relational Tables**: See [01_Data_Maps_Core_Architecture_and_HSP_Tables.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/01_Data_Maps_Architecture_and_Design/01_Data_Maps_Core_Architecture_and_HSP_Tables.md)
- **For Dimensional Topologies & Unmapped Dimensions**: See [02_Field_Mapping_Topologies_and_Exclusions.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/01_Data_Maps_Architecture_and_Design/02_Field_Mapping_Topologies_and_Exclusions.md)
- **For Form-Level Smart Push Configuration**: See [01_Smart_Push_Architecture_and_Form_Sync.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/02_Smart_Push_Internals/01_Smart_Push_Architecture_and_Form_Sync.md)
- **For Low-Level ASO Load Buffer APIs**: See [02_ASO_Load_Buffers_and_Slice_Internals.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/02_Smart_Push_Internals/02_ASO_Load_Buffers_and_Slice_Internals.md)
- **For ASO Slice Merge & Zero-Cell Purge**: See [03_ASO_Slice_Merge_and_Compaction_Strategies.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/02_Smart_Push_Internals/03_ASO_Slice_Merge_and_Compaction_Strategies.md)
- **For Legacy `@XREF` & `@XWRITE` Analysis**: See [01_XREF_Deep_Dive_and_Pull_Architecture.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/03_Cross_Cube_XREF_and_XWRITE/01_XREF_Deep_Dive_and_Pull_Architecture.md)
- **For Pipeline Orchestration & REST Endpoints**: See [01_Data_Exchange_Pipeline_Architecture.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/04_Data_Exchange_and_Pipelines/01_Data_Exchange_Pipeline_Architecture.md)
- **For Groovy Dynamic Push Scripts**: See [01_Groovy_DataGridDefinition_and_DataGridBuilder.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/05_Groovy_Data_Mover/01_Groovy_DataGridDefinition_and_DataGridBuilder.md)
- **For Interview Questions & Diagnostics**: See [01_Troubleshooting_Matrix_and_Log_Analysis.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/06_Diagnostics_and_Interview_Bible/01_Troubleshooting_Matrix_and_Log_Analysis.md) and [02_Comprehensive_Interview_Bible_and_Scenarios.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/06_Diagnostics_and_Interview_Bible/02_Comprehensive_Interview_Bible_and_Scenarios.md)
