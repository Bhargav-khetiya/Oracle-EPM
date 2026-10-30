# Application Lifecycle Management — Complete Guide

> **Section:** 14 — Application Lifecycle  
> **File:** 01 — Lifecycle Guide  
> **Difficulty:** Beginner → Architect  
> **Prerequisites:** [01_What_Is_EPM](../00_Foundation/01_What_Is_EPM.md), [01_Administration_Guide](../04_System_Administration/01_Administration_Guide.md)

---

## What Is Application Lifecycle Management?

Application Lifecycle Management (ALM) covers everything from **creating** an EPM application through **maintaining**, **migrating**, **cloning**, and **recovering** it. Think of it as the complete biography of your EPM application — from birth to daily care to disaster recovery.

---

## The Lifecycle at a Glance

```
Environment Provisioning
     │
     ├── Create Application (3 paths)
     │     ├── Sample App (Vision) → Learning/demo
     │     ├── New App Wizard → Production use
     │     └── Migrate from Snapshot → Restore/transfer
     │
     ├── Day-to-Day Operations
     │     ├── Database Refresh (metadata deployment)
     │     ├── Backups & Snapshots
     │     └── Feature Enablement
     │
     ├── Migration & Cloning
     │     ├── Export/Import Snapshots (LCM)
     │     ├── Clone Environment (Prod → Test)
     │     └── On-Premises → Cloud Migration
     │
     └── Disaster Recovery
           ├── Object Storage Backups (60-day retention)
           └── Instance Recreation (factory reset)
```

---

## Creating an Application — Three Paths

### Path 1: Sample Application (Vision)

A pre-built demonstration application with sample data, forms, rules, and dashboards. Use for learning, demos, and sandbox evaluation.

| Aspect | Detail |
|--------|--------|
| Time to create | ~5 minutes |
| Data included | Complete demonstration data |
| Use case | Training, POC, first-time learning |
| Limitation | Not suitable for production |

### Path 2: New Application Wizard

A multi-step wizard for creating production applications:

1. **General Properties** — Name (max 25 characters, no spaces), description
2. **Application Type** — Standard Planning, Modules, or FreeForm
3. **Calendar Setup** — Fiscal year, period granularity (12 or 13 periods), start month
4. **Currency Configuration** — Single or Multi-Currency, base currency
5. **Review & Create** — Final confirmation

**Application types:**

| Type | Description | Mandatory Dimensions |
|------|-------------|---------------------|
| **Standard Planning** | Manual dimension configuration | Account, Period, Year, Scenario, Version, Entity, Currency |
| **Planning Modules** | Pre-built business modules | Module-specific dimensions pre-configured |
| **FreeForm** | Custom Essbase modeling | None — you define everything |

> [!IMPORTANT]
> Several application settings are **immutable after creation**: application name, fiscal year start, period granularity, and some dimension configurations. Plan these carefully before creating.

### Path 3: Migrate from Snapshot

Restore an application from an LCM (Lifecycle Management) snapshot. Used for:
- Cloning an application to a new environment
- Restoring from backup
- Migrating from on-premises Hyperion

---

## Snapshots and Backups

### Snapshot Types

| Type | Contains | Created By | Size Limit (Web UI) |
|------|----------|-----------|-------------------|
| **Artifact Snapshot** | Forms, rules, dimensions, security, data | `exportsnapshot` command | 2 GB (web upload) |
| **Environment Backup** | Complete environment state | Daily maintenance window | Automatic |
| **Object Storage Backup** | Point-in-time environment copy | Oracle automatic | 60-day retention |

### Key EPM Automate Commands

| Command | Purpose |
|---------|---------|
| `exportsnapshot "SnapshotName"` | Export application artifacts |
| `importsnapshot "SnapshotName"` | Import artifacts into application |
| `downloadfile "SnapshotName"` | Download snapshot to local disk |
| `uploadfile "LocalFile"` | Upload file to EPM Cloud |
| `copySnapshotFromInstance` | Server-to-server snapshot transfer |
| `cloneEnvironment` | One-step environment replication |
| `recreate -f` | Factory reset the instance |
| `restoreEnvironment` | Restore from Object Storage backup |
| `listBackups` | List available backups |

---

## Environment Cloning (Prod → Test)

### Using `cloneEnvironment`

A single command that replicates an entire production environment to a test instance:

```
epmautomate cloneEnvironment SOURCE_URL SOURCE_USER SOURCE_PASS TARGET_URL TARGET_USER TARGET_PASS
```

This copies everything: application, data, security, forms, rules, dashboards.

### Using Snapshot Export/Import

More granular control — choose which artifacts to include:

```
1. On Production:  epmautomate exportsnapshot "Prod_Monthly_Backup"
2. Transfer:       epmautomate copySnapshotFromInstance PROD_URL PROD_USER PROD_PASS "Prod_Monthly_Backup"
3. On Test:        epmautomate importsnapshot "Prod_Monthly_Backup"
```

---

## Database Refresh

After importing metadata changes (adding/removing members, changing properties), you must **refresh the database** to deploy changes to Essbase:

### The Three Phases

| Phase | What Happens | Impact |
|-------|-------------|--------|
| **Phase 1: Validate** | Checks metadata for errors | No data impact |
| **Phase 2: Create Outline** | Updates Essbase outline structure | Brief lock |
| **Phase 3: Restructure** | Reorganizes data blocks to match new outline | Can be slow for large databases |

```
epmautomate refreshcube
```

> [!WARNING]
> Restructuring a large database with sparse dimension changes can take significant time. Schedule during maintenance windows.

---

## On-Premises to Cloud Migration

Migrating from Hyperion on-premises to EPM Cloud follows a two-step methodology:

### Step 1: Export from On-Premises

Use Lifecycle Management (LCM) in Shared Services to export artifacts:
- Planning application
- Essbase data
- Security definitions (role mappings)
- Forms, rules, reports

### Step 2: Import to Cloud

Upload the LCM export to EPM Cloud and import. Key considerations:

| On-Prem Component | Cloud Equivalent |
|-------------------|-----------------|
| Shared Services Security | Access Control / EPM Cloud Roles |
| Hyperion Planning | Planning (PBCS/EPBCS) |
| Essbase Server | Embedded Essbase (managed by Oracle) |
| HFM | Financial Consolidation Cloud |
| DRM | Data Relationship Management Cloud |

**Role mapping is critical:** On-premises uses Shared Services groups; cloud uses predefined roles (Service Administrator, Power User, Planner, Viewer).

---

## Instance Recreation (Factory Reset)

When you need to completely wipe an environment and start fresh:

```
epmautomate recreate -f
```

**What gets destroyed:**
- All applications and data
- All forms, rules, dashboards
- All security assignments
- All snapshots in the inbox/outbox

**What survives:**
- The instance URL
- Identity domain users
- Object Storage backups

---

## Daily Maintenance Window

Oracle runs an automatic daily maintenance window that:
- Creates a cold Essbase backup snapshot
- Performs database optimization
- Applies patches

You can configure the maintenance window time but cannot skip it. The environment is briefly unavailable during this window.

---

## Automation Runbook Example: Nightly Prod-to-Test Sync

```powershell
# Nightly Production-to-Test Replication
$prodUrl = "https://prod.pbcs.oraclecloud.com"
$testUrl = "https://test.pbcs.oraclecloud.com"

# Step 1: Export production snapshot
epmautomate login admin@company.com password $prodUrl
epmautomate exportsnapshot "Nightly_Backup"
epmautomate logout

# Step 2: Copy to test instance
epmautomate login admin@company.com password $testUrl
epmautomate copySnapshotFromInstance $prodUrl admin@company.com password "Nightly_Backup"

# Step 3: Import on test
epmautomate importsnapshot "Nightly_Backup"
epmautomate refreshcube

# Step 4: Verify
epmautomate listfiles
epmautomate logout
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `EPMLCM-26000` | Snapshot compatibility mismatch | Ensure source and target are same EPM version |
| `EPMIE-00070` | Import conflict with existing artifacts | Use "Create or Update" import mode |
| Upload exceeds 2 GB | Web UI file size limit | Use `epmautomate uploadfile` (no size limit) |
| Slow restructure | Large sparse dimension changes | Schedule during maintenance; consider incremental changes |
| Clone fails | Target instance not empty | Run `recreate -f` on target first |

---

## Quick Recall

1. **What are the three ways to create an application?** → Sample App, New App Wizard, Migrate from Snapshot.
2. **What does Database Refresh do?** → Deploys metadata changes to the Essbase outline (3 phases: validate, create outline, restructure).
3. **What is `cloneEnvironment`?** → A single EPM Automate command that replicates an entire environment.
4. **What survives instance recreation?** → Instance URL, identity domain users, Object Storage backups.
5. **What is the daily maintenance window?** → Oracle's automatic daily backup and optimization window.

**Teach-back prompt:** Explain to a colleague the difference between `cloneEnvironment`, `copySnapshotFromInstance`, and `exportsnapshot/importsnapshot` — when would you use each?

---

## Source Provenance

| Source | Files |
|--------|-------|
| ChatGPT | `05_Application_Creation_and_Lifecycle_Management/` (49 files across 6 sections) |
| Claude | `19_Implementation/`, `20_Projects/` |
| Gemini | `05_Application_Creation_and_Lifecycle_Management/` (mirrors ChatGPT) |
| Oracle | [Administering Planning](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfadm/), [EPM Automate](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cepma/) |

