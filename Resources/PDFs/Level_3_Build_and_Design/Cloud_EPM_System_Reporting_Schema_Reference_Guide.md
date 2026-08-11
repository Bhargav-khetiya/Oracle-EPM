# Cloud EPM System Reporting Schema Reference Guide — Complete Markdown Edition

> **Original PDF:** `Cloud_EPM_System_Reporting_Schema_Reference_Guide.pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** Definitive Markdown extraction of the relational audit and monitoring database tables (`Reporting Schema`) used by administrators to query audit logs, user sessions, and calculation job histories.

---

## Table of Contents
1. [What is the System Reporting Schema?](#reporting-schema)
2. [Key Audit & Job Monitoring Tables (`EPM_AUDIT`, `EPM_JOBS`)](#audit-tables)
3. [Extracting Schema Data via REST API & Data Integration](#extracting)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. What is the System Reporting Schema? <a name="reporting-schema"></a>

The **System Reporting Schema** is a hidden, pre-aggregated relational database layer inside EPM Cloud that stores historical compliance, user access, and calculation execution logs.

---

## 2. Key Audit & Job Monitoring Tables (`EPM_AUDIT`, `EPM_JOBS`) <a name="audit-tables"></a>

| Table Name | Description | Key Columns |
| :--- | :--- | :--- |
| **`EPM_AUDIT_DATA_CHANGES`** | Logs every numeric data cell modification made across all cubes (`Who changed what, when, and exact before/after values`). | `USER_ID`, `APP_NAME`, `CUBE_NAME`, `POV_TUPLE`, `OLD_VALUE`, `NEW_VALUE`, `TIMESTAMP` |
| **`EPM_AUDIT_METADATA_CHANGES`** | Logs structural outline edits (`Adding/deleting dimensions or members`). | `USER_ID`, `DIMENSION_NAME`, `MEMBER_NAME`, `ACTION_TYPE`, `TIMESTAMP` |
| **`EPM_JOB_HISTORY`** | Logs every Business Rule, Data Map, and EPM Automate execution along with runtime durations and errors. | `JOB_ID`, `JOB_NAME`, `JOB_TYPE`, `START_TIME`, `END_TIME`, `STATUS`, `ERROR_DETAILS` |

---

## 3. Extracting Schema Data via REST API & Data Integration <a name="extracting"></a>

Administrators can extract these tables into external data warehouses (`Snowflake, SQL Server`) using **REST API endpoints (`/interop/rest/v11/reports/audit`)** or via **Data Integration Pipeline queries** for enterprise SOC1/SOC2 compliance monitoring.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`16_Administration/03_Admin_Specialized_Deep_Reference.md`** — Audit schema extraction scripts.
- **`18_Production_Support/01_Production_Support_Guide.md`** — Auditing user data changes.
