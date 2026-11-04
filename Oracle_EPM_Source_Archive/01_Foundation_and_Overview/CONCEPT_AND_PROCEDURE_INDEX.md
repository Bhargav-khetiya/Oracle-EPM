# 📑 Oracle EPM Cloud: Master Concept & Procedure Index

This index provides a direct navigational lookup linking every major Oracle EPM Cloud architectural concept and operational procedure to its canonical documentation chapter in the 15 volumes of this knowledge base.

---

## 1. Quick Jump Directory

* [A — Application Lifecycle & Architecture](#a--application-lifecycle--architecture)
* [B — Blocks, Storage Physics & Essbase Kernel](#b--blocks-storage-physics--essbase-kernel)
* [C — Calculations, Business Rules & Groovy](#c--calculations-business-rules--groovy)
* [D — Dimensions, Members & Data Movement](#d--dimensions-members--data-movement)
* [E — EPM Automate & DevOps Scripting](#e--epm-automate--devops-scripting)
* [F — Forms, Web Grids & Spread Operations](#f--forms-web-grids--spread-operations)
* [G — Governance, Approvals & Workflows](#g--governance-approvals--workflows)
* [I — Integrations, ETL & Pipelines](#i--integrations-etl--pipelines)
* [M — Modules & Pre-Built Business Processes](#m--modules--pre-built-business-processes)
* [S — Security, Valid Intersections & Smart View](#s--security-valid-intersections--smart-view)
* [T — Troubleshooting, Incidents & Interview Prep](#t--troubleshooting-incidents--interview-prep)

---

## A — Application Lifecycle & Architecture

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Application Types Overview** | [`Techno_Functional_Consultant_Review_Bible/02_Application_Types_PBCS_EPBCS_Custom_FreeForm_FCCS.md`](Techno_Functional_Consultant_Review_Bible/02_Application_Types_PBCS_EPBCS_Custom_FreeForm_FCCS.md) | Architectural comparison of Custom Planning, EPBCS Modules, FreeForm, and FCCS. |
| **Application Creation Wizard Steps** | [`05_Application_Creation_and_Lifecycle_Management/02_Landing_Page_and_Application_Creation/02_Create_New_Application_Wizard/01_Wizard_Overview_and_Prerequisites.md`](05_Application_Creation_and_Lifecycle_Management/02_Landing_Page_and_Application_Creation/02_Create_New_Application_Wizard/01_Wizard_Overview_and_Prerequisites.md) | Complete 5-step walkthrough of the cloud creation wizard. |
| **Immutable Application Properties** | [`Techno_Functional_Consultant_Review_Bible/03_Application_Creation_Screen_by_Screen_Every_Property.md`](Techno_Functional_Consultant_Review_Bible/03_Application_Creation_Screen_by_Screen_Every_Property.md) | Why Calendar Frequencies, Multi-Currency, and Sandboxes cannot be modified post-creation. |
| **LCM Snapshot Lifecycle & Backups** | [`05_Application_Creation_and_Lifecycle_Management/01_Environment_Lifecycle_and_Maintenance/06_Snapshot_Lifecycle_Management.md`](05_Application_Creation_and_Lifecycle_Management/01_Environment_Lifecycle_and_Maintenance/06_Snapshot_Lifecycle_Management.md) | Exporting, downloading, uploading, and managing Migration snapshots. |
| **Environment Cloning** | [`05_Application_Creation_and_Lifecycle_Management/01_Environment_Lifecycle_and_Maintenance/09_Environment_Cloning_Master_Guide.md`](05_Application_Creation_and_Lifecycle_Management/01_Environment_Lifecycle_and_Maintenance/09_Environment_Cloning_Master_Guide.md) | One-step server-to-server pod replication via EPM Automate `cloneEnvironment`. |
| **On-Premises Hyperion to Cloud Migration** | [`05_Application_Creation_and_Lifecycle_Management/05_Migration_Reports_Auditing_and_OnPrem_Transition/02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md`](05_Application_Creation_and_Lifecycle_Management/05_Migration_Reports_Auditing_and_OnPrem_Transition/02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md) | Translating Classic/EPMA Hyperion Planning into Cloud EPM. |

---

## B — Blocks, Storage Physics & Essbase Kernel

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Essbase Architecture & History** | [`Essbase_Internal_Architecture/01_What_Is_Essbase.md`](Essbase_Internal_Architecture/01_What_Is_Essbase.md) | Why Essbase is NOT a relational database; multi-dimensional OLAP cubes. |
| **Sparse vs. Dense Dimensions** | [`Essbase_Internal_Architecture/03_Sparse_vs_Dense_Complete_Guide.md`](Essbase_Internal_Architecture/03_Sparse_vs_Dense_Complete_Guide.md) | Dense array offsets vs Sparse coordinate addresses; block size calculation formulas. |
| **Block Storage Anatomy (64KB Array)** | [`Essbase_Internal_Architecture/04_Block_Storage_Deep_Dive.md`](Essbase_Internal_Architecture/04_Block_Storage_Deep_Dive.md) | Input blocks vs Upper-level blocks; block creation triggers; concurrency locks. |
| **Index (`.IND`) & Page (`.PAG`) Files** | [`Essbase_Internal_Architecture/05_Index_and_Page_Files.md`](Essbase_Internal_Architecture/05_Index_and_Page_Files.md) | B-Tree index lookup mechanisms; page file fragmentation and restructuring. |
| **Hourglass Principle** | [`Essbase_Internal_Architecture/06_Hourglass_Principle.md`](Essbase_Internal_Architecture/06_Hourglass_Principle.md) | Optimal dimension outline ordering: Dense (largest to smallest) $\to$ Sparse (smallest to largest). |
| **Hybrid BSO Storage Engine** | [`Essbase_Internal_Architecture/13_Hybrid_BSO_Engine_Internals.md`](Essbase_Internal_Architecture/13_Hybrid_BSO_Engine_Internals.md) | Dynamic sparse calculations evaluated in-memory via ASO query engine. |
| **Essbase Memory Caches** | [`Essbase_Internal_Architecture/11_Kernel_and_Memory_Architecture.md`](Essbase_Internal_Architecture/11_Kernel_and_Memory_Architecture.md) | Index Cache, Data Cache, and Data File Cache tuning. |

---

## C — Calculations, Business Rules & Groovy

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Calc Manager Canvas & System Views** | [`Calc Manager/Calculations_and_Allocations/01_UI_Canvas_and_Navigation/01_System_Views_and_Architecture.md`](Calc%20Manager/Calculations_and_Allocations/01_UI_Canvas_and_Navigation/01_System_Views_and_Architecture.md) | Visual flowchart design, system views, relational repository tables (`HSP_CALCMGR_RULES`). |
| **Visual Palette Components (8 Types)** | [`Calc Manager/Calculations_and_Allocations/02_Palette_Objects_Deep_Dive/01_Formula_Component.md`](Calc%20Manager/Calculations_and_Allocations/02_Palette_Objects_Deep_Dive/01_Formula_Component.md) | Formulas, Scripts, Conditions, Member Blocks, Member Ranges (LOOP), and FIX objects. |
| **System Templates (8 Types)** | [`Calc Manager/Calculations_and_Allocations/03_System_Templates_Deep_Dive/01_Allocation_Template.md`](Calc%20Manager/Calculations_and_Allocations/03_System_Templates_Deep_Dive/01_Allocation_Template.md) | Allocations, Level-to-Level cascades, Clear Data, Copy Data, Currency Conversion. |
| **Bottom-Up vs. Top-Down Calculation** | [`Calc Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/01_Execution_Modes_BottomUp_vs_TopDown.md`](Calc%20Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/01_Execution_Modes_BottomUp_vs_TopDown.md) | Engine execution modes; avoiding the 300x slower sparse `IF` trap. |
| **Block Creation & Integrity** | [`Calc Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/02_Block_Creation_and_Data_Integrity.md`](Calc%20Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/02_Block_Creation_and_Data_Integrity.md) | Dangers of `SET CREATEBLOCKONEQ ON`; sparse block explosion remediation. |
| **Groovy Business Rules Architecture** | [`Calc Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/01_Groovy_Rule_Architecture_in_Calc_Manager.md`](Calc%20Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/01_Groovy_Rule_Architecture_in_Calc_Manager.md) | JVM sandbox execution, Planning Java object model, and REST execution triggers. |
| **Dynamic Micro-FIX via Groovy** | [`Calc Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/02_Dynamic_FIX_Generation_and_Context_Slicing.md`](Calc%20Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/02_Dynamic_FIX_Generation_and_Context_Slicing.md) | Reading `cell.isEdited()` to restrict calculations to modified coordinates (147x speedup). |
| **Pre-Save Veto Validation in Groovy** | [`Calc Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/03_Data_Grid_Calculations_and_Veto_Exceptions.md`](Calc%20Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/03_Data_Grid_Calculations_and_Veto_Exceptions.md) | Halting invalid data saves with `throwVetoException()` and displaying custom alert dialogs. |

---

## D — Dimensions, Members & Data Movement

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Universal Member Properties** | [`Dimension_Properties/01_Universal_Member_Properties.md`](Dimension_Properties/01_Universal_Member_Properties.md) | Data Storage options, Consolidation Operators (`+`, `-`, `~`, `^`), and Two-Pass Calc. |
| **Account Dimension Types** | [`Dimension_Properties/02_Account_Dimension_Deep_Dive.md`](Dimension_Properties/02_Account_Dimension_Deep_Dive.md) | Expense, Revenue, Asset, Liability, Equity, Saved Assumption, and Time Balance properties. |
| **Solve Order Deep Dive** | [`Dimension_Properties/10_Advanced_Solve_Order_and_Formula_Execution.md`](Dimension_Properties/10_Advanced_Solve_Order_and_Formula_Execution.md) | Resolving calculation order precedence between accounts, scenarios, and periods. |
| **Smart Lists Storage Physics** | [`Smart_Lists/01_Smart_Lists_Architecture_and_Storage_Physics.md`](Smart_Lists/01_Smart_Lists_Architecture_and_Storage_Physics.md) | Text-to-ID mappings; missing value storage behavior; calc script integration. |
| **Data Maps Core Architecture** | [`Data_Maps_and_Exchange/01_Data_Maps_Architecture_and_Design/01_Data_Maps_Core_Architecture_and_HSP_Tables.md`](Data_Maps_and_Exchange/01_Data_Maps_Architecture_and_Design/01_Data_Maps_Core_Architecture_and_HSP_Tables.md) | Mapping definitions in `HSP_MAP`; unmapped dimension handling; cube synchronization. |
| **Smart Push Real-Time Sync** | [`Data_Maps_and_Exchange/02_Smart_Push_Internals/01_Smart_Push_Architecture_and_Form_Sync.md`](Data_Maps_and_Exchange/02_Smart_Push_Internals/01_Smart_Push_Architecture_and_Form_Sync.md) | Streaming form save data directly into ASO cubes using in-memory load buffers. |
| **ASO Slice Merging & Compaction** | [`Data_Maps_and_Exchange/02_Smart_Push_Internals/03_ASO_Slice_Merge_and_Compaction_Strategies.md`](Data_Maps_and_Exchange/02_Smart_Push_Internals/03_ASO_Slice_Merge_and_Compaction_Strategies.md) | Preventing the 256 ASO slice limit; merge with zero elimination vs incremental slice merge. |
| **Cross-Cube `@XREF` and `@XWRITE`** | [`Data_Maps_and_Exchange/03_Cross_Cube_XREF_and_XWRITE/01_XREF_Deep_Dive_and_Pull_Architecture.md`](Data_Maps_and_Exchange/03_Cross_Cube_XREF_and_XWRITE/01_XREF_Deep_Dive_and_Pull_Architecture.md) | Programmatic cube-to-cube read/write scripts; location aliases and network protocols. |

---

## E — EPM Automate & DevOps Scripting

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **EPM Automate Installation & Auth** | [`EPM_Automate/01_Architecture_Installation_and_Authentication.md`](EPM_Automate/01_Architecture_Installation_and_Authentication.md) | Password encryption, OAuth token generation, and unattended CI/CD credentials. |
| **Automated Snapshot Backups** | [`EPM_Automate/02_Environment_and_Snapshot_Lifecycle.md`](EPM_Automate/02_Environment_and_Snapshot_Lifecycle.md) | Scripting nightly exports, downloads to local storage, and snapshot cleanup. |
| **Data & Metadata Load Automation** | [`EPM_Automate/03_Data_and_Metadata_Automation.md`](EPM_Automate/03_Data_and_Metadata_Automation.md) | Headless `uploadfile`, `importmetadata`, `importdata`, and `restructurecube`. |
| **Enterprise Batch Runbooks** | [`EPM_Automate/05_Enterprise_Scripting_Runbooks_and_Error_Handling.md`](EPM_Automate/05_Enterprise_Scripting_Runbooks_and_Error_Handling.md) | PowerShell / Bash wrapper scripts with error trapping and email notification alerting. |
| **CLI Return Codes & Troubleshooting** | [`EPM_Automate/06_Troubleshooting_Return_Codes_and_Interview_Guide.md`](EPM_Automate/06_Troubleshooting_Return_Codes_and_Interview_Guide.md) | Decoding return code `0` (Success), `1` (Failure), `6` (Session Expired), `7` (Invalid Credentials). |

---

## F — Forms, Web Grids & Spread Operations

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Form Grid & Display Properties** | [`Form_Properties/01_Grid_and_Display_Properties.md`](Form_Properties/01_Grid_and_Display_Properties.md) | Precision, row/column suppression, dynamic aliases, segment widths, read-only formatting. |
| **Grid Spread Operations (50 KB)** | [`02_User_Interface_and_Navigation/Oracle_EPM_Grid_Spread_Master_Guide.md`](02_User_Interface_and_Navigation/Oracle_EPM_Grid_Spread_Master_Guide.md) | Proportional, Even, and Fill spreading; cell lock handling and historical proportion spreading. |
| **Mass Allocation in Web Forms (69 KB)** | [`02_User_Interface_and_Navigation/Oracle_EPM_Mass_Allocate_Master_Guide.md`](02_User_Interface_and_Navigation/Oracle_EPM_Mass_Allocate_Master_Guide.md) | Client-side spreading across sparse dimensions based on basis driver ratios. |
| **Action Menus & Context Relay** | [`Action_Menus/01_Action_Menu_Architecture_and_Context_Relay.md`](Action_Menus/01_Action_Menu_Architecture_and_Context_Relay.md) | Right-click menu configuration, passing POV member tokens into business rules. |
| **The 9 Menu Item Types** | [`Action_Menus/02_The_9_Menu_Item_Types_Complete_Guide.md`](Action_Menus/02_The_9_Menu_Item_Types_Complete_Guide.md) | Business Rule, URL, Manage Approvals, Job Console, Open Form, and Navigation Flow targets. |

---

## G — Governance, Approvals & Workflows

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Approval Unit Hierarchies (AUH)** | [`03_Workflow_and_Task_Management/Oracle_EPM_Approval_Flow_Master_Guide.md`](03_Workflow_and_Task_Management/Oracle_EPM_Approval_Flow_Master_Guide.md) | Entity + Scenario + Version approval paths; promotional sign-offs and cell write lockouts. |
| **Task Lists & Task Manager** | [`03_Workflow_and_Task_Management/Oracle_EPM_Task_Lists_Master_Guide.md`](03_Workflow_and_Task_Management/Oracle_EPM_Task_Lists_Master_Guide.md) | Chronological user task checklists, completion dependencies, and status dashboards. |
| **Daily Automated Maintenance Window** | [`04_System_Administration/Oracle_EPM_Daily_Maintenance_Master_Guide.md`](04_System_Administration/Oracle_EPM_Daily_Maintenance_Master_Guide.md) | 1-hour automated pod maintenance, artifact snapshot creation, and Essbase index defrag. |
| **Compliance & Audit Logging** | [`04_System_Administration/Oracle_EPM_Audit_Master_Guide.md`](04_System_Administration/Oracle_EPM_Audit_Master_Guide.md) | Cell data change tracking, security audit, metadata change logs, and SOX exports. |

---

## I — Integrations, ETL & Pipelines

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Data Integration Master Guide (824 Lines)** | [`Data_Integration/Oracle_EPM_Data_Integration_Master_Guide.md`](Data_Integration/Oracle_EPM_Data_Integration_Master_Guide.md) | Comprehensive reference for Source Systems, Import Formats, Locations, and Load Rules. |
| **Member Mapping Rules (5 Types)** | [`Data_Integration/Oracle_EPM_Data_Integration_Master_Guide.md#component-4-member-mappings-data-load-mappings`](Data_Integration/Oracle_EPM_Data_Integration_Master_Guide.md#component-4-member-mappings-data-load-mappings) | Explicit, Like (wildcard), Between (range), In (list), and Multi-Dimension mapping rules. |
| **EPM Integration Agent Setup** | [`Data_Integration/Oracle_EPM_Data_Integration_Master_Guide.md#component-1-source-system`](Data_Integration/Oracle_EPM_Data_Integration_Master_Guide.md#component-1-source-system) | Extracting on-premises relational databases (SQL Server, Oracle DB) into cloud cubes. |
| **Integration Pipelines & REST APIs** | [`Data_Maps_and_Exchange/04_Data_Exchange_and_Pipelines/01_Data_Exchange_Pipeline_Architecture.md`](Data_Maps_and_Exchange/04_Data_Exchange_and_Pipelines/01_Data_Exchange_Pipeline_Architecture.md) | Multi-stage orchestration pipelines executing data loads, business rules, and Smart Push. |

---

## M — Modules & Pre-Built Business Processes

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Financials Module (`OEP_FS`)** | [`EPBCS_Modules_and_Business_Processes/01_Financials_Module_OEP_FS.md`](EPBCS_Modules_and_Business_Processes/01_Financials_Module_OEP_FS.md) | Revenue, Expense, Balance Sheet, Cash Flow architecture and seeded calculation rules. |
| **Workforce Module (`OEP_WFP`)** | [`EPBCS_Modules_and_Business_Processes/02_Workforce_Module_OEP_WFP.md`](EPBCS_Modules_and_Business_Processes/02_Workforce_Module_OEP_WFP.md) | Employee and Job granularity; salary, tax, benefit, and compensation modeling. |
| **Capital Module (`OEP_CPX`)** | [`EPBCS_Modules_and_Business_Processes/03_Capital_Module_OEP_CPX.md`](EPBCS_Modules_and_Business_Processes/03_Capital_Module_OEP_CPX.md) | New asset requests, CIP assets, straight-line and accelerated depreciation modeling. |
| **Projects Module (`OEP_PFP`)** | [`EPBCS_Modules_and_Business_Processes/04_Projects_Module_OEP_PFP.md`](EPBCS_Modules_and_Business_Processes/04_Projects_Module_OEP_PFP.md) | Internal, Capital, and Contract project financial tracking. |
| **Strategic Modeling (HSF)** | [`EPBCS_Modules_and_Business_Processes/05_Strategic_Modeling_HSF.md`](EPBCS_Modules_and_Business_Processes/05_Strategic_Modeling_HSF.md) | Long-range financial planning, M&A purchase price allocation, Monte Carlo simulation. |
| **Cross-Module Data Mesh & Offsets** | [`EPBCS_Modules_and_Business_Processes/06_Cross_Module_Integration_and_Data_Flow.md`](EPBCS_Modules_and_Business_Processes/06_Cross_Module_Integration_and_Data_Flow.md) | Seeded data maps connecting Workforce and Capital to Financials; offset accounting. |

---

## S — Security, Valid Intersections & Smart View

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **Role-Based Access Control (RBAC)** | [`01_Security_and_Access/Oracle_EPM_Access_Control_Master_Guide.md`](01_Security_and_Access/Oracle_EPM_Access_Control_Master_Guide.md) | Service Administrator, Power User, User, and Viewer predefined roles. |
| **Valid Intersections (VI) Setup** | [`01_Security_and_Access/Oracle_EPM_Valid_Intersections_Master_Guide.md`](01_Security_and_Access/Oracle_EPM_Valid_Intersections_Master_Guide.md) | Eliminating impossible dimensional coordinate combinations in forms and calculations. |
| **Cell-Level Security (CLS)** | [`Form_Properties/07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md`](Form_Properties/07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md) | Restricting Read/Write/Deny access at specific cell coordinates independently of roles. |
| **Smart View Ad-Hoc Grid Physics** | [`Smart_View_and_Ad_Hoc/02_Ad_Hoc_Analysis_Grid_Operations_and_Physics.md`](Smart_View_and_Ad_Hoc/02_Ad_Hoc_Analysis_Grid_Operations_and_Physics.md) | Zoom in/out, Keep Only, Remove Only, Pivot, and Submit Data mechanics. |
| **Flex Forms in Smart View** | [`Smart_View_and_Ad_Hoc/04_Flex_Forms_and_Advanced_Worksheets.md`](Smart_View_and_Ad_Hoc/04_Flex_Forms_and_Advanced_Worksheets.md) | Preserving custom Excel formulas, column sorting, and dynamic row filtering. |

---

## T — Troubleshooting, Incidents & Interview Prep

| Concept / Operational Procedure | Canonical Documentation Chapter | Key Takeaway / Direct Link |
| :--- | :--- | :--- |
| **120+ Twisted Trap Questions (Part 1)** | [`Techno_Functional_Consultant_Review_Bible/04_Twisted_Interview_Questions_Part_1_Architecture_and_Essbase.md`](Techno_Functional_Consultant_Review_Bible/04_Twisted_Interview_Questions_Part_1_Architecture_and_Essbase.md) | 30 wicked questions on Essbase Kernel, block physics, and outline design. |
| **120+ Twisted Trap Questions (Part 2)** | [`Techno_Functional_Consultant_Review_Bible/05_Twisted_Interview_Questions_Part_2_Calc_Manager_and_Groovy.md`](Techno_Functional_Consultant_Review_Bible/05_Twisted_Interview_Questions_Part_2_Calc_Manager_and_Groovy.md) | 30 wicked questions on Calc Manager, Top-Down performance, and Groovy rules. |
| **120+ Twisted Trap Questions (Part 3)** | [`Techno_Functional_Consultant_Review_Bible/06_Twisted_Interview_Questions_Part_3_Forms_SmartPush_DataMaps.md`](Techno_Functional_Consultant_Review_Bible/06_Twisted_Interview_Questions_Part_3_Forms_SmartPush_DataMaps.md) | 30 wicked questions on Web Forms, Smart Push, and data movement. |
| **120+ Twisted Trap Questions (Part 4)** | [`Techno_Functional_Consultant_Review_Bible/07_Twisted_Interview_Questions_Part_4_Modules_and_Troubleshooting.md`](Techno_Functional_Consultant_Review_Bible/07_Twisted_Interview_Questions_Part_4_Modules_and_Troubleshooting.md) | 30 wicked questions on EPBCS Modules, Security, and system administration. |
| **10 Production Incident Playbooks** | [`Techno_Functional_Consultant_Review_Bible/08_Emergency_Scenario_Walkthroughs_and_War_Stories.md`](Techno_Functional_Consultant_Review_Bible/08_Emergency_Scenario_Walkthroughs_and_War_Stories.md) | Emergency remediation for 45GB database bloat, HTTP 504 timeouts, ASO slice limits. |

