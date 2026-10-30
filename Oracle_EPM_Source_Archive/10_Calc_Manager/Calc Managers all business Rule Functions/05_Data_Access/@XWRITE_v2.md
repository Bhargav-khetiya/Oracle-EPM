# @XWRITE

## Overview

`@XWRITE` is a **cross-database write function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **writes a value to another database** (plan type or cube), or even back to the same cube. It is the write counterpart of `@XREF` — while @XREF reads from another plan type, @XWRITE pushes data to one.

`@XWRITE` does **not impose member and dimension mapping restrictions**, which means the data source and data target outlines can be completely different — different dimensions, different hierarchies, different member names.

### Why Does This Function Exist?

Calculations in one plan type sometimes need to push results to another:
- Writing calculated salary expense from Workforce to FinStmt
- Pushing capital depreciation from Capital plan type to FinStmt
- Writing allocation results across plan types
- Synchronizing summary data between cubes
- Re-mapping data from one member to another in the same cube (via `@LOOPBACK`)

### When to Use It

- To push calculated values from one plan type to another
- To write aggregated results to a reporting plan type
- To synchronize key metrics across plan types
- When a business rule in one cube needs to update data in another
- To push allocation results to the target plan type
- To re-map or copy data to different members within the same cube

---

## Category

**Data Access / Cross-Database / Write**

---

## Syntax

There are multiple ways to call this function, depending on your deployment:

### Syntax 1 — Using Location Alias (Remote or Cross-Server)

```essbase
@XWRITE(expression, locationAlias [, mbrList])
```

Use this when the target cube is on a **different Essbase server** or when a location alias has been configured. The querying user does **not** need to be provisioned or signed in on the remote cube when using a location alias.

### Syntax 2 — Using App/Cube Name (Same Server)

```essbase
@XWRITE(expression, appName, dbName [, mbrList])
```

Use this when source and target are on the **same Essbase server instance**. The user must be signed in on the target cube and provisioned on the source cube.

### Syntax 3 — Writing to the Same Cube (@LOOPBACK)

```essbase
@XWRITE(expression, @LOOPBACK [, mbrList])
```

Use `@LOOPBACK` as the location alias to write back to the **same cube**. This is useful for re-mapping data from one member intersection to another within the same plan type.

### Formal Syntax (EPM Cloud / Calc Manager)

```essbase
@XWRITE("planTypeName", numericExpression [, memberOverride1, memberOverride2, ...])
```

Where:
- `planTypeName` — The target plan type to write to
- `numericExpression` — The value to write
- `memberOverride` — Optional member overrides for dimension mapping

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric expression | ✅ Yes | A single member specification, variable name, or other numeric expression corresponding to the value to be stored. |
| `locationAlias` | String | ✅ (Syntax 1) | A location alias for the data target. Set by the administrator — specifies server, application, cube, username, and password for the target. The same alias can be shared by `@XREF` and `@XWRITE`. For `@XWRITE` only, the reserved keyword `@LOOPBACK` can be used to write to the same cube. |
| `appName, dbName` | Strings | ✅ (Syntax 2) | Application and cube name. Use only when source and target are on the same Essbase server instance. |
| `mbrList` | Member name(s) | ❌ No | Optional comma-delimited list of member names that qualify the @XWRITE operation. These override the automatic dimension mapping for the target. See the **Dimension Mapping Deep Dive** section below for complete details. |

---

## Return Value

`@XWRITE` does not return a value to the calling script — it **writes data to the target plan type**.

---

## ⚡ Deep Dive: How @XWRITE Works (Behind the Scenes)

### Execution Flow

```
1. Script runs on SOURCE cube
2. FIX statement scopes which data blocks to iterate
3. For each cell in the FIX scope:
   a. Evaluate the expression (the value to write)
   b. Determine the target intersection using mapping rules
   c. Buffer the write to the TARGET cube
4. After the calculation pass completes → commit all buffered writes
```

### Key Mechanics

1. **Top-Down Formula**: @XWRITE is a top-down formula. This means it calculates parent values first, then children — the opposite of the default bottom-up calculation order.

2. **Write Buffer**: @XWRITE operations are **buffered** and committed at the end of the calculation pass. They are **not immediately visible** in the target database during the current script execution.

3. **Block Creation**: If the target intersection doesn't have a data block, @XWRITE can create one (depending on the target plan type's configuration).

4. **Directionality**: @XWRITE writes **FROM** the current calculation context **TO** the target. The script runs in the source plan type and pushes to the target.

5. **Permissions**: The user/rule must have write access to the target plan type.

6. **BSO Only**: This function is applicable only to **block storage (BSO)** cubes.

---

## 🔗 Deep Dive: Dimension Mapping — How It Really Works

This is the most critical concept to understand when using @XWRITE. When source and target cubes have **different outlines** (different dimensions, different members, or both), @XWRITE uses a **three-tier precedence system** to determine exactly where to write data in the target.

### The Three-Tier Mapping Precedence

```
┌─────────────────────────────────────────────────────────┐
│           PRIORITY 1: mbrList (Highest)                 │
│  Members explicitly specified in the @XWRITE call       │
│  These ALWAYS win — they override everything else       │
├─────────────────────────────────────────────────────────┤
│           PRIORITY 2: Current Point of View             │
│  Members currently being calculated on the source cube  │
│  Used for SHARED dimensions not overridden by mbrList   │
├─────────────────────────────────────────────────────────┤
│           PRIORITY 3: Top Member (Lowest/Fallback)      │
│  The topmost (root) member of unspecified dimensions    │
│  in the TARGET cube. Used when a dimension exists in    │
│  the target but NOT in the source AND NOT in mbrList    │
└─────────────────────────────────────────────────────────┘
```

### How This Works — Step by Step

When @XWRITE fires for a given cell, Essbase builds the target intersection as follows:

**Step 1** — Start with a blank intersection on the target cube (one slot per dimension).

**Step 2** — Fill in any dimensions specified in the `mbrList`. These are locked in and cannot be overridden.

**Step 3** — For any remaining empty slots, check the current Point of View (POV) on the source cube. If the source has a dimension with the **same name** as the target, the current member from that dimension fills the slot.

**Step 4** — If any slots are STILL empty (because the dimension exists in the target but not the source, and was not in mbrList), fill those with the **top member** of that dimension in the target outline.

### Visual Example: Source Has 5 Dims, Target Has 6 Dims

```
SOURCE CUBE (Workforce):                TARGET CUBE (FinStmt):
├── Account                              ├── Account
├── Entity                               ├── Entity
├── Period                               ├── Period
├── Year                                 ├── Year
├── Scenario                             ├── Scenario
                                         ├── Product   ← NOT in source
```

**Script running on Workforce:**
```essbase
FIX("FY25", "Working", "East", "Jan")
    "Headcount"(
        @XWRITE("Headcount", "FinStmt", "HC_Account");
    )
ENDFIX
```

**How the target intersection is built:**

| Target Dimension | Source? | In mbrList? | Resolved From | Resolved Value |
|------------------|---------|-------------|---------------|----------------|
| Account | ✅ Yes | ✅ Yes (`"HC_Account"`) | **mbrList** (Priority 1) | `HC_Account` |
| Entity | ✅ Yes | ❌ No | **POV** (Priority 2) | `East` |
| Period | ✅ Yes | ❌ No | **POV** (Priority 2) | `Jan` |
| Year | ✅ Yes | ❌ No | **POV** (Priority 2) | `FY25` |
| Scenario | ✅ Yes | ❌ No | **POV** (Priority 2) | `Working` |
| Product | ❌ No | ❌ No | **Top Member** (Priority 3) | `Total Product` |

**Result**: Value is written to `FinStmt -> HC_Account, East, Jan, FY25, Working, Total Product`.

### Visual Example: Target Has 2 Extra Dimensions, Source Has 2 Unique Dimensions

```
SOURCE CUBE (Revenue Detail):           TARGET CUBE (FinStmt):
├── Account                              ├── Account
├── Entity                               ├── Entity
├── Period                               ├── Period
├── Year                                 ├── Year
├── Customer   ← ONLY in source          ├── Scenario   ← ONLY in target
├── Channel    ← ONLY in source          ├── Product     ← ONLY in target
                                         ├── Currency    ← ONLY in target
```

**Script running on Revenue Detail:**
```essbase
FIX("FY25", "East", "Jan", "Cust_001", "Online")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Revenue_Line", "Actual");
    )
ENDFIX
```

**How the target intersection is built:**

| Target Dimension | In Source? | In mbrList? | Resolved From | Resolved Value |
|------------------|-----------|-------------|---------------|----------------|
| Account | ✅ Yes | ✅ Yes (`"Revenue_Line"`) | **mbrList** (Priority 1) | `Revenue_Line` |
| Entity | ✅ Yes | ❌ No | **POV** (Priority 2) | `East` |
| Period | ✅ Yes | ❌ No | **POV** (Priority 2) | `Jan` |
| Year | ✅ Yes | ❌ No | **POV** (Priority 2) | `FY25` |
| Scenario | ❌ No | ✅ Yes (`"Actual"`) | **mbrList** (Priority 1) | `Actual` |
| Product | ❌ No | ❌ No | **Top Member** (Priority 3) | `Total Product` |
| Currency | ❌ No | ❌ No | **Top Member** (Priority 3) | `Total Currency` |

**What about Customer and Channel?** They exist **only in the source** — the target has no such dimensions. They are simply **ignored**. The target doesn't have a slot for them, so they play no role. They are part of the source FIX (they scope which data to iterate), but the target has no corresponding dimension.

### Critical Insight: Source-Only Dimensions Are Ignored, Target-Only Dimensions Default to Top Member

| Scenario | What Happens |
|----------|-------------|
| Dimension exists in **both** source and target | Current POV member is used (unless overridden by mbrList) |
| Dimension exists **only in source** | Completely ignored — target has no slot for it |
| Dimension exists **only in target** | Falls back to **top member** of that dimension (unless specified in mbrList) |
| Dimension exists in both but member names differ | **Error** — you must use mbrList to specify the correct target member |

---

### 🔥 Complete Scenario: Both Cubes Have Unique Dimensions (Revenue Detail → FinStmt)

This is the most complex and most asked-about scenario. Let's go through it exhaustively.

```
SOURCE CUBE (Revenue Detail):           TARGET CUBE (FinStmt):
├── Account  ─────────── SHARED ─────── Account
├── Entity   ─────────── SHARED ─────── Entity
├── Period   ─────────── SHARED ─────── Period
├── Year     ─────────── SHARED ─────── Year
├── Customer ← SOURCE ONLY              ├── Scenario ← TARGET ONLY
├── Channel  ← SOURCE ONLY              ├── Product  ← TARGET ONLY
                                         ├── Currency ← TARGET ONLY
```

**The big question**: Source has `Customer` and `Channel` (target doesn't). Target has `Scenario`, `Product`, and `Currency` (source doesn't). What happens with each type?

---

#### Understanding the Two Separate Roles

**Source-only dims (Customer, Channel)** play ONE role only:
> They determine **WHICH VALUE** is picked up from the source cube for the expression.

They are like a filter on the source side. The target has no corresponding slot, so these dims are completely invisible to the target. But they are **critically important** because they control what number gets written.

**Target-only dims (Scenario, Product, Currency)** play ONE role only:
> They determine **WHERE** the value lands in the target cube.

If you don't specify them in mbrList, they default to top member. The source has no corresponding dimension, so POV can never fill these slots — only mbrList or top-member fallback can.

---

#### Case A: Writing at Detail Level (Per Customer, Per Channel)

```essbase
/* FIX scopes source to DETAIL-level source-only dims */
FIX("FY25", "East", "Jan", "Cust_001", "Online")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Revenue_Line", "Actual", "Product_A", "USD");
    )
ENDFIX
```

**What the FIX does (SOURCE side only)**:
- `"FY25"` → locks Year to FY25 on source
- `"East"` → locks Entity to East on source
- `"Jan"` → locks Period to Jan on source
- `"Cust_001"` → locks Customer to Cust_001 on source (source-only dim!)
- `"Online"` → locks Channel to Online on source (source-only dim!)

**What value does `"Net_Revenue"` evaluate to?**
→ It reads `Net_Revenue` at the intersection of `East, Jan, FY25, Cust_001, Online` on the source cube. This is the revenue for Customer "Cust_001" through the "Online" channel. The FIX on source-only dims controls which specific value is picked up.

**Where does it land in the target?**

| Target Dim | How Resolved | Value | Why |
|------------|-------------|-------|-----|
| Account | mbrList | `Revenue_Line` | Explicitly specified |
| Entity | POV (shared) | `East` | From FIX — shared dim |
| Period | POV (shared) | `Jan` | From FIX — shared dim |
| Year | POV (shared) | `FY25` | From FIX — shared dim |
| Scenario | mbrList | `Actual` | Explicitly specified — target-only dim |
| Product | mbrList | `Product_A` | Explicitly specified — target-only dim |
| Currency | mbrList | `USD` | Explicitly specified — target-only dim |

**Result**: The value of `Net_Revenue` for `Cust_001, Online` is written to `FinStmt → Revenue_Line, East, Jan, FY25, Actual, Product_A, USD`.

**What about `Cust_001` and `Online`?** They were used to read the value from source, but the target has no Customer or Channel dimension. They simply vanish — no trace of them in the target intersection.

---

#### Case B: Writing at Aggregated Level (Top of Source-Only Dims)

**This is the key insight the user is asking about**: What if you FIX source-only dims at their TOP LEVEL (aggregated) and then dump into a specific member of target-only dims?

```essbase
/* FIX scopes source-only dims to their TOP (aggregated) members */
FIX("FY25", "East", "Jan", "Total_Customer", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Total_Revenue", "Actual", "All_Products", "USD");
    )
ENDFIX
```

**What the FIX does (SOURCE side)**:
- `"Total_Customer"` → picks up the AGGREGATED value across all customers
- `"All_Channels"` → picks up the AGGREGATED value across all channels
- Together: `Net_Revenue` at `East, Jan, FY25, Total_Customer, All_Channels` = **the total revenue for all customers through all channels**

**What value does `"Net_Revenue"` evaluate to?**
→ This is where the **critical question** comes in: **does @XWRITE (or Data Maps) automatically aggregate?**

---

##### ⚠️ Deep Dive: Does It Aggregate Automatically? (Dynamic Calc vs. Stored Parents)

**NO — neither @XWRITE nor Data Maps/Smart Push trigger automatic aggregation.** They all read whatever value currently exists at the intersection. The behavior depends entirely on how the parent member is configured in the **source** outline:

**Scenario 1: Parent is Dynamic Calc (most common in EPM Cloud)**

```
Total_Customer (Dynamic Calc)
├── Cust_001 (Stored) → 100
├── Cust_002 (Stored) → 200
├── Cust_003 (Stored) → 150
```

When @XWRITE (or Smart Push) reads `Total_Customer`:
- Essbase calculates the aggregation **on the fly** in memory
- Returns `100 + 200 + 150 = 450`
- ✅ **You get the correct, real-time aggregated value**
- This LOOKS like automatic aggregation, but it's just Dynamic Calc doing its job — the value isn't stored, it's computed when requested

**Scenario 2: Parent is Stored (not yet aggregated)**

```
Total_Customer (Stored) → currently holds 300 (stale!)
├── Cust_001 (Stored) → 100
├── Cust_002 (Stored) → 200
├── Cust_003 (Stored) → 150  ← new data loaded, parent not re-aggregated
```

When @XWRITE (or Smart Push) reads `Total_Customer`:
- Essbase reads the **stored value**: `300`
- It does NOT recalculate: `100 + 200 + 150 = 450`
- ❌ **You get the STALE value (300), not the correct aggregated value (450)**
- The parent was last aggregated when it held different children values

**Scenario 3: Parent is Stored and NEVER aggregated**

```
Total_Customer (Stored) → #MISSING (never aggregated)
├── Cust_001 (Stored) → 100
├── Cust_002 (Stored) → 200
├── Cust_003 (Stored) → 150
```

When @XWRITE reads `Total_Customer`:
- Returns `#MISSING`
- ❌ **Nothing useful gets written to the target**

---

##### Comparison: @XWRITE vs. Data Maps vs. Smart Push — Aggregation Behavior

| Tool | Triggers Aggregation? | What Value Does It Read? |
|------|-----------------------|--------------------------|
| **@XWRITE** | ❌ No | Reads whatever exists at the intersection — Dynamic Calc gives real-time value, Stored gives last-stored value |
| **Smart Push** | ❌ No | Same behavior — reads the value at the mapped intersection. Does NOT aggregate first |
| **Data Maps** | ❌ No | Same — maps and pushes existing values. No auto-aggregation |
| **DATACOPY** | ❌ No | Copies raw stored values. Does NOT aggregate |

> **None of these tools trigger an aggregation.** They all act as "readers" — they read what's there and push/copy it. If the parent is Dynamic Calc, you're fine. If it's Stored, you must aggregate first.

---

##### What About Writing TO a Parent in the Target?

Same principle applies on the **target** side:

| Target Parent Type | What Happens When @XWRITE Writes To It |
|--------------------|----------------------------------------|
| **Stored parent** | ✅ Value is written directly. But this is **input to a parent** — it may conflict with aggregation. If you later run AGG on the target, children will roll up and overwrite this value. |
| **Dynamic Calc parent** | ⚠️ **Write is silently ignored.** The value is calculated in memory during the @XWRITE execution, but it is NOT persisted to disk. Next time anyone reads that parent, it recalculates from children. Your write is lost. |
| **Store data (Label Only parent)** | Depends on outline config. Generally, Label Only members don't store data. |

> ⚠️ **Critical Warning**: Writing to a Dynamic Calc member in the target appears to work (no error is thrown), but the data is **never persisted**. This is one of the most common silent failures with @XWRITE.

---

##### Best Practice: Always Aggregate Before Pushing

If your source parents are **Stored** (not Dynamic Calc), run aggregation BEFORE @XWRITE:

```essbase
/* Step 1: Aggregate the source cube first */
CALC DIM(Customer, Channel);

/* Step 2: Now push the correctly aggregated parent values */
FIX("FY25", "East", "Jan", "Total_Customer", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Total_Revenue", "Actual", "All_Products", "USD");
    )
ENDFIX
```

Or aggregate only the specific dimensions you need:

```essbase
/* Aggregate only what's needed */
AGG(Customer);
AGG(Channel);

/* Then push */
FIX("FY25", @CHILDREN("Total Entity"), @CHILDREN("All Periods"),
    "Total_Customer", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Total_Revenue", "Actual", "All_Products", "USD");
    )
ENDFIX
```

##### Quick Decision: Do I Need to Aggregate First?

| Source Parent Type | Need AGG Before Push? | Why |
|-------------------|----------------------|-----|
| Dynamic Calc | ❌ No — it auto-calculates on read | Value is always current |
| Stored + recently aggregated | ❌ No — value is already fresh | But verify it's not stale |
| Stored + data changed since last AGG | ✅ **YES** — value is stale | Run `AGG` or `CALC DIM` first |
| Stored + never aggregated | ✅ **YES** — value is #MISSING | Must aggregate at least once |

---

**Where does the value land in the target?**

| Target Dim | How Resolved | Value | Why |
|------------|-------------|-------|-----|
| Account | mbrList | `Total_Revenue` | Explicitly specified |
| Entity | POV (shared) | `East` | From FIX — shared dim |
| Period | POV (shared) | `Jan` | From FIX — shared dim |
| Year | POV (shared) | `FY25` | From FIX — shared dim |
| Scenario | mbrList | `Actual` | Explicitly specified |
| Product | mbrList | `All_Products` | Explicitly specified |
| Currency | mbrList | `USD` | Explicitly specified |

**Result**: The aggregated revenue (if parent is Dynamic Calc or properly aggregated) is written to `FinStmt → Total_Revenue, East, Jan, FY25, Actual, All_Products, USD`.

---

#### Case C: What If You DON'T Specify Target-Only Dims? (Top Member Fallback)

```essbase
/* NO target-only dims specified in mbrList! */
FIX("FY25", "East", "Jan", "Total_Customer", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Total_Revenue");
        /* Only Account is overridden. What about Scenario, Product, Currency? */
    )
ENDFIX
```

**Where does it land?**

| Target Dim | How Resolved | Value | Why |
|------------|-------------|-------|-----|
| Account | mbrList | `Total_Revenue` | Explicitly specified |
| Entity | POV | `East` | Shared dim |
| Period | POV | `Jan` | Shared dim |
| Year | POV | `FY25` | Shared dim |
| Scenario | ⚠️ **TOP MEMBER** | `Scenario` (root) | Not in source, not in mbrList → fallback! |
| Product | ⚠️ **TOP MEMBER** | `Total Product` (root) | Not in source, not in mbrList → fallback! |
| Currency | ⚠️ **TOP MEMBER** | `Total Currency` (root) | Not in source, not in mbrList → fallback! |

> ⚠️ **WARNING**: This is where unexpected behavior happens! The data lands at the ROOT member of each target-only dimension. In most applications, top-level members are either parent/aggregation points (where you don't want direct input data) or Dynamic Calc members (where the write silently fails). **Always explicitly specify target-only dimensions in mbrList.**

---

#### Case D: Looping Source Details, Dumping to Target at Aggregate Level

**Scenario**: You want to iterate over all individual customers and channels on the source, but push the total to a single point in the target.

```essbase
/* Iterate each customer and channel on source — but write to same target point each time */
FIX("FY25", @CHILDREN("Total Entity"), @CHILDREN("All Periods"),
    @DESCENDANTS("Total_Customer"), @DESCENDANTS("All_Channels"))
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Total_Revenue", "Actual", "All_Products", "USD");
    )
ENDFIX
```

> ⚠️ **PROBLEM**: This writes to the SAME target intersection for each customer × channel combination! Each iteration **overwrites** the previous write. You DON'T get a sum — you get the LAST value that was written.

**Correct approach** — aggregate first, then write once:

```essbase
/* Option 1: FIX at top of source-only dims (pre-aggregated) */
FIX("FY25", @CHILDREN("Total Entity"), @CHILDREN("All Periods"),
    "Total_Customer", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Total_Revenue", "Actual", "All_Products", "USD");
    )
ENDFIX
```

Or if you need to calculate a per-customer value and sum it:

```essbase
/* Option 2: Compute the total in a variable first, then write once */
FIX("FY25", @CHILDREN("Total Entity"), @CHILDREN("All Periods"))
    VAR vTotalRev;

    /* First pass: Aggregate in the source cube */
    FIX("Total_Customer", "All_Channels")
        vTotalRev = "Net_Revenue";
    ENDFIX

    /* Second pass: Write the aggregated value */
    @XWRITE(vTotalRev, "FinStmt", "Total_Revenue", "Actual", "All_Products", "USD");
ENDFIX
```

---

#### Case E: Summary — Source-Only Dims Control VALUE, Target-Only Dims Control DESTINATION

```
┌──────────────────────────────────────────────────────────────────┐
│                    THE GOLDEN RULE                                │
│                                                                  │
│  Source-only dims in FIX  →  Control WHAT VALUE is read          │
│  (Customer, Channel)         from the source expression          │
│                                                                  │
│  Target-only dims in mbrList → Control WHERE VALUE lands         │
│  (Scenario, Product, Currency)  in the target cube               │
│                                                                  │
│  Shared dims (Account, Entity, Period, Year):                    │
│    - FIX sets the POV → flows to target automatically            │
│    - Can be overridden by mbrList if needed                      │
│                                                                  │
│  Source-only dims NOT in FIX → default to top of source dim      │
│  Target-only dims NOT in mbrList → default to top of target dim  │
└──────────────────────────────────────────────────────────────────┘
```

**The complete mental model:**

```
SOURCE (FIX)                              TARGET (@XWRITE)
═══════════                               ═════════════════
Shared dims in FIX     ──── POV ────────► Same member in target
                                          (unless overridden by mbrList)

Source-only dims in FIX ──── VALUE ──┐
                                     │    These dims have NO
                                     │    target equivalent.
                                     └──► They only determine
                                          what number gets read.

Target-only dims        NOT IN SOURCE     mbrList → specific member
                        ──────────────►   OR
                                          No mbrList → TOP MEMBER
                                          (⚠️ usually wrong!)
```

---

#### Practical Decision Matrix

| Your Goal | FIX (Source Side) | mbrList (Target Side) |
|-----------|-------------------|----------------------|
| Write one customer's revenue to a specific target account | FIX at detail customer level: `"Cust_001", "Online"` | `"Revenue_Online", "Actual", "Product_A", "USD"` |
| Write TOTAL revenue (all customers) to a summary account | FIX at top level: `"Total_Customer", "All_Channels"` | `"Total_Revenue", "Actual", "All_Products", "USD"` |
| Write each entity's total to the target (loop entities) | FIX: `@CHILDREN("Total Entity"), "Total_Customer"` | `"Revenue_Line", "Actual", "All_Products", "USD"` |
| Write different customer segments to different target products | Multiple FIX/XWRITE blocks (see below) | Different mbrList per block |

**Multiple blocks for segment-to-product mapping:**

```essbase
/* Map Customer segments to Product categories in target */

/* Enterprise customers → Enterprise_Product */
FIX("FY25", @CHILDREN("Total Entity"), "Enterprise_Customers", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Revenue_Line", "Actual", "Enterprise_Product", "USD");
    )
ENDFIX

/* SMB customers → SMB_Product */
FIX("FY25", @CHILDREN("Total Entity"), "SMB_Customers", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Revenue_Line", "Actual", "SMB_Product", "USD");
    )
ENDFIX

/* Consumer customers → Consumer_Product */
FIX("FY25", @CHILDREN("Total Entity"), "Consumer_Customers", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Revenue_Line", "Actual", "Consumer_Product", "USD");
    )
ENDFIX
```

This pattern effectively creates a **manual dimension-to-dimension mapping**: source `Customer` segments → target `Product` categories. Each FIX block reads a different segment from source, and the mbrList routes it to a different product in the target.

---

#### Case F: FIX Says FY25 but mbrList Says FY26 — What Happens? (Shared Dim Override)

This scenario is about **overriding a shared dimension**. Year exists in BOTH source and target. Normally the POV flows through automatically. But what if you specify a **different** member in mbrList?

```essbase
FIX("FY25", "East", "Jan", "Total_Customer", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Total_Revenue", "FY26", "Actual", "All_Products", "USD");
        /*                                                   ^^^^                                  */
        /*                                          mbrList overrides Year!                        */
    )
ENDFIX
```

**What happens step by step:**

**Step 1 — Reading the value (SOURCE side):**
- FIX locks Year to `FY25` on the source cube
- The expression `"Net_Revenue"` is evaluated at `East, Jan, FY25, Total_Customer, All_Channels`
- **The value read is FY25 data** — FIX controls what you read

**Step 2 — Writing the value (TARGET side):**

| Target Dim | POV (Priority 2) | mbrList (Priority 1) | **Final Value** | What Happened |
|------------|-------------------|----------------------|-----------------|---------------|
| Account | `Net_Revenue` | `Total_Revenue` | **`Total_Revenue`** | mbrList overrides POV ✅ |
| Entity | `East` | — | **`East`** | POV flows through |
| Period | `Jan` | — | **`Jan`** | POV flows through |
| Year | `FY25` | `FY26` | **`FY26`** | ⚡ **mbrList WINS** — overrides the shared dim! |
| Scenario | — | `Actual` | **`Actual`** | Target-only dim, set by mbrList |
| Product | — | `All_Products` | **`All_Products`** | Target-only dim, set by mbrList |
| Currency | — | `USD` | **`USD`** | Target-only dim, set by mbrList |

**Result**: FY25 revenue from the source is written to **FY26** in the target!

```
READ from:  Source → Net_Revenue, East, Jan, FY25, Total_Customer, All_Channels
WRITE to:   Target → Total_Revenue, East, Jan, FY26, Actual, All_Products, USD
                                                ^^^^
                                          Different year!
```

> **Key Insight**: The FIX controls **where you read from** (the source value). The mbrList controls **where you write to** (the target destination). They are independent. You can read FY25 data and write it to FY26. You can read East data and write it to West. The FIX and mbrList operate on different sides of the equation.

**Common use cases for this pattern:**

| Use Case | FIX (Read From) | mbrList (Write To) |
|----------|-----------------|-------------------|
| Copy last year's actuals as next year's budget seed | `FIX("FY25", "Actual")` | `"FY26", "Budget"` |
| Mirror one entity's plan to another | `FIX("East")` | `"West"` |
| Copy Working version to Final | `FIX("Working")` | `"Final"` |
| Reclassify one account to another | `FIX("Old_Account")` | `"New_Account"` |

**Example — Seed next year's budget from actuals:**

```essbase
/* Read FY25 Actual, write to FY26 Budget */
FIX("FY25", "Actual", @CHILDREN("Total Entity"), @CHILDREN("All Periods"))
    "Net_Revenue"(
        @XWRITE("Net_Revenue", @LOOPBACK, "Budget_Revenue", "FY26", "Budget");
        /*                                                   ^^^^    ^^^^^^   */
        /*                                    Override Year AND Scenario!     */
    )
ENDFIX
```

This reads each entity/period's FY25 Actual Net_Revenue and writes it as FY26 Budget Budget_Revenue — a classic **budget seeding** pattern.

---

## 🎯 Deep Dive: How FIX Works on Source vs. Target

This is one of the most misunderstood aspects of @XWRITE. The `FIX` statement operates **only on the source cube**. It has no direct control over the target.

### FIX = Source Scoping Only

```essbase
/* This FIX runs on the SOURCE cube */
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "100-30"(
        @XWRITE("100-30", @LOOPBACK, "100-20");
    )
ENDFIX
```

- The `FIX` scopes which data blocks to iterate **on the source cube**
- It determines the **Point of View** for each cell being calculated
- The FIX members become the **Priority 2** values in the mapping precedence
- The FIX does **NOT** create any scope or restriction on the target cube

### How FIX Controls What Gets Written to the Target

```
FIX on SOURCE                           Effect on TARGET
─────────────                           ────────────────
"FY25"                    ──POV──►      Year = FY25 (if Year exists in target)
"Working"                 ──POV──►      Scenario = Working (if Scenario exists in target)
@DESCENDANTS("Total Entity") ──POV──►   Entity = each descendant (if Entity exists in target)
```

The FIX controls the **iteration** — how many times @XWRITE fires and with what POV. Each iteration writes to a potentially different intersection in the target.

### Example: FIX Iterating Over Entities

```essbase
/* Source: Workforce cube */
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    "Salary_Cost"(
        @XWRITE("Salary_Cost", "FinStmt", "Salary_Expense");
    )
ENDFIX
```

If `Total Entity` has children: `East`, `West`, `Central`, this FIX causes @XWRITE to fire 3 times:

| Iteration | Source POV | Target Write Intersection |
|-----------|-----------|--------------------------|
| 1 | `East, FY25, Working, Salary_Cost` | `FinStmt → Salary_Expense, East, FY25, Working` |
| 2 | `West, FY25, Working, Salary_Cost` | `FinStmt → Salary_Expense, West, FY25, Working` |
| 3 | `Central, FY25, Working, Salary_Cost` | `FinStmt → Salary_Expense, Central, FY25, Working` |

### What You CANNOT Do with FIX on the Target

You **cannot** write a FIX that directly restricts or scopes the target cube. The target intersection is determined entirely by the three-tier precedence system. If you want to control where data lands in the target:

1. **Use `mbrList`** — specify target members explicitly in the @XWRITE call
2. **Structure your source FIX** — scope your source so the POV members map correctly to the target
3. **Use variables** — calculate target member values dynamically

### Example: Controlling Target Destination via mbrList

```essbase
/* Source: Workforce, Target: FinStmt */
/* Target has a "Department" dim that source doesn't have */
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    "Salary_Cost"(
        /* Explicitly set target Account AND Department */
        @XWRITE("Salary_Cost", "FinStmt", "Salary_Expense", "HR_Department");
    )
ENDFIX
```

Without `"HR_Department"` in the mbrList, the Department dimension would fall back to its top member (e.g., `Total Department`).

---

## ✅ What's Allowed in @XWRITE

### Allowed in the `expression` Parameter (1st argument)

| Construct | Example | Notes |
|-----------|---------|-------|
| Member reference | `"100-30"` | References the value of that member |
| Variable | `vTotalComp` | Previously defined VAR |
| Arithmetic expression | `"Base" + "Bonus"` | Any numeric calculation |
| Function returning single value | `@PARENT("100-30")` | Functions that return ONE value |
| Constants | `100` or `0` | Literal numeric values |
| Cross-dimensional operator | `"Revenue" -> "East"` | Pulling specific intersection |
| @XREF inside @XWRITE | `@XREF("OtherPlan", "Rate")` | Read from one cube, write to another |

### Allowed in `mbrList` Parameter (3rd argument onward)

| Construct | Allowed? | Notes |
|-----------|----------|-------|
| Individual member names | ✅ Yes | `"100-20"`, `"East"`, `"Actual"` |
| Multiple members (different dims) | ✅ Yes | `"100-20", "East", "Actual"` |
| Members from different dims | ✅ Yes | Each member must be from a different dimension |

### NOT Allowed in `mbrList`

| Construct | Allowed? | Why Not |
|-----------|----------|---------|
| Functions returning multiple members | ❌ No | e.g., `@LEVMBRS(Market, 0)` — returns a list, not a single member |
| Member ranges | ❌ No | e.g., `"Jan":"Dec"` — ranges are not supported |
| Attribute members | ❌ No | Attribute members/operators cannot be used |
| Attribute operators | ❌ No | e.g., `@ATTRIBUTE(...)` functions |
| Cross-dimensional operators | ❌ No | `->` not supported in mbrList |
| Duplicate dimension coverage | ❌ No | Cannot specify two members from the same dimension |

### Other Restrictions

| Rule | Details |
|------|---------|
| BSO only | @XWRITE works only with block storage cubes |
| No write to Dynamic Calc members | @XWRITE to dynamic calc cells is not recommended; data is calculated in memory but not written |
| Members must exist in target | An error is returned if any member in mbrList does not exist in the target cube |
| Top-down formula | @XWRITE is a top-down formula — parents calculate before children |

---

## Practical Examples

### Example 1: Simple Write to Same Cube (@LOOPBACK)

**Scenario**: Copy values from product `100-30` to product `100-20` within the same cube.

```essbase
FIX(East, Actual, Budget, Sales)
    "100-30"(
        @XWRITE("100-30", @LOOPBACK, "100-20");
    )
ENDFIX
```

**What Happens**:
- FIX scopes to `East, Actual, Budget, Sales` on the source cube
- For each cell of `100-30` within that scope, the value is read
- @LOOPBACK writes it back to the same cube at `100-20`
- All other dimensions retain their current POV (East, Actual, Budget, Sales)

---

### Example 2: Write to Remote Cube via Location Alias

**Scenario**: Push `100-30` values from `Sample Basic` to `Sample2 Basic` using location alias `sam2basic`.

```essbase
FIX(East, Actual, Budget, Sales)
    "100-30"(
        @XWRITE("100-30", sam2basic, "100-20");
    )
ENDFIX
```

**What Happens**:
- Same as Example 1, but writes to the remote cube identified by `sam2basic`
- The location alias contains connection info (server, app, cube, credentials)

---

### Example 3: Using a Function Inside @XWRITE Expression

```essbase
FIX(East, Actual, Budget, Sales)
    "100"(
        @XWRITE(@PARENT("100-30"), @LOOPBACK, "100-20");
    )
ENDFIX
```

**What Happens**:
- `@PARENT("100-30")` returns the parent of member `100-30`
- That parent's value is used as the expression — the value to write
- The value is written to `100-20` in the same cube

---

### Example 4: Push Workforce Costs to FinStmt (Different Dimensions)

**Scenario**: Workforce cube has `Grade` and `Position` dimensions. FinStmt has `Product` and `Currency` dimensions. Shared dimensions: Account, Entity, Period, Year, Scenario.

```
SOURCE (Workforce):                     TARGET (FinStmt):
├── Account                             ├── Account
├── Entity                              ├── Entity
├── Period                              ├── Period
├── Year                                ├── Year
├── Scenario                            ├── Scenario
├── Grade      ← source only            ├── Product    ← target only
├── Position   ← source only            ├── Currency   ← target only
```

```essbase
/* Running in Workforce plan type */
FIX("FY25", "Working", @DESCENDANTS("Total Entity"), @CHILDREN("All Periods"))
    "Total_Compensation"(
        /* Explicitly set target Account; Product and Currency will default to top members */
        @XWRITE("Total_Compensation", "FinStmt", "Salary_Expense");
    )
ENDFIX
```

**Mapping Result for each iteration (e.g., East, Jan)**:

| Target Dimension | Resolved From | Value |
|------------------|---------------|-------|
| Account | mbrList | `Salary_Expense` |
| Entity | POV | `East` (current entity being looped) |
| Period | POV | `Jan` (current period being looped) |
| Year | POV | `FY25` |
| Scenario | POV | `Working` |
| Product | Top Member (fallback) | `Total Product` |
| Currency | Top Member (fallback) | `Total Currency` |

**Source-only dimensions** (`Grade`, `Position`) are completely irrelevant — the target has no corresponding slots.

> ⚠️ **Warning**: If you don't want data landing at `Total Product` and `Total Currency`, you MUST specify those members in the mbrList:
> ```essbase
> @XWRITE("Total_Compensation", "FinStmt", "Salary_Expense", "No_Product", "USD");
> ```

---

### Example 5: Conditional Write with Member Override

```essbase
/* Running in Workforce plan type */
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF("Headcount" > 0)
        @XWRITE("Headcount" * "Avg_Salary", "FinStmt", "Salary_Expense");
    ENDIF
ENDFIX
```

**What Happens**:
- Only writes when Headcount > 0 — avoids writing zeros or #MISSING
- Calculates the product of Headcount and Avg_Salary
- Pushes the result to FinStmt's Salary_Expense member

---

### Example 6: Multiple @XWRITE Calls for Different Target Members

```essbase
/* Running in Capital plan type */
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Monthly_Depreciation"(
        @XWRITE("Monthly_Depreciation", "FinStmt", "Depreciation_Expense");
    )
    "Accumulated_Depreciation"(
        @XWRITE("Accumulated_Depreciation", "FinStmt", "Accum_Depreciation");
    )
ENDFIX
```

---

### Example 7: Exchange Rate Application and Cross-Cube Push

```essbase
/* Running in Rates plan type — read from FinStmt, apply rate, write back */
FIX("FY25", @DESCENDANTS("International"))
    VAR vRate = "Closing_Rate";
    @XWRITE(@XREF("FinStmt", "Revenue_Local") * vRate, "FinStmt", "Revenue_Reported");
ENDFIX
```

**What Happens**:
- `@XREF` reads `Revenue_Local` from FinStmt
- Multiplies by `Closing_Rate` from the current cube (Rates)
- `@XWRITE` pushes the result back to FinStmt at `Revenue_Reported`
- Effectively reads from one target intersection, transforms, writes to another

---

### Example 8: Source Has Unique Dims — Writing Summarized Data

**Scenario**: Revenue Detail cube has `Customer` and `Channel` dims not in FinStmt. You want to push total revenue by entity.

```essbase
/* Running in Revenue Detail plan type */
/* FIX at a summary level so you don't write per-customer detail */
FIX("FY25", "Actual", @CHILDREN("Total Entity"), "Total_Customer", "All_Channels")
    "Net_Revenue"(
        @XWRITE("Net_Revenue", "FinStmt", "Total_Revenue");
    )
ENDFIX
```

**Key Insight**: The FIX includes `"Total_Customer"` and `"All_Channels"` — these are source-only dimensions used to **aggregate** the value before writing. The target doesn't care about these dimensions; they're ignored in target mapping. But they're critical for ensuring the **correct value** is being written.

---

## 🔄 @XWRITE vs. @XREF — Side by Side

| Aspect | @XREF | @XWRITE |
|--------|-------|---------|
| Direction | READ from another cube | WRITE to another cube |
| Location Alias Role | Represents the **data source** | Represents the **data target** |
| Returns a value? | ✅ Yes — numeric value | ❌ No — performs a write |
| @LOOPBACK | Not applicable | ✅ Yes — write to same cube |
| Same location alias? | ✅ Yes — can share with @XWRITE | ✅ Yes — can share with @XREF |
| Formula type | N/A | Top-down formula |

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| **Expecting immediate visibility** | @XWRITE is buffered — target doesn't update mid-script | Results are visible only after the entire script completes |
| **Not specifying target-only dimensions** | Dimensions that exist only in the target will default to their top member — this is often not what you want | Explicitly specify those members in mbrList |
| **Using multi-member functions in mbrList** | `@LEVMBRS(Market,0)` returns a list and is not allowed | Use individual member names only |
| **Using ranges in mbrList** | `"Jan":"Dec"` is not supported | Specify each member individually or restructure the logic |
| **Using attribute members in mbrList** | Attribute members/operators are not supported | Use stored dimension members |
| **Writing to Dynamic Calc cells** | Data is calculated in memory but not written to disk | Ensure target members are stored, not dynamic calc |
| **Member doesn't exist in target** | Runtime error if mbrList contains a member not in the target outline | Verify member names in the target cube's outline |
| **Wrong plan type name** | Typo in plan type name causes runtime error | Verify exact name in application settings |
| **High-volume @XWRITE performance** | Writing millions of cells via @XWRITE is slow (cross-database network overhead) | Consider Data Maps, Smart Push, or DATACOPY for bulk transfers |
| **Circular references** | @XREF + @XWRITE between same plan types in same rule creating loops | Avoid reading and writing to the same target intersection in the same pass |
| **Assuming FIX controls the target** | FIX only scopes the source cube iteration — it does not restrict or filter the target | Use mbrList to control where data lands in the target |
| **Source-only dims in mbrList** | Specifying a member from a source-only dimension in mbrList — that member won't exist in the target | Only specify members from dimensions that exist in the TARGET |

---

## ⚠️ Performance Considerations

| Consideration | Recommendation |
|---------------|----------------|
| Each @XWRITE is a cross-database write | Minimize the number of @XWRITE calls per script |
| Network overhead for remote cubes | If target is remote, network latency multiplies with each write |
| Use narrow FIX | Scope your FIX to only the data you actually need to write |
| Bulk alternatives | For large data movements, consider **Smart Push**, **Data Maps**, or **DATACOPY** |
| Avoid redundant writes | Use `IF` conditions to skip cells with #MISSING or zero |
| Avoid nested loops with @XWRITE | Each @XWRITE in a nested loop multiplies the number of writes exponentially |

---

## 🆚 Alternatives to @XWRITE

| Method | When to Use |
|--------|-------------|
| **@XWRITE** | Real-time calculation-based write during a business rule; when you need transformation logic |
| **Smart Push** | Post-calculation data push between plan types; provides GUI mapping |
| **Data Maps** | Complex dimension mappings with member-to-member rules; visual configuration |
| **DATACOPY** | Simple bulk copy within the same cube or between plan types (no transformation) |
| **Data Integration** | ETL-style data movement with scheduling and more complex mapping |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@XREF`](./@XREF.md) | Cross-database READ (opposite of @XWRITE) |
| [`DATACOPY`](../03_Calc_Commands/DATACOPY.md) | Bulk data copy — faster for large volumes |
| [`FIX`](../01_Flow_Control/FIX.md) | Scopes @XWRITE operations on the source cube |

---

## Official Oracle Reference

- [Oracle Essbase 21 — @XWRITE](https://docs.oracle.com/en/database/other-databases/essbase/21/esscq/xwrite.html)
- [Understand XREF/XWRITE](https://docs.oracle.com/pls/topic/lookup?ctx=en/database/other-databases/essbase/21/esscq&id=UGESS-GUID-F8BB3012-42C8-4A96-B18C-B8D68EC8A056)
- [Create a Location Alias](https://docs.oracle.com/pls/topic/lookup?ctx=en/database/other-databases/essbase/21/esscq&id=UGESS-GUID-6CF2B0AB-9E8D-47B1-92F5-112D7A31D841)
