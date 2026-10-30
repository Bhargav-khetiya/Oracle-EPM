# Oracle EPM Cloud: Clone Environment (Full One-Command Replication)

## 1. What is `cloneEnvironment`?

The `cloneEnvironment` command is the **most comprehensive** method for replicating an EPM Cloud environment. In a single command, it:

1. **Recreates** the target environment (wipes it clean)
2. **Copies** the snapshot from the source
3. **Imports** everything into the target
4. Optionally imports **users, roles, Data Management, audit data, Job Console, stored snapshots, and more**

```
Source (Production)                        Target (Demo/Test)
       │                                          │
       │          cloneEnvironment                 │
       │  ═══════════════════════════════════════► │
       │      (one command does everything)        │
       │                                          │
       │  1. Recreates target (wipes clean)       │
       │  2. Copies snapshot server-to-server      │
       │  3. Imports all artifacts                 │
       │  4. Imports users & roles (optional)      │
       │  5. Imports DM staging data (optional)    │
       │  6. Imports audit data (optional)         │
       │  7. Imports job history (optional)        │
       │  8. Copies inbox/outbox (optional)        │
       │                                          │
       │  Result: Target = Exact copy of Source   │
```

> [!IMPORTANT]
> `cloneEnvironment` is equivalent to the **"Clone Environment"** feature in the EPM Cloud UI (Tools → Clone Environment). The EPM Automate command provides more flexibility with additional parameters.

---

## 2. Command Reference

### Syntax

```
epmautomate cloneEnvironment TARGET_USERNAME TARGET_PASSWORD_FILE TARGET_URL [parameters]
```

> [!CAUTION]
> **Direction matters!** You must be logged into the **SOURCE** environment. The command pushes FROM where you're logged in TO the target. This is the **opposite direction** from `copySnapshotFromInstance`.

| Parameter | Description | Example |
|-----------|-------------|---------|
| `TARGET_USERNAME` | Service Administrator username on the target | `admin@company.com` |
| `TARGET_PASSWORD_FILE` | Encrypted password file for the target | `C:\passwords\demo_pass.epw` |
| `TARGET_URL` | URL of the target environment | `https://planning-test-myco.epm.us1.oraclecloud.com` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `SnapshotName=NAME` | Name of a specific snapshot to use instead of the default `Artifact Snapshot` | `Artifact Snapshot` |
| `environmentBackup=NAME` | Use an Environment Backup from Object Storage instead of a snapshot (e.g., `2026-10-09T02:00:00/Environment_Backup`) | *(not used)* |
| `UsersAndApplicationRoles=true\|false` | Clone users and their role assignments | `false` |
| `DataManagement=true\|false` | Clone Data Management (FDMEE) staging table data | `false` |
| `appAudit=true\|false` | Clone application audit data | `false` |
| `jobConsole=true\|false` | Clone Job Console history | `false` |
| `storedSnapshotsAndFiles=true\|false` | Clone inbox/outbox files and stored snapshots | `false` |
| `DailyMaintenanceStartTime=true\|false` | Sync maintenance time from source to target | `true` |
| `ApplicationProperties=true\|false` | Clone application properties/settings | `true` |

**Applies to:** Planning, Planning Modules, FreeForm, Financial Consolidation and Close, Tax Reporting, Account Reconciliation, Profitability and Cost Management, Enterprise Profitability and Cost Management, Enterprise Data Management, Narrative Reporting, Sales Planning, Strategic Workforce Planning.

**Required Roles:**
- **Service Administrator** on both source and target
- **Identity Domain Administrator** on target (if `UsersAndApplicationRoles=true`)

---

## 3. Examples

### Example 1: Basic Clone (Application Only)

Clone just the application artifacts (metadata, data, forms, rules, security groups):

```cmd
REM Login to SOURCE (Production)
epmautomate login admin@company.com prod_pass.epw "https://planning-myco.epm.us1.oraclecloud.com"

REM Clone to TARGET (Demo)
epmautomate cloneEnvironment admin@company.com demo_pass.epw "https://planning-test-myco.epm.us1.oraclecloud.com"

REM Logout
epmautomate logout
```

### Example 2: Full Clone (Everything)

Clone absolutely everything — application, users, roles, DM data, audit, job history, inbox/outbox:

```cmd
epmautomate login admin@company.com prod_pass.epw "https://planning-myco.epm.us1.oraclecloud.com"

epmautomate cloneEnvironment admin@company.com demo_pass.epw "https://planning-test-myco.epm.us1.oraclecloud.com" UsersAndApplicationRoles=true DataManagement=true appAudit=true jobConsole=true storedSnapshotsAndFiles=true

epmautomate logout
```

### Example 3: Clone with Custom Snapshot

Use a specific named snapshot instead of the default Artifact Snapshot:

```cmd
epmautomate login admin@company.com prod_pass.epw "https://planning-myco.epm.us1.oraclecloud.com"

epmautomate cloneEnvironment admin@company.com demo_pass.epw "https://planning-test-myco.epm.us1.oraclecloud.com" SnapshotName="FullProdBackup" UsersAndApplicationRoles=true

epmautomate logout
```

### Example 4: Clone from an Environment Backup (Point-in-Time)

Use an archived Environment Backup instead of the current snapshot:

```cmd
epmautomate login admin@company.com prod_pass.epw "https://planning-myco.epm.us1.oraclecloud.com"

epmautomate cloneEnvironment admin@company.com demo_pass.epw "https://planning-test-myco.epm.us1.oraclecloud.com" environmentBackup="2026-10-05T02:00:00/Environment_Backup" UsersAndApplicationRoles=true

epmautomate logout
```

### Example 5: Optimized Clone (Skip Non-Essential Data)

For faster cloning, skip Data Management, audit, and job console data:

```cmd
epmautomate login admin@company.com prod_pass.epw "https://planning-myco.epm.us1.oraclecloud.com"

epmautomate cloneEnvironment admin@company.com demo_pass.epw "https://planning-test-myco.epm.us1.oraclecloud.com" UsersAndApplicationRoles=true DataManagement=false appAudit=false jobConsole=false storedSnapshotsAndFiles=false

epmautomate logout
```

---

## 4. Clone via the Web UI (Step-by-Step with Screen Layout)

If you prefer an interactive browser workflow instead of the command-line interface, Oracle Cloud EPM provides a dedicated **Clone Environment** tool directly in the Service Console.

### 🧭 Navigation
Log in to the **SOURCE** (Production) environment as a Service Administrator:
**Navigation:** `Home → Tools (🔧) → Clone Environment`

### 🖥️ Screen Layout & Options Wireframe

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Clone Environment                                                                    [ Help ❓ ] │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Configure target environment connection and select data components to clone:                     │
│                                                                                                  │
│ Target Environment Details:                                                                      │
│   Target URL:      [ https://planning-test-myco.epm.us1.oraclecloud.com                        ] │
│   User Name:       [ admin@company.com                                                         ] │
│   Password:        [ •••••••••••••••••                                                         ] │
│                                                                                                  │
│ Clone Scope & Artifact Inclusions:                                                               │
│   ☑ Users and Application Roles                                                                  │
│       Clones user accounts, security groups, and role mappings to the target.                    │
│       ⚠️ Requires Identity Domain Administrator role on the target environment.                  │
│                                                                                                  │
│   ☑ Data Management                                                                              │
│       Includes FDMEE / Data Integration staging tables (Workbench data).                         │
│       Note: May add 1–2 hours to execution time depending on data volume.                        │
│                                                                                                  │
│   ☑ Application Audit                                                                            │
│       Transfers metadata and data change audit logs.                                             │
│                                                                                                  │
│   ☑ Job Console                                                                                  │
│       Transfers historical job execution records and run logs.                                   │
│                                                                                                  │
│   ☑ Stored Snapshots and Files                                                                   │
│       Clones all LCM snapshots, CSV files, and data files currently in the Inbox/Outbox.         │
│                                                                                                  │
│   ☑ Sync Daily Maintenance Start Time                                                            │
│       Sets the target's daily maintenance window to match the source environment.                │
│                                                                                                  │
│ ⚠️ WARNING: Cloning will COMPLETELY OVERWRITE the target environment. All existing applications   │
│ and data on the target will be permanently destroyed before replicating the source.              │
│                                                                                                  │
│                                                          [ Clone ]               [ Cancel ]      │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 📋 Step-by-Step Web UI Cloning Procedure

1. **Access Source Instance:** Log into the environment you wish to copy FROM.
2. **Launch Tool:** Click **Tools**, then click **Clone Environment**.
3. **Specify Target:** Enter the full HTTPS URL of the destination instance (e.g., Demo or Test).
4. **Enter Target Credentials:** Provide a user with **Service Administrator** (and optionally **Identity Domain Administrator**) privileges on the target environment.
5. **Select Optional Artifacts:**
   - For a lean, fast clone: Leave **Data Management**, **Application Audit**, and **Job Console** unchecked.
   - For a 100% identical replica: Check all options.
6. **Click [ Clone ]:** Confirm the destructive overwrite prompt.
7. **Monitor Progress:** The system logs out the session and kicks off the background clone job. You can monitor progress in the target environment or via the Source Job Console (`Application → Jobs`).


---

## 5. Timing Estimates

| Configuration | Estimated Duration |
|---------------|-------------------|
| Basic clone (app artifacts only) | 30 min – 2 hours |
| With Users and Roles | +5–15 minutes |
| With Data Management | +1–2 hours |
| With Audit Data | +30–60 minutes |
| With Job Console | +15–30 minutes |
| With Stored Snapshots/Files | +varies by file sizes |
| **Full clone (everything)** | **2–6+ hours** |

> [!TIP]
> **Performance Optimization:** For Demo/Test environments, you often don't need audit data, job history, or DM staging tables. Skipping these can save **1–3 hours** of clone time.

---

## 6. Prerequisites and Restrictions

### Patch Version Requirement

> [!CAUTION]
> **Both environments MUST be on the same monthly patch version.** 
>
> Oracle patches Test environments on the **1st Friday** and Production on the **3rd Friday** of each month. During the ~2-week window between these dates, Test and Prod are on different versions and **cloning is blocked**.
>
> **Workaround:** Use `copySnapshotFromInstance` + `importSnapshot` during the blackout period — this method works across patch versions.

### Other Prerequisites

- [ ] Service Administrator on source AND target
- [ ] Identity Domain Administrator on target (if cloning users)
- [ ] No users actively working in the target
- [ ] Daily maintenance is NOT running on either environment
- [ ] Sufficient time for the clone to complete
- [ ] Target environment backup exists (in case you need to revert)
- [ ] **MFA Disabled**: Ensure the user account executing the clone does NOT have Multi-Factor Authentication (MFA) enabled, as cloning uses basic authorization.
- [ ] **SSO Configuration**: If Single Sign-On (SSO) is used on the source and you are cloning to a different domain, ensure SSO is configured on the target domain *before* cloning.
- [ ] **No Renamed Seeded Period Members**: Cloning may fail if Planning contains a renamed seeded period member that was replaced by a custom period member (e.g., renaming `YearTotal` to `unused_YearTotal` and adding an alternate `YearTotal` member).

### What Gets Overwritten on Target

| Component | What Happens |
|-----------|-------------|
| Application | **REPLACED** — target app is destroyed and rebuilt from source |
| All data | **REPLACED** with source data |
| All artifacts | **REPLACED** with source artifacts |
| Users & roles | **MERGED** — new users added, existing roles updated (not removed) |
| Inbox/Outbox | **REPLACED** (if `storedSnapshotsAndFiles=true`) |
| Maintenance time | **Synced** from source (if `DailyMaintenanceStartTime=true`) |

---

## 7. Post-Clone Verification

After cloning completes:

- [ ] Sign in to the target environment
- [ ] Verify the application loads correctly
- [ ] Check data in key forms
- [ ] Run a business rule to test calculations
- [ ] Verify user access (if users were cloned)
- [ ] **Update any connections** that point to Production:
  - Data Management connections
  - EPM Automate scripts
  - REST API integrations
  - Cross-environment links
- [ ] **Update substitution variables** if they differ between environments
- [ ] Verify the daily maintenance time is appropriate for the target
- [ ] **Change Bookmarks**: Remind users to update their bookmarks to point to the cloned environment.
- [ ] **Modify Integrated Business Processes**: Update navigation flows and connections for integrated processes to ensure SSO works correctly (especially if moving instances to a new domain).
- [ ] **Reconfigure Integration Agent**: Update configuration for the EPM Integration Agent to integrate correctly with the cloned environment.
- [ ] **Update Integration with Other Services**: Verify integration settings if the source was connected to other external services.
- [ ] **Update IP Addresses**: If the source environment's IP was whitelisted in external services or proxy configurations, find the new target IP address (using `nslookup` or `ping`) or the outbound IP address for the target region and update those external configurations.

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: Does cloneEnvironment require the target environment to be wiped clean with ecreate beforehand?
**Answer:** No. cloneEnvironment is fully automated and self-contained. The target environment automatically initiates its own clean recreation as Phase 1 of the clone process, dropping the target database before streaming and restoring the source environment.

### Q2: What happens to Data Management target application connections and drill-through URLs after a clone?
**Answer:** They reflect the **source (Production) environment**. Target application URLs in Data Management will point back to Production. Planners running test data loads in Demo could inadvertently trigger integrations against Production systems. You must immediately navigate to Data Management â†’ Setup â†’ Target Application and update all connection URLs to point to Demo.

### Q3: Why does cloneEnvironment fail if source and target environments are on different monthly patch versions?
**Answer:** Oracle Cloud EPM enforces strict schema parity for bare-metal replication. If Test is on 26.11 and Prod is on 26.10 during the first two weeks of the month, cloning between them is prohibited (Version Mismatch). In this scenario, use the snapshot export/copy/import method instead.
