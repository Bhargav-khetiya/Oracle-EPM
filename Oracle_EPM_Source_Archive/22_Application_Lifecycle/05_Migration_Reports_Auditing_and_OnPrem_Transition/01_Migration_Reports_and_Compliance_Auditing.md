﻿# 📊 Migration Reports, History & Audit Governance
## Tracking Artifact Migrations, Delta Modifications, and Comprehensive Audit Trails

> **Navigation:** `Home → Tools (🔧) → Migration → Reports`  
> **Applicability:** All Oracle Fusion Cloud EPM Business Processes  
> **Role Requirement:** Service Administrator or user with `Migrations - Administer` granular role  
> **Purpose:** Monitor migration execution jobs, drill down into failed artifact imports, isolate delta modifications, and generate compliance audit reports

---

## 🧭 Overview of Migration Reporting Suite

When managing migrations, environment clones, or snapshot imports, Oracle Cloud EPM provides three dedicated analytical reports within the Migration console:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration Console: Reports Workspace                                                            │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Snapshots     Categories     [ Reports ]                                                        │
│ ──────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                  │
│   ┌──────────────────────────┐  ┌──────────────────────────┐  ┌──────────────────────────┐     │
│   │ 📋 Migration Status      │  │ 🔍 Modification History  │  │ 📑 Artifact Updates      │     │
│   │ Tracks execution results │  │ Identifies changed       │  │ System-wide audit log of │     │
│   │ and failure stack traces │  │ artifacts since baseline │  │ all artifact changes     │     │
│   │ [ View Report ]          │  │ [ View Report ]          │  │ [ View Report ]          │     │
│   └──────────────────────────┘  └──────────────────────────┘  └──────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 1. Migration Status Report

The **Migration Status Report** is the primary diagnostic log for every import and export transaction performed in the environment.

### 🧭 Navigation
`Home → Tools (🔧) → Migration → Reports → Migration Status` (or click **Refresh** on the status modal immediately following an import).

### 🖥️ Report Layout Wireframe

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration Status Report                                                              [ Refresh ]   [ Close ]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Time Range Filter: [ Last 30 Days ▼ ]                                                                          │
│                                                                                                                │
│ ┌────────────┬─────────────────────────────┬─────────────────┬──────────────┬──────────────┬──────────┬──────┐ │
│ │ MigrationID│ Source                      │ Destination     │ Start Time   │ End Time     │ Duration │Status│ │
│ ├────────────┼─────────────────────────────┼─────────────────┼──────────────┼──────────────┼──────────┼──────┤ │
│ │ MIG_204891 │ Prod_Nightly_Clone.zip      │ Target Instance │ 12-Oct 02:00 │ 12-Oct 02:35 │ 00:35:12 │ ✔ OK │ │
│ │ MIG_204112 │ Rules_Update_20261011.zip   │ Target Instance │ 11-Oct 15:10 │ 11-Oct 15:12 │ 00:02:05 │ ⚠️ W │ │
│ │ MIG_203904 │ Legacy_OnPrem_Plan.zip      │ Target Instance │ 10-Oct 18:00 │ 10-Oct 18:04 │ 00:04:18 │ ❌ F │ │
│ └────────────┴─────────────────────────────┴─────────────────┴──────────────┴──────────────┴──────────┴──────┘ │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 🔍 Drilling Down into Failures
If an import status shows **Failed (❌ F)** or **Completed with Warnings (⚠️ W)**:
1. Click directly on the **Failed** or **Warnings** text hyperlink.
2. The **Migration Details** drill-down window opens:

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│ Migration Details — MIG_203904                                                      ✖ │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ Summary: Artifacts Processed: 520 | Succeeded: 508 | Failed: 12                       │
│                                                                                       │
│ Failure Stack:                                                                        │
│ ┌────────────────────────────────────────┬───────────────────┬──────────────────────┐ │
│ │ Artifact Path                          │ Artifact Name     │ Error Details        │ │
│ ├────────────────────────────────────────┼───────────────────┼──────────────────────┤ │
│ │ /Groups and Membership/Native Directory│ Assigned Roles    │ EPMIE-00070: User    │ │
│ │                                        │                   │ 'j.doe@company.com'  │ │
│ │                                        │                   │ not found in IDCS.   │ │
│ │ /Core/Dimensions/Account               │ Operating_Margin  │ Formula error:       │ │
│ │                                        │                   │ Syntax error line 2. │ │
│ └────────────────────────────────────────┴───────────────────┴──────────────────────┘ │
│                                                                         [ Close ]     │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### ⚠️ Retention Rules for Status Report
- **30-Day Automated Purge:** Historical migration status records are retained in the database for **30 days** before being automatically removed.
- **Instance Reset Clearing:** If you execute `epmautomate recreate` to reset the environment, all historical migration status logs are **wiped clean**.

---

## 🔍 2. Artifact Modification History Report

The **Modification History** report identifies artifacts that were modified *after* an original snapshot baseline was created. This allows administrators to track changes and export **delta-only patch snapshots**.

### 🧭 Navigation
`Home → Tools → Migration → Snapshots → [Select Snapshot] → Actions (...) → Modification History`

```
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Modification History: FullProdBackup                                                           │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Filter by Artifact Name: [ *                   ]   Modified By: [ all_users                 ▼ ]│
│                                                                                                │
│ ┌───┬────────────────────────────────────────┬──────────────────┬──────────────┬─────────────┐ │
│ │ ☑ │ Artifact Name                          │ Type             │ Modified By  │ Date        │ │
│ ├───┼────────────────────────────────────────┼──────────────────┼──────────────┼─────────────┤ │
│ │ ☑ │ Revenue_Forecast_Form                  │ Data Form        │ s.admin      │ 12-Oct 10:14│ │
│ │ ☑ │ Calc_Gross_Margin                      │ Business Rule    │ r.designer   │ 11-Oct 16:30│ │
│ │ ☐ │ Total_Entity                           │ Dimension Member │ s.admin      │ 10-Oct 09:00│ │
│ └───┴────────────────────────────────────────┴──────────────────┴──────────────┴─────────────┘ │
│                                                                                                │
│ [ Select All ]   [ Export Delta Snapshot ]                                      [ Close ]      │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 🚀 Creating an Incremental Delta Snapshot from History:
1. Review the list of modified artifacts.
2. Select the checkboxes next to the specific updated items.
3. Click **[ Export Delta Snapshot ]**.
4. Enter a unique snapshot name (e.g., `Delta_Patch_Oct12`).
5. Click **OK**.
6. **Result:** An ultra-lean, lightweight snapshot containing **only the changed objects** is generated in minutes!

---

## 📑 3. Artifact Updates Report

The **Artifact Updates Report** provides an enterprise compliance audit log of all changes across every artifact in the service.

### 🧭 Navigation
`Home → Tools (🔧) → Migration → Reports → Artifact Updates`

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ Artifact Updates Report Criteria                                           [ Run ]     │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                        │
│ Search Parameters:                                                                     │
│   Artifact Name: [ *                                                                 ] │
│   Artifact Type: [ All Types                                                       ▼ ] │
│   Modified By:   [ *                                                                 ] │
│   Date Range:    From: [ 01-Oct-2026        📅 ]   To: [ 12-Oct-2026              📅 ] │
│                                                                                        │
│ Target Components:                                                                     │
│   ☑ Planning / Core                                                                    │
│   ☑ Calculation Manager Rules                                                          │
│   ☑ Reporting and Analysis                                                             │
│   ☑ Access Control Groups                                                              │
│                                                                                        │
│ Output Format:   🔘 Screen View    🔘 Export to CSV    🔘 Print Preview                │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Export Options:
- **CSV Export:** Generates an Excel-ready audit file containing `Artifact Name`, `Category`, `Module`, `User ID`, `Timestamp`, and `Operation Type`.
- **Compliance Certification:** Satisfies SOX, ISO 27001, and SOC-2 auditor requests for evidence of change management controls in production EPM environments.

---

## 🛠️ Post-Replication Validation Matrix

When replicating Production to Demo or restoring a snapshot, use the reports to validate the pipeline:

| Verification Phase | Report / Tool | Expected Result | Action if Failed |
|:---|:---|:---|:---|
| **Step 1: Ingestion** | Migration Status Report | Status = `Completed` (0 fatal errors) | Click `Failed` link; review error log |
| **Step 2: User Access** | Access Control → Role Assignment | Service Admin & Users mapped | Verify Identity Domain pre-provisioning |
| **Step 3: Delta Integrity** | Modification History | Delta count matches expected releases | Re-export missing artifacts |
| **Step 4: Audit Trail** | Artifact Updates Report | Change timestamp reflects migration time | Review job console run logs |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Where are Migration Status diagnostic reports stored, and how long are they retained—
**Answer:** Diagnostic reports are accessible via `Tools → Migration → Reports → Migration Status`. Oracle Cloud EPM retains migration execution logs for **7 days**. For permanent compliance records, administrators should export migration reports to PDF or CSV immediately after migration completion.

### Q2: How does an auditor track delta changes between two application snapshots for SOX compliance—
**Answer:** Use **Artifact Modification History** under `Tools → Migration → Reports → Artifact Modification History`. Filter by date range to generate a comprehensive audit report detailing which forms, rules, calculations, or dimensions were modified, the timestamp of modification, and the user identity who made the change.

### Q3: Can you extract the Migration Status report programmatically via EPM Automate or REST API—
**Answer:** Yes. Cloud EPM provides REST API endpoints under `/interop/rest/v1/applicationsnapshots/migrationreports` to retrieve migration logs in JSON format, enabling automated compliance ingestion into SIEM or governance systems.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [03_Master_Troubleshooting_FAQ_and_Gotchas.md](../06_Automation_Runbooks_and_Troubleshooting/03_Master_Troubleshooting_FAQ_and_Gotchas.md) |
| **Next →** | [02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md](./02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md) |
| **Master Overview** | [01_Lifecycle_Strategy_and_Overview.md](../01_Environment_Lifecycle_and_Maintenance/01_Lifecycle_Strategy_and_Overview.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |

