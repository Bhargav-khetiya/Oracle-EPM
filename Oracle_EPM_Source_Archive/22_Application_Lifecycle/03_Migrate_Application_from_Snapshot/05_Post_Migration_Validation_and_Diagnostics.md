# 🔍 Post-Migration Validation & Troubleshooting Guide
## Comprehensive Verification, Reports, and System Readiness Checklist

> **Purpose:** Validate application integrity, troubleshoot migration failures, and verify functional readiness after restoring or creating an application from snapshot  
> **Key Tools:** Migration Status Report, Artifact Modification History, Database Refresh, Calculation Manager, Access Control  
> **Audience:** Service Administrators, EPM Lead Consultants, Security Architects

---

## 📋 Comprehensive Post-Migration Execution Flow

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                            POST-MIGRATION VALIDATION FLOW                                   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
  ┌─────────────────────────────────────────────────────────────────────────────────────────┐
  │ 1. INSPECT MIGRATION REPORTS                                                            │
  │    Check Migration Status Report (Tools → Migration → Reports → Migration Status)       │
  │    Verify Zero Fatal Errors; inspect any warnings or skipped artifacts                  │
  └─────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
  ┌─────────────────────────────────────────────────────────────────────────────────────────┐
  │ 2. MANDATORY SESSION RE-AUTHENTICATION                                                  │
  │    Sign Out of Oracle Cloud EPM → Clear browser cache → Sign In back                     │
  │    Forces reload of security context, navigation flows, and refreshed schemas           │
  └─────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
  ┌─────────────────────────────────────────────────────────────────────────────────────────┐
  │ 3. PERFORM FULL DATABASE REFRESH                                                        │
  │    Navigate: Application → Overview → Actions → Refresh Database                        │
  │    Re-indexes Essbase outlines, regenerates security filters, validates calc links      │
  └─────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
  ┌─────────────────────────────────────────────────────────────────────────────────────────┐
  │ 4. VALIDATE & DEPLOY CALCULATION MANAGER RULES                                          │
  │    Navigate: Tools → Calculation Manager → Deploy all Rules and Rulesets                │
  │    Recompiles scripts against the newly created cube outlines                           │
  └─────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
  ┌─────────────────────────────────────────────────────────────────────────────────────────┐
  │ 5. RECONCILE DATA & SYSTEM INTEGRITY                                                    │
  │    Check Application Overview statistics: Dimensions, Member counts, Cube storage stats │
  │    Open key Data Forms, execute retrieval queries, run test business rules              │
  └─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 1. Inspecting Migration Reports

### Migration Status Report
The primary diagnostic tool for any migration activity is the **Migration Status Report**.

**Navigation:** `Home → Tools (🔧) → Migration → Reports → Migration Status`

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration Status Report                                                               [ Refresh ]   [ Close ]   │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Filter: [ Last 30 Days ▼ ]                                                                                      │
│                                                                                                                 │
│ ┌────────────┬─────────────────────────────┬──────────────────┬──────────────┬──────────────┬──────────┬──────┐ │
│ │ MigrationID│ Source                      │ Destination      │ Start Time   │ End Time     │ Duration │Status│ │
│ ├────────────┼─────────────────────────────┼──────────────────┼──────────────┼──────────────┼──────────┼──────┤ │
│ │ MIG_104291 │ Planning_Gold_Build.zip     │ Local App        │ Oct 12 12:48 │ Oct 12 12:54 │ 00:06:12 │ ✔ OK │ │
│ │ MIG_104180 │ Interim_Rules_Patch.zip     │ Local App        │ Oct 11 09:15 │ Oct 11 09:16 │ 00:01:05 │ ⚠️ W │ │
│ │ MIG_103902 │ Legacy_11124_Export.zip     │ Local App        │ Oct 10 16:20 │ Oct 10 16:22 │ 00:02:18 │ ❌ F │ │
│ └────────────┴─────────────────────────────┴──────────────────┴──────────────┴──────────────┴──────────┴──────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

#### Diagnostic Fields Explained:
- **Migration ID:** Unique system transaction key (e.g., `MIG_104291`).
- **Source / Destination:** File archive path and target partition.
- **Duration:** Exact execution run time.
- **Status Indicators:**
  - **Completed (✔ OK):** All artifacts successfully restored.
  - **Completed with Warnings (⚠️ W):** Artifacts imported, but minor issues encountered (such as non-critical user mappings).
  - **Failed (❌ F):** One or more critical artifacts failed. **Click directly on the "Failed" hyperlink** to open the **Migration Details** drill-down modal!

---

### Migration Details Modal (Drill-Down on Errors)

When you click a **Failed** or **Warnings** status link, the detailed diagnostic log opens:

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│ Migration Details — MIG_103902                                                      ✖ │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ Summary: Total Artifacts: 412 | Successful: 398 | Failed: 14                          │
│                                                                                       │
│ Failure Log:                                                                          │
│ ┌────────────────────────────────────────┬───────────────────┬──────────────────────┐ │
│ │ Artifact Path                          │ Artifact Name     │ Error Details        │ │
│ ├────────────────────────────────────────┼───────────────────┼──────────────────────┤ │
│ │ /Groups and Membership/Native Directory│ Assigned Roles    │ EPMIE-00070: User    │ │
│ │                                        │                   │ 'm.smith@corp.com'   │ │
│ │                                        │                   │ not found in IDCS.   │ │
│ │ /Core/Dimensions/Account               │ Gross_Margin_Calc │ Member formula syntax│ │
│ │                                        │                   │ error on line 4.     │ │
│ └────────────────────────────────────────┴───────────────────┴──────────────────────┘ │
│                                                                                       │
│ Recommended Action:                                                                   │
│ 1. Provision user accounts in Identity Domain before re-importing roles.              │
│ 2. Correct dimension member formula and refresh database.                             │
│                                                                                       │
│                                                                         [ Close ]     │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

> [!NOTE]
> **Retention Window:** Migration Status Report history is automatically retained for **30 days**. However, if you execute an instance reset using `epmautomate recreate`, all past historical status logs are cleared.

---

## 📜 2. Artifact Modification History & Updates Reports

### Artifact Modification History
Use this report to inspect any artifacts that have changed since the snapshot was captured:

**Navigation:** `Home → Tools → Migration → Snapshots → [Select Snapshot] → Actions (...) → Modification History`

- **Purpose:** Identifies delta changes made to rules, forms, or metadata.
- **Filters:** Filter by **Artifact Name** or by **Modified By** username.
- **Export Delta:** You can check the modified artifacts and click **[Export]** to generate a targeted incremental patch snapshot without re-exporting the entire multi-gigabyte application!

### Artifact Updates Report
**Navigation:** `Home → Tools → Migration → Reports → Artifact Updates`
- Provides an audit trail of artifact paths, associated application modules, and exact timestamps of last configuration updates.

---

## 🔄 3. Mandatory Post-Migration Database Refresh

No application migration is functionally complete until a **Database Refresh** is executed.

**Navigation:** `Home → Application → Overview → Actions (...) → Refresh Database`

```
┌────────────────────────────────────────────────────────────────────────┐
│ Refresh Database Options                                             ✖ │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│ Options:                                                               │
│   ☑ Validate Metadata                                                  │
│   ☑ Refresh Database (Create/Restructure Cubes)                        │
│   ☑ Create/Update Security Filters                                     │
│                                                                        │
│ In-Flight User Access:                                                 │
│   🔘 Keep application available to all users                           │
│   🔘 Prevent all users except Service Administrators from accessing    │
│                                                                        │
│                                       [ Refresh ]        [ Cancel ]    │
└────────────────────────────────────────────────────────────────────────┘
```

### Why Refresh is Crucial:
1. **Essbase Outline Synchronization:** Commits all relational metadata changes into the physical Essbase `.otl` files.
2. **Security Filter Generation:** Compiles member cell security into Essbase native security filters.
3. **Smart List Synchronization:** Syncs member-driven Smart Lists with ASO and BSO cubes.

---

## 🧮 4. Calculation Manager Validation & Deployment

Following migration, business rules, templates, and rulesets must be verified:

1. Navigate to **Home → Tools (🔧) → Calculation Manager**.
2. Select your application from the tree.
3. Expand **Rules**, **Rulesets**, and **Templates**.
4. In the menu, click **Actions → Deploy All**.
5. Ensure the deployment log returns: `Deployment Status: Finished with 0 errors`.

---

## 🛡️ 5. Security & User Access Verification

Confirm that access control models survived migration:

1. **Access Control Inspection:** Navigate to `Home → Tools → Access Control → Groups`.
   - Verify all application groups (e.g., `Financial_Reviewers`, `Budget_Approvers`) exist.
   - Inspect Group Members to confirm active users are assigned.
2. **Role Mapping:** Navigate to `Role Assignment` tab.
   - Confirm granular roles (e.g., `Planner`, `Approver`, `Rule Designer`) are assigned to the expected groups.
3. **Data Grants (Cell-Level Security):**
   - Open `Application → Overview → Dimensions`.
   - Check dimension security (e.g., Entity, Account) to confirm Read/Write permissions are intact.

---

## 🛠️ Post-Migration Verification Checklist

Use this checklist to sign off on an application migration:

| Step | Verification Task | Expected Result | Pass / Fail |
|:---:|:---|:---|:---:|
| 1 | **Migration Status Report** | Status = `Completed` with 0 fatal errors | [ ] |
| 2 | **Re-Authentication** | Sign out, clear browser cookies, sign back in | [ ] |
| 3 | **Database Refresh** | Refresh completes with status `Succeeded` | [ ] |
| 4 | **Calc Manager Deploy** | All rules deployed without syntax or missing member errors | [ ] |
| 5 | **Cube Member Counts** | Application Overview reflects correct dimension depths | [ ] |
| 6 | **Data Form Open Test** | Open primary revenue/expense forms; grid renders valid data | [ ] |
| 7 | **Business Rule Run Test** | Run a test aggregation or calculation script in test POV | [ ] |
| 8 | **Task Lists / Navigation Flows** | Custom Navigation Flows render custom dashboards properly | [ ] |
| 9 | **Data Integration** | Data Management / Integration connections test valid | [ ] |
| 10 | **Audit Records** | Confirm audit policies are activated as desired | [ ] |

---

## 🚨 Troubleshooting Common Migration Failures

### Issue 1: `EPMLCM-26000: Snapshot Incompatible with this update`
- **Cause:** Snapshot taken from an unsupported release or a newer Cloud EPM build than the target instance.
- **Resolution:** Re-export snapshot from the matching environment version, or upgrade the source instance first.

### Issue 2: `Essbase data import is only supported during create application`
- **Cause:** Attempting to incrementally import Essbase data into an existing application via Migration UI.
- **Resolution:** Recreate the instance cleanly via `epmautomate recreate -f` and import the full snapshot, or load data files using Data Integration / Outline Load.

### Issue 3: `EPMIE-00070: Failed to find user during assigned roles import`
- **Cause:** Users exist in source security snapshot but have not been created in target Identity Domain (OCI IAM / IDCS).
- **Resolution:** Bulk create users in the target identity provider before re-running group/role import.

### Issue 4: `Cube outline restructure failure during database refresh`
- **Cause:** Invalid member formulas, circular hierarchy dependencies, or reserved member name collisions.
- **Resolution:** Open the Job Console log (`Home → Application → Jobs`), identify the specific offending dimension member, correct the hierarchy in Dimension Editor, and re-run Database Refresh.

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: Why is executing a manual Database Refresh mandatory immediately after snapshot import?
**Answer:** Snapshot imports write dimension records and formulas into the relational repository. While the import engine triggers an initial sync, a manual **Refresh Database** (Application â†’ Overview â†’ Actions â†’ Refresh Database) is required to ensure that all Essbase security filters, calculated member formulas, and index restructuring are fully compiled into physical cube storage.

### Q2: How do you verify that Calc Manager business rules deployed successfully and are not in draft mode?
**Answer:** Navigate to Navigator (â˜°) â†’ Rules (Calculation Manager). Switch to the **Deployment** view. Check that all rules display a green checkmark indicating **Deployed**. If any rules show as modified or undeployed, select the application node and click **Deploy Application** to compile scripts into Essbase.

### Q3: What diagnostics checks should be run on Substitution Variables and Valid Intersections post-migration?
**Answer:**
1. **Substitution Variables:** Verify that environment-specific variables (e.g. &CurYear, &CurMonth, server endpoints) reflect target values rather than source environment values.
2. **Valid Intersections:** Test a sample data form across restricted dimensions to confirm that target valid intersection rules properly block unauthorized cell combinations.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [04_Import_Options_Settings.md](./04_Import_Options_and_Settings.md) |
| **Next Directory →** | [04_Post_Creation_Settings/01_Application_Settings_Overview.md](../04_Post_Creation_Governance_and_Administration/01_Application_Settings_and_Immutability_Matrix.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |
