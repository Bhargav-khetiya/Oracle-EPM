# 📋 Project Register: Architectural Decisions, Assumptions, Risks, and Open Questions

This register provides a centralized governance log of all foundational architecture decisions, technical assumptions, environmental dependencies, operational risks, and open client questions across the Oracle EPM Cloud implementation.

---

## 1. Architectural Decisions Register

| Decision ID | Architecture Topic | Decision Made | Rationale & Justification | Alternatives Considered | Trade-Offs & Impact |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **DEC-01** | **Multi-Cube Topology** | Deploy a dual-engine architecture: BSO input cubes (`OEP_FS`, `OEP_WFP`, `OEP_CPX`) paired with an ASO Reporting cube (`OEP_REP`). | Allows complex driver-based budgeting in BSO while providing sub-second ad-hoc query performance for business analysts in ASO. | Single monolithic BSO cube. | Requires automated Data Maps / Smart Push to synchronize data between cubes. |
| **DEC-02** | **Hybrid BSO Calc Mode** | Enable Hybrid BSO calculation mode (`SET HYBRIDBSOINCALCSCRIPT FULL;`) across all BSO plan types. | Eliminates long batch calculation scripts (`CALC DIM`, `AGG`) by dynamically aggregating sparse upper-level members in-memory via the ASO query engine. | Classic BSO with batch aggregation scripts. | Upper-level sparse members cannot hold manual input data; requires outline cleanup of legacy two-pass settings on sparse dimensions. |
| **DEC-03** | **Form Save Performance** | Standardize on Groovy Dynamic micro-FIX rules instead of legacy Essbase calculation scripts on web forms. | Groovy inspects `operation.grid.dataCellIterator`, identifies modified cells, and slices calculations to edited coordinates only, cutting save times from 45s to 200ms. | Full-slice Essbase calculation scripts on form save. | Requires implementation team members to possess Groovy/Java scripting skills. |
| **DEC-04** | **Data Ingestion Strategy** | Utilize Data Integration (Data Management) pipelines with EPM Integration Agent for direct ERP ledger extraction. | Provides automated GL data extraction, staging in `TDATASEG`, drill-through audit capability, and transformation via Explicit and Like mapping rules. | Manual CSV file uploads or direct SQL table writes. | Requires on-premises EPM Integration Agent service installation and firewall port configuration. |
| **DEC-05** | **Security Model** | Enforce a defense-in-depth security model: Predefined Cloud Roles (OCI IAM) + Dimension Member Access + Cell-Level Security (CLS). | Prevents unauthorized data modifications across sensitive executive compensation and financial lines while maintaining broad read-only reporting access. | Simple dimension-only security. | Added administrative maintenance overhead when configuring CLS matrix definitions. |

---

## 2. Technical & Environmental Assumptions

| Assumption ID | Architecture Area | Assumption Statement | Risk if Assumption is Invalid | Verification Method |
| :---: | :--- | :--- | :--- | :--- |
| **ASM-01** | **Cloud Pod Release** | Target Oracle EPM Cloud instances are on current monthly update releases (24.xx or newer), supporting Hybrid BSO calculation script commands and Groovy rules. | Outdated syntax or unsupported CDF functions could fail validation. | Check EPM Automate `version` command output during environment onboarding. |
| **ASM-02** | **Maintenance Window** | A 1-hour daily maintenance window (02:00–03:00 UTC) can be dedicated to automated pod patching and cold backup snapshots without disrupting global planners. | Nightly batch jobs could collide with maintenance reboots, causing job aborts. | Confirm user time zones across Europe, Americas, and APAC to select optimal window. |
| **ASM-03** | **Dense Block Sizing** | The dense dimension outline design will yield physical block sizes strictly between 50KB and 250KB. | Blocks exceeding 1MB cause RAM cache starvation and excessive disk paging (`.PAG`). | Execute outline inspection script and review Essbase database statistics. |
| **ASM-04** | **ERP General Ledger Structure** | External ERP systems (Oracle Fusion ERP, SAP, or NetSuite) provide monthly trial balance extracts with consistent account segment lengths. | Inconsistent source formats will break Data Integration staging rules. | Inspect sample trial balance CSV files and validate delimiter consistency. |

---

## 3. Operational Risks & Mitigation Playbooks

| Risk ID | Operational Risk | Probability / Impact | Root Cause | Preventive Mitigation & Remediation Playbook |
| :---: | :--- | :---: | :--- | :--- |
| **RSK-01** | **Database Explosive Bloat** | Medium / High | Developer adds `SET CREATEBLOCKONEQ ON;` inside a broad calculation script, creating millions of empty sparse blocks. | **Mitigation**: Strictly wrap block-creation logic inside narrow `FIX` statements. Execute `CLEARBLOCK EMPTY;` during daily maintenance. |
| **RSK-02** | **ASO 256 Slice Limit Breach** | High / Critical | High-frequency Smart Push triggers create incremental data slices on the ASO cube until the 256-slice hard limit is reached, causing form saves to abort. | **Mitigation**: Schedule automated EPM Automate `mergeDataSlices` jobs to compact slices nightly with zero elimination. |
| **RSK-03** | **HTTP 504 Gateway Timeout** | Medium / High | Web form save triggers an unoptimized Top-Down calculation script that exceeds the 60-second cloud proxy timeout. | **Mitigation**: Convert the rule to Groovy dynamic micro-FIX; enforce `@CALCMODE(BOTTOMUP);` and eliminate sparse `IF` conditions. |
| **RSK-04** | **Double-Counting in Financials** | Medium / Critical | Compensation from Workforce and Depreciation from Capital are pushed into Financials without populating balance sheet offset accounts. | **Mitigation**: Enforce the EPBCS Seeded Offset Accounting Framework detailed in [`EPBCS_Modules_and_Business_Processes/06_Cross_Module_Integration_and_Data_Flow.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPBCS_Modules_and_Business_Processes/06_Cross_Module_Integration_and_Data_Flow.md). |

---

## 4. Open Questions & Required Confirmations

| Question ID | Architectural Topic | Specific Open Question | Assigned Owner | Action Required to Resolve |
| :---: | :--- | :--- | :---: | :--- |
| **OQ-01** | **EPM Integration Agent** | Will the customer host the EPM Integration Agent on an internal corporate server to enable direct SQL extraction from the on-premises General Ledger, or will external ETL push flat files to an SFTP server? | Client Infrastructure Lead | Confirm server provisioning and open outbound HTTPS port 443 to Oracle Cloud EPM. |
| **OQ-02** | **Fiscal Calendar Structure** | Does the retail division require a 4-4-5 / 4-5-4 retail calendar frequency, or will the entire enterprise standardize on a 12-month calendar starting in January? | Lead Financial Controller | **Critical Decision**: Calendar frequency is immutable post-application creation; must be finalized before running the creation wizard. |
| **OQ-03** | **Multi-Currency Requirements** | Which entities require multi-currency translation into parent currencies, and what is the designated triangulation currency for European subsidiaries? | Corporate Accounting Lead | Confirm currency dimension configuration in Application Creation Step 4. |
| **OQ-04** | **Directory Naming Alignment** | Should the repository folders `01_Security_and_Access`, `02_User_Interface_and_Navigation`, `03_Workflow_and_Task_Management`, and `04_System_Administration` remain with their current disk names or be renamed to `12A_Security_and_Access` through `12D_System_Administration`? | Documentation Reviewer / Lead | Confirm preference for on-disk folder naming versus master index mapping. |

