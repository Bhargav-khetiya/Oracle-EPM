﻿# Oracle EPM Cloud: Automation Scripts

## 1. Overview

These ready-to-use scripts automate the most common EPM Cloud migration and backup tasks. Customize the variables at the top of each script for your environment.

---

## 2. Configuration Variables

Before using any script, update these variables:

```batch
REM =====================================================
REM  ENVIRONMENT CONFIGURATION — UPDATE THESE VALUES
REM =====================================================
SET EPM_USER=admin@company.com

SET PROD_PASS=C:\EPM_Scripts\passwords\prod_password.epw
SET PROD_URL=https://planning-myco.epm.us1.oraclecloud.com

SET DEMO_PASS=C:\EPM_Scripts\passwords\demo_password.epw
SET DEMO_URL=https://planning-test-myco.epm.us1.oraclecloud.com

SET SNAPSHOT_DIR=C:\EPM_Scripts\snapshots
SET LOG_DIR=C:\EPM_Scripts\logs
SET DATE_STAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%
SET TIME_STAMP=%time:~0,2%-%time:~3,2%-%time:~6,2%
```

---

## 3. Script A: Daily Automated Backup Download

**Purpose:** Automatically download the Artifact Snapshot from Production every day for archival.

**Schedule:** Via Windows Task Scheduler, run at 3:00 AM daily (after daily maintenance at 2:00 AM).

```batch
@echo off
REM =====================================================
REM  SCRIPT: Daily Automated Backup Download
REM  PURPOSE: Download Prod Artifact Snapshot daily
REM  SCHEDULE: 3:00 AM via Windows Task Scheduler
REM =====================================================

SET EPM_USER=admin@company.com
SET PROD_PASS=C:\EPM_Scripts\passwords\prod_password.epw
SET PROD_URL=https://planning-myco.epm.us1.oraclecloud.com
SET SNAPSHOT_DIR=C:\EPM_Scripts\snapshots
SET LOG_DIR=C:\EPM_Scripts\logs
SET DATE_STAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%
SET LOG_FILE=%LOG_DIR%\daily_backup_%DATE_STAMP%.log

echo ===== Daily Backup Started: %date% %time% ===== >> %LOG_FILE%

REM Step 1: Login
echo [%time%] Logging in to Production... >> %LOG_FILE%
call epmautomate login %EPM_USER% %PROD_PASS% %PROD_URL% >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Login failed! >> %LOG_FILE%
    goto :ERROR
)

REM Step 2: Download Artifact Snapshot
echo [%time%] Downloading Artifact Snapshot... >> %LOG_FILE%
cd /d %SNAPSHOT_DIR%
call epmautomate downloadFile "Artifact Snapshot" >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Download failed! >> %LOG_FILE%
    call epmautomate logout >> %LOG_FILE% 2>&1
    goto :ERROR
)

REM Step 3: Rename with date stamp
echo [%time%] Renaming snapshot... >> %LOG_FILE%
rename "Artifact Snapshot.zip" "Prod_Snapshot_%DATE_STAMP%.zip" >> %LOG_FILE% 2>&1

REM Step 4: Logout
echo [%time%] Logging out... >> %LOG_FILE%
call epmautomate logout >> %LOG_FILE% 2>&1

REM Step 5: Cleanup old snapshots (keep last 30 days)
echo [%time%] Cleaning up snapshots older than 30 days... >> %LOG_FILE%
forfiles /p %SNAPSHOT_DIR% /m "Prod_Snapshot_*.zip" /d -30 /c "cmd /c del @path" 2>> %LOG_FILE%

echo ===== Daily Backup Completed Successfully: %date% %time% ===== >> %LOG_FILE%
goto :END

:ERROR
echo ===== BACKUP FAILED: %date% %time% ===== >> %LOG_FILE%
REM Add email notification here if desired

:END
```

---

## 4. Script B: Clone Production to Demo

**Purpose:** Full clone of Production to Demo/Test environment.

**When to run:** Before starting a new project phase, or weekly refresh.

```batch
@echo off
REM =====================================================
REM  SCRIPT: Clone Production to Demo
REM  PURPOSE: Full environment replication
REM  CAUTION: This OVERWRITES the Demo environment!
REM =====================================================

SET EPM_USER=admin@company.com
SET PROD_PASS=C:\EPM_Scripts\passwords\prod_password.epw
SET PROD_URL=https://planning-myco.epm.us1.oraclecloud.com
SET DEMO_PASS=C:\EPM_Scripts\passwords\demo_password.epw
SET DEMO_URL=https://planning-test-myco.epm.us1.oraclecloud.com
SET SNAPSHOT_DIR=C:\EPM_Scripts\snapshots
SET LOG_DIR=C:\EPM_Scripts\logs
SET DATE_STAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%
SET LOG_FILE=%LOG_DIR%\clone_prod_to_demo_%DATE_STAMP%.log

echo ===== Clone Started: %date% %time% ===== >> %LOG_FILE%

REM =============================================
REM  PHASE 1: Backup Demo before overwriting
REM =============================================
echo [%time%] PHASE 1: Backing up Demo environment... >> %LOG_FILE%
call epmautomate login %EPM_USER% %DEMO_PASS% %DEMO_URL% >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Cannot login to Demo! >> %LOG_FILE%
    goto :ERROR
)

echo [%time%] Running daily maintenance on Demo... >> %LOG_FILE%
call epmautomate runDailyMaintenance -f >> %LOG_FILE% 2>&1

echo [%time%] Downloading Demo backup... >> %LOG_FILE%
cd /d %SNAPSHOT_DIR%
call epmautomate downloadFile "Artifact Snapshot" >> %LOG_FILE% 2>&1
rename "Artifact Snapshot.zip" "Demo_Backup_%DATE_STAMP%.zip" >> %LOG_FILE% 2>&1

call epmautomate logout >> %LOG_FILE% 2>&1
echo [%time%] Demo backup complete. >> %LOG_FILE%

REM =============================================
REM  PHASE 2: Refresh Prod snapshot
REM =============================================
echo [%time%] PHASE 2: Refreshing Production snapshot... >> %LOG_FILE%
call epmautomate login %EPM_USER% %PROD_PASS% %PROD_URL% >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Cannot login to Production! >> %LOG_FILE%
    goto :ERROR
)

echo [%time%] Running daily maintenance on Prod... >> %LOG_FILE%
call epmautomate runDailyMaintenance -f >> %LOG_FILE% 2>&1

REM =============================================
REM  PHASE 3: Clone Prod → Demo
REM =============================================
echo [%time%] PHASE 3: Cloning Production to Demo... >> %LOG_FILE%
call epmautomate cloneEnvironment %EPM_USER% %DEMO_PASS% %DEMO_URL% UsersAndApplicationRoles=true DataManagement=false appAudit=false jobConsole=false storedSnapshotsAndFiles=false >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Clone failed! >> %LOG_FILE%
    call epmautomate logout >> %LOG_FILE% 2>&1
    goto :ERROR
)

call epmautomate logout >> %LOG_FILE% 2>&1

echo ===== Clone Completed Successfully: %date% %time% ===== >> %LOG_FILE%
goto :END

:ERROR
echo ===== CLONE FAILED: %date% %time% ===== >> %LOG_FILE%

:END
```

---

## 5. Script C: Recreate + Snapshot Copy + Import (No Clone)

**Purpose:** Alternative to cloning — useful during blackout periods or when you want more control.

```batch
@echo off
REM =====================================================
REM  SCRIPT: Recreate Demo + Copy Snapshot + Import
REM  PURPOSE: Alternative migration (works during blackout)
REM =====================================================

SET EPM_USER=admin@company.com
SET PROD_PASS=C:\EPM_Scripts\passwords\prod_password.epw
SET PROD_URL=https://planning-myco.epm.us1.oraclecloud.com
SET DEMO_PASS=C:\EPM_Scripts\passwords\demo_password.epw
SET DEMO_URL=https://planning-test-myco.epm.us1.oraclecloud.com
SET LOG_DIR=C:\EPM_Scripts\logs
SET DATE_STAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%
SET LOG_FILE=%LOG_DIR%\recreate_import_%DATE_STAMP%.log
SET DEMO_PASSWORD=DemoP@ss1

echo ===== Migration Started: %date% %time% ===== >> %LOG_FILE%

REM =============================================
REM  PHASE 1: Ensure fresh Prod snapshot
REM =============================================
echo [%time%] PHASE 1: Refreshing Production snapshot... >> %LOG_FILE%
call epmautomate login %EPM_USER% %PROD_PASS% %PROD_URL% >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Cannot login to Production! >> %LOG_FILE%
    goto :ERROR
)
call epmautomate runDailyMaintenance -f >> %LOG_FILE% 2>&1
call epmautomate logout >> %LOG_FILE% 2>&1

REM =============================================
REM  PHASE 2: Recreate Demo
REM =============================================
echo [%time%] PHASE 2: Recreating Demo environment... >> %LOG_FILE%
call epmautomate login %EPM_USER% %DEMO_PASS% %DEMO_URL% >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Cannot login to Demo! >> %LOG_FILE%
    goto :ERROR
)

call epmautomate recreate -f >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Recreate failed! >> %LOG_FILE%
    call epmautomate logout >> %LOG_FILE% 2>&1
    goto :ERROR
)

REM =============================================
REM  PHASE 3: Copy snapshot from Prod
REM =============================================
echo [%time%] PHASE 3: Copying snapshot from Production... >> %LOG_FILE%
call epmautomate copySnapshotFromInstance "Artifact Snapshot" %EPM_USER% %PROD_PASS% %PROD_URL% >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Snapshot copy failed! >> %LOG_FILE%
    call epmautomate logout >> %LOG_FILE% 2>&1
    goto :ERROR
)

REM =============================================
REM  PHASE 4: Import snapshot
REM =============================================
echo [%time%] PHASE 4: Importing snapshot... >> %LOG_FILE%
call epmautomate importSnapshot "Artifact Snapshot" importUsers=true userPassword=%DEMO_PASSWORD% resetPassword=false >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Import failed! >> %LOG_FILE%
    call epmautomate logout >> %LOG_FILE% 2>&1
    goto :ERROR
)

call epmautomate logout >> %LOG_FILE% 2>&1

echo ===== Migration Completed Successfully: %date% %time% ===== >> %LOG_FILE%
goto :END

:ERROR
echo ===== MIGRATION FAILED: %date% %time% ===== >> %LOG_FILE%

:END
```

---

## 6. Script D: Restore from a Specific Date

**Purpose:** Restore an environment from a specific date's backup in Object Storage.

```batch
@echo off
REM =====================================================
REM  SCRIPT: Restore from Specific Date
REM  PURPOSE: Point-in-time restore from archived backup
REM  USAGE: restore_from_date.bat 2026-10-05T02:00:00
REM =====================================================

SET EPM_USER=admin@company.com
SET EPM_PASS=C:\EPM_Scripts\passwords\prod_password.epw
SET EPM_URL=https://planning-myco.epm.us1.oraclecloud.com
SET LOG_DIR=C:\EPM_Scripts\logs
SET BACKUP_DATE=%1

IF "%BACKUP_DATE%"=="" (
    echo Usage: restore_from_date.bat YYYY-MM-DDTHH:MM:SS
    echo Example: restore_from_date.bat 2026-10-05T02:00:00
    exit /b 1
)

SET LOG_FILE=%LOG_DIR%\restore_%BACKUP_DATE%.log

echo ===== Restore Started: %date% %time% ===== >> %LOG_FILE%
echo Target Backup: %BACKUP_DATE% >> %LOG_FILE%

REM Login
call epmautomate login %EPM_USER% %EPM_PASS% %EPM_URL% >> %LOG_FILE% 2>&1

REM List available backups (verify our target exists)
echo [%time%] Listing available backups... >> %LOG_FILE%
call epmautomate listBackups >> %LOG_FILE% 2>&1

REM Restore the specific Artifact Snapshot
echo [%time%] Restoring backup %BACKUP_DATE%/Artifact_Snapshot.zip... >> %LOG_FILE%
call epmautomate restoreBackup "%BACKUP_DATE%/Artifact_Snapshot.zip" targetName=Restored_%BACKUP_DATE% >> %LOG_FILE% 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] ERROR: Restore failed! >> %LOG_FILE%
    call epmautomate logout >> %LOG_FILE% 2>&1
    goto :ERROR
)

REM Verify the restored file
call epmautomate listFiles >> %LOG_FILE% 2>&1

REM Import the restored snapshot
echo [%time%] Importing restored snapshot... >> %LOG_FILE%
call epmautomate importSnapshot "Restored_%BACKUP_DATE%" >> %LOG_FILE% 2>&1

call epmautomate logout >> %LOG_FILE% 2>&1

echo ===== Restore Completed Successfully: %date% %time% ===== >> %LOG_FILE%
goto :END

:ERROR
echo ===== RESTORE FAILED: %date% %time% ===== >> %LOG_FILE%

:END
```

---

## 7. PowerShell Alternative — Clone with Email Notification

For more advanced automation with error handling and email notifications:

```powershell
# =====================================================
#  SCRIPT: Clone Production to Demo (PowerShell)
#  PURPOSE: Full clone with email notification
# =====================================================

$EPM_USER = "admin@company.com"
$PROD_PASS = "C:\EPM_Scripts\passwords\prod_password.epw"
$PROD_URL = "https://planning-myco.epm.us1.oraclecloud.com"
$DEMO_PASS = "C:\EPM_Scripts\passwords\demo_password.epw"
$DEMO_URL = "https://planning-test-myco.epm.us1.oraclecloud.com"
$LOG_FILE = "C:\EPM_Scripts\logs\clone_$(Get-Date -Format 'yyyy-MM-dd').log"

# Email settings
$SMTP_SERVER = "smtp.company.com"
$EMAIL_FROM = "epm-automation@company.com"
$EMAIL_TO = "epm-admin@company.com"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -Append -FilePath $LOG_FILE
    Write-Host "$timestamp - $Message"
}

function Run-EPMCommand {
    param([string]$Command)
    Write-Log "Executing: epmautomate $Command"
    $result = & epmautomate $Command.Split(" ") 2>&1
    $exitCode = $LASTEXITCODE
    $result | Out-File -Append -FilePath $LOG_FILE
    if ($exitCode -ne 0) {
        throw "EPM Command failed: epmautomate $Command (Exit code: $exitCode)"
    }
    return $result
}

try {
    Write-Log "===== CLONE STARTED ====="

    # Phase 1: Login to Production
    Write-Log "Phase 1: Logging in to Production..."
    Run-EPMCommand "login $EPM_USER $PROD_PASS $PROD_URL"

    # Phase 2: Refresh snapshot
    Write-Log "Phase 2: Running daily maintenance..."
    Run-EPMCommand "runDailyMaintenance -f"

    # Phase 3: Clone
    Write-Log "Phase 3: Cloning to Demo..."
    Run-EPMCommand "cloneEnvironment $EPM_USER $DEMO_PASS $DEMO_URL UsersAndApplicationRoles=true"

    # Phase 4: Logout
    Run-EPMCommand "logout"

    Write-Log "===== CLONE COMPLETED SUCCESSFULLY ====="

    # Send success email
    Send-MailMessage -From $EMAIL_FROM -To $EMAIL_TO -Subject "EPM Clone SUCCESS - $(Get-Date -Format 'yyyy-MM-dd')" -Body "Production has been successfully cloned to Demo." -SmtpServer $SMTP_SERVER

} catch {
    Write-Log "ERROR: $_"
    & epmautomate logout 2>&1 | Out-Null

    # Send failure email
    Send-MailMessage -From $EMAIL_FROM -To $EMAIL_TO -Subject "EPM Clone FAILED - $(Get-Date -Format 'yyyy-MM-dd')" -Body "Clone failed. Error: $_`n`nSee log: $LOG_FILE" -SmtpServer $SMTP_SERVER
}
```

---

## 8. Setting Up Windows Task Scheduler

To automate the daily backup script:

1. Open **Task Scheduler** (Win + R → `taskschd.msc`)
2. Click **Create Task** (not "Create Basic Task")
3. **General tab:**
   - Name: `EPM Daily Backup`
   - Run whether user is logged on or not: ✅
   - Run with highest privileges: ✅
4. **Triggers tab:**
   - New → Daily → Start at 3:00 AM
5. **Actions tab:**
   - New → Start a program
   - Program: `C:\EPM_Scripts\scripts\daily_backup.bat`
   - Start in: `C:\EPM_Scripts\scripts`
6. **Settings tab:**
   - Allow task to be run on demand: ✅
   - Stop task if runs longer than 2 hours: ✅
7. Click **OK** and enter your Windows credentials

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Why should enterprise automation scripts use PowerShell with try/catch rather than legacy Windows Batch (`.bat`)—
**Answer:** Legacy Windows Batch scripts have primitive error handling. Batch commands often fail silently, `%ERRORLEVEL%` can be overwritten by intermediate commands, and batch lacks native JSON parsing, structured logging, and email alerting. PowerShell provides robust structured exceptions (`try/catch/finally`), regex parsing of EPM Automate logs, native SMTP alerting, and secure credential vaults.

### Q2: How do you implement automated email failure notifications in unattended EPM Automate scripts—
**Answer:** Use PowerShell's `Send-MailMessage` cmdlet inside the `catch` block:
```powershell
try {
    # Run EPM Automate command
    $output = & epmautomate refreshCube 2>&1
    if ($LASTEXITCODE -ne 0) { throw $output }
} catch {
    Send-MailMessage -From "alerts@company.com" -To "epm-oncall@company.com" `
        -Subject "CRITICAL: EPM Automation Failed" -Body "$_" -SmtpServer "smtp.company.com"
    exit 1
}
```

### Q3: How do you configure PowerShell scripts to execute unattended under Windows Task Scheduler—
**Answer:** In Task Scheduler:
1. General Tab: Check **"Run whether user is logged on or not"** and **"Run with highest privileges"**.
2. Actions Tab: Action: **Start a program**.
   - Program/script: `powershell.exe`
   - Add arguments: `-NoProfile -ExecutionPolicy Bypass -File "C:\EPM_Scripts\scripts\nightly_pipeline.ps1"`
   - Start in: `C:\EPM_Scripts\scripts`

---

## 🔗 Navigation

| Direction | Document | Focus Area |
|:---|:---|:---|
| **Next →** | [03_Master_Troubleshooting_FAQ_and_Gotchas.md](./03_Master_Troubleshooting_FAQ_and_Gotchas.md) | Master error codes catalog & troubleshooting FAQ |
| **← Previous** | [01_Prod_to_Demo_Complete_Runbook.md](./01_Prod_to_Demo_Complete_Runbook.md) | Prod-to-Demo end-to-end execution runbook |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) | Return to Master Index |

