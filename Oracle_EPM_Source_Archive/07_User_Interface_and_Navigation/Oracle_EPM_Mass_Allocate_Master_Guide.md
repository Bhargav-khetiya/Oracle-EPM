# Oracle EPM: The Ultimate Deep-Dive Guide to Mass Allocate (Data Forms)

---

## Table of Contents
1. [Introduction: What is Mass Allocate?](#1-introduction-what-is-mass-allocate)
2. [Why is Mass Allocate Needed?](#2-why-is-mass-allocate-needed)
3. [Mass Allocate vs Grid Spread — The Fundamental Difference](#3-mass-allocate-vs-grid-spread--the-fundamental-difference)
4. [How to Enable Mass Allocate (Administrator Setup)](#4-how-to-enable-mass-allocate-administrator-setup)
5. [How Mass Allocate Works Internally — Architecture Deep Dive](#5-how-mass-allocate-works-internally--architecture-deep-dive)
6. [Spreading Patterns Explained](#6-spreading-patterns-explained)
7. [Relational Spread — The Unique Mass Allocate Feature](#7-relational-spread--the-unique-mass-allocate-feature)
8. [Custom Spread Patterns](#8-custom-spread-patterns)
9. [Step-by-Step: Using Mass Allocate (Web and Smart View)](#9-step-by-step-using-mass-allocate-web-and-smart-view)
10. [Mass Allocate and Member Storage Properties — The Critical Rules](#10-mass-allocate-and-member-storage-properties--the-critical-rules)
11. [Mass Allocate and Dynamic Calc Members](#11-mass-allocate-and-dynamic-calc-members)
12. [Mass Allocate and Shared Members](#12-mass-allocate-and-shared-members)
13. [Mass Allocate and Label-Only Members](#13-mass-allocate-and-label-only-members)
14. [Mass Allocate and Member Formulas](#14-mass-allocate-and-member-formulas)
15. [Mass Allocate and Supporting Detail](#15-mass-allocate-and-supporting-detail)
16. [Mass Allocate and Security — The Bypass Behavior](#16-mass-allocate-and-security--the-bypass-behavior)
17. [Mass Allocate and Cell-Level Security (CLS)](#17-mass-allocate-and-cell-level-security-cls)
18. [Mass Allocate and Valid Intersections](#18-mass-allocate-and-valid-intersections)
19. [Mass Allocate Across BSO, ASO, and Hybrid Mode](#19-mass-allocate-across-bso-aso-and-hybrid-mode)
20. [Time Balance Property Impact on Mass Allocate](#20-time-balance-property-impact-on-mass-allocate)
21. [Data Block Creation and Performance Impact](#21-data-block-creation-and-performance-impact)
22. [Mass Allocate and Spread Patterns (Migration Artifact)](#22-mass-allocate-and-spread-patterns-migration-artifact)
23. [Dashboard 2.0 and Mass Allocate](#23-dashboard-20-and-mass-allocate)
24. [Complete Scenarios Where Mass Allocate Will NOT Work](#24-complete-scenarios-where-mass-allocate-will-not-work)
25. [Complete Scenarios Where Mass Allocate WILL Work](#25-complete-scenarios-where-mass-allocate-will-work)
26. [Practical Examples with Numbers](#26-practical-examples-with-numbers)
27. [Mass Allocate vs Grid Spread vs Default Spreading vs Calc Manager Allocations](#27-mass-allocate-vs-grid-spread-vs-default-spreading-vs-calc-manager-allocations)
28. [Troubleshooting Guide](#28-troubleshooting-guide)
29. [Quick Reference Cheat Sheet](#29-quick-reference-cheat-sheet)

---

## 1. Introduction: What is Mass Allocate?

**Mass Allocate** is a powerful server-side data distribution feature in Oracle Cloud EPM (Planning, FreeForm, and related business processes) that takes a value from a **parent/summary/total cell** on a data form and distributes it directly to **all descendants in the database** — including children and intersections that are **NOT visible on the current form grid**.

### The Core Concept
Think of it this way: A CFO enters `$50,000,000` as the company-wide revenue target at "Total Company." Mass Allocate pushes this down to all 200 cost centers, 12 months, and 50 product lines — **even though only a handful are visible on the form** — writing the results directly to Essbase in a single operation.

### Key Characteristics
| Characteristic | Details |
|:---|:---|
| **Feature Type** | Server-side data distribution tool (writes directly to database) |
| **Where it lives** | Data Forms (Web + Smart View) |
| **Who controls it** | Service Administrator enables it; only users with the **Mass Allocate role** can execute it |
| **Scope** | Distributes to **ALL descendants**, including those NOT on the grid |
| **Security** | **Bypasses form-level security** — writes directly to Essbase |
| **Reversibility** | ❌ **CANNOT be undone** — once executed, data is committed to the database |
| **Requires special role** | ✅ Yes — `Mass Allocate` application role must be provisioned |

### The #1 Differentiator from Grid Spread
> *Grid Spread only affects cells VISIBLE on the form. Mass Allocate affects ALL descendants in the database, visible or not.*

---

## 2. Why is Mass Allocate Needed?

### The Business Problem Grid Spread Cannot Solve

Grid Spread is powerful, but it has a fundamental limitation: it can only distribute data to cells that are **physically displayed on the current form grid**. In real-world enterprise planning:

*   A company has **200+ cost centers** — no form displays all of them.
*   An organization has **50+ product lines** across **12 months** — forms show aggregated views.
*   A corporate budget target of $50M needs to cascade to **thousands of base-level intersections** that span multiple dimensions.

### What Mass Allocate Solves

| Without Mass Allocate | With Mass Allocate |
|:---|:---|
| User must open multiple forms to cover all target members | User enters ONE value on ONE form — system distributes everywhere |
| Grid Spread skips hidden members | Mass Allocate reaches ALL descendants in the database |
| Must build complex Business Rules for multi-dimensional distributions | Interactive UI — no coding required |
| Limited to visible grid scope | Reaches across entire dimensional hierarchies |
| Respects form security (can't write to restricted cells) | Bypasses form security — writes directly to Essbase |

### Common Business Scenarios
1. **Corporate Top-Down Budgeting** — CFO sets $50M revenue target at "Total Company"; Mass Allocate pushes to all entities, departments, and products across all months.
2. **Macro-Level Forecast Adjustment** — VP increases Q3 forecast by 8% across all regions, including regions not displayed on the current form.
3. **Overhead Cost Distribution** — Distribute $2M IT costs across 150 departments based on prior-year headcount ratios (using Relational Spread).
4. **Annual Target Setting** — Set annual targets that cascade to all level-0 members across every dimension, regardless of form layout.
5. **One-Time Bulk Correction** — Correct a systematic error across thousands of intersections by replacing values with a corrected figure.

---

## 3. Mass Allocate vs Grid Spread — The Fundamental Difference

This is the most important distinction to understand. These two features look similar but behave **fundamentally differently** at the architectural level.

### Side-by-Side Comparison

| Aspect | Grid Spread | Mass Allocate |
|:---|:---|:---|
| **Execution location** | Client-side (browser/Excel) | **Server-side (Essbase)** |
| **Writes to database when?** | Only after user clicks Save | **Immediately on execution** |
| **Target scope** | ONLY visible cells on the grid | **ALL descendants in the database** |
| **Target cells must be on the form?** | ✅ Yes — mandatory | ❌ No — distributes to hidden members |
| **Respects form security?** | ✅ Yes — skips read-only cells | ❌ **No — bypasses form security** |
| **Can be undone?** | ✅ Yes — before saving | ❌ **No — irreversible once executed** |
| **Requires special role?** | ❌ No — standard user access | ✅ **Yes — Mass Allocate role required** |
| **Intermediate generations required on form?** | ✅ Yes — all levels must be visible | ❌ No — writes directly to level-0 |
| **Spread patterns** | Proportional, Even, Fill | Proportional, Even, Fill + **Relational Spread** |
| **Custom Spread Patterns** | ✅ Supported | ✅ Supported |
| **Performance impact** | Minimal (client-side math) | ⚠️ **Can be heavy** (creates data blocks in Essbase) |
| **Risk level** | Low (can undo) | ⚠️ **HIGH (cannot undo, bypasses security)** |

### When to Choose Mass Allocate Over Grid Spread

| Scenario | Use Grid Spread | Use Mass Allocate |
|:---|:---:|:---:|
| Adjusting visible monthly values | ✅ | |
| Distributing to 200+ cost centers (most hidden) | | ✅ |
| Quick what-if analysis (try before saving) | ✅ | |
| Permanent top-down target cascading | | ✅ |
| Writing to cells you can't see on the form | | ✅ |
| Need to preserve audit trail before committing | ✅ | |
| User lacks Mass Allocate role | ✅ | |

---

## 4. How to Enable Mass Allocate (Administrator Setup)

Mass Allocate requires **TWO** prerequisites — both must be in place:

### Prerequisite 1: Provision the Mass Allocate Role

**Navigation:** `Access Control → Application Roles` (or Identity Domain / Native Directory)

1. Log in as an EPM Administrator.
2. Navigate to **Access Control** (or **Tools → Access Control**).
3. Locate the target user.
4. Assign the **Mass Allocate** application-level role (`Application - Mass Allocate`).
5. Save changes.

> **⚠️ Important:** Without this role, the Mass Allocate option will be **greyed out** or completely hidden, even if the form property is enabled. This is by design — Mass Allocate is a powerful and potentially dangerous tool.

### Prerequisite 2: Enable Mass Allocate on the Form

**Navigation:** `Home → Navigator → Create and Manage → Forms`

1. Open the **Form Manager** and locate your target form.
2. Click **Actions → Edit** (or create a new form).
3. Navigate to the **Layout** tab.
4. Click **Display Properties** (on the right-side panel or under "Other Options").
5. **Check** the box labeled **"Enable Mass Allocate"**.
6. Click **Save** or **Finish**.

### Important Related Settings

| Setting | Location | Effect |
|:---|:---|:---|
| **Enable Mass Allocate** | Form → Layout → Display Properties | Turns on Mass Allocate for that specific form |
| **Disable Spreading** | Form → Layout → Smart View Options | If checked, **blocks ALL spreading** in Smart View (including Mass Allocate, Grid Spread, and default spreading) |
| **Mass Allocate Role** | Access Control → User Roles | User must have this role provisioned to see the option |
| **Make Form Read-Only** | Form → Layout → Display Properties | If checked, the source cell is read-only — cannot initiate Mass Allocate |

### The Three-Layer Gate System

```
┌─────────────────────────────────────────────────────────┐
│  GATE 1: Does the user have the Mass Allocate ROLE?     │
│  ✅ Yes → Proceed                                       │
│  ❌ No  → Option is greyed out / hidden                 │
├─────────────────────────────────────────────────────────┤
│  GATE 2: Is "Enable Mass Allocate" checked on the FORM?│
│  ✅ Yes → Proceed                                       │
│  ❌ No  → Option is not available on this form          │
├─────────────────────────────────────────────────────────┤
│  GATE 3: Is "Disable Spreading" UNCHECKED in SV Options?│
│  ✅ Yes → Proceed (Smart View)                          │
│  ❌ No  → Blocked in Smart View                         │
└─────────────────────────────────────────────────────────┘
```

> **⚠️ Critical Trap:** If **"Disable Spreading"** is checked under Smart View Options, it **overrides** everything — Mass Allocate will NOT be available in Smart View, even if the role is provisioned and the form property is enabled.

---

## 5. How Mass Allocate Works Internally — Architecture Deep Dive

### The Data Flow (What Happens Under the Hood)

```
┌─────────────────────────────────────────────────────────────┐
│  USER ACTION                                                │
│  1. User selects a parent/summary cell on the grid          │
│  2. User chooses Adjust → Mass Allocate (Web/Smart View)    │
│  3. User enters value/percentage and selects pattern        │
│  4. User clicks "Spread"                                    │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  PLANNING SERVER PROCESSING (Server-Side)                   │
│                                                             │
│  Step A: CONTEXT RESOLUTION & BOUNDARY MAPPING              │
│    • Capture the exact multidimensional intersection         │
│      of the selected cell (Entity, Account, Period, etc.)   │
│    • Query dimension hierarchy metadata to find ALL          │
│      descendants of the selected member across ALL dims     │
│    • Compute the full target boundary space — potentially   │
│      hundreds or thousands of intersections                 │
│                                                             │
│  Step B: CALCULATE DISTRIBUTION                             │
│    • Apply the selected spread pattern:                     │
│      - Proportional: Use existing target cell values        │
│      - Evenly: Divide equally across all descendants        │
│      - Fill: Place same value in all descendants            │
│      - Relational: Use values from a DIFFERENT source       │
│                     location as the distribution weights     │
│                                                             │
│  Step C: DATABASE INJECTION (Essbase)                       │
│    • Write directly to Essbase data blocks                  │
│    • If target blocks don't exist → CREATE new blocks       │
│    • Bypass form-level security entirely                    │
│    • Write values to level-0 (leaf) intersections           │
│    • DATA IS COMMITTED IMMEDIATELY — NO UNDO               │
│                                                             │
│  Step D: BLOCK MANAGEMENT                                   │
│    • Mark parent blocks as "dirty" for recalculation        │
│    • Trigger internal rollups or prepare for next calc pass │
│    • Update index files if new blocks were created          │
│                                                             │
│  Step E: FORM REFRESH                                       │
│    • Refresh the form/grid to display updated values        │
│    • Dynamic Calc parents recalculate on retrieval          │
└─────────────────────────────────────────────────────────────┘
```

### Critical Architectural Differences from Grid Spread

| Architectural Aspect | Grid Spread | Mass Allocate |
|:---|:---|:---|
| **Processing location** | Browser (Web) or Excel (Smart View) | Planning Server → Essbase |
| **Database write timing** | Deferred (user must Save) | **Immediate** (on click of Spread) |
| **Target discovery** | Scans visible grid cells only | Queries dimensional metadata for ALL descendants |
| **Data block handling** | N/A (writes through form layer) | May **create new data blocks** in Essbase |
| **Security enforcement** | Full form-level security check | **Bypasses form security** — uses system context |
| **Transaction atomicity** | Can be rolled back (Refresh/Undo) | **Atomic commit — no rollback** |

---

## 6. Spreading Patterns Explained

Mass Allocate offers **four** spreading patterns — the three standard patterns (same as Grid Spread) plus the unique **Relational Spread**:

### 6.1 Proportional Spread (Default)

**Logic:** Distributes the value proportionally based on the **existing values** in the target descendants.

**Formula:**
```
New Cell Value = Existing Cell Value × (New Total / Existing Total)
```

**Key Difference from Grid Spread:** In Mass Allocate, "existing values" includes ALL descendants in the database — not just visible cells on the form.

### 6.2 Evenly Split

**Logic:** Divides the value equally across ALL target descendants (level-0 members).

**Formula:**
```
New Cell Value = Total Value / Count of ALL Level-0 Descendants
```

**Key Difference:** The count includes descendants NOT on the form. If "Total Entity" has 200 level-0 entities, the value is divided by 200 — even if only 10 are visible on the form.

### 6.3 Fill

**Logic:** Places the **exact entered value** into EVERY target descendant cell.

**Formula:**
```
New Cell Value = Spread Value (identical for all descendants)
```

**⚠️ Extreme Caution:** Fill across Mass Allocate can write the same value into **thousands** of cells. For example, filling $100,000 into "Total Company" across 200 entities × 12 months = writing $100,000 into 2,400 cells. This creates a parent total of $240,000,000 (200 × 12 × $100K) if the account is Flow type.

### 6.4 Relational Spread (Unique to Mass Allocate) ⭐

**Logic:** Distributes data into target cells using values from a **completely different source location** as the distribution weights.

This is the feature that makes Mass Allocate uniquely powerful — see [Section 7](#7-relational-spread--the-unique-mass-allocate-feature) for the complete deep dive.

### Pattern Comparison Matrix

| Aspect | Proportional | Evenly Split | Fill | Relational |
|:---|:---|:---|:---|:---|
| **Uses existing target data?** | ✅ Yes | ❌ No | ❌ No | ❌ No (uses separate source) |
| **Uses external reference data?** | ❌ No | ❌ No | ❌ No | ✅ Yes |
| **Available in Grid Spread?** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ **No — Mass Allocate only** |
| **Result at parent** | Equals entered total | Equals entered total | SUM of fills | Equals entered total |
| **Best for** | Seasonal adjustments | New items, flat distributions | Fixed recurring costs | Historical-driver budgeting |

---

## 7. Relational Spread — The Unique Mass Allocate Feature

### What is Relational Spread?

Relational Spread is a spreading pattern **exclusive to Mass Allocate** that distributes data using values from a **completely different cross-dimensional location** as the weighting basis.

### Why is it Needed?

**Scenario:** You want to spread the FY2026 Budget total across departments using FY2025 Actuals as the distribution pattern.

With Proportional Spread, the system uses the **existing FY2026 Budget values** as weights — but what if FY2026 Budget is empty or has incorrect preliminary values?

With Relational Spread, you tell the system: *"Use FY2025 Actuals as the weight pattern to distribute the FY2026 Budget target."*

### How Relational Spread Works — Step by Step

```
┌─────────────────────────────────────────────────────────────┐
│  RELATIONAL SPREAD PROCESS                                  │
│                                                             │
│  1. USER CONTEXT (Current Relation):                        │
│     Scenario = Budget                                       │
│     Year = FY2026                                           │
│     Entity = Total Company                                  │
│     Account = Revenue                                       │
│     Value: $10,000,000                                      │
│                                                             │
│  2. SOURCE RELATION (Choose Relation):                      │
│     Scenario = Actual    ← User maps to Actual              │
│     Year = FY2025        ← User maps to prior year          │
│     Entity = Total Company (same)                           │
│     Account = Revenue (same)                                │
│                                                             │
│  3. SYSTEM EVALUATES SOURCE RELATION:                       │
│     Looks at FY2025 Actual Revenue by Entity:               │
│     • East Region:  $4,000,000 (40%)                        │
│     • West Region:  $3,000,000 (30%)                        │
│     • Central:      $2,000,000 (20%)                        │
│     • South:        $1,000,000 (10%)                        │
│     Total:          $10,000,000                             │
│                                                             │
│  4. APPLY PERCENTAGES TO TARGET:                            │
│     FY2026 Budget Revenue:                                  │
│     • East Region:  $10M × 40% = $4,000,000                │
│     • West Region:  $10M × 30% = $3,000,000                │
│     • Central:      $10M × 20% = $2,000,000                │
│     • South:        $10M × 10% = $1,000,000                │
│                                                             │
│  5. WRITTEN DIRECTLY TO ESSBASE                             │
└─────────────────────────────────────────────────────────────┘
```

### The "Choose Relation" Dialog

When you select Relational Spread, the Mass Allocate dialog presents a mapping table with two columns:

| Dimension | Current Relation (Your Cursor) | Choose Relation (Source Driver) |
|:---|:---|:---|
| Scenario | Budget | **Actual** ← You change this |
| Year | FY2026 | **FY2025** ← You change this |
| Entity | Total Company | Total Company (keep same) |
| Account | Revenue | Revenue (keep same) |
| Version | Working | Working (keep same) |

You can **remap any dimension** to a different member, creating a cross-dimensional driver.

### Real-World Examples of Relational Spread

| Scenario | Current Relation | Source Relation | Effect |
|:---|:---|:---|:---|
| Budget FY2026 based on FY2025 Actuals | Scenario=Budget, Year=FY2026 | Scenario=Actual, Year=FY2025 | Distributes using last year's actual pattern |
| New product forecast based on similar product | Account=New Product Rev | Account=Existing Product Rev | Uses existing product's pattern for new product |
| Department allocation based on headcount | Account=Overhead Costs | Account=Headcount | Uses headcount numbers as weights |
| Plan based on seasonality from prior forecast | Scenario=Plan, Version=v2 | Scenario=Forecast, Version=v1 | Uses prior forecast pattern |

---

## 8. Custom Spread Patterns

### What is a Custom Spread Pattern?

Beyond the four built-in patterns, Oracle EPM allows administrators to define **Custom Spread Patterns** — weighted distribution templates with specific ratios for each target member.

### Availability in Mass Allocate

Custom Spread Patterns appear in the **Spread Pattern dropdown** within the Mass Allocate dialog, just as they do in Grid Spread. When selected, the custom weights override the standard proportional/even/fill logic.

### Example Custom Pattern (Seasonal Weighting)

| Month | Weight | Distribution |
|:---|---:|:---|
| Jan | 6 | `(6/100) × Total` |
| Feb | 6 | `(6/100) × Total` |
| Mar | 8 | `(8/100) × Total` |
| Apr | 8 | `(8/100) × Total` |
| May | 9 | `(9/100) × Total` |
| Jun | 10 | `(10/100) × Total` |
| Jul | 11 | `(11/100) × Total` |
| Aug | 11 | `(11/100) × Total` |
| Sep | 9 | `(9/100) × Total` |
| Oct | 8 | `(8/100) × Total` |
| Nov | 7 | `(7/100) × Total` |
| Dec | 7 | `(7/100) × Total` |
| **Total** | **100** | |

### Mass Allocate Advantage with Custom Patterns

Unlike Grid Spread (which requires all target months to be visible on the form), Mass Allocate can apply custom patterns across **all 12 months even if only "YearTotal" is displayed on the form**.

---

## 9. Step-by-Step: Using Mass Allocate (Web and Smart View)

### 9.1 Using Mass Allocate in the Web Interface

1. **Open the Data Form** that has Mass Allocate enabled.
2. **Click on a parent/summary cell** whose value you want to distribute.
3. Click **Edit** (or **Data** / **Adjust**) in the form toolbar.
4. Select **Mass Allocate** from the dropdown menu.
5. In the Mass Allocate dialog:
   *   **Spread Type:** Choose `Value` or `Percentage`.
   *   **Adjustment:** Choose `Increase by`, `Decrease by`, or enter a target value directly.
   *   **Spread Pattern:** Choose `Proportional Spread`, `Evenly Split`, `Fill`, `Relational Spread`, or a custom pattern.
   *   **Spread Value:** Enter the numeric amount or percentage.
   *   **Choose Relation** (if Relational Spread): Map dimensions to the source driver location.
6. Click **Spread**.
7. **⚠️ Data is IMMEDIATELY committed to the database. There is NO undo.**
8. The form refreshes to display updated values.

### 9.2 Using Mass Allocate in Smart View (Excel)

1. **Open the form** in Smart View for Office (Excel).
2. **Click on a parent/summary cell** in the worksheet.
3. Go to the **Planning ribbon** (or the Smart View provider ribbon).
4. Click **Adjust → Mass Allocate**.
5. Fill in the Mass Allocate dialog (same options as Web).
6. Click **Spread**.
7. **⚠️ Data is IMMEDIATELY committed to the database. There is NO undo.**

### 9.3 Adjustment Types

| Adjustment Type | What It Does | Example |
|:---|:---|:---|
| **Increase by Value** | Adds a flat amount to the parent total, then distributes the new total to ALL descendants | Parent = $1M → Increase by $200K → $1.2M distributed to all descendants |
| **Decrease by Value** | Subtracts a flat amount, then distributes | Parent = $1M → Decrease by $100K → $900K distributed |
| **Increase by Percentage** | Increases the parent total by a percentage, then distributes | Parent = $1M → Increase by 15% → $1.15M distributed |
| **Decrease by Percentage** | Decreases by a percentage, then distributes | Parent = $1M → Decrease by 10% → $900K distributed |
| **Spread Value (Direct Entry)** | Replaces the parent total entirely, then distributes | Enter $2M → $2M distributed to all descendants |

---

## 10. Mass Allocate and Member Storage Properties — The Critical Rules

### The Fundamental Rule

Mass Allocate writes data **directly to Essbase**. It targets **level-0 (leaf) Store members** — the base cells where data physically resides.

### 10.1 Store Members ✅

| Property | Mass Allocate Behavior |
|:---|:---|
| **Data Storage** | Store |
| **Can be a SOURCE cell?** | ✅ Yes |
| **Can be a TARGET cell?** | ✅ Yes — Mass Allocate writes data directly to Store members |

This is the standard, expected behavior. Mass Allocate's ultimate target is always level-0 Store members.

### 10.2 Dynamic Calc Members ❌ (as targets)

| Property | Mass Allocate Behavior |
|:---|:---|
| **Data Storage** | Dynamic Calc |
| **Can be a SOURCE cell?** | ✅ Yes — Mass Allocate reads the dynamic value and uses it as the starting point |
| **Can be a TARGET cell?** | ❌ **No** — Dynamic Calc members don't store data; Mass Allocate skips them and writes to their Store-type level-0 descendants |

**The Flow:** When you select a Dynamic Calc parent and run Mass Allocate, the system reads its dynamically calculated value, then **traverses down the hierarchy** until it finds Store-type level-0 members. Data is written ONLY to those level-0 members.

### 10.3 Dynamic Calc and Store Members ⚠️

| Property | Mass Allocate Behavior |
|:---|:---|
| **Data Storage** | Dynamic Calc and Store |
| **Can be a TARGET cell?** | ⚠️ **Risky** — Mass Allocate may write to the stored portion, but the member formula overwrites the stored value on the next calculation or retrieval |

**Verdict:** Avoid targeting "Dynamic Calc and Store" members. The write may succeed, but the formula recalculates and overwrites the value, making the allocation appear to "vanish."

### 10.4 Summary Table

| Data Storage Property | Can be SOURCE? | Can be TARGET? | Notes |
|:---|:---:|:---:|:---|
| **Store** | ✅ | ✅ | The ideal and intended target |
| **Dynamic Calc** | ✅ | ❌ | Skipped — system writes to Store descendants |
| **Dynamic Calc and Store** | ✅ | ⚠️ Risky | Write succeeds but formula overwrites |
| **Never Share** | ✅ | ✅ | Works like Store |
| **Label Only** | ❌ | ❌ | No data storage — see Section 13 |
| **Shared Member** | ⚠️ | ⚠️ | See Section 12 |

---

## 11. Mass Allocate and Dynamic Calc Members

### Spreading FROM a Dynamic Calc Parent

This is the **standard use case**. You select a Dynamic Calc parent (e.g., "Total Entity" which aggregates all entities dynamically) and run Mass Allocate. The system:

1. **Reads** the dynamically calculated total (e.g., $10,000,000).
2. **Traverses** the hierarchy to find ALL level-0 Store descendants.
3. **Distributes** the new value/adjustment across those level-0 members.
4. **Writes** directly to Essbase.

```
Total Entity (Dynamic Calc)  ← User selects this, enters $12M
  ├── North America (Dynamic Calc)
  │     ├── US_East (Store)         ← ✅ Mass Allocate writes here
  │     ├── US_West (Store)         ← ✅ Mass Allocate writes here
  │     └── Canada (Store)          ← ✅ Mass Allocate writes here
  ├── Europe (Dynamic Calc)
  │     ├── UK (Store)              ← ✅ Mass Allocate writes here
  │     ├── Germany (Store)         ← ✅ Mass Allocate writes here
  │     └── France (Store)          ← ✅ Mass Allocate writes here
  └── Asia (Dynamic Calc)
        ├── Japan (Store)           ← ✅ Mass Allocate writes here
        └── China (Store)           ← ✅ Mass Allocate writes here
```

### What if ALL Descendants are Dynamic Calc?

If there are **no Store-type level-0 members** in the entire descendant tree, Mass Allocate has **no valid target cells**. The operation will fail or produce no results.

---

## 12. Mass Allocate and Shared Members

### The Rules

| Rule | Details |
|:---|:---|
| **Can you Mass Allocate TO a shared member?** | ⚠️ **Conditional** — Not recommended. Writing to a shared hierarchy's branch can cause unpredictable behavior |
| **Where does the data go?** | If the write succeeds, data is written to the **base (primary) member** |
| **Best Practice** | Always perform Mass Allocate from the **primary (non-shared) hierarchy** — never from alternate/shared hierarchies |

### Why Shared Members are Risky for Mass Allocate

1. **Data fragmentation** — Shared members point to base members in a different hierarchy. Mass Allocate traversing a shared branch may not correctly resolve the base member's write path.
2. **Security conflicts** — The shared hierarchy may have different security assignments than the primary hierarchy, causing unexpected skips or failures.
3. **Block resolution** — Essbase data blocks are stored based on the primary hierarchy's sparse intersection. Shared branches may not align with the block structure, causing write failures.

### Example

```
Primary Hierarchy (✅ Use for Mass Allocate):
  Total Products
    ├── Electronics (Store)
    ├── Furniture (Store)
    └── Clothing (Store)

Alternate Hierarchy (⚠️ Avoid for Mass Allocate):
  By Region View
    ├── Domestic Products
    │     ├── Electronics (Shared → Primary.Electronics)
    │     └── Clothing (Shared → Primary.Clothing)
    └── International Products
          └── Furniture (Shared → Primary.Furniture)
```

**Best Practice:** Always Mass Allocate from "Total Products" in the primary hierarchy — not from "By Region View."

---

## 13. Mass Allocate and Label-Only Members

### The Rule: Absolute Prohibition ❌

| Aspect | Details |
|:---|:---|
| **Can Mass Allocate source from a Label-Only member?** | ❌ **No** — Label-Only members hold no data to distribute |
| **Can Mass Allocate write to a Label-Only member?** | ❌ **No** — Label-Only members have no data storage |
| **Why?** | Label-Only members are structural placeholders with zero data intersections in the cube |

### What Happens If You Try?

The system treats the cell as **invalid for data input**. The Mass Allocate dialog will either:
*   Not appear (the cell is not recognized as a valid source).
*   Show an error indicating no data exists at the selected intersection.

### The Implied Share Trap

Label-Only parents create an **implied share** with their first child. If a user sees a value displayed on a Label-Only parent (which is actually the first child's value), they might attempt to Mass Allocate from it. This will fail because the parent itself has no data block.

**Fix:** Change the parent member to **Dynamic Calc** instead of Label Only if users need to spread from it.

---

## 14. Mass Allocate and Member Formulas

### How Member Formulas Interact with Mass Allocate

| Scenario | Behavior |
|:---|:---|
| **Target cell is Dynamic Calc with a member formula** | ❌ **Skipped** — Mass Allocate writes to its Store-type level-0 descendants instead |
| **Target cell is "Dynamic Calc and Store" with a formula** | ⚠️ Write may succeed, but formula overwrites on next retrieval — effectively useless |
| **Source cell has a member formula (Dynamic Calc)** | ✅ Fine — Mass Allocate reads the formula-calculated value as the starting total |
| **Level-0 Store member with NO formula** | ✅ This is the intended target — Mass Allocate writes here successfully |

### Example

```
Account Hierarchy:
  Revenue (Store, level-0)            ← ✅ Mass Allocate writes here
  COGS (Store, level-0)               ← ✅ Mass Allocate writes here
  Gross Margin (Dynamic Calc)         ← ❌ Formula: "Revenue" - "COGS" — SKIPPED
    └── GM% (Dynamic Calc)            ← ❌ Formula: "Gross Margin" / "Revenue" — SKIPPED
  Operating Expenses (Store, level-0) ← ✅ Mass Allocate writes here
  Net Income (Dynamic Calc)           ← ❌ Formula: "Gross Margin" - "OpEx" — SKIPPED
```

Mass Allocate distributes only to Revenue, COGS, and Operating Expenses. Gross Margin, GM%, and Net Income recalculate automatically from their formulas after the allocation.

---

## 15. Mass Allocate and Supporting Detail

### The Conflict

**Supporting Detail** provides line-item breakdowns within a data cell (e.g., breaking a $50K expense into $20K software, $15K hardware, $15K consulting). It is stored in a relational table, not directly in Essbase.

### Mass Allocate Behavior

| Aspect | Details |
|:---|:---|
| **Does Mass Allocate overwrite Supporting Detail values?** | ⚠️ **Yes, partially** — Mass Allocate writes the new value directly to the Essbase cell, but the Supporting Detail structure (stored relationally) remains disconnected |
| **What happens to the Supporting Detail?** | The Supporting Detail entries still exist in the relational database, but their sum no longer matches the Essbase cell value. This creates a **data discrepancy** |
| **Does Mass Allocate skip Supporting Detail cells?** | Unlike Grid Spread (which skips them), Mass Allocate writes directly to Essbase and **does NOT check for Supporting Detail** |

### Best Practice

**Clear Supporting Detail** from target cells BEFORE running Mass Allocate. After allocation, recreate Supporting Detail if needed. Otherwise, the cell value and Supporting Detail will be out of sync.

---

## 16. Mass Allocate and Security — The Bypass Behavior

### The Critical Security Architecture Difference

This is one of the most important and most dangerous aspects of Mass Allocate.

```
┌─────────────────────────────────────────────────────────────┐
│  GRID SPREAD SECURITY:                                      │
│  • Checks form-level security for EVERY target cell         │
│  • Skips cells where user lacks write access                │
│  • Respects data access grants and restrictions              │
│  • User sees exactly what was changed                       │
├─────────────────────────────────────────────────────────────┤
│  MASS ALLOCATE SECURITY:                                    │
│  • Checks ONLY that the user has the Mass Allocate ROLE     │
│  • Checks ONLY that the user has write access to SOURCE cell│
│  • Writes to ALL descendants via system-level context        │
│  • BYPASSES form-level security on target cells             │
│  • Can write to cells the user CANNOT normally see or edit   │
└─────────────────────────────────────────────────────────────┘
```

### What This Means in Practice

| Scenario | Grid Spread | Mass Allocate |
|:---|:---|:---|
| User can write to East Region but NOT West Region | ✅ Only spreads to East | ⚠️ **Writes to BOTH East and West** |
| Cost Center 5 is read-only for this user | ✅ Skips Cost Center 5 | ⚠️ **Writes to Cost Center 5 anyway** |
| User doesn't have access to "Confidential" entity | ✅ Skips Confidential | ⚠️ **Writes to Confidential** |

### Why This Design Exists

Mass Allocate is designed for **administrative-level data operations** where a small number of trusted users need to push top-down targets across the entire organization. Requiring granular write access to every single level-0 intersection would make the feature useless for its intended purpose.

### Governance Best Practice

| Practice | Details |
|:---|:---|
| **Limit role assignment** | Grant the Mass Allocate role to **very few** trusted users (Finance Directors, FP&A leads) |
| **Document usage** | Require users to document when and why they run Mass Allocate |
| **Post-allocation review** | Run data validation reports after Mass Allocate to verify results |
| **Use locked versions** | Lock versions/scenarios that should not be modified via Mass Allocate |

---

## 17. Mass Allocate and Cell-Level Security (CLS)

### How CLS Interacts with Mass Allocate

Cell-Level Security (CLS) acts as an **exception layer** that overrides standard dimension security with granular intersection-level rules.

| CLS Rule | Mass Allocate Behavior |
|:---|:---|
| **Deny Write** on a target intersection | ⚠️ The allocation engine encounters a security violation for those specific cells — **may skip or fail** depending on the scope |
| **Deny Read** on a target intersection | ⚠️ The cell resolves to `#NoAccess` — Mass Allocate **may fail or skip** these cells |
| **No CLS restrictions** | ✅ Mass Allocate writes normally |

### Key Point

While Mass Allocate bypasses **form-level** security, Cell-Level Security (CLS) operates at the **database engine level** and is **harder to bypass**. CLS rules may block Mass Allocate from writing to specific intersections, causing:
*   **Partial distribution** — Some target cells receive data, others are skipped.
*   **Skewed totals** — The distributed amounts don't sum to the expected total because blocked cells absorbed nothing.
*   **Silent failures** — No error message, but data didn't write to CLS-protected cells.

---

## 18. Mass Allocate and Valid Intersections

### How Valid Intersections Impact Mass Allocate

Valid Intersection rules define which combinations of dimension members are **valid (allowed)** for data entry.

| Behavior | Details |
|:---|:---|
| **Invalid target intersections** | Mass Allocate evaluates target intersections against active Valid Intersection rules. **Invalid intersections are automatically skipped** |
| **Read-only enforcement** | Cells that violate valid intersections are rendered read-only — the allocation engine distributes ONLY among remaining valid target cells |
| **Discrepancies in totals** | Because invalid cells are skipped, the sum of distributed child cells may NOT match the parent's source value |

### Example

Valid Intersection Rule: `Entity = "US Operations"` can ONLY have `Currency = "USD"`.

If Mass Allocate tries to distribute data to `Entity = "US Operations"` × `Currency = "EUR"`, this intersection is invalid. The system **skips** it, distributing data only to the valid `Currency = "USD"` intersection.

### The Silent Math Problem

**Scenario:** Mass Allocate distributes $1,000,000 across 10 entities. 2 entities are blocked by Valid Intersections.

| Without Valid Intersections | With Valid Intersections |
|:---|:---|
| $100K each × 10 entities = $1,000,000 ✅ | $125K each × 8 valid entities = $1,000,000 ✅ |
| All 10 entities receive data | 2 entities receive NOTHING — users may not realize this |

---

## 19. Mass Allocate Across BSO, ASO, and Hybrid Mode

### 19.1 Traditional BSO (Block Storage Option) ✅

| Aspect | Behavior |
|:---|:---|
| **Mass Allocate supported?** | ✅ Fully supported — this is the native environment |
| **Data write target** | Level-0 stored data blocks |
| **Block creation** | Essbase **creates new data blocks** if they don't exist for target intersections |
| **After execution** | Parent blocks marked dirty; may need manual or automatic aggregation |

### 19.2 Pure ASO (Aggregate Storage Option) ❌

| Aspect | Behavior |
|:---|:---|
| **Mass Allocate supported?** | ❌ **Not natively supported** on ASO-backed forms |
| **Why?** | ASO cubes are designed for read-only aggregation and reporting. Direct user data input (including Mass Allocate) is not supported on ASO forms |
| **Workaround** | Perform Mass Allocate on the **BSO input cube**, then use **Smart Push** or **DataMaps** to push results to the ASO reporting cube |

### 19.3 Hybrid BSO Mode ✅

| Aspect | Behavior |
|:---|:---|
| **Mass Allocate supported?** | ✅ **Fully supported** — operates on the BSO write-back layer |
| **Advantage** | Dynamic sparse aggregation means parents update instantly after write-back |
| **After execution** | Parent aggregates update automatically via Calc-on-the-Fly |

### Comparison Table

| Feature | Pure ASO | Traditional BSO | Hybrid BSO |
|:---|:---|:---|:---|
| **Mass Allocate supported?** | ❌ No | ✅ Yes | ✅ Yes |
| **Block creation?** | N/A | ✅ Creates new blocks | ✅ Creates new blocks |
| **Post-execution rollup** | N/A | Manual calc needed | Automatic (Calc-on-the-Fly) |
| **Performance** | N/A | Depends on block density | Optimized |

---

## 20. Time Balance Property Impact on Mass Allocate

The Account dimension's **Time Balance** property affects how Mass Allocate results aggregate at parent time levels — identical to Grid Spread behavior.

### Impact by Time Balance Type

| Time Balance | Aggregation Logic | Mass Allocate Impact |
|:---|:---|:---|
| **Flow** (default) | Parent = Sum of children | Standard — parent shows sum of distributed values |
| **First** | Parent = First child's value | After Fill allocation, YearTotal shows only Jan's value |
| **Last** | Parent = Last child's value | After Fill allocation, YearTotal shows only Dec's value |
| **Average** | Parent = Average of children | After Fill allocation, YearTotal shows the average |

### The Fill Trap (Same as Grid Spread)

**Example:** Fill $50,000 into every month for "Headcount" account (Time Balance = Last):

| Month | Value |
|:---|---:|
| Jan through Dec | 50,000 each |
| **YearTotal** | **50,000** ← NOT $600,000! |

**With Mass Allocate, this is even more dangerous** because it writes to ALL descendants (including months not visible on the form), and users may not see the downstream impact until they open a different form.

---

## 21. Data Block Creation and Performance Impact

### Why This Section Matters

Mass Allocate writes directly to Essbase. If target data blocks **don't exist** (because no data was previously loaded or entered for those intersections), Essbase must **create new blocks** on the fly. This has significant performance implications.

### Understanding Essbase Data Blocks

| Concept | Details |
|:---|:---|
| **What is a data block?** | Every unique combination of stored sparse dimension members forms a data block. Each block contains all dense dimension members |
| **Missing Block Rule** | Essbase does NOT create empty blocks — if no data exists at an intersection, no block exists |
| **The Catch** | Mass Allocate may try to write to intersections where no block exists — forcing Essbase to create them |

### Performance Impact Scenarios

| Scenario | Blocks Created | Performance Impact |
|:---|:---|:---|
| Mass Allocate to 10 entities × 1 year | ~10 new blocks | ✅ Minimal — fast |
| Mass Allocate to 50 entities × 3 scenarios | ~150 new blocks | ⚠️ Moderate — noticeable delay |
| Mass Allocate to 200 entities × 5 products × 3 versions | ~3,000 new blocks | ❌ **Heavy** — may take minutes |
| Mass Allocate to "Total Company" across ALL dimensions | Potentially **millions** of blocks | ❌ **Extremely heavy** — can crash the system |

### The "Cube Explosion" Problem

**What it is:** Mass Allocate at a very high summary level (e.g., "Total Company") can force Essbase to create data blocks for every possible sparse combination — even combinations that should never have data. This is called "cube explosion" or "block bloat."

**Symptoms:**
*   Database size suddenly grows by 10×–100×.
*   Query performance degrades dramatically.
*   Backup times increase significantly.
*   Memory consumption spikes on the Essbase server.

### Best Practices to Avoid Performance Issues

| Best Practice | Details |
|:---|:---|
| **Scope the allocation** | Mass Allocate from the lowest possible parent level — not "Total Company" |
| **Use Proportional Spread** | Proportional Spread only writes to existing blocks (where data already exists). It doesn't create new blocks for empty intersections |
| **Avoid Fill on high-level parents** | Fill creates data at EVERY level-0 intersection, potentially creating thousands of new blocks |
| **Run during off-peak hours** | Large Mass Allocate operations consume significant server resources |
| **Monitor database size** | Check Essbase database size before and after Mass Allocate operations |
| **Consider Calc Manager instead** | For very large allocations, a targeted Calc Manager Business Rule with scoped `FIX` statements is more efficient |

---

## 22. Mass Allocate and Spread Patterns (Migration Artifact)

### Spread Patterns as Artifacts

Spread Patterns are classified as **Application-level artifacts** in Oracle EPM Cloud:

| Artifact Property | Value |
|:---|:---|
| **Category** | Application Artifacts |
| **Name** | Spread Patterns |
| **Description** | A custom spreading pattern that determines how data is distributed from a parent to its children |
| **Available From** | **Mass Allocate** and Grid Spread menus |
| **Editable (Import)** | Yes: XML |
| **Dependencies** | None |

### Migration Considerations
*   Spread Patterns are exported/imported as **XML** files.
*   They have **no dependencies** on other artifacts.
*   When migrating between environments, always include Spread Patterns in the migration snapshot if your forms use custom patterns for Mass Allocate.
*   Spread Patterns are shared between Mass Allocate and Grid Spread — the same pattern appears in both dialogs.

---

## 23. Dashboard 2.0 and Mass Allocate

### The Limitation (Same as Grid Spread)

When a form is embedded as a **grid component inside a Dashboard 2.0**, Mass Allocate is **NOT directly available** on the dashboard component.

### The Workaround

1. Hover over the grid component in the dashboard.
2. Click the **Actions** icon (⋮ or gear icon).
3. Select **"Open Form"**.
4. The underlying form opens in a **new dynamic tab**.
5. Use Mass Allocate normally in the opened form.

> **📖 Reference:** The Oracle documentation states: *"The Maximize option only enlarges the dashboard component. If the dashboard component is a grid and you want to perform grid actions on the component such as Adjust, Grid Spread, Comment, and so on, select Open Form (in the Actions menu) to open the underlying form associated with the component."*

---

## 24. Complete Scenarios Where Mass Allocate Will NOT Work

### 24.1 Access-Level Failures (Option Not Available)

| # | Scenario | Why It Fails | Fix |
|:---:|:---|:---|:---|
| 1 | **User does NOT have the Mass Allocate role** | Role not provisioned — option is greyed out | Admin must assign Mass Allocate role in Access Control |
| 2 | **"Enable Mass Allocate" is NOT checked** on the form | Feature disabled at form level | Admin must enable it in Form → Layout → Display Properties |
| 3 | **"Disable Spreading" IS checked** under Smart View Options | Overrides all spreading in Smart View | Admin must uncheck "Disable Spreading" |
| 4 | **Form is set to Read-Only** | Entire form is read-only — cannot initiate | Uncheck "Make form read-only" |
| 5 | **Dashboard 2.0 component** | Not available directly on dashboard grids | Use Actions → Open Form |

### 24.2 Source-Level Failures (Cannot Initiate Mass Allocate)

| # | Scenario | Why It Fails | Fix |
|:---:|:---|:---|:---|
| 6 | **Source cell is Label Only** | No data stored — nothing to distribute | Change member to Dynamic Calc |
| 7 | **Source cell is a level-0 member with no children** | No descendants to distribute TO | Select a parent/summary cell |
| 8 | **Source cell is on an ASO-backed form** | ASO doesn't support direct data write operations | Use BSO input cube form |
| 9 | **Source cell has #NoAccess (CLS Deny Read)** | User cannot read the value — cannot use as source | Adjust CLS rules |

### 24.3 Target-Level Failures (Data Not Written to Specific Targets)

| # | Scenario | Why It Fails | Fix |
|:---:|:---|:---|:---|
| 10 | **ALL descendants are Dynamic Calc** | No Store-type level-0 members exist to receive writes | Add Store-type level-0 members |
| 11 | **Target intersection violates Valid Intersections** | Invalid intersection — skipped | Adjust Valid Intersection rules or accept the skip |
| 12 | **Target intersection blocked by Cell-Level Security (Deny Write)** | CLS prevents writes at the database level | Adjust CLS rules |
| 13 | **Target intersection blocked by Cell-Level Security (Deny Read)** | Cell resolves to #NoAccess | Adjust CLS rules |
| 14 | **Shared member branch** with incorrect block resolution | Data blocks don't align with shared hierarchy | Use primary hierarchy instead |
| 15 | **Label-Only descendants** | No data storage at Label-Only members | Change to Dynamic Calc or Store |
| 16 | **Dynamic Calc and Store targets** | Write succeeds but formula overwrites on refresh | Change to pure Store for input members |
| 17 | **Target blocks don't exist + Proportional Spread** | Proportional Spread uses existing values as weights; if target blocks don't exist (all #MISSING), all weights are zero | Use Evenly Split or Fill to seed initial data, or use Relational Spread |
| 18 | **Locked Version/Scenario** | Version or scenario is locked for input | Unlock before allocating |

### 24.4 Performance Failures

| # | Scenario | Why It Fails | Fix |
|:---:|:---|:---|:---|
| 19 | **Mass Allocate on extremely high-level parent** (e.g., "Total Company" across all dimensions) | Creates millions of data blocks — system runs out of memory | Scope allocation to lower-level parents |
| 20 | **Fill pattern on dense hierarchy** | Writes identical values to every intersection — massive block creation | Use Proportional or Evenly Split instead |

---

## 25. Complete Scenarios Where Mass Allocate WILL Work

| # | Scenario | Behavior |
|:---:|:---|:---|
| 1 | **Dynamic Calc parent → Store level-0 descendants** | ✅ The standard use case — works perfectly |
| 2 | **Store parent → Store children** | ✅ Works — parent value is overwritten |
| 3 | **Descendants NOT visible on the form** | ✅ **This is the primary advantage** — Mass Allocate reaches hidden members |
| 4 | **Proportional Spread on cells with existing data** | ✅ Preserves relative distribution across ALL descendants |
| 5 | **Evenly Split across all level-0 members** | ✅ Divides equally — creates blocks if needed |
| 6 | **Fill (use with caution)** | ✅ Writes same value to every target — creates blocks |
| 7 | **Relational Spread (cross-dimensional driver)** | ✅ Uses external source as weight pattern |
| 8 | **Custom Spread Pattern** | ✅ Uses administrator-defined weights |
| 9 | **Increase/Decrease by Value** | ✅ Adjusts total then distributes |
| 10 | **Increase/Decrease by Percentage** | ✅ Calculates new total then distributes |
| 11 | **Hybrid BSO cube** | ✅ Optimized with Calc-on-the-Fly |
| 12 | **Traditional BSO cube** | ✅ Standard — may create blocks |
| 13 | **Target cells where user normally lacks form write access** | ✅ **Mass Allocate bypasses form security** |
| 14 | **Smart View (Excel) — Adjust → Mass Allocate** | ✅ Works (if "Disable Spreading" is unchecked and role is provisioned) |
| 15 | **Never Share members** | ✅ Treated like Store members |

---

## 26. Practical Examples with Numbers

### Example 1: Proportional Mass Allocate — Distributing to Hidden Entities

**Scenario:** The form shows only "Total Company" and 3 regions. But each region has 5 entities (15 total). The CFO wants to increase total revenue by $1.5M (from $10M to $11.5M), distributed proportionally.

**Form View (only 3 rows visible):**
| Entity | Revenue |
|:---|---:|
| North America | $4,000,000 |
| Europe | $3,000,000 |
| Asia | $3,000,000 |
| **Total Company** | **$10,000,000** |

**Database View (15 level-0 entities — most hidden):**
| Entity | Existing Revenue | % of Total | New Revenue ($11.5M) |
|:---|---:|---:|---:|
| US_East | $1,600,000 | 16% | $1,840,000 |
| US_West | $1,200,000 | 12% | $1,380,000 |
| US_Central | $800,000 | 8% | $920,000 |
| Canada | $300,000 | 3% | $345,000 |
| Mexico | $100,000 | 1% | $115,000 |
| UK | $1,200,000 | 12% | $1,380,000 |
| Germany | $900,000 | 9% | $1,035,000 |
| France | $500,000 | 5% | $575,000 |
| Spain | $250,000 | 2.5% | $287,500 |
| Italy | $150,000 | 1.5% | $172,500 |
| Japan | $1,200,000 | 12% | $1,380,000 |
| China | $800,000 | 8% | $920,000 |
| India | $600,000 | 6% | $690,000 |
| Korea | $250,000 | 2.5% | $287,500 |
| Australia | $150,000 | 1.5% | $172,500 |
| **Total** | **$10,000,000** | **100%** | **$11,500,000** ✅ |

**Key Point:** The user only saw 3 rows on the form, but Mass Allocate distributed across all 15 level-0 entities in the database.

---

### Example 2: Relational Spread — Budget Based on Prior-Year Actuals

**Scenario:** Set FY2026 Budget for "IT Costs" = $1,200,000, distributed across departments using FY2025 Actual headcount as the driver.

**Relational Mapping:**
| Dimension | Current (Target) | Source (Driver) |
|:---|:---|:---|
| Scenario | Budget | **Actual** |
| Year | FY2026 | **FY2025** |
| Account | IT Costs | **Headcount** |
| Entity | Total Company | Total Company |

**FY2025 Actual Headcount by Department (Source Driver):**
| Department | Headcount | % of Total |
|:---|---:|---:|
| Engineering | 120 | 40% |
| Sales | 90 | 30% |
| Marketing | 45 | 15% |
| Finance | 30 | 10% |
| HR | 15 | 5% |
| **Total** | **300** | **100%** |

**Mass Allocate Result — FY2026 Budget IT Costs:**
| Department | Allocation |
|:---|---:|
| Engineering | $1,200,000 × 40% = **$480,000** |
| Sales | $1,200,000 × 30% = **$360,000** |
| Marketing | $1,200,000 × 15% = **$180,000** |
| Finance | $1,200,000 × 10% = **$120,000** |
| HR | $1,200,000 × 5% = **$60,000** |
| **Total** | **$1,200,000** ✅ |

---

### Example 3: Even Split — New Budget Item

**Scenario:** A new $600,000 "Sustainability Initiative" budget must be distributed equally across 6 regions. None of the regions are visible on the current form.

**Mass Allocate:** Source = $600,000 → Even Split

| Region | Allocation |
|:---|---:|
| North America | $100,000 |
| Europe | $100,000 |
| Asia | $100,000 |
| Latin America | $100,000 |
| Middle East | $100,000 |
| Africa | $100,000 |
| **Total** | **$600,000** ✅ |

---

### Example 4: Mass Allocate Failure — Proportional with No Existing Data

**Scenario:** User selects "New Product Line" total ($500,000) and tries Proportional Spread. But ALL level-0 descendants have #MISSING — no historical data exists.

**Result:** All weights are zero (0/0 = undefined). The system either:
*   Produces all #MISSING values (nothing distributed), OR
*   Degenerates to an even split (implementation-dependent).

**Fix:** Use **Evenly Split** or **Relational Spread** (pointing to a related product's data as the driver) instead.

---

### Example 5: The Security Bypass — Writing to Restricted Cells

**Scenario:** User has Mass Allocate role but only write access to "US_East." They Mass Allocate $1M across "Total Company."

**Grid Spread behavior:** Would only distribute to US_East (the only writable cell).

**Mass Allocate behavior:** Distributes across **ALL level-0 entities** (US_East, US_West, UK, Germany, etc.) — bypassing the user's normal form-level write restrictions.

**This is why the Mass Allocate role must be tightly controlled.**

---

## 27. Mass Allocate vs Grid Spread vs Default Spreading vs Calc Manager Allocations

### The Complete Comparison

| Feature | Default Spreading | Grid Spread | Mass Allocate | Calc Manager Allocations |
|:---|:---|:---|:---|:---|
| **Primary scope** | Time dimension only | Visible grid cells | ALL descendants (visible + hidden) | Fully customizable (any scope) |
| **Execution** | On data entry (type + Enter) | Edit → Grid Spread | Adjust → Mass Allocate | Run as Business Rule |
| **Writes to DB** | After Save | After Save | **Immediately** | After rule execution |
| **Respects security** | ✅ Yes | ✅ Yes | ❌ **Bypasses form security** | Depends on rule design |
| **Requires role** | No | No | ✅ **Mass Allocate role** | Relevant calc role |
| **Spread patterns** | Time Balance properties | Proportional, Even, Fill | Proportional, Even, Fill, **Relational** | Fully customizable (share, spread, percent, etc.) |
| **Cross-dimensional driver** | ❌ No | ❌ No | ✅ **Yes (Relational Spread)** | ✅ Yes (code-driven) |
| **Reversibility** | Before save | Before save | ❌ **Cannot undo** | Depends on rule design |
| **Performance impact** | Minimal | Minimal | ⚠️ Can create blocks | Depends on rule scope |
| **Code required** | No | No | No | ✅ Yes (calc script/Groovy) |
| **Flexibility** | Low | Medium | Medium-High | ⭐ Maximum |

### Decision Guide

| Need | Recommended Tool |
|:---|:---|
| Distribute annual total to months (visible on form) | Default Spreading or Grid Spread |
| Quick what-if (try before saving) | Grid Spread |
| Distribute to hidden members/descendants | **Mass Allocate** |
| Use prior-year actuals as distribution driver | **Mass Allocate (Relational Spread)** |
| Complex multi-step allocation with offsets and rounding | **Calc Manager Allocation Template** |
| Automated, scheduled, repeatable allocation | **Calc Manager Business Rule** |
| Custom Groovy-driven allocation logic | **Groovy Business Rule** |

---

## 28. Troubleshooting Guide

### Problem → Cause → Solution

| Problem | Likely Cause | Solution |
|:---|:---|:---|
| **Mass Allocate option is greyed out** | User lacks Mass Allocate role | Admin: Provision Mass Allocate role in Access Control |
| **Mass Allocate option not visible on the form** | "Enable Mass Allocate" not checked | Admin: Enable in Form → Layout → Display Properties |
| **Works on Web but not in Smart View** | "Disable Spreading" is checked | Admin: Uncheck "Disable Spreading" in Smart View Options |
| **Mass Allocate runs but values don't change** | All target descendants are Dynamic Calc | Verify target members have Store data storage |
| **Values appear then vanish after refresh** | Targets are "Dynamic Calc and Store" — formula overwrites | Change targets to pure Store |
| **Distribution doesn't add up to expected total** | Some targets skipped by Valid Intersections or CLS | Check Valid Intersection rules and Cell-Level Security |
| **Proportional spread produces all zeros/missing** | All existing target values are #MISSING — no pattern to proportion from | Use Evenly Split, Fill, or Relational Spread |
| **Unexpected large totals after Fill** | Fill × many descendants = huge sum; also check Time Balance | Verify account Time Balance property; consider scope |
| **Database size suddenly exploded** | Mass Allocate created millions of new data blocks (cube explosion) | Run database restructure; scope future allocations tighter |
| **Performance degradation after Mass Allocate** | Too many new blocks created in sparse dimensions | Restructure database; clear unnecessary blocks |
| **Mass Allocate writes to cells user shouldn't access** | By design — Mass Allocate bypasses form security | Restrict Mass Allocate role; use Grid Spread for security-aware spreading |
| **Supporting Detail out of sync after Mass Allocate** | Mass Allocate overwrites Essbase values without clearing Supporting Detail | Clear Supporting Detail before Mass Allocate |
| **Relational Spread produces wrong pattern** | Source relation dimensions are mapped incorrectly | Double-check the "Choose Relation" mappings for each dimension |
| **Mass Allocate doesn't appear in Dashboard 2.0** | Not available on dashboard components | Use Actions → Open Form |
| **Error on Label-Only source cell** | Label-Only members have no data | Change member to Dynamic Calc |

---

## 29. Quick Reference Cheat Sheet

### Mass Allocate at a Glance

```
┌──────────────────────────────────────────────────────────────┐
│                  MASS ALLOCATE CHEAT SHEET                    │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  PREREQUISITES:                                              │
│    1. User has Mass Allocate ROLE (Access Control)           │
│    2. Form has "Enable Mass Allocate" checked                │
│    3. "Disable Spreading" is NOT checked (Smart View)        │
│                                                              │
│  ACCESS:   Web: Edit/Adjust → Mass Allocate                  │
│            Smart View: Adjust → Mass Allocate                │
│                                                              │
│  PATTERNS: Proportional | Evenly Split | Fill |              │
│            ⭐ Relational Spread (unique to Mass Allocate)    │
│            + Custom Spread Patterns                          │
│                                                              │
│  WRITES TO:                                                  │
│    ✅ Store members (level-0 descendants)                    │
│    ✅ Never Share members                                    │
│    ✅ Hidden/invisible descendants (NOT on form)             │
│    ✅ Cells where user lacks form-level write access          │
│    ❌ Dynamic Calc members (skipped → writes to Store kids)  │
│    ❌ Label-Only members                                     │
│    ❌ Invalid Intersection cells (skipped)                   │
│    ❌ CLS Deny Write cells (may skip)                        │
│    ⚠️  Dynamic Calc and Store (writes but formula overwrites)│
│    ⚠️  Supporting Detail (overwrites, causes desync)        │
│                                                              │
│  SCOPE:    ALL descendants in the database                   │
│            (visible + hidden + cross-dimensional)            │
│                                                              │
│  SAVES:    ⚠️ IMMEDIATELY to Essbase — NO UNDO              │
│                                                              │
│  SECURITY: ⚠️ BYPASSES form-level security                  │
│            (Only checks Mass Allocate role + source access)  │
│                                                              │
│  CUBES:                                                      │
│    ✅ BSO (Traditional) — fully supported                    │
│    ✅ Hybrid BSO — supported + optimized                     │
│    ❌ ASO — not natively supported                           │
│                                                              │
│  DASHBOARD: Not available directly on dashboard components   │
│             → Use Actions → Open Form                        │
│                                                              │
│  PERFORMANCE:                                                │
│    ⚠️ Can create new Essbase data blocks                    │
│    ⚠️ Avoid Fill on very high-level parents                 │
│    ⚠️ Scope allocations as tightly as possible              │
│                                                              │
│  ⛔ THE #1 RULE:                                             │
│    MASS ALLOCATE CANNOT BE UNDONE.                            │
│    Verify inputs BEFORE clicking Spread.                     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Decision Tree: Which Spreading Tool to Use?

```
                    ┌─────────────────────────┐
                    │ Need to distribute       │
                    │ data from a parent?       │
                    └───────────┬──────────────┘
                                │
                    ┌───────────▼──────────────┐
                    │ Are ALL target cells      │
                    │ visible on the form?      │
                    └───────────┬──────────────┘
                           ╱         ╲
                         Yes           No
                         ╱               ╲
             ┌──────────▼──────┐   ┌──────▼───────────────┐
             │ Need to undo     │   │ Do you need a cross-  │
             │ before saving?   │   │ dimensional driver?   │
             └───────┬─────────┘   └──────┬───────────────┘
                  ╱     ╲               ╱       ╲
                Yes       No          Yes         No
                ╱           ╲         ╱             ╲
   ┌──────────▼─────┐  ┌───▼────┐ ┌▼──────────┐ ┌──▼──────────┐
   │ Grid Spread     │  │ Either │ │ Mass       │ │ Mass         │
   │ (can undo)      │  │ works  │ │ Allocate   │ │ Allocate     │
   └─────────────────┘  └────────┘ │ (Relational│ │ (Prop/Even/  │
                                   │  Spread)   │ │  Fill)       │
                                   └────────────┘ └──────────────┘
```

### Risk Assessment Matrix

| Spread Tool | Data Risk | Security Risk | Performance Risk | Reversibility |
|:---|:---:|:---:|:---:|:---:|
| **Default Spreading** | 🟢 Low | 🟢 None | 🟢 None | ✅ Before save |
| **Grid Spread** | 🟢 Low | 🟢 None | 🟢 None | ✅ Before save |
| **Mass Allocate** | 🔴 **HIGH** | 🔴 **HIGH** (bypasses security) | 🟡 Medium (block creation) | ❌ **None** |
| **Calc Manager Rules** | 🟡 Medium | 🟢 Low (rule-scoped) | 🟡 Medium | Depends on design |

---

*Document Version: 1.0*
*Last Updated: October 2026*
*Applies to: Oracle Cloud EPM — Planning, FreeForm, Planning Modules*
