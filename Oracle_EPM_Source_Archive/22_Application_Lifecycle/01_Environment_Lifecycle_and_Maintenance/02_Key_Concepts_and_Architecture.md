﻿# Oracle EPM Cloud: Key Concepts and Terminology

## 1. What is an EPM Cloud "Instance" / "Environment"—

An **instance** (also called an **environment**) is a fully provisioned Oracle EPM Cloud service deployment. When you purchase an Oracle EPM Cloud subscription, Oracle provisions **two** environments:

| Environment | Purpose | Patching Schedule |
|-------------|---------|-------------------|
| **Production (Prod)** | Live business operations, real users, real data | Patched on the **3rd Friday** of each month |
| **Test** | UAT, development, testing changes safely | Patched on the **1st Friday** of each month |

> [!IMPORTANT]
> **Blackout Period:** Between the 1st Friday (Test patch) and 3rd Friday (Prod patch), the two environments are on **different patch versions**. During this ~2-week window, you **cannot clone** from Prod to Test or vice versa. Snapshot-based migration (Approach 2) still works during this period.

Each environment has its own:
- **URL** (e.g., `https://planning-mycompany.epm.us1.oraclecloud.com`)
- **Application** (Planning, FreeForm, FCCS, etc.)
- **Identity Domain** (user accounts and roles)
- **Inbox/Outbox** (file staging area)
- **Oracle Object Storage** (automated backup archive)

---

## 2. Environment Types / Service Types

Oracle EPM Cloud supports multiple business process types. Each environment can host **one** business process at a time:

| Service Type Code | Business Process | Description |
|-------------------|------------------|-------------|
| *(default)* | **Planning** / **Planning Modules** | Out-of-the-box Planning with modules (Financials, Workforce, Capital, Projects, Strategic Modeling) |
| *(default)* | **FreeForm** | Custom Planning application without pre-built modules |
| *(default)* | **Financial Consolidation and Close (FCCS)** | Financial consolidation |
| *(default)* | **Tax Reporting** | Tax provision calculations |
| `ARCS` | **Account Reconciliation** | Reconciliation management |
| `EDMCS` | **Enterprise Data Management (EDM)** | Master data governance |
| `EPRCS` | **Narrative Reporting** | Report authoring & distribution |
| `PCMCS` | **Profitability and Cost Management** | Cost allocation |

> [!NOTE]
> **EPM Enterprise** subscribers can switch between ANY service type by using `recreate` with the `TempServiceType` parameter. **EPM Standard** subscribers have restricted conversion options.

---

## 3. Snapshots — The Core Migration Unit

A **snapshot** is a compressed file (`.zip`) that contains a complete or partial export of an EPM environment. Snapshots are the primary mechanism for moving content between environments.

### What's Inside a Snapshot

| Category | Included | Details |
|----------|----------|---------|
| **Metadata** | ✅ Yes | Dimensions, members, hierarchies, aliases |
| **Data** | ✅ Yes | All cube data (Essbase/ASO/BSO) |
| **Security** | ✅ Yes | Access control, user provisioning (optional) |
| **Artifacts** | ✅ Yes | Forms, dashboards, infolets, task lists, approval units |
| **Business Rules** | ✅ Yes | Calculation scripts, Groovy rules, rule sets |
| **Smart Lists** | ✅ Yes | Smart list definitions and entries |
| **Data Maps / Smart Push** | ✅ Yes | Data map definitions |
| **Navigation Flows** | ✅ Yes | Custom navigation flows |
| **Substitution Variables** | ✅ Yes | All sub var definitions and values |
| **Reports (FR)** | ✅ Yes | Financial Reports |
| **Reports (Narrative)** | ✅ Yes | Reports, books, bursting definitions |
| **Audit Data** | ❌ No | Historical audit trail — **not in snapshot** |
| **Job Console Data** | ❌ No | Job run history — **not in snapshot** |
| **DM Staging Tables** | ❌ No | Data Management (FDMEE) staging data — **not in snapshot** |
| **Access Logs** | ❌ No | System access logs — **not in snapshot** |
| **Activity Reports** | ❌ No | Usage/activity reports — **not in snapshot** |

### Types of Snapshots

| Snapshot Type | Created By | Name Format | Location |
|---------------|------------|-------------|----------|
| **Artifact Snapshot** | Daily Maintenance (automatic) | `Artifact Snapshot` | Migration inbox/outbox (overwritten daily) |
| **Manual Snapshot** | Administrator via Migration UI or EPM Automate | Custom name (e.g., `MyBackup_Oct2026`) | Migration inbox/outbox |
| **Backup Snapshot** (archived) | Oracle (during daily maintenance) | `YYYY-MM-DDTHH:MM:SS/Artifact_Snapshot.zip` | Oracle Object Storage (~60 days retention) |
| **Environment Backup** (archived) | Oracle (during daily maintenance) | `YYYY-MM-DDTHH:MM:SS/Environment_Backup` | Oracle Object Storage (~60 days retention) |

> [!WARNING]
> **Critical Retention Rule:** The `Artifact Snapshot` in the inbox/outbox is **overwritten every day** during daily maintenance. Only the most recent one exists. Older backups are archived to Oracle Object Storage and can be listed with `listBackups`.

---

## 4. Oracle Object Storage (Backup Archive)

Oracle automatically archives snapshots and environment backups to **Oracle Object Storage** during each daily maintenance cycle. These archived backups:

- Are stored for approximately **60 days**
- Cannot be accessed directly by the user — must use `listBackups` to see them and `restoreBackup` or `restoreEnvironment` to retrieve them
- Include both **Artifact Snapshots** (application only) and **Environment Backups** (full environment including users, roles, inbox/outbox)
- Are identified by timestamp: `2026-10-09T02:00:00/Artifact_Snapshot.zip`

---

## 5. Inbox and Outbox

Every EPM Cloud environment has a virtual file system with two key locations:

| Location | Purpose |
|----------|---------|
| **Inbox** | Upload destination — files go here before import. Used by `uploadFile`, data loads, rules |
| **Outbox** | Download source — exported files appear here. Used by `downloadFile`, data exports |

You can view the contents of both using:
```
epmautomate listFiles
```

Subdirectories can exist within inbox (e.g., `inbox/data_loads/`).

---

## 6. Daily Maintenance Window

Every EPM Cloud environment undergoes a mandatory **1-hour daily maintenance** window:

- **What happens:**
  1. Application is backed up (creates/overwrites `Artifact Snapshot`)
  2. An `Environment Backup` is created and archived to Object Storage
  3. Oracle patches are applied (if any are pending)
  4. Essbase restarts and optimizations run
  5. Old temp files are cleaned up

- **User impact:** Environment is **completely unavailable** during maintenance
- **Default time:** Set by admin via *Tools → Daily Maintenance*
- **Best practice:** Schedule during lowest activity (e.g., 2:00 AM local time)

> [!TIP]
> You can trigger maintenance manually using `epmautomate runDailyMaintenance -f`. This is useful before taking a snapshot for migration — it ensures you have the freshest backup.

---

## 7. Clone vs. Snapshot Migration — Detailed Comparison

| Feature | Clone Environment | Snapshot Export/Import |
|---------|-------------------|----------------------|
| **Command** | `cloneEnvironment` | `exportSnapshot` + `copySnapshotFromInstance` or `uploadFile` + `importSnapshot` |
| **Application data & metadata** | ✅ | ✅ |
| **Users & roles** | ✅ (optional) | ✅ (optional with `importUsers=true`) |
| **Data Management staging** | ✅ (optional) | ❌ |
| **Audit data** | ✅ (optional) | ❌ |
| **Job Console history** | ✅ (optional) | ❌ |
| **Inbox/Outbox files** | ✅ (optional) | ❌ |
| **Maintenance time sync** | ✅ (optional) | ❌ |
| **Requires same patch version** | ✅ Yes | ❌ No |
| **Overwrites target completely** | ✅ Yes (recreates) | Only imported artifacts |
| **Granular artifact selection** | ❌ All-or-nothing | ✅ Via Migration UI |
| **Speed** | Fastest (server-to-server) | Slower (multi-step) |
| **Can work offline** | ❌ | ✅ (download snapshot locally) |

---

## 8. Key EPM Automate Commands Summary

| Command | Purpose |
|---------|---------|
| `encrypt` | Create encrypted password file for script automation |
| `login` | Authenticate to an EPM environment |
| `logout` | End session |
| `listFiles` | List files in inbox/outbox |
| `listBackups` | List archived backups in Object Storage |
| `runDailyMaintenance` | Trigger daily maintenance immediately |
| `exportSnapshot` | Create/refresh a named snapshot |
| `downloadFile` | Download a file from outbox to local machine |
| `uploadFile` | Upload a file from local machine to inbox |
| `importSnapshot` | Import a snapshot into the environment |
| `copySnapshotFromInstance` | Copy a snapshot from another instance (server-to-server) |
| `recreate` | Wipe environment clean (delete app, data, database) |
| `cloneEnvironment` | Full environment replication (recreate + import in one step) |
| `restoreBackup` | Retrieve an archived backup from Object Storage |
| `restoreEnvironment` | Full environment restore from an archived Environment Backup |

---

## 9. Role Requirements Matrix

| Operation | Service Admin | Identity Domain Admin | Migrations - Administer |
|-----------|:------------:|:--------------------:|:----------------------:|
| Login / Logout | ✅ | — | — |
| List Files / Backups | ✅ | — | ✅ (alternative) |
| Export Snapshot | ✅ | — | — |
| Import Snapshot (app only) | ✅ | — | — |
| Import Snapshot (with users) | ✅ | ✅ | — |
| Recreate | ✅ | — | — |
| Clone Environment | ✅ | ✅ (for users) | — |
| Restore Backup | ✅ | — | ✅ (alternative) |
| Restore Environment | ✅ | ✅ (for users) | — |
| Upload / Download Files | ✅ | — | ✅ (alternative) |

> [!NOTE]
> The **Migrations - Administer** granular role can be used as an alternative to the Service Administrator role for certain migration commands. However, for critical operations like `recreate` and `cloneEnvironment`, the full **Service Administrator** role is mandatory.

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the exact architectural difference between an "Artifact Snapshot" and an "Environment Backup"—
**Answer:** 
- An **Artifact Snapshot** (LCM snapshot) is a portable .zip archive containing application metadata (XML, CSV), forms, business rules, Calc Manager scripts, and Level 0 data slices. It can be exported, downloaded, and imported selectively.
- An **Environment Backup** is an automated, full-system disk and relational database image taken during Daily Maintenance and written to Oracle Cloud Object Storage. It represents the complete state of the underlying Kubernetes container, Essbase binaries, and relational schemas.

### Q2: Why does an Artifact Snapshot NOT include Data Management staging tables or audit records by default—
**Answer:** Artifact Snapshots focus on application definition and active data. Data Management staging tables and system audit logs can grow to hundreds of gigabytes over time. Including them in routine snapshots would cause backup files to exceed size limits and drag backup windows past acceptable thresholds. To capture staging and audit data, you must explicitly use cloneEnvironment or configure full LCM audit exports.

### Q3: Can an enterprise query Oracle Cloud Object Storage backups directly using AWS S3 or OCI Object Storage SDKs—
**Answer:** No. Oracle Cloud EPM manages the underlying OCI Object Storage bucket within Oracle's internal infrastructure control plane. Customers do not receive direct S3/OCI REST API bucket credentials. All interactions with Object Storage backups must be orchestrated through EPM Automate commands (listBackups, estoreBackup, estoreEnvironment) or EPM Cloud REST API endpoints.
