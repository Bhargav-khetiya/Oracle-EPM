# EPM Automate Complete Guide

> **Prerequisites:** [EPM Architecture](../00_Foundation/02_EPM_Architecture.md), [Data Integration](../06_Data_Integration_and_Exchange/01_Data_Integration_Overview.md)  
> **Sources merged:** ChatGPT EPM_Automate (6 files), Claude 14_EPM_Automate, Gemini EPM_Automate (6 files)  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## What Is EPM Automate?

**EPM Automate** is Oracle's official command-line interface (CLI) for automating repetitive administration, data integration, and maintenance tasks in Oracle EPM Cloud. Behind the scenes, it translates CLI commands into **HTTPS REST API calls (JSON over TLS 1.2/1.3 on port 443)** directed at the Oracle Cloud EPM service gateway.

```
┌──────────────────────────────────────────────────────────────────────┐
│ 1. CLI COMMAND:                                                      │
│    epmautomate runBusinessRule "FinPlan_01_Aggregation"               │
│                                                                      │
│ 2. CLIENT-SIDE REST TRANSLATION:                                     │
│    POST /HyperionPlanning/rest/v3/applications/FinPlan/jobs          │
│    Headers: Authorization: Bearer <token>                            │
│    Body: {"jobType":"RULES","jobName":"FinPlan_01_Aggregation"}      │
│                                                                      │
│ 3. ORACLE CLOUD GATEWAY:                                             │
│    Validates credentials via OCI IAM                                 │
│    Dispatches job to Planning Application Server                     │
│                                                                      │
│ 4. POLLING & RETURN:                                                 │
│    EPM Automate polls GET /jobs/<jobId> until completion             │
│    Returns: "The business rule completed successfully." (Exit = 0)   │
└──────────────────────────────────────────────────────────────────────┘
```

`[Oracle Documented]`

---

## Installation

### Supported Platforms
- **Windows:** 64-bit Windows Server 2016/2019/2022, Windows 10/11
- **Linux:** Oracle Linux, RHEL, SUSE, Ubuntu

### Installation Steps
1. Log into your EPM Cloud instance as a Service Administrator
2. Navigate to **Navigator → Tools → Download EPM Automate**
3. Run the installer:
   - **Windows:** Run `epmautomate-setup.exe` (default: `C:\Oracle\EPM Automate`)
   - **Linux:** Extract `epmautomate.tar` and execute `./install.sh`
4. Auto-upgrade to latest release:
   ```
   epmautomate upgrade
   ```

`[Oracle Documented]`

---

## Authentication

Oracle EPM Cloud prohibits plaintext passwords in batch scripts. Three authentication methods are available:

| Method | Security Level | Best For |
|:---|:---|:---|
| **Encrypted Password File (.epw)** | High | Standard scheduled batch scripts |
| **OAuth 2.0 Tokens (OCI IAM)** | Maximum (passwordless) | Cloud CI/CD pipelines, zero-trust |
| **API Keys** | High | Service account automation |

### Method 1: Encrypted Password File

```cmd
:: Generate encrypted password file
epmautomate encrypt MySecretP@ssword C:\Oracle\EPM_Automate\password.epw

:: With custom private key (prevents other users from decrypting)
epmautomate encrypt MySecretP@ssword C:\Keys\mykey.key C:\Oracle\EPM_Automate\password.epw
```

### Method 2: OAuth 2.0 Token

```cmd
epmautomate login <Client_ID> <Token_File> https://epm-test.oraclecloud.com
```

### SSO / MFA Bypass for Automation

When your organization enforces SSO with MFA (Okta, Azure AD, PingFederate), automated scripts cannot complete interactive challenges. **Solution:** Create a **Native Non-Federated Service Account** (e.g., `epm_svc_automation@company.com`) in OCI IAM with the Service Administrator role, authenticated via `.epw`.

`[Oracle Documented]`

---

## Essential Commands Reference

### Session Management

```cmd
:: Login
epmautomate login svc_admin@company.com C:\Keys\admin.epw https://epm.oraclecloud.com

:: Logout (always include at end of scripts)
epmautomate logout
```

### File Operations

| Command | Purpose | Example |
|:---|:---|:---|
| `uploadFile` | Upload file to EPM Inbox | `epmautomate uploadFile "GL_Data.csv"` |
| `downloadFile` | Download from EPM to local | `epmautomate downloadFile "export.zip" C:\Backups` |
| `deleteFile` | Delete file from EPM | `epmautomate deleteFile "old_data.csv"` |
| `listFiles` | List files on EPM server | `epmautomate listFiles` |

### Metadata Operations

| Command | Purpose |
|:---|:---|
| `importMetadata <job> [file]` | Ingest dimension members from CSV using a pre-configured import job |
| `exportMetadata <job> [file]` | Export outline hierarchies to CSV |
| `refreshCube [cube]` | **Critical** — compile relational metadata into Essbase outline (.OTL) |

> [!WARNING]
> `refreshCube` **locks the application**. Planners cannot save data while a refresh is in progress. Always execute during maintenance windows.

### Data Operations

| Command | Purpose |
|:---|:---|
| `importData <job> [file]` | Load data from a flat file |
| `exportData <job> [file]` | Export data to a file |
| `clearCube <job>` | Clear physical data blocks (All Data, Upper-Level, Dynamic Calc Cache) |
| `runDataRule <rule> <start> <end> <import> <export> [file]` | Execute Data Integration/Management rule |
| `runDataMap <map_name>` | Execute a Data Map (Smart Push between cubes) |

### Data Rule Syntax

```cmd
epmautomate runDataRule "Load_SAP_GL" "Oct-26" "Oct-26" "REPLACE" "STORE_DATA" "GL_Data.csv"
```

| Parameter | Options |
|:---|:---|
| **Import Mode** | `REPLACE` (wipe staging, reload), `APPEND` (add rows) |
| **Export Mode** | `STORE_DATA` (write to Essbase), `REPLACE_DATA` (clear target first) |

### Business Rules and Calculations

| Command | Purpose |
|:---|:---|
| `runBusinessRule <rule> [prompts]` | Execute a single Calc Manager / Essbase rule |
| `runRuleSet <ruleset> [prompts]` | Execute an ordered sequence of business rules |
| `runJob <type> <name> [params]` | Universal job executor |

#### Passing Runtime Prompts (RTP)

```cmd
:: Single-member prompts
epmautomate runBusinessRule "Revenue_Calc" "Entity=E10002" "Scenario=Budget" "Years=FY26"

:: Multi-member prompts (escaped quotes)
epmautomate runBusinessRule "Aggregate_Full" "Entity=\"E10001\",\"E10002\"" "Years=FY26"

:: Executing a rule set
epmautomate runRuleSet "Nightly_Calc_RuleSet" "Scenario=Budget" "Version=Working"
```

#### Universal Job Types (`runJob`)

| Job Type | Purpose |
|:---|:---|
| `RULES` | Single business rule |
| `RULESET` | Rule set |
| `CUBE_REFRESH` | Essbase database refresh |
| `CLEAR_CUBE` | Physical data clear |
| `IMPORT_DATA` / `EXPORT_DATA` | Data file operations |
| `IMPORT_METADATA` / `EXPORT_METADATA` | Hierarchy builds |

### Snapshot and Backup Operations

| Command | Purpose |
|:---|:---|
| `exportSnapshot <name>` | Create an on-demand application snapshot |
| `importSnapshot <name>` | Restore from a snapshot |
| `copySnapshotFromInstance` | Copy snapshot from another EPM environment |

### Security and Governance

```cmd
:: Export user directory with roles to CSV
epmautomate exportUsers "Active_Users_Audit.csv"

:: Generate dimension-level access control report
epmautomate userAccessReport "Security_Report.csv"

:: Generate audit trail of logins and data modifications
epmautomate userAuditReport "2026-10-01" "2026-10-31" "Audit_Oct2026.csv"

:: Assign role to a user
epmautomate assignRole "jsmith@company.com" "Planner"
```

`[Oracle Documented]`

---

## Return Codes

EPM Automate signals success or failure via the OS process exit code:
- **`0`:** Command completed successfully
- **`1`:** Command failed with an error

### PowerShell Error Checking

```powershell
epmautomate login svc_admin password.epw https://epm.oraclecloud.com
if ($LASTEXITCODE -ne 0) {
    Write-Error "EPM Automate Login Failed with exit code $LASTEXITCODE"
    exit 1
}
```

### Bash Error Checking

```bash
epmautomate login svc_admin password.epw https://epm.oraclecloud.com
if [ $? -ne 0 ]; then
    echo "EPM Automate Login Failed"
    exit 1
fi
```

---

## Production Nightly Automation Script

A complete enterprise-ready PowerShell script with error handling, logging, and guaranteed session cleanup:

```powershell
<#
SCRIPT:  EPM_Nightly_Orchestration.ps1
PURPOSE: Automated Backup, Metadata Build, Data Load, Calc, and Smart Push
#>

[CmdletBinding()]
param (
    [string]$Url         = "https://epm-prod.oraclecloud.com",
    [string]$User        = "epm_svc_automation@company.com",
    [string]$PasswordEpw = "C:\Oracle\EPM_Automate\Keys\prod.epw",
    [string]$LogDir      = "C:\Oracle\EPM_Automate\Logs"
)

$DateStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile   = Join-Path $LogDir "EPM_Run_$DateStamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Formatted = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Host $Formatted
    Add-Content -Path $LogFile -Value $Formatted
}

function Execute-Epm {
    param([string]$Command, [string]$Arguments)
    Write-Log "Executing: epmautomate $Command $Arguments"
    $Output = & epmautomate $Command $Arguments 2>&1
    foreach ($line in $Output) { Write-Log "  OUTPUT: $line" }
    if ($LASTEXITCODE -ne 0) {
        Write-Log "FAILED with Exit Code: $LASTEXITCODE" "ERROR"
        throw "EPM Automate failure in command '$Command'."
    }
    Write-Log "Command completed successfully."
}

try {
    Write-Log "======== STARTING EPM NIGHTLY RUN ========"

    # 1. Login
    Execute-Epm "login" "$User $PasswordEpw $Url"

    # 2. Create backup snapshot
    Execute-Epm "exportSnapshot" "Nightly_Backup_$DateStamp"

    # 3. Upload data file
    Execute-Epm "uploadFile" "C:\Inbound\GL_Actuals_Latest.csv"

    # 4. Run Data Integration rule
    Execute-Epm "runDataRule" "Load_GL Oct-26 Oct-26 REPLACE STORE_DATA GL_Actuals_Latest.csv"

    # 5. Refresh cube (compile metadata)
    Execute-Epm "refreshCube" ""

    # 6. Run aggregation business rule
    Execute-Epm "runBusinessRule" "FinPlan_Aggregation Scenario=Actual Years=FY26"

    # 7. Smart Push to reporting cube
    Execute-Epm "runDataMap" "FinPlan_to_Reporting_Map"

    Write-Log "======== NIGHTLY RUN COMPLETED SUCCESSFULLY ========"
}
catch {
    Write-Log "FATAL ERROR: $_" "FATAL"
    # Send-MailMessage -To "epm_admins@company.com" -Subject "EPM JOB FAILED" ...
    exit 1
}
finally {
    Write-Log "Executing session cleanup (logout)..."
    & epmautomate logout | Out-Null
    Write-Log "Session terminated."
}
```

`[Illustrative]` — Adapt URLs, credentials, rule names, and file paths to your environment.

### Scheduling with Windows Task Scheduler

1. Open Task Scheduler (`taskschd.msc`)
2. Create Basic Task → Name: `"EPM_Nightly_ETL"`
3. Trigger: **Daily at 01:00 AM**
4. Action: Start a program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\Oracle\EPM_Automate\EPM_Nightly_Orchestration.ps1"`
5. Security: "Run whether user is logged on or not" + "Run with highest privileges"

### Linux Crontab

```bash
# Run EPM nightly pipeline at 1:00 AM
0 1 * * * /opt/epmautomate/scripts/epm_nightly_run.sh >> /var/log/epm/cron.log 2>&1
```

---

## Nightly Automation Sequence Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                    NIGHTLY AUTOMATION SEQUENCE                      │
├────────────────────────────────────────────────────────────────────┤
│ 1. Login to EPM Cloud                                              │
│ 2. Export backup snapshot                                          │
│ 3. Upload data files (GL actuals, metadata deltas)                 │
│ 4. Import metadata (new accounts, cost centers, employees)         │
│ 5. Refresh cube (compile .OTL outline)                             │
│ 6. Run Data Integration rules (GL load with member mappings)       │
│ 7. Run business rules (aggregation, allocation, currency calc)     │
│ 8. Run Data Maps / Smart Push (BSO → ASO reporting)                │
│ 9. Export reports / audit files                                    │
│ 10. Logout                                                         │
└────────────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "Invalid credentials" on login | Password changed or .epw out of date | Regenerate .epw with `epmautomate encrypt` |
| "Cannot connect" | Proxy not configured or URL wrong | Set `HTTP_PROXY`/`HTTPS_PROXY` env vars; verify URL |
| SSO redirect prevents login | Using federated account | Create a native non-federated service account |
| `refreshCube` hangs | Another user has a lock | Check active sessions; schedule during maintenance window |
| Business rule fails with "member not found" | Metadata not refreshed after dimension import | Run `refreshCube` before `runBusinessRule` |
| Data rule returns partial load | Mapping errors in Data Integration | Check Workbench validation errors; fix member mappings |
| Exit code 1 but no clear error | Server-side timeout | Check Job Console in EPM UI for detailed error logs |

---

## Quick Recall

1. **What is EPM Automate under the hood?**
   → A CLI wrapper that translates commands into HTTPS REST API calls to the EPM Cloud gateway.

2. **Why do you need a non-federated service account?**
   → Because automated scripts cannot complete interactive SSO/MFA challenges. A native account authenticates directly via encrypted password.

3. **What is the correct order: data load or refreshCube?**
   → Import metadata → refreshCube → load data → run business rules. Metadata must be compiled into the outline before data can target new members.

4. **Why always include `logout` in scripts?**
   → To release the server session token. Abandoned sessions consume server resources and can count against concurrent session limits.

---

**See also:**
- [Data Integration Overview](../06_Data_Integration_and_Exchange/01_Data_Integration_Overview.md) — the ETL framework that EPM Automate commands invoke
- [Calc Manager Overview](../05_Calc_Manager_and_Business_Rules/01_Calc_Manager_Overview.md) — the business rules executed by `runBusinessRule`

