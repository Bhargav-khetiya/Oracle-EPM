﻿# ⚙️ Migration Import Options & Settings — Deep Dive
## Configuring Group Management, Role Assignment Rules, and Migration Policies

> **Navigation:** `Home → Tools (🔧) → Migration → Snapshots → Options (⚙️)`  
> **Applicability:** All application migrations, snapshot restores, and incremental artifact imports  
> **Role Requirement:** Service Administrator or user with `Migrations - Administer` granular role  
> **Key Function:** Dictates how security groups, role bindings, error thresholds, and member validation are treated during import

---

## 🧭 Navigating to Migration Options

To configure import options before initiating an import:
1. Navigate to **Home → Tools → Migration**.
2. Select the **Snapshots** tab.
3. In the upper right corner of the Migration interface, click the **Options (⚙️)** icon (or **Migration Options** button).

```
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration                                                                  [ ⚙️ Options ] [❓] │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Snapshots     Categories     Reports                                                          │
│ ────────────────────────────────────────────────────────────────────────────────────────────── │
│ [ Upload ]  [ Refresh ]                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼ Click
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration Options                                                                            ✖ │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                │
│ Configure how the migration engine handles security groups and role assignments:              │
│                                                                                                │
│ Groups and Membership Import Mode:                                                             │
│   🔘 Create or Update   (Default)                                                             │
│   ⚪ Create Only                                                                               │
│   ⚪ Update Only                                                                               │
│   ⚪ Delete                                                                                    │
│                                                                                                │
│ Member Validation Policy:                                                                      │
│   ☑ Skip target dimension member validation during import (Default: Enabled)                   │
│                                                                                                │
│ Error Threshold:                                                                               │
│   Maximum allowable error count before aborting job: [ 100 ]                                   │
│                                                                                                │
│                                                         [ Save and Close ]     [ Cancel ]      │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Groups and Membership Import Modes

The most consequential setting in Migration Options is the **Groups and Membership** import behavior. In Oracle Cloud EPM, user accounts reside in OCI IAM / IDCS, while **Groups, Team definitions, and Granular Role assignments** reside in EPM Access Control (Native Directory).

The table below contrasts the 4 operational modes:

| Option Mode | New Groups Created— | Existing Groups Updated— | Missing Groups Deleted— | Granular Role Assignments | Recommended Use Case |
|:---|:---:|:---:|:---:|:---|:---|
| **Create or Update** *(Default)* | ✅ Yes | ✅ Yes | ❌ No | Adds newly assigned roles; updates existing bindings | **Standard Application Migrations & Clones.** Ensures target environment matches source without wiping non-overlapping local groups. |
| **Create Only** | ✅ Yes | ❌ No | ❌ No | Assigns roles only to newly created groups/users | **Initial onboarding** of new business units or subsidiary groups where existing target configurations must remain untouched. |
| **Update Only** | ❌ No | ✅ Yes | ❌ No | Synchronizes role updates and membership changes only for groups that already exist in target | **Strict security freeze** environments where security admins forbid the introduction of unapproved new group names. |
| **Delete** | ❌ No | ❌ No | ✅ Yes | Strips and unassigns roles associated with matching groups in the import file | **Decommissioning** or cleaning up deprecated access groups across environments. |

---

## 📋 Detailed Behavioral Matrix for Groups & Roles

### 1. `Create or Update` (Recommended Default)
- **What happens:** If group `Fin_Planners` exists in the snapshot and exists on target, its members and assigned application roles are synchronized with the snapshot. If group `HR_Analysts` exists in the snapshot but does not exist on target, it is created in target Access Control and assigned its roles.
- **Roles Behavior:** Assigns or unassigns granular roles to users and groups based on snapshot definitions.
- **Safety:** Safe for 95% of migration workflows.

### 2. `Create Only`
- **What happens:** The migration engine scans groups in the snapshot. Any group that already exists on the target environment is skipped entirely. Only non-existent groups are added.
- **Roles Behavior:** Only assigns roles to the newly added groups. Existing group roles remain unchanged.
- **Safety:** Guarantees existing security structures on target are never overwritten.

### 3. `Update Only`
- **What happens:** The migration engine only modifies groups that are already present in target Access Control. If the snapshot contains new groups, they are **ignored and skipped**.
- **Roles Behavior:** Granular roles on existing target groups are aligned with the snapshot.
- **Safety:** Prevents schema clutter from foreign groups.

### 4. `Delete`
- **What happens:** Scans the import file for group names. Any group matching those names in the target Access Control is **deleted**.
- **Roles Behavior:** Unassigns all granular roles from those users and groups.
- **Safety:** ⚠️ **High Risk.** Never use this mode unless explicitly retiring a set of legacy security groups.

---

## 🚫 Target Dimension Member Validation Policy

### Default Engine Behavior:
> **Policy:** Migration **always skips** the validation of target dimension members in the destination location during import by default.

### Architectural Rationale:
- In relational database terms, checking every member reference in forms, data slices, and calc scripts prior to the dimension outlines being committed creates circular dependency deadlocks.
- By skipping real-time validation during stream ingestion, the migration engine loads outlines, dimensions, and dependent artifacts in high-speed batches.
- Member integrity is reconciled during the mandatory **Database Refresh** step following import completion.

---

## 🛑 Maximum Error Threshold

| Setting | Default Value | Configurable Range | Description |
|:---|:---:|:---:|:---|
| **Max Error Threshold** | **100** | 1 – 1,000 | The maximum number of non-fatal artifact errors permitted before the migration engine abruptly halts the import job. |

### When to Adjust:
- **Increase Threshold (e.g., 500):** When migrating large historical environments with known orphaned user access records or legacy form references that you plan to clean up post-migration.
- **Decrease Threshold (e.g., 10):** When performing strict production cutover validations where any unexpected metadata failure must immediately trigger an abort.

---

## ⚠️ Common Identity Domain Pitfall: `EPMIE-00070`

A frequent failure encountered during application migration relates to user presence:

```
Error: EPMIE-00070: Failed to find user during assigned roles import.
Artifact: /Groups and Membership/Native Directory/Assigned Roles
```

### Why This Happens:
1. The snapshot contains role assignments for `john.doe@company.com`.
2. In the target environment's Identity Domain (OCI IAM / IDCS), `john.doe@company.com` **has not yet been provisioned**.
3. Cloud EPM Access Control cannot bind application roles to a user account that does not exist in the identity provider.

### Resolution:
1. **Pre-provision users:** Before importing the snapshot, bulk-upload the user accounts into the target OCI IAM / IDCS identity domain using CSV import or SCIM sync.
2. Alternatively, if migrating to a test sandbox where not all production users need access, ignore non-fatal `EPMIE-00070` warnings or adjust the error threshold.

---

## 📦 Data Management LCM Snapshot Modes

When migrating applications that utilize **Data Management / Data Integration**, the staging table volume can severely impact import performance.

In Data Management (`Tools → Data Management → System Settings`):

| LCM Mode | Data Management Snapshot Behavior | Export/Import Duration |
|:---|:---|:---:|
| **Single Snapshot – Setup Only** | Captures application definitions, import formats, location mappings, and validation rules. Staging workbench rows are omitted. | **Fast** (Seconds to minutes) |
| **Single Snapshot – Setup and Data** | Captures all setup configurations **plus** the complete historical TDATASEG staging table rows. | **Long** (May trigger maintenance mode) |
| **All (Baseline Snapshot)** | Mandatory baseline snapshot required before generating subsequent incremental snapshots. | Moderate |

> [!TIP]
> **Best Practice for App Creation & Migration:**  
> For creating a new environment or migrating to a new instance, export Data Management using **Setup Only**. Historical staging workbench records are rarely needed in target environments and unnecessarily bloat snapshot files from 50 MB to 15+ GB.

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the difference between Group Import Mode Create or Update versus Skip Existing—
**Answer:**
- **Create or Update:** If a group in the snapshot exists in the target, the import merges roles and updates group membership. If it does not exist, it creates the group.
- **Skip Existing:** If a group already exists in the target, the import ignores the snapshot definition, preserving target group permissions untouched.

### Q2: What is the Error Threshold parameter, and what happens if errors exceed it—
**Answer:** In Migration Options, the **Error Threshold** specifies the maximum number of artifact import errors allowed before the migration engine aborts the entire job (default is typically 100 errors). If corrupted metadata triggers errors exceeding this count, the import immediately halts to prevent leaving the application in an unstable state.

### Q3: How do you resolve EPMIE-00070 when the executing admin is not an Identity Domain Administrator—
**Answer:** If the executing user holds only the application Service Administrator role but lacks the **Identity Domain Administrator** role, they cannot provision new users into IDCS. In this case, either assign the Identity Domain Administrator role to the migration user or pre-create the missing users in the target identity domain before running the import.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [03_Upload_and_Import.md](./03_Upload_and_Import_Walkthrough.md) |
| **Next →** | [05_Post_Migration_Validation.md](./05_Post_Migration_Validation_and_Diagnostics.md) |
