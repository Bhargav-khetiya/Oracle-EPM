# Oracle EPM Cloud: Export and Download Snapshots

## 1. `exportSnapshot` — Create or Refresh a Named Snapshot

The `exportSnapshot` command repeats a previously performed export operation to create (or refresh) a snapshot in the environment's default location.

### How It Works

When you manually export a snapshot via the **Migration** UI, Oracle records the export configuration (which artifacts, which categories). The `exportSnapshot` command **repeats** that exact same export, overwriting the existing snapshot with fresh data.

> [!IMPORTANT]
> You must have **previously created** the named snapshot at least once via the Migration UI before you can use `exportSnapshot` via EPM Automate. The command replays the last export configuration — it does **not** allow you to specify which artifacts to include.

---

### Command Reference

**Syntax:**
```
epmautomate exportSnapshot SNAPSHOT_NAME
```

| Parameter | Description | Example |
|-----------|-------------|---------|
| `SNAPSHOT_NAME` | The name of an **existing** snapshot in the Migration default location | `NightlyBackup` |

**Applies to:** Planning, Planning Modules, FreeForm, Financial Consolidation and Close, Tax Reporting, Account Reconciliation, Profitability and Cost Management, Enterprise Profitability and Cost Management, Enterprise Data Management, Narrative Reporting, Sales Planning, Strategic Workforce Planning.

**Required Roles:** Service Administrator

### Example

```cmd
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"
epmautomate exportSnapshot NightlyBackup
epmautomate logout
```

This overwrites the existing `NightlyBackup` snapshot with a fresh export using the same artifact selection as the original export.

---

### Creating a Snapshot via Migration UI (First Time)

Before using `exportSnapshot`, you need to create the initial snapshot:

1. Sign in to EPM Cloud
2. Navigate to **Navigator → Migration**
3. Click **Export**
4. Select the artifacts you want to include:
   - ✅ All application artifacts (recommended for full backup)
   - Or select specific categories
5. Enter a **Snapshot Name** (e.g., `FullProdBackup`)
6. Click **Export**
7. Wait for the export to complete
8. Now you can use `epmautomate exportSnapshot FullProdBackup` to refresh it anytime

---

### `exportSnapshot` vs. Daily Maintenance Artifact Snapshot

| | `exportSnapshot` | Daily Maintenance Artifact Snapshot |
|---|---|---|
| **Name** | Custom name you choose | Always `Artifact Snapshot` |
| **Trigger** | Manual / scripted | Automatic (daily) |
| **Content** | Based on your export configuration | Full application export |
| **Overwritten** | Only when you run the command again | Every daily maintenance |
| **Customizable** | ✅ Choose specific artifacts | ❌ Always full |

---

## 2. `downloadFile` — Download Files from EPM Cloud to Local Machine

The `downloadFile` command retrieves a file from the EPM Cloud environment (inbox, outbox, or default location) and saves it to your local machine.

### Command Reference

**Syntax:**
```
epmautomate downloadFile "FILE_NAME" [LOCAL_DIRECTORY]
```

| Parameter | Description | Example |
|-----------|-------------|---------|
| `FILE_NAME` | Name of the file in the cloud (exact name as shown by `listFiles`) | `"Artifact Snapshot"` |
| `LOCAL_DIRECTORY` | *(Optional)* Local folder to save the file. Defaults to current working directory | `"C:\EPM_Scripts\snapshots"` |

**Required Roles:** Service Administrator or Migrations - Administer granular role

### Examples

**Download the daily Artifact Snapshot:**
```cmd
epmautomate downloadFile "Artifact Snapshot"
```
*(Downloads `Artifact Snapshot.zip` to the current directory)*

**Download a custom snapshot:**
```cmd
epmautomate downloadFile "FullProdBackup"
```

**Download a file from the outbox:**
```cmd
epmautomate downloadFile "outbox/export_report.csv"
```

---

## 3. Complete Export-and-Download Workflow

### Scenario: Take a fresh snapshot of Production and download it

```cmd
REM =============================================
REM  Step 1: Login to Production
REM =============================================
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\prod_password.epw" "https://planning-myco.epm.us1.oraclecloud.com"

REM =============================================
REM  Step 2: (Optional) Force a fresh daily maintenance
REM  This ensures the Artifact Snapshot is current
REM =============================================
epmautomate runDailyMaintenance -f

REM =============================================
REM  Step 3: Wait for maintenance to complete
REM  (Command blocks until done, typically 15-30 min)
REM =============================================

REM =============================================
REM  Step 4: Verify the snapshot exists
REM =============================================
epmautomate listFiles

REM =============================================
REM  Step 5: Download the Artifact Snapshot
REM =============================================
epmautomate downloadFile "Artifact Snapshot"

REM =============================================
REM  Step 6: Logout
REM =============================================
epmautomate logout

REM =============================================
REM  Step 7: Rename with date for archival
REM =============================================
rename "Artifact Snapshot.zip" "Prod_Snapshot_2026-10-09.zip"
move "Prod_Snapshot_2026-10-09.zip" "C:\EPM_Scripts\snapshots\"
```

### Scenario: Export a custom snapshot and download it

```cmd
REM Login
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"

REM Refresh the custom snapshot
epmautomate exportSnapshot "FullProdBackup"

REM Download it
epmautomate downloadFile "FullProdBackup"

REM Logout
epmautomate logout
```

---

## 4. Important Notes

> [!WARNING]
> **File Size Considerations:**
> - Large applications can produce snapshots of **several GB**
> - Download time depends on your internet speed and the datacenter location
> - Ensure you have sufficient disk space on your local machine
> - For very large environments, consider using `copySnapshotFromInstance` (server-to-server) instead of downloading locally

> [!NOTE]
> **What if `downloadFile` fails mid-download?**
> - The partial file may remain on your local machine — delete it
> - Re-run the `downloadFile` command (it will overwrite)
> - If the session timed out, `login` again first
> - Check your network connection / VPN

> [!TIP]
> **Pro tip:** If you're transferring a snapshot between two EPM environments and don't need a local copy, skip the download entirely and use `copySnapshotFromInstance` instead — it's faster because it transfers server-to-server within Oracle's network.

---

## 5. Comprehensive Snapshot Lifecycle Management

### A. Web UI vs. EPM Automate Limits

| Operation | Migration Web Interface (UI) | EPM Automate / REST API |
|:---|:---:|:---:|
| **Snapshot Download** | Unlimited file size | Unlimited file size |
| **Snapshot Upload** | **Capped at 2.0 GB** | **Unlimited (Multi-GB supported)** |
| **Individual File Upload** | **Capped at 500 MB** | **Unlimited** |

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ Migration Web UI: Snapshots Screen                                                     │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ Snapshots                                                                              │
│ ────────────────────────────────────────────────────────────────────────────────────── │
│ [ Upload ]  [ Refresh ]                                                                │
│                                                                                        │
│ ┌───┬────────────────────────────────────────┬─────────────┬──────────────┬──────────┐ │
│ │   │ Name                                   │ Size        │ Last Modified│ Actions  │ │
│ ├───┼────────────────────────────────────────┼─────────────┼──────────────┼──────────┤ │
│ │ ▶ │ Artifact Snapshot                      │ 145 MB      │ 12-Oct 01:00 │ [...]    │ │
│ │ ▶ │ FullProdBackup                         │ 210 MB      │ 11-Oct 14:30 │ [...]    │ │
│ └───┴────────────────────────────────────────┴─────────────┴──────────────┴──────────┘ │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### B. Repeating an Export Operation
You can repeat a previously executed export operation to generate a fresh snapshot without having to manually re-select all categories and artifacts:
1. In the Web UI, navigate to **Tools → Migration → Snapshots**.
2. Select the custom snapshot that was previously exported.
3. Click **Actions (...) → Repeat Export**.
4. Enter a new snapshot folder name and click **OK**.
5. The system reuses the exact same artifact inclusion rules and creates an updated snapshot.

### C. Renaming Snapshots
Renaming is useful to align snapshot filenames with automated scripts or resolve name mismatches:
- **Web UI:** Navigate to **Tools → Migration → Snapshots** → select snapshot → **Actions (...) → Rename** → enter new name → click **OK**.
- **EPM Automate:**
  ```cmd
  epmautomate renameSnapshot "Old_Snapshot_Name" "New_Snapshot_Name"
  ```
- **Rule:** You can rename user-created snapshots, but you **CANNOT rename Environment Backups** stored in Oracle Object Storage.

### D. Deleting Snapshots
To prevent storage exhaustion, delete deprecated snapshots:
- **Web UI:** **Tools → Migration → Snapshots** → select snapshot → **Actions (...) → Delete**.
- **EPM Automate:**
  ```cmd
  epmautomate deleteFile "Old_Snapshot_Name.zip"
  ```
- **Critical Caution:** **Never delete the daily maintenance `Artifact Snapshot`**. If accidentally deleted, the next maintenance cycle will re-create it, but you will temporarily lack a baseline recovery snapshot.

### E. Oracle Cloud EPM Retention Policies
Oracle enforces automated storage maintenance policies during the nightly maintenance window:
1. **60-Day Expiration:** Files and snapshots created or uploaded by users are automatically purged after **60 days**.
2. **150 GB Total Storage Threshold:** If the cumulative size of all snapshots exceeds **150 GB**, the system deletes user snapshots from the last 60 days—**oldest first**—until the total storage drops below 150 GB.
3. **Daily Maintenance Snapshot Exemption:** The daily maintenance snapshot (`Artifact Snapshot`) is **always retained**, regardless of size, even if it exceeds 150 GB.
4. **Data Management Logs:** Process logs are retained for **7 days only**. Always download audit or staging files to local storage or Oracle Object Storage if required for compliance.

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the exact deletion priority when tenant snapshot storage exceeds the 150 GB threshold?
**Answer:** Oracle Cloud EPM enforces automated lifecycle pruning during the nightly maintenance window. When total snapshot storage exceeds 150 GB, the system purges user-created snapshots starting from the **oldest creation date first**, continuing until total storage drops below 150 GB. The daily maintenance snapshot (Artifact Snapshot) is **exempt** from this deletion rule and will never be purged by the storage threshold.

### Q2: Why does epmautomate downloadFile succeed on a 15 GB snapshot while browser downloads crash at 2 GB?
**Answer:** The Oracle Cloud EPM Web Application Firewall (WAF) reverse proxy enforces a hard 2 GB timeout buffer on standard browser HTTP downloads. EPM Automate circumvents this by using chunked binary streams (50 MB blocks) with individual MD5 checksum validation and automatic resume capabilities. Always use CLI for files exceeding 2 GB.

### Q3: How do you automate the cleanup of snapshots older than 14 days to prevent storage threshold alerts?
**Answer:** Use an automated PowerShell script with EPM Automate:
`powershell
$files = & epmautomate listFiles
$cutoff = (Get-Date).AddDays(-14)
# Parse custom date-stamped snapshots and delete
$files | Where-Object { $_ -match 'Backup_(\d{4}-\d{2}-\d{2})\.zip' } | ForEach-Object {
    $snapDate = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
    if ($snapDate -lt $cutoff) {
        & epmautomate deleteFile $_
    }
}
`
"@

    "02_Landing_Page_and_Application_Creation\00_Landing_Page_Complete_Overview.md" = @"
---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: When does the Planning Landing Page appear, and why does it disappear once an application exists?
**Answer:** The Planning Landing Page appears **only when an environment container contains ZERO applications** (freshly provisioned or reset via ecreate -f). In Oracle Cloud EPM, each business process pod hosts exactly **one active application**. Once an application is created (via Sample, Wizard, or Migration), the Landing Page is permanently replaced by the Application Home Page. To see the Landing Page again, the application must be dropped.

### Q2: Can a user with the "User" or "Power User" role access the Landing Page?
**Answer:** No. Standard Users and Power Users logging into a clean instance will receive an authorization notice: *"No application is available. Please contact your Service Administrator."* Only users assigned the **Service Administrator** predefined role in Identity Domain (OCI IAM / IDCS) are authorized to view the Landing Page and initiate application creation.

### Q3: If an administrator clicks START by mistake, can they safely return to the clean Landing Page?
**Answer:** Yes. As long as the administrator does not click the final **[Create]** button on Step 5 of the wizard, clicking **[Cancel]** at any step immediately aborts the wizard and returns the browser to the pristine Landing Page without making any changes to the database.
