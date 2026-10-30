# Data Maps, Smart Push, and Cross-Cube Data Movement

> **Prerequisites:** [Data Integration Overview](01_Data_Integration_Overview.md)  
> **Sources merged:** ChatGPT Data_Maps_and_Exchange (17 files across 6 subdirectories), Claude 11.11, Gemini Data_Maps_and_Exchange  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## What Are Data Maps?

Data Maps are Oracle EPM Cloud's **declarative data movement engine** between cubes within an application or across applications. Unlike `@XREF`/`@XWRITE` (which execute cell-by-cell inside the Essbase kernel), Data Maps operate at the **platform metadata and buffer layer**, enabling bulk extraction, transformation, and parallel loading.

```
SOURCE CUBE (BSO/ASO)                    TARGET CUBE (ASO/BSO)
┌──────────────────────┐                 ┌──────────────────────┐
│ Dense/Sparse Blocks  │                 │ ASO Data Slices      │
│ (.pag/.ind files)    │                 │ or BSO Block Storage  │
└──────────┬───────────┘                 └──────────▲───────────┘
           │ 1. MDX Slice Extract                   │ 4. Load Buffer Commit
           ▼                                        │
┌──────────────────────┐                 ┌──────────────────────┐
│ SOURCE DATA STREAM   │                 │ TARGET LOAD BUFFER   │
│ [Tuple: Dims | Value]│  2. Transform   │ [EssWriteLoadBuffer] │
└──────────┬───────────┘ ──────────────► └──────────────────────┘
           │                    ▲
           └────────────────────┘
                 3. HSP_MAP_* Relational Metadata
                    (dimension mappings, exclusions)
```

`[Oracle Documented]`

---

## Data Maps vs @XREF/@XWRITE

| Parameter | Data Maps | @XREF / @XWRITE (Calc Scripts) |
|:---|:---|:---|
| **Execution** | Application server + bulk buffer API | Essbase C++ calculation kernel |
| **Extraction** | MDX bulk query / Grid Slicer | Point-by-point network socket call |
| **Load Method** | ASO Load Buffer / bulk BSO writer | Individual cell injection |
| **Throughput** | **100,000–500,000 cells/second** | **500–2,500 cells/second** |
| **Lock Impact** | Single clean slice; minimal contention | Serial block locks; high overhead |
| **UI Integration** | Visual configuration, Smart Push | Custom calc script coding |
| **Maintenance** | Auto-updates when metadata changes | Hardcoded member names need manual audits |

> [!TIP]
> Use Data Maps for any regular inter-cube data movement. Reserve @XREF for point-reference lookups within formulas, and @XWRITE for targeted cell writes from business rules.

`[Recommendation]`

---

## Configuring a Data Map

A Data Map defines:
1. **Source Cube** and **Target Cube**
2. **Dimension Mappings** — how each dimension in the source maps to the target
3. **Member Selections** — which members to extract (with exclusions)
4. **Options** — clear target data, copy comments, aggregate on target

### Dimension Mapping Types

| Type | Description | Example |
|:---|:---|:---|
| **Identity (Exact Match)** | Same member names in source and target | Account → Account (same hierarchy) |
| **Fixed** | All source data maps to one target member | Source "Entity" → Target "Periodic" view |
| **One-to-Many** | One source member maps to multiple target members | Source "Total_Rev" → Target sub-accounts |
| **Many-to-One** | Multiple source members map to one target member | Source sub-entities → Target "Total_US" |

### Member Selection Syntax

```
Descendants(Total_Entity)       — All descendants of Total_Entity
ILvl0Descendants(Total_Entity)  — Only leaf-level (Level 0) descendants
Children(Revenue)               — Direct children only
Member(E10001)                  — Specific individual member
```

`[Oracle Documented]`

---

## Smart Push: Real-Time Form Integration

**Smart Push** binds a Data Map to a Web Form, enabling automatic data movement when users click **Save**. It's the presentation-layer operational manifestation of Data Maps.

### Smart Push Configuration

| Setting | Options | Purpose |
|:---|:---|:---|
| **Data Map Selection** | Dropdown of active maps | Which routing rules to use |
| **Run On Save** | Yes / No | Execute automatically on form save |
| **Use Form Context** | Yes / No | **Critical** — limits push to form's visible members |
| **Run in Background** | Yes / No | Release UI immediately (async) |
| **Overwrite Data** | Yes / No | Whether to overwrite existing target values |

### Context-Aware Micro-Slice (Critical Concept)

When **Use Form Context** is checked, the engine extracts only the intersection of the form's active layout and the Data Map scope:

```
Form Context:
  Page:  Entity = "E101_Sales_East"
  POV:   Scenario = "Plan", Version = "Working", Year = "FY26"
  Rows:  Accounts = "Advertising", "Travel", "Meals" (3 members)
  Cols:  Periods = "Jan", "Feb", "Mar" (3 members)

Total cells pushed: 1 × 1 × 1 × 1 × 3 × 3 = 9 cells
Execution time: < 400 milliseconds
```

> [!CAUTION]
> If **Use Form Context** is NOT checked, saving a form with a single cell change triggers a **full macro-slice push** — potentially extracting millions of cells, locking server threads for 30–60 seconds, and causing browser timeouts (HTTP 504).

### Execution Flow on Form Save

```
1. User clicks Save
2. Client-side validation (formula syntax, read-only locks)
3. Dirty cells written to Source BSO cube
4. Before-Save business rules execute (if attached)
5. Source blocks committed to disk
6. Smart Push builds micro-slice MDX
7. Micro-slice streamed to target via load buffer
8. After-Save business rules execute (if attached)
9. UI acknowledgement: "Data saved. Smart Push completed."
```

### Synchronous vs Asynchronous

| Mode | Behavior | Use When |
|:---|:---|:---|
| **Synchronous** (Background = No) | Browser waits until push completes | Interactive planning; user needs immediate target results; < 5,000 cells |
| **Asynchronous** (Background = Yes) | Source save returns immediately; push runs in background | Large forms; hundreds of rows; heavy target aggregations |

`[Oracle Documented]`

---

## Cross-Cube Functions: @XREF and @XWRITE

### @XREF — Pull Data from Another Cube

Reads a single cell value from another cube at calculation time:

```essbase
/* In FinPlan cube: pull headcount from Manpower cube */
"Salary_Per_Head" = @XREF("Manpower", "Headcount");

/* With overrides: specify different members in the target cube */
"Revenue_Target" = @XREF("TargetCube", "Revenue", "Budget", "Final");
```

**How it works:** Essbase opens a network socket to the target cube, reads the cell, and returns the value. This happens **per cell intersection** — making it slow for large data volumes.

### @XWRITE — Push Data to Another Cube

Writes a value to a cell in another cube during calculation:

```essbase
/* Push consolidated revenue from FinPlan to Reporting cube */
@XWRITE("Revenue", "ReportingCube", "Revenue", "Actual");
```

### Performance Considerations

| Factor | @XREF/@XWRITE | Data Maps |
|:---|:---|:---|
| 100 cells | ≈ 0.1 sec | Overkill |
| 10,000 cells | ≈ 4–10 sec | ≈ 0.1 sec |
| 1,000,000 cells | ≈ 7–30 **minutes** | ≈ 2–10 sec |

`[Oracle Documented]`

---

## Data Map Execution Lifecycle

When triggered (via UI, Job Console, Smart Push, EPM Automate, or REST API):

```
Phase 1: Validation & Security Check
  → Verify user access to source and target data slices
  → Validate dimension hierarchies

Phase 2: Source Extraction
  → Parse member selections and exclusions
  → Generate optimized MDX extraction query

Phase 3: Target Preparation (Optional)
  → If "Clear Target Data" enabled:
    ASO: MDX Clear Slice or negative compensation slice
    BSO: Targeted CLEARBLOCK/CLEARDATA on target slice

Phase 4: Stream Transformation
  → Source tuples streamed in chunks (10,000–50,000 cells)
  → Apply dimension mappings, fixed assignments, data conversion

Phase 5: Target Ingestion
  → ASO: Open load buffer → stream rows → commit slice
  → BSO: Block writer buffer → direct to .pag/.ind files

Phase 6: Target Rollup (Optional)
  → ASO: Incremental aggregate view update
  → BSO: Internal CALC DIM aggregation
```

---

## Common Data Movement Patterns

### Pattern 1: BSO → ASO Reporting Push

```
Source: FinPlan (BSO) — where planners enter data
Target: OEP_REP (ASO) — reporting/dashboard cube
Trigger: Smart Push on form save OR nightly scheduled job
Why: ASO provides fast ad-hoc retrieval across large dimensions
```

### Pattern 2: Cross-Module Data Sharing

```
Workforce Module → FinPlan:
  Headcount, Salary costs pushed from Manpower to financial P&L

Capital Module → FinPlan:
  Depreciation expense pushed from Capital to financial statements

FinPlan → Projects:
  Revenue allocations distributed to project-level tracking
```

### Pattern 3: Actuals Integration

```
ERP (Oracle Fusion) → Data Integration → FinPlan (BSO)
  Monthly GL balances loaded via flat file or direct connector

FinPlan (BSO) → Smart Push → OEP_REP (ASO)
  Actuals available for ad-hoc reporting within seconds of load
```

`[Illustrative]`

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Smart Push takes 30+ seconds | Use Form Context not checked → macro-slice | Check "Use Form Context" in form designer |
| Target data shows stale values | Smart Push not triggered on save | Enable "Run On Save" in form Smart Push settings |
| "Insufficient privileges" error | User lacks write access to target cube | Grant appropriate access to target cube/members |
| Data appears doubled in target | Clear Target Data not enabled | Enable "Clear Target Data" or use Replace mode |
| @XREF returns #MISSING | Target member name mismatch or cube not refreshed | Verify member exists in target; refresh target cube |
| Timeout during large push | Too many cells in single push | Break into smaller Data Map scopes; use background mode |

---

## Quick Recall

1. **Why are Data Maps faster than @XREF/@XWRITE?**
   → Data Maps use bulk MDX extraction and load buffer streaming (100K+ cells/sec) vs @XREF's point-by-point network calls (500–2,500 cells/sec).

2. **What does "Use Form Context" do in Smart Push?**
   → Limits the data push to only the members visible on the current form, reducing millions of potential cells down to just what the user is working with.

3. **When would you still use @XREF instead of a Data Map?**
   → For point-reference lookups within a member formula or calculation script where you need one value from another cube, not bulk movement.

---

**Next:** [EPM Automate](../12_EPM_Automate/01_EPM_Automate_Complete_Guide.md) — automating data loads, refreshes, and administrative tasks

