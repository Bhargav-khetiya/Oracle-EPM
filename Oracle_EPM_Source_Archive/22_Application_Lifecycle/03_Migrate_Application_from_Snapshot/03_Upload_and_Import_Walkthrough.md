﻿# 📥 Upload and Import Snapshot — Complete Step-by-Step Guide
## Restoring or Creating an Application from Snapshot via the Landing Page & Migration Console

> **Navigation Path 1 (Landing Page):** `Planning Landing Page → MIGRATE button`  
> **Navigation Path 2 (Maintenance):** `Home → Tools (🔧) → Migration → Snapshots`  
> **Purpose:** Upload an application snapshot ZIP archive and execute an import to create/restore the application  
> **Supported File Format:** Oracle LCM Snapshot (`.zip`)  
> **Prerequisites:** Service Administrator role; snapshot must be compatible with target Cloud EPM release

---

## 🧭 Entry Point: Planning Landing Page [MIGRATE] Button

When you first log in to a clean or unconfigured Oracle Cloud EPM Planning instance, the third card on the landing page is **Migrate**.

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
│   │ looks...             │  │ own application      │  │                 │ │
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

## 🖥️ Screen Layout & Interactive Elements

Clicking **[MIGRATE]** opens the Migration workspace focused on the **Snapshots** tab:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration                                                                                    ⚙️ Options  ❓ Help │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                                                             │
│ │ Snapshots    │  │ Categories   │  │ Reports      │                                                             │
│ └──────────────┘  └──────────────┘  └──────────────┘                                                             │
│                                                                                                                  │
│ Snapshots                                                                            🔍 Search: [          ]     │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│ [ Upload ]  [ Refresh ]                                                                                          │
│                                                                                                                  │
│ ┌───┬──────────────────────────────────┬─────────────────┬───────────┬───────────────┬─────────────────────────┐ │
│ │   │ Name                             │ Type            │ Size      │ Last Modified │ Actions                 │ │
│ ├───┼──────────────────────────────────┼─────────────────┼───────────┼───────────────┼─────────────────────────┤ │
│ │ ▶ │ Artifact Snapshot                │ System Backup   │ 142.6 MB  │ Oct 12, 01:00 │ [...]                   │ │
│ │ ▶ │ Planning_Prod_Backup_20261010    │ User Snapshot   │ 210.4 MB  │ Oct 10, 14:32 │ [Import] [...]          │ │
│ └───┴──────────────────────────────────┴─────────────────┴───────────┴───────────────┴─────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Key UI Elements Reference

| UI Element | Type | Purpose | Behavior / Notes |
|:---|:---|:---|:---|
| **Snapshots Tab** | Tab | View, upload, download, and import snapshots | Primary workspace for LCM archives |
| **Categories Tab** | Tab | View specific artifact hierarchies (Core, Calc Manager, etc.) | Used for granular selective exports/imports |
| **Reports Tab** | Tab | View status and audit reports | Migration Status, Modification History, Artifact Updates |
| **[ Upload ] Button** | Button | Uploads a `.zip` snapshot from client computer to Cloud EPM storage | Launches the **Upload Snapshot** modal dialog |
| **[ Refresh ] Button** | Button | Refreshes the snapshot list table | Polls current server storage status |
| **Search Box** | Input | Filters snapshot listing by file name | Case-insensitive filter |
| **Options (⚙️)** | Icon / Modal | Opens global Migration Import Options | Controls Group & Role import behaviors |
| **Actions Menu ([...])** | Dropdown Menu | Context actions per snapshot | Import, Download, Rename, Delete, Repeat Export |

---

## 📤 Step 1: Uploading the Snapshot File

If the snapshot file is stored on your local workstation, you must upload it to the Cloud EPM staging repository.

### Web Browser Upload Procedure

1. Click the **[ Upload ]** button in the Snapshots toolbar.
2. The **Upload Snapshot** dialog opens:

```
┌────────────────────────────────────────────────────────┐
│ Upload Snapshot                                      ✖ │
├────────────────────────────────────────────────────────┤
│                                                        │
│ File: [ C:\Snapshots\Planning_Gold_Build.zip ] [Browse]│
│                                                        │
│ Note: Maximum upload size via browser is 2 GB.         │
│ For larger files, use EPM Automate.                    │
│                                                        │
│                            [ Upload ]    [ Cancel ]    │
└────────────────────────────────────────────────────────┘
```

3. Click **[Browse]** and select your `.zip` snapshot file.
4. Click **[Upload]**.
5. Wait for the browser upload progress bar to reach 100%.
6. When complete, a notification confirms: `The snapshot was successfully uploaded.`
7. The snapshot now appears in the **Snapshots** table.

### ⚠️ File Size Limits & Alternative Upload Protocols

| Interface / Tool | Snapshot Upload Limit | Individual File Limit | Recommended For |
|:---|:---|:---|:---|
| **Web Browser (GUI)** | **2.0 GB** | **500 MB** | Ad-hoc small to medium migrations |
| **EPM Automate** | **No browser timeout / multi-GB** | **Standard multi-GB** | Production cutovers, large cubes, automated jobs |
| **REST API** | Chunked upload supported | Chunked upload supported | CI/CD pipelines, programmatic integrations |
| **Direct Instance-to-Instance** | **Cloud-to-Cloud transfer** | Direct streaming | Moving test to prod directly without local download |

#### EPM Automate Upload Command

```bash
# Authenticate against target instance
epmautomate login admin@example.com "P@ssword123" https://epm-target.epm.us-ashburn-1.ocs.oraclecloud.com epmeur

# Upload snapshot archive
epmautomate uploadfile "C:\Backups\Planning_Gold_Build.zip"

# Verify file existence in cloud repository
epmautomate listfiles
```

#### Direct Copy From Source Instance (Zero Local Disk Use)

```bash
# Log in to target instance and stream snapshot directly from source instance
epmautomate copysnapshotfrominstance "Planning_Gold_Build" "https://epm-source.epm.us-ashburn-1.ocs.oraclecloud.com" "admin@example.com" "password" "epmeur"
```

---

## 📥 Step 2: Executing Application Import

Once the snapshot resides in the Cloud EPM repository, you execute the import.

### Option A: Full Application Import (Clean Clone / Disaster Recovery)

Use this method when creating an application from scratch or completely restoring an environment.

1. In the **Snapshots** table, locate your uploaded snapshot.
2. Click the **Actions ([...])** menu or click directly on the row.
3. Select **Import**:

```
┌─────────────────────────────────────────────────────────────────┐
│ Import Application Snapshot                                   ✖ │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Snapshot: Planning_Gold_Build.zip                               │
│ Target: Local Application Instance                              │
│                                                                 │
│ ⚠️ WARNING: Importing a full application snapshot will recreate │
│ all application structures, dimensions, security, forms, rules, │
│ and data. Existing data will be overwritten.                    │
│                                                                 │
│ Do you want to continue—                                        │
│                                                                 │
│                                    [ OK ]         [ Cancel ]    │
└─────────────────────────────────────────────────────────────────┘
```

4. Click **[ OK ]**.
5. The system initiates the import and immediately transitions you to the **Migration Status Report** screen.

---

### Option B: Selective / Granular Artifact Import

If you only need to import specific parts of a snapshot (e.g., specific Business Rules, Forms, Dashboards, or Security Groups):

1. In the **Snapshots** table, click the expand arrow (**▶**) next to the snapshot name.
2. Expand the category tree:

```
▼ 📁 Planning_Gold_Build.zip
   ├── 📁 Core (or Planning)
   │    ├── 📁 Configuration
   │    ├── 📁 Dimensions & Metadata
   │    ├── 📁 Data Forms
   │    │    ├── ☑ Revenue_Forecast_Form
   │    │    └── ☐ Expense_Input_Form
   │    ├── 📁 Task Lists
   │    └── 📁 Business Rules & Calc Scripts
   ├── 📁 Calculation Manager
   ├── 📁 Reporting & Analysis (Financial Reporting)
   ├── 📁 Data Management / Data Integration
   └── 📁 Groups and Membership (Native Directory)
```

3. Check the checkboxes next to the specific artifacts or components you wish to import.
4. Click **[Selected Artifacts]** button at the top right to verify your exact selection payload.
5. Click **[Import]**.
6. Confirm the dialog prompt.

---

## 📊 Step 3: Monitoring Import Progress in Real Time

Upon launching the import, the **Migration Status Report** displays real-time execution steps:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration Status Report                                                         [ Refresh ] │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│ Migration ID: MIG_20261012_074812                                                           │
│ Source: Planning_Gold_Build.zip                                                             │
│ Destination: Local Environment                                                             │
│ Started By: service.admin@company.com                                                       │
│ Start Time: 12-Oct-2026 12:48:15 PM                                                         │
│ Elapsed Time: 00:04:32                                                                      │
│ Current Status: In Progress ⏳                                                              │
│                                                                                             │
│ Component Execution Progress:                                                               │
│ ─────────────────────────────────────────────────────────────────────────────────────────── │
│  ✔ Groups and Membership ......................................... Completed (00:00:22)     │
│  ✔ Application Foundation & Schema ................................ Completed (00:00:45)     │
│  ✔ Dimension Structures & Outlines ................................ Completed (00:01:10)     │
│  ⏳ Essbase Cubes & Stored Data .................................... Processing (00:02:15)    │
│  ☐ Calculation Manager Rules & Templates .......................... Pending                 │
│  ☐ Data Forms & Composite Grids ................................... Pending                 │
│  ☐ Financial Reports & Books ...................................... Pending                 │
│  ☐ Security Access Permissions .................................... Pending                 │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Status Indicators

- ⏳ **In Progress:** The migration engine is actively writing artifacts. Click **[ Refresh ]** to update counters.
- ✔ **Completed:** All artifacts in the category succeeded without issues.
- ⚠️ **Completed With Warnings:** Artifacts were imported, but minor non-fatal warnings occurred (e.g., missing non-critical user mappings).
- ❌ **Failed:** Fatal error occurred. Click on the **Failed** link to inspect stack traces and offending XML nodes.

---

## 🛠️ Performing Import via EPM Automate

For enterprise production deployments, run the migration via scripted command line:

```bash
# Step 1: Login
epmautomate login admin@example.com "MasterPassword" https://target-epm.oraclecloud.com epmeur

# Step 2: (Optional) If target already has an obsolete app, reset instance cleanly
# epmautomate recreate -f

# Step 3: Upload snapshot
epmautomate uploadfile "Production_Planning_Snapshot.zip"

# Step 4: Execute application import
epmautomate importsnapshot "Production_Planning_Snapshot.zip"

# Step 5: Validate post-import application status
epmautomate getappinfo

# Step 6: Logout
epmautomate logout
```

---

## ⚠️ Critical Constraints & Pitfalls During Snapshot Import

> [!CAUTION]
> **Version Incompatibility Warning (`EPMLCM-26000`):**  
> Cloud EPM instances receive monthly updates (e.g., 26.10, 26.11). Importing a snapshot from an older, unsupported version or from a higher release to a lower release may trigger:  
> `EPMLCM-26000: This snapshot is from Cloud EPM <version> that is incompatible with this update.`  
> Always ensure snapshots are taken from an environment running within the supported release compatibility window.

> [!IMPORTANT]
> **Essbase Data Import Rule:**  
> Cloud EPM does **not** allow incremental standalone imports of Essbase data cubes directly through the Migration UI on existing applications. Essbase data is restored **only during initial application creation from a full snapshot**, or loaded separately via Data Integration / Outline Load.

> [!NOTE]
> **Mandatory Browser Session Refresh:**  
> Immediately after a successful application import completes, **log out of the Cloud EPM web interface and log back in**. This ensures your browser session drops stale cached tokens and loads fresh metadata schemas, navigation flows, and role assignments.

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: How do you bypass the browser 2 GB upload limit when importing a large production snapshot—
**Answer:** The Oracle Cloud EPM browser UI enforces a hard 2 GB limit on multipart file uploads. For large snapshots (e.g. 5 GB to 50 GB), you must upload using EPM Automate CLI:
```cmd
epmautomate uploadFile "Prod_Snapshot_30GB.zip"
```
EPM Automate automatically splits the file into 50 MB chunked binary streams with MD5 verification and reassembles it in the cloud Inbox.

### Q2: What happens if an automated import process is interrupted midway by a network disconnect—
**Answer:** Because `importSnapshot` executes server-side, a client network disconnect does not stop the import job. The cloud server completes the database restructuring. You can monitor its completion by logging back in and checking `Tools → Migration → Reports → Migration Status`.

### Q3: Can an administrator import a snapshot while users are actively working in the system—
**Answer:** Never import snapshots while users are connected. The import process acquires exclusive outline locks on Essbase, drops active connections, and invalidates uncommitted Smart View grid submissions. Always broadcast a system maintenance outage beforehand.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [02_Prepare_Snapshot.md](./02_Prepare_and_Export_Snapshots.md) |
| **Next →** | [04_Import_Options_Settings.md](./04_Import_Options_and_Settings.md) |
