# 03 — Data & Metadata Automation: ETL Pipeline

---

## 3.1 Overview: The Nightly ETL & Dimension Pipeline

Enterprise planning applications require daily or hourly data and metadata synchronization:
1. **Dimensions & Metadata**: Ingesting new cost centers, employees, accounts, and projects from ERP (Oracle Fusion, SAP, NetSuite).
2. **Transactional Data**: Loading general ledger trial balances, sales invoices, payroll runs, and asset depreciations.
3. **Database Refresh**: Recompiling the Essbase `.OTL` outline to activate new members.
4. **Smart Push / Data Maps**: Synchronizing calculation cubes (`FinPlan`) with reporting cubes (`EPBCS`).

```
┌────────────────────────────────────────────────────────────────────────┐
│                        NIGHTLY AUTOMATION SEQUENCE                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. UPLOAD ARTIFACTS:                                                   │
│    epmautomate uploadFile "Accounts_Delta.csv"                         │
│    epmautomate uploadFile "GL_Actuals_Oct2026.txt"                     │
│                                                                        │
│ 2. IMPORT METADATA:                                                    │
│    epmautomate importMetadata "Import_Accounts_Job" "Accounts_Delta.csv"│
│                                                                        │
│ 3. REFRESH ESSBASE CUBES:                                              │
│    epmautomate refreshCube                                             │
│    -> Compiles outline (.OTL), restructures blocks                     │
│                                                                        │
│ 4. LOAD TRIAL BALANCE (Data Integration Rule):                         │
│    epmautomate runDataRule "GL_Load_Rule" "Oct-26" "Oct-26" "REPLACE"   │
│                                                                        │
│ 5. SYNC REPORTING CUBE:                                                │
│    epmautomate runDataMap "FinPlan_to_EPBCS_Map"                       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3.2 Dimension & Metadata Automation

| Command Syntax | Operational Mechanics | Best Practices & Gotchas |
| :--- | :--- | :--- |
| **`importMetadata <job> [file]`** | Ingests dimension members from a CSV flat file using a pre-configured Planning Import Metadata job. | Always validate header column mappings (`Member Name`, `Parent`, `Data Storage`, `Consolidation Operator`). |
| **`exportMetadata <job> [file]`** | Exports outline dimension hierarchies into CSV files. | Used for metadata backups and syncing dimensions into data warehouses. |
| **`refreshCube [cube]`** | **The Essential Compilation Step**. Compiles changes from Planning relational tables into the Essbase outline (`.OTL`). | **Locks the application**. Planners cannot save data while a refresh is in progress. Always execute during maintenance windows. |

---

## 3.3 Data Loads & Clear Operations

### 3.3.1 Loading Native Data Files:
```cmd
epmautomate importData "Native_Data_Import_Job" "GL_Actuals_Oct2026.txt"
```

### 3.3.2 Exporting Data:
```cmd
epmautomate exportData "Export_Level0_Job" "FinPlan_Level0_Oct26.zip"
```

### 3.3.3 Clearing Physical Data Blocks:
Before reloading a full fiscal year of Actuals, clear the prior data to eliminate stale intersections:
```cmd
epmautomate clearCube "Clear_Actual_FY26_Job"
```
* **Clear Options**: Can clear `All Data`, `Upper-Level Blocks Only`, `Dynamic Calc Cache`, or `Supporting Detail`.

---

## 3.4 Data Management (FDMEE) & Data Integration Automation

When data requires transformation, mapping, or GL drill-through, organizations use **Data Integration (Data Management)**:

```cmd
epmautomate runDataRule <Rule_Name> <Start_Period> <End_Period> <Import_Mode> <Export_Mode> [File_Name]
```

### Concrete Example:
```cmd
epmautomate runDataRule "Load_SAP_General_Ledger" "Jan-26" "Mar-26" "REPLACE" "STORE_DATA" "SAP_Trial_Balance.csv"
```

### Import Modes:
* **`REPLACE`**: Wipes existing staging data in Data Management and reloads.
* **`APPEND`**: Adds new rows to staging tables.

### Export Modes:
* **`STORE_DATA`**: Writes transformed numeric floats directly into Essbase `.PAG` data blocks.
* **`REPLACE_DATA`**: Clears the target slice in Essbase before loading.

---

## 3.5 Cross-Cube Sync: `runDataMap` (Smart Push)

To trigger automated data movement between planning and reporting cubes:
```cmd
epmautomate runDataMap "FinPlan_to_EPBCS_Map"
```
* Transfers the configured dimension mapping from Block Storage to Aggregate Storage.
* Can be scheduled immediately following the nightly data load to ensure executive dashboards reflect fresh numbers before morning business hours.
