# Oracle EPM Cloud: Restore Backup and Restore Environment

## 1. Overview — Two Restore Commands

Oracle provides two distinct restore commands for different purposes:

| Command | Purpose | What It Does |
|---------|---------|-------------|
| `restoreBackup` | Retrieve an **Artifact Snapshot** from Object Storage archive | Copies the archived snapshot to inbox — you then import it manually |
| `restoreEnvironment` | Full **environment restore** from an Environment Backup | Restores the entire environment in one step (app + users + files) |

```
Oracle Object Storage Archive (~60 days of backups)
  │
  ├── 2026-10-09T02:00:00/Artifact_Snapshot.zip  ─── restoreBackup ──► Inbox ──► importSnapshot
  ├── 2026-10-09T02:00:00/Environment_Backup      ─── restoreEnvironment ──► Full Restore
  ├── 2026-10-08T02:00:00/Artifact_Snapshot.zip
  ├── 2026-10-08T02:00:00/Environment_Backup
  └── ...
```

---

## 2. `restoreBackup` — Retrieve Archived Artifact Snapshot

### What It Does

Copies a specific **Artifact Snapshot** from Oracle Object Storage back to your environment's inbox/outbox so you can then import it. This is a **two-step process** — restore first, then import.

### When to Use

- You need to go back to a specific date's snapshot
- The current Artifact Snapshot in inbox has been overwritten
- You want to import a point-in-time backup selectively

### Command Reference

**Syntax:**
```
epmautomate restoreBackup SNAPSHOT_NAME [targetName=TARGET_SNAPSHOT_NAME]
```

| Parameter | Description | Example |
|-----------|-------------|---------|
| `SNAPSHOT_NAME` | Name of the backup as shown by `listBackups` | `2026-10-05T02:00:00/Artifact_Snapshot.zip` |
| `targetName` | *(Optional)* Rename the restored file (without extension) | `Oct5_Backup` |

**Default naming:** If you don't specify `targetName`, the `/` in the path is replaced with `_`. For example:
- Source: `2026-10-05T02:00:00/Artifact_Snapshot.zip`
- Restored as: `2026-10-05T02:00:00_Artifact_Snapshot.zip`

**Applies to:** Planning, Planning Modules, FreeForm, Financial Consolidation and Close, Tax Reporting, Account Reconciliation, Profitability and Cost Management, Enterprise Profitability and Cost Management, Enterprise Data Management, Narrative Reporting, Sales Planning, Strategic Workforce Planning.

**Required Roles:**
- Service Administrator, **OR**
- Any application role + Migrations - Administer granular role

### Examples

**Restore with a custom target name:**
```cmd
epmautomate restoreBackup "2026-10-05T02:00:00/Artifact_Snapshot.zip" targetName=Oct5_Backup
```

**Restore with default naming:**
```cmd
epmautomate restoreBackup "2026-10-05T02:00:00/Artifact_Snapshot.zip"
```
*(Restored as `2026-10-05T02:00:00_Artifact_Snapshot.zip`)*

### Complete Restore-and-Import Workflow

```cmd
REM Login
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"

REM Check available backups
epmautomate listBackups

REM Restore a specific backup
epmautomate restoreBackup "2026-10-05T02:00:00/Artifact_Snapshot.zip" targetName=Oct5_Backup

REM Verify it's in the inbox
epmautomate listFiles

REM Import the restored snapshot
epmautomate importSnapshot "Oct5_Backup" importUsers=true

REM Logout
epmautomate logout
```

### Narrative Reporting — Special Process

For **Narrative Reporting** environments only, the restore/import process is different:

1. Restore the backup:
   ```cmd
   epmautomate restoreBackup "2026-10-05T02:00:00/EPRCS_Backup" targetName=Example_EPRCS_Backup
   ```

2. Download the restored snapshot:
   ```cmd
   epmautomate downloadFile "Example_EPRCS_Backup"
   ```

3. Rename the downloaded file to `EPRCS_Backup`

4. Upload with the correct name:
   ```cmd
   epmautomate uploadFile "EPRCS_Backup" to_be_imported
   ```
   *(Note the `to_be_imported` location — required for Narrative Reporting)*

5. In the Narrative Reporting UI:
   - Open the **Daily Maintenance** card
   - Select **Use an Uploaded Backup Snapshot**
   - Click **Schedule Restore**
   - Confirm with **Yes**

6. The snapshot will be imported during the next daily maintenance run.

---

## 3. `restoreEnvironment` — Full Environment Restore

### What It Does

Restores the **entire environment** from an **Environment Backup** (not just an Artifact Snapshot). This is the most comprehensive restore — it can restore:

- All application artifacts (metadata, data, forms, rules, security)
- Users and application role assignments (optional)
- EPM groups and granular role assignments (always restored)
- Daily maintenance start time (optional)
- Inbox/outbox contents and stored snapshots (optional)

### When to Use

- **Disaster recovery** — the environment has crashed or become corrupted
- **Data loss** — application changes caused unrecoverable issues
- You need a **complete point-in-time restore** including users, files, and settings
- A snapshot import (`importSnapshot`) alone won't fix the issue

> [!WARNING]
> `restoreEnvironment` is a **heavy operation**. It completely overwrites the current environment state. Use it only when necessary — for routine migration between environments, use `cloneEnvironment` or the snapshot approach instead.

### Command Reference

**Syntax:**
```
epmautomate restoreEnvironment ENV_BACKUP_NAME [UsersAndApplicationRoles=true|false] [DailyMaintenanceStartTime=true|false] [StoredSnapshotsAndFiles=true|false]
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ENV_BACKUP_NAME` | Name of the Environment Backup (from `listBackups`) | *(required)* |
| `UsersAndApplicationRoles` | Restore users and role assignments | `false` |
| `DailyMaintenanceStartTime` | Reset maintenance time to match the backup | `true` |
| `StoredSnapshotsAndFiles` | Restore inbox/outbox contents and stored snapshots | `false` |

**Critical:** `ENV_BACKUP_NAME` must be an **Environment Backup** (not an Artifact Snapshot). Environment Backups have the format `YYYY-MM-DDTHH:MM:SS/Environment_Backup`.

**Applies to:** Planning, Planning Modules, FreeForm, Financial Consolidation and Close, Tax Reporting, Account Reconciliation, Profitability and Cost Management, Enterprise Profitability and Cost Management, Enterprise Data Management, Narrative Reporting, Sales Planning, Strategic Workforce Planning.

**Required Roles:**
- Service Administrator
- Identity Domain Administrator + any application role (if restoring users/roles)

### Examples

**Basic environment restore:**
```cmd
epmautomate restoreEnvironment "2026-10-05T02:00:00/Environment_Backup"
```

**Full restore with users, files, but keep current maintenance time:**
```cmd
epmautomate restoreEnvironment "2026-10-05T02:00:00/Environment_Backup" UsersAndApplicationRoles=true DailyMaintenanceStartTime=false StoredSnapshotsAndFiles=true
```

**Restore without changing maintenance schedule:**
```cmd
epmautomate restoreEnvironment "2026-10-05T02:00:00/Environment_Backup" DailyMaintenanceStartTime=false storedSnapshotsAndFiles=true
```

---

## 4. `restoreBackup` vs. `restoreEnvironment` — Comparison

| | `restoreBackup` | `restoreEnvironment` |
|---|---|---|
| **Input** | Artifact Snapshot from Object Storage | Environment Backup from Object Storage |
| **Action** | Copies snapshot to inbox (staging) | Directly restores the environment |
| **Requires import step?** | ✅ Yes — `importSnapshot` needed after | ❌ No — one-step complete restore |
| **Application content** | ✅ (after import) | ✅ |
| **Users & roles** | ⚙️ Optional (via `importUsers` in import) | ⚙️ Optional |
| **Inbox/Outbox** | ❌ | ⚙️ Optional |
| **EPM Groups & Granular Roles** | ❌ | ✅ Always |
| **Maintenance time** | ❌ | ⚙️ Optional |
| **Stored snapshots** | ❌ | ⚙️ Optional |
| **Granular control** | ✅ Choose what to import | ❌ All-or-nothing |
| **Typical use case** | Selective restore, cross-environment | Disaster recovery |
| **Risk level** | Lower (two-step, can verify before import) | Higher (immediate full overwrite) |

---

## 5. Finding the Right Backup to Restore

### Step 1: List Available Backups

```cmd
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"
epmautomate listBackups
```

### Step 2: Identify the Right One

Sample output:
```
2026-10-09T02:00:00/Artifact_Snapshot.zip        ← Latest
2026-10-09T02:00:00/Environment_Backup           ← Latest (full)
2026-10-08T02:00:00/Artifact_Snapshot.zip        ← Yesterday
2026-10-08T02:00:00/Environment_Backup           ← Yesterday (full)
2026-10-07T02:00:00/Artifact_Snapshot.zip        ← 2 days ago
...
2026-08-11T02:00:00/Artifact_Snapshot.zip        ← ~60 days ago (oldest)
2026-08-11T02:00:00/Environment_Backup           ← ~60 days ago (oldest)
```

### Step 3: Choose Your Restore Method

- **Want selective import?** → Use `restoreBackup` with the `Artifact_Snapshot.zip` entry
- **Want complete restore?** → Use `restoreEnvironment` with the `Environment_Backup` entry

> [!NOTE]
> **Timestamps are UTC.** If your maintenance runs at 2:00 AM UTC and you're in IST (UTC+5:30), the backup timestamp `2026-10-09T02:00:00` corresponds to 7:30 AM IST on October 9th.

---

## 6. Safety Recommendations

> [!CAUTION]
> **Before ANY restore operation:**
> 1. **Backup the current state** — Run `runDailyMaintenance -f` and download the snapshot
> 2. **Verify the backup exists** — Run `listBackups` and confirm your target backup is listed
> 3. **Confirm no active users** — Notify users and ensure nobody is working
> 4. **Double-check the environment** — Make sure you're logged into the right one
> 5. **Plan for downtime** — Restores can take 1–6 hours depending on size
> 6. **Have a rollback plan** — If the restore fails or produces unexpected results

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the critical operational difference between estoreBackup and estoreEnvironment?
**Answer:**
- estoreBackup: Retrieves an archived snapshot from Object Storage and places the .zip file into the **Inbox**. It does **NOT** touch the active application. Planners can continue working uninterrupted.
- estoreEnvironment: Performs a **full bare-metal disaster recovery**. It wipes the current environment clean and restores the entire system image from Object Storage, destroying all changes made since that backup was taken.

### Q2: How can an administrator recover an individual business rule from a 30-day-old backup without overwriting the live database?
**Answer:**
1. Run epmautomate restoreBackup "2026-09-12_Backup.zip" to place the archive in the Inbox.
2. Download it locally and upload it to a Test or Sandbox environment.
3. In the Test Migration UI, expand Planning â†’ Artifacts â†’ Business Rules.
4. Select ONLY the required rule and click Import.
5. Export that single rule as a small patch snapshot and import it cleanly into Production.

### Q3: What is the maximum retention period for backups in Oracle Object Storage, and what happens on Day 61?
**Answer:** Oracle retains automated backups for approximately **60 days** on a rolling basis. On Day 61, the oldest backup is automatically and irreversibly purged by lifecycle policies. To maintain compliance for 7-year audit requirements, organizations must automate nightly downloads of the Artifact Snapshot to offsite enterprise storage (AWS S3, Azure Blob, or internal NAS).
