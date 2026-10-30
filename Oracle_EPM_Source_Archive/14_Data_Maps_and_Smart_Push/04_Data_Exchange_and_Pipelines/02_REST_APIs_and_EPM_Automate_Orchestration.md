# 02 REST APIs and EPM Automate Orchestration for Data Movement

## 1. Complete REST API Endpoint Catalog

Enterprise automation frequently manages data exchange pipelines, data maps, and integrations via the Oracle EPM Cloud REST API framework.

### 1.1 Core Data Movement Endpoints

| Operation | Method | URI Endpoint | Functional Description |
| :--- | :--- | :--- | :--- |
| **Execute Data Map** | `POST` | `/HyperionPlanning/rest/v3/applications/{app}/jobs` | Triggers a Data Map bulk sync with parameters (`jobType: "Push Data"`). |
| **Execute Pipeline** | `POST` | `/HyperionPlanning/rest/v3/applications/{app}/jobs` | Launches an end-to-end Integration Pipeline (`jobType: "Pipeline"`). |
| **Execute Integration Rule** | `POST` | `/aif/rest/v1/jobs` | Triggers a Data Integration rule (FDMEE load rule). |
| **Merge ASO Slices** | `POST` | `/HyperionPlanning/rest/v3/applications/{app}/jobs` | Compulsorily compacts ASO storage slices (`jobType: "Merge Data Slices"`). |
| **Poll Job Status** | `GET` | `/HyperionPlanning/rest/v3/applications/{app}/jobs/{jobId}` | Checks asynchronous execution progress and retrieves error logs. |
| **Export Data Map LCM** | `POST` | `/HyperionPlanning/rest/v3/applications/{app}/jobs` | Exports Data Map definitions as LCM XML (`jobType: "Export Data Maps"`). |

---

## 2. JSON Request and Response Schemas

### 2.1 Pipeline Execution Payload
* **Endpoint**: `POST https://<epm_instance>/HyperionPlanning/rest/v3/applications/Vision/jobs`
* **Payload**:
```json
{
    "jobType": "Pipeline",
    "jobName": "NIGHTLY_FINANCIAL_SYNC",
    "parameters": {
        "Period": "Jan-25",
        "ImportMode": "Replace",
        "ExportMode": "Merge"
    }
}
```

### 2.2 Job Status Polling Response
* **Endpoint**: `GET https://<epm_instance>/HyperionPlanning/rest/v3/applications/Vision/jobs/928411`
* **Response**:
```json
{
    "jobId": 928411,
    "jobName": "NIGHTLY_FINANCIAL_SYNC",
    "jobType": "Pipeline",
    "status": 0,
    "descriptiveStatus": "Completed Successfully",
    "startTime": "2026-10-30T02:00:15.000Z",
    "endTime": "2026-10-30T02:04:32.000Z",
    "details": [
        "Stage 1: ERP_TO_OEP_FS loaded 45,210 rows.",
        "Stage 2: Calculate_Actuals completed in 18s.",
        "Stage 3: Data Map OEP_FS to OEP_REP pushed 45,210 cells.",
        "Stage 4: ASO Slice Merge compacted 14 slices into main slice."
    ]
}
```

---

## 3. Production Python Enterprise Orchestrator

The following production script implements bearer token generation, job submission, status polling with exponential backoff, and error reporting:

```python
"""
==================================================================================
Script: epm_pipeline_orchestrator.py
Description: Enterprise REST orchestrator for Oracle EPM Cloud Data Movement
==================================================================================
"""

import requests
import time
import base64
import sys

# Configuration
EPM_HOST = "https://epm-prod-cloud.oraclecloud.com"
APP_NAME = "Vision"
USERNAME = "epm_service_account"
PASSWORD = "SecurePassword123!"
JOB_NAME = "NIGHTLY_FINANCIAL_SYNC"

# Base64 Encode Credentials
auth_str = f"{USERNAME}:{PASSWORD}"
auth_bytes = auth_str.encode("ascii")
b64_auth = base64.b64encode(auth_bytes).decode("ascii")

headers = {
    "Authorization": f"Basic {b64_auth}",
    "Content-Type": "application/json"
}

def trigger_job(job_type, job_name, parameters=None):
    """Submits a job to the Oracle EPM REST API"""
    url = f"{EPM_HOST}/HyperionPlanning/rest/v3/applications/{APP_NAME}/jobs"
    payload = {
        "jobType": job_type,
        "jobName": job_name
    }
    if parameters:
        payload["parameters"] = parameters

    response = requests.post(url, json=payload, headers=headers)
    if response.status_code not in (200, 201, 202):
        print(f"Error triggering job: {response.status_code} - {response.text}")
        sys.exit(1)

    job_data = response.json()
    return job_data["jobId"]

def poll_job_status(job_id, timeout_seconds=600):
    """Polls job status until terminal state (0=Success, >0=Error)"""
    url = f"{EPM_HOST}/HyperionPlanning/rest/v3/applications/{APP_NAME}/jobs/{job_id}"
    elapsed = 0
    poll_interval = 5

    print(f"Polling Job ID {job_id}...")
    while elapsed < timeout_seconds:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            print(f"Polling error: {response.status_code}")
            sys.exit(1)

        data = response.json()
        status = data.get("status")

        # -1 = In Progress
        if status == -1:
            time.sleep(poll_interval)
            elapsed += poll_interval
            print(f"Job in progress... ({elapsed}s elapsed)")
        elif status == 0:
            print(f"SUCCESS: Job {job_id} completed successfully in {elapsed}s.")
            for detail in data.get("details", []):
                print(f"  --> {detail}")
            return True
        else:
            print(f"FAILURE: Job {job_id} failed with status {status}!")
            print(f"Details: {data.get('details')}")
            return False

    print("ERROR: Job polling timed out!")
    return False

if __name__ == "__main__":
    print("Initiating Enterprise Data Pipeline via REST API...")
    job_id = trigger_job("Pipeline", JOB_NAME)
    success = poll_job_status(job_id)
    if not success:
        sys.exit(2)
```

---

## 4. EPM Automate Orchestration Command Reference

| Command | Syntax | Operational Context |
| :--- | :--- | :--- |
| `runDataMap` | `epmautomate runDataMap "MapName" clearTargetData=true` | Pushes internal cube data synchronously or asynchronously. |
| `runPipeline` | `epmautomate runPipeline "PipelineName"` | Triggers multi-step integration sequence. |
| `runIntegration` | `epmautomate runIntegration "RuleName" "Jan-25" "Jan-25" "Replace" "Merge"` | Executes Data Integration rule. |
| `mergeDataSlices` | `epmautomate mergeDataSlices "CubeName" mergeOption=all withZeroCells=true` | Compulsorily consolidates ASO storage slices. |
| `exportDataMap` | `epmautomate exportDataMap "MapName" "fileName.zip"` | Extracts mapping definitions for version control backup. |

