# Oracle EPM Cloud: Backup Strategy and Daily Maintenance

## 1. Understanding the Daily Maintenance Process

Oracle EPM Cloud **requires** every environment to undergo a daily maintenance window. This is not optional — it is a built-in platform requirement.

### What Happens During Daily Maintenance

The process runs automatically in this sequence:

```
┌──────────────────────────────────────────────────────────┐
│              DAILY MAINTENANCE SEQUENCE                   │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  1. ❌ Environment goes OFFLINE                          │
│     └─ All active user sessions are terminated           │
│     └─ Running jobs may be forcefully stopped            │
│                                                          │
│  2. 📸 Artifact Snapshot is created                      │
│     └─ Overwrites previous day's "Artifact Snapshot"     │
│     └─ Contains: metadata, data, forms, rules, security │
│                                                          │
│  3. 💾 Environment Backup is archived                    │
│     └─ Stored in Oracle Object Storage                   │
│     └─ Retained for ~60 days                             │
│     └─ Includes inbox/outbox, users, roles               │
│                                                          │
│  4. 🔧 Patches are applied (if pending)                  │
│     └─ Monthly patches on 1st Friday (Test)              │
│     └─ Monthly patches on 3rd Friday (Prod)              │
│                                                          │
│  5. 🔄 Essbase optimization & restart                    │
│     └─ Database restructures if needed                   │
│     └─ Temp files cleaned up                             │
│                                                          │
│  6. ✅ Environment comes back ONLINE                     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Duration

| Scenario | Typical Duration |
|----------|------------------|
| Normal day (no patches) | **15–30 minutes** |
| Monthly patch day | **30–60+ minutes** |
| Large application with many cubes | **30–45 minutes** |

---

## 2. Setting the Maintenance Time

### Via the UI

1. Sign in to EPM Cloud as **Service Administrator**
2. Navigate to **Tools → Daily Maintenance**
3. Set the **Start Time** (in the environment's configured timezone)
4. Click **Save**

### Best Practices for Scheduling

- Schedule during the **lowest activity period** (e.g., 2:00 AM local time)
- Consider time zones of all users if the organization is global
- Avoid scheduling near end-of-period close deadlines
- Coordinate between Prod and Test if users work in both
- **Do NOT** schedule both Prod and Test at the same time if you plan to clone between them

---

## 3. The Artifact Snapshot

The **Artifact Snapshot** is the most important output of daily maintenance.

### Key Facts

| Property | Value |
|----------|-------|
| **Name** | `Artifact Snapshot` (always this exact name) |
| **Location** | Migration inbox/outbox (default location) |
| **Format** | `.zip` file |
| **Created** | Every day during daily maintenance |
| **Retention** | **Overwritten daily** — only the most recent exists in inbox |
| **Contents** | Full application export — metadata, data, forms, rules, security, everything |

> [!CAUTION]
> **Oracle keeps ONLY ONE Artifact Snapshot** in the inbox/outbox at any time. Each daily maintenance overwrites the previous day's snapshot. If you need historical backups, you **must** download them before the next maintenance runs.

### How to Download the Current Artifact Snapshot

```cmd
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"
epmautomate downloadFile "Artifact Snapshot"
epmautomate logout
```

This downloads the `.zip` file to your current working directory.

---

## 4. Archived Backups in Oracle Object Storage

While the inbox only holds one snapshot, Oracle **archives** both Artifact Snapshots and Environment Backups to **Object Storage** for approximately **60 days**.

### Artifact Snapshot Archives

- Named: `YYYY-MM-DDTHH:MM:SS/Artifact_Snapshot.zip`
- Example: `2026-10-09T02:00:00/Artifact_Snapshot.zip`
- Contains: Same as the daily Artifact Snapshot

### Environment Backup Archives

- Named: `YYYY-MM-DDTHH:MM:SS/Environment_Backup`
- Example: `2026-10-09T02:00:00/Environment_Backup`
- Contains: **Everything** — application artifacts, users, roles, inbox/outbox contents, maintenance time settings, stored snapshots

### Difference Between Artifact Snapshot and Environment Backup

| | Artifact Snapshot | Environment Backup |
|---|---|---|
| **Application content** | ✅ | ✅ |
| **Users & role assignments** | ❌ (import separately) | ✅ |
| **Inbox/Outbox files** | ❌ | ✅ |
| **Stored snapshots** | ❌ | ✅ |
| **Maintenance time setting** | ❌ | ✅ |
| **Restore command** | `restoreBackup` → `importSnapshot` | `restoreEnvironment` |
| **Overwrite risk** | Selective import | Full environment overwrite |

---

## 5. Manual Backup / On-Demand Maintenance

### Trigger Daily Maintenance Immediately

If you don't want to wait for the scheduled maintenance window, you can force it:

### `runDailyMaintenance` Command

**Syntax:**
```
epmautomate runDailyMaintenance [skipNext=true|false] [-f]
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `skipNext` | Whether to skip the **next** scheduled maintenance after this one | `false` |
| `-f` | Force start without interactive confirmation prompt | *(prompts if omitted)* |

**Applies to:** Planning, Planning Modules, FreeForm, Financial Consolidation and Close, Tax Reporting, Account Reconciliation, Profitability and Cost Management, Enterprise Profitability and Cost Management, Enterprise Data Management, Narrative Reporting, Sales Planning, Strategic Workforce Planning.

**Required Role:** Service Administrator

### Examples

**Force an immediate maintenance (recommended before migration):**
```cmd
epmautomate runDailyMaintenance -f
```

**Run maintenance now AND skip the next scheduled one:**
```cmd
epmautomate runDailyMaintenance skipNext=true -f
```

**Run maintenance with interactive confirmation:**
```cmd
epmautomate runDailyMaintenance skipNext=true
```
*(You will be prompted: "Do you want to continue? (y/n)")*

> [!TIP]
> **Always run `runDailyMaintenance` on Production before starting a migration** to ensure the snapshot you're copying is the absolute freshest. Wait for it to complete before proceeding.

---

## 6. Recommended Backup Strategy

### Minimum Viable Strategy

```
Production:
  ├── Daily Maintenance runs at 2:00 AM (automated)
  ├── EPM Automate script downloads Artifact Snapshot at 3:00 AM (scheduled task)
  ├── Script renames file with date: Snapshot_2026-10-09.zip
  └── Archived to network drive / cloud storage
```

### Enterprise-Grade Strategy

```
Production:
  ├── Daily Maintenance at 2:00 AM
  ├── Automated download at 3:00 AM → rename → archive
  ├── Weekly: Full clone to Test environment (Sunday night)
  ├── Monthly: Download + archive to cold storage (after patch day)
  └── On-demand: Manual snapshot before any major change

Test:
  ├── Daily Maintenance at 4:00 AM (offset from Prod)
  ├── Weekly refresh from Prod (via cloneEnvironment)
  └── Manual snapshots before experimental changes

Archive:
  ├── Network drive: Last 30 days of daily snapshots
  ├── Cloud storage (S3/Azure Blob): Last 6 months
  └── Cold storage: Year-end snapshots kept indefinitely
```

### Sample Automated Download Script (Windows Batch)

```batch
@echo off
REM =====================================================
REM  Daily EPM Backup Download Script
REM  Schedule via Windows Task Scheduler at 3:00 AM
REM =====================================================

SET EPM_USER=admin@company.com
SET EPM_PASS=C:\EPM_Scripts\passwords\prod_password.epw
SET EPM_URL=https://planning-myco.epm.us1.oraclecloud.com
SET BACKUP_DIR=C:\EPM_Scripts\snapshots
SET DATE_STAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%

REM Login
epmautomate login %EPM_USER% %EPM_PASS% %EPM_URL%
IF %ERRORLEVEL% NEQ 0 (
    echo LOGIN FAILED >> C:\EPM_Scripts\logs\backup_%DATE_STAMP%.log
    exit /b 1
)

REM Download the Artifact Snapshot
epmautomate downloadFile "Artifact Snapshot"
IF %ERRORLEVEL% NEQ 0 (
    echo DOWNLOAD FAILED >> C:\EPM_Scripts\logs\backup_%DATE_STAMP%.log
    epmautomate logout
    exit /b 1
)

REM Rename with date stamp
rename "Artifact Snapshot.zip" "Snapshot_%DATE_STAMP%.zip"
move "Snapshot_%DATE_STAMP%.zip" %BACKUP_DIR%\

REM Logout
epmautomate logout

echo BACKUP SUCCESSFUL: Snapshot_%DATE_STAMP%.zip >> C:\EPM_Scripts\logs\backup_%DATE_STAMP%.log
```

> [!IMPORTANT]
> **Relying solely on Oracle's Object Storage for backups is an architectural risk.** Oracle retains backups for ~60 days, but you should maintain your own off-platform archive for business continuity and compliance.

---

## 7. Before-Migration Backup Checklist

Before performing any recreation or migration, follow this checklist:

- [ ] Run `runDailyMaintenance -f` on the **source** (Prod) to get the freshest snapshot
- [ ] Wait for maintenance to complete (check status or wait ~30 min)
- [ ] Download the Artifact Snapshot from Prod locally as a safety copy
- [ ] Run `runDailyMaintenance -f` on the **target** (Demo/Test) to back it up
- [ ] Download the Demo/Test Artifact Snapshot locally (in case you need to revert)
- [ ] Verify both snapshots downloaded successfully (check file sizes)
- [ ] Confirm no users are actively working in the Demo/Test environment
- [ ] Proceed with the migration

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What causes the Daily Maintenance window to take 2 hours instead of the usual 15 minutes?
**Answer:** Several factors trigger extended maintenance durations:
1. **Essbase Outline Restructure / Compaction:** If large metadata additions occurred during the day, Essbase performs defragmentation and page file restructure.
2. **Monthly Cloud Patch Application:** On the 1st and 3rd Fridays, Oracle applies system updates and restarts cloud containers.
3. **Massive Snapshot Archival:** If data volume expanded significantly, compressing the Artifact Snapshot to Object Storage takes longer.
4. **Data Management Index Rebuilds:** Nightly table cleanup on bloated staging repositories.

### Q2: What happens if an automated ETL job is actively writing data when the Daily Maintenance window starts?
**Answer:** Daily Maintenance has absolute priority. At the scheduled start time, the orchestrator forcefully severs all active database connections, aborts running EPM Automate/REST commands, and initiates a clean shutdown of Essbase. Any uncommitted data load transaction is rolled back, and the client script will receive an HTTP 503 or socket reset error. Always schedule automation to finish at least 30 minutes before maintenance starts.

### Q3: Can an administrator trigger an immediate daily maintenance backup on-demand without modifying the scheduled daily window?
**Answer:** Yes. You can execute:
`cmd
epmautomate runDailyMaintenance -f
`
The -f (force) flag triggers the maintenance pipeline immediately. The system enters maintenance mode, kicks out active users, backs up artifacts to the internal repository, and restarts services. Use this before high-risk cutovers or massive metadata migrations.
