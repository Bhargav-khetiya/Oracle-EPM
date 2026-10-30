# 📥 Prepare Snapshot — Complete Export & Packaging Guide
## Full Application Backups vs. Selective Incremental Exports from Source Environments

> **Source Environment:** Any healthy Oracle Fusion Cloud EPM Environment  
> **Navigation (Web UI):** `Home → Tools (🔧) → Migration → Categories` OR `Migration → Backup`  
> **Output:** Encrypted `.zip` archive containing application artifacts  
> **Role Requirement:** Service Administrator or user with `Migrations - Administer` granular role  
> **Key Objective:** Generate a clean, error-free snapshot ready for migration or disaster recovery

---

## 🧭 The Two Export Modes: Full Backup vs. Incremental Export

Before clicking export, understand the fundamental architectural difference between the two export mechanisms:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       SNAPSHOT EXPORT METHODOLOGIES                         │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 🛡️ FULL APPLICATION BACKUP           │ 📑 INCREMENTAL ARTIFACT EXPORT       │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Button: **[ Backup ]** in UI       │ • Button: **[ Export ]** in UI       │
│ • Captures 100% of application       │ • Granularly captures only selected  │
│   metadata, forms, rules, and data.  │   sub-components (e.g., 2 forms).    │
│ • Creates a cloneable snapshot.      │ • Creates a patch snapshot.          │
│ • Default name: `Backup DD-MM-YY`    │ • Default name: `Username DD-MM-YY`  │
│ • Includes cold Essbase data blocks. │ • Excludes full application schema.  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 🖥️ Method 1: Web UI Full Application Backup (Step-by-Step)

### Step 1: Navigate to Migration Console
Log in to the **Source Environment** as Service Administrator:
**Navigation:** `Home → Tools (🔧) → Migration`

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration                                                                  [ ⚙️ Options ] [❓]   │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                                             │
│ │ Snapshots    │  │ Categories   │  │ Reports      │                                             │
│ └──────────────┘  └──────────────┘  └──────────────┘                                             │
│                                                                                                  │
│ [ Backup ]   [ Import ]   [ Upload ]   [ Refresh ]                                               │
│                                                                                                  │
│ Saved Snapshots:                                                                                 │
│ ┌───┬────────────────────────────────────┬───────────┬───────────────┬─────────────────────────┐ │
│ │   │ Name                               │ Size      │ Last Modified │ Actions                 │ │
│ ├───┼────────────────────────────────────┼───────────┼───────────────┼─────────────────────────┤ │
│ │ ▶ │ Artifact Snapshot                  │ 145 MB    │ 12-Oct 01:00  │ [...]                   │ │
│ └───┴────────────────────────────────────┴───────────┴───────────────┴─────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Step 2: Launch Backup Dialog
1. Click the **[ Backup ]** button in the top toolbar.
2. The **Backup Application** dialog opens:

```
┌─────────────────────────────────────────────────────────────┐
│ Backup Application                                        ✖ │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Destination Snapshot Name:                                  │
│ [ Production_Gold_Build_20261012                          ] │
│                                                             │
│ ⚠️ Note: Do not use illegal OS characters (e.g., : / \ * ?) │
│                                                             │
│                                       [ OK ]     [ Cancel ] │
└─────────────────────────────────────────────────────────────┘
```

3. Enter a descriptive filename (e.g., `Production_Gold_Build_20261012`).
4. Click **[ OK ]**.
5. The **Migration Status Report** launches automatically to track export progress.
6. Once complete, click **Snapshots** tab, click **Actions (...)** on your snapshot row, and click **Download** to save the `.zip` archive locally.

---

## 🖥️ Method 2: Web UI Selective Incremental Export

When you only need to export specific components (e.g., updated Calculation Manager business rules or newly created Data Forms) without exporting gigabytes of Essbase data:

### Step 1: Open Categories Tab
In Migration, click the **Categories** tab:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration: Categories                                            [ Selected Artifacts ] [Export] │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                  │
│ Artifact Hierarchy:                                                                              │
│ ▼ ☑ Planning / Core (expand to select items)                                                     │
│    ├── 📁 Configuration Settings                                                                 │
│    ├── 📁 Dimensions & Metadata                                                                  │
│    │    ├── ☑ Account                                                                            │
│    │    └── ☐ Entity                                                                             │
│    ├── 📁 Data Forms                                                                             │
│    │    ├── ☑ Revenue_Forecast_v2                                                                │
│    │    └── ☐ Headcount_Input                                                                    │
│    └── 📁 Task Lists & Approvals                                                                 │
│ ▼ ☑ Calculation Manager                                                                          │
│    └── 📁 Rules & Rulesets                                                                       │
│         └── ☑ Aggregate_Total_Revenue                                                            │
│ ▼ ☐ Reporting & Analysis (Financial Reporting)                                                   │
│ ▼ ☐ Groups and Membership (Native Directory Access Control)                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Step 2: Validate Selection & Export
1. Check the checkboxes next to the desired artifacts.
2. Click **[ Selected Artifacts ]** in the top right corner to verify your payload list.
3. Click **[ Export ]**.
4. Enter an incremental snapshot name (e.g., `Patch_RevenueRules_Oct12`).
5. Click **OK**.

---

## ⚠️ Mission-Critical Export Considerations

### 1. Essbase Data Integrity (Cold Backup Rule)
Oracle Essbase data exports are executed with Essbase momentarily frozen.  
- **Action:** Before initiating a full backup, ensure no long-running calculations, aggregations, data maps, or heavy user data submits are in flight. Running heavy jobs during export risks incomplete data blocks.

### 2. Aggregate Storage (ASO) Member-Driven Smart Lists
If your Planning application uses member-driven Smart Lists enabled in ASO cubes (`OEP_REP`), the export engine generates complex MDX cross-join queries:
- **Gotcha:** If thousands of dynamic members are enabled for ASO, the export process can hit memory allocation limits.
- **Remedy:** Use the daily maintenance snapshot (`Artifact Snapshot`) to restore Planning environments rather than running ad-hoc heavy manual full exports.

### 3. Data Management (FDMEE) LCM Modes
Exporting Data Management workbench staging tables can take hours. Configure your export mode in **Tools → Data Management → System Settings**:
- **Single Snapshot – Setup Only (Recommended):** Exports import formats, mappings, and rules in seconds.
- **Single Snapshot – Setup and Data:** Exports all historical workbench rows; creates very large snapshots.

---

## 🤖 Method 3: Scripted Export via EPM Automate

For scheduled unattended operations:

```bash
# 1. Login to Source Environment
epmautomate login admin@company.com "C:\EPM\keys\prod_auth.epw" "https://epm-prod.oraclecloud.com" "epmprod"

# 2. (Optional) Force fresh daily maintenance to update the baseline Artifact Snapshot
# epmautomate runDailyMaintenance -f

# 3. Export custom named snapshot
epmautomate exportsnapshot "Automated_Backup_20261012"

# 4. Download snapshot to on-premises disaster recovery server
epmautomate downloadfile "Automated_Backup_20261012" "D:\Backups\EPM_Nightly\"

# 5. Logout
epmautomate logout
```

---

## 📏 Snapshot Sizing & Transmission Benchmark

| Environment Data Volume | Typical Snapshot Size | Export Time | Web Download Time |
|:---|:---:|:---:|:---:|
| **Small App** (< 1M cells, setup only) | 15 MB – 60 MB | 1 – 3 mins | < 1 min |
| **Medium App** (1M – 15M cells) | 100 MB – 500 MB | 5 – 15 mins | 2 – 5 mins |
| **Large App** (15M – 100M cells) | 1 GB – 4 GB | 20 – 45 mins | 10 – 30 mins |
| **Enterprise Multi-Cube** (100M+ cells) | 5 GB – 15 GB+ | 45 – 90 mins | Use `copysnapshotfrominstance` |

> [!TIP]
> **Avoid Downloading Multi-GB Snapshots:**  
> If you are moving an application directly between two cloud environments (e.g., Prod to Test), **never download the snapshot locally**. Use the `copysnapshotfrominstance` EPM Automate command to transfer data directly across Oracle's internal cloud backbone at gigabit speeds!

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: How do you exclude transactional data from a snapshot to create a lightweight "Structure-Only" template?
**Answer:** In Tools â†’ Migration â†’ Categories, expand the Planning business process, expand **Data**, and uncheck all cube data categories (Plan1 Data, OEP_FS Data). Exporting without data reduces snapshot size from 10 GB+ to under 50 MB, making it fast and safe for promoting application design changes across pods.

### Q2: Why should administrators ensure no users are active when running exportSnapshot?
**Answer:** If users are submitting data forms or executing calculation scripts while an export is running, Essbase blocks may be in a "dirty / uncommitted" state in memory. This can result in transactional data slices capturing partial or inconsistent data, or cause the export job to fail with outline lock contention.

### Q3: How do you script automated nightly scheduled LCM exports using EPM Automate?
**Answer:** Execute in an automated batch pipeline:
`cmd
epmautomate login admin@company.com "C:\EPM\pass.epw" "https://epm.oraclecloud.com"
epmautomate exportSnapshot "Nightly_Backup_%date:~10,4%-%date:~4,2%-%date:~7,2%"
epmautomate downloadFile "Nightly_Backup_%date:~10,4%-%date:~4,2%-%date:~7,2%.zip"
epmautomate logout
`
"@

    "03_Migrate_Application_from_Snapshot\03_Upload_and_Import_Walkthrough.md" = @"
---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the exact difference between importing via Web UI Migration versus EPM Automate importSnapshot?
**Answer:**
- **Web UI Migration:** Allows granular, selective artifact selection. You can expand trees and choose to import only a single form, a single business rule, or a single dimension.
- **EPM Automate importSnapshot:** Executes a **full application ingestion** of the entire snapshot archive in unattended mode. It cannot cherry-pick individual forms from CLI.

### Q2: Why does an import sometimes complete with "Completed with Warnings", and where is the error log?
**Answer:** "Completed with Warnings" indicates that the core application was created, but specific artifacts encountered non-fatal conflicts (e.g. an imported form references a user variable that was not in the snapshot). Navigate to Tools â†’ Migration â†’ Reports â†’ Migration Status, click the completed job, and view the line-by-line diagnostic details.

### Q3: How do you resolve missing user identity errors during automated import?
**Answer:** Include the parameter importUsers=true:
`cmd
epmautomate importSnapshot "ProdSnapshot" importUsers=true
`
This instructs Cloud EPM to automatically provision missing user accounts into the target Identity Domain (OCI IAM / IDCS) and assign their corresponding application roles.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [01_Migration_Overview.md](./01_Migration_Concepts_and_Payload_Architecture.md) |
| **Next →** | [03_Upload_and_Import.md](./03_Upload_and_Import_Walkthrough.md) |
| **Import Options** | [04_Import_Options_Settings.md](./04_Import_Options_and_Settings.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |
