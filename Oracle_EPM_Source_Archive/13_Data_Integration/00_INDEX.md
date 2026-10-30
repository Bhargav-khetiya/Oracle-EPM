# Volume 09: Data Integration and External ERP Pipeline Architecture

## 1. Executive Architectural Overview

**Data Integration** (formerly Data Management / FDMEE) in Oracle EPM Cloud is the enterprise ETL and financial data quality management engine that extracts, maps, transforms, validates, and loads external transactional and financial data from ERP systems (Oracle Fusion ERP, SAP, NetSuite, Workday, flat files) into multidimensional EPM cubes.

```
+---------------------------------------------------------------------------------------------------+
|                                  DATA INTEGRATION PIPELINE TOPOLOGY                               |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [SOURCE SYSTEMS: Fusion ERP, SAP, Workday, On-Premises DB, Flat CSV/Text Files]                  |
|                                                  |                                                |
|                                                  | 1. Extract via EPM Integration Agent / REST    |
|                                                  v                                                |
|  +---------------------------------------------------------------------------------------------+  |
|  | DATA INTEGRATION STAGING REPOSITORY (TDataSeg Relational Tables)                           |  |
|  | - Import Format: Parses source delimiter, columns, and expressions                          |  |
|  | - Location & Period Mapping: Maps external fiscal periods to EPM Years/Periods              |  |
|  | - Category Mapping: Maps ERP Ledgers / Scenarios (Actual, Budget) to EPM Scenarios          |  |
|  | - Dimension Member Mappings: Explicit, In, Between, Multi-Dim, and Like (Wildcard)          |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  | 2. Transform & Validate                        |
|                                                  v                                                |
|  +---------------------------------------------------------------------------------------------+  |
|  | TARGET MULTIDIMENSIONAL INGESTION (BSO / ASO Cubes)                                         |  |
|  | - Export Modes: Replace, Merge, Accumulate, Store Data                                      |  |
|  | - Post-Load Business Rule Triggers & Aggregations                                           |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Directory Contents and Chapter Navigation

| Document | Primary Focus | Key Architectural Concepts |
| :--- | :--- | :--- |
| [Oracle_EPM_Data_Integration_Master_Guide.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Integration/Oracle_EPM_Data_Integration_Master_Guide.md) | **Data Integration Master Guide** | Comprehensive 40KB reference covering Import Formats, Locations, Mapping Rules (Explicit, Between, In, Multi-Dim, Like), Export Modes, and EPM Integration Agent architecture. |

---

## 3. Related Cross-References
- **Integration Pipelines & REST APIs**: See [Data_Maps_and_Exchange/04_Data_Exchange_and_Pipelines/01_Data_Exchange_Pipeline_Architecture.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/04_Data_Exchange_and_Pipelines/01_Data_Exchange_Pipeline_Architecture.md)
- **EPM Automate Load Automation**: See [EPM_Automate/03_Data_and_Metadata_Automation.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPM_Automate/03_Data_and_Metadata_Automation.md)

