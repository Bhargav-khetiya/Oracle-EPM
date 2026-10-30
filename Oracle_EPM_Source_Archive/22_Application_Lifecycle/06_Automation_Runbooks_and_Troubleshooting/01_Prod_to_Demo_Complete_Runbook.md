# Oracle EPM Cloud: Complete Walkthrough — Copy Production to Demo

## Overview

This document provides **three complete step-by-step runbooks** for copying your Production Planning (or FreeForm) instance to a Demo/Test instance. Choose the approach that best fits your situation.

> [!IMPORTANT]
> **Your Scenario:** Out-of-the-box Planning instance (Prod) + FreeForm instance. Goal: Create a Demo instance that's an exact copy of Prod for safe project changes.

---

## Pre-Flight Checklist (All Approaches)

Complete these steps before starting ANY approach:

- [ ] **1. Verify credentials:** You have Service Administrator access on both Prod and Demo
- [ ] **2. Verify Identity Domain Admin:** You have this role on Demo (needed for importing users)
- [ ] **3. Disable MFA:** Ensure the user account executing the commands does NOT have Multi-Factor Authentication (MFA) enabled.
- [ ] **4. Install EPM Automate:** On your local Windows machine
- [ ] **5. Create password files:**
  ```cmd
  epmautomate encrypt "ProdPassword" "myKey" "C:\EPM_Scripts\passwords\prod_password.epw"
  epmautomate encrypt "DemoPassword" "myKey" "C:\EPM_Scripts\passwords\demo_password.epw"
  ```
- [ ] **5. Test connectivity:**
  ```cmd
  epmautomate login admin@company.com "C:\EPM_Scripts\passwords\prod_password.epw" "https://planning-myco.epm.us1.oraclecloud.com"
  epmautomate listFiles
  epmautomate logout
  
  epmautomate login admin@company.com "C:\EPM_Scripts\passwords\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com"
  epmautomate listFiles
  epmautomate logout
  ```
- [ ] **6. Notify users:** Inform all Demo/Test users that the environment will be unavailable
- [ ] **7. Check patch versions:** Ensure both environments are on the same monthly patch (for clone approach)
- [ ] **8. Verify maintenance not running:** On either environment

---

## APPROACH A: Clone Environment (Recommended — Fastest & Most Complete)

### Best For
- Full identical copy of Production in Demo
- When both environments are on the same patch version
- When you need Data Management staging data, audit data, job history

### Duration: 1–6 hours (depending on environment size)

---

### Step-by-Step

#### Step A1: Backup the Demo Environment

Before overwriting Demo, create a safety backup:

```cmd
REM Login to Demo
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com"

REM Force daily maintenance to create a fresh backup
epmautomate runDailyMaintenance -f

REM Wait for completion (15-30 minutes)...

REM Download the backup locally
epmautomate downloadFile "Artifact Snapshot"

REM Rename for safety
REM (In a separate CMD window or after logout)
epmautomate logout
```

Rename the downloaded file:
```cmd
rename "Artifact Snapshot.zip" "Demo_Backup_Before_Clone_%date:~10,4%-%date:~4,2%-%date:~7,2%.zip"
move "Demo_Backup_Before_Clone_*.zip" "C:\EPM_Scripts\snapshots\"
```

#### Step A2: Ensure Production Snapshot is Fresh

```cmd
REM Login to Production
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\prod_password.epw" "https://planning-myco.epm.us1.oraclecloud.com"

REM Force daily maintenance for fresh snapshot
epmautomate runDailyMaintenance -f

REM Wait for completion (15-30 minutes)...
REM The Artifact Snapshot is now current
```

#### Step A3: Execute the Clone

While still logged into Production:

```cmd
REM Full clone with users and roles
epmautomate cloneEnvironment admin@company.com "C:\EPM_Scripts\passwords\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com" UsersAndApplicationRoles=true DataManagement=false appAudit=false jobConsole=false storedSnapshotsAndFiles=false
```

> [!NOTE]
> **Optimization:** We set `DataManagement=false`, `appAudit=false`, `jobConsole=false` to speed things up. For a Demo environment, you typically don't need historical audit trails or DM staging data. Change these to `true` if you do need them.

Wait for the clone to complete. This can take **1–4 hours** for a typical environment.

#### Step A4: Logout from Production

```cmd
epmautomate logout
```

#### Step A5: Verify the Clone

```cmd
REM Login to Demo
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com"

REM List files to see the snapshot
epmautomate listFiles

REM Logout
epmautomate logout
```

Then sign in to the Demo EPM Cloud UI and verify:
- [ ] Application loads
- [ ] Dimensions and members are correct
- [ ] Data exists in forms
- [ ] Business rules execute
- [ ] Dashboards render
- [ ] Navigation flows work
- [ ] User access works

#### Step A6: Post-Clone Configuration

After cloning, update environment-specific settings in Demo:

1. **Data Management connections** — Update source/target URLs if they point to Prod
2. **EPM Automate scripts** — Update URLs in any automation scripts
3. **REST API integrations** — Update endpoint URLs
4. **Substitution variables** — Update any variables that should differ (e.g., `Env=DEMO`)
5. **Email notifications** — Disable or redirect to prevent Demo emails going to production users
6. **Cross-environment connections** — Update any inter-module links and integrated business processes.
7. **SSO and Bookmarks** — Update SSO configurations if on a new domain, and have users update bookmarks.
8. **Integration Agent & External IP Allow-lists** — Reconfigure the Integration Agent and update any external firewalls/proxies with the Demo environment's new IP/outbound IP address.

---

## APPROACH B: Snapshot Copy Method (No Local Download)

### Best For
- When you want more control over the import process
- When environments are on different patch versions (blackout period)
- When you don't need DM staging data or audit data

### Duration: 2–6 hours

---

### Step-by-Step

#### Step B1: Backup Demo (Same as Step A1 above)

*(Follow Step A1 from Approach A)*

#### Step B2: Ensure Production Snapshot is Fresh

```cmd
REM Login to Production
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\prod_password.epw" "https://planning-myco.epm.us1.oraclecloud.com"

REM Force daily maintenance
epmautomate runDailyMaintenance -f

REM Wait for completion...

REM Logout
epmautomate logout
```

#### Step B3: Recreate Demo (Clean Slate)

```cmd
REM Login to Demo
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com"

REM Recreate — wipe everything clean
epmautomate recreate -f
```

Wait for recreate to complete (5–30 minutes).

#### Step B4: Copy Snapshot from Production to Demo

While still logged into Demo:

```cmd
REM Copy the Artifact Snapshot directly from Prod
epmautomate copySnapshotFromInstance "Artifact Snapshot" admin@company.com "C:\EPM_Scripts\passwords\prod_password.epw" "https://planning-myco.epm.us1.oraclecloud.com"
```

Wait for the copy to complete.

#### Step B5: Verify the Snapshot Arrived

```cmd
epmautomate listFiles
REM Should show: Artifact Snapshot
```

#### Step B6: Import the Snapshot

```cmd
REM Import with users and set a default password for Demo
epmautomate importSnapshot "Artifact Snapshot" importUsers=true userPassword=DemoP@ss1 resetPassword=false
```

Wait for import to complete (30 min – 4 hours).

#### Step B7: Logout and Verify

```cmd
epmautomate logout
```

*(Follow same verification steps as Step A5 and A6 from Approach A)*

---

## APPROACH C: Manual Download & Upload (Full Offline Control)

### Best For
- When you want a local copy of the snapshot for archival
- When network between environments is unreliable
- When you need to modify the snapshot or transfer it offline

### Duration: 3–8 hours (includes download/upload time)

---

### Step-by-Step

#### Step C1: Backup Demo (Same as Step A1 above)

*(Follow Step A1 from Approach A)*

#### Step C2: Download Snapshot from Production

```cmd
REM Login to Production
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\prod_password.epw" "https://planning-myco.epm.us1.oraclecloud.com"

REM Force fresh snapshot
epmautomate runDailyMaintenance -f

REM Wait for completion...

REM Download
epmautomate downloadFile "Artifact Snapshot"

REM Logout
epmautomate logout
```

Rename and store:
```cmd
rename "Artifact Snapshot.zip" "Prod_Snapshot_%date:~10,4%-%date:~4,2%-%date:~7,2%.zip"
```

#### Step C3: Recreate Demo

```cmd
REM Login to Demo
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com"

REM Recreate
epmautomate recreate -f
```

Wait for completion.

#### Step C4: Upload Snapshot to Demo

```cmd
REM Upload the Production snapshot
epmautomate uploadFile "C:\EPM_Scripts\snapshots\Prod_Snapshot_2026-10-09.zip"
```

Wait for upload to complete (depends on file size and internet speed).

#### Step C5: Verify Upload

```cmd
epmautomate listFiles
REM Should show: Prod_Snapshot_2026-10-09
```

#### Step C6: Import

```cmd
epmautomate importSnapshot "Prod_Snapshot_2026-10-09" importUsers=true userPassword=DemoP@ss1 resetPassword=false
```

#### Step C7: Logout and Verify

```cmd
epmautomate logout
```

*(Follow same verification steps as Step A5 and A6 from Approach A)*

---

## Quick Comparison — All Three Approaches

| Step | Approach A (Clone) | Approach B (Copy+Import) | Approach C (Download+Upload) |
|------|-------------------|-------------------------|------------------------------|
| Backup Demo | ✅ | ✅ | ✅ |
| Fresh Prod snapshot | ✅ | ✅ | ✅ |
| Recreate Demo | Automatic | Manual | Manual |
| Transfer snapshot | Server-to-server (auto) | Server-to-server (manual) | Download → Upload |
| Import | Automatic | Manual | Manual |
| Local copy? | ❌ No | ❌ No | ✅ Yes |
| DM staging data? | ✅ Optional | ❌ No | ❌ No |
| Audit data? | ✅ Optional | ❌ No | ❌ No |
| Works during blackout? | ❌ No | ✅ Yes | ✅ Yes |
| Total commands | ~4 | ~6 | ~8 |
| Complexity | Low | Medium | High |
| Speed | Fastest | Medium | Slowest |

---

## FreeForm-Specific Considerations

If your Production is a **FreeForm** instance:

1. **Service type matching:** The Demo must be the same service type (FreeForm). If Demo is currently a different type, recreate with the appropriate service type first.

2. **No `TempServiceType` needed for FreeForm:** FreeForm uses the default service type (same as Planning). When you `recreate -f` without `TempServiceType`, it defaults to the Planning/FreeForm service type.

3. **Custom dimensions:** FreeForm apps have fully custom dimensions (no predefined Account, Period, etc.). The snapshot captures all custom dimension definitions perfectly.

4. **BSO/ASO cubes:** All cube types (BSO, ASO, Hybrid BSO) are included in the snapshot.

---

## Rollback Plan

If something goes wrong, you can restore Demo from the backup you took in Step 1:

```cmd
REM Login to Demo
epmautomate login admin@company.com "C:\EPM_Scripts\passwords\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com"

REM Recreate Demo clean
epmautomate recreate -f

REM Upload the backup you saved earlier
epmautomate uploadFile "C:\EPM_Scripts\snapshots\Demo_Backup_Before_Clone_2026-10-09.zip"

REM Import it
epmautomate importSnapshot "Demo_Backup_Before_Clone_2026-10-09" importUsers=true

REM Logout
epmautomate logout
```

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: How do you verify that the target Demo environment is completely safe to overwrite before cloning?
**Answer:**
1. Check the target environment URL to confirm you are connected to `test` or `demo`, **never** `prod`.
2. Take an on-demand baseline backup of Demo before starting:
   ```cmd
   epmautomate exportSnapshot "Demo_Backup_Before_Overwrite"
   epmautomate downloadFile "Demo_Backup_Before_Overwrite.zip"
   ```
3. Check Job Console to verify no users are currently running tests.

### Q2: What post-clone steps are mandatory before releasing Demo to testing teams?
**Answer:**
1. **Data Management URLs:** Re-point target connection URLs from Production to Demo endpoints.
2. **Substitution Variables:** Update `&CurYear` or environment tags to reflect test parameters.
3. **Email Notifications:** Disable automated email alerts in Application Settings to prevent test workflows from sending emails to corporate executives.

### Q3: How do you roll back Demo if the production clone encounters errors?
**Answer:** Recreate the instance clean and restore the baseline snapshot saved in Step 1:
```cmd
epmautomate recreate -f
epmautomate uploadFile "Demo_Backup_Before_Overwrite.zip"
epmautomate importSnapshot "Demo_Backup_Before_Overwrite" importUsers=true
```

---

## 🔗 Navigation

| Direction | Document | Focus Area |
|:---|:---|:---|
| **Next →** | [02_Enterprise_Automation_Scripts.md](./02_Enterprise_Automation_Scripts.md) | Enterprise PowerShell & Windows Batch unattended automation |
| **← Previous** | [02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md](../05_Migration_Reports_Auditing_and_OnPrem_Transition/02_On_Premises_Hyperion_to_Cloud_EPM_Migration.md) | Legacy Hyperion migration pathways & role mapping |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) | Return to Master Index |

