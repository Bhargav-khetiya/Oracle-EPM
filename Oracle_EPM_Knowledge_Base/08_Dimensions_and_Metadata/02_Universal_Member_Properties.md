# Universal Member Properties

> **Prerequisites:** [Dimension Fundamentals](01_Dimension_Fundamentals.md)  
> **Sources merged:** ChatGPT 01, Claude 05.30 §10, Gemini 01  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## Overview

Every member in Oracle EPM Cloud — regardless of which dimension it belongs to — carries a set of **universal properties**. These control identification, data storage, aggregation behavior, and formula execution.

---

## 1. Identification Properties

| Property | UI Element | Constraints |
|----------|-----------|-------------|
| **Name / Code** | Text field (max 80 chars) | Globally unique across the entire application (unless "Duplicate Member Names" is enabled). Cannot contain `+ - * / [ ] ( ) " ' , ;`. Cannot match Essbase reserved words: `MISSING`, `ERROR`, `NONE`, `CALC`, `ALL`. |
| **Description** | Text area | Administrative notes only. Stored **only** in the relational database — never compiled into the Essbase `.OTL`, consuming zero Essbase RAM or disk. |
| **Alias Table** | Dropdown (Default, Arabic, etc.) | Defines the localization dictionary. EPM allows multiple alias tables (English, Arabic, Japanese, Regulatory). A member can have exactly one alias per table. |
| **Alias** | Text field (max 80 chars) | The display label on forms, reports, Smart View, and dashboards. Must be unique within each alias table. |

> [!NOTE]
> Because forms, task lists, and security groups reference members by their internal `OBJECT_ID` (not the name string), **renaming a member never breaks forms or permissions**. The internal ID remains constant.

`[Oracle Documented]`

---

## 2. Data Storage Types

The **Data Storage** property is the single most critical setting. It governs whether a member consumes disk space, exists in the B-tree index, or calculates in RAM on demand.

```
                         DATA STORAGE TYPES
                                │
         ┌──────────────────────┼──────────────────────┐
         ▼                      ▼                      ▼
      [STORE]            [DYNAMIC CALC]          [LABEL ONLY]
   Physical 8-byte      Zero disk footprint     Header/organizer
   cells in .PAG        Evaluated in RAM        No data cells
   Aggregated in        at query time           Cannot enter data
   CALC/AGG batches                             Children bypass
         │                      │                to grandparent
         ▼                      ▼
   [NEVER SHARE]        [DYNAMIC CALC & STORE]
   Forces distinct      Calculates on query,
   block; prevents      then writes back to
   auto-sharing         disk (deprecated)
```

### Comparison Matrix

| Storage Option | On Disk? | In Index (.IND)? | User Input? | Best Use Case |
|:---|:---:|:---:|:---:|:---|
| **Store** | ✅ .PAG files | Yes (if Sparse) | ✅ (Level 0) | Base input accounts, loaded data |
| **Dynamic Calc** | ❌ 0 bytes | No | ❌ Calculated | Parent rollups, ratios, KPIs, variances |
| **Dynamic Calc & Store** | ✅ after first query | Yes (if Sparse) | ❌ | **Discouraged** — causes page file fragmentation |
| **Never Share** | ✅ .PAG files | Yes (if Sparse) | ✅ (Level 0) | Single-child parents needing independent blocks |
| **Shared** | ❌ (shares base cell) | Via base member | Via base only | Alternate hierarchies, different rollup views |
| **Label Only** | ❌ 0 bytes | No | ❌ | Organizational headers ("P&L Summary") |

`[Oracle Documented]`

### The "Never Share" Trap

When a parent has exactly **one child**, Essbase optimization treats parent and child as sharing the same block (since mathematically Parent = Child). This can cause:
- Lock errors when both are accessed simultaneously
- Unexpected formula overwrites in business rules

Setting **Never Share** on the child forces Essbase to generate distinct blocks, isolating their data.

```
Without Never Share:           With Never Share:
  Revenue                        Revenue
    └── Rooms Revenue             └── Rooms Revenue [Never Share]
  
  Same cell → lock conflicts     Separate cells → safe
```

### Shared Members for Alternate Hierarchies

```
Primary Hierarchy:
  Revenue → Rooms Revenue → 100110 (base member, Store)

Alternate Hierarchy:
  By Geography → India Revenue → 100110 (SHARED member)

Both point to the SAME data cell. Change one → both change.
Zero additional storage cost.
```

`[Oracle Documented]`

---

## 3. Consolidation Operators

The consolidation operator determines how a child member rolls up into its immediate parent during outline aggregation.

| Symbol | Name | Action | When to Use |
|:---:|:---|:---|:---|
| **`+`** | Addition | Parent = Parent + Child | Standard revenue, expense, entity rollups |
| **`-`** | Subtraction | Parent = Parent − Child | Returns, allowances, discounts |
| **`*`** | Multiplication | Parent = Parent × Child | Units × Price drivers |
| **`/`** | Division | Parent = Parent ÷ Child | Weighted unit cost |
| **`%`** | Percent | Child as percentage of parent | Margin contribution analysis |
| **`~`** | Ignore | Child contributes zero to parent | Statistical accounts (Headcount), KPI drivers |
| **`^`** | Never | Exempt from consolidation entirely | Complex formula members calculated by scripts |

> [!IMPORTANT]
> **BSO cubes** support all 7 operators. **ASO cubes** support only Addition (`+`) and Ignore (`~`) because ASO does not use procedural consolidation — it aggregates via MDX solve order sets.

### Worked Example

```
Net Income (^) ← Has formula, excluded from operator consolidation
  ├── (+) Revenue = ₹26,00,000
  │   ├── (+) Rooms Revenue = ₹18,00,000
  │   ├── (+) Banquet Revenue = ₹5,00,000
  │   └── (+) F&B Revenue = ₹3,00,000
  │
  ├── (-) Total Expense = ₹11,00,000    ← MINUS: subtracted from parent
  │   ├── (+) Salaries = ₹8,00,000      ← Plus WITHIN expenses
  │   ├── (+) Benefits = ₹2,00,000
  │   └── (+) Utilities = ₹1,00,000
  │
  └── (~) Gross Margin % = 57.69%        ← IGNORED in consolidation

Calculation:
  Revenue = 18L + 5L + 3L = ₹26,00,000
  Expense = 8L + 2L + 1L = ₹11,00,000
  Net Income = Revenue (+) + Expense (-) = 26L - 11L = ₹15,00,000
```

`[Oracle Documented]`

---

## 4. Two-Pass Calculation

### The Problem

During a standard BSO calculation pass, Essbase aggregates values along hierarchies. If a percentage or ratio member (like `Gross Margin % = Gross Profit / Revenue`) is calculated during the normal rollup, the parent simply **adds up child percentages**:

```
Without Two-Pass:               With Two-Pass (Correct):
  East GM%:  40%                  Total Sales = $2,000,000
  West GM%:  60%                  Total COGS  = $1,200,000
  Total:    100% ❌ NONSENSICAL   Total GM%   = ($2M-$1.2M)/$2M = 40% ✅
```

### How It Works

1. **Pass 1:** Essbase calculates all members, rolling up base values across hierarchies
2. **Pass 2:** Essbase recalculates only members tagged with Two-Pass, using the newly consolidated parent values

### Restrictions

- **Only on Dense dimensions** — specifically Account and Period
- **Must be Dynamic Calc** — the Two-Pass checkbox is grayed out for Store, Never Share, or Label Only members
- Reason: stored members are pre-calculated in batch, not evaluated dynamically

`[Oracle Documented]`

---

## 5. Plan Type (Cube) Enablement

Each member can be enabled or disabled for specific cubes independently:

```
┌──────────────────────────────────┬─────────────────────────────────────┐
│  CUBE ENABLEMENT (Checkbox)      │  CONSOLIDATION OPERATOR (Dropdown)  │
├──────────────────────────────────┼─────────────────────────────────────┤
│ Whether the member is deployed   │ How the member rolls up within      │
│ into that cube's outline (.OTL)  │ that specific cube                  │
└──────────────────────────────────┴─────────────────────────────────────┘
```

This allows different dimensional granularity per cube. For example, a cost center might be:
- **Enabled** in FinPlan (financial reporting) and Manpower (workforce planning)
- **Disabled** in EPBCS (ASO reporting) and Capital (fixed assets)

> [!TIP]
> Disabling unneeded dimensions in specific cubes keeps Essbase block sizes lean and prevents block explosion in sub-cubes.

`[Recommendation]`

---

## 6. Data Types and Smart Lists

| Data Type | Storage Behavior | Use Case |
|-----------|-----------------|----------|
| **Unspecified** | Generic numeric float | Default for most members |
| **Currency** | Subject to currency conversion via exchange rate tables | Financial amounts |
| **Non-Currency** | Pure numbers; bypasses currency conversion | Headcount, units sold |
| **Percentage** | Formatted as % (entered 0.15, displayed 15%) | Ratios, growth rates |
| **Smart List** | Text dropdown stored as numeric ID | Status selections |
| **Date** | Calendar date; stored internally as YYYYMMDD | Milestones, deadlines |
| **Text** | Cell comments via Planning relational tables | Notes, annotations |

### Smart List Storage Physics

Essbase can **only store 64-bit double-precision floating-point numbers** in its data blocks. There is no native text engine in BSO cells.

```
User selects "Full-Time" from a Smart List  →  Entry ID = 1
Essbase stores 1.00000000 in the .PAG block cell
When form is retrieved, Planning reads 1.0  →  renders "Full-Time" in the dropdown
```

`[Oracle Documented]`

---

## 7. Dynamic Children and Member Creator Access

Dynamic Children allow planners to add new members (employees, projects, line items) directly from forms without waiting for an admin to run metadata import.

```
1. Administrator enables "Enable for Dynamic Children" on a parent
2. Sets "Number of Possible Dynamic Children" (e.g., 10)
3. Essbase pre-reserves 10 placeholder slots in the outline
4. Planner clicks "Add New Employee" in the form grid
5. Planning binds the new name to a reserved slot
6. Access Granted to Member Creator controls permissions:
   • Inherit: Takes parent's access rights
   • Write: Creator can immediately edit data
   • Read: Creator can view only
```

`[Oracle Documented]`

---

## 8. UDAs vs Attribute Dimensions

Both provide metadata categorization, but they work very differently:

```
┌──────────────────────────────────┬─────────────────────────────────────┐
│  USER-DEFINED ATTRIBUTES (UDA)   │  ATTRIBUTE DIMENSIONS               │
├──────────────────────────────────┼─────────────────────────────────────┤
│ Flat text string tag             │ True multidimensional hierarchy     │
│ No parent-child rollup           │ Aggregates data dynamically         │
│ Cannot be placed on form axes    │ Can be dragged to Row, Column, POV  │
│ Used in Calc Manager: @ISUDA     │ Supports Text, Numeric, Date, Bool  │
│ Zero disk overhead               │ Zero disk bloat (dynamic calc)      │
│ Lightweight, fast                │ More powerful, more complex          │
└──────────────────────────────────┴─────────────────────────────────────┘
```

### Attribute Data Types

| Type | Description | Example | Query Capability |
|------|-----------|---------|-----------------|
| **Text** | Categorical strings | `Product_Color: Red, Blue` | Exact match |
| **Numeric** | Numeric values | `Square_Footage: 2500` | Range queries (`> 5000`) |
| **Date** | Calendar dates | `Contract_End: 2026-12-31` | Date ranges |
| **Boolean** | True/False flags | `Tax_Exempt: True` | Binary filtering |

### Decision Framework

```
Do users need to slice, pivot, or display this property in Forms/Smart View?
├── YES → ✅ ATTRIBUTE DIMENSION
└── NO  → Is it needed ONLY inside calculation scripts (e.g., @ISUDA)?
          ├── YES → ✅ USER-DEFINED ATTRIBUTE (UDA)
          └── NO  → Use a standard Alias or Description
```

`[Oracle Documented]`

---

## 9. Member Formulas and Solve Order

- **Member Formula:** Calculation logic attached to a Dynamic Calc member (e.g., `[Revenue] - [COGS]`)
- **Solve Order (0 to 127):** When multiple Dynamic Calc dimensions intersect (Account formula × Period variance formula), Solve Order dictates which evaluates first. **Higher Solve Order wins** and calculates last (overriding earlier formulas).

See [Advanced Solve Order](05_Advanced_Topics.md) for details.

---

## Quick Recall

1. **What is the most critical member property for performance?**
   → Data Storage — it determines whether a member consumes disk space and index entries.

2. **Why does renaming a member NOT break forms?**
   → Because forms reference the internal numeric OBJECT_ID, not the text name.

3. **When would you use Never Share vs Label Only?**
   → Never Share: when you need to store data but prevent implied sharing. Label Only: when the member is purely an organizational header with no data.

4. **Explain Two-Pass to a colleague:**
   → "It forces Essbase to do a second calculation pass on ratio members after all base values are aggregated, so percentages are computed from consolidated totals instead of being summed from children."

---

**Next:** [Account Dimension](03_Account_Dimension.md) — the financial backbone with account types, time balance, and variance reporting

