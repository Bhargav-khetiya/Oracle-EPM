﻿# 🏛️ On-Premises Hyperion to Cloud EPM Migration & Role Mapping
## Complete Transition Architecture, Application Conversion Paths, and Security Role Mapping

> **Source Systems:** Oracle Hyperion EPM Release 11.1.2.4.x / 11.2.x (On-Premises)  
> **Target Systems:** Oracle Fusion Cloud EPM (Enterprise & Standard Subscriptions)  
> **Reference Standard:** *Oracle Fusion Cloud EPM Administering Migration (E96251)* Chapter 4 & Appendix A  
> **Scope:** Architecture shift, prerequisites, 2-step migration methodology, application-specific pathways, and comprehensive role mapping

---

## 🧭 1. Architectural Transformation: On-Premises vs. Cloud EPM

Migrating from on-premises Hyperion to Oracle Cloud EPM represents a generational shift in architecture:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       HYPERION ON-PREM vs CLOUD EPM                         │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 🏢 HYPERION ON-PREMISES (11.1.2.4/11.2)│ ☁️ ORACLE FUSION CLOUD EPM           │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • On-prem Windows/Linux servers      │ • Fully managed Oracle Cloud (OCI)   │
│ • Direct Relational DB Access (SQL)  │ • Zero direct DB access (REST/EPM Auto)│
│ • Custom Defined Functions (CDFs)    │ • Groovy business rules              │
│ • Local file system & `essbase.cfg`  │ • Autonomous Essbase tuning & Hybrid │
│ • Shared Services Native Directory   │ • OCI IAM / IDCS Identity Domains    │
│ • Manual patch cycles (annual)       │ • Continuous monthly updates         │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 🚫 2. Prerequisites & Unsupported Artifacts

### Unsupported On-Premises Artifacts
The following artifacts cannot be migrated to Cloud EPM and must be redesigned or retired:
- **`essbase.cfg` Configurations:** Server-level Essbase settings are managed autonomously by Oracle.
- **Custom Java CDFs (Custom Defined Functions):** Replace with native Calc Manager functions or **Groovy scripts**.
- **Direct Database SQL Scripts:** Any custom triggers, stored procedures, or direct SQL tables are not permitted in Cloud. Use **Data Integration** or **EPM Integration Agent**.
- **Hyperion Enterprise & Obsolete EPMA Applications:** Must be converted to Classic Planning outlines before LCM export.
- **Reserved Words Collision:** Ensure member names do not collide with Cloud EPM reserved words (e.g., `Period`, `Year`, `Scenario`, `Version`, `Entity`, `Account`, `CrossDim`).

---

## 🔄 3. The 2-Step Migration Methodology

Every on-premises to Cloud migration follows a mandatory 2-step sequence:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ STEP 1: MIGRATE THE SECURITY MODEL                                          │
│ 1. Extract Users & Groups from Shared Services via Lifecycle Management    │
│ 2. Create Security Upload CSV files mapped to Cloud Application Roles       │
│ 3. Bulk provision user accounts into OCI Identity Management (IDCS / IAM)   │
│ 4. Import Security Groups into Cloud Access Control                         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ STEP 2: MIGRATE APPLICATION ARTIFACTS                                       │
│ 1. Export application metadata, forms, rules, and data via on-prem LCM      │
│ 2. Package into a standard ZIP snapshot archive                             │
│ 3. Upload ZIP to Cloud EPM via Migration Console or EPM Automate            │
│ 4. Execute snapshot import and perform Database Refresh                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 4. Application-Specific Migration Pathways

### A. Planning (On-Premises) ➔ Planning (Cloud)
- **Supported Releases:** Hyperion Planning 11.1.2.4.x and 11.2.x.
- **Artifacts Migrated:** Relational metadata, dimensions, members, aliases, attributes, Smart Lists, data forms, task lists, Calc Manager rules, and Essbase data slices.
- **Key Consideration:** If the on-premises application uses EPMA, convert the application to **Classic Planning** within on-premises prior to running LCM export.
- **Essbase Data:** Export Essbase data to native text export files or include stored data in the LCM snapshot.

---

### B. Financial Management (HFM) ➔ Financial Consolidation and Close (FCCS)
- **Architecture Difference:** HFM uses custom VB Script rules (`.rle`), whereas FCCS uses pre-built, standardized consolidation dimensions with Configurable Consolidations / Insertion Rules.
- **Workflow:**
  1. Extract HFM metadata using on-premises LCM.
  2. Map HFM Account, Entity, and Custom dimensions to FCCS standard dimensions (`Consolidation`, `Currency`, `View`, `Movement`, `Data Source`).
  3. Re-implement custom HFM rules as **FCCS Insertion Rules**.

---

### C. Profitability & Cost Management (HPCM) ➔ Cloud PCM / EPCM
- **Supported Releases:** HPCM 11.1.2.4.130+.
- **Workflow:**
  1. In on-premises HPCM, open Model Architecture and export the model template.
  2. Upload the exported `.zip` template to Cloud PCM via Migration.
  3. Execute template import to generate calculation rules, rule sets, and driver allocations.

---

### D. Strategic Finance (HSF) ➔ Strategic Modeling (SM)
- **Workflow:**
  1. In on-premises HSF, check out all offline models (`.alc` files).
  2. In Cloud EPM, create a Planning Modules application and **Enable Strategic Modeling**.
  3. Upload and import the `.alc` model files directly into Strategic Modeling.
  4. Build consolidation roll-up structures across individual models.

---

### E. Data Relationship Management (DRM) ➔ Enterprise Data Management (EDM)
- **Workflow:** Export DRM hierarchies, properties, and node sets to CSV/JSON files. Import into Oracle Cloud EDM applications, viewpoints, and node types.

---

### F. FDMEE (On-Premises) ➔ Data Integration / Data Management (Cloud)
- **Workflow:**
  - Import Formats, Location Mappings, and Validation Rules migrate cleanly via LCM.
  - Custom SQL / Jython scripts in FDMEE must be reviewed. Cloud EPM supports **Jython** for event scripts, but database SQL queries must be converted to query through the **EPM Integration Agent** or REST APIs.

---

## 👥 5. Appendix A: On-Premises to Cloud Role Mapping Matrix

In on-premises Hyperion Shared Services, dozens of granular security roles exist across products. In Oracle Cloud EPM, security is streamlined into **4 Primary Functional Roles**:

| Cloud EPM Role | Permissions Level | Description |
|:---|:---:|:---|
| **Service Administrator** | Full Admin | Complete operational control: create/delete apps, manage security, run all jobs. |
| **Power User** | High Privileges | Create forms, reports, business rules; manage approval units; cannot drop apps. |
| **User** | Interactive Data Entry | Enter and submit data into forms, run business rules, view reports. |
| **Viewer** | Read-Only | Read data in reports, forms, and dashboards; no data entry or rule execution. |

---

### Planning Role Mapping

| If User Has Only These On-Premises Roles | Assign User to This Cloud EPM Role |
|:---|:---|
| • Planning Administrator<br>• Provisioning Manager | **Service Administrator** |
| • Interactive User<br>• Mass Allocate<br>• Calculation Manager - Rule Designer | **Power User** |
| • Planner<br>• Calculation Manager - Rule Run | **User** |
| • Viewer<br>• Calculation Manager - Rule View | **Viewer** |

---

### Financial Management (HFM) Role Mapping

| If User Has Only These On-Premises Roles | Assign User to This Cloud EPM Role (FCCS) |
|:---|:---|
| • Application Administrator<br>• Security Administrator | **Service Administrator** |
| • Power User<br>• Manage Data Records<br>• Consolidation Specialist | **Power User** |
| • All Users (Standard User)<br>• Journal Preparer / Approver | **User** |
| • Read Only User | **Viewer** |

---

### Profitability and Cost Management (HPCM) Role Mapping

| If User Has Only These On-Premises Roles | Assign User to This Cloud EPM Role |
|:---|:---|
| • Profitability Administrator | **Service Administrator** |
| • Profitability Application Designer<br>• Model Builder | **Power User** |
| • Calculation User<br>• Cost Analyst | **User** |
| • Report Viewer | **Viewer** |

---

## 🛠️ On-Premises Migration Execution Checklist

```
Pre-Migration Phase:
  [ ] Audit on-premises member names for Cloud EPM reserved words
  [ ] Identify all custom CDFs and convert logic to Groovy scripts
  [ ] Clean up orphaned shared members in on-premises outlines
  [ ] Confirm on-premises version is at supported release (11.1.2.4.x+)

Security Phase:
  [ ] Export Shared Services native directory users and groups
  [ ] Map on-premises roles to the 4 Cloud EPM functional roles using Appendix A
  [ ] Provision user accounts in OCI IAM / IDCS
  [ ] Import security groups into Cloud Access Control

Artifact Migration Phase:
  [ ] Export full application snapshot using on-premises LCM utility
  [ ] Zip the LCM export directory
  [ ] Upload snapshot to Cloud EPM via EPM Automate (epmautomate uploadfile)
  [ ] Import snapshot via Migration Console
  [ ] Execute full Database Refresh in Cloud EPM
  [ ] Deploy and validate all Calculation Manager rules
  [ ] Reconcile financial balances between On-Premises and Cloud
```

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Why cannot on-premises Hyperion Planning EPMA outlines be imported directly into Cloud EPM—
**Answer:** Oracle Enterprise Performance Management Architect (EPMA) relies on an on-premises relational metadata engine that is not supported in Cloud EPM. Prior to migration, EPMA applications must be transformed to **Classic Planning** applications or dimensions must be exported as flat outline files (`.csv` / `.txt`) using the Outline Load Utility before importing into Cloud EPM.

### Q2: How do on-premises Shared Services security roles map to Oracle Cloud EPM predefined roles—
**Answer:** On-premises Shared Services used granular provisioned roles (e.g. *Planner*, *Interactive User*, *Mass Allocate*). Cloud EPM consolidates security into 4 predefined functional roles:
1. **Service Administrator** (Full control)
2. **Power User** (Manage forms, rules, and task lists)
3. **User** (Data entry, run rules, view reports)
4. **Viewer** (Read-only reporting)

### Q3: What happens to on-premises custom Essbase Calc Scripts during migration to Cloud EPM—
**Answer:** Standalone `.csc` calc scripts stored in the Essbase filesystem are not natively exposed in the Cloud EPM web interface. Calc scripts must be converted into **Calc Manager Business Rules** in Calculation Manager. Furthermore, scripts using unsupported functions (such as custom C-based User Defined Functions or file-system `@EXECUTE` calls) must be refactored into Groovy rules or native functions.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [01_Migration_Reports_and_Compliance_Auditing.md](./01_Migration_Reports_and_Compliance_Auditing.md) |
| **Next → Runbooks** | [01_Prod_to_Demo_Complete_Runbook.md](../06_Automation_Runbooks_and_Troubleshooting/01_Prod_to_Demo_Complete_Runbook.md) |
| **Master Overview** | [01_Lifecycle_Strategy_and_Overview.md](../01_Environment_Lifecycle_and_Maintenance/01_Lifecycle_Strategy_and_Overview.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |

