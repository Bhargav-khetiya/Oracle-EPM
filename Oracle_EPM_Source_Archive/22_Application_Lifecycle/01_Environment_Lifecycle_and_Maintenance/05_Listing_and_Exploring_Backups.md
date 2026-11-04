﻿# Oracle EPM Cloud: List and Explore Backups

## 1. `listBackups` — Discover Available Archived Backups

The `listBackups` command shows all **Artifact Snapshots** and **Environment Backups** that have been archived to Oracle Object Storage by the daily maintenance process.

### Why You Need This

Before restoring any backup, you need to know **what's available**. Oracle retains these archived backups for approximately 60 days, each tagged with the exact timestamp of when it was created.

---

### Command Reference

**Syntax:**
```
epmautomate listBackups
```

**Applies to:** Planning, Planning Modules, FreeForm, Financial Consolidation and Close, Tax Reporting, Account Reconciliation, Profitability and Cost Management, Enterprise Profitability and Cost Management, Enterprise Data Management, Narrative Reporting, Sales Planning, Strategic Workforce Planning.

**Required Roles:**
- Service Administrator, **OR**
- Any application role + the **Migrations - Administer** granular role

### Example Usage

```cmd
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"
epmautomate listBackups
epmautomate logout
```

### Sample Output

```
Backups:
2026-10-09T02:00:00/Artifact_Snapshot.zip
2026-10-09T02:00:00/Environment_Backup
2026-10-08T02:00:00/Artifact_Snapshot.zip
2026-10-08T02:00:00/Environment_Backup
2026-10-07T02:00:00/Artifact_Snapshot.zip
2026-10-07T02:00:00/Environment_Backup
2026-10-06T02:00:00/Artifact_Snapshot.zip
2026-10-06T02:00:00/Environment_Backup
... (up to ~60 days of backups)
```

### Understanding the Output

| Entry | Type | What It Contains |
|-------|------|------------------|
| `YYYY-MM-DDTHH:MM:SS/Artifact_Snapshot.zip` | Artifact Snapshot | Application artifacts only (metadata, data, forms, rules, security) |
| `YYYY-MM-DDTHH:MM:SS/Environment_Backup` | Environment Backup | Full environment (application + users + roles + inbox/outbox + settings) |
| `YYYY-MM-DDTHH:MM:SS/EPRCS_Backup.tar.gz` | Narrative Reporting Backup | *(Narrative Reporting only)* Full NR backup in tar.gz format |

> [!NOTE]
> The timestamp (e.g., `2026-10-09T02:00:00`) is in **UTC time**, reflecting when the daily maintenance started. This may differ from your local time zone.

### What to Do Next

- **To use an Artifact Snapshot:** Use `restoreBackup` to copy it to your environment, then `importSnapshot` to import it → see [10_Restore_Backup_and_Environment.md](./10_Object_Storage_Backup_Restoration.md)
- **To use an Environment Backup:** Use `restoreEnvironment` to fully restore your environment → see [10_Restore_Backup_and_Environment.md](./10_Object_Storage_Backup_Restoration.md)

---

## 2. `listFiles` — See What's in Your Inbox/Outbox Right Now

The `listFiles` command shows all files currently in the environment's **default location** (inbox/outbox), including snapshots, data files, export files, and more.

### Why You Need This

Before importing a snapshot, uploading a file, or downloading something, you need to know exactly what files exist in the environment. This is your "directory listing" for the EPM Cloud file system.

---

### Command Reference

**Syntax:**
```
epmautomate listFiles
```

**Applies to:** Planning, Planning Modules, FreeForm, Financial Consolidation and Close, Tax Reporting, Account Reconciliation, Profitability and Cost Management, Enterprise Profitability and Cost Management, Enterprise Data Management, Narrative Reporting, Sales Planning, Strategic Workforce Planning.

**Required Roles:**
- Service Administrator, **OR**
- Any application role + the **Migrations - Administer** granular role

### Example Usage

```cmd
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"
epmautomate listFiles
epmautomate logout
```

### Sample Output

```
Artifact Snapshot
MyCustomBackup
inbox/data_load_jan.csv
inbox/exchange_rates.csv
outbox/export_report.csv
outbox/member_export.csv
Logs/Migration Status Report 2026_10_09.txt
```

### Understanding the Output

| File Pattern | What It Is |
|-------------|------------|
| `Artifact Snapshot` | The daily maintenance backup (most recent) |
| Custom names (e.g., `MyCustomBackup`) | Manually created snapshots via Migration UI or `exportSnapshot` |
| `inbox/*` | Files uploaded by admin (data files, templates) |
| `outbox/*` | Files exported by the system (reports, data exports) |
| `Logs/*` | Migration status reports and logs |
| Incremental/backup export files | Data export files from business rules or data management |

> [!WARNING]
> `listFiles` will **not show the current snapshot** if the command is executed **while daily maintenance is running** (i.e., while the snapshot is being generated). Wait for maintenance to complete before listing.

---

## 3. Practical Workflows

### Workflow A: "What backups do I have available—

```cmd
REM Login to the environment
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"

REM Check archived backups (Object Storage - last ~60 days)
epmautomate listBackups

REM Check current files in inbox/outbox
epmautomate listFiles

REM Logout
epmautomate logout
```

### Workflow B: "Find a specific date's backup and restore it"

```cmd
REM Login
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"

REM List all archived backups
epmautomate listBackups
REM Output shows: 2026-10-05T02:00:00/Artifact_Snapshot.zip

REM Restore that specific backup to the inbox
epmautomate restoreBackup "2026-10-05T02:00:00/Artifact_Snapshot.zip" targetName=Oct5_Backup

REM Verify it's now in the inbox
epmautomate listFiles
REM Output should show: Oct5_Backup.zip

REM Now you can import it
epmautomate importSnapshot "Oct5_Backup"

REM Logout
epmautomate logout
```

### Workflow C: "Check if my upload was successful"

```cmd
REM Login
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"

REM Upload a snapshot
epmautomate uploadFile "C:\EPM_Scripts\snapshots\Prod_Snapshot.zip"

REM Verify the upload
epmautomate listFiles
REM Should show: Prod_Snapshot

REM Logout
epmautomate logout
```

---

## 4. Tips and Best Practices

| Tip | Details |
|-----|---------|
| **Run `listBackups` before any restore** | Always verify the backup exists before attempting `restoreBackup` or `restoreEnvironment` |
| **Run `listFiles` after upload** | Confirm your file made it to the inbox before trying to import |
| **Timestamps are UTC** | The backup names like `2026-10-09T02:00:00` are in UTC. Adjust for your timezone |
| **Maintenance in progress—** | If `listFiles` doesn't show the `Artifact Snapshot`, maintenance may be running. Wait and retry |
| **Retention is ~60 days** | If you need a backup older than 60 days, you must have already downloaded it locally |
| **File names are case-sensitive** | `Artifact Snapshot` ≠ `artifact snapshot` — use exact casing |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the exact functional distinction between listFiles and listBackups—
**Answer:**
- listFiles queries the **epm-cloud filesystem container (Inbox/Outbox)**. It lists active user-uploaded data files, error logs, and the current day's active Artifact Snapshot.
- listBackups queries the **OCI Object Storage archive**. It lists the rolling 60-day historical cold backups (e.g. 2026-10-01_Backup, 2026-10-02_Backup) that are preserved offsite and not directly visible in the Inbox.

### Q2: Why do some files listed by listFiles not appear in the web UI Inbox/Outbox explorer—
**Answer:** Files placed in subdirectories or generated by internal system jobs (such as Data Management staging files, temporary Essbase error logs, or chunked upload parts) are indexed by the CLI filesystem parser but may be filtered out from the Migration web UI view to prevent accidental user corruption.

### Q3: Can you filter the output of listFiles directly using wildcard arguments like *.zip—
**Answer:** No. The listFiles command does not accept command-line wildcard parameters natively in EPM Automate. To filter output, pipe the command output through your operating system shell:
- Windows Batch: epmautomate listFiles | findstr /i "\.zip"
- Windows PowerShell: (& epmautomate listFiles) | Where-Object {  -match '\.zip$' }
"@

    "06_Snapshot_Lifecycle_Management.md" = @"
---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the hard rule for snapshot retention in the Inbox, and when does Oracle automatically purge them—
**Answer:** Every day during the Daily Maintenance window, the automated backup routine creates a new Artifact Snapshot in the Inbox, **overwriting yesterday's Artifact Snapshot**. Custom-named snapshots (e.g. Pre_Migration_FY26.zip) remain in the Inbox until manually deleted, subject to the **150 GB tenant threshold**. If tenant storage exceeds 150 GB, Oracle sends compliance alerts and may block further snapshot creation until old archives are deleted.

### Q2: What happens if an organization exceeds the 150 GB total snapshot storage quota—
**Answer:** Oracle Cloud EPM does not instantly shut down the application, but:
1. Automated daily maintenance logs flag warning events.
2. Large exportSnapshot or cloneEnvironment jobs may fail with disk quota exceeded errors.
3. Oracle Cloud Operations issues a compliance notice giving the tenant 30 days to purge unneeded snapshots down below 150 GB.

### Q3: Why does downloading a 5 GB snapshot via the browser fail at 2 GB, while epmautomate downloadFile succeeds—
**Answer:** The Oracle Cloud EPM Web Application Firewall (WAF) and web UI reverse proxy enforce a strict **2 GB payload limit** on standard browser HTTP downloads. For files larger than 2 GB, browser sessions suffer timeouts or buffer overflows. EPM Automate bypasses this by utilizing chunked binary streaming with automated retry logic, supporting multi-gigabyte files up to the maximum snapshot size.
