# Oracle EPM Cloud — Data Integration Master Guide

## Overview

**Data Integration** (formerly known as **Data Management** / **FDMEE**) is Oracle EPM Cloud's built-in **ETL framework** for moving data into and out of EPM applications. It is the primary tool for loading external data (from ERP systems, flat files, databases) into Planning, FCCS, Tax Reporting, and other EPM business processes.

While **Data Maps** and **Smart Push** move data *between EPM cubes*, Data Integration moves data *from external systems into EPM* (and can export data out too).

### The Big Picture: Where Data Integration Fits

```
┌──────────────────────────────────────────────────────────────────────┐
│                     DATA MOVEMENT IN EPM CLOUD                       │
│                                                                      │
│  EXTERNAL WORLD                    EPM CLOUD                         │
│  ═════════════                     ═════════                         │
│                                                                      │
│  ┌──────────┐   Data Integration   ┌──────────────┐                 │
│  │ ERP      │ ──────────────────► │ Planning BSO │                  │
│  │ (Oracle, │   (Import/Export)    │ (FinStmt)    │                  │
│  │  SAP,    │                      └──────┬───────┘                  │
│  │  etc.)   │                             │                          │
│  └──────────┘                     Data Maps / Smart Push             │
│                                           │                          │
│  ┌──────────┐   Data Integration   ┌──────▼───────┐                 │
│  │ Flat     │ ──────────────────► │ Reporting ASO│                  │
│  │ Files    │                      └──────────────┘                  │
│  │ (CSV/TXT)│                                                        │
│  └──────────┘                      ┌──────────────┐                 │
│                                    │ FCCS         │                  │
│  ┌──────────┐   Data Integration   │ (Consolidation)                │
│  │ On-Prem  │ ──────────────────► └──────────────┘                  │
│  │ Database │   (via EPM Agent)                                      │
│  │ (SQL/    │                      ┌──────────────┐                 │
│  │  Oracle) │                      │ Tax Reporting│                  │
│  └──────────┘                      └──────────────┘                  │
└──────────────────────────────────────────────────────────────────────┘
```

### When to Use Data Integration vs. Other Tools

| Scenario | Tool |
|----------|------|
| Load data from ERP/external system into EPM | **Data Integration** |
| Load data from a flat file (CSV/TXT) | **Data Integration** |
| Load data from an on-premise database | **Data Integration** (via EPM Agent) |
| Move data between EPM cubes (BSO→ASO) | **Data Maps / Smart Push** |
| Move data between cubes during a calc script | **@XWRITE** |
| Read data from another cube in a formula | **@XREF** |
| Export data from EPM to a flat file | **Data Integration** (Export mode) |

---

## Category

**System Administration / Data Exchange / ETL**

---

## ⚡ Deep Dive: The Five Core Components

Data Integration is built on **five core components** that chain together to form a complete ETL pipeline:

```
┌─────────────────────────────────────────────────────────────────┐
│              THE DATA INTEGRATION COMPONENT CHAIN                │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │ SOURCE   │ →  │ IMPORT   │ →  │ LOCATION │ →  │ DATA LOAD│  │
│  │ SYSTEM   │    │ FORMAT   │    │          │    │ RULE     │  │
│  │          │    │          │    │          │    │          │  │
│  │ Where    │    │ How to   │    │ Container│    │ Execute  │  │
│  │ data     │    │ read the │    │ that ties│    │ the load │  │
│  │ comes    │    │ source   │    │ everything│   │          │  │
│  │ from     │    │ columns  │    │ together │    │          │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│                                       │                          │
│                                  ┌────▼─────┐                   │
│                                  │ MEMBER   │                    │
│                                  │ MAPPINGS │                    │
│                                  │          │                    │
│                                  │ Translate│                    │
│                                  │ source → │                    │
│                                  │ target   │                    │
│                                  └──────────┘                    │
└─────────────────────────────────────────────────────────────────┘
```

---

### Component 1: Source System

**What it is**: Defines WHERE your data comes from.

| Source Type | Description | Requires Agent— |
|-------------|-------------|-----------------|
| **File** | CSV, TXT, or delimited file uploaded to the Inbox | ❌ No |
| **Oracle ERP Cloud** | Direct connection to Oracle Fusion ERP | ❌ No |
| **Oracle NetSuite** | Direct connection to NetSuite | ❌ No |
| **On-Premise Database** | SQL Server, Oracle DB, MySQL, etc. | ✅ Yes (EPM Agent) |
| **On-Premise ERP** | Oracle EBS, PeopleSoft, JD Edwards | ✅ Yes (EPM Agent) |
| **Another EPM Application** | Data from another EPM business process | ❌ No |

### Component 2: Import Format

**What it is**: A **blueprint** that tells the system how to read source data columns and map them to target dimensions.

```
SOURCE FILE (GL_Data.csv):
Col1: Account Code     →  maps to →  Account dimension
Col2: Cost Center       →  maps to →  Entity dimension
Col3: Period Code       →  maps to →  Period dimension
Col4: Amount            →  maps to →  Data (numeric value)
Col5: Description       →  skipped (not mapped)
```

**Configuration includes**:
- File type (Delimited, Fixed-width)
- Delimiter character (comma, tab, pipe)
- Header row count (skip N rows)
- Column-to-dimension mapping

### Component 3: Location

**What it is**: A **container** that ties together the Source System, Import Format, Target Application, and all mapping rules. Think of it as a named "integration pipeline."

```
Location: "GL_Monthly_Load"
├── Source System: File
├── Import Format: GL_Import_Format
├── Target Application: Planning (FinStmt BSO)
├── Member Mappings: [defined per dimension]
└── Data Load Rules: [execution objects]
```

### Component 4: Member Mappings (Data Load Mappings)

**What it is**: Translation rules that convert source system codes into EPM member names.

This is the **most critical component** — if your ERP uses account code `40100` but EPM uses `Revenue_Product_Sales`, the member mapping bridges this gap.

| Mapping Type | What It Does | Example |
|-------------|-------------|---------|
| **Explicit** | 1-to-1 exact match translation | `40100` → `Revenue_Product_Sales` |
| **Like** | Pattern/wildcard matching | `40*` → `Revenue_*` (all accounts starting with 40) |
| **Between** | Range-based mapping | `40100` to `40199` → `Revenue_Summary` |
| **In** | List of specific values to one target | `40100, 40200, 40300` → `Total_Revenue` |
| **Multi-Dimension** | Maps based on combinations of multiple columns | Account=`40100` + Entity=`US01` → `Revenue_US` |

### Component 5: Data Load Rule

**What it is**: The **executable object** that actually runs the integration. It combines everything above and adds execution parameters (which periods, which category, import mode, export mode).

---

## 🔗 Deep Dive: The Four-Stage Execution Pipeline

When you execute a Data Load Rule (or an Integration), the data flows through four stages:

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│  STAGE 1  │ →   │  STAGE 2  │ →   │  STAGE 3  │ →   │  STAGE 4  │
│  IMPORT   │     │  VALIDATE │     │  EXPORT   │     │  CHECK    │
│           │     │  (Map)    │     │           │     │ (Optional)│
│ Extract   │     │ Translate │     │ Load into │     │ Verify    │
│ from      │     │ source →  │     │ target    │     │ data      │
│ source    │     │ target    │     │ EPM app   │     │ integrity │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
```

### Stage 1: IMPORT

**What happens**: Data is extracted from the source and staged in an intermediate table.

| Import Mode | Behavior |
|-------------|----------|
| **Append** | Adds new rows to existing staged data |
| **Replace** | Clears existing staged data, then loads new data |
| **Map and Validate** | Imports and immediately maps in one step |
| **No Import** | Skips import — uses previously imported data |

**For file-based loads**: The file must be in the **Inbox** folder. Upload via:
- EPM Cloud UI (Data Exchange → Inbox)
- EPM Automate: `epmautomate uploadFile filename.csv inbox`
- REST API

### Stage 2: VALIDATE (Map)

**What happens**: Each row of imported data is checked against your member mappings. Source values are translated to target member names.

```
SOURCE ROW:                          AFTER MAPPING:
Account: 40100                →      Account: Revenue_Product_Sales
Entity:  CC-1001              →      Entity:  East
Period:  JAN-2025             →      Period:  Jan
Year:    2025                 →      Year:    FY25
Amount:  50000                →      Amount:  50000
```

**What can go wrong here** (Mapping Errors):

| Error | Cause | Fix |
|-------|-------|-----|
| **Unmapped member** | Source value has no mapping rule | Add an Explicit, Like, or Between mapping |
| **Invalid target member** | Mapping points to a member that doesn't exist in EPM | Fix the mapping or add the member to the outline |
| **Multiple matches** | Ambiguous Like/Between rules match the same source value | Make mappings more specific |
| **Data type mismatch** | Non-numeric value in the amount column | Fix source data |

**Fixing errors in the Workbench**:
1. Open the **Workbench** for the failed load
2. Go to the **Validation Errors** tab
3. Click **Fix Maps** on the failing row
4. Add or correct the mapping
5. Click **Validate** again

### Stage 3: EXPORT

**What happens**: The mapped/validated data is pushed into the target EPM application.

| Export Mode | Behavior |
|-------------|----------|
| **Merge** | Adds/updates data in the target — existing data not in the load is preserved |
| **Replace** | Clears the target scope first, then loads — ensures exact match |
| **Accumulate** | Adds the loaded values to existing values (running total) |
| **Subtract** | Subtracts the loaded values from existing values |
| **No Export** | Skips export — data stays in staging |
| **Check** | Export + verification check |

> ⚠️ **Replace vs. Merge** — this is the most important decision:
> - **Replace**: Guarantees target is clean, but clears ALL data in the mapped scope (including data from other sources)
> - **Merge**: Preserves existing data, but doesn't remove deleted rows from the source
> - **Best practice**: Use **Replace** for full-refresh scenarios; use **Merge** for incremental/delta loads

### Stage 4: CHECK (Optional)

**What happens**: Post-export verification. Can run custom validation scripts or verify that expected data landed correctly.

---

## 🔍 Deep Dive: Member Mapping — The Heart of Integration

Member mapping is where most of the work (and most of the errors) happen. Let's drill into each type:

### Mapping Type 1: Explicit

The most common and straightforward type. One source value maps to exactly one target value.

```
Source Value         Target Value
═══════════         ════════════
40100            →   Revenue_Product_Sales
40200            →   Revenue_Services
50100            →   COGS_Materials
50200            →   COGS_Labor
60100            →   SGA_Salaries
```

**Use when**: Source codes are known and finite. Best for account and entity mappings.

### Mapping Type 2: Like (Wildcard)

Uses `*` wildcards to match patterns.

```
Source Pattern       Target Value
══════════════       ════════════
40*              →   Revenue_*        (Copy everything after 40)
50*              →   COGS_*
6———0            →   Admin_————       (— matches single character)
```

**Use when**: Source and target follow predictable naming conventions.

### Mapping Type 3: Between (Range)

Maps a range of source values to a single target value.

```
Source Range              Target Value
════════════              ════════════
40100  to  40199      →   Revenue_Summary
40200  to  40299      →   Service_Revenue_Summary
50000  to  59999      →   Total_COGS
```

**Use when**: Source chart of accounts follows a numeric range convention.

### Mapping Type 4: In (List)

Maps a specific list of non-sequential source values to one target.

```
Source List                           Target Value
═══════════                           ════════════
40100, 40250, 40375, 40500        →   Revenue_All
CC-1001, CC-1005, CC-1012         →   East_Region
```

**Use when**: You need to map scattered source values that don't follow a pattern.

### Mapping Type 5: Multi-Dimension

Maps based on **combinations** of multiple source columns simultaneously.

```
Source Account + Source Entity     →   Target Account
═══════════════════════════════         ══════════════
40100         + US                →   Revenue_US
40100         + UK                →   Revenue_UK
40100         + JP                →   Revenue_JP
```

**Use when**: The target member depends on a combination of source fields (e.g., account + entity together determine the target account).

### Mapping Processing Order (Precedence)

When multiple mapping rules could match the same source value, the system processes them in this order:

```
┌─────────────────────────────────────────────────────┐
│          MAPPING PRECEDENCE (Highest to Lowest)      │
│                                                      │
│  1. Multi-Dimension  ← most specific wins            │
│  2. Explicit         ← exact match                   │
│  3. Between          ← range match                   │
│  4. In               ← list match                    │
│  5. Like             ← pattern match (least specific) │
└─────────────────────────────────────────────────────┘
```

**The most specific mapping always wins.** If an Explicit mapping exists for `40100` and a Like mapping exists for `40*`, the Explicit mapping takes precedence.

---

## 🤖 Deep Dive: EPM Integration Agent (On-Premise Connectivity)

### What It Is

The EPM Integration Agent is a lightweight **Java-based utility** that runs on a server inside your corporate network. It bridges the gap between EPM Cloud and on-premise data sources (SQL databases, Oracle DB, EBS, PeopleSoft).

### Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  YOUR CORPORATE NETWORK              ORACLE CLOUD                │
│  ════════════════════                ════════════                 │
│                                                                  │
│  ┌──────────────┐                   ┌──────────────┐            │
│  │ On-Premise   │   JDBC            │              │            │
│  │ Database     │◄──────────────────│  EPM Agent   │            │
│  │ (SQL Server, │                   │  (Java App)  │            │
│  │  Oracle DB)  │                   │              │            │
│  └──────────────┘                   └──────┬───────┘            │
│                                            │                     │
│                               SSL/TLS + OAuth                    │
│                          (Outbound HTTPS only)                   │
│                                            │                     │
│  ═ ═ ═ ═ ═ ═ ═ ═  FIREWALL  ═ ═ ═ ═ ═ ═ ═│═ ═ ═ ═ ═ ═ ═ ═   │
│                                            │                     │
│                                     ┌──────▼───────┐            │
│                                     │  EPM Cloud   │            │
│                                     │  Data        │            │
│                                     │  Integration │            │
│                                     └──────────────┘            │
└──────────────────────────────────────────────────────────────────┘
```

### Two Communication Modes

| Mode | How It Works | Firewall Requirement |
|------|-------------|---------------------|
| **Synchronous** | EPM Cloud calls the agent directly | ⚠️ Inbound port must be open |
| **Asynchronous** (Recommended) | Agent polls EPM Cloud for queued jobs | ✅ No inbound ports — outbound HTTPS only |

> **Best practice**: Use **Asynchronous mode**. It's more secure (no inbound firewall rules needed) and more resilient (the agent retries automatically).

### Setup Steps

1. **Prerequisites**: Install Java JRE 8+ on the host server
2. **Download**: Get the agent from EPM Cloud → Data Exchange → Download Agent
3. **Initialize**: Run `createAppFolder.bat` to set up the directory structure
4. **Configure**: Set JDBC connection strings, EPM Cloud URL, credentials
5. **Register**: Register the agent in EPM Cloud
6. **Test**: Run a test connection from the Data Integration UI

### Agent Clusters

For high availability and load distribution, deploy **multiple agents in a cluster**:
- Agents share the workload
- If one agent goes down, others continue processing
- Recommended for production environments

---

## 🔥 Complete Scenario: File-Based GL Data Load

This is the most common Data Integration use case — loading monthly General Ledger data from a CSV file into Planning.

### Step 1: Prepare the Source File

**File**: `GL_JAN2025.csv` (uploaded to Inbox)

```csv
Account,Entity,Period,Year,Scenario,Amount
40100,CC-1001,JAN,2025,ACTUAL,50000
40200,CC-1001,JAN,2025,ACTUAL,25000
50100,CC-1001,JAN,2025,ACTUAL,-30000
50200,CC-1002,JAN,2025,ACTUAL,-15000
60100,CC-1002,JAN,2025,ACTUAL,-8000
40100,CC-1002,JAN,2025,ACTUAL,42000
```

### Step 2: Create the Import Format

| Setting | Value |
|---------|-------|
| Name | `GL_Import_Format` |
| Source Type | File |
| File Type | Delimited |
| Delimiter | Comma |
| Header Rows | 1 |

**Column Mappings**:

| Column # | Source Column | Maps To | Type |
|----------|-------------|---------|------|
| 1 | Account | Account dimension | Text |
| 2 | Entity | Entity dimension | Text |
| 3 | Period | Period dimension | Text |
| 4 | Year | Year dimension | Text |
| 5 | Scenario | Scenario dimension | Text |
| 6 | Amount | Data (Amount) | Numeric |

### Step 3: Create the Location

| Setting | Value |
|---------|-------|
| Name | `GL_Monthly_Load` |
| Source System | File |
| Import Format | `GL_Import_Format` |
| Target Application | Planning (FinStmt) |

### Step 4: Define Member Mappings

**Account Mappings** (Explicit):

| Source | → | Target |
|--------|---|--------|
| `40100` | → | `Revenue_Product_Sales` |
| `40200` | → | `Revenue_Services` |
| `50100` | → | `COGS_Materials` |
| `50200` | → | `COGS_Labor` |
| `60100` | → | `SGA_Salaries` |

**Entity Mappings** (Explicit):

| Source | → | Target |
|--------|---|--------|
| `CC-1001` | → | `East` |
| `CC-1002` | → | `West` |

**Period Mappings** (Explicit):

| Source | → | Target |
|--------|---|--------|
| `JAN` | → | `Jan` |
| `FEB` | → | `Feb` |
| ... | ... | ... |

**Year Mappings** (Explicit):

| Source | → | Target |
|--------|---|--------|
| `2025` | → | `FY25` |

**Scenario Mappings** (Explicit):

| Source | → | Target |
|--------|---|--------|
| `ACTUAL` | → | `Actual` |

### Step 5: Create and Execute the Data Load Rule

| Setting | Value |
|---------|-------|
| Name | `GL_Jan_Load` |
| Category | Actual |
| Period | Jan |
| Import Mode | Replace |
| Export Mode | Merge |
| Source File | `GL_JAN2025.csv` |

### Step 6: What Happens During Execution

```
Stage 1 — IMPORT:
  Read GL_JAN2025.csv from Inbox
  6 rows extracted → staged in intermediate table

Stage 2 — VALIDATE (Map):
  Row 1: 40100, CC-1001, JAN, 2025, ACTUAL, 50000
         → Revenue_Product_Sales, East, Jan, FY25, Actual, 50000  ✅
  Row 2: 40200, CC-1001, JAN, 2025, ACTUAL, 25000
         → Revenue_Services, East, Jan, FY25, Actual, 25000       ✅
  ...
  All 6 rows mapped successfully.

Stage 3 — EXPORT:
  Load 6 rows into FinStmt BSO cube
  Export Mode = Merge → existing data preserved, new data added/updated

Stage 4 — CHECK:
  Verification passed — 6 rows loaded successfully
```

---

## 🔥 Complete Scenario: On-Premise Database Load (via EPM Agent)

### The Setup

Your ERP stores GL data in a SQL Server database. You need to load monthly actuals into EPM Cloud Planning.

### Step 1: Configure the EPM Agent

The agent is installed on a Windows server inside your corporate network:

```
Agent Server: FINANCE-APP01
Database: SQL Server (FINANCE_DB)
JDBC Driver: mssql-jdbc-XX.jar
Connection String: jdbc:sqlserver://FINANCE-DB01:1433;databaseName=FINANCE_DB
```

### Step 2: Define the SQL Query as the Source

In Data Integration, define a **SQL-based source** that the agent executes:

```sql
SELECT 
    gl.ACCOUNT_CODE    AS "Account",
    gl.COST_CENTER     AS "Entity",
    gl.PERIOD_NAME     AS "Period",
    gl.FISCAL_YEAR     AS "Year",
    'ACTUAL'           AS "Scenario",
    SUM(gl.AMOUNT)     AS "Amount"
FROM GL_TRANSACTIONS gl
WHERE gl.FISCAL_YEAR = '2025'
  AND gl.PERIOD_NAME = 'JAN'
  AND gl.STATUS = 'POSTED'
GROUP BY gl.ACCOUNT_CODE, gl.COST_CENTER, gl.PERIOD_NAME, gl.FISCAL_YEAR
```

### Step 3: Execution Flow

```
1. EPM Cloud queues the job
2. EPM Agent (on FINANCE-APP01) picks up the job
3. Agent executes SQL query against SQL Server
4. Agent sends results to EPM Cloud (SSL/TLS encrypted)
5. EPM Cloud processes through Import → Validate → Export stages
6. Data lands in Planning FinStmt cube
```

---

## 📋 Deep Dive: Import and Export Modes — Complete Reference

### Import Modes

| Mode | Behavior | When to Use |
|------|----------|-------------|
| **Append** | Adds new rows to previously staged data without clearing | Building up data from multiple files before exporting |
| **Replace** | Clears ALL previously staged data, then imports fresh | Standard monthly load — start clean each time |
| **Map and Validate** | Imports and applies mappings in one step | Quick loads where you want to skip manual validation |
| **No Import** | Skips import entirely — uses previously staged data | Re-exporting after fixing mapping errors |
| **Direct** | Bypasses staging — loads directly into target | Performance optimization for clean, pre-mapped data |

### Export Modes

| Mode | Behavior | When to Use |
|------|----------|-------------|
| **Merge** | Loads data into target; existing data not in the load is preserved | Incremental/delta loads |
| **Replace** | Clears target scope, then loads fresh data | Full refresh — ensures target matches source exactly |
| **Accumulate** | Adds loaded values to existing target values | Journaling — each load adds to the running balance |
| **Subtract** | Subtracts loaded values from existing target values | Reversals or adjustments |
| **No Export** | Data stays in staging — not pushed to target | Testing mappings without affecting the cube |
| **Check** | Exports data and runs a post-export verification | Production loads where data integrity is critical |

### The Critical Replace vs. Merge Decision

```
┌──────────────────────────────────────────────────────────────────┐
│                    REPLACE vs. MERGE                              │
│                                                                  │
│  REPLACE:                                                        │
│  ✅ Target is always a perfect mirror of the source              │
│  ✅ Deleted source rows are removed from target                  │
│  ⚠️ Clears ALL data in the target scope — not just your load    │
│  ⚠️ If other processes also write to this scope, their data     │
│     is WIPED                                                     │
│                                                                  │
│  MERGE:                                                          │
│  ✅ Preserves existing target data not in the load               │
│  ✅ Safe for multi-source scenarios                              │
│  ⚠️ Deleted source rows remain in target (no cleanup)           │
│  ⚠️ Can lead to stale data if source rows are removed           │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🤖 Automation: EPM Automate & Scheduling

### EPM Automate Commands for Data Integration

| Command | What It Does | Example |
|---------|-------------|---------|
| `uploadFile` | Upload a file to the Inbox | `epmautomate uploadFile GL_JAN.csv inbox` |
| `runIntegration` | Execute a Data Integration job | `epmautomate runIntegration "GL_Load" importMode=Replace exportMode=Merge periodName=Jan` |
| `importData` | Run a pre-defined import data job | `epmautomate importData "GL_Import" GL_JAN.csv errorFile=errors.zip` |
| `runDataRule` | Run a Data Load Rule (legacy) | `epmautomate runDataRule "GL_Rule" Jan-25 Jan-25 Replace Merge` |
| `importMapping` | Import mapping rules from a file | `epmautomate importMapping "GL_Location" Account GL_AcctMap.csv` |

### Sample Automation Script (Windows Batch)

```batch
@echo off
REM ========================================
REM Monthly GL Load Automation Script
REM ========================================

SET EPM_URL=https://mycompany-planning.epm.us6.oraclecloud.com
SET EPM_USER=admin@mycompany.com
SET EPM_PASS_FILE=password.epw

REM Step 1: Login
epmautomate login %EPM_USER% %EPM_PASS_FILE% %EPM_URL%
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Login failed
    exit /b 1
)

REM Step 2: Upload the data file
epmautomate uploadFile "C:\Data\GL_JAN2025.csv" inbox
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: File upload failed
    epmautomate logout
    exit /b 1
)

REM Step 3: Run the integration
epmautomate runIntegration "GL_Monthly_Load" importMode=Replace exportMode=Merge periodName=Jan inputFileName=GL_JAN2025.csv
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Integration failed
    epmautomate logout
    exit /b 1
)

REM Step 4: Logout
epmautomate logout
echo SUCCESS: GL data loaded for January 2025
```

### Scheduling Options

| Method | Description | Best For |
|--------|-------------|----------|
| **EPM Platform Job Scheduler** | Built-in EPM Cloud scheduler (no external server needed) | Standard scheduled jobs — simplest setup |
| **Windows Task Scheduler** | Schedule the batch script on a Windows server | When you need pre/post-processing logic |
| **Linux Cron** | Schedule the shell script on a Linux server | Unix-based automation infrastructure |
| **REST API** | Call EPM Cloud APIs from any application | Third-party orchestration tools (Informatica, SSIS, etc.) |
| **Groovy Business Rule** | Trigger integration from within a business rule | Event-driven loads (e.g., after a user action) |

---

## 🔧 The Workbench — Troubleshooting Central

The **Workbench** is where you view, troubleshoot, and fix data at every stage of the pipeline.

### What You Can Do in the Workbench

| Action | How |
|--------|-----|
| **View imported data** | Open Workbench → Source tab → see raw imported rows |
| **View mapped data** | Open Workbench → Target tab → see after-mapping results |
| **Find mapping errors** | Open Workbench → Validation Errors tab → see unmapped rows |
| **Fix mappings inline** | Click "Fix Maps" on a failed row → add/edit mapping → re-validate |
| **View export results** | Check the Process Details page for row counts and status |
| **Download logs** | Process Details → Download Log/Output files (.log, .out) |

### Common Error Types and Fixes

| Error | Stage | Cause | Fix |
|-------|-------|-------|-----|
| **Unmapped member** | Validate | Source value has no mapping rule | Add Explicit/Like/Between mapping |
| **Invalid target member** | Validate | Mapping points to non-existent EPM member | Fix mapping or add member to outline |
| **File not found** | Import | File not in Inbox or wrong filename | Upload file to correct Inbox path |
| **Connection failed** | Import | EPM Agent down or JDBC misconfigured | Check agent status, verify connection string |
| **Export failed** | Export | Target cube locked or maintenance running | Wait for lock to release, retry |
| **Zero/Missing rows skipped** | Export | Rows with all zeros or #MISSING are excluded | By design — ensure source has non-zero values |
| **Security violation** | Export | User lacks write access to target members | Verify user provisioning and data security |

---

## 🆚 Complete Comparison: All Data Movement Tools

| Feature | Data Integration | Data Maps | Smart Push | @XWRITE | @XREF |
|---------|-----------------|-----------|------------|---------|-------|
| **Primary purpose** | External → EPM | EPM → EPM | EPM → EPM (delta) | EPM → EPM (calc) | EPM ← EPM (read) |
| **Source** | Files, databases, ERP | EPM cube | EPM cube | Current cube | Another cube |
| **Target** | EPM cube | EPM cube | EPM cube | Another cube | Current cube |
| **Configuration** | UI-based ETL | UI mapping | Uses Data Map | Calc script | Calc script |
| **Transformation** | Member mappings | Member mappings | Via Data Map | Full calc logic | N/A (read only) |
| **Execution** | Manual / scheduled / EPM Automate | Manual / scheduled / Groovy | On form save | During calculation | During calculation |
| **Clear target** | ✅ Replace mode | ✅ Optional | ✅ Narrow clear | ❌ Overwrites cell | N/A |
| **External sources** | ✅ Yes (primary use) | ❌ No | ❌ No | ❌ No | ❌ No |
| **On-premise sources** | ✅ Yes (via EPM Agent) | ❌ No | ❌ No | ❌ No | ❌ No |
| **Drill-through** | ✅ Yes (back to source) | ❌ No | ❌ No | ❌ No | ❌ No |
| **Comments/Attachments** | ❌ No | ✅ Yes | ✅ Yes | ❌ No | ❌ No |
| **BSO → ASO** | ❌ (use Data Maps) | ✅ Yes | ✅ Yes | ❌ No | ❌ No |
| **Error handling** | ✅ Workbench + logs | ❌ Limited | ❌ Limited | ❌ Calc errors | ❌ Calc errors |
| **Automation** | EPM Automate / REST API | Groovy | Form-triggered | Calc script | Calc script |

---

## 📋 Data Integration vs. Data Management — Which UI—

EPM Cloud has **two interfaces** for the same underlying engine:

| Feature | Data Integration (Modern) | Data Management (Legacy) |
|---------|--------------------------|-------------------------|
| **Access** | Navigator → Data Integration | Navigator → Data Management |
| **UI** | Modern, card-based | Classic, tabbed interface |
| **Quick Mode** | ✅ Yes — simplified setup | ❌ No |
| **All features** | Most features | All features (more granular control) |
| **Synchronization** | ✅ Changes sync to Data Management | ✅ Changes sync to Data Integration |
| **Recommendation** | Use for new setups | Use for advanced/complex scenarios |

> **Key point**: They are **two views of the same engine**. A mapping created in Data Management is visible in Data Integration and vice versa. You can switch between them freely.

---

## ⚠️ Drill-Through: Tracing Data Back to Source

One of the most powerful features of Data Integration is **drill-through** — clicking on a value in an EPM form and seeing the original source transactions that contributed to it.

### How It Works

```
User clicks cell in EPM form → "Revenue_Product_Sales, East, Jan, FY25" = 50,000
    │
    ▼ Drill-Through
    │
Workbench shows:
    GL Transaction 1: 40100, CC-1001, JAN, 2025 → 30,000
    GL Transaction 2: 40100, CC-1001, JAN, 2025 → 20,000
                                                    ═══════
                                          Total:    50,000 ✅
```

### Setup Requirements

1. Data was loaded through Data Integration (not manually entered)
2. Drill-through is configured on the target application
3. User has appropriate access permissions
4. The integration retained the mapping lineage

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| **File not in Inbox** | Integration can't find the source file | Upload to the correct `inbox/` path |
| **Wrong delimiter** | Import Format expects comma but file uses pipe | Match the delimiter in Import Format settings |
| **Missing header skip** | First row (headers) loaded as data | Set Header Rows = 1 in Import Format |
| **Unmapped new accounts** | New ERP accounts added without updating mappings | Add new mappings or use Like/Between rules |
| **Replace wiping shared data** | Export Replace clears ALL data in scope | Use Merge, or narrow the scope |
| **EPM Agent offline** | On-premise loads fail silently | Monitor agent health, set up alerts |
| **Mapping order conflicts** | Like rule overriding an Explicit rule | Explicit always wins — check mapping precedence |
| **Period mapping mismatch** | Source says "JAN" but EPM expects "Jan" | Create explicit period mappings (case-sensitive) |
| **Year format mismatch** | Source says "2025" but EPM expects "FY25" | Add year mapping: 2025 → FY25 |
| **Simultaneous loads** | Two loads to the same scope overlap | Sequence loads or use different categories |
| **Not refreshing cube after metadata load** | New members added but not visible | Run Refresh Database after metadata imports |
| **Large file timeout** | Files with millions of rows time out | Break into smaller chunks or use Direct mode |

---

## Performance Considerations

| Consideration | Recommendation |
|---------------|----------------|
| **File size** | Keep under 500MB per file; break large files into chunks |
| **Direct mode** | Use for pre-mapped, clean data — bypasses staging for speed |
| **Replace vs. Merge** | Replace is faster (bulk clear + load); Merge is safer |
| **EPM Agent placement** | Install agent close to the database server for low latency |
| **Agent clusters** | Use multiple agents for high-volume or parallel loads |
| **Like mappings** | Faster than Explicit for large member counts (fewer rules) |
| **Schedule during off-hours** | Large loads can lock cubes — run during maintenance windows |
| **Pre-aggregate in source** | Summarize in SQL before loading — fewer rows = faster |

---

## Related Concepts

| Concept | Relationship |
|---------|-------------|
| [Data Maps](../04_System_Administration/Oracle_EPM_Data_Maps_and_Smart_Push_Master_Guide.md) | Moves data between EPM cubes (not from external sources) |
| [@XWRITE](../Calc%20Manager/Calc%20Managers%20all%20business%20Rule%20Functions/05_Data_Access/@XWRITE.md) | Programmatic cross-cube write during calculations |
| [@XREF](../Calc%20Manager/Calc%20Managers%20all%20business%20Rule%20Functions/05_Data_Access/@XREF.md) | Programmatic cross-cube read during calculations |
| **EPM Automate** | Command-line automation for all EPM Cloud operations |
| **REST API** | Programmatic API for triggering integrations from external systems |
| **Groovy Rules** | Trigger integrations from within business rules |

---

## Official Oracle Reference

- [Administering Data Integration for EPM Cloud](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/diepm/index.html)
- [EPM Automate Command Reference](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cepma/index.html)
- [Setting Up the EPM Integration Agent](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/diepm/setting_up_epm_integration_agent.html)
- [Data Load Mapping Types](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/diepm/mapping_types.html)
