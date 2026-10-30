# Data Integration Overview

> **Prerequisites:** [What Is EPM](../00_Foundation/01_What_Is_EPM.md), [EPM Architecture](../00_Foundation/02_EPM_Architecture.md)  
> **Sources merged:** ChatGPT Data_Integration + Data_Maps_and_Exchange, Claude 11_Data_Integration, Gemini Data_Integration + Data_Maps_and_Exchange  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## The Big Picture: Data Movement in EPM Cloud

EPM Cloud doesn't exist in isolation. Organizations need to get data **into** EPM from ERP systems and flat files, move data **between** EPM cubes, and sometimes export data **out** for downstream reporting.

```
┌──────────────────────────────────────────────────────────────────────┐
│                     DATA MOVEMENT IN EPM CLOUD                       │
│                                                                      │
│  EXTERNAL WORLD                    EPM CLOUD                         │
│                                                                      │
│  ┌──────────┐   Data Integration   ┌──────────────┐                 │
│  │ ERP      │ ────────────────────► │ Planning BSO │                 │
│  │ (Oracle, │   (Import/Export)     │ (FinStmt)    │                 │
│  │  SAP,    │                       └──────┬───────┘                 │
│  │  etc.)   │                              │                         │
│  └──────────┘                      Data Maps / Smart Push            │
│                                            │                         │
│  ┌──────────┐   Data Integration   ┌──────▼───────┐                 │
│  │ Flat     │ ────────────────────► │ Reporting    │                 │
│  │ Files    │                       │ ASO          │                 │
│  │ (CSV/TXT)│                       └──────────────┘                 │
│  └──────────┘                                                        │
│                                     ┌──────────────┐                 │
│  ┌──────────┐   Data Integration   │ FCCS         │                 │
│  │ On-Prem  │ ────────────────────► │ (Consolidat.)│                 │
│  │ Database │   (via EPM Agent)     └──────────────┘                 │
│  └──────────┘                                                        │
└──────────────────────────────────────────────────────────────────────┘
```

### Which Tool for Which Job?

| Scenario | Tool |
|----------|------|
| Load data from ERP/external system into EPM | **Data Integration** |
| Load data from a flat file (CSV/TXT) | **Data Integration** |
| Load data from an on-premise database | **Data Integration** (via EPM Agent) |
| Move data between EPM cubes (BSO → ASO) | **Data Maps / Smart Push** |
| Move data between cubes during a calc script | **@XWRITE** |
| Read data from another cube in a formula | **@XREF** |
| Export data from EPM to a flat file | **Data Integration** (Export mode) |
| Small datasets or ad-hoc adjustments | **Manual form entry or Smart View paste** |

`[Oracle Documented]`

---

## Data Management vs Data Integration

Oracle provides two data loading frameworks. Understanding when to use which is critical:

| Feature | Data Management (Legacy) | Data Integration (Modern) |
|---------|:---:|:---:|
| **Complexity** | High — full FDMEE engine | Low — simplified UI |
| **Underlying Engine** | FDMEE | Simplified layer on FDMEE |
| **Mapping** | Explicit rules per dimension | Auto-mapping with overrides |
| **Transformation** | Script-based (Jython/SQL) | Visual drag-and-drop mapping |
| **Source Types** | Files, ERP, databases, on-prem | Files, ERP Cloud, REST APIs |
| **Drill-Back** | ✅ Full drill-through to source | ✅ Limited drill-back |
| **Validation** | Multi-step with data staging | Inline validation |
| **Best For** | Complex, regulated industries | Standard cloud integrations |
| **Navigation** | Navigator → Data Exchange → Data Management | Navigator → Data Exchange → Data Integration |

`[Oracle Documented]`

---

## The Five Core Components

Data Integration is built on five components that chain together into a complete ETL pipeline:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ SOURCE   │ →  │ IMPORT   │ →  │ LOCATION │ →  │ DATA LOAD│
│ SYSTEM   │    │ FORMAT   │    │          │    │ RULE     │
│          │    │          │    │          │    │          │
│ Where    │    │ How to   │    │ Container│    │ Execute  │
│ data     │    │ read the │    │ that ties│    │ the load │
│ comes    │    │ source   │    │ everything│   │          │
│ from     │    │ columns  │    │ together │    │          │
└──────────┘    └──────────┘    └──────┬───┘    └──────────┘
                                       │
                                  ┌────▼─────┐
                                  │ MEMBER   │
                                  │ MAPPINGS │
                                  │          │
                                  │ Translate│
                                  │ source → │
                                  │ target   │
                                  └──────────┘
```

### 1. Source System

Defines **where** data comes from:

| Source Type | Description | Requires EPM Agent? |
|-------------|-------------|:---:|
| **File** | CSV, TXT, or delimited file in the Inbox | ❌ |
| **Oracle ERP Cloud** | Direct connection to Oracle Fusion ERP | ❌ |
| **Oracle NetSuite** | Direct connection to NetSuite | ❌ |
| **On-Premise Database** | SQL Server, Oracle DB, MySQL | ✅ |
| **On-Premise ERP** | Oracle EBS, PeopleSoft, JD Edwards | ✅ |
| **Another EPM Application** | Data from another EPM process | ❌ |

### 2. Import Format

A **blueprint** that tells the system how to read source columns and map them to target dimensions:

```
SOURCE FILE (GL_Data.csv):
  Col 1: Account Code     → maps to → Account dimension
  Col 2: Cost Center       → maps to → Entity dimension
  Col 3: Period Code       → maps to → Period dimension
  Col 4: Amount            → maps to → Data (numeric value)
  Col 5: Description       → skipped (not mapped)
```

### 3. Location

A named **container** that ties together Source System, Import Format, Target Application, and all mapping rules:

```
Location: "GL_Monthly_Load"
  ├── Source System: File
  ├── Import Format: GL_Import_Format
  ├── Target Application: Planning (FinStmt BSO)
  ├── Member Mappings: [defined per dimension]
  └── Data Load Rules: [execution objects]
```

### 4. Member Mappings

Translation rules that convert source system codes into EPM member names. This is the **most critical component** — where most work and most errors happen.

| Mapping Type | Description | Example |
|:---|:---|:---|
| **Explicit** | 1-to-1 exact match | `40100` → `Revenue_Product_Sales` |
| **Like** | Wildcard pattern matching | `40*` → `Revenue_*` |
| **Between** | Range-based mapping | `40100` to `40199` → `Revenue_Summary` |
| **In** | List of specific values to one target | `40100, 40200, 40300` → `Total_Revenue` |
| **Multi-Dimension** | Maps based on multiple column combinations | Account=`40100` + Entity=`US01` → `Revenue_US` |

### Mapping Precedence

When multiple rules could match, the system processes from most specific to least:

```
1. Multi-Dimension  ← most specific wins
2. Explicit         ← exact match
3. Between          ← range match
4. In               ← list match
5. Like             ← pattern match (least specific)
```

### 5. Data Load Rule

The **executable object** that combines everything above with execution parameters (which periods, which category, import mode, export mode).

`[Oracle Documented]`

---

## The Four-Stage Execution Pipeline

When you run a Data Load Rule, data flows through four stages:

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

### Stage 1: Import

| Import Mode | Behavior |
|:---|:---|
| **Append** | Adds new rows to existing staged data |
| **Replace** | Clears existing staged data, then loads new |
| **Map and Validate** | Imports and immediately maps in one step |
| **No Import** | Skips import — uses previously imported data |

For file-based loads, the file must be in the **Inbox** folder (upload via EPM Cloud UI, EPM Automate, or REST API).

### Stage 2: Validate (Map)

Each row is checked against member mappings. Source values are translated:

```
SOURCE ROW:                          AFTER MAPPING:
Account: 40100                →      Account: Revenue_Product_Sales
Entity:  CC-1001              →      Entity:  East
Period:  JAN-2025             →      Period:  Jan
Year:    2025                 →      Year:    FY25
Amount:  50000                →      Amount:  50000
```

Common mapping errors:

| Error | Cause | Fix |
|-------|-------|-----|
| Unmapped member | Source value has no mapping rule | Add an Explicit, Like, or Between mapping |
| Invalid target member | Mapping points to a member that doesn't exist | Fix mapping or add member to outline |
| Multiple matches | Ambiguous rules match same source value | Make mappings more specific |
| Data type mismatch | Non-numeric value in amount column | Fix source data |

### Stage 3: Export

| Export Mode | Behavior |
|:---|:---|
| **Merge** | Adds/updates data — existing data not in the load is preserved |
| **Replace** | Clears the target scope first, then loads |
| **Accumulate** | Adds loaded values to existing values (running total) |
| **Subtract** | Subtracts loaded values from existing values |

> [!IMPORTANT]
> **Replace vs Merge** is the most important decision:
> - **Replace:** Guarantees clean data, but clears ALL data in the mapped scope
> - **Merge:** Preserves existing data, but doesn't remove deleted source rows
> - **Best practice:** Use Replace for full-refresh scenarios; Merge for incremental/delta loads

### Stage 4: Check (Optional)

Post-export verification. Can run custom validation scripts or verify data landed correctly.

`[Oracle Documented]`

---

## EPM Integration Agent (On-Premise Connectivity)

A lightweight Java-based utility that runs inside your corporate network, bridging EPM Cloud and on-premise data sources.

```
┌── On-Premise Network ──────────┐     ┌── Oracle Cloud ────────────┐
│                                 │     │                             │
│  SQL Server / Oracle DB         │     │  EPM Cloud Data Integration│
│          │                      │     │          ▲                  │
│          ▼  JDBC                │     │          │                  │
│  EPM Integration Agent  ──────────────────────────                 │
│  (Java app, Windows service)    │  HTTPS (443)   │                 │
│                                 │  Outbound Only │                 │
└─────────────────────────────────┘     └────────────────────────────┘
```

| Communication Mode | How It Works | Firewall Requirement |
|:---|:---|:---|
| **Synchronous** | EPM Cloud calls the agent directly | ⚠️ Inbound port required |
| **Asynchronous** (Recommended) | Agent polls EPM Cloud for queued jobs | ✅ Outbound HTTPS only |

`[Oracle Documented]` `[Recommendation]` — Use Asynchronous mode for security and resilience.

---

## Quick Recall

1. **What is the difference between Data Management and Data Integration?**
   → Data Management is the full FDMEE engine with complex scripting. Data Integration is a simplified modern UI layer on top of FDMEE for standard cloud integrations.

2. **What are the 5 mapping types in order of precedence?**
   → Multi-Dimension (most specific) → Explicit → Between → In → Like (least specific).

3. **When should you use Replace vs Merge export mode?**
   → Replace for full monthly refreshes (clean slate). Merge for incremental delta loads (preserve existing data).

---

**Next:** [Data Maps and Smart Push](02_Data_Maps_and_Smart_Push.md) — moving data between EPM cubes

