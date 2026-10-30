# Oracle EPM: The Ultimate Master Guide to Allocations (EPBCS / PBCS)

---

## Table of Contents

1. [Conceptual Foundation: What Is Allocation & Why It Exists](#1-conceptual-foundation-what-is-allocation--why-it-exists)
2. [The Two Allocation Mechanisms in EPM Cloud](#2-the-two-allocation-mechanisms-in-epm-cloud)
3. [Allocation Component — Deep Dive](#3-allocation-component--deep-dive)
4. [Allocation Template — Deep Dive](#4-allocation-template--deep-dive)
5. [The @ALLOCATE Essbase Calc Function](#5-the-allocate-essbase-calc-function)
6. [Major Allocation Rule Types (Performance Hierarchy)](#6-major-allocation-rule-types-performance-hierarchy)
7. [Allocation Rule Types & Allowed Member Selection Options](#7-allocation-rule-types--allowed-member-selection-options)
8. [Allocation Methods Explained: Share, Spread, Percent, Add, Subtract, Multiply, Divide](#8-allocation-methods-explained)
9. [Rounding: Every Option Dissected](#9-rounding-every-option-dissected)
10. [Lifecycle Operations: Open, Edit, Copy, Paste, Save, Delete](#10-lifecycle-operations-open-edit-copy-paste-save-delete)
11. [Real-World Worked Examples](#11-real-world-worked-examples)
12. [Do's & Don'ts — The Definitive Checklist](#12-dos--donts--the-definitive-checklist)
13. [What Happens Before → During → After an Allocation](#13-what-happens-before--during--after-an-allocation)
14. [Troubleshooting & Common Errors](#14-troubleshooting--common-errors)
15. [Quick-Reference Decision Flowchart](#15-quick-reference-decision-flowchart)
16. [Glossary](#16-glossary)

---

## 1. Conceptual Foundation: What Is Allocation & Why It Exists

### The Business Problem

In enterprise planning, budgets and actuals are often loaded or entered at **summary (parent/aggregate) levels** — for example, Total Administrative Expenses at the company level. However, reporting, analysis, and downstream planning require this data to be **spread (allocated) to granular, lower-level (level 0) members** — for example, splitting administrative expenses across individual departments, products, or cost centers.

### What Allocation Does

Allocation is the process of distributing (spreading) a numeric value from a **source** intersection to multiple **target** intersections. The distribution can be:

| Approach | Description | Example |
|---|---|---|
| **Evenly** | Equal split across all targets | $12,000 ÷ 4 products = $3,000 each |
| **Driver-Based** | Proportional split using a "basis" or "driver" metric | $12,000 split by headcount: Dept A (60 heads) gets $8,000, Dept B (30 heads) gets $4,000 |
| **Percentage** | Explicit percentage applied per target | $12,000 × 25% = $3,000 per target |
| **Arithmetic** | Add/Subtract/Multiply/Divide a value from the driver | Amount + driver value per member |

### Where Allocation Lives in the Architecture

```
┌──────────────────────────────────────────────────────┐
│                  Oracle EPM Cloud                     │
│                                                      │
│  ┌─────────────┐    ┌──────────────────────┐         │
│  │ Planning Hub │───▶│  Calculation Manager │         │
│  │ (Web Forms)  │    │  (Rule Designer)     │         │
│  └─────────────┘    └────────┬─────────────┘         │
│                              │                        │
│              ┌───────────────┼───────────────┐        │
│              ▼               ▼               ▼        │
│     ┌────────────┐  ┌──────────────┐  ┌──────────┐   │
│     │ Allocation │  │  Allocation  │  │ Formula  │   │
│     │ Component  │  │  Template    │  │Component │   │
│     │ (Graphical)│  │  (System)    │  │(@ALLOCATE│   │
│     └──────┬─────┘  └──────┬───────┘  └────┬─────┘   │
│            │               │               │          │
│            └───────────────┼───────────────┘          │
│                            ▼                          │
│               ┌────────────────────┐                  │
│               │   Oracle Essbase   │                  │
│               │ (Calc Engine/BSO)  │                  │
│               └────────────────────┘                  │
└──────────────────────────────────────────────────────┘
```

**Key Insight:** Regardless of which approach you choose (Allocation Component, Allocation Template, or raw @ALLOCATE script), the calculation ultimately runs on the **Essbase engine**. The Component and Template are graphical/wizard-based wrappers that generate the underlying Essbase calc script for you.

---

## 2. The Two Allocation Mechanisms in EPM Cloud

Oracle EPM Cloud provides **two primary graphical tools** for allocations, plus the raw Essbase function:

| Feature | Allocation Component | Allocation Template | @ALLOCATE (Script) |
|---|---|---|---|
| **Created From** | New Objects Palette → drag into Business Rule flowchart | System Templates → drag into Business Rule or Template | Written directly in calc script or Formula Component |
| **Belongs To** | A single Business Rule (cannot be shared) | Can be used in Business Rules and Templates | Any calc script or member formula |
| **Configuration** | Allocate Wizard (multi-step) | Allocation Wizard (multi-step) | Manual syntax |
| **Shareable** | ❌ No — exists only in its parent rule | ✅ Yes — can be used in templates across rules | ✅ Yes — via script include or member formulas |
| **Flexibility** | Medium — wizard-guided | Medium — wizard-guided with additional options (offset, spread method, percentage source) | Maximum — full Essbase calc language |
| **Best For** | Quick, straightforward allocations within a single rule | Repeatable allocation patterns, offset accounting, percentage-of-source | Complex multi-step allocations, conditional logic, custom rounding |

### When to Use What

| Scenario | Recommended Approach |
|---|---|
| Simple one-time cost allocation within a single rule | **Allocation Component** |
| Standardized allocation pattern reused across multiple rules | **Allocation Template** |
| Allocation with offsetting journal entries | **Allocation Template** (has built-in Offset step) |
| Complex, multi-pass allocation with conditional logic | **@ALLOCATE in a Formula/Script Component** |
| Need to allocate a percentage of the source (e.g., 25%) | **Allocation Template** (Source step allows percentage entry) |
| Performance-critical allocations on large cubes | **@ALLOCATE with FIX** (maximum control over calc order) |

---

## 3. Allocation Component — Deep Dive

### 3.1 What It Is

An Allocation Component is a **graphical building block** that you drag into a Business Rule's flowchart in the **Calculation Manager Rule Designer**. It generates an Essbase allocation calculation behind the scenes.

**Critical Facts:**
- It **exists only** within the business rule where it is created.
- It **cannot be shared** across business rules.
- If the parent business rule is deleted, the allocation component is deleted with it.
- It can be placed **inside** a Point of View (POV) component to inherit dimension members from that POV.
- If you drop a POV within another POV, the inner POV inherits members from the outer POV.

### 3.2 Creating an Allocation Component — Every Wizard Step Explained

Navigate: **System View → Right-click a Business Rule → Open → Rule Designer → New Objects Palette → drag "Allocation" into the flowchart**

The **Allocate Wizard** opens with the following steps:

---

#### Step 1: Point of View (POV)

**What It Does:** Defines the dimensions (and their members) that **do NOT vary** during the allocation. These are your "fixed" dimensions — every allocated value will be written to these exact members.

**How to Select Members:**
| Method | How | When to Use |
|---|---|---|
| **Use Predefined Selection** | Click the Variable Selector icon → select a saved variable set | When you have reusable member selections saved |
| **Member Selector** | Click the Member Selector icon → pick members from the tree | For one-off, specific member picks |
| **Actions Menu** | Select a dimension in the list → click Actions → choose member, variable, or function | When you need a function like `@RELATIVE` or a runtime prompt variable |

**Rules & Constraints:**
- You **must** select at least one member for the POV.
- All members you select in the POV **must be valid level 0 members** (the lowest-level, leaf members with no children).
- The POV establishes the "fixed context" — dimensions not specified here are defined in Source, Range, Target, etc.

**Effect:** Every allocation result (target cell) will include these POV members as part of its intersection. For example, if POV sets `Scenario = Budget, Version = Working`, then every allocated value is written to Budget → Working.

**Common Mistake:** Selecting a parent member (e.g., `"All Entities"`) in the POV. This causes the allocation to attempt writing to a non-level-0 intersection, which will either error or silently skip.

---

#### Step 2: Source

**What It Does:** Defines the **origin** of the data you want to allocate. This is "where the money is coming from."

**How to Select Members:**
- Same three methods as POV (Predefined Selection, Member Selector, Actions).

**Rules & Constraints:**
- You **must** select a member for **every** dimension listed.
- Source members **can be non-level 0 members** (parents/aggregates). This is a critical difference from POV! For example, you can source from `"Total Expenses"` (a parent), and the system reads the aggregated value.
- You **cannot use functions** in this step (e.g., no `@CHILDREN`, no `@RELATIVE`). Only explicit members or variables.
- If a Predefined Selection does not fill all dimensions, you must manually fill the remaining ones.

**Optional — Fixed Amount:**
Instead of reading a value from the database, you can **type a specific number** in the "Optional" field. This overrides the Source member selection and allocates exactly that amount.

**Zero-Value Handling:**
If the source amount is zero, you must choose:
| Option | Effect |
|---|---|
| **Select the next pool record** | Skips this source and moves to the next allocation pool record |
| **Stop processing the allocation** | The entire allocation rule halts — no data is written |

**Effect:** The system reads the value at the intersection defined by (POV members + Source members). This value becomes the "amount" to be distributed.

---

#### Step 3: Allocation Range

**What It Does:** Defines **which dimension** and **which parent member** will be used to identify the target cells. The data is allocated to the **level 0 descendants** (leaf members) beneath the parent you specify.

**How to Select Members:**
- Same three methods as POV.

**Rules & Constraints:**
- Select the **parent member** of the dimension you want to allocate across.
- The allocation writes to **level 0 members only** — the system automatically resolves all leaf-level children under that parent.
- For example, if you set Allocation Range = `"Total Products"`, and Total Products has children A, B, C (all level 0), data goes to A, B, and C.

**Clear Region Option:**
| Setting | Effect |
|---|---|
| **Yes** | Before the allocation runs, the system clears (sets to `#MISSING`) the target region. This prevents "stale" data from prior runs from mixing with the new allocation. You must specify the clear region members in the next step (Step 4 / Clear Region). |
| **No** | The allocation writes on top of whatever already exists. Use when you want additive behavior (e.g., multiple allocations contributing to the same target). |

**Effect:** Determines the "spread dimension" and the scope of the allocation.

**Common Mistake:** Choosing a parent that has children at multiple levels (e.g., `@DESCENDANTS` returning both level 1 and level 0). The allocation targets **only level 0** — upper-level members are ignored, which may cause unexpected shortfalls if your hierarchy is unbalanced.

---

#### Step 4: Target

**What It Does:** For the remaining dimensions (those not already fixed by POV or Allocation Range), specifies the **exact level 0 member** to which allocated data is written.

**Rules & Constraints:**
- All target members **must be level 0**.
- Every dimension not already specified must have a target member.

**Effect:** Completes the target intersection. The final write location is: `(POV members) × (Allocation Range level 0 members) × (Target members)`.

---

#### Step 5: Clear Region (Conditional)

**When It Appears:** Only if you selected **"Yes"** to clear the region in the Allocation Range step.

**What It Does:** Specifies which members' data should be **logically cleared** (set to `#MISSING`) before the allocation writes new values.

**Rules & Constraints:**
- Select level 0 members to clear.
- The clear happens **before** the allocation write, ensuring a clean slate.

**Effect:** Prevents double-counting from prior allocation runs.

**Common Mistake:** Forgetting to set this when "Yes" is selected — the system may skip the clear, leading to accumulated stale data.

---

#### Step 6: Offset

**What It Does:** Specifies the intersection where the **offsetting (balancing) entry** is written. This ensures the total net effect of the allocation is zero (debit the targets, credit the offset — or vice versa).

**Rules & Constraints:**
- You **must specify** members for the offset — **it cannot be left empty**.
- The offset value is typically the negative of the total allocated amount.

**Effect:** After the allocation writes $10,000 across 5 products ($2,000 each), the offset writes -$10,000 to the specified offset member. This keeps your books balanced.

**Common Mistake:** Leaving offset members blank. The wizard will raise an error. If you truly don't want an offset, use the Allocation Template instead (where Offset is optional).

---

#### Step 7: Exclude (Optional)

**What It Does:** Removes specific members from the Allocation Range, so they receive **no allocated data** and their driver values are excluded from basis calculations.

**Effect:** If Allocation Range = children of `"Total Products"` but you exclude Product D, then:
- Product D gets $0 (no allocation).
- Product D's driver value is NOT counted in the denominator for share/percentage calculations.

**When to Use:** Inactive products, discontinued departments, or any member you want to "protect" from receiving allocations.

---

#### Step 8: Basis (Allocation Method)

**What It Does:** Defines **how** the source amount is split across the allocation range.

**Two Primary Methods:**

| Method | Description | Configuration |
|---|---|---|
| **Allocate Evenly** | Splits the source amount equally across all level 0 members in the Allocation Range (minus any excluded members) | Select "Allocate evenly" → configure Basis Options for edge cases |
| **Allocate Using a Driver** | Uses a "driver" metric (e.g., headcount, square footage, revenue) to calculate each member's proportional share | Select "Allocate using a driver" → specify the driver member/location → configure Basis Options |

**Basis Options — Edge Case Handling:**

For **Allocate Evenly**:
| Scenario | Options | Recommendation |
|---|---|---|
| Basis is negative | Choose behavior (proceed, skip, stop) | Depends on business logic — typically "proceed" |
| Basis is zero | Choose behavior | Typically "skip" to avoid division-by-zero |
| Basis has missing values | Choose behavior | Typically "skip missing" to allocate only to populated members |
| All members excluded | Choose behavior | Typically "stop" — nothing to allocate to |

For **Allocate Using a Driver**:
| Scenario | Options | Recommendation |
|---|---|---|
| Driver basis is negative | Choose behavior | Business-dependent |
| Driver basis is zero | Choose behavior | "Skip" — avoids division by zero |

**Driver Member Selection:**
- Dimensions not specified for the driver **inherit from the POV**.
- You can override POV selections for the driver by explicitly selecting different members.
- The driver value for each member in the Allocation Range determines its share: `(member's driver value / sum of all driver values) × source amount`.

**Effect:** This is the core mathematical engine of the allocation.

---

#### Step 9: Rounding

**What It Does:** Controls how allocated values are rounded and where rounding differences are placed.

| Setting | Description |
|---|---|
| **Number of decimal places** | Enter an integer (e.g., `2` for two decimal places). You can also use a variable or member reference. |
| **Define location** | You choose a specific member on which to place the rounding difference. That member **must be in the Allocation Range**. |
| **Use biggest value** | Adds the rounding difference to the member that received the **largest** allocated value. |
| **Use smallest value** | Adds the rounding difference to the member that received the **smallest** allocated value. |
| **Discard rounding error** | Allocated values are used as-is. The sum of allocated values may not exactly equal the source — the difference is silently discarded. |

**Effect:** Ensures that allocated values sum exactly to the source (unless "Discard" is selected).

**Example:**
- Source: $10,000 allocated across 3 products.
- Even split: $3,333.33 × 3 = $9,999.99 → rounding difference = $0.01.
- "Use biggest value": The product with the highest allocation gets $3,333.34.

---

#### Final Step: Finish

Click **Finish** to save the allocation component into the business rule's flowchart.

---

### 3.3 Visual Summary: Allocation Component Data Flow

```
┌──────────────────┐
│   SOURCE         │  (Where the data comes from)
│   e.g. "Total    │  Member can be parent/aggregate
│   Expenses"      │  Reads value: $12,000
│   Budget, FY25   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐    ┌─────────────────┐
│   POV (Fixed)    │    │  EXCLUDE        │
│   Scenario=Budget│    │  Product D      │
│   Version=Working│    │  (Gets $0)      │
│   Year=FY2025    │    └─────────────────┘
└────────┬─────────┘
         │
         ▼
┌──────────────────┐    ┌─────────────────┐
│ ALLOCATION RANGE │    │   DRIVER/BASIS  │
│ Parent: "Total   │    │   Revenue or    │
│ Products"        │    │   Headcount     │
│ Targets: Level 0 │    │   (Proportional)│
│ A, B, C          │    │   OR "Even"     │
└────────┬─────────┘    └────────┬────────┘
         │                       │
         ├───────────────────────┘
         ▼
┌──────────────────┐    ┌─────────────────┐
│   TARGET         │    │   OFFSET        │
│   Product A=$4k  │    │   Source member  │
│   Product B=$5k  │    │   gets -$12,000 │
│   Product C=$3k  │    │   (Balancing     │
│   (Level 0 only) │    │    entry)        │
└──────────────────┘    └─────────────────┘
         │
         ▼
┌──────────────────┐
│   ROUNDING       │
│   2 decimal places│
│   Diff → biggest │
│   value member   │
└──────────────────┘
```

---

## 4. Allocation Template — Deep Dive

### 4.1 What It Is

The Allocation Template is a **system-provided template** in Calculation Manager that provides a wizard-driven interface for building allocations. Unlike the Allocation Component, it offers:
- **Offset as an optional step** (not mandatory).
- **Percentage-of-source** capability (e.g., allocate only 25% of the source).
- **Spread Method** selection when using "allocate evenly."
- Can be used in both **Business Rules** and **Templates** (reusable).

### 4.2 How to Access

- **Graphical Rule/Template:** Under **New Objects** palette → select **Allocation** → drop into flowchart between Begin and End.
- **Script Rule/Template:** Expand **System Templates** → select **Allocation** → drop into the script area.

### 4.3 Allocation Wizard — Every Step Explained

---

#### Step 1: Information

**What It Shows:** A description of the template's function. Read-only. No configuration needed.

**Effect:** None — purely informational.

---

#### Step 2: Point of View

**What It Does:** Identical to the Allocation Component's POV step. Defines the fixed (non-varying) dimensions.

**Rules:**
- Select at least one member from one dimension.
- All selected members should be level 0.

**Member Selection Options:**
| Method | Icon | Description |
|---|---|---|
| Use Predefined Selection | Variable Selector 🔘 | Select variables to populate all dimensions |
| Member Selector | Member Selector 📋 | Select members for each dimension individually |
| Actions | Select ⚙️ | Select a variable, member, or function for a specific dimension |

---

#### Step 3: Source

**What It Does:** For each dimension, select the member **from which** to allocate data.

**Key Difference from Component:** The Template allows you to enter the **percentage of the source** to allocate.

| Field | Description | Example |
|---|---|---|
| Member per dimension | The source member for each dimension | `Account = "Admin Expenses"` |
| Percentage to allocate | What fraction of the source value to spread | Enter `25` to allocate 25% of the source value |

**Effect:** If the source intersection holds $40,000 and you enter 25, the amount to be allocated is $10,000.

---

#### Step 4: Allocation Range

**What It Does:** Select the dimension and parent member to identify the allocation targets. Data goes to **level 0 members** beneath the parent.

**Effect:** Identical to Component — defines the "spread dimension."

---

#### Step 5: Destination — Target

**What It Does:** Specify a target member for each dimension defined in the source (for dimensions not covered by POV or Allocation Range).

**Rules:**
- Target members must be level 0.
- Every dimension must be accounted for across POV + Range + Target.

---

#### Step 6: Destination — Offset (Optional)

**What It Does:** Creates an **offsetting (balancing) entry** so the allocation doesn't double-count.

**This step has three sub-options:**

| Option | Description |
|---|---|
| **Offset Members** | Specify one member per dimension for the offset intersection |
| **Clear offset data before allocation** | Yes/No — if Yes, the offset region is cleared to `#MISSING` before the allocation runs |
| **Opposite sign** | Yes/No — if Yes, the offset value is the negative of the allocated total. For example, if $1,000 is allocated out, the offset writes -$1,000 |

**Real-World Example:**
> You have $1,000 in `Admin Expenses → Corporate`. You allocate it to `Admin Expenses → Dept A, Dept B, Dept C`. Without an offset, your total is now $2,000 ($1,000 original + $1,000 allocated). With an offset writing -$1,000 to `Admin Expenses → Corporate`, the net is correct: $1,000 total.

**Key Difference from Component:** In the Allocation Component, offset is **mandatory** (cannot be left empty). In the Template, offset is **optional** — you can skip it entirely.

---

#### Step 7: Exclude (Optional)

**What It Does:** Select members to exclude from the allocation range.

**Effect:** Excluded members:
- Receive **no allocated data** ($0 / #MISSING).
- Their driver values are **excluded from the basis percentage** calculation.

---

#### Step 8: Driver

**What It Does:** Define the allocation method.

| Option | Description |
|---|---|
| **Allocate using a driver** | Uses a driver metric to calculate proportional shares. Select one member per dimension for each dimension that varies from the POV. |
| **Allocate evenly** | Splits equally. Proceeds to the Spread Method step. |

**Inheritance Rule:** Dimensions you leave empty in the Driver step **inherit** from:
1. The POV (first priority)
2. Upper member ranges defined earlier in the rule

---

#### Step 9: Spread Method (Only if "Allocate Evenly" was selected)

**What It Does:** Configures how the "even" allocation handles edge cases.

**Options:**

| Spread Option | Description |
|---|---|
| **Spread, Skip None** | Divide evenly across ALL members, including those with zero or #MISSING driver values |
| **Spread, Skip Missing** | Divide evenly but exclude members with #MISSING driver values |
| **Spread, Skip Zero** | Divide evenly but exclude members with zero driver values |
| **Spread, Skip Both** | Divide evenly but exclude members with both zero and #MISSING driver values |

---

#### Step 10: Other Options (Including Rounding)

**What It Does:** Additional configuration, primarily rounding.

**Rounding Methods:**

| Method | Next Step | Description |
|---|---|---|
| **Define Rounding Member** | → "Rounding on Member" | Enter decimal places + select a specific member to absorb the rounding difference. That member must be in the allocation range. |
| **Use Biggest Value** | → "Round on Biggest" | Enter decimal places. Rounding difference goes to the member with the largest allocated value. |
| **Use Smallest Value** | → "Round on Smallest" | Enter decimal places. Rounding difference goes to the member with the smallest allocated value. |
| **No Rounding** | (No additional steps) | Values are not rounded. Rounding differences are silently discarded. |

---

### 4.4 Component vs. Template: Side-by-Side Comparison

| Feature | Allocation Component | Allocation Template |
|---|---|---|
| Offset | **Mandatory** (must specify members) | **Optional** (can skip entirely) |
| Source Percentage | ❌ Not available (allocates 100%) | ✅ Can specify percentage (e.g., 25%) |
| Spread Method Step | ❌ Not a separate step | ✅ Dedicated step with Skip options |
| Shareability | ❌ Tied to one rule | ✅ Usable in templates across rules |
| Zero Source Handling | Choose: next pool record / stop | Not explicitly surfaced (handled in Basis Options) |
| Script vs. Graphical | Graphical only | Both graphical and script modes |
| Clear Region | Explicit step with member selection | Handled within Offset step (clear offset data) |

---

## 5. The @ALLOCATE Essbase Calc Function

### 5.1 What It Is

`@ALLOCATE` is the **native Essbase calculation function** that both the Allocation Component and Template generate behind the scenes. Writing it directly gives you maximum control.

### 5.2 Full Syntax

```
@ALLOCATE (
    amount,
    allocationRange,
    basisMbr,
    [roundMbr],
    method [, methodParams]
    [, round [, numDigits] [, roundErr]]
)
```

### 5.3 Every Parameter Explained

---

#### `amount`

**What:** The value to be allocated. Can be:

| Type | Example | Notes |
|---|---|---|
| A constant | `10000` | Allocates exactly this number |
| A member | `Budget` | Reads the value from that member's cell |
| A cross-dimensional member | `Budget->"Total Expenses"` | Reads from a specific intersection |

**Rules:**
- If `amount` is a member, it **must be from the same dimension** as `allocationRange`.
- If `amount` is a cross-dimensional member, **at least one member** must be from the same dimension as `allocationRange`.
- `amount` **cannot be a Dynamic Calc member** if it's a loaded value (Dynamic Calc members are calculated on-the-fly and have no stored value to read).

---

#### `allocationRange`

**What:** The list of members **into which** the value is distributed.

| Type | Example | Notes |
|---|---|---|
| Explicit list | `"Product A", "Product B", "Product C"` | Comma-delimited |
| Member set function | `@CHILDREN("Total Expenses")` | Dynamic — picks up hierarchy changes automatically |
| Range function | `@RANGE("Product A", "Product C")` | Positional range in outline |

**Best Practice:** Use members from **a single level** (e.g., `@CHILDREN` rather than `@DESCENDANTS`) to avoid allocating to members at different aggregation levels, which produces unexpected results.

---

#### `basisMbr`

**What:** The member (or cross-dimensional member) whose values provide the **driver/basis** for the allocation.

**Effect:** How `basisMbr` is used depends on the `method` parameter:
- For `share`: Each member's driver value is divided by the sum of all driver values.
- For `spread`: `basisMbr` is used to determine which members to skip.
- For `percent`: `basisMbr` values are treated as percentages.
- For arithmetic methods: `basisMbr` values are used directly in the calculation.

---

#### `roundMbr` (Optional)

**What:** The member to which rounding errors are added (when using `errorsToMbr`).

**Rule:** Must be included in `allocationRange`.

---

#### `method` — All Seven Methods

| Method | Formula Applied per Member | Use Case |
|---|---|---|
| `share` | `amount × (memberBasis ÷ sumOfAllBasis)` | Proportional allocation — most common. Driver determines each member's "share" of the total. |
| `spread` | `amount × (1 ÷ count)` | Even spread. Requires a SKIP parameter. |
| `percent` | `amount × (memberBasis × 0.01)` | Basis values are treated as percentages. If basis = 25, the member gets 25% of amount. |
| `add` | `amount + memberBasis` | Adds the driver value to the source amount for each member. |
| `subtract` | `amount - memberBasis` | Subtracts the driver value from the source amount for each member. |
| `multiply` | `amount × memberBasis` | Multiplies the source amount by each member's driver value. |
| `divide` | `amount ÷ memberBasis` | Divides the source amount by each member's driver value. |

---

#### `methodParams` (for `spread` only)

| Parameter | Effect |
|---|---|
| `SKIPNONE` | Includes all cells — no skipping |
| `SKIPMISSING` | Excludes `#MISSING` values from count; stores `#MISSING` for members with missing basis |
| `SKIPZERO` | Excludes zero values from count; stores `#MISSING` for members with zero basis |
| `SKIPBOTH` | Excludes both `#MISSING` and zero values |

---

#### `round` (Optional)

| Value | Effect |
|---|---|
| `noRound` | No rounding (default) |
| `roundAmt` | Round allocated values. Must also specify `numDigits`. |

---

#### `numDigits`

| Value | Effect |
|---|---|
| `0` | Round to nearest integer |
| `> 0` (e.g., `2`) | Round to that many decimal places |
| `< 0` (e.g., `-2`) | Round to powers of 10 (e.g., -2 rounds to nearest 100) |

---

#### `roundErr` (Optional, requires `roundAmt`)

| Value | Effect |
|---|---|
| `errorsToHigh` | Adds rounding error to the member with the **highest** allocated value |
| `errorsToLow` | Adds rounding error to the member with the **lowest** allocated value. `#MISSING` is treated as the lowest value. |
| `errorsToMbr` | Adds rounding error to the specific `roundMbr` you defined |

---

### 5.4 Complete @ALLOCATE Example (From Sample Basic)

**Scenario:** Allocate budget values loaded at `Total Expenses` to each child expense category, based on prior year actual shares.

**Setup:**
- Scenario dimension has an additional member: `PY Actual` (prior year actuals).
- `Budget → Total Expenses → Jan = 7000, Feb = 8000`.
- `Total Expenses` has children: Marketing, Payroll, Misc.

**Calc Script:**
```
FIX("Total Expenses")
    Budget = @ALLOCATE(
        Budget->"Total Expenses",           /* amount: source value */
        @CHILDREN("Total Expenses"),        /* allocationRange: targets */
        "PY Actual",                        /* basisMbr: driver */
        ,                                   /* roundMbr: not specified */
        share                               /* method: proportional share */
    );
ENDFIX
```

**Data Before:**
| Member | PY Actual Jan | PY Actual Feb | Budget Jan | Budget Feb |
|---|---|---|---|---|
| Marketing | 5,223 | 5,289 | — | — |
| Payroll | 4,056 | 4,056 | — | — |
| Misc | 75 | 71 | — | — |
| **Total Expenses** | **9,354** | **9,416** | **7,000** | **8,000** |

**Calculation (January — Share Method):**
- Marketing: `7000 × (5223 ÷ 9354) = 7000 × 0.5584 = 3,908.60`
- Payroll: `7000 × (4056 ÷ 9354) = 7000 × 0.4336 = 3,035.28`
- Misc: `7000 × (75 ÷ 9354) = 7000 × 0.0080 = 56.13`
- **Total: 3,908.60 + 3,035.28 + 56.13 = 7,000.01** (rounding difference of $0.01)

**Data After:**
| Member | PY Actual Jan | PY Actual Feb | Budget Jan | Budget Feb |
|---|---|---|---|---|
| Marketing | 5,223 | 5,289 | **3,908.60** | **4,493.63** |
| Payroll | 4,056 | 4,056 | **3,035.28** | **3,446.05** |
| Misc | 75 | 71 | **56.13** | **60.32** |
| Total Expenses | 9,354 | 9,416 | 7,000 | 8,000 |

---

### 5.5 @ALLOCATE Performance Best Practice: Always Use FIX

```
/* ✅ GOOD — FIX narrows the calc scope */
FIX("Total Expenses")
    Budget = @ALLOCATE(...);
ENDFIX

/* ❌ BAD — Without FIX, Essbase iterates all members */
Budget = @ALLOCATE(...);
```

**Why:** Without `FIX`, Essbase evaluates the formula for **every member** in the dimension, not just the one you want. Using `FIX` limits the scope and dramatically improves performance.

---

## 6. Major Allocation Rule Types (Performance Hierarchy)

In Oracle Profitability and Cost Management (and applicable to EPBCS allocation design), there are **five major allocation rule types**, ranked by performance (best to worst):

| Rank | Rule Type | Abbreviation | Performance | Description |
|---|---|---|---|---|
| 1 | Simple Dimension Extension | **SDE** | ⭐⭐⭐⭐⭐ Fastest | Extends data along one dimension. Source stays, data is "spread" to new members in a different dimension. At least one destination dimension = "Same as Source." |
| 2 | Complex Dimension Extension | **CDE** | ⭐⭐⭐⭐ Fast | Like SDE but allows non-level-0 driver tuples and more flexible destination member selection. |
| 3 | Simple Reclassification | **SR** | ⭐⭐⭐ Medium | Moves data from one member to another within the same dimension. Source is "reclassified" (reassigned). |
| 4 | Complex Reclassification | **CR** | ⭐⭐ Slower | Like SR but allows non-level-0 driver tuples and more flexible destination/driver combinations. |
| 5 | Same as Source, Different Dimension | **SAD** | ⭐ Slowest | Uses "Same as Source, Different Dimension" in destination — most flexible but worst performance. |

### Why Performance Differs

The allocation type determines how Essbase constructs its internal calculation logic:
- **SDE/CDE**: Essbase can use optimized block-level operations because the source and destination share most dimensional context.
- **SR/CR**: Requires reading from one location and writing to another within the same dimension, forcing additional block lookups.
- **SAD**: Requires cross-dimensional member mapping, which is the most computationally expensive.

### How to Identify Your Rule Type

```
┌─────────────────────────────────────┐
│ Does at least one destination       │
│ dimension = "Same as Source"?        │
├───────┬─────────────────────────────┤
│  YES  │  NO                         │
│       │  → Is any destination       │
│       │    "Same as Source,          │
│       │     Different Dimension"?   │
│       │    YES → SAD                │
│       │    NO  → (Not valid)        │
├───────┘                             │
│ Is the source a level 0 member      │
│ OR destination = Same as Source      │
│ for non-level-0 source dims?        │
├───────┬─────────────────────────────┤
│  YES  │  NO → Invalid config        │
├───────┘                             │
│ Is the driver a level 0 tuple?      │
├───────┬─────────────────────────────┤
│  YES  │  NO                         │
│  SDE  │  CDE (if dim extension)     │
│  or   │  CR  (if reclassification)  │
│  SR   │                             │
└───────┴─────────────────────────────┘
```

---

## 7. Allocation Rule Types & Allowed Member Selection Options

### Detailed Selection Matrix

| Rule Type | Source Dimensions | Destination Dimensions | Driver Dimensions |
|---|---|---|---|
| **SDE** | • A single level 0 member | • At least one "Same as Source" | • Allocate evenly |
| | • Any other member IF destination = Same as Source for that dimension | • A single level 0 member | • Driver is a Level 0 Tuple |
| | | • Any other member IF no driver for that dimension | |
| **CDE** | • A single level 0 member | • At least one "Same as Source" | • Allocate evenly |
| | • Any other member IF destination = Same as Source for that dimension | • A single level 0 member | • Driver is Level 0 Tuple |
| | | • Any other member selection | • Driver is NOT a Level 0 Tuple |
| **SR** | • A single level 0 member | • Same as Source | • Allocate evenly |
| | • Any other member selection | • A single level 0 member | • Driver is a Level 0 Tuple |
| | | • Any other member IF no driver for that dimension | |
| **CR** | • A single level 0 member | • Same as Source | • Allocate evenly |
| | • Any other member selection | • A single level 0 member | • Driver is Level 0 Tuple |
| | | • Any other member selection | • Driver is NOT a Level 0 Tuple |
| **SAD** | • A single level 0 member | • Same as Source | • Allocate evenly |
| | • Any other member selection | • Same as Source, Different Dimension | • Driver is Level 0 Tuple |
| | | • Any other member selection | • Driver is NOT a Level 0 Tuple |

### What "Same as Source" Means

When a destination dimension is set to **"Same as Source"**, it means the allocated data is written to the **same member in that dimension as the source**. For example:
- Source: `Currency = USD`
- Destination: `Currency = Same as Source (Currency)`
- Result: Allocated data is written to `Currency = USD`.

This is required for **SDE** and **CDE** rule types — at least one destination dimension must use "Same as Source."

### What "Same as Source, Different Dimension" Means

Used only in **SAD** rules. The destination member is determined by looking at the source member in one dimension and finding a corresponding member in a **different** dimension. This is the most flexible but slowest approach.

---

## 8. Allocation Methods Explained

### 8.1 Share (Proportional Allocation)

**Formula:** `allocated_value = amount × (member_basis ÷ total_basis)`

**When to Use:** Most common method. Use when you have a meaningful driver metric (revenue, headcount, square footage) and want each target to receive a proportional share.

**Example:**
```
Total to allocate: $100,000
Driver: Headcount
  Dept A: 50 heads
  Dept B: 30 heads
  Dept C: 20 heads
  Total:  100 heads

Dept A: $100,000 × (50/100) = $50,000
Dept B: $100,000 × (30/100) = $30,000
Dept C: $100,000 × (20/100) = $20,000
```

### 8.2 Spread (Even Allocation)

**Formula:** `allocated_value = amount × (1 ÷ count_of_members)`

**When to Use:** When no meaningful driver exists, or when the business rule mandates equal distribution.

**Example:**
```
Total to allocate: $90,000
Members: 3 departments

Each department: $90,000 ÷ 3 = $30,000
```

**SKIP Parameters:**
```
SKIPNONE:    $90,000 ÷ 3 = $30,000 each (all included)
SKIPMISSING: If Dept C is #MISSING → $90,000 ÷ 2 = $45,000 (A & B only)
SKIPZERO:    If Dept C has 0 driver → $90,000 ÷ 2 = $45,000 (A & B only)
SKIPBOTH:    Skips both #MISSING and 0
```

### 8.3 Percent

**Formula:** `allocated_value = amount × (member_basis × 0.01)`

**When to Use:** When the basis member contains explicit percentage values.

**Example:**
```
Amount: $200,000
Basis values (percentages):
  Product A: 40 (meaning 40%)
  Product B: 35
  Product C: 25

Product A: $200,000 × (40 × 0.01) = $80,000
Product B: $200,000 × (35 × 0.01) = $70,000
Product C: $200,000 × (25 × 0.01) = $50,000
```

> **⚠️ Warning:** The sum of percentages does not have to equal 100. If they sum to 120, you will allocate 120% of the source amount!

### 8.4 Add

**Formula:** `allocated_value = amount + member_basis`

**When to Use:** When you need to augment a base value by a member-specific adjustment.

### 8.5 Subtract

**Formula:** `allocated_value = amount - member_basis`

### 8.6 Multiply

**Formula:** `allocated_value = amount × member_basis`

### 8.7 Divide

**Formula:** `allocated_value = amount ÷ member_basis`

> **⚠️ Warning:** If `member_basis` is zero, this causes a division-by-zero error. Always handle zero values in your basis.

---

## 9. Rounding: Every Option Dissected

### Why Rounding Matters

When you allocate $10,000 evenly across 3 members:
- Each gets $3,333.33 (rounded to 2 decimal places).
- Sum: $9,999.99 — **$0.01 short** of the original.

Without rounding error handling, your books are off by $0.01. In large allocations with many members, this can compound.

### Rounding Decision Matrix

| Do You Want Rounding? | Where Should the Difference Go? | Setting |
|---|---|---|
| No | N/A | `noRound` (or "No Rounding" in wizard) |
| Yes | Specific member I choose | `roundAmt` + `numDigits` + `errorsToMbr` → specify `roundMbr` |
| Yes | Member with the largest value | `roundAmt` + `numDigits` + `errorsToHigh` |
| Yes | Member with the smallest value | `roundAmt` + `numDigits` + `errorsToLow` |
| Yes | Discard it (accept the discrepancy) | `roundAmt` + `numDigits` (no `roundErr`) |

### Rounding Example

```
Source: $10,000.00
Allocation Range: Product A, B, C (3 members)
Method: Spread (even)
numDigits: 2

Unrounded:
  A: $3,333.333...
  B: $3,333.333...
  C: $3,333.333...

Rounded (2 decimal places):
  A: $3,333.33
  B: $3,333.33
  C: $3,333.33
  Sum: $9,999.99
  Rounding Error: $0.01

With errorsToHigh (all equal, so goes to first):
  A: $3,333.34  ← absorbs $0.01
  B: $3,333.33
  C: $3,333.33
  Sum: $10,000.00 ✓
```

---

## 10. Lifecycle Operations: Open, Edit, Copy, Paste, Save, Delete

### 10.1 Opening an Allocation Component

**Path:** `System View → Right-click the Business Rule → Open → In Rule Designer, double-click the allocation component in the flowchart`

**Important:** You **cannot** open an allocation component from System View directly — you must open the parent business rule first.

### 10.2 Editing an Allocation Component

**Path:** `System View → Right-click the Business Rule → Open → In Rule Designer, click the allocation component in the flowchart`

**What You Can Edit:**
| Property | Editable? |
|---|---|
| Source member | ✅ Yes |
| Target level 0 members | ✅ Yes |
| Amount to allocate | ✅ Yes |
| Offset member | ✅ Yes |
| Allocation method (even vs. driver) | ✅ Yes |
| Rounding settings | ✅ Yes |
| The dimension for Allocation Range | ✅ Yes |

**Effect:** Changes take effect the next time the business rule is executed. Don't forget to **Save** the rule after editing.

### 10.3 Copying and Pasting

**Path:** `Rule Designer → Right-click the component → Copy (or Copy Group)`

| Action | What Happens |
|---|---|
| **Copy** | Copies the single allocation component |
| **Copy Group** | Copies the component AND any components nested within it (e.g., if the allocation is inside a POV, Copy Group copies both) |
| **Paste (same rule)** | Right-click target location in flowchart → Paste. Creates a duplicate. |
| **Paste (different rule)** | Open the target rule → right-click location → Paste. The component is now in the new rule. |

**After Paste:** Click **Save** to persist the change.

### 10.4 Deleting an Allocation Component

**Path:** `Rule Designer → Right-click the allocation component → Remove`

**Important Behaviors:**
- If the allocation component is **inside** a POV component, removing the POV **also removes** the allocation.
- Deletion is permanent once saved. There is no "undo" after saving.

**After Removal:** Click **Save**.

### 10.5 Saving

**Rule:** Allocation components are saved **as part of the business rule**. They cannot be saved independently.

**Path:** After any create/edit/delete operation → Click the **Save** button in Rule Designer.

**Key Fact:** Unlike Formula Components (which can exist as reusable objects), allocation components are **always tied** to their parent business rule.

---

## 11. Real-World Worked Examples

### Example 1: Administrative Cost Allocation by Revenue Share

**Business Requirement:** Allocate $500,000 of administrative expenses to 5 product lines based on their Gross Sales (revenue).

**Configuration (Allocation Template):**

| Wizard Step | Setting |
|---|---|
| **POV** | Scenario = Budget, Version = Working, Year = FY2025, Period = Jan |
| **Source** | Account = Admin Expenses, Entity = Corporate HQ; Percentage = 100 |
| **Allocation Range** | Dimension = Product, Parent = Total Products |
| **Target** | Account = Admin Expenses Allocated, Entity = Corporate HQ |
| **Offset** | Account = Admin Expenses, Entity = Corporate HQ; Opposite Sign = Yes; Clear = Yes |
| **Exclude** | Product = Discontinued_LineX |
| **Driver** | Account = Gross Sales (same POV for other dimensions) |
| **Rounding** | Use Biggest Value, 2 decimal places |

**Data:**
```
Gross Sales:
  Product A: $2,000,000  (40%)
  Product B: $1,500,000  (30%)
  Product C: $1,000,000  (20%)
  Product D: $500,000    (10%)
  Discontinued_LineX: $100,000  (EXCLUDED)

Admin Expenses: $500,000 (at Corporate HQ)
```

**Result:**
```
Admin Expenses Allocated:
  Product A: $500,000 × (2,000,000 / 5,000,000) = $200,000.00
  Product B: $500,000 × (1,500,000 / 5,000,000) = $150,000.00
  Product C: $500,000 × (1,000,000 / 5,000,000) = $100,000.00
  Product D: $500,000 × (500,000 / 5,000,000)   = $50,000.00
  Discontinued_LineX: $0 (excluded)
  Total Allocated: $500,000 ✓

Offset (Admin Expenses @ Corporate HQ): -$500,000
Net Effect: $0 change to total company
```

---

### Example 2: Even Spread of IT Costs

**Calc Script (@ALLOCATE):**
```
FIX("IT Costs", "Budget", "FY2025", "Jan")
    "IT Costs" = @ALLOCATE(
        "IT Costs",
        @CHILDREN("All Departments"),
        "IT Costs",
        "IT Support",
        spread, SKIPNONE,
        roundAmt, 2, errorsToMbr
    );
ENDFIX
```

**Explanation:**
- Allocates IT Costs evenly across all child departments.
- Rounds to 2 decimal places.
- Rounding errors go to "IT Support" department (must be a child of "All Departments").

---

### Example 3: Multi-Step Allocation (Waterfall)

**Business Requirement:** First allocate corporate overhead to divisions, then allocate each division's total cost to products.

**Step 1 — Rule 1: Corporate → Divisions**
```
FIX("Corporate Overhead")
    Budget = @ALLOCATE(
        Budget->"Corporate Overhead",
        @CHILDREN("All Divisions"),
        "Headcount",, share
    );
ENDFIX
```

**Step 2 — Rule 2: Divisions → Products**
```
FIX(@CHILDREN("All Divisions"))
    Budget = @ALLOCATE(
        Budget,
        @CHILDREN("All Products"),
        "Revenue",, share,
        roundAmt, 2, errorsToHigh
    );
ENDFIX
```

**Execution Order:** Rule 1 must run before Rule 2 (use a Rule Set to sequence them).

---

## 12. Do's & Don'ts — The Definitive Checklist

### ✅ DO's

| # | Do | Why |
|---|---|---|
| 1 | **Use FIX statements** with @ALLOCATE | Dramatically improves performance by limiting scope |
| 2 | **Always validate source has data** before running | Allocating a #MISSING or zero source produces no results or errors |
| 3 | **Select level 0 members for POV and Target** | Parent members in POV/Target cause writes to non-leaf intersections, which either fail or are ignored |
| 4 | **Use Clear Region** when running allocations repeatedly | Prevents double-counting from prior runs |
| 5 | **Set up an Offset** for financial allocations | Keeps your books balanced; prevents double-counting of the source amount |
| 6 | **Handle rounding explicitly** | Even small rounding errors compound over many allocations and cause reconciliation headaches |
| 7 | **Use Allocation Range from a single level** | `@CHILDREN` is preferred over `@DESCENDANTS` to avoid multi-level allocation issues |
| 8 | **Test with a small dataset first** | Allocations can write to thousands of cells — test on a limited scope to verify logic |
| 9 | **Document your allocation rules** | Future administrators need to understand source, driver, target, and offset logic |
| 10 | **Use "Same as Source" for SDE rules** | Required for Simple Dimension Extension — the fastest rule type |
| 11 | **Verify driver data is populated** before running | #MISSING drivers cause uneven allocation or zero results |
| 12 | **Save the business rule** after every change to the allocation component | Unsaved changes are lost when you navigate away |
| 13 | **Use Predefined Selections** for commonly-used member sets | Saves time and ensures consistency across rules |
| 14 | **Consider the "Exclude" step** for inactive members | Prevents allocating data to discontinued or placeholder members |

### ❌ DON'TS

| # | Don't | Why |
|---|---|---|
| 1 | **Don't use parent members in POV** | Allocation writes to level 0 only; parent members in the POV create invalid intersections |
| 2 | **Don't use functions in the Source step** of the Allocation Component | The wizard explicitly prohibits functions (e.g., `@CHILDREN`) in the Source step |
| 3 | **Don't leave the Offset empty** in the Allocation Component | It's mandatory — the wizard will error. Use the Template if you don't need an offset. |
| 4 | **Don't use `@DESCENDANTS` in allocationRange** | Multi-level allocation ranges cause data to be written at different hierarchy levels, producing inconsistent results |
| 5 | **Don't forget to handle zero-value drivers** | Division by zero causes calc errors or #MISSING results |
| 6 | **Don't use Dynamic Calc members as the source amount** | Essbase cannot read stored values from Dynamic Calc members — the allocation will read #MISSING |
| 7 | **Don't skip the "Clear Region" step when re-running** | Old allocated values remain, and new allocations add on top, causing double-counting |
| 8 | **Don't allocate across multiple dimensions simultaneously** without understanding the rule type | The performance impact varies dramatically (SDE is 5× faster than SAD) |
| 9 | **Don't assume percentages sum to 100** when using the `percent` method | If they sum to 120, you'll allocate 120% of the source |
| 10 | **Don't remove a POV component** without realizing it deletes enclosed allocations | Removing a parent POV deletes all child components within it |
| 11 | **Don't run allocation rules without first aggregating** the database (if using stored driver values) | Driver data may not be current if the database hasn't been aggregated |
| 12 | **Don't use the same member for both Source and Target** in the same dimension without an offset | You'll overwrite your source data with the allocated values |

---

## 13. What Happens Before → During → After an Allocation

### Phase 1: BEFORE the Allocation Runs

| Step | What Happens | What You Should Do |
|---|---|---|
| 1. Data Load | Source data and driver data are loaded into Essbase | Verify source values are present and correct |
| 2. Aggregation | Database is aggregated so parent-level values are current | Run an aggregation script or ensure dense/sparse configurations are correct |
| 3. Rule Validation | Calculation Manager validates the rule for syntax errors | Fix any errors reported in the validation log |
| 4. Clear Region (if enabled) | The target region is cleared to `#MISSING` | Ensure your Clear Region members are correct to avoid wiping unrelated data |
| 5. Clear Offset (if enabled) | The offset region is cleared to `#MISSING` | Same as above — verify offset member selections |

### Phase 2: DURING the Allocation

| Step | What Happens | What's Happening Internally |
|---|---|---|
| 1. Source Read | Essbase reads the value at the source intersection | The amount to allocate is determined |
| 2. Driver Read | Essbase reads driver values for each member in the Allocation Range | The basis for proportional allocation is calculated |
| 3. Calculation | For each member in the Allocation Range: applies the method formula | `share`, `spread`, `percent`, etc. — produces a value per member |
| 4. Exclusion | Excluded members are skipped | Their driver values are removed from the denominator |
| 5. Rounding | Allocated values are rounded (if configured) | Rounding difference is placed per your settings |
| 6. Write to Target | Calculated values are written to the target intersections | Level 0 cells in Essbase are updated |
| 7. Write to Offset | Offset value is written (if configured) | Typically the negative of the total allocated amount |

### Phase 3: AFTER the Allocation Runs

| Step | What Happens | What You Should Do |
|---|---|---|
| 1. Aggregation | Database should be re-aggregated to reflect new level 0 values | Run aggregation or let Essbase dynamic calcs pick up changes |
| 2. Validation | Verify allocated values sum to the source | Run a validation report or cross-check totals |
| 3. Audit Trail | Review the calculation log for errors or warnings | Navigate: Jobs → Calc Script Job → View Log |
| 4. Reporting | Refresh reports and dashboards to show allocated data | Ensure forms and reports point to the correct target members |

---

## 14. Troubleshooting & Common Errors

| Error / Symptom | Likely Cause | Fix |
|---|---|---|
| Allocation produces all `#MISSING` | Source value is `#MISSING` or zero | Verify source data is loaded; check zero-handling settings |
| Allocated values don't sum to source | Rounding errors without rounding error handling | Enable `roundAmt` with `errorsToHigh` or `errorsToMbr` |
| "Member not found" error | Typo in member name in calc script | Verify exact member names in outline; check for trailing spaces |
| Offset is not written | Offset members not specified (Component) | In Component, Offset is mandatory — ensure members are selected |
| Double-counting in targets | Clear Region not enabled; running allocation multiple times | Enable "Clear Region = Yes" and specify the region to clear |
| Performance is very slow | Using SAD rule type or missing FIX statement | Use SDE/CDE rule types when possible; always use FIX in scripts |
| "Cannot allocate to Dynamic Calc member" | Target or Range includes Dynamic Calc members | Ensure all target members are stored (not Dynamic Calc) |
| Zero division error | Driver basis values are zero for all members | Handle zero basis: use SKIPZERO or set basis handling options |
| Allocation skips some members | SKIPMISSING or SKIPZERO is active and those members have no driver data | Load driver data for all target members, or change SKIP setting |
| "Wizard does not show Clear Region step" | "Clear Region = No" was selected in Allocation Range | Go back to Allocation Range step and select "Yes" |
| Negative allocated values | Source or driver contains negative values | Check your data; use basis options for negative handling |
| Offset has wrong sign | "Opposite Sign" not enabled in Template | Enable "Opposite Sign = Yes" in the Offset step |

---

## 15. Quick-Reference Decision Flowchart

```
START: You need to allocate data in EPM Cloud
       │
       ▼
┌──────────────────────────────────┐
│ Do you need to reuse the         │
│ allocation across multiple       │
│ rules or templates?              │
├────────┬─────────────────────────┤
│  YES   │  NO                     │
│        │                         │
│  Use   │  Is the allocation      │
│  ALLOC │  simple (single         │
│  TEMP- │  source, single         │
│  LATE  │  range, no complex      │
│        │  conditions)?           │
│        ├────────┬────────────────┤
│        │  YES   │  NO            │
│        │        │                │
│        │  Use   │  Use           │
│        │  ALLOC │  @ALLOCATE     │
│        │  COMP. │  in script     │
└────────┴────────┴────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ Do you need an offset?           │
├────────┬─────────────────────────┤
│  YES   │  NO                     │
│        │                         │
│ Both   │ Use Allocation          │
│ options│ Template (offset is     │
│ work,  │ optional) OR            │
│ but    │ @ALLOCATE (no           │
│ Template│ built-in offset)       │
│ is     │                         │
│ easier │                         │
└────────┴─────────────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ Choose allocation method:        │
├──────────────────────────────────┤
│ • Have a driver metric?          │
│   → Use SHARE method             │
│ • No driver, split equally?      │
│   → Use SPREAD method            │
│ • Basis contains %s?             │
│   → Use PERCENT method           │
│ • Need arithmetic operation?     │
│   → Use ADD/SUB/MUL/DIV          │
└──────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ Choose rounding:                 │
├──────────────────────────────────┤
│ • Financial reporting?           │
│   → Round to 2 decimals,         │
│     errorsToHigh or              │
│     errorsToMbr                  │
│ • Statistical/approximate?       │
│   → noRound or Discard           │
└──────────────────────────────────┘
```

---

## 16. Glossary

| Term | Definition |
|---|---|
| **Allocation** | The process of distributing a value from a source to multiple targets |
| **Allocation Component** | A graphical building block in Calculation Manager that creates an allocation within a Business Rule's flowchart |
| **Allocation Template** | A system-provided wizard-based template for building allocations, usable in both Rules and Templates |
| **@ALLOCATE** | The native Essbase calculation function for allocations |
| **Source** | The member or intersection from which the value to be allocated is read |
| **Target** | The member(s) or intersection(s) to which allocated values are written |
| **Allocation Range** | The parent member whose level 0 descendants receive the allocated values |
| **Basis / Driver** | The metric used to determine each target member's proportional share of the allocation |
| **Offset** | A balancing entry that prevents double-counting (typically the negative of the allocated total) |
| **POV (Point of View)** | The fixed dimensions that do not vary during the allocation |
| **Level 0 Member** | The lowest-level (leaf) member in a dimension hierarchy — has no children |
| **Share Method** | Allocates proportionally based on driver values |
| **Spread Method** | Allocates evenly across all members |
| **Percent Method** | Uses basis values as explicit percentages |
| **FIX Statement** | An Essbase construct that limits the scope of a calculation to specific members |
| **SDE** | Simple Dimension Extension — fastest allocation rule type |
| **CDE** | Complex Dimension Extension — second fastest |
| **SR** | Simple Reclassification — moderate performance |
| **CR** | Complex Reclassification — slower |
| **SAD** | Same as Source, Different Dimension — slowest |
| **Dynamic Calc** | An Essbase member whose value is calculated on-the-fly, not stored — cannot be used as a source for allocations |
| **Rounding Error** | The difference between the sum of rounded allocated values and the original source amount |
| **Clear Region** | The process of setting target cells to `#MISSING` before writing new allocated values |
| **Rule Set** | A collection of business rules executed in sequence — used for multi-step (waterfall) allocations |
| **Predefined Selection** | A saved set of member selections that can be reused across wizard steps |
| **Essbase / BSO** | Block Storage Option — the Essbase storage model that supports allocations |

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│               ALLOCATION QUICK REFERENCE                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  COMPONENT PATH:                                             │
│  System View → Rule → Open → New Objects → Allocation        │
│                                                              │
│  TEMPLATE PATH:                                              │
│  System View → Rule → Open → System Templates → Allocation   │
│                                                              │
│  WIZARD STEPS (Component):                                   │
│  POV → Source → Range → Target → Clear → Offset → Exclude    │
│  → Basis → Rounding → Finish                                │
│                                                              │
│  WIZARD STEPS (Template):                                    │
│  Info → POV → Source (%) → Range → Target → Offset (opt)     │
│  → Exclude → Driver → Spread Method → Rounding → Finish     │
│                                                              │
│  @ALLOCATE SYNTAX:                                           │
│  @ALLOCATE(amount, range, basis, [roundMbr],                │
│            method [,params] [,round [,digits] [,roundErr]])  │
│                                                              │
│  METHODS: share | spread | percent | add | subtract |        │
│           multiply | divide                                  │
│                                                              │
│  PERFORMANCE (best → worst):                                 │
│  SDE → CDE → SR → CR → SAD                                  │
│                                                              │
│  GOLDEN RULES:                                               │
│  ✓ Always use FIX with @ALLOCATE                             │
│  ✓ POV & Target = Level 0 members only                       │
│  ✓ Source CAN be a parent member                             │
│  ✓ Save the rule after every change                          │
│  ✓ Clear region before re-running allocations                │
│  ✗ Never use Dynamic Calc as source amount                   │
│  ✗ Never leave Offset empty in Component                     │
│  ✗ Never use @DESCENDANTS in allocationRange                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

> **Document Version:** 1.0
> **Applies To:** Oracle EPM Cloud — Enterprise Planning and Budgeting Cloud Service (EPBCS / PBCS)
> **Last Updated:** August 2026
> **Source References:**
> - [Oracle EPM Calculation Manager Documentation](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/)
> - [Essbase @ALLOCATE Function Reference](https://docs.oracle.com/en/database/other-databases/essbase/21/esscq/)
> - [Oracle Profitability and Cost Management — Allocation Rule Types](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/)
