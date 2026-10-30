# 📖 Oracle EPM Automate: Master Architecture Bible

> **Purpose**: This directory serves as the definitive, production-grade reference for Oracle EPM Automate — the command-line utility and automation backbone of Oracle Cloud Enterprise Performance Management (Planning, EPBCS, FCCS, ARCS, PCMCS, EDMCS). Every command, authentication mechanism, REST API mapping, error handling pattern, production script, and troubleshooting scenario is documented in depth.

---

## 📂 Document Index

| # | File | Focus Area & Commands | Technical Level |
|---|------|-----------------------|-----------------|
| 00 | [00_INDEX.md](./00_INDEX.md) | Master directory index, command taxonomy, architecture overview | Overview |
| 01 | [01_Architecture_Installation_and_Authentication.md](./01_Architecture_Installation_and_Authentication.md) | REST API wrapper physics, Windows/Linux installation, password encryption (`.epw`), OAuth 2.0 token authentication, API keys, SSO bypass, IP allowlists | Foundation & Security |
| 02 | [02_Environment_and_Snapshot_Lifecycle.md](./02_Environment_and_Snapshot_Lifecycle.md) | Snapshot management (`exportSnapshot`, `importSnapshot`, `uploadFile`, `downloadFile`, `deleteFile`, `listFiles`), Daily Maintenance, `restart`, `recreate`, cross-environment cloning (`cloneEnvironment`, `copySnapshotFromInstance`) | Lifecycle Management |
| 03 | [03_Data_and_Metadata_Automation.md](./03_Data_and_Metadata_Automation.md) | Metadata import/export (`importMetadata`, `exportMetadata`), database refresh (`refreshCube`), data loads (`importData`, `exportData`, `clearCube`, `mergeDataSlices`), Data Integration / Data Management rules (`runDataRule`), Smart Push (`runDataMap`) | Core Integration |
| 04 | [04_Business_Rules_Jobs_and_Calculations.md](./04_Business_Rules_Jobs_and_Calculations.md) | Calc automation (`runBusinessRule` with Runtime Prompts, `runRuleSet`), Job management (`runJob`, `jobStatus`), Security & user provisioning (`provisionUsers`, `assignRole`, `exportUsers`, `userAuditReport`) | Calculation & Governance |
| 05 | [05_Enterprise_Scripting_Runbooks_and_Error_Handling.md](./05_Enterprise_Scripting_Runbooks_and_Error_Handling.md) | Production PowerShell & Bash frameworks, retry logic, email alerting, logging, Windows Task Scheduler / Linux Cron, complete end-to-end Nightly Automation Runbook | Enterprise Engineering |
| 06 | [06_Troubleshooting_Return_Codes_and_Interview_Guide.md](./06_Troubleshooting_Return_Codes_and_Interview_Guide.md) | Return codes (`0`, `1`), EPMAT error code dictionary (EPMAT-00000 to EPMAT-09000), SSL/TLS proxy debugging, Do's & Don'ts, 20 consultant interview questions & answers | Diagnostics & Interview |

---

## 🎯 How to Use This Guide

1. **For Setup & Secure Scripting**: Read `01` → `05`.
2. **For Backup, Cloning & Daily Maintenance**: Read `02`.
3. **For Nightly ETL, Data & Metadata Loading**: Read `03` → `04`.
4. **For Enterprise Production Orchestration**: Read `05`.
5. **For Error Resolution & Interview Preparation**: Read `06`.

---

## 🔑 Key Architecture at a Glance

```
EPM Automate Client (On-Premises Server / Cloud VM)
  │
  ├── 1. Command Execution: epmautomate login user.epw ...
  ├── 2. Translates CLI command into REST API Payload
  ├── 3. Establishes TLS 1.2/1.3 HTTPS connection (Port 443)
  │
  ▼
Oracle Cloud EPM Gateway (api.epm.us-ashburn-1.ocs.oraclecloud.com)
  │
  ├── 4. Token validation & Identity Cloud Service (IDCS / OCI IAM)
  ├── 5. Dispatches request to EPM Planning / Essbase Server (ESSSVR)
  ├── 6. Executes asynchronous job & returns HTTP 200 with Job ID
  │
  ▼
EPM Automate Polls Job Status -> Outputs Result -> Exits with code 0 or 1
```
