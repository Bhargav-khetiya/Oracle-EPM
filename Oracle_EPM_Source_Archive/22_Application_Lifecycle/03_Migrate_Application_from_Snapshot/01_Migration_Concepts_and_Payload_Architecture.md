# 📥 Path 3: Migrate Application — Master Overview
## Concepts, Architecture, Snapshot Payloads, Version Governance & Migration Methods

> **Entry Point (Landing Page):** `Planning Landing Page → MIGRATE button`  
> **Entry Point (Maintenance):** `Home → Tools (🔧) → Migration`  
> **Core Concept:** Creates or restores an entire Oracle Cloud EPM application from an LCM snapshot (`.zip`) archive  
> **Role Requirement:** Service Administrator (or user with `Migrations - Administer` granular role)  
> **Irreversibility:** ⚠️ High — Importing a full snapshot overwrites or recreates the application

---

## 🧭 Entry Point: Planning Landing Page [MIGRATE] Button

When you log into a newly provisioned or reset Oracle Cloud EPM instance, the third card on the landing page is **Migrate**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                               Planning                                      │
│                                                                             │
│   ┌──────────────────────┐  ┌──────────────────────┐  ┌─────────────────┐ │
│   │ 📦 Create a sample   │  │ 📑 Create a new      │  │ 📥 Migrate      │ │
│   │    application       │  │    application       │  │                 │ │
│   │                      │  │                      │  │ Create your app │ │
│   │ Check out how a      │  │ Jump right in and    │  │ by uploading a  │ │
│   │ built out solution   │  │ start creating your  │  │ snapshot        │ │
│   │ looks by creating a  │  │ own application      │  │                 │ │
│   │ sample application   │  │                      │  │                 │ │
│   │                      │  │                      │  │                 │ │
│   │      [CREATE]        │  │       [START]        │  │    [MIGRATE]    │ │
│   └──────────────────────┘  └──────────────────────┘  └────────┬────────┘ │
└────────────────────────────────────────────────────────────────┼────────────┘
                                                                 │ Click
                                                                 ▼
                                                  ┌───────────────────────────┐
                                                  │ Opens Migration Console:  │
                                                  │ Snapshots / Upload Dialog │
                                                  └───────────────────────────┘
```

---

## 🤔 When to Choose Path 3 (MIGRATE)

| Enterprise Scenario | Operational Description | Recommended Tool |
|:---|:---|:---|
| **Disaster Recovery** | Restoring an application to a known good historical state following accidental corruption or deletion. | Web UI or `epmautomate importsnapshot` |
| **Environment Promotion** | Promoting tested development artifacts from DEV/TEST into PRODUCTION during formal cutover. | `epmautomate copysnapshotfrominstance` |
| **Gold Build Deployment** | Provisioning multiple brand-new cloud instances using a standardized corporate blueprint template. | Web UI [MIGRATE] button |
| **On-Premises Migration** | Transitioning legacy Hyperion Planning (11.1.2.4/11.2) into Cloud EPM via on-prem LCM export. | Web UI [MIGRATE] button |
| **Cloning Sandbox for Testing** | Overwriting a Test/Demo instance with fresh Production data to perform project changes safely. | `epmautomate cloneEnvironment` |

---

## 📦 What is Inside an Application Snapshot?

An Oracle LCM Snapshot is a structured `.zip` archive containing relational metadata, dimensional schemas, XML configuration definitions, and compressed Essbase data:

| Component Category | Included in Snapshot? | Detailed Contents |
|:---|:---:|:---|
| **Application & Dimensions** | ✅ **YES** | Dimensions, members, aliases, attributes, UDAs, Smart Lists, evaluation orders |
| **Essbase Cubes & Data** | ✅ **YES** | Outlines (`.otl`), stored data blocks, and calculation scripts |
| **Forms & Grids** | ✅ **YES** | Data entry forms, composite forms, flex grids, and formatting rules |
| **Business Rules** | ✅ **YES** | Calc Manager rules, rulesets, templates, and Groovy scripts |
| **Security Groups & Roles** | ✅ **YES** | Access Control native directory groups, team definitions, and role bindings |
| **Data Management / Integration**| ✅ **YES** | Import formats, location mappings, data rules, and Workbench staging tables *(governed by LCM Mode)* |
| **Dashboards & Infolets** | ✅ **YES** | Dashboards 2.0, navigation flows, and custom cards |
| **Reports & Books** | ✅ **YES** | Financial Reporting (FR) reports, books, and batches |
| **Task Lists & Approvals** | ✅ **YES** | Task lists, Approval Unit Hierarchies (AUH), and promotional paths |
| **User Identity Accounts** | ❌ **NO** | User authentication accounts reside in OCI IAM / IDCS and must be provisioned in the Identity Domain |
| **Audit Trails (Application Audit)**| ❌ **NO** | Historical audit records are excluded from standard snapshots; backed up separately via business process audit tools |

---

## ⚖️ Environment Backup vs. Artifact Snapshot

Understanding the architectural distinction prevents recovery blunders:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    BACKUP ARCHITECTURE COMPARISON                           │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 🛡️ ENVIRONMENT BACKUP (OBJECT STORAGE)│ 📦 ARTIFACT SNAPSHOT (CLOUD STAGING) │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Generated automatically by Oracle  │ • Generated manually by Admins or via│
│   during daily maintenance.          │   nightly `exportsnapshot` jobs.     │
│ • Stored in encrypted, off-instance   │ • Stored directly in the Cloud EPM   │
│   Oracle Object Storage.             │   staging repository (Inbox/Outbox). │
│ • Retained for **60 days**.          │ • Retained for **60 days**; capped   │
│ • Restored via `restoreEnvironment`. │   at 150 GB cumulative storage.      │
│ • Protected against manual deletion. │ • Can be downloaded locally as .zip. │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## ⚠️ Version Compatibility & Upgrade Constraints

> [!CAUTION]
> **Strict Version Compatibility Rule:**  
> Cloud EPM receives monthly updates (e.g., 26.10, 26.11).  
> - **Supported:** Migrating from an **older or equal release** to a **newer release** (Cloud EPM automatically upgrades schemas during import).  
> - **Prohibited:** Migrating from a **newer release** to an **older release** (e.g., from 26.11 Test to 26.10 Prod during the blackout window).  
> Attempting an unsupported version import triggers:  
> `EPMLCM-26000: This snapshot is from Cloud EPM <version> that is incompatible with this update.`

---

## 🔄 The 4 Primary Migration Methods Compared

| Method | Interface | Best For | Local Download Required? |
|:---|:---:|:---|:---:|
| **1. Landing Page [MIGRATE]** | Web GUI | First-time application creation on a fresh pod | Yes (browser upload) |
| **2. Migration Console (`Tools → Migration`)** | Web GUI | Granular, selective updates into an existing app | Optional |
| **3. Server-to-Server (`copySnapshotFromInstance`)** | EPM Automate CLI | Automated promotions between Test and Prod | ❌ **No** (Direct streaming) |
| **4. Full Clone (`cloneEnvironment`)** | Web UI / CLI | 1-step complete replication of Prod to Demo | ❌ **No** (Direct streaming) |

---

## 🔗 Detailed Migration Suite Documentation

| Step | Master Document | Key Focus |
|:---:|:---|:---|
| **Step 1** | [02_Prepare_Snapshot.md](./02_Prepare_and_Export_Snapshots.md) | Exporting snapshots from source environments |
| **Step 2** | [03_Upload_and_Import.md](./03_Upload_and_Import_Walkthrough.md) | Web UI upload dialogs, CLI streaming & import execution |
| **Step 3** | [04_Import_Options_Settings.md](./04_Import_Options_and_Settings.md) | Group import modes (`Create/Update/Delete`) & thresholds |
| **Step 4** | [05_Post_Migration_Validation.md](./05_Post_Migration_Validation_and_Diagnostics.md) | Status reports, Database Refresh & troubleshooting |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) | Full application creation directory |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the role of the root manifest PackageInfo.xml inside an LCM snapshot archive?
**Answer:** PackageInfo.xml is the master manifest read by the Lifecycle Management (LCM) engine. It specifies the source application name, application type (Planning, FreeForm, FCCS), product version, character set encoding, and the complete index of artifact categories included in the export. If this file is corrupted or missing, the snapshot cannot be parsed.

### Q2: What happens if an LCM snapshot from Cloud EPM 26.11 is imported into an environment running 26.10?
**Answer:** The import fails with a version incompatibility error (EPMLCM-14000). Oracle Cloud EPM prohibits importing snapshots from higher release versions into lower release versions to prevent relational database schema desynchronization and corruption.

### Q3: How are relational repository artifacts separated from Essbase data in the snapshot directory?
**Answer:** Inside the snapshot .zip:
- Relational metadata (forms, task lists, security, navigation flows) is stored as XML definitions under /resource/Planning/.
- Essbase metadata (outlines, dimensions, members, formulas) is stored under /resource/HP/.
- Essbase transactional data is stored as compressed data slices (.txt or .dat Level 0 exports) under /resource/Planning/Data/.
