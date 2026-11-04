# Oracle EPM Cloud — Data Maps & Smart Push Master Guide

## Overview

**Data Maps** and **Smart Push** are the primary GUI-based tools in Oracle EPM Cloud for moving data between plan types (cubes). While `@XWRITE` is a programmatic calc-script approach, Data Maps provide a **visual, configuration-driven** way to define source-to-target dimension mappings and move data — without writing a single line of Essbase script.

They share the same underlying mapping definition but serve different operational purposes:

- **Data Maps** = Batch-oriented, full-scope data push (scheduled or manual)
- **Smart Push** = Delta-oriented, real-time data push (triggered on form save)

### Why Do These Exist—

EPM applications typically have multiple plan types:

| Plan Type | Purpose | Storage |
|-----------|---------|---------|
| **FinStmt** (BSO) | Financial statements, P&L, input | Block Storage |
| **Workforce** (BSO) | Headcount, compensation planning | Block Storage |
| **Revenue** (BSO) | Detailed revenue by product/customer | Block Storage |
| **Capital** (BSO) | Capital expenditure, depreciation | Block Storage |
| **Reporting** (ASO) | High-performance reporting, dashboards | Aggregate Storage |

Users input data into BSO cubes. But reporting cubes (ASO) need that data too. And different BSO cubes need to share data with each other. Data Maps and Smart Push bridge these cubes.

### When to Use What

| Scenario | Use |
|----------|-----|
| User saves a form and target cube needs immediate update | **Smart Push** (Run on Save) |
| Nightly sync of full data between cubes | **Data Map** (scheduled job) |
| Bulk data movement after a business rule runs | **Data Map** (via Groovy) |
| Real-time calculation-based transformation while moving | **@XWRITE** (calc script) |
| Complex member-to-member remapping with visual UI | **Data Map** (Advanced mapping) |
| Simple push of same-named members, small scope | **Smart Push** |

---

## Category

**System Administration / Data Exchange / Data Movement**

---

## 🔗 Core Concept: Data Maps

### What Is a Data Map—

A Data Map is a **reusable mapping definition** that specifies:
1. **Source cube** — where data comes from
2. **Target cube** — where data goes to
3. **Dimension mappings** — how source dimensions map to target dimensions
4. **Member mappings** — how individual members map (when names differ)
5. **Options** — what to copy (comments, attachments, supporting detail)

A Data Map is **not an execution** — it's a **blueprint**. You can execute it manually, on schedule, or via Groovy.

### Creating a Data Map

**Navigation**: Application → Data Exchange → Data Maps → Create

**Steps**:
1. Select **Source Cube** (e.g., `FinStmt`)
2. Select **Target Cube** (e.g., `Reporting`)
3. System auto-maps **same-named dimensions**
4. You manually map any remaining **unmapped dimensions**
5. Define **member selections** for each dimension (scope)
6. Configure **options** (comments, attachments, supporting detail)
7. Save the Data Map

---

## ⚡ Deep Dive: How Dimension Mapping Works in Data Maps

### Auto-Mapping vs. Manual Mapping

When you create a Data Map, the system automatically maps dimensions that have the **same name** in both source and target. Dimensions that don't match are placed in the **Unmapped Dimensions** list.

```
SOURCE CUBE (FinStmt BSO):               TARGET CUBE (Reporting ASO):
├── Account  ──── AUTO-MAPPED ──────────► Account
├── Entity   ──── AUTO-MAPPED ──────────► Entity
├── Period   ──── AUTO-MAPPED ──────────► Period
├── Year     ──── AUTO-MAPPED ──────────► Year
├── Scenario ──── AUTO-MAPPED ──────────► Scenario
├── Version  ──── AUTO-MAPPED ──────────► Version
├── Currency ──── AUTO-MAPPED ──────────► Currency
├── Product  ← UNMAPPED (not in target—)  
                                          ├── Department ← UNMAPPED (not in source—)
```

### Three Types of Dimension Relationships

#### Type 1: Matched Dimensions (Same Name, Same Members)

```
Source: Account                    Target: Account
├── Revenue                        ├── Revenue           ← same member
├── COGS                           ├── COGS              ← same member
├── Net_Income                     ├── Net_Income        ← same member
```

**Mapping**: Automatic. Members flow directly. No configuration needed.

#### Type 2: Matched Dimensions (Same Name, Different Members)

```
Source: Account                    Target: Account
├── Rev_Detail_001                 ├── Revenue_Summary
├── Rev_Detail_002                 ├── COGS_Summary
├── Rev_Detail_003                 
```

**Mapping**: Requires **member mapping rules** to translate source members to target members. See the Member Mapping section below.

#### Type 3: Unmatched Dimensions (Exists Only in One Cube)

```
Source: Product (ONLY in source)   Target: Department (ONLY in target)
├── Product_A                      ├── HR
├── Product_B                      ├── Finance
├── Product_C                      ├── IT
```

**Mapping**: You must decide how to handle these:
- **Source-only dimension** → You select which member(s) to push from. This controls what VALUE is read (same concept as FIX on source-only dims in @XWRITE)
- **Target-only dimension** → You must specify which member(s) to push TO. This controls WHERE data lands (same concept as mbrList for target-only dims in @XWRITE)

---

### How Data Maps Handle Different Dimensions — The Complete Picture

This is the **same Revenue Detail → FinStmt scenario** we covered in @XWRITE, but now through the Data Map lens:

```
SOURCE CUBE (Revenue Detail BSO):        TARGET CUBE (Reporting ASO):
├── Account  ─────── MAPPED ──────────── Account
├── Entity   ─────── MAPPED ──────────── Entity
├── Period   ─────── MAPPED ──────────── Period
├── Year     ─────── MAPPED ──────────── Year
├── Customer ← SOURCE ONLY              ├── Scenario ← TARGET ONLY
├── Channel  ← SOURCE ONLY              ├── Product  ← TARGET ONLY
                                         ├── Currency ← TARGET ONLY
```

#### In the Data Map UI, you configure:

**For mapped dimensions** (Account, Entity, Period, Year):
- Select which members to include in the push
- e.g., Account: `ILvl0Descendants(Total_Account)` — push all level-0 accounts
- e.g., Entity: `ILvl0Descendants(Total Entity)` — push all level-0 entities

**For source-only dimensions** (Customer, Channel):
- Select which member level to push FROM
- e.g., Customer: `Total_Customer` — push the aggregated total
- or Customer: `ILvl0Descendants(Total_Customer)` — push each individual customer

**For target-only dimensions** (Scenario, Product, Currency):
- Select which SINGLE member to push TO
- e.g., Scenario: `Actual`
- e.g., Product: `No_Product`
- e.g., Currency: `USD`

> **Key Insight**: This is exactly the same logic as @XWRITE's three-tier precedence, but configured visually instead of programmatically:
> - Source-only dims → like FIX in @XWRITE (controls what value is read)
> - Target-only dims → like mbrList in @XWRITE (controls where value lands)
> - Mapped dims → like POV in @XWRITE (flows automatically)

---

## 🔍 Deep Dive: Member Mapping Types

When member names differ between source and target, you need **member mapping rules**. Data Maps support several types:

### Mapping Type 1: Explicit Mapping

Maps a specific source member to a specific target member.

| Source Member | → | Target Member |
|---------------|---|---------------|
| `Rev_001` | → | `Revenue_Line1` |
| `Rev_002` | → | `Revenue_Line2` |
| `Cost_001` | → | `COGS_Line1` |

**Use when**: Member names are completely different and you need 1-to-1 translation.

### Mapping Type 2: "Like" Mapping (Pattern/Wildcard)

Uses pattern matching to translate member names.

| Pattern | Source Example | Target Result |
|---------|---------------|---------------|
| Replace `BSO_` with `ASO_` | `BSO_Revenue` | `ASO_Revenue` |
| Replace `_Input` with `_Report` | `Sales_Input` | `Sales_Report` |

**Use when**: Source and target members follow a naming convention with a predictable prefix/suffix difference.

### Mapping Type 3: "In" Mapping (Many-to-One)

Maps multiple source members to one target member.

| Source Members | → | Target Member |
|----------------|---|---------------|
| `Rev_Prod_A`, `Rev_Prod_B`, `Rev_Prod_C` | → | `Total_Revenue` |
| `Cost_Labor`, `Cost_Material`, `Cost_Overhead` | → | `Total_COGS` |

**Use when**: You need to consolidate detail members into a summary member.

> ⚠️ **Important**: When multiple source members map to one target member, the values are **summed** in the target. This IS a form of aggregation, but it happens during the Data Map push process, not via an explicit `AGG` command.

### Mapping Type 4: "Between" Mapping (Range)

Maps a range of source values to a single target value.

| Source Range | → | Target Member |
|-------------|---|---------------|
| Members between `Acct_100` and `Acct_199` | → | `Revenue_Summary` |
| Members between `Acct_200` and `Acct_299` | → | `Expense_Summary` |

**Use when**: Source members follow a numeric or alphabetical range pattern.

### Mapping Type 5: Multi-Dimension Mapping

Maps based on combinations of multiple source dimensions to target dimensions.

| Source Account | Source Entity | → | Target Account |
|----------------|---------------|---|----------------|
| `Revenue` | `East` | → | `Revenue_East` |
| `Revenue` | `West` | → | `Revenue_West` |
| `COGS` | `East` | → | `COGS_East` |

**Use when**: The target has a "flattened" structure where one dimension combines what were two dimensions in the source.

> This is also used for the reverse — splitting one source dimension into two target dimensions.

### Target Expressions (Alternative to Member Mapping)

For large-scale mappings, Oracle recommends **Target Expressions** over member mappings for better performance:

| Expression | What It Does | Example |
|------------|-------------|---------|
| **Copy Source Value** | Target member name = source member name | `Revenue` → `Revenue` |
| **Prefix** | Adds a prefix to source member name | `Revenue` → `ASO_Revenue` |
| **Suffix** | Adds a suffix to source member name | `Revenue` → `Revenue_RPT` |
| **Substring** | Extracts part of the source member name | `BSO_Revenue_Line` → `Revenue` |

---

## ⚠️ Deep Dive: Does Data Map Aggregate Automatically—

**This is the same question we answered for @XWRITE — and the answer is the same: NO.**

Data Maps read whatever value exists at the source intersection. They do NOT trigger an aggregation.

### The Behavior Depends on Source Member Storage Type

| Source Member Type | What Data Map Reads | Correct— |
|--------------------|--------------------|---------| 
| **Dynamic Calc (parent)** | ✅ Calculates on-the-fly → correct aggregated value | ✅ Yes — always current |
| **Stored (parent, freshly aggregated)** | ✅ Reads the stored aggregated value | ✅ Yes — if nothing changed |
| **Stored (parent, stale — data changed since last AGG)** | ❌ Reads the OLD stored value | ❌ No — stale data pushed! |
| **Stored (parent, never aggregated)** | ❌ Reads #MISSING | ❌ No — nothing pushed |
| **Level-0 stored member** | ✅ Reads the input value directly | ✅ Yes — always correct |

### Scenario: Pushing Parent Data to Target

```
Source: Entity (BSO)                    Target: Entity (ASO)
Total Entity (Stored) → 1000 (stale)   Total Entity → receives 1000 (wrong!)
├── East (Stored) → 400                ├── East → receives 400 (correct)
├── West (Stored) → 350                ├── West → receives 350 (correct)
├── Central (Stored) → 350             ├── Central → receives 350 (correct)
                                        Sum = 1100, but parent shows 1000!
```

**What happened—**: A user changed East from 300 to 400 after the last `AGG`. The children are correct (they're level-0 input), but `Total Entity` still holds the old sum (1000). The Data Map pushed 1000, not 1100.

**Fix**: Always aggregate before pushing if your source parents are Stored:

```
Step 1: Run business rule with AGG or CALC DIM
Step 2: Execute Data Map
```

### If Source Parents Are Dynamic Calc (Most Common in EPM Cloud)

```
Source: Entity (BSO)                    Target: Entity (ASO)
Total Entity (Dynamic Calc) → 1100     Total Entity → receives 1100 ✅
├── East (Stored) → 400                ├── East → receives 400 ✅
├── West (Stored) → 350                ├── West → receives 350 ✅
├── Central (Stored) → 350             ├── Central → receives 350 ✅
```

Dynamic Calc parents always compute on-the-fly, so the Data Map always reads the correct value. This is why EPM Cloud applications typically use Dynamic Calc for parents.

### What About Writing TO Parents in the Target—

Same rules as @XWRITE:

| Target Member Type | What Happens |
|--------------------|-------------|
| **ASO cube** | ASO handles parent aggregation differently — parents are aggregated dynamically during queries. Data is typically pushed to level-0 only. Pushing to upper-level members in ASO can create "input data" at that level. |
| **BSO Stored parent** | Value is written directly. May conflict with later AGG. |
| **BSO Dynamic Calc parent** | Write is silently ignored — not persisted. |

> **Best Practice for ASO targets**: Push only **level-0 members** to the ASO cube. Let ASO's natural aggregation handle the parents during query time. This is the intended architecture.

---

## 🎯 Deep Dive: Data Maps vs. Smart Push — Execution Behavior

### Data Maps (Batch Execution)

```
┌─────────────────────────────────────────────────────────────┐
│                  DATA MAP EXECUTION FLOW                     │
│                                                             │
│  Step 1: CLEAR target intersection (if clear=true)          │
│          └── Removes ALL existing data in the target scope  │
│                                                             │
│  Step 2: EXPORT source data                                 │
│          └── Reads values from source cube at mapped scope  │
│                                                             │
│  Step 3: TRANSFORM (apply member mappings)                  │
│          └── Translates source members → target members     │
│                                                             │
│  Step 4: IMPORT to target cube                              │
│          └── Loads transformed data into target             │
│                                                             │
│  Result: Target is an EXACT MIRROR of source for the scope  │
└─────────────────────────────────────────────────────────────┘
```

**Key behavior**: Data Maps perform a **clear + reload** by default. This means:
- ✅ Target is always consistent with source after execution
- ⚠️ Any data in the target scope that DOESN'T exist in the source is **deleted**
- ⚠️ During the clear phase, the target data is temporarily missing (brief gap)

### Smart Push (Delta Execution)

```
┌─────────────────────────────────────────────────────────────┐
│                  SMART PUSH EXECUTION FLOW                   │
│                                                             │
│  Step 1: IDENTIFY changed cells                             │
│          └── Detect which cells the user modified on save   │
│                                                             │
│  Step 2: DETERMINE scope                                    │
│          └── Changed cells + their parent rollups           │
│                                                             │
│  Step 3: CLEAR only the affected slice in target            │
│          └── Narrow clear — only the impacted intersection  │
│                                                             │
│  Step 4: PUSH the delta to target                           │
│          └── Load only the changed data + parent values     │
│                                                             │
│  Result: Target is INCREMENTALLY UPDATED (merge behavior)   │
└─────────────────────────────────────────────────────────────┘
```

**Key behavior**: Smart Push performs a **narrow clear + delta load**. This means:
- ✅ Only modified data is pushed — very fast for small changes
- ✅ Existing data outside the change scope is **preserved**
- ⚠️ Not suitable for large-scale changes (>250K cells)
- ⚠️ Doesn't guarantee full consistency — only the delta is pushed

### Side-by-Side Comparison

| Aspect | Data Map | Smart Push |
|--------|----------|------------|
| **Trigger** | Manual, scheduled, or Groovy | On form save ("Run on Save") |
| **Scope** | Entire mapping scope (bulk) | Only changed cells + parents (delta) |
| **Clear behavior** | Clears ENTIRE target scope, then reloads | Clears ONLY the changed slice |
| **Data consistency** | ✅ Full — target mirrors source exactly | ⚠️ Incremental — only delta is current |
| **Performance** | Slower (bulk), but reliable | Faster (delta), but limited scale |
| **Max recommended cells** | Millions (batch job) | ~250,000 cells max |
| **Comments/Attachments** | ✅ Configurable | ✅ Configurable |
| **Supporting Detail** | ✅ Only 1-to-1 mappings | ✅ Only 1-to-1 mappings |
| **User security** | Runs as admin/service account | Runs under saving user's security |
| **Best for** | Nightly sync, full refresh, post-rule push | Real-time form saves, small edits |

---

## 🔧 Configuring Smart Push on a Form

### Step-by-Step Setup

1. **Create a Data Map** first (Application → Data Exchange → Data Maps)
2. **Open Form Designer** for your BSO input form
3. Go to the **Smart Push** tab
4. Click **Add** → select the Data Map you created
5. Configure the scope:

### Scope Options

| Option | What It Does |
|--------|-------------|
| **Use Form Context** | Dynamically scopes the push based on the form's rows, columns, POV, and page selections. The members currently visible in the form define the push scope. |
| **Manual Selection** | You manually specify which members to push, independent of the form layout. More predictable but less flexible. |

### "Use Form Context" — How It Works

```
Form Layout:
  POV: FY25, Actual
  Page: East
  Rows: Account members
  Columns: Jan, Feb, Mar

Smart Push scope = East, FY25, Actual, [all row accounts], Jan+Feb+Mar
```

When the user saves:
- Smart Push identifies which cells changed within this scope
- Pushes only those changed cells + their parent rollups
- If the user switches the Page to "West" and saves, only West data is pushed

> ⚠️ **Hidden segments**: If your form has hidden grids/segments, data from those hidden segments is STILL included in the push scope when "Use Form Context" is enabled. This can cause unexpected data movement.

### Security

Smart Push runs under the **saving user's security profile**:
- User must have read access to source members
- User must have write access to target members
- If user lacks access to certain members, those are silently excluded from the push

---

## 📋 Data Map Options

### What Else Can Be Copied—

| Option | Description | Requirement |
|--------|-------------|-------------|
| **Comments** | Cell-level comments attached to data cells | Can be collated (merged) or non-collated |
| **Attachments** | File attachments on cells | Can be collated or non-collated |
| **Supporting Detail** | Structured breakdown supporting a cell value | ⚠️ Only copied for **1-to-1 mappings** |

### Collation Settings

When multiple source cells map to one target cell:

| Setting | Behavior |
|---------|----------|
| **With Collate** | Comments/attachments from ALL source cells are combined into the target cell |
| **Without Collate** | Only the comments/attachments from the LAST source cell (with non-empty data) are copied |

### Zero and Missing Handling

> Data Maps and Smart Push **skip rows consisting entirely of zeros or #MISSING values**. These are not pushed to the target. This is important to understand — it means your target won't have explicit zeros; those cells will remain #MISSING in the target.

---

## 🔥 Complete Scenario: BSO Input → ASO Reporting

This is the most common Data Map use case in EPM Cloud.

### The Setup

```
SOURCE: FinStmt (BSO — Input)           TARGET: Reporting (ASO — Reporting)
├── Account  ──── MAPPED ───────────── Account
├── Entity   ──── MAPPED ───────────── Entity
├── Period   ──── MAPPED ───────────── Period
├── Year     ──── MAPPED ───────────── Year
├── Scenario ──── MAPPED ───────────── Scenario
├── Version  ──── MAPPED ───────────── Version
├── Currency ──── MAPPED ───────────── Currency
├── Product  ──── MAPPED ───────────── Product
```

All dimensions match. Members are identical. This is the simplest case.

### Data Map Configuration

| Dimension | Source Selection | Target Selection |
|-----------|-----------------|-----------------|
| Account | `ILvl0Descendants(Total_Account)` | Same (auto-mapped) |
| Entity | `ILvl0Descendants(Total Entity)` | Same (auto-mapped) |
| Period | `ILvl0Descendants(Year Total)` | Same (auto-mapped) |
| Year | `FY25` | Same (auto-mapped) |
| Scenario | `Actual, Budget, Forecast` | Same (auto-mapped) |
| Version | `Working` | Same (auto-mapped) |
| Currency | `USD` | Same (auto-mapped) |
| Product | `ILvl0Descendants(Total Product)` | Same (auto-mapped) |

### Execution Flow

```
1. CLEAR: Remove all data in Reporting ASO at:
   FY25, (Actual+Budget+Forecast), Working, USD,
   all level-0 accounts × entities × periods × products

2. EXPORT: Read all values from FinStmt BSO at same intersections

3. LOAD: Insert all values into Reporting ASO

4. ASO cube now has fresh data — parents aggregate dynamically on query
```

### Smart Push on Form Save

A user opens a BSO form for `East, FY25, Actual, Jan`:

```
                    Jan
Revenue             500  ← user changes from 450 to 500
COGS               -200
Gross Profit        300  (Dynamic Calc)
```

When user saves:
1. Smart Push detects: `Revenue, East, Jan, FY25, Actual` changed
2. Pushes the new value (500) + parent rollups to ASO Reporting
3. ASO Reporting now shows 500 for that intersection immediately

---

## 🔥 Complete Scenario: Different Dimensions (BSO Workforce → ASO Reporting)

### The Setup

```
SOURCE: Workforce (BSO):                TARGET: Reporting (ASO):
├── Account  ──── MAPPED ───────────── Account
├── Entity   ──── MAPPED ───────────── Entity
├── Period   ──── MAPPED ───────────── Period
├── Year     ──── MAPPED ───────────── Year
├── Scenario ──── MAPPED ───────────── Scenario
├── Grade    ← SOURCE ONLY             ├── Product  ← TARGET ONLY
├── Position ← SOURCE ONLY             ├── Currency ← TARGET ONLY
```

### Data Map Configuration

| Dimension | Type | Configuration | What Happens |
|-----------|------|---------------|-------------|
| Account | Mapped | Source: `Headcount, Salary, Benefits` → Target: same names | Members flow directly |
| Entity | Mapped | Source: `ILvl0Descendants(Total Entity)` → Target: same | Members flow directly |
| Period | Mapped | Source: `ILvl0Descendants(Year Total)` → Target: same | Members flow directly |
| Year | Mapped | Source: `FY25` → Target: `FY25` | Direct mapping |
| Scenario | Mapped | Source: `Actual` → Target: `Actual` | Direct mapping |
| **Grade** | **Source only** | Source: `Total_Grade` (aggregated) | ⬅️ Controls WHAT VALUE is read |
| **Position** | **Source only** | Source: `Total_Position` (aggregated) | ⬅️ Controls WHAT VALUE is read |
| **Product** | **Target only** | Target: `No_Product` | ➡️ Controls WHERE data lands |
| **Currency** | **Target only** | Target: `USD` | ➡️ Controls WHERE data lands |

### What Gets Pushed (Conceptually)

```
For each entity (East, West, Central...) × each period (Jan, Feb...) × each account:

SOURCE READ:  Workforce → Headcount, East, Jan, FY25, Actual, Total_Grade, Total_Position
              Value = 45 (total headcount across all grades and positions)

TARGET WRITE: Reporting → Headcount, East, Jan, FY25, Actual, No_Product, USD
              Value = 45
```

### Same Golden Rule as @XWRITE

```
┌──────────────────────────────────────────────────────────────────┐
│          DATA MAPS FOLLOW THE SAME LOGIC AS @XWRITE              │
│                                                                  │
│  Source-only dims (Grade, Position):                              │
│    Your selection controls WHAT VALUE is read from source         │
│    → "Total_Grade" reads aggregated value                        │
│    → "Grade_1" reads only that grade's value                     │
│                                                                  │
│  Target-only dims (Product, Currency):                           │
│    Your selection controls WHERE VALUE lands in target            │
│    → "No_Product" lands at No_Product                            │
│    → Must specify SOMETHING — there's no "auto" for these        │
│                                                                  │
│  Mapped dims (Account, Entity, Period, Year, Scenario):          │
│    Members flow automatically from source → target               │
│    → Same member names map directly                              │
│    → Different names need member mapping rules                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🤖 Groovy Automation for Data Maps

### Basic Execution

```groovy
// Execute a Data Map with clear data enabled
String dataMapName = "FinStmt_to_Reporting"

if (operation.application.hasDataMap(dataMapName)) {
    operation.application.getDataMap(dataMapName).execute(true)
    // true = clear target data before push
    // false = merge (no clear, push only)
} else {
    println("Data Map '${dataMapName}' not found.")
}
```

### Execute with Member Overrides

```groovy
// Override the Data Map's default scope to push only specific members
String dataMapName = "FinStmt_to_Reporting"

Map<String, String> overrides = [
    "ACCOUNT"  : "ILvl0Descendants(Total_Account)",
    "ENTITY"   : "East",
    "YEARS"    : "FY25",
    "PERIOD"   : "Jan,Feb,Mar",
    "SCENARIO" : "Actual"
]

if (operation.application.hasDataMap(dataMapName)) {
    operation.application.getDataMap(dataMapName).execute(overrides, true)
}
```

### Conditional: Smart Push for Small Changes, Data Map for Large

```groovy
// Smart conditional logic
int changedCells = operation.grid.getModifiedCellCount()

if (changedCells < 1000) {
    // Small change — use Smart Push (fast delta)
    operation.application.getDataMap("FinStmt_to_Reporting").executeSmartPush()
} else {
    // Large change — use full Data Map (reliable batch)
    operation.application.getDataMap("FinStmt_to_Reporting").execute(true)
}
```

### Execute Data Map After Business Rule

```groovy
// Common pattern: Run calculation, then push results
// Step 1: The business rule runs (this Groovy is part of the rule)
// ... calculation logic ...

// Step 2: Push results to reporting cube
operation.application.getDataMap("FinStmt_to_Reporting").execute(true)
println("Data Map executed successfully — data pushed to Reporting cube.")
```

### Clear Data Parameter Explained

| Parameter | Behavior | When to Use |
|-----------|----------|-------------|
| `execute(true)` | **Clear target scope first**, then load source data | Full refresh — ensures target exactly mirrors source |
| `execute(false)` | **No clear** — merge source data into existing target data | Incremental updates — preserves existing target data not in source |

> ⚠️ **Critical**: `execute(true)` clears ALL data in the target scope defined by the Data Map, not just the data that came from the source. If other processes also write to the same target scope, their data will be wiped.

---

## 🆚 Complete Comparison: @XWRITE vs. Data Maps vs. Smart Push vs. DATACOPY

| Feature | @XWRITE | Data Map | Smart Push | DATACOPY |
|---------|---------|----------|------------|----------|
| **Type** | Calc script function | GUI configuration | GUI + auto-trigger | Calc script command |
| **Configuration** | Written in code | Visual UI | Uses Data Map definition | Written in code |
| **Execution** | During calculation | Manual / scheduled / Groovy | On form save | During calculation |
| **Transformation** | ✅ Full calc logic (IF, formulas) | ✅ Member mappings | ❌ No transformation | ❌ Simple copy only |
| **Dimension mapping** | Manual (via mbrList) | Visual UI (auto-map + manual) | Via Data Map | Same structure only |
| **Different outlines** | ✅ Yes | ✅ Yes | ✅ Yes (via Data Map) | ❌ Must be same structure |
| **Aggregation** | ❌ No auto-aggregation | ❌ No auto-aggregation | ❌ No auto-aggregation | ❌ No auto-aggregation |
| **Clear target** | ❌ No (overwrites cell-by-cell) | ✅ Optional (clear + reload) | ✅ Narrow clear (delta only) | ❌ No (overwrites) |
| **BSO → BSO** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **BSO → ASO** | ❌ No | ✅ Yes | ✅ Yes | ❌ No |
| **ASO → BSO** | ❌ No | ❌ No | ❌ No | ❌ No |
| **Same cube** | ✅ Yes (@LOOPBACK) | ❌ No | ❌ No | ✅ Yes |
| **Performance** | Slow (per-cell write) | Fast (bulk export/import) | Fast (delta) | Fast (bulk) |
| **Max scale** | Thousands of cells | Millions of cells | ~250K cells | Millions of cells |
| **Comments/Attachments** | ❌ No | ✅ Yes | ✅ Yes | ❌ No |
| **Supporting Detail** | ❌ No | ✅ (1-to-1 only) | ✅ (1-to-1 only) | ❌ No |
| **Security** | Runs as rule owner | Configurable | User who saves | Runs as rule owner |
| **Groovy control** | Via calc script | ✅ Full API | ✅ Via Groovy | Via calc script |

### When to Use What — Decision Guide

```
Do you need real-time transformation logic (IF, formulas)—
  └── YES → @XWRITE

Is the data movement BSO → ASO—
  └── YES → Data Map or Smart Push (not @XWRITE or DATACOPY)

Is it triggered by a user saving a form—
  └── YES → Smart Push (on form save)

Is it a large-scale nightly/scheduled sync—
  └── YES → Data Map (batch job)

Is it within the same cube, same structure—
  └── YES → DATACOPY (fastest)

Do you need to copy Comments/Attachments—
  └── YES → Data Map or Smart Push
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| **Not aggregating before Data Map push** | Stored parents may hold stale values | Run `AGG` or `CALC DIM` before Data Map execution |
| **Smart Push on large-scale rule** | Copy Version rule changes 500K cells → Smart Push chokes | Use Groovy to trigger a Data Map instead for bulk changes |
| **Forgetting target-only dimensions** | Data Map requires you to specify a member for target-only dims | Always configure target-only dimensions explicitly |
| **Pushing to Dynamic Calc members in BSO** | Values are not persisted | Ensure target members are stored |
| **Pushing parents to ASO** | Creates "input" data at parent level, conflicting with ASO aggregation | Push only level-0 members to ASO; let ASO aggregate dynamically |
| **execute(true) wiping shared target data** | Clear removes ALL data in scope, including data from other sources | Use `execute(false)` for merge, or narrow the scope with overrides |
| **Not synchronizing after metadata changes** | Adding new members without syncing the Data Map causes errors | Always Actions → Synchronize after dimension changes |
| **Hidden form segments in Smart Push** | "Use Form Context" includes hidden segments | Switch to manual selection or remove hidden segments |
| **Rows of all zeros skipped** | Data Maps skip rows that are entirely zero or #MISSING | If you need zeros in the target, you may need a different approach |
| **Smart Push under user security** | User without target access silently misses members | Verify user has access to both source and target members |

---

## ⚠️ Performance Considerations

| Consideration | Recommendation |
|---------------|----------------|
| Push level-0 only to ASO | Let ASO aggregate; don't push parents |
| Use Target Expressions over Member Mappings | Target Expressions are more efficient for large-scale pushes |
| Narrow your Data Map scope | Don't push all years/scenarios if you only need the current one |
| Schedule Data Maps during off-hours | Batch jobs can lock cubes; run during maintenance windows |
| Smart Push < 250K cells | Beyond this, use a Data Map triggered via Groovy |
| Aggregate before push if source has stored parents | Ensures correct values are pushed |
| Use overrides in Groovy | Override Data Map scope to push only what changed |

---

## 🔄 Data Map Synchronization

When the outline (metadata) of your source or target cube changes — new members added, members renamed, hierarchy restructured — you **must synchronize** the Data Map:

**Navigation**: Application → Data Exchange → Data Maps → select map → Actions → **Synchronize**

### What Synchronize Does

1. Re-reads the source and target outlines
2. Updates the dimension and member lists in the Data Map
3. Validates existing mappings against the new outlines
4. Flags any broken mappings (e.g., a mapped member was deleted)

### When to Synchronize

| Event | Need Sync— |
|-------|-----------|
| New member added to source or target | ✅ Yes |
| Member renamed | ✅ Yes |
| Member deleted | ✅ Yes — existing mapping will break |
| Hierarchy restructured | ✅ Yes |
| Data loaded (no metadata change) | ❌ No |
| Business rule changed | ❌ No |

> ⚠️ **Failure to synchronize** after metadata changes is one of the most common causes of Data Map errors. The Data Map caches the outline at the time of creation — if the outline changes, the cache is stale.

---

## Related Concepts

| Concept | Relationship |
|---------|-------------|
| [`@XWRITE`](../../Calc%20Manager/Calc%20Managers%20all%20business%20Rule%20Functions/05_Data_Access/@XWRITE.md) | Programmatic cross-database write — alternative to Data Maps |
| [`@XREF`](../../Calc%20Manager/Calc%20Managers%20all%20business%20Rule%20Functions/05_Data_Access/@XREF.md) | Programmatic cross-database read |
| **DATACOPY** | Bulk copy within same structure (no dimension mapping) |
| **Data Integration** | ETL-style data movement with scheduling and external sources |
| **Groovy Rules** | Programmatic control of Data Map/Smart Push execution |

---

## Official Oracle Reference

- [Managing Data Maps](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/managing_data_maps.html)
- [Working with Smart Push](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/smart_push.html)
- [Data Map Dimension Mapping](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/data_map_dimension_mapping.html)
