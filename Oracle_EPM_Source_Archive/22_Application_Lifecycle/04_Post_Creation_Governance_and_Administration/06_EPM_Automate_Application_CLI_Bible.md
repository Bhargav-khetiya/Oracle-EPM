# 🤖 EPM Automate Application Bible
## Command Reference, Syntax Dictionary & Enterprise Automation Runbooks

> **Tool:** EPM Automate CLI  
> **Applicability:** Oracle Fusion Cloud EPM (All Business Processes)  
> **Audience:** DevOps Engineers, EPM Service Administrators, Automation Architects  
> **Scope:** Full command catalog for application creation, instance recreation, snapshot migration, cube synchronization, and automated maintenance

---

## 🧭 Authentication & Session Management

Every automation script begins and ends with authenticated sessions:

```bash
# Encrypted password login (Recommended for CI/CD & unattended jobs)
# First generate encrypted password file: epmautomate encrypt "MyP@ssword" "my_key.epw"
epmautomate login "admin@company.com" "my_key.epw" "https://epm-target.oraclecloud.com" "epmeur"

# Plaintext login (Interactive shells only)
epmautomate login "admin@company.com" "Password123" "https://epm-target.oraclecloud.com" "epmeur"

# End session and purge local cached tokens
epmautomate logout
```

---

## ⚡ The Application Lifecycle Command Dictionary

### 1. `recreate` — Reset Environment to Factory Landing Page
Drops the existing application, purges relational schemas, and returns the service instance to the original Planning Landing Page.

```bash
# Syntax:
epmautomate recreate [-f]

# Example:
epmautomate recreate -f
```
- `-f` (Force): Suppresses the interactive confirmation prompt.
- **Result:** Application is deleted. The web interface displays the original 3 cards: `Create a sample application`, `Create a new application`, `Migrate`.

---

### 2. `importsnapshot` — Restore or Create Application from Snapshot
Creates a full application or updates artifacts from an LCM snapshot ZIP file residing on the service instance.

```bash
# Syntax:
epmautomate importsnapshot "SNAPSHOT_NAME" [importOptions="OPTIONS"]

# Example:
epmautomate importsnapshot "Production_Gold_Build.zip"
```

---

### 3. `copysnapshotfrominstance` — Cloud-to-Cloud Zero-Disk Transfer
Streams a snapshot directly from a source cloud instance into the current target instance without downloading gigabytes of data to local workstations.

```bash
# Syntax:
epmautomate copysnapshotfrominstance "SNAPSHOT_NAME" "SOURCE_URL" "SOURCE_USER" "PASSWORD_OR_KEY" "SOURCE_DOMAIN"

# Example:
epmautomate copysnapshotfrominstance "Prod_Nightly_Backup" "https://epm-prod.oraclecloud.com" "admin@company.com" "prod_key.epw" "epmprod"
```

---

### 4. `exportsnapshot` — Backup Application Artifacts
Generates a full or selective LCM snapshot of the active application.

```bash
# Syntax:
epmautomate exportsnapshot "SNAPSHOT_NAME"

# Example:
epmautomate exportsnapshot "Pre_Deployment_Backup_20261012"
```

---

### 5. `uploadfile` & `downloadfile` — Transfer Snapshots Across Firewalls

```bash
# Upload local ZIP archive to Cloud EPM staging repository
epmautomate uploadfile "D:\Backups\Planning_Release_v2.zip"

# Download Cloud snapshot to on-premises disaster recovery storage
epmautomate downloadfile "Artifact Snapshot.zip" "D:\Cold_Storage\"
```

---

### 6. `refreshcube` — Synchronize Essbase Outlines & Security

```bash
# Syntax:
epmautomate refreshcube [validateMetadata=true|false] [stopAllUsers=true|false]

# Example with user lockdown:
epmautomate refreshcube validateMetadata=true stopAllUsers=true
```

---

### 7. `clearcube` — Purge Data Blocks & Slices

```bash
# Full clear:
epmautomate clearcube "OEP_FS" clearMode="ALL"

# Targeted Point-of-View clear:
epmautomate clearcube "OEP_FS" clearMode="PARTIAL" pov="Scenario:Forecast,Years:FY26"
```

---

### 8. `mergeslices` & `compactoutline` — Cube Optimization

```bash
# Merge ASO incremental slices into main slice:
epmautomate mergeslices "OEP_REP" mergeType="ALL" purgeZeros=true

# Defragment Essbase outline:
epmautomate compactoutline "OEP_FS"
```

---

### 9. `setusermode` — Toggle Maintenance Mode

```bash
# Lock down application: Only Service Admins can log in
epmautomate setusermode "ADMIN"

# Unlock application: Restore access to all business users
epmautomate setusermode "ALL"
```

---

## 📜 Enterprise Production Automation Runbooks

### Runbook 1: Automated Production-to-Test Environment Clone (Nightly)

This PowerShell script runs automatically on a scheduled server to clone the Production instance into the Test instance every morning at 03:00 AM.

```powershell
<#
================================================================================
.SYNOPSIS
    Automated Production-to-Test Application Clone Pipeline
================================================================================
#>

$ErrorActionPreference = "Stop"

$PROD_URL    = "https://epm-prod.oraclecloud.com"
$PROD_USER   = "automation.admin@company.com"
$PROD_KEY    = "C:\EPM_Keys\prod_auth.epw"
$PROD_DOMAIN = "epmprod"

$TEST_URL    = "https://epm-test.oraclecloud.com"
$TEST_USER   = "automation.admin@company.com"
$TEST_KEY    = "C:\EPM_Keys\test_auth.epw"
$TEST_DOMAIN = "epmtest"

$SNAPSHOT_NAME = "Nightly_Clone_" + (Get-Date -Format "yyyyMMdd")

Write-Host ">>> [STEP 1] Authenticating against PRODUCTION..."
epmautomate login $PROD_USER $PROD_KEY $PROD_URL $PROD_DOMAIN

Write-Host ">>> [STEP 2] Exporting PRODUCTION Snapshot: $SNAPSHOT_NAME..."
epmautomate exportsnapshot $SNAPSHOT_NAME
epmautomate logout

Write-Host ">>> [STEP 3] Authenticating against TEST Environment..."
epmautomate login $TEST_USER $TEST_KEY $TEST_URL $TEST_DOMAIN

Write-Host ">>> [STEP 4] Locking TEST application (Maintenance Mode)..."
epmautomate setusermode "ADMIN"

Write-Host ">>> [STEP 5] Recreating TEST environment to clean slate..."
epmautomate recreate -f

Write-Host ">>> [STEP 6] Copying snapshot directly from PRODUCTION..."
epmautomate copysnapshotfrominstance $SNAPSHOT_NAME $PROD_URL $PROD_USER $PROD_KEY $PROD_DOMAIN

Write-Host ">>> [STEP 7] Importing snapshot into TEST environment..."
epmautomate importsnapshot "$SNAPSHOT_NAME.zip"

Write-Host ">>> [STEP 8] Performing Database Refresh on TEST..."
epmautomate refreshcube validateMetadata=true stopAllUsers=false

Write-Host ">>> [STEP 9] Unlocking TEST application for business users..."
epmautomate setusermode "ALL"

Write-Host ">>> [STEP 10] Signing out..."
epmautomate logout

Write-Host ">>> CLONE PIPELINE COMPLETED SUCCESSFULLY! <<<" -ForegroundColor Green
```

---

### Runbook 2: Automated Disaster Recovery & Snapshot Rollback

```bash
#!/bin/bash
set -e

# Target instance credentials
TARGET_URL="https://epm-sandbox.oraclecloud.com"
TARGET_USER="admin@company.com"
TARGET_KEY="/etc/epm/sandbox.epw"
TARGET_DOMAIN="epmsbx"
GOLD_SNAPSHOT="Baseline_Gold_Application.zip"

echo "=== INITIATING DISASTER ROLLBACK TO GOLD BUILD ==="

# 1. Login
epmautomate login "$TARGET_USER" "$TARGET_KEY" "$TARGET_URL" "$TARGET_DOMAIN"

# 2. Reset instance completely
epmautomate recreate -f

# 3. Import known gold baseline
epmautomate importsnapshot "$GOLD_SNAPSHOT"

# 4. Refresh databases
epmautomate refreshcube validateMetadata=true stopAllUsers=false

# 5. Logout
epmautomate logout

echo "=== ROLLBACK COMPLETE: ENVIRONMENT RESTORED TO GOLD BASELINE ==="
```

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What are the most critical application-level EPM Automate commands for daily DevOps pipelines?
**Answer:**
- `refreshCube`: Compiles metadata and security into Essbase.
- `importMetadata` / `exportMetadata`: Automates chart of accounts synchronization.
- `importData` / `exportData`: Automates nightly transactional data feeds.
- `clearcube`: Clears specific data slices prior to reload.
- `runBusinessRule`: Executes Calc Manager calculations and data maps.

### Q2: How do you trap errors in Windows Batch scripts when an EPM Automate command returns exit code 0 despite warnings?
**Answer:** Parse the console output log. EPM Automate may return exit code 0 if the API call succeeded, even if individual metadata records failed. Use PowerShell to check return code AND inspect log output for error strings:
```powershell
$log = & epmautomate refreshCube 2>&1
if ($LASTEXITCODE -ne 0 -or $log -match "Failed" -or $log -match "Error") {
    throw "Database refresh failed: $log"
}
```

### Q3: Can multiple EPM Automate CLI commands be chained together in a single pipeline?
**Answer:** Yes. Scripts can execute login â†’ clear data â†’ load data â†’ run business rules â†’ refresh cube â†’ export backup â†’ logout in a continuous pipeline, provided proper error checking is implemented after each step.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [05_Cube_and_Storage_Management.md](./05_Cube_and_Storage_Management.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |
