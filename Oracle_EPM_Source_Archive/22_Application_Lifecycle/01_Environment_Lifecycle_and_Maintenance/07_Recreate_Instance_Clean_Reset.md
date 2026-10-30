# Oracle EPM Cloud: Recreate Instance (Remove & Clean Reset)

## 1. What Does `recreate` Do?

The `recreate` command **completely wipes** an EPM Cloud environment and restores it to a clean, empty state — as if it were freshly provisioned.

### What Gets Deleted

| Component | Deleted? | Details |
|-----------|----------|---------|
| **Application** | ✅ Yes | The entire application (all cubes, plans, modules) is destroyed |
| **Database** | ✅ Yes | Essbase databases are dropped and recreated empty |
| **All data** | ✅ Yes | Every data point in every cube is permanently erased |
| **Forms, dashboards, infolets** | ✅ Yes | All UI artifacts are removed |
| **Business rules** | ✅ Yes | All calculation scripts, Groovy rules, rule sets |
| **Navigation flows** | ✅ Yes | Custom navigation flows |
| **Smart Lists** | ✅ Yes | All smart list definitions |
| **Data Maps / Smart Push** | ✅ Yes | All data map configurations |
| **Substitution variables** | ✅ Yes | All sub var definitions |
| **Migration history** | ✅ Yes | Migration Status Reports are cleared |
| **Users** | ❌ No | User accounts in the Identity Domain are **not** deleted |
| **Role assignments** | ❌ No | User role assignments **may persist** (depends on options) |
| **Inbox/Outbox files** | ⚙️ Optional | Only deleted if `removeAll=true` |
| **Stored snapshots** | ⚙️ Optional | Only deleted if `removeAll=true` |
| **Archived backups (Object Storage)** | ⚙️ Optional | Only deleted if `removeAll=true` |

> [!CAUTION]
> **This operation is IRREVERSIBLE.** Once you run `recreate`, the application, all data, and all artifacts are permanently destroyed. There is no "undo." Always take a full backup before recreating.

---

## 2. Command Reference

### Syntax

```
epmautomate recreate [-f] [removeAll=true|false] [TempServiceType=Service_type]
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-f` | Force — skip the interactive confirmation prompt | *(prompts if omitted)* |
| `removeAll` | If `true`: also deletes all snapshots, archived backups in Object Storage, and clears inbox/outbox | `false` |
| `TempServiceType` | Convert the environment to a different service type (see below) | *(keeps current type)* |

**Applies to:** Planning, Planning Modules, FreeForm, Financial Consolidation and Close, Tax Reporting, Account Reconciliation, Profitability and Cost Management, Enterprise Profitability and Cost Management, Enterprise Data Management, Narrative Reporting, Sales Planning, Strategic Workforce Planning.

**Required Role:** Service Administrator

---

## 3. The `removeAll` Parameter — Detailed Behavior

### `removeAll=false` (Default)

- Application, data, database → **DELETED**
- Snapshots in inbox/outbox → **KEPT**
- Archived backups in Object Storage → **KEPT**
- Files in inbox/outbox → **KEPT**

**Use this when:** You want to wipe the application but keep your snapshots and files (e.g., you're about to import a different snapshot)

### `removeAll=true`

- Application, data, database → **DELETED**
- Snapshots in inbox/outbox → **DELETED**
- Archived backups in Object Storage → **DELETED**
- Files in inbox/outbox → **DELETED**

**Verification after `removeAll=true`:**
```cmd
epmautomate listFiles     REM → Returns nothing
epmautomate listBackups   REM → Returns nothing
```

**Use this when:** You want a truly pristine environment with zero remnants of the previous application (e.g., converting to a completely different service type)

---

## 4. The `TempServiceType` Parameter — Switching Business Process Types

You can convert an environment from one business process to another using this parameter.

### Acceptable Values

| Value | Converts to |
|-------|-------------|
| `ARCS` | Account Reconciliation |
| `EDMCS` | Enterprise Data Management (Cloud EDM) |
| `EPRCS` | Narrative Reporting |
| `PCMCS` | Profitability and Cost Management |
| *(omitted)* | Original service type (Planning / FCCS / Tax Reporting / EPCM) |

### Behavior by Subscription Type

#### EPM Enterprise Cloud Service (Full Flexibility)

You can convert to **any** supported business process:

```cmd
REM Convert from Planning to Account Reconciliation
epmautomate recreate -f removeAll=true TempServiceType=ARCS

REM Convert from ARCS to Enterprise Data Management
epmautomate recreate -f removeAll=true TempServiceType=EDMCS

REM Convert back to Planning (original type)
epmautomate recreate -f removeAll=true
```

#### EPM Standard Cloud Service (Limited)

Conversion options are restricted. Check Oracle documentation for your specific subscription.

#### Other Subscriptions (Legacy)

- Planning/Enterprise Planning/Tax/FCCS → Can convert to ARCS, EDMCS, PCMCS
- PCMCS → Can convert to PBCS (Planning)
- PCMCS → **Cannot** convert to ARCS, EDMCS, or EPRCS

### Reverting to Original Service Type

To convert back to the original service type:
```cmd
epmautomate recreate -f
```
*(Omitting `TempServiceType` reverts to the original type)*

---

## 5. Examples

### Example 1: Simple Recreate (Keep Snapshots)

**Scenario:** Wipe the Demo environment clean before importing a Production snapshot. Keep existing snapshots.

```cmd
epmautomate login admin@company.com demo_password.epw "https://planning-test-myco.epm.us1.oraclecloud.com"
epmautomate recreate -f
epmautomate logout
```

### Example 2: Full Clean Recreate (Remove Everything)

**Scenario:** Completely wipe Demo — no snapshots, no files, no archived backups.

```cmd
epmautomate login admin@company.com demo_password.epw "https://planning-test-myco.epm.us1.oraclecloud.com"
epmautomate recreate -f removeAll=true
epmautomate logout
```

### Example 3: Convert to a Different Service Type

**Scenario:** Convert a Planning environment to Enterprise Data Management.

```cmd
epmautomate login admin@company.com password.epw "https://planning-myco.epm.us1.oraclecloud.com"
epmautomate recreate -f removeAll=true TempServiceType=EDMCS
epmautomate logout
```

### Example 4: Recreate with Interactive Confirmation

**Scenario:** Recreate but get prompted for confirmation (safer, recommended for first time).

```cmd
epmautomate login admin@company.com password.epw "https://planning-test-myco.epm.us1.oraclecloud.com"
epmautomate recreate
```

Output:
```
WARNING: This operation will delete the existing application and re-create the database.
Do you want to continue? (y/n): y
```

---

## 6. What Happens After Recreate?

After `recreate` completes, the environment is in a **clean, empty state**:

```
┌─────────────────────────────────────────┐
│        ENVIRONMENT AFTER RECREATE       │
├─────────────────────────────────────────┤
│  Application:    NONE (deleted)         │
│  Database:       EMPTY (recreated)      │
│  Data:           NONE                   │
│  Forms:          NONE                   │
│  Rules:          NONE                   │
│  Security:       Users still exist      │
│                  in Identity Domain     │
│  Inbox/Outbox:   Empty (if removeAll)   │
│                  OR still has files     │
│  Status:         Ready for new app      │
│                  or snapshot import     │
└─────────────────────────────────────────┘
```

### Next Steps After Recreate

You now have two options:

1. **Create a new application** via the EPM Cloud UI (Application → Create)
2. **Import a snapshot** to restore an existing application:
   ```cmd
   epmautomate uploadFile "C:\snapshots\Prod_Snapshot.zip"
   epmautomate importSnapshot "Prod_Snapshot"
   ```
   Or use `copySnapshotFromInstance` to copy directly from another environment.

---

## 7. Timing and Duration

| Environment Size | Recreate Duration |
|-----------------|-------------------|
| Small (< 5 cubes, < 1M cells) | 5–15 minutes |
| Medium (5–15 cubes, 1M–50M cells) | 15–30 minutes |
| Large (15+ cubes, 50M+ cells) | 30–60 minutes |

> [!NOTE]
> The recreate process duration depends mainly on the database teardown and recreation. The actual data deletion is fast since the databases are simply dropped.

---

## 8. Pre-Recreate Safety Checklist

- [ ] **Take a backup** — Run `runDailyMaintenance -f` or manually export a snapshot
- [ ] **Download the backup** — `downloadFile "Artifact Snapshot"` to your local machine
- [ ] **Verify the backup** — Check file size is reasonable (not 0 bytes)
- [ ] **Confirm no users** are working in the environment
- [ ] **Confirm no running jobs** — Check Job Console
- [ ] **Document current settings** — Note the maintenance time, substitution variables, connection settings
- [ ] **Confirm you're logged into the RIGHT environment** — Double-check the URL!
- [ ] **Have the import snapshot ready** — Know exactly what you'll import after recreate

> [!CAUTION]
> **The #1 mistake** with `recreate` is running it on the **wrong environment**. Always triple-check the URL before executing. A `recreate` on Production instead of Test is a disaster scenario.

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the catastrophic risk of running ecreate -f removeAll=true?
**Answer:** Running ecreate -f wipes the application and inbox, but **preserves the 60-day historical backups in OCI Object Storage**. Running ecreate -f removeAll=true permanently expunges **ALL 60-day Object Storage backups**. It performs a cryptographically unrecoverable purge of all tenant archives. Even Oracle Support cannot restore data after emoveAll=true.

### Q2: Does ecreate delete user accounts from the Identity Domain (OCI IAM / IDCS)?
**Answer:** No. User accounts and identity groups exist in the Identity Domain layer, outside the application container. ecreate destroys application definitions, Essbase data, and role assignments within the app, but user identities remain in IDCS and can log into a newly created application once roles are reassigned.

### Q3: How do you use TempServiceType during ecreate to switch an instance to FCCS or ARCS?
**Answer:** If you have an Enterprise Cloud EPM license, you can switch business processes on a clean instance using:
`cmd
epmautomate recreate -f TempServiceType=FCCS
`
This reconfigures the environment container to Financial Consolidation and Close. Supported parameters include ARCS, EDMCS, EPRCS, TRCS, and PCMCS. If omitted, it defaults to Planning / FreeForm.
