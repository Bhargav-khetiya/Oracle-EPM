# Oracle EPM: The Ultimate Deep-Dive Guide to Grid Spread (Data Forms)

---

## Table of Contents
1. [Introduction: What is Grid Spread—](#1-introduction-what-is-grid-spread)
2. [Why is Grid Spread Needed—](#2-why-is-grid-spread-needed)
3. [How to Enable Grid Spread (Administrator Setup)](#3-how-to-enable-grid-spread-administrator-setup)
4. [How Grid Spread Works Internally — Architecture Deep Dive](#4-how-grid-spread-works-internally--architecture-deep-dive)
5. [Spreading Patterns Explained](#5-spreading-patterns-explained)
6. [Custom Spread Patterns](#6-custom-spread-patterns)
7. [Step-by-Step: Using Grid Spread (Web and Smart View)](#7-step-by-step-using-grid-spread-web-and-smart-view)
8. [Grid Spread and Member Storage Properties — The Critical Rules](#8-grid-spread-and-member-storage-properties--the-critical-rules)
9. [Grid Spread and Shared Members](#9-grid-spread-and-shared-members)
10. [Grid Spread and Label-Only Members](#10-grid-spread-and-label-only-members)
11. [Grid Spread and Member Formulas](#11-grid-spread-and-member-formulas)
12. [Grid Spread vs Default Spreading vs Mass Allocate](#12-grid-spread-vs-default-spreading-vs-mass-allocate)
13. [Grid Spread Across BSO, ASO, and Hybrid Mode](#13-grid-spread-across-bso-aso-and-hybrid-mode)
14. [Time Balance Property Impact on Grid Spread](#14-time-balance-property-impact-on-grid-spread)
15. [Grid Spread and Spread Patterns (Migration Artifact)](#15-grid-spread-and-spread-patterns-migration-artifact)
16. [Complete Scenarios Where Grid Spread Will NOT Work](#16-complete-scenarios-where-grid-spread-will-not-work)
17. [Complete Scenarios Where Grid Spread WILL Work](#17-complete-scenarios-where-grid-spread-will-work)
18. [Practical Examples with Numbers](#18-practical-examples-with-numbers)
19. [Dashboard 2.0 and Grid Spread](#19-dashboard-20-and-grid-spread)
20. [Troubleshooting Guide](#20-troubleshooting-guide)
21. [Quick Reference Cheat Sheet](#21-quick-reference-cheat-sheet)

---

## 1. Introduction: What is Grid Spread—

**Grid Spread** is a data-entry feature in Oracle Cloud EPM (Planning, FreeForm, and related business processes) that allows users to take a value from a **parent/summary/total cell** on a data form and **automatically distribute (spread) it downward** to its underlying child/target cells across one or more dimensions visible on the grid.

### The Core Concept
Think of it this way: A Finance Director enters `$1,200,000` as the annual revenue target for "YearTotal." Grid Spread breaks this into months — either **evenly** ($100,000 each), **proportionally** (based on prior-year seasonal pattern), or by **filling** every month with $1,200,000.

### Key Characteristics
| Characteristic | Details |
|:---|:---|
| **Feature Type** | End-user data entry tool (not a business rule or calculation) |
| **Where it lives** | Data Forms (Web + Smart View) and Ad Hoc Grids |
| **Who controls it** | Service Administrator enables it; end-users execute it |
| **Scope** | Only affects cells **visible on the current grid** |
| **Security** | Fully respects user data access permissions |
| **Reversibility** | Can be undone before saving (Refresh/Undo); once saved, requires manual reversal |

---

## 2. Why is Grid Spread Needed—

### The Business Problem
In enterprise planning, data is frequently entered or targeted at **summary levels**:
*   A CFO sets a company-wide revenue target of $50M.
*   A VP of Sales assigns $12M to the West Region for FY2026.
*   A department head budgets $600K for total annual travel expenses.

But the **planning database** and downstream reporting need data at **granular, base-level (level-0) intersections** — by month, by cost center, by product line. Manually typing values into 12 months × 50 departments × 10 product lines = **6,000 cells** is impractical.

### What Grid Spread Solves
| Without Grid Spread | With Grid Spread |
|:---|:---|
| User manually types into every base cell | User enters ONE value at the parent level |
| Risk of arithmetic errors | System distributes automatically using mathematical patterns |
| Extremely time-consuming | Completes in seconds |
| Hard to apply consistent seasonal patterns | Can use proportional spread based on historical data |
| No audit trail of the spreading logic | The system applies a deterministic, repeatable pattern |

### Common Business Scenarios
1. **Top-Down Budgeting** — Executive sets annual target; Grid Spread distributes to months.
2. **Revenue Forecasting** — Update Q3 forecast; spread proportionally to July, August, September based on prior-year mix.
3. **Headcount Planning** — Set total FTE target for a department; spread evenly across cost centers.
4. **Expense Adjustments** — Increase travel budget by 10%; Grid Spread applies the percentage increase across all visible periods.
5. **Quick What-If Analysis** — "What if we increase Q2 by $50K— — Grid Spread shows the impact instantly before saving.

---

## 3. How to Enable Grid Spread (Administrator Setup)

Grid Spread is **NOT enabled by default**. A Service Administrator must explicitly turn it on for each form.

### Step-by-Step: Enable Grid Spread

**Navigation:** `Home → Navigator → Create and Manage → Forms`

1. Open the **Form Manager** and locate your target form.
2. Click **Actions → Edit** (or create a new form).
3. Navigate to the **Layout** tab.
4. Click **Display Properties** (on the right-side panel or under "Other Options").
5. **Check** the box labeled **"Enable Grid Spread"**.
6. Click **Save** or **Finish**.

### Important Related Settings

| Setting | Location | Effect |
|:---|:---|:---|
| **Enable Grid Spread** | Form → Layout → Display Properties | Turns on Grid Spread for that specific form |
| **Disable Spreading** | Form → Layout → Smart View Options | If checked, **overrides and blocks** ALL spreading in Smart View (including Grid Spread, default spreading, and mass allocations) |
| **Enable Mass Allocate** | Form → Layout → Display Properties | Separate feature — enables Mass Allocate (different from Grid Spread) |
| **Make Form Read-Only** | Form → Layout → Display Properties | If checked, the entire form is read-only — Grid Spread has no writable targets |

> **⚠️ Critical Trap:** If **"Disable Spreading"** is checked under Smart View Options, it **overrides** the "Enable Grid Spread" checkbox. Users in Smart View will NOT see the Grid Spread option even though it appears enabled. Always verify BOTH settings.

---

## 4. How Grid Spread Works Internally — Architecture Deep Dive

### The Data Flow (What Happens Under the Hood)

```
┌─────────────────────────────────────────────────────────────┐
│  USER ACTION                                                │
│  1. User selects a parent/summary cell on the grid          │
│  2. User chooses Edit → Grid Spread (Web) or                │
│     Adjust → Grid Spread (Smart View)                       │
│  3. User enters value/percentage and selects pattern        │
│  4. User clicks "Spread"                                    │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  EPM ENGINE PROCESSING (In-Memory)                          │
│                                                             │
│  Step A: IDENTIFY TARGET CELLS                              │
│    • Scan the grid layout for all descendant/child cells    │
│      of the selected parent — BUT ONLY cells that are:      │
│      ✅ Visible on the current form grid                    │
│      ✅ Writable (user has write access)                    │
│      ✅ Not locked (cell lock not active)                   │
│      ✅ Not read-only (no Dynamic Calc, no formula cells)   │
│      ✅ Not containing Supporting Detail                    │
│                                                             │
│  Step B: CALCULATE DISTRIBUTION                             │
│    • Apply the selected spread pattern:                     │
│      - Proportional: new_value = existing_value ×           │
│                      (adjustment / total_existing)          │
│      - Evenly: new_value = total / count_of_targets         │
│      - Fill: new_value = spread_value (same for all)        │
│                                                             │
│  Step C: IN-MEMORY UPDATE                                   │
│    • Update the cell values in the BROWSER/EXCEL memory     │
│    • The database is NOT yet changed!                       │
│    • User sees the new values on screen immediately         │
│                                                             │
│  Step D: USER SAVES THE FORM                                │
│    • Values are submitted (written) to Essbase/database     │
│    • Only Store-type level-0 cells receive the data         │
│    • Dynamic Calc parents recalculate automatically         │
└─────────────────────────────────────────────────────────────┘
```

### Critical Architectural Points

1. **Grid Spread is a CLIENT-SIDE calculation** — The math happens in the browser (Web) or in Excel (Smart View) before submission.
2. **Nothing is saved until the user clicks Save/Submit** — This is a key difference from Mass Allocate, which writes directly to the database.
3. **Scope is LIMITED to what's on the grid** — If a child member is not displayed on the form, Grid Spread cannot and will not distribute to it. This is fundamentally different from Mass Allocate.
4. **Grid Spread walks the dimensional hierarchy on the grid axes** — It follows rows and columns to identify which cells are parents and which are children.

---

## 5. Spreading Patterns Explained

Grid Spread offers three built-in patterns for distributing data:

### 5.1 Proportional Spread (Default)

**Logic:** Distributes the new value across target cells in proportion to their **existing values**.

**Formula:**
```
New Cell Value = Existing Cell Value × (New Total / Existing Total)
```

**Example:**
| Month | Existing Value | Proportion | New Value (Total = $120,000) |
|:---|---:|---:|---:|
| Jan | $20,000 | 20% | $24,000 |
| Feb | $10,000 | 10% | $12,000 |
| Mar | $30,000 | 30% | $36,000 |
| Apr | $40,000 | 40% | $48,000 |
| **Q1 Total** | **$100,000** | **100%** | **$120,000** |

**When to Use:**
*   You want to preserve the existing seasonal/distribution pattern.
*   Historical data already reflects the correct relative mix.

**Important Edge Case — All Zeros or All #MISSING:**
If all target cells contain `0` or `#MISSING`, proportional spread **degenerates into an even spread** because there's no existing pattern to proportion from. The value is split equally.

### 5.2 Evenly Split

**Logic:** Divides the value equally across ALL valid target cells, regardless of existing values.

**Formula:**
```
New Cell Value = Total Value / Count of Valid Target Cells
```

**Example:**
| Month | Existing Value | New Value (Total = $120,000 ÷ 4 months) |
|:---|---:|---:|
| Jan | $20,000 | $30,000 |
| Feb | $10,000 | $30,000 |
| Mar | $30,000 | $30,000 |
| Apr | $40,000 | $30,000 |
| **Q1 Total** | **$100,000** | **$120,000** |

**When to Use:**
*   No historical data exists (new budget items).
*   Business requirement is equal monthly distribution (e.g., rent, salaries).

### 5.3 Fill

**Logic:** Places the **exact entered value** into EVERY target cell, replacing whatever was there before.

**Formula:**
```
New Cell Value = Spread Value (identical for all)
```

**Example:**
| Month | Existing Value | New Value (Fill = $30,000) |
|:---|---:|---:|
| Jan | $20,000 | $30,000 |
| Feb | $10,000 | $30,000 |
| Mar | $30,000 | $30,000 |
| Apr | $40,000 | $30,000 |
| **Q1 Total** | **$100,000** | **$120,000** (sum) |

**When to Use:**
*   Fixed recurring costs (monthly rent of exactly $30K).
*   Headcount that stays flat (e.g., 5 FTEs every month).

**⚠️ Warning — Time Balance Impact:**
The "Fill" pattern interacts with the Account dimension's **Time Balance** property. For **Balance** accounts (First, Last, Average), filling $30K into every month does NOT produce a Year Total of $360K — it produces $30K at the parent level because the parent uses Last/First/Average instead of Sum. See [Section 14](#14-time-balance-property-impact-on-grid-spread).

### Pattern Comparison Matrix

| Aspect | Proportional | Evenly Split | Fill |
|:---|:---|:---|:---|
| **Preserves existing pattern—** | ✅ Yes | ❌ No | ❌ No |
| **Works with all-zero data—** | ⚠️ Degenerates to even split | ✅ Yes | ✅ Yes |
| **Result at parent** | Equals the entered total | Equals the entered total | Equals SUM of fills (or Time Balance result) |
| **Best for** | Seasonal budgets, revenue forecasting | New items, flat distributions | Fixed recurring costs |

---

## 6. Custom Spread Patterns

### What is a Custom Spread Pattern—

Beyond the three built-in patterns, Oracle EPM allows administrators to define **Custom Spread Patterns** — weighted distribution templates that control exactly how data flows from parent to children. These custom patterns appear in the **Spread Pattern dropdown** within the Grid Spread and Mass Allocate dialogs.

### How Custom Patterns are Defined

Custom Spread Patterns are application-level artifacts stored in the Planning relational database (historically in the `HSP_SPREAD_PATTERN` table in on-premises Hyperion).

**In Oracle EPM Cloud:**
*   Custom Spread Patterns are defined through the application and are listed under **Spread Patterns** in the migration artifact list.
*   They can be exported/imported as XML via Migration (Administration → Migration).

### Custom Pattern Weights — How They Work

A custom pattern typically assigns a **numeric weight** to each target member (usually periods):

| Month | Weight | Calculation |
|:---|---:|:---|
| Jan | 8 | `(8 / 100) × Total` |
| Feb | 7 | `(7 / 100) × Total` |
| Mar | 9 | `(9 / 100) × Total` |
| Apr | 8 | `(8 / 100) × Total` |
| May | 9 | `(9 / 100) × Total` |
| Jun | 10 | `(10 / 100) × Total` |
| Jul | 10 | `(10 / 100) × Total` |
| Aug | 9 | `(9 / 100) × Total` |
| Sep | 8 | `(8 / 100) × Total` |
| Oct | 8 | `(8 / 100) × Total` |
| Nov | 7 | `(7 / 100) × Total` |
| Dec | 7 | `(7 / 100) × Total` |
| **Total Weight** | **100** | |

**Example:** Spread $1,000,000 annual revenue using the above seasonal pattern:
*   January: `$1,000,000 × (8/100) = $80,000`
*   June: `$1,000,000 × (10/100) = $100,000`
*   December: `$1,000,000 × (7/100) = $70,000`

### Cloud Limitation

In Oracle EPM Cloud, the UI for custom spread patterns is more limited compared to on-premises. For complex custom weighted allocations, Oracle recommends using:
*   **Groovy Business Rules** — Intercept data changes and apply custom weights programmatically.
*   **Calc Manager Allocation Templates** — Use the Allocation wizard for driver-based distributions.

---

## 7. Step-by-Step: Using Grid Spread (Web and Smart View)

### 7.1 Using Grid Spread in the Web Interface

1. **Open the Data Form** that has Grid Spread enabled.
2. **Click on a parent/summary cell** whose value you want to distribute.
3. Click **Edit** (or **Data**) in the form toolbar.
4. Select **Grid Spread** from the dropdown menu.
5. In the Grid Spread dialog:
   *   **Spread Type:** Choose `Value` or `Percentage`.
   *   **Adjustment:** Choose `Increase by`, `Decrease by`, or enter a target value.
   *   **Spread Pattern:** Choose `Proportional Spread`, `Evenly Split`, `Fill`, or a custom pattern (if configured).
   *   **Spread Value:** Enter the numeric amount or percentage.
6. Click **Spread**.
7. Review the results on the grid (values update immediately in the browser).
8. Click **Save** to commit to the database, or **Refresh** to discard.

### 7.2 Using Grid Spread in Smart View (Excel)

1. **Open the form** in Smart View for Office (Excel).
2. **Click on a parent/summary cell** in the worksheet.
3. Go to the **Planning ribbon** (or the Smart View provider ribbon).
4. Click **Adjust → Grid Spread**.
5. Fill in the Grid Spread dialog (same options as Web: value/percentage, pattern).
6. Click **Spread**.
7. Click **Submit Data** to save changes to the database.

> **💡 Tip:** In Smart View, Grid Spread is also accessible via the **right-click context menu** on the cell — look for it under the Smart View flyout.

### 7.3 Adjustment Types

| Adjustment Type | What It Does | Example |
|:---|:---|:---|
| **Increase by Value** | Adds a flat amount to the existing parent total, then re-spreads | Parent = $100K → Increase by $20K → New total $120K is spread |
| **Decrease by Value** | Subtracts a flat amount from the existing parent total, then re-spreads | Parent = $100K → Decrease by $10K → New total $90K is spread |
| **Increase by Percentage** | Increases the parent total by a percentage, then re-spreads | Parent = $100K → Increase by 10% → New total $110K is spread |
| **Decrease by Percentage** | Decreases the parent total by a percentage, then re-spreads | Parent = $100K → Decrease by 5% → New total $95K is spread |
| **Spread Value (Direct Entry)** | Replaces the parent total with the entered value, then spreads | Parent = $100K → Enter $150K → New total $150K is spread |

---

## 8. Grid Spread and Member Storage Properties — The Critical Rules

This is the **most important section** for understanding when Grid Spread works and when it fails. The behavior of Grid Spread is fundamentally tied to the **Data Storage Property** of the members involved.

### 8.1 Store Members ✅

| Property | Grid Spread Behavior |
|:---|:---|
| **Data Storage** | Store |
| **Can be a SOURCE cell—** | ✅ Yes — you CAN select a Store member cell and spread from it |
| **Can be a TARGET cell—** | ✅ Yes — Grid Spread WILL write data to Store members |
| **Typical Use** | Level-0 (leaf) members where data is physically stored |

**This is the happy path.** Grid Spread is designed to write data into Store-type level-0 members.

**Example:**
```
Entity Dimension:
  Total Company (Dynamic Calc — aggregates children)
    ├── East Region (Dynamic Calc — aggregates children)
    │     ├── New York (Store)    ← ✅ Grid Spread writes here
    │     ├── Boston (Store)      ← ✅ Grid Spread writes here
    │     └── Philadelphia (Store)← ✅ Grid Spread writes here
    └── West Region (Dynamic Calc)
          ├── Los Angeles (Store) ← ✅ Grid Spread writes here
          └── San Francisco (Store)← ✅ Grid Spread writes here
```

### 8.2 Dynamic Calc Members ❌

| Property | Grid Spread Behavior |
|:---|:---|
| **Data Storage** | Dynamic Calc |
| **Can be a SOURCE cell—** | ✅ Yes — you CAN select a Dynamic Calc parent and say "spread this total down" |
| **Can be a TARGET cell—** | ❌ **NO** — Grid Spread CANNOT write data to a Dynamic Calc member |

**Why—** Dynamic Calc members do not physically store data. They calculate their values on-the-fly by aggregating their children or evaluating a member formula. Since Grid Spread needs to **write** values into cells, and Dynamic Calc cells cannot accept writes, the system **skips** them entirely.

**The Golden Rule:**
> *You can spread FROM a Dynamic Calc parent, but Grid Spread will ONLY write data INTO its Store-type children/descendants. Dynamic Calc members in the target path are simply skipped.*

**Example — Spreading FROM a Dynamic Calc parent:**
```
Period Dimension:
  YearTotal (Dynamic Calc)  ← User right-clicks here, enters $120K
    ├── Q1 (Dynamic Calc)   ← SKIPPED (cannot receive writes)
    │     ├── Jan (Store)   ← ✅ Receives $10K
    │     ├── Feb (Store)   ← ✅ Receives $10K
    │     └── Mar (Store)   ← ✅ Receives $10K
    ├── Q2 (Dynamic Calc)   ← SKIPPED
    │     ├── Apr (Store)   ← ✅ Receives $10K
    │     ...
    └── Q4 (Dynamic Calc)   ← SKIPPED
          └── Dec (Store)   ← ✅ Receives $10K
```

### 8.3 Dynamic Calc and Store Members ⚠️

| Property | Grid Spread Behavior |
|:---|:---|
| **Data Storage** | Dynamic Calc and Store |
| **Can be a TARGET cell—** | ⚠️ **Conditional** — The system may accept the write, BUT the member formula will overwrite the stored value on the next retrieval/recalculation |

**The Problem:** A "Dynamic Calc and Store" member has a member formula. If you Grid Spread a value INTO it, the value may appear to save. But on the next database retrieval or form refresh, the member formula recalculates and **overwrites** the stored value. The user sees their spread value "disappear."

**Verdict:** Avoid targeting "Dynamic Calc and Store" members with Grid Spread. It creates confusion and unreliable data.

### 8.4 Never Share Members

| Property | Grid Spread Behavior |
|:---|:---|
| **Data Storage** | Never Share |
| **Can be a TARGET cell—** | ✅ Yes — Grid Spread treats it like a Store member; it can receive writes |

### 8.5 Summary Table: Storage Properties & Grid Spread

| Data Storage Property | Can be SOURCE— | Can be TARGET— | Notes |
|:---|:---:|:---:|:---|
| **Store** | ✅ | ✅ | The ideal target cell type |
| **Dynamic Calc** | ✅ | ❌ | Skipped — cannot accept writes |
| **Dynamic Calc and Store** | ✅ | ⚠️ Risky | Write may succeed but gets overwritten by formula |
| **Never Share** | ✅ | ✅ | Works like Store |
| **Label Only** | ❌ | ❌ | No data storage at all — see Section 10 |
| **Shared Member** | ✅ | ⚠️ Conditional | See Section 9 |

---

## 9. Grid Spread and Shared Members

### What Happens When Grid Spread Targets a Shared Member—

**Shared members** are pointers to a "base" (primary) member that exists elsewhere in the hierarchy. They enable alternate rollup hierarchies without duplicating data.

### The Rules

| Rule | Details |
|:---|:---|
| **Can you spread TO a shared member—** | ✅ **Yes**, if the user has write access to the underlying base member |
| **Where does the data go—** | The data is written to the **base member**, not a separate storage location |
| **Security check** | If the shared member's context (e.g., alternate hierarchy security) renders it read-only, Grid Spread **skips** it |
| **Member formula** | Shared members **cannot have their own member formulas** — they inherit all properties from the base member |

### Example: Grid Spread with Shared Members

```
Primary Hierarchy:                    Alternate Hierarchy:
  Total Accounts                        Geographic View
    ├── Revenue (Store)                   ├── North America
    │     ├── Product A (Store)           │     ├── Product A (Shared → Revenue.Product A)
    │     └── Product B (Store)           │     └── Product C (Shared → Revenue.Product C)
    └── ...                               └── Europe
                                                └── Product B (Shared → Revenue.Product B)
```

If a user performs Grid Spread on the "North America" parent in the Alternate Hierarchy, the data will flow through the shared members and ultimately **write to the base members** (Product A and Product C under Revenue).

### Key Gotcha
If the base member is set to **Dynamic Calc**, then even though the shared member appears on the form, it is functionally read-only. Grid Spread will skip it.

---

## 10. Grid Spread and Label-Only Members

### The Rule: Absolute Prohibition ❌

| Aspect | Details |
|:---|:---|
| **Can Grid Spread write to a Label-Only member—** | ❌ **No — Never** |
| **Can Grid Spread source from a Label-Only member—** | ❌ **No** — Label-Only members have no data to spread |
| **Why—** | Label-Only members are structural placeholders. They do NOT store data values, they do NOT have data intersections in the cube, and they cannot participate in any data write operation |

### What is a Label-Only Member—
A Label-Only member is a parent node used purely for **organizational/structural grouping**. It has no data storage, no aggregation, and no calculation. It simply provides a label/header in the hierarchy.

### Implied Share Trap
When a parent is set to "Label Only," it creates an **implied share** with its first child. This means:
*   The parent DISPLAYS the first child's value.
*   But the parent is still read-only — Grid Spread cannot write to it.
*   If users see a value on a Label-Only parent and try to Grid Spread from it, the behavior is undefined or will fail.

### Example
```
Account Dimension:
  Operating Expenses (Label Only)     ← ❌ Grid Spread will NOT work here
    ├── Travel (Store)                ← ✅ Writable target
    ├── Training (Store)              ← ✅ Writable target
    └── Supplies (Store)              ← ✅ Writable target
```

**Best Practice:** If you need users to Grid Spread from a parent, set that parent to **Dynamic Calc** (not Label Only) so it can display an aggregated total that users can spread downward.

---

## 11. Grid Spread and Member Formulas

### The Rule: Formula-Driven Cells are Read-Only ❌

Cells whose values are governed by a **member formula** are treated as **read-only** by Grid Spread. The system skips them entirely.

### Why—
Member formulas enforce calculation logic (e.g., `"Revenue" - "Expenses"`). If Grid Spread were to overwrite these cells, it would break the formula-based integrity. The system protects formula cells from inadvertent data input.

### Scenarios

| Scenario | Grid Spread Behavior |
|:---|:---|
| Target cell has a member formula (e.g., `"Gross Margin" = "Revenue" - "COGS"`) | ❌ Skipped — read-only |
| Parent has a member formula but children do not | ✅ Grid Spread writes to children; parent recalculates via formula |
| Dynamic Calc member with a formula | ❌ Skipped (Double reason: Dynamic Calc + Formula = definitely read-only) |
| Store member with a member formula ("Dynamic Calc and Store") | ⚠️ May accept write but formula overwrites on next calc/refresh |

### Example
```
Account Dimension:
  Revenue (Store)              ← ✅ Writable — receives Grid Spread
  COGS (Store)                 ← ✅ Writable — receives Grid Spread
  Gross Margin (Dynamic Calc)  ← ❌ Formula: "Revenue" - "COGS" — SKIPPED
  Operating Expenses (Store)   ← ✅ Writable — receives Grid Spread
  Net Income (Dynamic Calc)    ← ❌ Formula: "Gross Margin" - "OpEx" — SKIPPED
```

If a user tries to Grid Spread a value across all accounts, `Gross Margin` and `Net Income` will be **skipped**, and the spread will only distribute across `Revenue`, `COGS`, and `Operating Expenses`.

---

## 12. Grid Spread vs Default Spreading vs Mass Allocate

These three are often confused. Here is the complete comparison:

### Comparison Matrix

| Feature | Default Spreading | Grid Spread | Mass Allocate |
|:---|:---|:---|:---|
| **What triggers it** | Typing a value into a parent time period cell and hitting Enter/Tab | Selecting a cell → Edit → Grid Spread | Selecting a cell → Adjust → Mass Allocate |
| **Primary scope** | **Time dimension only** (periods) | **Any dimension visible on the grid** | **Any dimension, including hidden descendants** |
| **Target cells must be visible—** | Time children are usually on the form | ✅ **Yes — mandatory** | ❌ **No — can write to unseen descendants** |
| **Writes directly to database—** | After Save | After Save | ✅ **Yes — immediately on execution** |
| **Respects form security—** | ✅ Yes | ✅ Yes | ❌ **No — writes directly to Essbase, bypassing form security** |
| **Requires special role—** | No | No | ✅ **Yes — requires "Mass Allocate" role** |
| **Reversibility** | Undo before save | Undo before save | ❌ **Cannot undo — requires reverse data submission** |
| **Spread patterns** | Time Balance properties, weekly layouts (4-4-5) | Proportional, Even, Fill (+ custom) | Proportional, Even, Fill (+ custom) |
| **Form property** | Always available (unless spreading disabled) | Must enable "Enable Grid Spread" | Must enable "Enable Mass Allocate" |
| **Smart View property** | Controlled by "Disable Spreading" | Controlled by "Disable Spreading" | Controlled by "Disable Spreading" |
| **Performance impact** | Minimal | Minimal (client-side calculation) | Can be heavy (writes to many blocks in Essbase) |

### When to Use Which—

| Scenario | Recommended Tool |
|:---|:---|
| Distributing annual budget to months | Default Spreading or Grid Spread |
| Adjusting Q2 forecast by 10% across visible months | Grid Spread |
| Spreading a corporate target to all 200 cost centers (most not on the form) | Mass Allocate |
| Writing data to cells the user cannot see on the form | Mass Allocate |
| Quick what-if analysis (try before committing) | Grid Spread (can undo before save) |
| Complex multi-dimensional allocation with driver-based weighting | Calc Manager Allocation Templates or Groovy Rules |

---

## 13. Grid Spread Across BSO, ASO, and Hybrid Mode

### 13.1 Traditional BSO (Block Storage Option) ✅

| Aspect | Behavior |
|:---|:---|
| **Grid Spread supported—** | ✅ Fully supported |
| **Requirements** | All intermediate generations between parent and level-0 must be on the form |
| **Write target** | Level-0 stored blocks |
| **After save** | Requires manual or scripted rollup (AGG/CALC) to update parent aggregates |

### 13.2 Pure ASO (Aggregate Storage Option) ❌

| Aspect | Behavior |
|:---|:---|
| **Grid Spread supported—** | ❌ **Not natively supported** for upper-level parents |
| **Why—** | ASO is designed for fast aggregation and reporting, not data input. Upper-level cells are dynamically aggregated and read-only |
| **Workaround** | Use Groovy Rules or custom MDX write-back scripts to achieve similar behavior |

### 13.3 Hybrid BSO Mode ✅ (Optimized)

| Aspect | Behavior |
|:---|:---|
| **Grid Spread supported—** | ✅ **Fully supported and optimized** |
| **Advantage** | Leverages **Calc-on-the-Fly** — back-spreading to level-0 cells is seamless |
| **After save** | Parent aggregates update **instantly** (no manual rollup needed) |
| **Performance** | Significantly faster than traditional BSO |

### Comparison Table

| Feature | Pure ASO | Traditional BSO | Hybrid BSO |
|:---|:---|:---|:---|
| **Parent-Level Grid Spread** | ❌ Not supported | ✅ Supported | ✅ Supported + optimized |
| **Data write target** | N/A | Level-0 stored blocks | Level-0 cells via Calc-on-the-Fly |
| **Post-save rollup** | N/A | Manual calc script needed | Automatic (instant) |
| **Performance** | N/A | Depends on block density | Highly efficient |

---

## 14. Time Balance Property Impact on Grid Spread

The Account dimension's **Time Balance** property fundamentally affects how Grid Spread results appear at parent time levels.

### How Time Balance Interacts with Grid Spread

| Time Balance | Account Example | Aggregation Logic | Grid Spread Impact |
|:---|:---|:---|:---|
| **Flow** (default) | Revenue, Expenses | Parent = Sum of children | Standard behavior — parent shows the sum of spread children |
| **First** | Opening Balance | Parent = First child's value | After Fill spread, parent shows only Jan's value, NOT the sum |
| **Last** | Closing Balance, Headcount | Parent = Last child's value | After Fill spread, parent shows only Dec's value |
| **Average** | Average Headcount | Parent = Average of children | After Fill spread, parent shows the average (which happens to equal the fill value if all are the same) |

### Common Confusion: Fill Spread on Balance Accounts

**Scenario:** User fills $30,000 into each month for a "Headcount" account (Time Balance = Last).

| Month | Value |
|:---|---:|
| Jan | 30,000 |
| Feb | 30,000 |
| ... | 30,000 |
| Dec | 30,000 |
| **YearTotal** | **30,000** ← NOT $360,000! |

The YearTotal shows $30,000 because Time Balance = Last → Parent takes the last child's value.

**Best Practice:** Always verify the Time Balance property of the account before performing Grid Spread, especially when using the "Fill" pattern.

---

## 15. Grid Spread and Spread Patterns (Migration Artifact)

### Spread Patterns as Artifacts

Spread Patterns are classified as **Application-level artifacts** in Oracle EPM Cloud:

| Artifact Property | Value |
|:---|:---|
| **Category** | Application Artifacts |
| **Name** | Spread Patterns |
| **Description** | A custom spreading pattern that determines how data is distributed from a parent to its children |
| **Available From** | Mass Allocate and Grid Spread menus |
| **Last Modified Time** | No |
| **Last Modified User** | No |
| **Editable (Import)** | Yes: XML |
| **Dependencies** | None |

### Migration Considerations
*   Spread Patterns are exported/imported as **XML** files.
*   They have **no dependencies** on other artifacts.
*   When migrating between environments, always include Spread Patterns in the migration snapshot if your forms use custom patterns for Grid Spread.

---

## 16. Complete Scenarios Where Grid Spread Will NOT Work

This is the most critical reference section. Grid Spread will **fail** or **silently skip cells** in all of the following scenarios:

### 16.1 Form-Level Failures (Grid Spread Option Not Available)

| # | Scenario | Why It Fails | Fix |
|:---:|:---|:---|:---|
| 1 | **"Enable Grid Spread" is NOT checked** on the form | Feature is disabled at the form level | Admin must enable it in Form → Layout → Display Properties |
| 2 | **"Disable Spreading" IS checked** under Smart View Options | Overrides all spreading in Smart View | Admin must uncheck "Disable Spreading" |
| 3 | **Form is set to Read-Only** ("Make form read-only" is checked) | Entire form is read-only — no writable targets | Uncheck "Make form read-only" |
| 4 | **Dashboard 2.0 component** (grid inside a dashboard) | Grid Spread is NOT available directly on dashboard components | Must click "Open Form" (Actions menu) to open the underlying form in a separate tab |
| 5 | **ASO cube form** | ASO does not support direct data input to upper-level parents | Use Groovy or switch to BSO/Hybrid |

### 16.2 Cell-Level Failures (Grid Spread Skips Specific Cells)

| # | Scenario | Why It's Skipped | Fix |
|:---:|:---|:---|:---|
| 6 | **Target cell is Dynamic Calc** | Cannot accept writes (calculates on-the-fly) | Change member to Store, or spread to its Store children |
| 7 | **Target cell is Label Only** | No data storage — purely structural | Change to Dynamic Calc or Store |
| 8 | **Target cell has a Member Formula** (and is Dynamic Calc) | Read-only — formula governs the value | Remove the formula or use a different target member |
| 9 | **Target cell has Supporting Detail** | Grid Spread skips cells with supporting detail | Clear/remove the supporting detail first |
| 10 | **Target cell is Locked** (cell lock is active) | Locked cells are deliberately protected from changes | Unlock the cell before spreading |
| 11 | **Target cell is Read-Only due to security** | User lacks write access to that intersection | Grant write access via security |
| 12 | **Target cell is in a Locked Version/Scenario** | The version or scenario is locked for input | Unlock the version or use a target bottom-up version |
| 13 | **Target child members are NOT visible on the form grid** | Grid Spread only affects visible cells | Add the missing members to the form layout, or use Mass Allocate |
| 14 | **All target cells are zero/#MISSING** (Proportional pattern) | Proportional spread has no pattern to proportion from | Not truly a failure — it degenerates to even split, but the result may surprise users |
| 15 | **Shared member whose base member is Dynamic Calc** | The shared member inherits the base member's storage property | Change the base member to Store |
| 16 | **Target cell is in a suppressed/hidden row** | If the row is suppressed (e.g., #MISSING suppression), the cell is not on the grid | Disable suppression or ensure data exists |
| 17 | **Dynamic Calc and Store member** | Write may succeed but formula overwrites on refresh | Avoid using as target — redesign the member hierarchy |

### 16.3 Dimension/Hierarchy Failures

| # | Scenario | Why It Fails | Fix |
|:---:|:---|:---|:---|
| 18 | **Source cell is a level-0 (leaf) member with no children** | Grid Spread requires children to distribute TO | Use a parent/summary cell as the source |
| 19 | **Flex Form with Period dimension flex-enabled on the spread axis** | Grid Spread is not fully supported in this configuration | Remove Period from flex-enabled axes |
| 20 | **Valid Intersection rules exclude target cells** | The intersection is marked as invalid — system treats it as read-only | Adjust valid intersection rules |

---

## 17. Complete Scenarios Where Grid Spread WILL Work

| # | Scenario | Behavior |
|:---:|:---|:---|
| 1 | **Parent (Dynamic Calc) → Store children visible on grid** | ✅ Works perfectly — the standard use case |
| 2 | **Store parent → Store children** | ✅ Works — parent value is overwritten by the new total |
| 3 | **Shared members pointing to Store base members** | ✅ Works — data writes through to the base member |
| 4 | **Increase/Decrease by Value** | ✅ Works — adjusts the total then re-spreads |
| 5 | **Increase/Decrease by Percentage** | ✅ Works — calculates new total then re-spreads |
| 6 | **Proportional spread on cells with existing data** | ✅ Works — preserves relative distribution |
| 7 | **Even spread on all-zero or all-#MISSING cells** | ✅ Works — divides equally |
| 8 | **Fill spread** | ✅ Works — places identical value in every target cell |
| 9 | **Hybrid BSO cube** | ✅ Works (optimized with Calc-on-the-Fly) |
| 10 | **Traditional BSO cube** | ✅ Works (requires post-save aggregation) |
| 11 | **Smart View (Excel) — Adjust → Grid Spread** | ✅ Works (if "Disable Spreading" is unchecked) |
| 12 | **Ad Hoc Grid** | ✅ Works (if Grid Spread enabled on the connection/app) |
| 13 | **Cell with Locked sibling — spreading skips the locked cell** | ✅ Works — remaining unlocked cells absorb the full spread |
| 14 | **Custom Spread Pattern selected** | ✅ Works — uses administrator-defined weights |
| 15 | **Never Share members** | ✅ Works — treated like Store members |

---

## 18. Practical Examples with Numbers

### Example 1: Proportional Spread — Updating Revenue Forecast

**Scenario:** The Q1 Revenue forecast is currently $90,000 (based on monthly data). The VP wants to increase it to $120,000, maintaining the existing seasonal pattern.

**Before Grid Spread:**
| Month | Revenue |
|:---|---:|
| Jan | $30,000 |
| Feb | $20,000 |
| Mar | $40,000 |
| **Q1 Total** | **$90,000** |

**Action:** User clicks on Q1 Total → Edit → Grid Spread → Value: $120,000 → Proportional Spread → Spread

**Calculation:**
```
Jan = $30,000 × ($120,000 / $90,000) = $30,000 × 1.3333 = $40,000
Feb = $20,000 × ($120,000 / $90,000) = $20,000 × 1.3333 = $26,667
Mar = $40,000 × ($120,000 / $90,000) = $40,000 × 1.3333 = $53,333
```

**After Grid Spread:**
| Month | Revenue |
|:---|---:|
| Jan | $40,000 |
| Feb | $26,667 |
| Mar | $53,333 |
| **Q1 Total** | **$120,000** ✅ |

---

### Example 2: Even Spread — New Budget Line Item

**Scenario:** A new "Cloud Infrastructure" expense account has been created. The annual budget is $240,000. No historical data exists.

**Action:** User clicks on YearTotal → Grid Spread → Value: $240,000 → Evenly Split → Spread

**After Grid Spread:**
| Month | Cloud Infrastructure |
|:---|---:|
| Jan | $20,000 |
| Feb | $20,000 |
| Mar | $20,000 |
| ... | $20,000 |
| Dec | $20,000 |
| **YearTotal** | **$240,000** ✅ |

---

### Example 3: Percentage Increase — Adjusting All Months

**Scenario:** Management decides to increase the entire department's travel budget by 15%.

**Before:** Q1 Travel = $30,000 (Jan=$8K, Feb=$10K, Mar=$12K)

**Action:** User clicks Q1 Total → Grid Spread → Percentage → Increase by 15% → Proportional Spread → Spread

**Calculation:**
```
New Q1 Total = $30,000 × 1.15 = $34,500
Jan = $8,000 × ($34,500 / $30,000) = $9,200
Feb = $10,000 × ($34,500 / $30,000) = $11,500
Mar = $12,000 × ($34,500 / $30,000) = $13,800
```

**After Grid Spread:**
| Month | Travel |
|:---|---:|
| Jan | $9,200 |
| Feb | $11,500 |
| Mar | $13,800 |
| **Q1 Total** | **$34,500** ✅ |

---

### Example 4: Grid Spread with Locked Cells

**Scenario:** User wants to spread $120,000 across Q1, but February is locked (e.g., actuals already loaded).

**Before:** Jan=$30K, **Feb=$25K (LOCKED)**, Mar=$40K → Q1 = $95K

**Action:** Grid Spread → Value: $120,000 → Proportional Spread

**What Happens:**
*   Feb is locked → **SKIPPED** (stays at $25,000).
*   Remaining amount to spread: $120,000 - $25,000 = **$95,000**.
*   This $95,000 is spread proportionally across Jan and Mar.

```
Jan = $30,000 × ($95,000 / $70,000) = $40,714
Mar = $40,000 × ($95,000 / $70,000) = $54,286
```

**After Grid Spread:**
| Month | Revenue |
|:---|---:|
| Jan | $40,714 |
| Feb | **$25,000** (locked — unchanged) |
| Mar | $54,286 |
| **Q1 Total** | **$120,000** ✅ |

---

### Example 5: Grid Spread Failure — Dynamic Calc Children

**Scenario:** A user tries to spread $100,000 across entities, but ALL child entities are set to Dynamic Calc.

```
Total Entity (Dynamic Calc)  ← User tries to spread $100K from here
  ├── East (Dynamic Calc)    ← ❌ SKIPPED
  ├── West (Dynamic Calc)    ← ❌ SKIPPED
  └── Central (Dynamic Calc) ← ❌ SKIPPED
```

**Result:** Grid Spread finds **ZERO valid target cells**. The operation does nothing or shows an error. No data is distributed.

**Fix:** Change the children to **Store** data storage, or add level-0 Store members as children of these Dynamic Calc members and display them on the form.

---

## 19. Dashboard 2.0 and Grid Spread

### The Limitation

When a form is embedded as a **grid component inside a Dashboard 2.0**, the grid actions (including **Grid Spread**, Adjust, and Comment) are **NOT directly available** on the dashboard component.

### The Workaround

To access Grid Spread for a dashboard grid component:
1. Hover over the grid component in the dashboard.
2. Click the **Actions** icon (⋮ or gear icon).
3. Select **"Open Form"**.
4. The underlying form opens in a **new dynamic tab**.
5. Use Grid Spread normally in this opened form.

> **📖 Reference:** The Oracle documentation explicitly states: *"The Maximize option only enlarges the dashboard component. If the dashboard component is a grid and you want to perform grid actions on the component such as Adjust, Grid Spread, Comment, and so on, select Open Form (in the Actions menu)."*

---

## 20. Troubleshooting Guide

### Problem → Cause → Solution

| Problem | Likely Cause | Solution |
|:---|:---|:---|
| **Grid Spread option is greyed out / not visible** | "Enable Grid Spread" not checked on the form, OR form is read-only | Admin: Enable Grid Spread in form Display Properties |
| **Grid Spread works on Web but not in Smart View** | "Disable Spreading" is checked under Smart View Options | Admin: Uncheck "Disable Spreading" in form Smart View Options |
| **Grid Spread runs but values don't change** | All target cells are Dynamic Calc or have member formulas | Verify target members' data storage properties — need Store members |
| **Values appear after spread but vanish after Save/Refresh** | Target members are "Dynamic Calc and Store" — formula overwrites | Change targets to Store, or redesign formulas |
| **Spread distribution is wrong (all equal when expected proportional)** | All existing target values are zero or #MISSING | Expected behavior — with no existing pattern, proportional = even split |
| **Parent total after spread doesn't match expected amount** | Account has non-Flow Time Balance (First/Last/Average) | Check the account's Time Balance property — it changes parent aggregation |
| **Some cells are skipped during spread** | Cells have Supporting Detail, are locked, or are read-only | Clear supporting detail, unlock cells, or grant write access |
| **Grid Spread doesn't distribute to hidden members** | Grid Spread only targets visible cells | Use Mass Allocate instead, or add hidden members to the form |
| **"You do not have sufficient access" error** | User lacks write permission to target intersections | Update security filters / data access grants |
| **Grid Spread doesn't appear in Dashboard 2.0** | Grid actions are not available on dashboard components | Use Actions → Open Form to open the form in a new tab |
| **Shared member cells are skipped** | Base member is Dynamic Calc or user lacks access to the base | Check base member storage property and security |

---

## 21. Quick Reference Cheat Sheet

### Grid Spread at a Glance

```
┌──────────────────────────────────────────────────────────────┐
│                    GRID SPREAD CHEAT SHEET                    │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ENABLE:   Form → Layout → Display Properties →              │
│            ✅ Enable Grid Spread                             │
│                                                              │
│  ACCESS:   Web: Edit → Grid Spread                           │
│            Smart View: Adjust → Grid Spread                  │
│                                                              │
│  PATTERNS: Proportional | Evenly Split | Fill | Custom       │
│                                                              │
│  WRITES TO:                                                  │
│    ✅ Store members                                          │
│    ✅ Never Share members                                    │
│    ✅ Shared members (if base is Store + writable)           │
│    ❌ Dynamic Calc members                                   │
│    ❌ Label-Only members                                     │
│    ❌ Locked cells                                           │
│    ❌ Read-only cells                                        │
│    ❌ Cells with Supporting Detail                           │
│    ❌ Cells with Member Formulas (Dynamic Calc)              │
│    ⚠️  Dynamic Calc and Store (writes but gets overwritten)  │
│                                                              │
│  SCOPE:    ONLY cells visible on the current grid            │
│            (Use Mass Allocate for hidden descendants)         │
│                                                              │
│  SAVES:    Client-side only until user clicks Save/Submit    │
│                                                              │
│  CUBES:                                                      │
│    ✅ BSO (Traditional) — works, needs manual rollup         │
│    ✅ Hybrid BSO — works optimally (Calc-on-the-Fly)        │
│    ❌ ASO — not natively supported                           │
│                                                              │
│  DASHBOARD: Not available directly on dashboard components   │
│             → Use Actions → Open Form                        │
│                                                              │
│  SMART VIEW TRAP:                                            │
│    If "Disable Spreading" is checked → Grid Spread is        │
│    blocked in Smart View even if enabled on the form!        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Decision Tree: Which Spreading Tool to Use—

```
                    ┌─────────────────────┐
                    │ Need to distribute   │
                    │ data from a parent—  │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │ Are ALL target cells │
                    │ visible on the form— │
                    └─────────┬───────────┘
                         ╱         ╲
                       Yes           No
                       ╱               ╲
           ┌──────────▼─────┐    ┌──────▼──────────┐
           │ Is it just the │    │ Use Mass         │
           │ Time dimension—│    │ Allocate         │
           └───────┬────────┘    │ (or Groovy/Calc  │
                ╱     ╲          │  Manager Rules)  │
              Yes       No       └─────────────────┘
              ╱           ╲
  ┌──────────▼─────┐  ┌───▼───────────┐
  │ Default         │  │ Grid Spread    │
  │ Spreading       │  │ (Edit menu)    │
  │ (just type &    │  │                │
  │  press Enter)   │  │                │
  └────────────────┘  └────────────────┘
```

---

*Document Version: 1.0*
*Last Updated: October 2026*
*Applies to: Oracle Cloud EPM — Planning, FreeForm, Planning Modules*
