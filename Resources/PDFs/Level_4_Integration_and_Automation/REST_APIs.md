# REST APIs for Oracle EPM Cloud — Complete Markdown Edition

> **Original PDF:** `REST_APIs.pdf` | **Folder:** Level 4 (Integration & Automation)  
> **Purpose:** Definitive Markdown developer reference covering all HTTP endpoints, JSON request payloads, batch polling, data slice extraction, and Groovy REST integration across EPM Cloud.

---

## Table of Contents
1. [REST Authentication (`Basic Auth`, `OAuth 2.0 Identity Tokens`)](#auth)
2. [Core Endpoints Matrix (`Jobs`, `Applications`, `Data Slices`)](#endpoints)
3. [Asynchronous Job Polling Loop Architecture](#polling)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. REST Authentication (`Basic Auth`, `OAuth 2.0 Identity Tokens`) <a name="auth"></a>

All endpoints use base URL: `https://your-tenant.epm.ocs.oraclecloud.com/interop/rest/v11` (Global/Migration) or `/HyperionPlanning/rest/v3` (Planning Specific).
- Requires `Authorization: Basic [Base64_String]` or `Authorization: Bearer [OAuth_Token]`.

---

## 2. Core Endpoints Matrix (`Jobs`, `Applications`, `Data Slices`) <a name="endpoints"></a>

| HTTP Method | Endpoint Path | Payload / Parameters | What It Does |
| :--- | :--- | :--- | :--- |
| **`POST`** | `/HyperionPlanning/rest/v3/applications/EPBCS/jobs` | `{"jobType": "CALC_CUBE", "jobName": "Calculate_Overhead"}` | Launches calculation job asynchronously. Returns `jobId` and `status: -1 (In Progress)`. |
| **`GET`** | `/HyperionPlanning/rest/v3/applications/EPBCS/jobs/[jobId]` | `None` | Polls current job status (`0 = Success, 1 = Error`). |
| **`POST`** | `/HyperionPlanning/rest/v3/applications/EPBCS/dataexport/planningslice` | JSON Grid Definition | Returns live Essbase data grid slice in JSON format. |

---

## 3. Asynchronous Job Polling Loop Architecture <a name="polling"></a>

- **Architect Golden Rule:** Never fire a `POST /jobs` request and immediately assume it finished! Always enter an asynchronous polling loop (`GET /jobs/[id]`) sleeping 3 seconds between polls until status transitions out of `-1`.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`13_REST_API/01_REST_API_Complete_Guide.md`** — Comprehensive cURL and Python code examples.
- **`24_Architect_Masterclass/03_Elite_Groovy_Architecture.md`** — Groovy calling REST webhooks.
