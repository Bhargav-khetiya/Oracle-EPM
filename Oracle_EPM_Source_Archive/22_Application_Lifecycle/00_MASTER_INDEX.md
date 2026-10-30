# 📖 Oracle Cloud EPM — Application Creation & Lifecycle Management Master Bible
## The Comprehensive Master Index & Architectural Navigation Guide

> **Version:** 2.0 (Unified Enterprise Edition)  
> **Scope:** End-to-end lifecycle governance for Oracle Fusion Cloud EPM: from environment provisioning, backups, and instance recreation to application creation (Sample, Wizard, Modules, FreeForm), snapshot migration, post-creation administration, and automated operations.  
> **Audience:** EPM Architects, Service Administrators, Implementation Consultants, DevOps Engineers

---

## 🗺️ Visual Architecture Map

This unified master suite governs every phase of an Oracle Cloud EPM environment and its resident applications:

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                        ORACLE CLOUD EPM UNIFIED LIFECYCLE ARCHITECTURE                                  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                    │
                                                    ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 1️⃣ ENVIRONMENT LIFECYCLE & MAINTENANCE (Container Level)                                              │
│ • Daily Maintenance Windows & Cold Essbase Backups        • Snapshot Management (Export/Download/Upload)│
│ • Object Storage Environment Backups (60-day retention)  • Instance Wipe & Factory Reset (`recreate`)  │
│ • Server-to-Server Streaming (`copySnapshotFromInstance`) • Full 1-Step Environment Replication (`clone`)│
└──────────────────────────────────────┬─────────────────────────────────────────────────────────────────┘
                                       │ When environment is clean or reset:
                                       ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 2️⃣ APPLICATION CREATION FROM THE LANDING PAGE (Application Level)                                      │
├───────────────────────────────┬────────────────────────────────────────┬───────────────────────────────┤
│ 📦 PATH 1: SAMPLE APP         │ 📑 PATH 2: CREATE NEW APP              │ 📥 PATH 3: MIGRATE SNAPSHOT   │
│ • Vision Sample Model         │ • Multi-Step Planning Wizard           │ • Upload Snapshot Archive     │
│ • Instant sandbox evaluation  │ • Pre-Built Modules (Fin/WF/Cap/Prj/SM)│ • Group Modes (Create/Update) │
│ • Complete demonstration data │ • FreeForm Custom Cubes (BSO/ASO/Hyb)  │ • Snapshot Payload Ingestion  │
└───────────────────────────────┴───────────────────┬────────────────────┴───────────────────────────────┘
                                                    │ Once application is created:
                                                    ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 3️⃣ POST-CREATION GOVERNANCE & CUBE ADMINISTRATION (Operational Level)                                 │
│ • Immutability Governance (Locked vs Modifiable settings)  • Dense vs. Sparse Dimension Architecture   │
│ • Progressive Feature Enablement (Phase-by-phase rollout)  • Full Database Refresh Pipeline (3 Phases) │
│ • Dual-Engine Tuning (BSO Hybrid vs. ASO Slice Merging)    • EPM Automate Application Command CLI Bible│
└──────────────────────────────────────┬─────────────────────────────────────────────────────────────────┘
                                       │ Day-to-Day Maintenance & Enterprise Transition:
                                       ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 4️⃣ MIGRATION REPORTS, TRANSITION & AUTOMATION (Operations & Compliance Level)                          │
│ • Migration Status Diagnostic Reports & Drill-downs       • On-Premises Hyperion to Cloud Migration    │
│ • Modification History & Delta Patch Exports              • Shared Services to Cloud EPM Role Mapping  │
│ • Automated Production-to-Test Nightly Clone Runbook      • Master Troubleshooting Error Code Catalog  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📚 Complete Document Catalog by Section

### Section 1: Environment Lifecycle & Maintenance
*Managing the Cloud Environment Container, Backups, and Provisioning Lifecycle*

| # | Document | File Path | Focus Area |
|:---:|:---|:---|:---|
| 01 | **Lifecycle Strategy & Overview** | [01_Lifecycle_Strategy_and_Overview.md](./01_Environment_Lifecycle_and_Maintenance/01_Lifecycle_Strategy_and_Overview.md) | Executive replication strategy, Clone vs Copy vs Download, and Decision Tree. |
| 02 | **Key Concepts & Architecture** | [02_Key_Concepts_and_Architecture.md](./01_Environment_Lifecycle_and_Maintenance/02_Key_Concepts_and_Architecture.md) | Snapshots vs Environment Backups, Object Storage, and Version Compatibility. |
| 03 | **EPM Automate Setup & Security** | [03_EPM_Automate_Setup_and_Authentication.md](./01_Environment_Lifecycle_and_Maintenance/03_EPM_Automate_Setup_and_Authentication.md) | CLI installation, encrypted `.epw` key generation, Basic Auth vs OAuth, and MFA rules. |
| 04 | **Backup Strategy & Maintenance** | [04_Backup_Strategy_and_Daily_Maintenance.md](./01_Environment_Lifecycle_and_Maintenance/04_Backup_Strategy_and_Daily_Maintenance.md) | Automated maintenance windows, cold Essbase snapshots, and on-demand backups. |
| 05 | **Listing & Exploring Backups** | [05_Listing_and_Exploring_Backups.md](./01_Environment_Lifecycle_and_Maintenance/05_Listing_and_Exploring_Backups.md) | Querying cloud storage via `listFiles` and `listBackups`. |
| 06 | **Snapshot Lifecycle Management** | [06_Snapshot_Lifecycle_Management.md](./01_Environment_Lifecycle_and_Maintenance/06_Snapshot_Lifecycle_Management.md) | Web UI limits (2 GB cap), repeating exports, renaming, deleting, and 60d/150GB retention. |
| 07 | **Recreate Instance (Clean Wipe)** | [07_Recreate_Instance_Clean_Reset.md](./01_Environment_Lifecycle_and_Maintenance/07_Recreate_Instance_Clean_Reset.md) | Resetting instance clean via `recreate`, what is destroyed vs kept, and resetting to landing page. |
| 08 | **Server-to-Server Snapshot Copy** | [08_Copy_Snapshot_Between_Instances.md](./01_Environment_Lifecycle_and_Maintenance/08_Copy_Snapshot_Between_Instances.md) | Direct cross-pod streaming (`copySnapshotFromInstance`) without local disk downloads. |
| 09 | **Environment Cloning Master Guide** | [09_Environment_Cloning_Master_Guide.md](./01_Environment_Lifecycle_and_Maintenance/09_Environment_Cloning_Master_Guide.md) | 1-step replication (`cloneEnvironment`), Web UI wireframe, renamed seeded members gotcha. |
| 10 | **Object Storage Backup Restore** | [10_Object_Storage_Backup_Restoration.md](./01_Environment_Lifecycle_and_Maintenance/10_Object_Storage_Backup_Restoration.md) | Point-in-time disaster recovery from Oracle Object Storage (`restoreEnvironment`). |

---

### Section 2: Landing Page & Application Creation
*The Three Creation Pathways: Sample Application, New Application Wizard & FreeForm*

| # | Document | File Path | Focus Area |
|:---:|:---|:---|:---|
| 11 | **Landing Page Overview** | [00_Landing_Page_Complete_Overview.md](./02_Landing_Page_and_Application_Creation/00_Landing_Page_Complete_Overview.md) | Detailed walkthrough of the Planning Landing Page, user roles, and 3 primary paths. |
| 12 | **Sample App Overview** | [01_Sample_Application_Overview.md](./02_Landing_Page_and_Application_Creation/01_Create_Sample_Application/01_Sample_Application_Overview.md) | When to use sample apps and sandbox architecture. |
| 13 | **Vision Creation Walkthrough** | [02_Vision_Sample_Creation_Walkthrough.md](./02_Landing_Page_and_Application_Creation/01_Create_Sample_Application/02_Vision_Sample_Creation_Walkthrough.md) | Step-by-step creation of the Vision sample application. |
| 14 | **Vision Contents & Artifacts** | [03_Vision_Sample_Contents_and_Artifacts.md](./02_Landing_Page_and_Application_Creation/01_Create_Sample_Application/03_Vision_Sample_Contents_and_Artifacts.md) | Complete inventory of pre-built Vision cubes, dimensions, forms, and rules. |
| 15 | **Post-Sample Walkthrough** | [04_Post_Sample_Creation_Walkthrough.md](./02_Landing_Page_and_Application_Creation/01_Create_Sample_Application/04_Post_Sample_Creation_Walkthrough.md) | Navigating the Vision application home page and sample dashboards. |
| 16 | **Wizard Overview & Prerequisites**| [01_Wizard_Overview_and_Prerequisites.md](./02_Landing_Page_and_Application_Creation/02_Create_New_Application_Wizard/01_Wizard_Overview_and_Prerequisites.md) | Creation wizard step sequence and preparation checklist. |
| 17 | **Step 1: General Properties** | [02_Step1_General_Properties.md](./02_Landing_Page_and_Application_Creation/02_Create_New_Application_Wizard/02_Step1_General_Properties.md) | Application naming rules, character constraints, and description setup. |
| 18 | **Step 2: App Type Selection** | [03_Step2_Application_Type_Selection.md](./02_Landing_Page_and_Application_Creation/02_Create_New_Application_Wizard/03_Step2_Application_Type_Selection.md) | Choosing between Standard Planning, Modules, and FreeForm. |
| 19 | **Step 3: Calendar Setup** | [04_Step3_Calendar_Setup.md](./02_Landing_Page_and_Application_Creation/02_Create_New_Application_Wizard/04_Step3_Calendar_Setup.md) | Fiscal year configuration, period granularity (12 vs 13 periods), and distribution patterns. |
| 20 | **Step 4: Currency Configuration** | [05_Step4_Currency_Configuration.md](./02_Landing_Page_and_Application_Creation/02_Create_New_Application_Wizard/05_Step4_Currency_Configuration.md) | Single Currency vs Multi-Currency and default base currency selection. |
| 21 | **Step 5: Review & Create** | [06_Step5_Review_and_Create.md](./02_Landing_Page_and_Application_Creation/02_Create_New_Application_Wizard/06_Step5_Review_and_Create.md) | Final pre-flight checklist and application creation execution. |

---

### Section 2A: Pre-Built Planning Modules
*Out-of-the-Box Business Modules with Embedded Intelligence & Pre-Configured Content*

| # | Document | File Path | Focus Area |
|:---:|:---|:---|:---|
| 22 | **Modules Architecture Overview** | [01_Modules_Architecture_Overview.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/01_Modules_Architecture_Overview.md) | Enterprise module framework, shared reporting cube (`OEP_REP`), and module comparison matrix. |
| 23 | **Financials Module Master Guide** | [02_Financials_Module_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/02_Financials_Module_Master_Guide.md) | Revenue, Expense, Balance Sheet, Cash Flow, and Rolling Forecast setup. |
| 24 | **Workforce Module Master Guide** | [03_Workforce_Module_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/03_Workforce_Module_Master_Guide.md) | Headcount, compensation, salary, benefits, and labor cost modeling. |
| 25 | **Capital Module Master Guide** | [04_Capital_Module_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/04_Capital_Module_Master_Guide.md) | Fixed assets, depreciation formulas, ASC 842 / IFRS 16 lease accounting, and CapEx cash flows. |
| 26 | **Projects Module Master Guide** | [05_Projects_Module_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/05_Projects_Module_Master_Guide.md) | Contract, Capital, and Indirect projects, resource allocation, and tri-directional sync. |
| 27 | **Strategic Modeling Master Guide**| [06_Strategic_Modeling_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/06_Strategic_Modeling_Master_Guide.md) | Long-range financial modeling, M&A valuations, and debt/equity optimization. |
| 28 | **Sales Planning Master Guide** | [07_Sales_Planning_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/07_Sales_Planning_Master_Guide.md) | Top-down/bottom-up quota allocation, territory segmentation, and pipeline probability. |

---

### Section 2B: FreeForm Custom Essbase Modeling
*Schema-Free Multidimensional Modeling Without Mandatory Dimensions*

| # | Document | File Path | Focus Area |
|:---:|:---|:---|:---|
| 29 | **FreeForm Architecture & Use Cases**| [01_FreeForm_Architecture_and_Use_Cases.md](./02_Landing_Page_and_Application_Creation/04_FreeForm_Application/01_FreeForm_Architecture_and_Use_Cases.md) | On-prem Essbase migration, hybrid modeling, and comparison to Standard Planning. |
| 30 | **FreeForm Cube Setup** | [02_FreeForm_Cube_Setup.md](./02_Landing_Page_and_Application_Creation/04_FreeForm_Application/02_FreeForm_Cube_Setup.md) | BSO, ASO, and Hybrid cube creation, sandboxing, and duplicate member options. |
| 31 | **FreeForm Dimension Setup** | [03_FreeForm_Dimension_Setup.md](./02_Landing_Page_and_Application_Creation/04_FreeForm_Application/03_FreeForm_Dimension_Setup.md) | Custom dimension configuration, dimension types, and import options. |
| 32 | **FreeForm Review & Create** | [04_FreeForm_Review_and_Create.md](./02_Landing_Page_and_Application_Creation/04_FreeForm_Application/04_FreeForm_Review_and_Create.md) | Final verification and FreeForm application creation. |

---

### Section 3: Migrate Application from Snapshot
*Path 3: Creating or Restoring Applications from LCM Snapshot Archives*

| # | Document | File Path | Focus Area |
|:---:|:---|:---|:---|
| 33 | **Migration Concepts & Payload** | [01_Migration_Concepts_and_Payload_Architecture.md](./03_Migrate_Application_from_Snapshot/01_Migration_Concepts_and_Payload_Architecture.md) | Snapshot contents, Environment Backups vs Artifact Snapshots, and version compatibility. |
| 34 | **Prepare & Export Snapshots** | [02_Prepare_and_Export_Snapshots.md](./03_Migrate_Application_from_Snapshot/02_Prepare_and_Export_Snapshots.md) | Full backup vs incremental export, cold Essbase rules, and Data Management LCM modes. |
| 35 | **Upload & Import Walkthrough** | [03_Upload_and_Import_Walkthrough.md](./03_Migrate_Application_from_Snapshot/03_Upload_and_Import_Walkthrough.md) | Web UI upload dialogs (2 GB cap), EPM Automate streaming, and import execution. |
| 36 | **Import Options & Settings** | [04_Import_Options_and_Settings.md](./03_Migrate_Application_from_Snapshot/04_Import_Options_and_Settings.md) | Group management modes (`Create or Update`), error thresholds, and `EPMIE-00070` resolution. |
| 37 | **Post-Migration Diagnostics** | [05_Post_Migration_Validation_and_Diagnostics.md](./03_Migrate_Application_from_Snapshot/05_Post_Migration_Validation_and_Diagnostics.md) | Migration Status report inspection, Database Refresh, Calc Manager deploy, and checklist. |

---

### Section 4: Post-Creation Governance & Administration
*Application Settings, Metadata Management, Database Refresh & Cube Engine Governance*

| # | Document | File Path | Focus Area |
|:---:|:---|:---|:---|
| 38 | **Application Settings & Immutability**| [01_Application_Settings_and_Immutability_Matrix.md](./04_Post_Creation_Governance_and_Administration/01_Application_Settings_and_Immutability_Matrix.md) | Application Overview screen, Actions menu, and Immutable vs Mutable settings matrix. |
| 39 | **Progressive Feature Enablement** | [02_Progressive_Feature_Enablement.md](./04_Post_Creation_Governance_and_Administration/02_Progressive_Feature_Enablement.md) | Enabling modules post-creation, irreversible actions warning, and Hybrid BSO conversion. |
| 40 | **Dimension Management & Properties**| [03_Dimension_Management_and_Member_Properties.md](./04_Post_Creation_Governance_and_Administration/03_Dimension_Management_and_Member_Properties.md) | Custom dimensions, Dense vs Sparse architecture, member properties dictionary, and bulk CSVs. |
| 41 | **Database Refresh Master Operations**| [04_Database_Refresh_Master_Operations.md](./04_Post_Creation_Governance_and_Administration/04_Database_Refresh_Master_Operations.md) | The 3 phases of Database Refresh, Sparse vs Dense restructure impacts, and CLI automation. |
| 42 | **Cube & Storage Management** | [05_Cube_and_Storage_Management.md](./04_Post_Creation_Governance_and_Administration/05_Cube_and_Storage_Management.md) | BSO Hybrid vs ASO architecture, 4 data clearing modes, outline compaction, and slice merging. |
| 43 | **EPM Automate CLI Bible** | [06_EPM_Automate_Application_CLI_Bible.md](./04_Post_Creation_Governance_and_Administration/06_EPM_Automate_Application_CLI_Bible.md) | Comprehensive command catalog (`recreate`, `importsnapshot`, `refreshcube`, `clearcube`). |

---

### Section 5: Migration Reports, Auditing & On-Premises Transition
*Compliance Auditing, Delta Tracking, and Migrating Legacy Hyperion to Cloud EPM*

| # | Document | File Path | Focus Area |
|:---:|:---|:---|:---|
| 44 | **Migration Reports & SOX Auditing**| [01_Migration_Reports_and_Compliance_Auditing.md](./05_Migration_Reports_Auditing_and_OnPrem_Transition/01_Migration_Reports_and_Compliance_Auditing.md) | Migration Status report, Artifact Modification History delta exports, and Artifact Updates audit logs. |
| 45 | **On-Premises to Cloud EPM Migration**| [02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md](./05_Migration_Reports_Auditing_and_OnPrem_Transition/02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md) | 2-step migration methodology (Planning, HFM, HPCM, HSF, DRM) and Appendix A Role Mapping Matrix. |

---

### Section 6: Enterprise Automation Runbooks & Troubleshooting
*Production Runbooks, Unattended Scripts, and Master Error Catalog*

| # | Document | File Path | Focus Area |
|:---:|:---|:---|:---|
| 46 | **Prod-to-Demo Replication Runbook** | [01_Prod_to_Demo_Complete_Runbook.md](./06_Automation_Runbooks_and_Troubleshooting/01_Prod_to_Demo_Complete_Runbook.md) | End-to-end production cutover runbook for cloning Production into Demo/Test. |
| 47 | **Enterprise Automation Scripts** | [02_Enterprise_Automation_Scripts.md](./06_Automation_Runbooks_and_Troubleshooting/02_Enterprise_Automation_Scripts.md) | Production-ready PowerShell and Windows Batch scripts for unattended execution. |
| 48 | **Master Troubleshooting & FAQ** | [03_Master_Troubleshooting_FAQ_and_Gotchas.md](./06_Automation_Runbooks_and_Troubleshooting/03_Master_Troubleshooting_FAQ_and_Gotchas.md) | Error code index (`EPMLCM-26000`, `EPMIE-00070`, timeouts), root causes, and verified fixes. |
| 49 | **Master Twisted Questions & Edge Cases** | [04_Master_Twisted_Questions_and_Deep_Architectural_Scenarios.md](./06_Automation_Runbooks_and_Troubleshooting/04_Master_Twisted_Questions_and_Deep_Architectural_Scenarios.md) | 50 Deep, twisted scenario questions, edge cases, landmines, and verified architectural workarounds across all modules. |

---

## 🔑 Quick Decision Matrix: Which Tool to Use When

| Business Objective | Recommended Tool / Pathway | Go-To Master Document |
|:---|:---|:---|
| **First-time learning or demoing EPM** | Landing Page → [CREATE] Sample Application | [02_Vision_Sample_Creation_Walkthrough.md](./02_Landing_Page_and_Application_Creation/01_Create_Sample_Application/02_Vision_Sample_Creation_Walkthrough.md) |
| **Corporate financial budgeting (P&L, BS, CF)**| Landing Page → [START] → Planning Modules → Financials | [02_Financials_Module_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/02_Financials_Module_Master_Guide.md) |
| **Salary, bonus, headcount & benefits** | Landing Page → [START] → Planning Modules → Workforce | [03_Workforce_Module_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/03_Workforce_Module_Master_Guide.md) |
| **CapEx, depreciation & ASC 842 / IFRS 16 leases**| Landing Page → [START] → Planning Modules → Capital | [04_Capital_Module_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/04_Capital_Module_Master_Guide.md) |
| **Contract billing, capital construction & tasks**| Landing Page → [START] → Planning Modules → Projects | [05_Projects_Module_Master_Guide.md](./02_Landing_Page_and_Application_Creation/03_PreBuilt_Planning_Modules/05_Projects_Module_Master_Guide.md) |
| **Custom Essbase outline (no mandatory dims)**| Landing Page → [START] → FreeForm | [01_FreeForm_Architecture_and_Use_Cases.md](./02_Landing_Page_and_Application_Creation/04_FreeForm_Application/01_FreeForm_Architecture_and_Use_Cases.md) |
| **Restoring from backup on clean instance** | Landing Page → [MIGRATE] Snapshot | [03_Upload_and_Import_Walkthrough.md](./03_Migrate_Application_from_Snapshot/03_Upload_and_Import_Walkthrough.md) |
| **Wiping an existing application clean** | CLI `recreate -f` | [07_Recreate_Instance_Clean_Reset.md](./01_Environment_Lifecycle_and_Maintenance/07_Recreate_Instance_Clean_Reset.md) |
| **Fast server-to-server clone of Prod to Demo** | CLI `cloneEnvironment` or UI Clone | [09_Environment_Cloning_Master_Guide.md](./01_Environment_Lifecycle_and_Maintenance/09_Environment_Cloning_Master_Guide.md) |
| **Moving snapshots during blackout period** | CLI `copySnapshotFromInstance` | [08_Copy_Snapshot_Between_Instances.md](./01_Environment_Lifecycle_and_Maintenance/08_Copy_Snapshot_Between_Instances.md) |
| **Recovering historical data (>60 days)** | CLI `restoreEnvironment` from Object Storage | [10_Object_Storage_Backup_Restoration.md](./01_Environment_Lifecycle_and_Maintenance/10_Object_Storage_Backup_Restoration.md) |
| **Transitioning from Hyperion 11.1.2.4 on-prem**| LCM Export ➔ Security Mapping ➔ Cloud Import | [02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md](./05_Migration_Reports_Auditing_and_OnPrem_Transition/02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md) |
| **Technical interview prep & high-stakes dilemmas**| 50 Master Twisted Questions & Architectural Scenarios | [04_Master_Twisted_Questions_and_Deep_Architectural_Scenarios.md](./06_Automation_Runbooks_and_Troubleshooting/04_Master_Twisted_Questions_and_Deep_Architectural_Scenarios.md) |

