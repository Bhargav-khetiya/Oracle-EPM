# 4.1 Oracle EPM Cloud REST API: Architecture, Authentication & Job Execution

## Table of Contents
1. [Core Consultant Mental Model](#1-core-consultant-mental-model)
2. [Authentication Architecture: Basic Auth vs. OAuth 2.0](#2-authentication-architecture-basic-auth-vs-oauth-20)
3. [Asynchronous Job Execution & Polling Engine](#3-asynchronous-job-execution--polling-engine)
4. [Core REST API Endpoint Matrix](#4-core-rest-api-endpoint-matrix)
5. [Tough & Twisted Review Questions with Consultant Model Answers](#5-tough--twisted-review-questions-with-consultant-model-answers)

---

<!-- ===================================================================== -->
<!-- 🎯 LIVE INTERACTIVE VISUAL CARD: REST API ARCHITECTURE -->
<!-- ===================================================================== -->
<details open>
<summary><b>🎯 Live Interactive Architecture Card: REST API & Asynchronous Job Engine (Click to Collapse / Expand)</b></summary>

<br/>

> [!TIP]
> **Consultant High-Yield Summary:** EPM REST API operations are **asynchronous**. When a client triggers a business rule, data import, or cube refresh, the server does not hold the HTTP connection open. It returns an HTTP `201 Created` with a `jobId`, requiring the client to poll `/HyperionPlanning/rest/v3/applications/{app}/jobs/{jobId}` until status changes from `-1` (In Progress) to `0` (Success).

| Component | Technical Specification | Operational Use Case |
| :--- | :--- | :--- |
| **Protocol & Port** | HTTPS / TLS 1.3 over Port 443 | Secure external programmatic access |
| **Authentication** | OAuth 2.0 Bearer Token (OCI IAM) or Basic Auth Base64 | Machine-to-machine automation without storing plaintext passwords |
| **Payload Format** | JSON (`Content-Type: application/json`) | Payload parameterization for jobs, metadata, and data grids |
| **Execution Model** | **Asynchronous polling** (Long-running jobs) | Batch rule calculation, cube refresh, LCM export |
| **Large File Handling** | Chunked multi-part upload (`/files/upload`) | Uploading data files > 50 MB to Cloud staging |

```mermaid
sequenceDiagram
    autonumber
    actor Script as External Python / ETL Pipeline
    participant Gateway as OCI IAM Gateway
    participant EPM as EPM Cloud REST Engine
    participant JobEngine as Planning Job Console

    Script->>Gateway: POST /oauth2/v1/token (Client ID + Secret)
    Gateway-->>Script: 200 OK (Bearer JWT Access Token)
    
    Script->>EPM: POST /rest/v3/applications/Plan1/jobs<br/>{"jobType": "Rules", "jobName": "Calc_Opex"}
    EPM->>JobEngine: Enqueues calculation job
    EPM-->>Script: 201 Created ({"jobId": 14022, "jobStatus": -1})
    
    loop Poll Job Status (every 5 seconds)
        Script->>EPM: GET /rest/v3/applications/Plan1/jobs/14022
        EPM-->>Script: 200 OK ({"jobStatus": -1, "statusMessage": "In Progress"})
    end
    
    Script->>EPM: GET /rest/v3/applications/Plan1/jobs/14022
    EPM-->>Script: 200 OK ({"jobStatus": 0, "statusMessage": "Completed Successfully"})
```

</details>

---

## 1. Core Consultant Mental Model

When integrating Oracle Cloud EPM with enterprise automation suites (Airflow, Autosys, Jenkins, Informatica), consultants must never rely on brittle web UI scraping.

**The REST API Architecture:**
* Every action performed in the Redwood web interface (launching rules, refreshing outlines, importing metadata, downloading snapshots) maps directly to a **versioned REST endpoint** (`/HyperionPlanning/rest/v3/...`).
* External ETL systems trigger jobs via REST, monitor execution status asynchronously, and parse JSON responses for error diagnosis.

---

## 2. Authentication Architecture: Basic Auth vs. OAuth 2.0

### 1. Basic Authentication
* Constructed by base64-encoding `username:password` into the HTTP header:
  `Authorization: Basic YWRtaW5AY29tcGFueS5jb206U2VjdXJlUGFzczEyMw==`
* **Limitation:** Fails if the user account has Single Sign-On (SSO) with Multi-Factor Authentication (MFA) enabled. Requires a dedicated service account.

### 2. OAuth 2.0 (Modern Enterprise Standard)
* Built using **OCI IAM / IDCS Confidential Applications**:
  1. Register a Confidential Application in OCI IAM with client credentials grant.
  2. Request an OAuth JWT access token:
     `POST https://identity.<region>.oraclecloud.com/oauth2/v1/token`
  3. Pass token in EPM REST headers:
     `Authorization: Bearer <eyJhbGciOi...>`
* **Benefit:** Eliminates password expiration issues and operates seamlessly with corporate SSO policies.

---

## 3. Asynchronous Job Execution & Polling Engine

When launching heavy jobs in EPM, the HTTP request must never wait for job completion (which could take 10 minutes and cause gateway gateway timeouts).

### Standard Execution Pattern:
1. **Trigger Job:**
   * `POST https://<epm_url>/HyperionPlanning/rest/v3/applications/<app>/jobs`
   * Request Payload:
     ```json
     {
         "jobType": "Cube Refresh",
         "jobName": "Refresh_Essbase"
     }
     ```
2. **Receive Job Tracking ID:**
   * Response `201 Created`:
     ```json
     {
         "jobId": 48291,
         "jobStatus": -1,
         "descriptiveStatus": "In Progress"
     }
     ```
3. **Poll Status:**
   * `GET https://<epm_url>/HyperionPlanning/rest/v3/applications/<app>/jobs/48291`
   * Status Codes:
     * **`-1`**: In Progress (continue polling).
     * **`0`**: Completed Successfully.
     * **`1`**: Completed with Warnings.
     * **`2`**: Completed with Errors.
     * **`3` / `4`**: Cancelled / Aborted.

---

## 4. Core REST API Endpoint Matrix

| Operational Capability | HTTP Method | Endpoint URI | Key Parameters / Payload |
| :--- | :---: | :--- | :--- |
| **Launch Business Rule** | `POST` | `/HyperionPlanning/rest/v3/applications/{app}/jobs` | `{"jobType":"Rules", "jobName":"RuleName", "parameters":{}}` |
| **Execute Cube Refresh** | `POST` | `/HyperionPlanning/rest/v3/applications/{app}/jobs` | `{"jobType":"Cube Refresh"}` |
| **Import Data (Data Management)** | `POST` | `/HyperionPlanning/rest/v3/applications/{app}/jobs` | `{"jobType":"Data Management", "jobName":"RuleName"}` |
| **List Application Files** | `GET` | `/interop/rest/11.1.2.3.600/applicationsnapshots` | Returns list of LCM zip snapshots and data files |
| **Upload File in Chunks** | `POST` | `/interop/rest/11.1.2.3.600/applicationsnapshots/upload` | Multi-part stream, `chunkSize`, `totalChunks` |
| **Export Metadata Dimension** | `POST` | `/HyperionPlanning/rest/v3/applications/{app}/jobs` | `{"jobType":"Export Metadata", "parameters":{"dimName":"Account"}}` |

---

## 5. Tough & Twisted Review Questions with Consultant Model Answers

### Question 1: "An integration script triggers an EPM business rule via REST API. The HTTP POST returns `201 Created`, but the calculation never updated the data. Why?"
**Consultant Model Answer:**
> "An HTTP `201 Created` status from the EPM REST API **only confirms that the job request was successfully enqueued in the Job Console**; it does not indicate that the job completed or succeeded. 
> If the business rule encountered a syntax error, member formula compilation failure, or lock timeout, the job will fail in the background with `jobStatus: 2`. The integration script must inspect the returned `jobId` and poll the job status endpoint until `jobStatus: 0` (Completed Successfully) is returned before proceeding."

### Question 2: "How do you automate uploading a 2 GB data export file into Oracle Cloud EPM when standard HTTP POST requests timeout?"
**Consultant Model Answer:**
> "For files exceeding 50 MB, standard single-request HTTP POSTs are prone to network timeouts. Cloud EPM provides a dedicated **Chunked File Upload REST API** (`/interop/rest/11.1.2.3.600/applicationsnapshots/upload`). 
> The automation script:
> 1. Splits the 2 GB file locally into 50 MB binary chunks.
> 2. Sends sequential POST requests passing headers: `chunkNumber`, `totalChunks`, and `chunkSize`.
> 3. The EPM server reassembles the binary chunks upon receiving the final chunk and verifies file checksum integrity."

### Question 3: "A security architect demands that no static administrative passwords be stored in external cron scripts for EPM Automate or REST. How do you comply?"
**Consultant Model Answer:**
> "I implement **OAuth 2.0 Client Credentials with OCI IAM**:
> 1. In OCI IAM / IDCS, register a Confidential Application with appropriate role grants.
> 2. The external script authenticates using its Client ID and Secret to request a short-lived JSON Web Token (JWT) over HTTPS.
> 3. The script passes this token as a Bearer Token in EPM REST headers.
> 4. For EPM Automate, we can encrypt passwords using an encrypted password file (`epm-automate encrypt`), or leverage OAuth tokens directly via modern EPM Automate login parameters (`epm-automate login -oauth`)."

---
*Proceed to [4.2 System Administration: Backups, Cube Refresh & Operations](../04_System_Administration/01_Administration_Guide.md).*
