# REST API Integration — Complete Guide

> **Section:** 04 — REST API  
> **File:** 01 — REST API Guide  
> **Difficulty:** Intermediate → Architect  
> **Prerequisites:** [01_What_Is_EPM](../00_Foundation/01_What_Is_EPM.md), basic HTTP/JSON knowledge

---

## What Is the EPM Cloud REST API?

The Oracle EPM Cloud REST API lets external systems and scripts **programmatically interact** with your EPM environment. Instead of clicking through the web interface, you send HTTP requests to run rules, load data, manage metadata, and automate administration.

**Simple analogy:** The EPM web interface is like using a TV remote control — you push buttons manually. The REST API is like programming your TV to record shows automatically on a schedule.

---

## Authentication

All API calls require authentication. Two methods are supported:

### Basic Authentication

Encode your username and password in Base64 and include it in every request header.

```
Header: Authorization: Basic <base64(username:password)>

Example:
  Username: admin@company.com
  Password: SecurePass123
  Base64:   YWRtaW5AY29tcGFueS5jb206U2VjdXJlUGFzczEyMw==
  Header:   Authorization: Basic YWRtaW5AY29tcGFueS5jb206U2VjdXJlUGFzczEyMw==
```

### OAuth 2.0

For production integrations, Oracle recommends OAuth 2.0 tokens for better security. Configure an OAuth client in Oracle Cloud Identity Console.

### Base URL

```
https://<instance>.pbcs.<datacenter>.oraclecloud.com/HyperionPlanning/rest/v3/
```

---

## Core API Endpoints

### 1. Application Management

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/applications` | List all applications |
| GET | `/applications/{appName}` | Get application details |
| GET | `/applications/{appName}/plantypes` | List cubes (plan types) |

### 2. Running Business Rules

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/applications/{appName}/plantypes/{planType}/rules/{ruleName}` | Launch a business rule |

```json
// Request body (with Runtime Prompts):
{
    "parameters": {
        "RTP_Entity": "E10001",
        "RTP_Scenario": "Budget",
        "RTP_Year": "FY26"
    }
}

// Response:
{
    "status": 0,
    "details": "Rule launched successfully",
    "jobId": 12345
}
```

> [!CAUTION]
> **`status: 0` does NOT mean the rule finished!** It means the server received your request and placed it in the job queue. Business rules run **asynchronously**. You must poll the job status endpoint until the job completes.

### 3. Data Load and Export

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/applications/{appName}/plantypes/{planType}/importdata` | Load data from file |
| POST | `/applications/{appName}/plantypes/{planType}/exportdata` | Export data to file |

**Data load workflow:**
1. Upload the data file to the inbox (File Operations endpoint)
2. Trigger an IMPORT_DATA job
3. Poll for completion

### 4. File Operations

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/applications/{appName}/files` | List files |
| POST | `/applications/{appName}/files/{path}` | Upload a file |
| GET | `/applications/{appName}/files/{path}` | Download a file |
| DELETE | `/applications/{appName}/files/{path}` | Delete a file |

### 5. Job Management

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/applications/{appName}/jobs` | List recent jobs |
| GET | `/applications/{appName}/jobs/{jobId}` | Get job status |

**Job status values:**

| Status | Meaning |
|--------|---------|
| `PROCESSING` | Job is running |
| `COMPLETED` | Job finished — check `executionStatus` |
| `SUCCESS` | Execution was successful |
| `FAILED` | Execution had errors |

### 6. Metadata Operations

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/applications/{appName}/dimensions/{dimName}/members` | Add a member |
| PUT | `/applications/{appName}/dimensions/{dimName}/members/{memberName}` | Update member properties |
| DELETE | `/applications/{appName}/dimensions/{dimName}/members/{memberName}` | Delete member |

### 7. Substitution Variables

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/applications/{appName}/substitutionvariables` | List all variables |
| POST | `/applications/{appName}/substitutionvariables` | Create/update variable |

---

## The Asynchronous Job Pattern

Almost all write operations (rules, data loads, exports) are **asynchronous**. The critical pattern is:

```
1. POST request → Launch the job
2. Extract jobId from response
3. LOOP: GET /jobs/{jobId} until status ≠ "PROCESSING"
4. Check executionStatus: "SUCCESS" or "FAILED"
5. Only THEN proceed to next step
```

> [!WARNING]
> A common mistake: launching 10 rules simultaneously via POST requests. If those rules touch overlapping Essbase blocks, they create **lock contention** — all rules queue up waiting for database locks, and users experience a frozen application. Always orchestrate sequential execution unless rules operate on completely independent data slices.

---

## Automation Examples

### PowerShell: Daily Data Load

```powershell
$baseUrl = "https://mycompany.pbcs.us2.oraclecloud.com/HyperionPlanning/rest/v3"
$cred = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("admin@company.com:Password"))
$headers = @{
    "Authorization" = "Basic $cred"
    "Content-Type" = "application/json"
}

# Step 1: Upload file
Invoke-RestMethod -Uri "$baseUrl/applications/Vision/files/inbox/actuals.csv" `
    -Method Post -Headers $headers -InFile "C:\data\actuals.csv"

# Step 2: Import data
$importBody = @{ jobType = "IMPORT_DATA"; jobName = "DailyActualsLoad" } | ConvertTo-Json
$job = Invoke-RestMethod -Uri "$baseUrl/applications/Vision/jobs" `
    -Method Post -Headers $headers -Body $importBody

# Step 3: Poll for completion
do {
    Start-Sleep -Seconds 10
    $status = Invoke-RestMethod -Uri "$baseUrl/applications/Vision/jobs/$($job.jobId)" `
        -Headers $headers
} while ($status.status -eq "PROCESSING")

Write-Host "Job completed: $($status.executionStatus)"
```

### Python: Run Business Rule and Wait

```python
import requests, base64, time

base_url = "https://mycompany.pbcs.us2.oraclecloud.com/HyperionPlanning/rest/v3"
credentials = base64.b64encode(b"admin@company.com:Password").decode()
headers = {"Authorization": f"Basic {credentials}", "Content-Type": "application/json"}

# Launch business rule
response = requests.post(
    f"{base_url}/applications/Vision/plantypes/FinPlan/rules/Calculate_Revenue",
    headers=headers,
    json={"parameters": {"RTP_Entity": "E10001", "RTP_Year": "FY26"}}
)
job_id = response.json()["jobId"]

# Poll for completion
while True:
    status = requests.get(
        f"{base_url}/applications/Vision/jobs/{job_id}", headers=headers
    ).json()
    if status["status"] != "PROCESSING":
        print(f"Result: {status['executionStatus']}")
        break
    time.sleep(10)
```

---

## REST API vs EPM Automate

| Feature | REST API | EPM Automate |
|---------|----------|-------------|
| **Interface** | HTTP requests (any language) | Command-line utility |
| **Setup** | Just need HTTP client | Install EPM Automate utility |
| **Flexibility** | Full control over every parameter | Pre-built commands, less flexible |
| **Error handling** | Custom per-call | Exit codes |
| **Job orchestration** | You must build poll loops | Built-in wait for completion |
| **Best for** | Custom integrations, CI/CD | Simple automation, scripting |

Both connect to the same underlying EPM Cloud services. EPM Automate internally uses the REST API.

---

## HTTP Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 400 | Bad request | Check JSON payload syntax |
| 401 | Unauthorized | Check credentials |
| 403 | Forbidden | User lacks permissions |
| 404 | Not found | Check endpoint URL |
| 500 | Server error | Check EPM Cloud status, retry |
| 503 | Service unavailable | Instance under maintenance |

---

## Quick Recall

1. **What authentication does the REST API use?** → Basic Auth (Base64) or OAuth 2.0.
2. **Are business rules synchronous or asynchronous via API?** → Asynchronous — you must poll the job status.
3. **How do you load data via REST API?** → Upload file to inbox, then trigger IMPORT_DATA job.
4. **What happens if you launch 10 rules simultaneously?** → Lock contention if they touch overlapping blocks — application freezes.
5. **What's the base URL pattern?** → `https://<instance>.pbcs.<datacenter>.oraclecloud.com/HyperionPlanning/rest/v3/`

**Teach-back prompt:** Explain to a colleague why they can't assume a business rule has completed just because the POST request returned `status: 0`.

---

## Source Provenance

| Source | Files |
|--------|-------|
| Claude | `13_REST_API/13.10_REST_API_Complete_Guide.md`, `13.02_REST_API_Integration.md`, `13.11_REST_API_Oracle_Deep_Reference.md` |
| ChatGPT | EPM Automate REST integration references |
| Oracle | [EPM Cloud REST API Reference](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/prest/) |

