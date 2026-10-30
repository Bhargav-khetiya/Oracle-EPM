# 01 Data Exchange Pipeline Architecture, Stages, and Error Trapping

## 1. Unified Data Integration and Pipeline Architecture

In modern Oracle EPM Cloud releases, the legacy Financial Data Quality Management Enterprise Edition (FDMEE) and Data Management interfaces have been unified into the **Data Integration (Data Exchange)** platform. The crowning architectural component of this framework is the **Integration Pipeline**.

A Pipeline is a visual orchestration engine that coordinates multi-step data movements, transformations, business rule calculations, data maps, and administrative routines into a single deterministic workflow with built-in error handling and branching.

```
+---------------------------------------------------------------------------------------------------+
|                                  DATA INTEGRATION PIPELINE TOPOLOGY                               |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [PIPELINE START]                                                                                 |
|         |                                                                                         |
|         v                                                                                         |
|  +-------------------------------------+                                                          |
|  | STAGE 1: Extract & Load External ERP |  - Ingests General Ledger trial balance via             |
|  | (Integration Job: ERP_TO_OEP_FS)     |    EPM Integration Agent / Direct Cloud Connector       |
|  +-------------------------------------+                                                          |
|         |                                                                                         |
|         +-----------------------+-----------------------+                                         |
|         | Success               | Failure               |                                         |
|         v                       v                       v                                         |
|  +-----------------------+  +------------------------------------------------------------------+  |
|  | STAGE 2: Calculations |  | CONDITIONAL BRANCH: ABORT & ALERT                                |  |
|  | (Business Rule:       |  | - Send Email Notification to Admin via SMTP                      |  |
|  |  Calculate_Actuals)   |  | - Write error payload to Job Console                             |  |
|  +-----------------------+  +------------------------------------------------------------------+  |
|         |                                                                                         |
|         v                                                                                         |
|  +-------------------------------------+                                                          |
|  | STAGE 3: Cross-Cube Synchronization |  - Executes bulk Data Map streaming BSO leaf             |
|  | (Data Map: OEP_FS to OEP_REP)       |    actuals into ASO reporting cube                       |
|  +-------------------------------------+                                                          |
|         |                                                                                         |
|         v                                                                                         |
|  +-------------------------------------+                                                          |
|  | STAGE 4: ASO Slice Maintenance      |  - Executes ASO slice merge & zero-cell purge            |
|  | (Job: Merge_ASO_Slices)             |    to ensure sub-second reporting dashboard response     |
|  +-------------------------------------+                                                          |
|         |                                                                                         |
|         v                                                                                         |
|  [PIPELINE COMPLETE (Exit Code: 0)]                                                               |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Pipeline Components and Job Types

Pipelines support seven distinct job types that can be sequenced in serial or parallel execution blocks:

| Job Type | Functional Description | Key Parameters |
| :--- | :--- | :--- |
| **Integration** | Runs a predefined Data Integration load rule (File, ERP, or Cloud Connector). | Integration Name, Import Mode, Export Mode, Start/End Period. |
| **Business Rule** | Executes a Calculation Manager business rule or ruleset on a specified cube. | Rule Name, Cube Name, Runtime Prompt (RTP) Key-Value Pairs. |
| **Data Map** | Triggers an internal Data Map between source and target cubes. | Data Map Name, Clear Target Data flag. |
| **EPM Automate** | Executes headless administrative commands natively within the pipeline. | Command String, Parameters (e.g., `exportSnapshot`, `recreate`). |
| **OpenBatch** | Ingests all data files residing in the inbox matching a specific file mask. | Batch Name, File Pattern (e.g., `GL_*.csv`). |
| **File Operation** | Manages server file systems (Inbox/Outbox). | Copy, Move, Delete, Unzip file operations. |
| **Clear Cube** | Performs targeted physical or logical clear on BSO blocks or ASO slices. | Cube Name, Clear Region MDX Specification. |

---

## 3. Execution Control, Conditional Branching, and Error Trapping

Each stage in a Pipeline contains configurable error thresholds and conditional exit triggers:

### 3.1 Stop on Error Policy
* **Abort on Failure (Default)**: If any step fails (e.g., General Ledger validation failure or missing members), subsequent stages are immediately halted.
* **Continue on Failure**: Useful for non-critical steps such as deleting temporary export files or sending informational alerts.

### 3.2 Conditional Execution Parameters
Stages can be configured to execute conditionally based on runtime prompts passed to the pipeline:
```
Condition: $Prompt.RunClear$ == "TRUE"
  ==> Executes Stage 1 (Clear Cube)
Condition: $Prompt.RunClear$ == "FALSE"
  ==> Skips Stage 1 and proceeds directly to Stage 2 (Load)
```

### 3.3 Email Alerting and Webhook Hooks
* **On Success Notification**: Sends summary reports detailing row counts, rejected records, and total execution time.
* **On Failure Alert**: Attaches the execution error log and line-item rejection table to alert the infrastructure support team.

---

## 4. Pipeline LCM Migration and Portability

Pipelines are fully portable across Dev, Test, and Production environments via Lifecycle Management (LCM).
* LCM Artifact Path: `Data Integration -> Pipeline -> [Pipeline_Name]`
* Stored in the application relational repository under `HSP_PM_PIPELINE` and `HSP_PM_PIPELINE_STEP`.
* Variable substitution allows environment-specific endpoints (e.g., swapping Dev ERP URLs for Prod ERP URLs) without modifying pipeline structure.

