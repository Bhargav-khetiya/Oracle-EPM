# 02 — Environment & Snapshot Lifecycle Management

---

## 2.1 Overview: Lifecycle Management (LCM) in the Cloud

In Oracle EPM Cloud, environment governance relies on **Snapshots** (often called LCM Snapshots) — complete archive packages (.ZIP) containing all application artifacts:
* Relational metadata (dimensions, members, aliases, properties).
* UI definitions (forms, dashboards, navigation flows, action menus).
* Calculation logic (Calc Manager rules, rule sets, member formulas).
* Security definitions (groups, roles, access permissions).
* Native data exports (optional Essbase data slices).

EPM Automate provides commands to export, download, upload, import, and clone these snapshots programmatically.

---

## 2.2 Core Snapshot Commands

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SNAPSHOT LIFECYCLE PIPELINE                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. EXPORT:                                                             │
│    epmautomate exportSnapshot "Nightly_Backup_20261027"                │
│    -> Creates ZIP snapshot in cloud staging repository                 │
│                                                                        │
│ 2. DOWNLOAD:                                                           │
│    epmautomate downloadFile "Nightly_Backup_20261027.zip" C:\Backups   │
│    -> Moves archive to on-premise secure SAN/NAS storage               │
│                                                                        │
│ 3. CLEANUP:                                                            │
│    epmautomate deleteFile "Nightly_Backup_20261027.zip"                │
│    -> Frees cloud inbox/outbox storage space                           │
└────────────────────────────────────────────────────────────────────────┘
```

### Detailed Command Reference:

| Command Syntax | Function | Parameters & Notes |
| :--- | :--- | :--- |
| **`exportSnapshot <name>`** | Generates an on-demand LCM snapshot of the application. | Name of snapshot (alphanumeric). Automatically appends `.zip`. |
| **`importSnapshot <name>`** | Restores the application from an existing snapshot in the cloud. | Overwrites existing artifacts. Forces cube restructure upon completion. |
| **`uploadFile <file> [folder]`** | Transfers a local file from your server into the EPM Cloud Inbox. | Used for data files, metadata CSVs, and migration snapshots. |
| **`downloadFile <file> [path]`** | Downloads a file from the EPM Cloud Outbox to your local drive. | Used to pull nightly backups to corporate disaster recovery servers. |
| **`deleteFile <file>`** | Deletes a file from the cloud staging repository. | Essential for storage maintenance. Staging storage is capped at 150 GB. |
| **`listFiles [folder]`** | Lists all files currently stored in the cloud repository. | Outputs file names and sizes. Used to verify upload/export success. |

---

## 2.3 Daily Maintenance & Service Controls

Oracle Cloud EPM environments undergo mandatory automated daily maintenance (typically lasting 15 to 45 minutes) during which Oracle:
1. Generates the system snapshot named **`Artifact Snapshot`**.
2. Applies cloud software patches and infrastructure updates.
3. Compacts Essbase databases and defragments `.PAG` files.
4. Restarts application processes (`ESSSVR`, WebLogic).

### EPM Automate Daily Maintenance Commands:

```cmd
:: Check current maintenance start time
epmautomate getDailyMaintenanceStartTime

:: Set maintenance window to 03:00 UTC (off-peak hours)
epmautomate setDailyMaintenanceStartTime 03:00

:: Manually trigger maintenance on demand (prior to testing or after hours)
epmautomate runDailyMaintenance
```

### Service Restarts and Clean Resets:
* **`epmautomate restart`**: Gracefully bounces the EPM Cloud application servers. Useful when Essbase blocks are locked by a hung process.
* **`epmautomate resetService`**: Kills hung queries and re-initializes service containers.
* **`epmautomate recreate`**: **The Nuclear Option**. Completely wipes the environment, deleting the application, databases, and users, returning the instance to a blank factory state.

---

## 2.4 Cross-Environment Cloning & Direct Migration

Historically, migrating an application from **Production** to **Test** required downloading a 10 GB snapshot to an on-premise computer and re-uploading it to Test, consuming hours of network bandwidth.

Modern EPM Automate provides **Cloud-to-Cloud Direct Migration**:

### 1. `copySnapshotFromInstance`
Transfers a snapshot directly between cloud instances across Oracle's high-speed data center backbone:
```cmd
epmautomate copySnapshotFromInstance https://epm-prod.oraclecloud.com prod_svc C:\Keys\prod.epw "Artifact Snapshot" "Prod_Migration_Snapshot.zip"
```

### 2. `cloneEnvironment` (The 1-Click Refresh)
Clones an entire environment (application, data, users, and audit logs) directly from target to source:
```cmd
epmautomate cloneEnvironment https://epm-test.oraclecloud.com test_svc C:\Keys\test.epw
```
