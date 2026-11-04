﻿# Oracle EPM Cloud: Instance Remove, Recreate & Migration — Master Overview

## Purpose of This Guide

This documentation set is your **complete reference** for understanding how to:

1. **Remove (recreate)** an existing Oracle EPM Cloud environment
2. **Take backups** (manual & automated) of any environment
3. **Copy a Production instance** into a separate Demo/Test instance
4. **Import/Export** snapshots between environments
5. **Clone environments** for a full replica

> [!IMPORTANT]
> **Your Scenario:** You have an out-of-the-box Planning instance (Prod) and a FreeForm instance. You want to set up a Demo instance as an exact copy of Production so you can safely make project changes without affecting Prod.

---

## Document Index

## 📚 Environment Lifecycle Document Suite Index

| # | File | Topic & Focus Area |
|:---:|:---|:---|
| 01 | [01_Lifecycle_Strategy_and_Overview.md](./01_Lifecycle_Strategy_and_Overview.md) | ← You are here. Master architectural overview & strategy |
| 02 | [02_Key_Concepts_and_Architecture.md](./02_Key_Concepts_and_Architecture.md) | Core concepts — snapshots, environments, backups, artifacts |
| 03 | [03_EPM_Automate_Setup_and_Authentication.md](./03_EPM_Automate_Setup_and_Authentication.md) | CLI installation, encrypted password vaults, authentication |
| 04 | [04_Backup_Strategy_and_Daily_Maintenance.md](./04_Backup_Strategy_and_Daily_Maintenance.md) | Daily maintenance windows, Artifact Snapshots, retention policies |
| 05 | [05_Listing_and_Exploring_Backups.md](./05_Listing_and_Exploring_Backups.md) | `listBackups`, `listFiles`, exploring snapshot inventory |
| 06 | [06_Snapshot_Lifecycle_Management.md](./06_Snapshot_Lifecycle_Management.md) | Snapshot lifecycle, 60-day rule, 150GB limit, export & download |
| 07 | [07_Recreate_Instance_Clean_Reset.md](./07_Recreate_Instance_Clean_Reset.md) | `recreate` command & UI — wiping an environment clean |
| 08 | [08_Copy_Snapshot_Between_Instances.md](./08_Copy_Snapshot_Between_Instances.md) | `copySnapshotFromInstance` — cross-pod server-to-server transfer |
| 09 | [09_Environment_Cloning_Master_Guide.md](./09_Environment_Cloning_Master_Guide.md) | `cloneEnvironment` — full 1-command replica (data, audit, staging) |
| 10 | [10_Object_Storage_Backup_Restoration.md](./10_Object_Storage_Backup_Restoration.md) | `restoreBackup`, `restoreEnvironment` — OCI Object Storage recovery |
| — | **Related Runbooks & Auditing** | |
| 11 | [01_Prod_to_Demo_Complete_Runbook.md](../06_Automation_Runbooks_and_Troubleshooting/01_Prod_to_Demo_Complete_Runbook.md) | **Step-by-step runbook** — copy Prod Planning to Demo sandbox |
| 12 | [02_Enterprise_Automation_Scripts.md](../06_Automation_Runbooks_and_Troubleshooting/02_Enterprise_Automation_Scripts.md) | Enterprise PowerShell & Bash scripts for complete automation |
| 13 | [03_Master_Troubleshooting_FAQ_and_Gotchas.md](../06_Automation_Runbooks_and_Troubleshooting/03_Master_Troubleshooting_FAQ_and_Gotchas.md) | Troubleshooting FAQ, error code catalog & gotchas |
| 14 | [01_Migration_Reports_and_Compliance_Auditing.md](../05_Migration_Reports_Auditing_and_OnPrem_Transition/01_Migration_Reports_and_Compliance_Auditing.md) | Migration status reports, audit logs & delta exports |
| 15 | [02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md](../05_Migration_Reports_Auditing_and_OnPrem_Transition/02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md) | On-premises Hyperion to Cloud migration pathways & Appendix A |

---

## 🔗 Architecture Link: Relationship to Application Creation

This lifecycle guide works hand-in-hand with the **[Application Creation Master Suite](../00_MASTER_INDEX.md)**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. ENVIRONMENT LIFECYCLE (This Guide: EPM_Instance_Remove_Recreate_Guide)   │
│    • Wipe instance clean via `recreate`                                     │
│    • Clone full environment via `cloneEnvironment`                          │
│    • Stream snapshots cross-pod via `copySnapshotFromInstance`              │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ When instance is clean:
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. APPLICATION CREATION (Guide: 05_Application_Creation)                    │
│    • Landing Page: [CREATE Sample]  [START New App]  [MIGRATE Snapshot]     │
│    • Application Wizard, Planning Modules, FreeForm & Post-Creation Setup   │
└─────────────────────────────────────────────────────────────────────────────┘
```


## The Three Approaches — When to Use Which

### Approach 1: Clone Environment (Recommended for Full Copy)

```
Production ──── cloneEnvironment ────► Demo/Test
                 (one command)
```

**Best for:** Creating an identical copy of Prod in Test/Demo, including all data, metadata, security, forms, rules.

**Pros:**
- Single command — server-to-server, no local download needed
- Includes Data Management staging tables, audit data, Job Console (optional)
- Fastest and most complete method

**Cons:**
- Completely **overwrites** the target environment — everything in Demo is deleted first
- Both environments must be on the **same monthly patch version** (no blackout period)

---

### Approach 2: Snapshot Export → Recreate → Import (Selective & Controlled)

```
Production ─── exportSnapshot ──► Download ──► Upload to Demo ──► importSnapshot
                                     OR
Production ─── copySnapshotFromInstance ──► Demo ──► importSnapshot
```

**Best for:** When you want more control over what gets migrated, or when environments are on different patch versions.

**Pros:**
- Granular control over what you import
- Can keep the snapshot file locally as a backup
- Works across different patch versions

**Cons:**
- Multiple manual steps
- Does NOT include Data Management staging tables, audit data, or Job Console data
- Slower process (download → upload → import)

---

### Approach 3: Restore from Oracle Object Storage Backup

```
Oracle Object Storage ─── restoreBackup ──► Demo ──► importSnapshot
            OR
Oracle Object Storage ─── restoreEnvironment ──► Demo (full restore)
```

**Best for:** Disaster recovery, restoring to a specific point-in-time from automated daily backups.

**Pros:**
- Can go back to any available daily backup snapshot
- `restoreEnvironment` is comprehensive (includes users, roles, files)

**Cons:**
- Limited to daily backup retention (Oracle keeps ~60 days in Object Storage)
- Cannot cherry-pick individual artifacts

---

## Decision Matrix

| Question | → Use |
|----------|-------|
| I want an **exact clone** of Prod in Demo | **Approach 1** — `cloneEnvironment` |
| I want to **selectively import** only certain artifacts | **Approach 2** — Snapshot Export/Import |
| I need to **go back to a specific date** (disaster recovery) | **Approach 3** — `restoreBackup` / `restoreEnvironment` |
| Both environments are on **different patch versions** | **Approach 2** — Snapshot method |
| I need Data Management staging tables in Demo | **Approach 1** — `cloneEnvironment` only |
| I want to change the **service type** (e.g., Planning → FreeForm) | Use `recreate` with `TempServiceType` |

---

## High-Level Process Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRODUCTION INSTANCE                         │
│  (Out-of-the-box Planning / FreeForm with real data & config)  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
          ┌───────────────┼────────────────┐
          │               │                │
    ┌─────▼─────┐   ┌────▼─────┐   ┌──────▼──────┐
    │  Option A  │   │ Option B │   │  Option C   │
    │   Clone    │   │ Snapshot │   │  Restore    │
    │Environment │   │ Export/  │   │  Backup     │
    │            │   │ Import   │   │             │
    └─────┬─────┘   └────┬─────┘   └──────┬──────┘
          │               │                │
          │         ┌─────▼──────┐         │
          │         │  Recreate  │         │
          │         │    Demo    │         │
          │         │ (clean it) │         │
          │         └─────┬──────┘         │
          │               │                │
          └───────┬───────┘────────────────┘
                  │
    ┌─────────────▼─────────────────────────────┐
    │          DEMO / TEST INSTANCE             │
    │  (Fresh copy of Prod — safe to modify)    │
    └───────────────────────────────────────────┘
```

---

## Prerequisites Checklist

Before starting any of these processes, ensure:

- [ ] **Service Administrator** role on both Prod and Demo environments
- [ ] **Identity Domain Administrator** role (if importing users/roles)
- [ ] **EPM Automate** utility installed on your local machine
- [ ] **Encrypted password files** created for both environments
- [ ] **No users** are actively working in the target (Demo) environment
- [ ] **Daily maintenance** is NOT currently running on either environment
- [ ] Both environments are on the **same patch version** (for clone approach)
- [ ] You have taken a **backup of the Demo environment** (in case you need to revert)

---

## What's NOT Included in Snapshots

> [!WARNING]
> Standard snapshots (Artifact Snapshots) do **NOT** include:
> - **Audit data** — historical audit trail
> - **Job Console data** — job run history
> - **Data Management staging tables** — FDMEE/DM data
> - **Access logs** and **Activity Reports**
>
> To get these, you must use `cloneEnvironment` or the Clone Environment UI feature.

---

## Next Steps

Start with [02_Key_Concepts_and_Architecture.md](./02_Key_Concepts_and_Architecture.md) to understand foundational concepts, then proceed sequentially through the documents.

For a direct **step-by-step walkthrough** of copying Prod to Demo, jump to [01_Prod_to_Demo_Complete_Runbook.md](../06_Automation_Runbooks_and_Troubleshooting/01_Prod_to_Demo_Complete_Runbook.md).

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: When should an enterprise use cloneEnvironment versus the multi-step exportSnapshot + importSnapshot approach—
**Answer:** Use cloneEnvironment when you need an exact, full-fidelity replica of Production in Test/Demo—including Data Management staging tables, historical audit logs, and Job Console history—in a single unattended command. Use the snapshot approach (exportSnapshot $\to$ copySnapshotFromInstance $\to$ importSnapshot) when:
1. Environments are in different monthly patch windows (Test on release .11, Prod on .10).
2. You only want selective artifacts (e.g. metadata and rules without multi-year transactional data).
3. You need to keep an offline archival .zip file for compliance or disaster recovery.

### Q2: What happens if an administrator initiates a clone during the two-week monthly patch window between Test and Prod—
**Answer:** The clone command fails immediately with a version incompatibility error (EPMLCM-14000: Release version mismatch). Oracle blocks cross-version cloning to prevent relational schema and Essbase outline corruption. The only supported method during this window is to migrate from the lower version to the higher version (Prod $\to$ Test) using snapshot copy, never higher to lower.

### Q3: Can you execute environment lifecycle commands while end users are actively working in the system—
**Answer:** Non-destructive commands (listFiles, listBackups) are safe during active hours. Destructive operations (ecreate, cloneEnvironment, estoreEnvironment, unDailyMaintenance) will forcefully terminate all active HTTP/Smart View sessions, abort running calculation scripts, rollback uncommitted data grids, and lock out users. Always broadcast an outage notification and set the system to Admin-only mode before executing lifecycle operations.
