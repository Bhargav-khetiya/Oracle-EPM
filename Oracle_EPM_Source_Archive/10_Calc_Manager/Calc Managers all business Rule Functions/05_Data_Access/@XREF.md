# @XREF

## Overview

`@XREF` is a **cross-database reference function** in Oracle EPM Cloud (PBCS/EPBCS) and Essbase that **retrieves a data value from another database** (plan type or cube). It enables calculations that pull data across plan types — for example, reading workforce headcount from the Workforce plan type into the Financial plan type for per-employee calculations.

`@XREF` is the **read counterpart** of `@XWRITE` — while @XWRITE pushes data to another plan type, @XREF pulls data from one. Like @XWRITE, it does **not impose strict dimension mapping restrictions**, meaning the source and target outlines can be different.

### Why Does This Function Exist—

EPM applications typically have multiple plan types (cubes) that store different categories of data:
- **FinStmt** (Financial Statements): Revenue, expenses, P&L
- **Workforce**: Headcount, salary, benefits
- **Revenue**: Detailed revenue planning by product/customer
- **Capital**: Capital expenditure planning
- **Rates**: Exchange rates, tax rates

Business rules often need to combine data from multiple plan types. @XREF bridges these databases by allowing a calculation in one cube to read values from another.

### When to Use It

- To pull headcount from Workforce into FinStmt for per-employee calculations
- To bring detailed revenue from Revenue plan type into FinStmt
- To read capital depreciation from Capital plan type into FinStmt
- To cross-reference exchange rates from a rates cube
- To look up a single rate/factor from another plan type to use in a formula
- Any calculation that needs data from a different plan type

---

## Category

**Data Access / Cross-Database / Read**

---

## Syntax

There are multiple ways to call this function, depending on your deployment:

### Syntax 1 — Using Location Alias (Remote or Cross-Server)

```essbase
@XREF(locationAlias [, mbrList])
```

Use this when the source (data) cube is on a **different Essbase server**. A location alias is a predefined connection that specifies server, application, cube, username, and password. The location alias must be set on the cube where the calculation runs.

### Syntax 2 — Using App/Cube Name (Same Server)

```essbase
@XREF(appName, dbName [, mbrList])
```

Use this when source and target are on the **same Essbase server instance**.

### Syntax 3 — EPM Cloud / Calc Manager (Same Application)

```essbase
@XREF("planTypeName" [, memberOverride1, memberOverride2, ...])
```

In EPM Cloud, plan types are databases within the same application. You simply reference the plan type name in quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `locationAlias` | String | ✅ (Syntax 1) | A location alias pointing to the remote cube. Set by the administrator — specifies server, application, cube, username, and password. The same alias can be shared by `@XREF` and `@XWRITE`. For `@XREF`, it represents the **data source**. |
| `appName, dbName` | Strings | ✅ (Syntax 2) | Application and cube name. Use only when source and target are on the same Essbase server instance. |
| `planTypeName` | String | ✅ (Syntax 3) | The name of the source plan type in EPM Cloud (e.g., `"Workforce"`, `"Revenue"`, `"Capital"`). |
| `mbrList` | Member name(s) | ❌ No | Optional comma-delimited list of member names from the source cube. These override the automatic dimension mapping. See the **Dimension Mapping Deep Dive** section for complete details. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Valid intersection with data | Numeric value from the source database |
| Valid intersection, no data | `#MISSING` |
| Invalid member mapping (member doesn't exist in source) | Calculation error |

**Return Type**: Numeric (double-precision floating point)

---

## ⚡ Deep Dive: How @XREF Works (Behind the Scenes)

### Execution Flow

```
1. Script runs on the LOCAL cube (the "calculation cube")
2. FIX statement scopes which data blocks to iterate
3. For each cell in the FIX scope:
   a. Determine the source intersection using mapping rules
   b. Reach out to the REMOTE/SOURCE cube
   c. Read the value at that intersection
   d. Return the value into the local formula
4. Local formula uses the returned value for calculation
```

### Key Mechanics

1. **Top-Down Formula**: @XREF is a **top-down formula**. This means it calculates parent values first, then children — the opposite of the default bottom-up calculation order. This has significant performance implications (see Performance section).

2. **Per-Cell Lookup**: Every time @XREF fires, it performs a **cross-database read** for that specific cell intersection. If your FIX iterates over 100,000 cells, @XREF fires 100,000 times — each one is a separate lookup to the source cube.

3. **Read-Only**: @XREF **only reads** from the source. It cannot modify the source database. To write, use `@XWRITE`.

4. **Inline Usage**: @XREF returns a value, so it can be used **anywhere a numeric expression is valid** — in formulas, IF conditions, variable assignments, as an argument to other functions, etc.

5. **Calculation Scripts and Outline Formulas**: @XREF can be used in both calculation scripts and outline member formulas.

6. **BSO Only**: This function is applicable only to **block storage (BSO)** cubes. However, it can read FROM an ASO cube under certain conditions.

---

## 🔗 Deep Dive: Dimension Mapping — How It Really Works

@XREF uses the **exact same three-tier precedence system** as @XWRITE, but in **reverse direction** — instead of determining where to WRITE, it determines where to READ FROM.

### The Three-Tier Mapping Precedence

```
┌─────────────────────────────────────────────────────────┐
│           PRIORITY 1: mbrList (Highest)                 │
│  Members explicitly specified in the @XREF call         │
│  These ALWAYS win — they override everything else       │
├─────────────────────────────────────────────────────────┤
│           PRIORITY 2: Current Point of View             │
│  Members currently being calculated on the local cube   │
│  Used for SHARED dimensions not overridden by mbrList   │
├─────────────────────────────────────────────────────────┤
│           PRIORITY 3: Top Member (Lowest/Fallback)      │
│  The topmost (root) member of unspecified dimensions    │
│  in the SOURCE cube. Used when a dimension exists in    │
│  the source but NOT in the local cube AND NOT in mbrList│
└─────────────────────────────────────────────────────────┘
```

### How This Works — Step by Step

When @XREF fires for a given cell, Essbase builds the source intersection (the "read address") as follows:

**Step 1** — Start with a blank intersection on the source cube (one slot per dimension).

**Step 2** — Fill in any dimensions specified in the `mbrList`. These are locked in.

**Step 3** — For any remaining empty slots, check the current Point of View (POV) on the local cube. If the local cube has a dimension with the **same name** as the source, the current member from that dimension fills the slot.

**Step 4** — If any slots are STILL empty (because the dimension exists in the source but not the local cube, and was not in mbrList), fill those with the **top member** of that dimension in the source outline.

### Key Difference from @XWRITE

| Aspect | @XREF | @XWRITE |
|--------|-------|---------|
| Direction | Builds intersection on the **SOURCE** (where to read) | Builds intersection on the **TARGET** (where to write) |
| Local cube role | The cube running the calculation (result consumer) | The cube running the calculation (data provider) |
| Remote cube role | The data source (provides the value) | The data target (receives the value) |
| "Unmatched dim" fallback | Top member of the **source** cube | Top member of the **target** cube |

### Visual Example: Local Has 5 Dims, Source Has 6 Dims

```
LOCAL CUBE (FinStmt — running calc):    SOURCE CUBE (Workforce — data source):
├── Account                              ├── Account
├── Entity                               ├── Entity
├── Period                               ├── Period
├── Year                                 ├── Year
├── Scenario                             ├── Scenario
                                         ├── Grade   ← ONLY in source
```

**Script running on FinStmt:**
```essbase
FIX("FY25", "Working", "East", "Jan")
    "Salary_Expense" = @XREF("Workforce", "Total_Compensation");
ENDFIX
```

**How the source intersection is built (where to READ from):**

| Source Dimension | In Local— | In mbrList— | Resolved From | Resolved Value |
|------------------|-----------|-------------|---------------|----------------|
| Account | ✅ Yes | ✅ Yes (`"Total_Compensation"`) | **mbrList** (Priority 1) | `Total_Compensation` |
| Entity | ✅ Yes | ❌ No | **POV** (Priority 2) | `East` |
| Period | ✅ Yes | ❌ No | **POV** (Priority 2) | `Jan` |
| Year | ✅ Yes | ❌ No | **POV** (Priority 2) | `FY25` |
| Scenario | ✅ Yes | ❌ No | **POV** (Priority 2) | `Working` |
| Grade | ❌ No | ❌ No | **Top Member** (Priority 3) | `Total_Grade` |

**Result**: @XREF reads `Workforce → Total_Compensation, East, Jan, FY25, Working, Total_Grade` and returns that value to the FinStmt formula.

### Visual Example: Both Cubes Have Unique Dimensions

```
LOCAL CUBE (FinStmt):                    SOURCE CUBE (Revenue Detail):
├── Account ──── SHARED ──────────────── Account
├── Entity  ──── SHARED ──────────────── Entity
├── Period  ──── SHARED ──────────────── Period
├── Year    ──── SHARED ──────────────── Year
├── Scenario  ← LOCAL ONLY              ├── Customer  ← SOURCE ONLY
├── Product   ← LOCAL ONLY              ├── Channel   ← SOURCE ONLY
├── Currency  ← LOCAL ONLY
```

**Script running on FinStmt:**
```essbase
FIX("FY25", "Actual", "East", "Jan", "All_Products", "USD")
    "Total_Revenue" = @XREF("Revenue", "Net_Revenue", "Total_Customer", "All_Channels");
ENDFIX
```

**How the source intersection is built:**

| Source Dimension | In Local— | In mbrList— | Resolved From | Resolved Value |
|------------------|-----------|-------------|---------------|----------------|
| Account | ✅ Yes | ✅ Yes (`"Net_Revenue"`) | **mbrList** (Priority 1) | `Net_Revenue` |
| Entity | ✅ Yes | ❌ No | **POV** (Priority 2) | `East` |
| Period | ✅ Yes | ❌ No | **POV** (Priority 2) | `Jan` |
| Year | ✅ Yes | ❌ No | **POV** (Priority 2) | `FY25` |
| Customer | ❌ No | ✅ Yes (`"Total_Customer"`) | **mbrList** (Priority 1) | `Total_Customer` |
| Channel | ❌ No | ✅ Yes (`"All_Channels"`) | **mbrList** (Priority 1) | `All_Channels` |

**What about Scenario, Product, Currency—** They exist **only in the local cube** — the source has no such dimensions. They are **completely irrelevant** to the source read. They are part of the local FIX (they scope which local cells get calculated), but the source has no corresponding dimension.

### Critical Insight: Local-Only Dimensions Are Irrelevant, Source-Only Dimensions Default to Top Member

| Scenario | What Happens |
|----------|-------------|
| Dimension exists in **both** local and source | Current POV member is used (unless overridden by mbrList) |
| Dimension exists **only in local** | Completely irrelevant — source has no slot for it |
| Dimension exists **only in source** | Falls back to **top member** of that dimension in the source (unless specified in mbrList) |
| Dimension exists in both but member names differ | **Error** — you must use mbrList to specify the correct source member |

---

### 🔥 Complete Scenario: Both Cubes Have Unique Dimensions (FinStmt reading from Revenue Detail)

```
LOCAL CUBE (FinStmt):                    SOURCE CUBE (Revenue Detail):
├── Account  ─────── SHARED ──────────── Account
├── Entity   ─────── SHARED ──────────── Entity
├── Period   ─────── SHARED ──────────── Period
├── Year     ─────── SHARED ──────────── Year
├── Scenario ← LOCAL ONLY               ├── Customer ← SOURCE ONLY
├── Product  ← LOCAL ONLY               ├── Channel  ← SOURCE ONLY
├── Currency ← LOCAL ONLY
```

---

#### Understanding the Two Separate Roles (Mirror of @XWRITE)

**Local-only dims (Scenario, Product, Currency)** play ONE role only:
> They determine **WHICH LOCAL CELL** gets the result. They scope the iteration on the local cube.

They are invisible to the source. The source has no corresponding slot. But they are critically important because they control WHERE in the local cube the returned value is stored.

**Source-only dims (Customer, Channel)** play ONE role only:
> They determine **WHICH VALUE** is read from the source cube.

If you don't specify them in mbrList, they default to the top member of the source cube. You must specify them if you want a specific member's value.

---

#### Case A: Reading Aggregated Source Data (Top of Source-Only Dims)

```essbase
FIX("FY25", "Actual", "East", "Jan", "All_Products", "USD")
    "Total_Revenue" = @XREF("Revenue", "Net_Revenue", "Total_Customer", "All_Channels");
ENDFIX
```

**What the FIX does (LOCAL side only)**:
- `"FY25"`, `"Actual"`, `"East"`, `"Jan"` → shared dims that flow to the source as POV
- `"All_Products"`, `"USD"` → local-only dims — scope the local cube, invisible to source

**What value does @XREF return—**
→ It reads `Net_Revenue` at `East, Jan, FY25, Total_Customer, All_Channels` from the Revenue Detail cube — the total revenue across all customers and channels.

**Where does the result land—**
→ Into the local cell `FinStmt → Total_Revenue, East, Jan, FY25, Actual, All_Products, USD`.

---

#### Case B: Reading Detail-Level Source Data

```essbase
FIX("FY25", "Actual", "East", "Jan", "All_Products", "USD")
    "Enterprise_Revenue" = @XREF("Revenue", "Net_Revenue", "Enterprise_Customers", "Online");
ENDFIX
```

**Source read**: `Revenue → Net_Revenue, East, Jan, FY25, Enterprise_Customers, Online`
→ Returns the revenue for Enterprise customers through the Online channel only.

**Local write**: `FinStmt → Enterprise_Revenue, East, Jan, FY25, Actual, All_Products, USD`

---

#### Case C: What If You DON'T Specify Source-Only Dims— (Top Member Fallback)

```essbase
FIX("FY25", "Actual", "East", "Jan", "All_Products", "USD")
    "Total_Revenue" = @XREF("Revenue", "Net_Revenue");
    /* Customer and Channel NOT specified! */
ENDFIX
```

**Source read**: `Revenue → Net_Revenue, East, Jan, FY25, ———Customer———, ———Channel———`

| Source Dimension | Resolved From | Value |
|------------------|---------------|-------|
| Account | mbrList | `Net_Revenue` |
| Entity | POV | `East` |
| Period | POV | `Jan` |
| Year | POV | `FY25` |
| Customer | ⚠️ **TOP MEMBER** | `Customer` (root) |
| Channel | ⚠️ **TOP MEMBER** | `Channel` (root) |

> ⚠️ **This may or may not be what you want.** If the top member is a Dynamic Calc parent, you'll get the aggregated value (correct). If it's a Stored parent that hasn't been aggregated, you'll get a stale or #MISSING value (wrong). See the Aggregation section below.

---

#### Case D: FIX Says FY25 but mbrList Says FY26 — Shared Dim Override

Just like @XWRITE, you can override a shared dimension to read from a **different member** than your current POV:

```essbase
FIX("FY25", "Actual", @CHILDREN("Total Entity"))
    /* Read LAST year's revenue as a base for this year's forecast */
    "Revenue_Prior" = @XREF("Revenue", "Net_Revenue", "FY24", "Total_Customer", "All_Channels");
    /*                                                  ^^^^                                  */
    /*                                      mbrList overrides Year!                           */
ENDFIX
```

**What happens:**
- FIX sets Year = `FY25` on the local cube (Priority 2)
- mbrList specifies `"FY24"` (Priority 1) — it **wins**
- @XREF reads `Revenue → Net_Revenue, [current entity], [current period], FY24, Total_Customer, All_Channels`
- The FY24 value is returned and stored in the local FY25 cell

**Common use cases for this pattern:**

| Use Case | FIX (Local Context) | mbrList (Read Override) |
|----------|--------------------|------------------------|
| Read prior year for comparison | `FIX("FY25")` | `"FY24"` |
| Read Actual for Forecast seeding | `FIX("Forecast")` | `"Actual"` |
| Read a different entity's data | `FIX("East")` | `"West"` |
| Read from a different version | `FIX("Working")` | `"Final"` |

---

#### Case E: The Golden Rule for @XREF

```
┌──────────────────────────────────────────────────────────────────┐
│                    THE GOLDEN RULE (@XREF)                        │
│                                                                  │
│  Source-only dims in mbrList → Control WHAT VALUE is read        │
│  (Customer, Channel)           from the source cube              │
│                                                                  │
│  Local-only dims in FIX    → Control WHERE RESULT is stored      │
│  (Scenario, Product, Currency) in the local cube                 │
│                                                                  │
│  Shared dims (Account, Entity, Period, Year):                    │
│    - POV flows to source automatically                           │
│    - Can be overridden by mbrList to read different member        │
│                                                                  │
│  Source-only dims NOT in mbrList → default to top of source dim  │
│  Local-only dims NOT in FIX → default context of local cube      │
└──────────────────────────────────────────────────────────────────┘
```

**Compared to @XWRITE:**

```
@XREF:   FIX scopes LOCAL (where result goes)    mbrList targets SOURCE (where to read)
@XWRITE: FIX scopes SOURCE (what value to read)   mbrList targets TARGET (where to write)
```

They are **mirror images** of each other:
- @XREF: local cube is the consumer, source cube is the provider
- @XWRITE: local cube is the provider, target cube is the consumer

---

## ⚠️ Deep Dive: Does @XREF Aggregate Automatically—

**Same answer as @XWRITE and Data Maps: NO.**

@XREF reads whatever value exists at the source intersection. It does NOT trigger an aggregation.

### The Behavior Depends on Source Member Storage Type

| Source Member Type | What @XREF Reads | Correct— |
|--------------------|------------------|---------| 
| **Dynamic Calc parent** | ✅ Calculates on-the-fly → correct aggregated value | ✅ Yes — always current |
| **Stored parent, freshly aggregated** | ✅ Reads the stored aggregated value | ✅ Yes — if nothing changed |
| **Stored parent, stale** | ❌ Reads the OLD stored value | ❌ No — wrong number returned! |
| **Stored parent, never aggregated** | ❌ Returns #MISSING | ❌ No — your formula gets #MISSING |
| **Level-0 stored member** | ✅ Reads the direct input value | ✅ Yes — always correct |

### What Happens When @XREF Returns #MISSING—

If the source intersection has no data, @XREF returns `#MISSING`. This can cascade:

```essbase
/* DANGEROUS: Division by @XREF that might return #MISSING */
"Cost_Per_Head" = "Total_Cost" / @XREF("Workforce", "Headcount");
/* If Headcount is #MISSING → division by #MISSING → result is #MISSING */
```

**Always guard against #MISSING:**

```essbase
VAR vHC = @XREF("Workforce", "Headcount");
IF(vHC > 0)
    "Cost_Per_Head" = "Total_Cost" / vHC;
ELSE
    "Cost_Per_Head" = 0;
ENDIF
```

---

## 🎯 Deep Dive: How FIX Works with @XREF

### FIX Controls the Local Cube Iteration

```essbase
/* This FIX runs on the LOCAL cube (FinStmt) */
FIX("FY25", "Actual", @DESCENDANTS("Total Entity"), @CHILDREN("All Periods"))
    "Salary_Expense" = @XREF("Workforce", "Total_Compensation");
ENDFIX
```

- The FIX scopes which cells to calculate **on the local cube**
- For each cell in the FIX, @XREF fires and reads from the source
- The FIX members become the **Priority 2** values for mapping to the source
- The FIX does **NOT** restrict what's read from the source — it only determines the POV context

### How FIX Drives Multiple @XREF Lookups

If `Total Entity` has children `East, West, Central` and `All Periods` has children `Jan, Feb, Mar`:

| Iteration | Local Cell | @XREF Reads From (Source) |
|-----------|-----------|--------------------------|
| 1 | `FinStmt → Salary_Expense, East, Jan, FY25, Actual` | `Workforce → Total_Compensation, East, Jan, FY25, Actual, Total_Grade` |
| 2 | `FinStmt → Salary_Expense, East, Feb, FY25, Actual` | `Workforce → Total_Compensation, East, Feb, FY25, Actual, Total_Grade` |
| 3 | `FinStmt → Salary_Expense, East, Mar, FY25, Actual` | `Workforce → Total_Compensation, East, Mar, FY25, Actual, Total_Grade` |
| 4 | `FinStmt → Salary_Expense, West, Jan, FY25, Actual` | `Workforce → Total_Compensation, West, Jan, FY25, Actual, Total_Grade` |
| ... | ... | ... |
| 9 | `FinStmt → Salary_Expense, Central, Mar, FY25, Actual` | `Workforce → Total_Compensation, Central, Mar, FY25, Actual, Total_Grade` |

**That's 9 separate cross-database reads** (3 entities × 3 periods). Each one is a round-trip to the source cube. This is why performance matters.

---

## ✅ What's Allowed in @XREF

### Allowed in `mbrList` (Same Rules as @XWRITE)

| Construct | Allowed— | Notes |
|-----------|----------|-------|
| Individual member names | ✅ Yes | `"Headcount"`, `"East"`, `"FY24"` |
| Multiple members (different dims) | ✅ Yes | `"Headcount", "East", "FY24"` |
| Each member from a different dim | ✅ Yes | Must be from different dimensions |

### NOT Allowed in `mbrList`

| Construct | Allowed— | Why Not |
|-----------|----------|---------|
| Functions returning multiple members | ❌ No | e.g., `@LEVMBRS(Market, 0)` — returns a list |
| Member ranges | ❌ No | e.g., `"Jan":"Dec"` |
| Attribute members | ❌ No | Attribute members/operators cannot be used |
| Cross-dimensional operators | ❌ No | `->` not supported in mbrList |

### Where @XREF Can Be Used (Unlike @XWRITE)

Because @XREF **returns a value**, it can be used in many contexts:

| Context | Example | Notes |
|---------|---------|-------|
| Direct assignment | `"A" = @XREF("WF", "HC");` | Assigns the value |
| In arithmetic | `"A" = "B" * @XREF("WF", "HC");` | Multiply local × remote value |
| In IF conditions | `IF(@XREF("WF", "HC") > 0)` | Conditional logic |
| In variable assignment | `VAR v = @XREF("WF", "HC");` | Store for reuse |
| Nested in functions | `@ABS(@XREF("WF", "HC"))` | As argument to other functions |
| Inside @XWRITE | `@XWRITE(@XREF("Rates", "FX_Rate") * "Rev", "FinStmt")` | Read from one, write to another |
| In outline member formulas | Member formula on "Salary" | Runs whenever the member is calculated |

---

## Practical Examples

### Example 1: Headcount-Based Cost Allocation

**Scenario**: In FinStmt, allocate IT costs based on headcount from Workforce plan type.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vHeadcount = @XREF("Workforce", "Headcount");
    VAR vTotalHC = @XREF("Workforce", "Headcount", "Total Entity");
    
    IF(vTotalHC > 0)
        "IT_Allocation" = "IT_Total_Cost" -> "Corporate" * (vHeadcount / vTotalHC);
    ELSE
        "IT_Allocation" = 0;
    ENDIF
ENDFIX
```

**What Happens**:
- First @XREF: reads each entity's Headcount from Workforce (entity flows from POV)
- Second @XREF: reads Total Entity Headcount (overrides Entity dim with mbrList)
- Calculates each entity's share of IT costs proportionally

**Key detail**: The second @XREF overrides the Entity dimension via mbrList (`"Total Entity"`) to always read the grand total, even though the FIX is iterating over individual entities.

---

### Example 2: Exchange Rate Lookup and Currency Conversion

```essbase
FIX("FY25", "Working", @DESCENDANTS("International_Entities"))
    VAR vRate = @XREF("Rates", "Avg_Exchange_Rate");
    "Revenue_USD" = "Revenue_Local" * vRate;
    "COGS_USD" = "COGS_Local" * vRate;
ENDFIX
```

**Performance tip**: Store the @XREF result in a variable (`vRate`) and reuse it. This avoids calling @XREF twice for the same value.

---

### Example 3: Depreciation from Capital Plan

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Depreciation_Expense" = @XREF("Capital", "Monthly_Depreciation");
ENDFIX
```

---

### Example 4: Conditional Cross-Reference with #MISSING Guard

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    VAR vHC = @XREF("Workforce", "Headcount");
    IF(vHC > 0)
        "Benefits_Cost" = vHC * "Benefit_Rate_Per_Head";
    ELSE
        "Benefits_Cost" = 0;
    ENDIF
ENDFIX
```

---

### Example 5: Reading Prior Year from Source for Forecast Seeding

```essbase
/* Running on FinStmt, reading FY24 Actual from Revenue to seed FY25 Forecast */
FIX("FY25", "Forecast", @CHILDREN("Total Entity"), @CHILDREN("All Periods"))
    "Revenue_Seed" = @XREF("Revenue", "Net_Revenue", "FY24", "Actual", "Total_Customer");
    /*                                                 ^^^^    ^^^^^^                    */
    /*                              Override Year AND Scenario from the source!          */
ENDFIX
```

**What happens**: FIX is at FY25/Forecast on the local cube. mbrList overrides to read FY24/Actual from the source. Last year's actual revenue seeds this year's forecast.

---

### Example 6: Multiple @XREF Calls from Different Plan Types

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    /* Read from Workforce */
    VAR vHC = @XREF("Workforce", "Headcount");
    
    /* Read from Rates */
    VAR vBenefitRate = @XREF("Rates", "Benefit_Rate");
    
    /* Read from Capital */
    VAR vDepreciation = @XREF("Capital", "Monthly_Depreciation");
    
    /* Calculate locally using data from 3 different plan types */
    "Total_OpEx" = (vHC * "Avg_Salary") + (vHC * vBenefitRate) + vDepreciation;
ENDFIX
```

---

### Example 7: @XREF Inside @XWRITE (Read from One, Write to Another)

```essbase
/* Running on Rates cube */
/* Read local currency revenue from FinStmt, apply exchange rate, write converted value back */
FIX("FY25", @DESCENDANTS("International"))
    VAR vRate = "Closing_Rate";
    @XWRITE(@XREF("FinStmt", "Revenue_Local") * vRate, "FinStmt", "Revenue_Reported");
ENDFIX
```

---

## 🚀 Deep Dive: Performance — Why @XREF Can Be Slow and How to Fix It

### Why @XREF Is Expensive

```
┌──────────────────────────────────────────────────────────────┐
│                    PER-CELL COST MODEL                        │
│                                                              │
│  For each cell in your FIX scope:                            │
│    1. Pause local calculation                                │
│    2. Build the source intersection (mapping)                │
│    3. Open connection to source cube                         │
│    4. Locate the data block in source                        │
│    5. Read the value                                         │
│    6. Return value to local formula                          │
│    7. Resume local calculation                               │
│                                                              │
│  Cost = N cells × (mapping + lookup + return)                │
│  For 1M cells, that's 1M cross-database reads!               │
└──────────────────────────────────────────────────────────────┘
```

### Additional Performance Impacts

- **Top-down formula**: Forces Essbase into top-down calculation mode, preventing some parallel optimizations
- **Block creation**: Can force the creation of blocks on the local cube that wouldn't otherwise exist
- **Network latency**: If the source is remote, network round-trips multiply the cost

### Performance Comparison

| Approach | Relative Speed | Best For |
|----------|---------------|----------|
| Local calculation (no @XREF) | ⚡ Fastest | Data already in the cube |
| DATACOPY + local calc | 🔵 Fast | Bulk staging then calculation |
| @XREF (small scope) | 🟡 Moderate | < 10K lookups, simple reads |
| @XREF (large scope) | 🔴 Slow | Avoid — use staging instead |
| Multiple @XREF calls per cell | 🔴🔴 Very Slow | Avoid — use variables |

### Performance Best Practices

#### 1. Store @XREF in a Variable — Don't Call It Twice

```essbase
/* ❌ BAD: Two @XREF calls for the same value */
IF(@XREF("Workforce", "Headcount") > 0)
    "Benefits" = @XREF("Workforce", "Headcount") * "Rate";
ENDIF

/* ✅ GOOD: One @XREF call, stored in variable */
VAR vHC = @XREF("Workforce", "Headcount");
IF(vHC > 0)
    "Benefits" = vHC * "Rate";
ENDIF
```

#### 2. Narrow Your FIX — Fewer Cells = Fewer Lookups

```essbase
/* ❌ BAD: Broad FIX — @XREF fires for every member combination */
FIX("FY25", @DESCENDANTS("Total Entity"), @DESCENDANTS("All Periods"))
    "Expense" = @XREF("Workforce", "Salary");
ENDFIX

/* ✅ GOOD: Narrow FIX — only level-0 members that need data */
FIX("FY25", @LEVMBRS("Total Entity", 0), @LEVMBRS("All Periods", 0))
    "Expense" = @XREF("Workforce", "Salary");
ENDFIX
```

#### 3. Consider DATACOPY Staging Instead

For high-volume scenarios, stage the data first with DATACOPY, then calculate locally:

```essbase
/* Step 1: Copy external data into a staging member in the local cube */
DATACOPY "Source_Account" TO "Staging_Account";

/* Step 2: Calculate locally — no @XREF needed, much faster */
FIX("FY25", @DESCENDANTS("Total Entity"))
    "Result" = "Local_Data" * "Staging_Account";
ENDFIX
```

#### 4. Use @XWRITE Instead (Push vs. Pull)

If you control the source cube's business rule, consider pushing data with @XWRITE instead of pulling with @XREF. @XWRITE can filter out #MISSING and zero values, reducing the number of cross-cube operations.

---

## 🔄 @XREF vs. @XWRITE — Complete Comparison

| Aspect | @XREF | @XWRITE |
|--------|-------|---------|
| **Direction** | READ from another cube | WRITE to another cube |
| **Returns a value—** | ✅ Yes — numeric | ❌ No — performs a write |
| **FIX controls** | LOCAL cube (where result goes) | SOURCE cube (what value to read) |
| **mbrList targets** | SOURCE cube (where to read from) | TARGET cube (where to write to) |
| **Unmatched dims default to** | Top member of SOURCE | Top member of TARGET |
| **Local-only dims** | Ignored by source (scope local cells only) | Ignored by target (scope source value only) |
| **Remote-only dims** | Default to top member of source | Default to top member of target |
| **@LOOPBACK** | Not applicable | ✅ Yes — write to same cube |
| **Can use in formulas** | ✅ Yes — anywhere numeric is valid | ❌ No — standalone write operation |
| **Location Alias role** | Represents the **data source** | Represents the **data target** |
| **Shares same location alias** | ✅ Yes — same alias as @XWRITE | ✅ Yes — same alias as @XREF |
| **Formula type** | Top-down | Top-down |
| **Performance** | Per-cell read (expensive at scale) | Per-cell write (expensive at scale) |

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| **Wrong plan type name** | `@XREF("WrkForce")` fails if the plan type is named `"Workforce"` | Verify exact plan type name in application settings |
| **Not specifying source-only dims** | Dimensions that exist only in the source default to top member — may not be what you want | Explicitly specify source-only dimension members in mbrList |
| **Calling @XREF twice for same value** | Two identical @XREF calls = two cross-database reads | Store in a variable: `VAR v = @XREF(...)` |
| **Broad FIX scope** | @XREF fires for every cell in the FIX — millions of cells = millions of lookups | Narrow FIX to only level-0 members that need data |
| **Not handling #MISSING** | If source returns #MISSING, `"A" = "B" / @XREF(...)` gives #MISSING | Check: `IF(vRef > 0)` before using |
| **Assuming write capability** | @XREF only READS — it cannot modify the source | Use @XWRITE for cross-database writes |
| **Stale source parent data** | Reading a Stored parent that hasn't been aggregated returns old/wrong value | Ensure source parents are Dynamic Calc, or run AGG on source first |
| **Using multi-member functions in mbrList** | `@LEVMBRS(Market, 0)` returns a list — not allowed | Use individual member names |
| **Using ranges in mbrList** | `"Jan":"Dec"` not supported | Specify each member individually |
| **Performance in ASO reads** | Reading from ASO has specific requirements | Ensure source intersection in ASO is stored or upper-level |
| **Circular @XREF** | Cube A reads from Cube B which reads from Cube A | Avoid circular cross-database references |

---

## ⚠️ Performance Considerations

| Consideration | Recommendation |
|---------------|----------------|
| Each @XREF is a cross-database read | Minimize @XREF calls — store results in variables |
| Broad FIX = millions of lookups | Narrow FIX to only required level-0 intersections |
| Multiple @XREF per cell | Combine reads: store each in a VAR, then compute locally |
| High-volume data needs | Stage with DATACOPY first, then calculate locally |
| Remote source cube | Network latency multiplies — keep lookups minimal |
| Consider @XWRITE alternative | Push from source instead of pull from local (often faster) |
| Top-down calculation impact | @XREF forces top-down mode — can slow overall calculation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@XWRITE`](./@XWRITE.md) | Cross-database WRITE (opposite of @XREF) |
| [`DATACOPY`](./DATACOPY.md) | Alternative: stage data locally first for faster calculations |
| [`@CURRMBR`](./@CURRMBR.md) | Often used to understand which member is being mapped |
| [`FIX`](./FIX.md) | Scopes @XREF calculations on the local cube |

---

## Official Oracle Reference

- [Oracle Essbase 21 — @XREF](https://docs.oracle.com/en/database/other-databases/essbase/21/esscq/xref.html)
- [Understand XREF/XWRITE](https://docs.oracle.com/pls/topic/lookup—ctx=en/database/other-databases/essbase/21/esscq&id=UGESS-GUID-F8BB3012-42C8-4A96-B18C-B8D68EC8A056)
- [Create a Location Alias](https://docs.oracle.com/pls/topic/lookup—ctx=en/database/other-databases/essbase/21/esscq&id=UGESS-GUID-6CF2B0AB-9E8D-47B1-92F5-112D7A31D841)
