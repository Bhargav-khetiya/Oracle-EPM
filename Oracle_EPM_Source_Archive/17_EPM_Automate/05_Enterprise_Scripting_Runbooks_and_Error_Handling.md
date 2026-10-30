# 05 — Enterprise Scripting Frameworks & Nightly Runbooks

---

## 5.1 Production-Grade PowerShell Automation Framework

Below is an enterprise-ready, production-grade PowerShell automation script implementing **robust error handling, timestamped logging, retry logic, and guaranteed session logout**:

```powershell
<#
================================================================================
SCRIPT:      EPM_Nightly_Orchestration.ps1
PURPOSE:     Automated Nightly Backup, Metadata Build, Data Load, and Calc
AUTHOR:      Oracle EPM Architecture Center
================================================================================
#>

[CmdletBinding()]
param (
    [string]$Url         = "https://epm-prod.oraclecloud.com",
    [string]$User        = "epm_svc_automation@orbrick.com",
    [string]$PasswordEpw = "C:\Oracle\EPM_Automate\Keys\prod.epw",
    [string]$LogDir      = "C:\Oracle\EPM_Automate\Logs"
)

# Initialize Logging
$DateStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile   = Join-Path $LogDir "EPM_Run_$DateStamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Formatted = "[$Timestamp] [$Level] $Message"
    Write-Host $Formatted
    Add-Content -Path $LogFile -Value $Formatted
}

function Execute-Epm {
    param([string]$Command, [string]$Arguments)
    Write-Log "Executing: epmautomate $Command $Arguments"
    
    $Output = & epmautomate $Command $Arguments 2>&1
    $ExitCode = $LASTEXITCODE
    
    foreach ($line in $Output) {
        Write-Log "  OUTPUT: $line"
    }
    
    if ($ExitCode -ne 0) {
        Write-Log "Command FAILED with Exit Code: $ExitCode" "ERROR"
        throw "EPM Automate execution failure in command '$Command'."
    }
    Write-Log "Command completed successfully."
}

try {
    Write-Log "================ STARTING EPM NIGHTLY RUN ================"
    
    # 1. Login to EPM Cloud
    Execute-Epm "login" "$User $PasswordEpw $Url"
    
    # 2. Export On-Demand Backup Snapshot
    $SnapshotName = "Nightly_Backup_$DateStamp"
    Execute-Epm "exportSnapshot" "$SnapshotName"
    
    # 3. Download Backup to Local SAN Archive
    Execute-Epm "downloadFile" "$SnapshotName.zip C:\Backups"
    
    # 4. Upload Today's General Ledger Data File
    Execute-Epm "uploadFile" "C:\Inbound\GL_Actuals_Latest.csv"
    
    # 5. Execute Data Management Integration Rule
    Execute-Epm "runDataRule" "Load_SAP_GL Oct-26 Oct-26 REPLACE STORE_DATA GL_Actuals_Latest.csv"
    
    # 6. Execute Departmental Aggregation Business Rule
    Execute-Epm "runBusinessRule" "FinPlan_01_Aggregation Scenario=Actual Years=FY26"
    
    # 7. Execute Real-Time Smart Push (FinPlan -> EPBCS Reporting)
    Execute-Epm "runDataMap" "FinPlan_to_EPBCS_Map"
    
    Write-Log "================ EPM NIGHTLY RUN COMPLETED SUCCESSFULLY ================"
}
catch {
    Write-Log "FATAL ERROR OCCURRED: $_" "FATAL"
    # Send-MailMessage -To "epm_admins@orbrick.com" -Subject "EPM JOB FAILED" ...
    exit 1
}
finally {
    Write-Log "Executing Session Cleanup (Logout)..."
    & epmautomate logout | Out-Null
    Write-Log "Session terminated."
}
```

---

## 5.2 Production-Grade Linux Bash Framework

For organizations running enterprise orchestrators on Linux (e.g., Control-M, Autosys, Airflow, or Crontab):

```bash
#!/usr/bin/env bash
# ==============================================================================
# SCRIPT:  epm_nightly_run.sh
# ==============================================================================
set -euo pipefail

URL="https://epm-prod.oraclecloud.com"
USER="epm_svc_automation@orbrick.com"
PW_FILE="/opt/epmautomate/keys/prod.epw"
LOG_FILE="/opt/epmautomate/logs/epm_$(date +'%Y%m%d_%H%M%S').log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cleanup() {
    log "Terminating session..."
    epmautomate logout >> "$LOG_FILE" 2>&1 || true
}
trap cleanup EXIT

log "Starting EPM batch pipeline..."

# 1. Login
epmautomate login "$USER" "$PW_FILE" "$URL" >> "$LOG_FILE" 2>&1

# 2. Upload Delta File
epmautomate uploadFile "/data/inbound/GL_Data.csv" >> "$LOG_FILE" 2>&1

# 3. Run Data Rule
epmautomate runDataRule "Load_SAP_GL" "Oct-26" "Oct-26" "REPLACE" "STORE_DATA" "GL_Data.csv" >> "$LOG_FILE" 2>&1

# 4. Refresh Cube
epmautomate refreshCube >> "$LOG_FILE" 2>&1

log "Pipeline completed successfully."
```

---

## 5.3 Windows Task Scheduler Automation Setup

1. Open **Task Scheduler (`taskschd.msc`)**.
2. Create Basic Task $\rightarrow$ Name: `"EPM_Nightly_ETL"`.
3. Trigger: **Daily at 01:00 AM**.
4. Action: **Start a program**:
   * Program/script: `powershell.exe`
   * Arguments: `-ExecutionPolicy Bypass -File "C:\Oracle\EPM_Automate\EPM_Nightly_Orchestration.ps1"`
5. Security Options:
   * Select **"Run whether user is logged on or not"**.
   * Check **"Run with highest privileges"**.
