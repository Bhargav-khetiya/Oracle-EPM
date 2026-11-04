# Oracle EPM: Complete Guide to the Allocation Template (EPBCS / PBCS)

---

## 1. What Is the Allocation Template—

The **Allocation Template** is a system-provided wizard in Oracle EPM Cloud's **Calculation Manager** that generates an Essbase allocation calculation without requiring you to write any calc script manually. It distributes data from a source intersection to target intersections — either evenly or based on a specified driver.

### Where It Lives

```
Calculation Manager
  └── Business Rules / Templates
        └── New Objects Palette (Graphical) → "Allocation"
        └── System Templates (Script)     → "Allocation"
```

### When to Use This Template

| Situation | Use Allocation Template— |
|---|---|
| Spread a cost pool to level 0 members using a driver (e.g., revenue, headcount) | ✅ Yes |
| Allocate a fixed percentage of a source (e.g., 25%) | ✅ Yes — Source step accepts percentage |
| Need an offsetting (balancing) journal entry | ✅ Yes — Offset step is built-in (optional) |
| Simple one-time allocation inside a single rule | ✅ Yes (or use the Allocation Component) |
| Need to allocate from one hierarchy level to another (e.g., level 3 → level 0) | ❌ No — Use the **Allocate - Level to Level** template instead |
| Need multi-pass, conditional, or scripted allocation logic | ❌ No — Use `@ALLOCATE` in a Formula/Script Component |

---

## 2. How to Add the Allocation Template to a Rule

### Method A: Graphical Rule or Template

1. Open or create a Business Rule or Template in **Calculation Manager → Rule Designer**.
2. In the **New Objects** palette (left panel), locate **Allocation**.
3. **Drag** the Allocation object and **drop** it into the flowchart between **Begin** and **End**.
4. The **Allocation Wizard** opens automatically.

### Method B: Script Rule or Template

1. Open or create a Business Rule or Template in script mode.
2. Expand **System Templates** in the left panel.
3. Select **Allocation** and **drop** it into the desired location in the script.
4. The **Allocation Wizard** opens automatically.

---

## 3. The Allocation Wizard — Every Step in Detail

The wizard walks you through a sequence of steps. Each step builds on the previous one. Below is the **complete walkthrough** with every field, every option, and every consequence explained.

---

### Step 1: Information

| Field | Value |
|---|---|
| Content | Read-only description of what the Allocation template does |
| Action Required | None — just read and click **Next** |

**What It Does:** Provides context about the template. No configuration is needed.

**What Happens If You Skip Reading It:** Nothing — it's purely informational.

---

### Step 2: Point of View (POV)

**Purpose:** Define the dimensions and members that **do NOT change** during the allocation. These are your "fixed" dimensions.

#### What You See

A table listing all dimensions in your application:

| Dimension | Selection |
|---|---|
| Account | *(select member)* |
| Period | *(select member)* |
| Scenario | *(select member)* |
| Version | *(select member)* |
| Entity | *(select member)* |
| Year | *(select member)* |
| Currency | *(select member)* |
| *(Custom dimensions)* | *(select member)* |

#### How to Select Members

| Method | How | Best For |
|---|---|---|
| **Use Predefined Selection** | Click the 🔘 Variable Selector icon → select a saved variable set | Reusable, consistent selections across rules |
| **Member Selector** | Click the 📋 Member Selector icon → browse the tree and pick members | One-off, specific picks |
| **Actions (per dimension)** | Select a dimension row → click the ⚙️ Actions icon → choose member, variable, or function | When you need `@RELATIVE`, runtime prompts, or substitution variables |

#### Rules

| Rule | Details |
|---|---|
| **Must select at least one member** | You cannot leave ALL dimensions empty in POV |
| **Members should be level 0** | POV members form part of the target intersection — level 0 (leaf) members only |
| **Dimensions left empty here** | Will be handled in subsequent steps (Source, Target, etc.) |
| **Functions are allowed** | Unlike the Source step, you CAN use functions like `@CHILDREN` in POV |

#### Effect

Every allocated value is written to the intersection that includes these POV members. For example:
- POV: `Scenario = Budget, Version = Working, Year = FY2025`
- Every allocated cell will be at `Budget → Working → FY2025 → (target members from other steps)`

#### ⚠️ Common Mistake

Selecting a **parent member** (e.g., `"All Entities"`) in the POV. Since allocations write to level 0 cells only, a parent in the POV creates an invalid intersection → data is silently skipped or the rule errors.

#### ✅ Correct Example

```
POV:
  Scenario  = Budget        (level 0 ✓)
  Version   = Working       (level 0 ✓)
  Year      = FY2025        (level 0 ✓)
  Currency  = USD           (level 0 ✓)
  Entity    = (leave empty — will be defined in Source/Target)
  Account   = (leave empty — will be defined in Source/Target)
  Product   = (leave empty — will be the Allocation Range dimension)
```

---

### Step 3: Source

**Purpose:** Define **where the data comes from** — the intersection whose value will be distributed.

#### What You See

A table listing all dimensions NOT yet fully specified in the POV, plus a percentage field:

| Field | Description |
|---|---|
| Dimension rows | One row per dimension — select the source member |
| **Percentage to allocate** | A number field (default: `100`) |

#### How to Select Members

Same three methods as POV (Predefined Selection, Member Selector, Actions).

#### Rules

| Rule | Details |
|---|---|
| **Must enter one member per dimension** | Every dimension listed must have a value |
| **Source members CAN be parent/aggregate** | Unlike POV, you can source from `"Total Expenses"` — the system reads the aggregated value |
| **Functions are NOT allowed** | You cannot use `@CHILDREN`, `@RELATIVE`, etc. Only explicit members or variables |
| **Leave the allocation dimension empty** | The dimension you plan to allocate across (in Allocation Range) should NOT be specified here |
| **Percentage field** | Enter the % of the source value to allocate. Enter `100` for the full amount, `25` for a quarter, etc. |

#### Effect

The system reads the value at `(POV members) + (Source members)` and multiplies it by the percentage:

```
Amount to allocate = Source Value × (Percentage ÷ 100)
```

**Example:**
- Source intersection value: $40,000
- Percentage: 25
- Amount to allocate: $40,000 × 0.25 = **$10,000**

#### ⚠️ Common Mistakes

| Mistake | Consequence |
|---|---|
| Leaving a dimension empty (not the allocation dimension) | Wizard error — every listed dimension needs a member |
| Entering a function like `@CHILDREN` | Wizard error — functions are prohibited in Source |
| Setting percentage to 0 | Allocates $0 — nothing happens |
| Forgetting to leave the allocation dimension empty | The allocation range step won't work correctly |

---

### Step 4: Allocation Range

**Purpose:** Define **which dimension** to spread the data across and **which parent member's level 0 descendants** receive the allocated values.

#### What You See

| Field | Description |
|---|---|
| **Dimension** | Drop-down to select the allocation dimension (e.g., Product, Entity, Department) |
| **Parent member** | The parent member whose level 0 children receive the allocation |

#### How It Works

1. You select a dimension (e.g., `Product`).
2. You enter a parent member (e.g., `"Total Products"`).
3. The system finds **all level 0 members** (leaf nodes) underneath that parent.
4. The allocation distributes the source amount to those level 0 members.

#### Visual Example

```
Hierarchy:
  Total Products (Parent — selected in Allocation Range)
    ├── Category A
    │     ├── Product A1  ← level 0 (receives allocation)
    │     └── Product A2  ← level 0 (receives allocation)
    └── Category B
          ├── Product B1  ← level 0 (receives allocation)
          └── Product B2  ← level 0 (receives allocation)

Allocation targets: Product A1, A2, B1, B2
```

#### Rules

| Rule | Details |
|---|---|
| **Only level 0 members receive data** | Intermediate parents (Category A, B) are skipped |
| **Parent member must exist in the outline** | A typo will cause a "member not found" error |
| **The dimension chosen here should NOT have a member in POV or Source** | It's the "varying" dimension |

#### Effect

Determines the scope of the allocation — how many members receive data and which ones.

#### ⚠️ Common Mistake

Choosing a parent whose children are at **multiple levels** in an unbalanced hierarchy. The allocation only targets level 0 — upper-level members are skipped, which can cause amounts to "disappear" if some branches are deeper than others.

---

### Step 5: Destination — Target

**Purpose:** For dimensions defined in the Source that are NOT used in the Allocation Range, specify the **target member** where allocated data is written.

#### What You See

A table with dimensions from the Source step that still need a target member.

**Default behavior:** The members you selected in the Source step are entered here by default. You can override them.

#### Rules

| Rule | Details |
|---|---|
| **Target members must be level 0** | Writing to parent members is not supported |
| **Every dimension must be accounted for** | Across POV + Allocation Range + Target, every dimension must have a member |
| **You can change the target to differ from the source** | For example: Source Account = "Admin Expenses" → Target Account = "Admin Expenses Allocated" |

#### Effect

Completes the intersection for allocated data:
```
Final target cell = (POV members) × (Allocation Range level 0 members) × (Target members)
```

#### Real-World Example

| Step | Dimension | Member |
|---|---|---|
| POV | Scenario | Budget |
| POV | Version | Working |
| POV | Year | FY2025 |
| POV | Period | Jan |
| Source | Account | Admin Expenses |
| Source | Entity | Corporate HQ |
| Allocation Range | Product | Total Products (parent) |
| **Target** | **Account** | **Admin Expenses Allocated** |
| **Target** | **Entity** | **Corporate HQ** |

**Resulting writes:**
- `Budget → Working → FY2025 → Jan → Admin Expenses Allocated → Corporate HQ → Product A1`
- `Budget → Working → FY2025 → Jan → Admin Expenses Allocated → Corporate HQ → Product A2`
- ... etc. for each level 0 product.

---

### Step 6: Destination — Offset (Optional)

**Purpose:** Create an **offsetting (balancing) entry** so the allocation doesn't double-count the source amount.

#### What You See

| Field | Description |
|---|---|
| **Offset members** | One member per dimension — defines the offset intersection |
| **Clear offset data before allocation** | Yes / No |
| **Opposite sign** | Yes / No |

#### Sub-Options Explained

| Option | What It Does | When to Use |
|---|---|---|
| **Offset members** | Specifies where the balancing entry is written | Always define if you want an offset |
| **Clear offset data = Yes** | Clears the offset intersection to `#MISSING` before writing | When re-running allocations — prevents accumulation |
| **Clear offset data = No** | Writes on top of existing data | When you want additive offset behavior |
| **Opposite sign = Yes** | The offset value is the **negative** of the total allocated amount | Almost always — this is the standard accounting behavior |
| **Opposite sign = No** | The offset value is the **same sign** as the allocated amount | Rare — only for special non-accounting use cases |

#### How It Works

```
Source: Admin Expenses @ Corporate HQ = $10,000
Allocation: $10,000 spread to Products A, B, C, D, E

WITHOUT Offset:
  Products receive: +$10,000 (spread)
  Source still has:  $10,000
  Company Total:    $20,000 ← WRONG (double-counted!)

WITH Offset (Opposite Sign = Yes):
  Products receive: +$10,000 (spread)
  Offset writes:    -$10,000 to Source member
  Company Total:    $10,000 ← CORRECT
```

#### Rules

| Rule | Details |
|---|---|
| **This step is OPTIONAL** | You can leave it blank to skip offset entirely |
| **If defined, specify one member per dimension** | Every dimension in the offset must have a value |
| **Offset and Source can be the same intersection** | This effectively "moves" data from source to targets |

#### ⚠️ Common Mistake

Forgetting to set **Opposite Sign = Yes**. Without it, the offset writes a *positive* value, which doesn't balance anything.

---

### Step 7: Exclude (Optional)

**Purpose:** Remove specific members from the Allocation Range so they receive **no data** and their driver values are excluded from calculations.

#### What You See

A member selector for the Allocation Range dimension.

#### Effect

| Without Exclude | With Exclude (e.g., Product D) |
|---|---|
| All level 0 members get allocated data | Product D gets `$0` / `#MISSING` |
| All driver values count in the denominator | Product D's driver value is removed from the denominator |
| Share percentages include all members | Share percentages are recalculated without Product D |

#### Example

```
WITHOUT Exclude:
  Total to allocate: $100,000
  Driver: Revenue
    Product A: $40,000 (40%)  → $40,000
    Product B: $30,000 (30%)  → $30,000
    Product C: $20,000 (20%)  → $20,000
    Product D: $10,000 (10%)  → $10,000

WITH Exclude (Product D):
  Total to allocate: $100,000
  Driver: Revenue (excluding Product D)
    Product A: $40,000 (44.4%)  → $44,444
    Product B: $30,000 (33.3%)  → $33,333
    Product C: $20,000 (22.2%)  → $22,222
    Product D: EXCLUDED          → $0
```

#### When to Use

- Inactive or discontinued products/entities
- Placeholder members (e.g., "No Department")
- Members you want to protect from receiving allocations

---

### Step 8: Driver

**Purpose:** Define how the source amount is split across the Allocation Range members.

#### What You See

| Field | Description |
|---|---|
| **Method selection** | "Allocate using a driver" OR "Allocate evenly" |
| **Dimension/member table** | Select the driver member for each varying dimension |

#### Option A: Allocate Using a Driver

Select one member per dimension for each dimension that **varies from the POV**. This member's values provide the basis for proportional allocation.

**How It Calculates:**
```
For each member M in Allocation Range:
  Allocated Value(M) = Source Amount × (Driver Value(M) ÷ Sum of All Driver Values)
```

**Example:**
```
Source: $120,000
Driver: Account = "Headcount"

  Dept A headcount: 60  → $120,000 × (60/120) = $60,000
  Dept B headcount: 36  → $120,000 × (36/120) = $36,000
  Dept C headcount: 24  → $120,000 × (24/120) = $24,000
  Total headcount: 120
```

**Inheritance Rule:** Dimensions you leave empty in the Driver step **inherit** from:
1. The POV (first priority)
2. Upper member ranges defined earlier in the rule

#### Option B: Allocate Evenly

Splits the source amount equally across all members in the Allocation Range.

**How It Calculates:**
```
Allocated Value(M) = Source Amount ÷ Count of Members in Range
```

If you select this option, the wizard proceeds to the **Spread Method** step.

---

### Step 9: Spread Method (Only if "Allocate Evenly" Selected)

**Purpose:** Configure how the even spread handles members with zero or `#MISSING` values.

#### Options

| Spread Option | Formula | Effect on Zero/Missing Members |
|---|---|---|
| **Spread, Skip None** | `Amount ÷ Total Count` | ALL members counted, ALL receive data |
| **Spread, Skip Missing** | `Amount ÷ (Count - Missing Count)` | `#MISSING` members skipped — get `#MISSING` |
| **Spread, Skip Zero** | `Amount ÷ (Count - Zero Count)` | Zero-value members skipped — get `#MISSING` |
| **Spread, Skip Both** | `Amount ÷ (Count - Missing - Zero Count)` | Both zero and `#MISSING` skipped |

#### Example

```
Source: $100,000
Members: A, B, C, D, E
  A: has data
  B: has data
  C: #MISSING
  D: value is 0
  E: has data

Skip None:    $100,000 ÷ 5 = $20,000 each (all 5 get data)
Skip Missing: $100,000 ÷ 4 = $25,000 (A, B, D, E get data; C = #MISSING)
Skip Zero:    $100,000 ÷ 4 = $25,000 (A, B, C, E get data; D = #MISSING)
Skip Both:    $100,000 ÷ 3 = $33,333 (A, B, E get data; C & D = #MISSING)
```

---

### Step 10: Other Options

**Purpose:** Final configuration — rounding, block creation, and region clearing.

#### Questions in This Step

| Question | Options | Recommendation |
|---|---|---|
| **Clear the Allocation Range before allocation—** | Yes / No | **Yes** if re-running — prevents double-counting. **No** if multiple allocations feed the same range. |
| **Reaggregate the allocation range after allocation—** | Yes / No | **Yes** if downstream calcs or reports need updated parent values immediately. **No** for performance (aggregate later). |
| **Number of decimal places** | Integer (e.g., `0`, `2`, `4`) | `2` for financial data. `0` for whole-number allocations. |
| **Create missing blocks automatically—** | Yes / No | **Yes** if target members might not have existing data blocks. **No** for performance (only if blocks already exist). |

#### Rounding Methods (If Decimal Places > 0)

If you specify decimal places, you may see additional rounding options:

| Method | Description |
|---|---|
| **Define Rounding Member** | Enter decimal places + select a specific member to absorb the rounding difference |
| **Use Biggest Value** | Rounding difference goes to the member with the largest allocated value |
| **Use Smallest Value** | Rounding difference goes to the member with the smallest allocated value |
| **No Rounding** | Values are not rounded — rounding differences are silently discarded |

#### Example: Rounding Impact

```
Source: $10,000, Decimal Places: 2, Members: A, B, C (even spread)

Unrounded: $3,333.333... each
Rounded:   $3,333.33 each → Sum = $9,999.99 → Error = $0.01

With "Use Biggest Value": A = $3,333.34, B = $3,333.33, C = $3,333.33 → Sum = $10,000.00 ✓
```

---

## 4. Complete Configuration Example

### Business Scenario

**Requirement:** Allocate 100% of Corporate Administrative Expenses ($500,000) across all products based on their Gross Sales revenue. Write an offset to the source. Exclude the discontinued product line.

### Wizard Configuration

| Step | Dimension | Value | Notes |
|---|---|---|---|
| **POV** | Scenario | Budget | Fixed — does not vary |
| | Version | Working | Fixed |
| | Year | FY2025 | Fixed |
| | Period | Jan | Fixed |
| | Currency | USD | Fixed |
| **Source** | Account | Admin Expenses | Where the $500K lives |
| | Entity | Corporate HQ | Specific entity |
| | Product | *(leave empty)* | This is the allocation dimension |
| | Percentage | 100 | Allocate 100% |
| **Allocation Range** | Dimension | Product | Spread across products |
| | Parent | Total Products | All level 0 children under this parent |
| **Target** | Account | Admin Expenses Allocated | Write to a different account |
| | Entity | Corporate HQ | Same entity |
| **Offset** | Account | Admin Expenses | Offset the source |
| | Entity | Corporate HQ | Same intersection |
| | Product | Total Products | Offset at the parent level |
| | Opposite Sign | Yes | Write -$500,000 |
| | Clear Offset | Yes | Clear before running |
| **Exclude** | Product | Discontinued_Line | Skip this product |
| **Driver** | Account | Gross Sales | Revenue-based share |
| **Other Options** | Clear Range | Yes | Clean slate before allocation |
| | Reaggregate | Yes | Update parent totals |
| | Decimal Places | 2 | Financial precision |
| | Create Blocks | Yes | Ensure all targets exist |

### Data & Calculation

```
BEFORE ALLOCATION:

Admin Expenses @ Corporate HQ = $500,000

Gross Sales (Driver):
  Product A:         $2,000,000  (40.0%)
  Product B:         $1,500,000  (30.0%)
  Product C:         $1,000,000  (20.0%)
  Product D:           $500,000  (10.0%)
  Discontinued_Line:   $100,000  (EXCLUDED — not counted)
  ─────────────────────────────
  Total (excl.):     $5,000,000  (100%)

ALLOCATION CALCULATION:

  Product A: $500,000 × (2,000,000 / 5,000,000) = $200,000.00
  Product B: $500,000 × (1,500,000 / 5,000,000) = $150,000.00
  Product C: $500,000 × (1,000,000 / 5,000,000) = $100,000.00
  Product D: $500,000 × (500,000 / 5,000,000)   =  $50,000.00
  Discontinued_Line:                              =       $0.00
  ─────────────────────────────────────────────────
  Total Allocated:                                = $500,000.00 ✓

OFFSET:
  Admin Expenses @ Corporate HQ → -$500,000

AFTER ALLOCATION:

  Admin Expenses @ Corporate HQ:           $500,000 - $500,000 = $0
  Admin Expenses Allocated @ Product A:    $200,000
  Admin Expenses Allocated @ Product B:    $150,000
  Admin Expenses Allocated @ Product C:    $100,000
  Admin Expenses Allocated @ Product D:     $50,000
  ─────────────────────────────────────────────────
  Company Total:                           $500,000 ✓ (balanced)
```

---

## 5. Step-by-Step Execution Flow: What Happens When You Run the Rule

```
┌─────────────────────────────────────────────────────────────┐
│                    EXECUTION TIMELINE                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. VALIDATION                                               │
│     Rule Designer validates all wizard settings              │
│     Checks: members exist, dimensions are complete,          │
│     no syntax errors                                         │
│     ↓                                                        │
│  2. CLEAR OFFSET (if Clear Offset = Yes)                     │
│     Sets offset intersection to #MISSING                     │
│     ↓                                                        │
│  3. CLEAR RANGE (if Clear Range = Yes)                       │
│     Sets all target intersections to #MISSING                │
│     ↓                                                        │
│  4. READ SOURCE                                              │
│     Reads value at source intersection                       │
│     Applies percentage: Amount = Value × (Pct / 100)         │
│     ↓                                                        │
│  5. READ DRIVER                                              │
│     For each member in Allocation Range:                     │
│       Read the driver value (excluding excluded members)     │
│     Calculate total driver value                             │
│     ↓                                                        │
│  6. CALCULATE                                                │
│     For each member M in Allocation Range:                   │
│       If M is excluded → skip                                │
│       If driver-based → Value(M) = Amount × (Driver(M)/Total)│
│       If even spread  → Value(M) = Amount ÷ Count            │
│     ↓                                                        │
│  7. ROUND (if decimal places specified)                      │
│     Round each value to N decimal places                     │
│     Place rounding difference per settings                   │
│     ↓                                                        │
│  8. WRITE TARGETS                                            │
│     Write calculated values to target intersections          │
│     ↓                                                        │
│  9. WRITE OFFSET (if offset defined)                         │
│     Write offsetting value (opposite sign if selected)       │
│     ↓                                                        │
│ 10. REAGGREGATE (if Reaggregate = Yes)                       │
│     Recalculate parent-level totals                          │
│     ↓                                                        │
│ 11. COMPLETE                                                 │
│     Rule finishes — check job log for errors/warnings        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Do's & Don'ts for the Allocation Template

### ✅ DO's

| # | Do | Why |
|---|---|---|
| 1 | **Leave the allocation dimension empty in Source** | It's defined in the Allocation Range step — specifying it in both causes conflicts |
| 2 | **Use level 0 members in POV and Target** | Allocations write to level 0 only — parents create invalid intersections |
| 3 | **Set Opposite Sign = Yes for financial offsets** | Without it, the offset doesn't balance the books |
| 4 | **Enable Clear Range when re-running** | Prevents old values from accumulating |
| 5 | **Verify driver data is populated** | Missing driver data causes zero or #MISSING allocations |
| 6 | **Use decimal places = 2 for currency** | Standard financial precision |
| 7 | **Enable "Create Missing Blocks" for new targets** | Without blocks, Essbase cannot write data |
| 8 | **Test with percentage = 100 first** | Verify the full allocation works before using partial percentages |
| 9 | **Save the rule after completing the wizard** | Unsaved rules lose all wizard settings |

### ❌ DON'TS

| # | Don't | Why |
|---|---|---|
| 1 | **Don't use functions in the Source step** | The wizard prohibits `@CHILDREN`, `@RELATIVE`, etc. in Source |
| 2 | **Don't leave dimensions empty in Source** (except the allocation dimension) | Every other dimension must have a member |
| 3 | **Don't forget to define target for all dimensions** | Underfined dimensions cause incomplete intersections |
| 4 | **Don't set percentage to 0** | Allocates nothing — the rule runs but produces no results |
| 5 | **Don't skip the Exclude step for inactive members** | They'll receive allocated data and skew your reporting |
| 6 | **Don't assume the offset is automatic** | You must explicitly define it — it's optional in this template |
| 7 | **Don't select Dynamic Calc members as driver** | Dynamic Calc values may not be available at calculation time |
| 8 | **Don't use this template for level-to-level allocations** | Use the **Allocate - Level to Level** template instead |

---

## 7. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| All targets show `#MISSING` | Source value is `#MISSING` or percentage is 0 | Verify source data; check percentage field |
| Targets don't sum to source | Rounding without error handling | Set decimal places and choose a rounding method |
| "Member not found" error | Typo in member name | Verify member names in the dimension outline |
| Double-counting | Clear Range = No and rule ran multiple times | Set Clear Range = Yes |
| Offset not created | Offset step left blank | Fill in offset members and set Opposite Sign = Yes |
| Some members get $0 | Exclude step includes them, or SKIP setting drops them | Check Exclude list and Spread Method settings |
| Rule runs but no data changes | Target members are Dynamic Calc | Change targets to stored members |
| Performance is slow | Reaggregate = Yes on a large cube | Set to No and aggregate separately |

---

## 8. Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│          ALLOCATION TEMPLATE QUICK REFERENCE                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ACCESS:                                                     │
│  Graphical: New Objects → Allocation → drop into flowchart   │
│  Script:    System Templates → Allocation → drop into script │
│                                                              │
│  WIZARD STEPS:                                               │
│  Information → POV → Source (%) → Allocation Range →         │
│  Target → Offset (optional) → Exclude (optional) →          │
│  Driver → Spread Method (if even) → Other Options → Finish  │
│                                                              │
│  KEY FIELDS:                                                 │
│  • Source Percentage: Enter 100 for full, 25 for quarter     │
│  • Allocation Range: Parent member → level 0 descendants     │
│  • Offset: Opposite Sign = Yes for balanced accounting       │
│  • Driver: One member per varying dimension                  │
│  • Spread Method: SKIPNONE / SKIPMISSING / SKIPZERO / BOTH  │
│                                                              │
│  GOLDEN RULES:                                               │
│  ✓ Leave allocation dimension empty in Source                │
│  ✓ POV & Target = Level 0 members only                       │
│  ✓ Source CAN be a parent member                             │
│  ✓ Offset is OPTIONAL (unlike Allocation Component)          │
│  ✓ Functions NOT allowed in Source step                       │
│  ✓ Save after completing the wizard                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

> **Document Version:** 1.0  
> **Applies To:** Oracle EPM Cloud — Enterprise Planning and Budgeting Cloud Service (EPBCS / PBCS)  
> **Last Updated:** August 2026  
> **Source:** [Oracle EPM Calculation Manager — Using the Allocation Template](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/)
