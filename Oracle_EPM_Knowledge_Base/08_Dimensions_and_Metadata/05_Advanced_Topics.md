# Advanced Dimensions Topics

> **Prerequisites:** [Account Dimension](03_Account_Dimension.md), [Period/Scenario/Version](04_Period_Scenario_Version.md)  
> **Sources merged:** ChatGPT 06/09/10/11, Claude 05.30 §15-21, Gemini 06/09/10/11  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## HSP System Members and the 17 Metric Types

### The HSP_ Prefix

Members beginning with `HSP_` are **internal system members** generated and maintained by Oracle Planning's kernel. They bind the relational workflow engine (Planning Unit Hierarchies) to Essbase storage blocks.

> [!CAUTION]
> Never rename, delete, add custom children to, or repurpose any `HSP_` member. Doing so corrupts the relational-to-Essbase mapping and can require a full application rebuild.

### The 17 Metric Types

The Metric Type dropdown defines how a system member interacts with workflow, promotions, and dynamic cell-level security:

| # | Metric Type | Purpose |
|:-:|:---|:---|
| 1 | **None** | Standard operational member — no workflow binding |
| 2 | **Data Value** | Financial data submission point (budget dollars) |
| 3 | **Process State** | Workflow status code (0=Under Review, 1=Submitted, 2=Approved) |
| 4 | **Approval Unit PM Member** | Base member bound to approval unit |
| 5 | **Approval Unit Primary Member** | Resolves secondary trees to primary Entity |
| 6 | **Approval Unit Secondary Member** | Tracks secondary dimension coordinates |
| 7 | **Approval Unit Owner** | Current user holding write access |
| 8 | **Approval Unit Previous Owner** | User who promoted/delegated/rejected |
| 9 | **Approval Unit Last Action** | Audit trail: Promote, Reject, Sign Off |
| 10 | **Approval Unit Substate** | Granular workflow condition (e.g., Validation Failed) |
| 11 | **Approval Unit Submission Group** | Enables split submission of entity sections |
| 12 | **Approval Unit Hierarchy** | Binds member to Planning Unit Hierarchy tree |
| 13 | **Entity Process State** | Rollup entity workflow status (all children approved?) |
| 14 | **Approval Unit Total** | Checksum dollar value at promotion time |
| 15 | **Approval Unit Total (Dynamic)** | Dynamic threshold for routing rules |
| 16 | **Approval Unit Last Modified** | Epoch timestamp of last promotion |
| 17 | **Cell Level Security Access** | Toggles read/write based on workflow state |

### Submission Groups in Practice

Traditional budgeting required an entire Entity to be submitted at once. Submission Groups allow partitioned promotion:

```
Entity: E10002
  Group 1: Personnel Costs    → Promoted by HR on Day 5
  Group 2: Operating Expenses → Promoted by Cost Center Manager on Day 10
  Group 3: Capital Outlays    → Promoted by Facilities on Day 15
```

Each group follows independent promotion, rejection, and approval cycles.

`[Oracle Documented]`

---

## Relational Schema Internals (HSP_ Tables)

All dimensions and member properties are stored as normalized relational rows before being compiled into the Essbase outline.

```
METADATA PERSISTENCE FLOW:
  1. Admin saves member in Web UI
     → SQL INSERT/UPDATE into HSP_ tables
  2. Application Refresh (Cube Refresh)
     → Planning queries relational tables via JDBC
     → Constructs multidimensional tree in memory
     → Compiles binary outline (.OTL) via Essbase API
     → Triggers Essbase restructure (.PAG / .IND)
```

### Core HSP_ Tables

| Table | Stores |
|-------|--------|
| **HSP_OBJECT** | Global catalog: unique OBJECT_ID for every dimension, member, form, menu, user |
| **HSP_MEMBER** | Hierarchy: MEMBER_ID → PARENT_ID, DIM_ID, sibling sort position |
| **HSP_ACCOUNT** | Account properties: ACCOUNT_TYPE, TIME_BALANCE, SKIP, VARIANCE_REPORTING |
| **HSP_MEMBER_TO_PLAN_TYPE** | Multi-cube deployment: enablement flags and consolidation operators per cube |
| **HSP_ALIAS** | Display labels mapped to ALIAS_TABLE_ID |
| **HSP_MEMBER_FORMULA** | Calc formulas stored as text strings per cube |
| **HSP_UDA_ASSIGNMENT** | Many-to-many mapping between MEMBER_ID and UDA_ID |

### Data Storage Codes in HSP_MEMBER

| Code | Data Storage |
|:---:|:---|
| 0 | Store |
| 1 | Never Share |
| 2 | Label Only |
| 3 | Shared |
| 4 | Dynamic Calc |

### Account Type Codes in HSP_ACCOUNT

| Code | Account Type |
|:---:|:---|
| 1 | Expense |
| 2 | Revenue |
| 3 | Asset |
| 4 | Liability |
| 5 | Equity |
| 6 | Saved Assumption |

### Why Renaming Never Breaks Forms

```sql
-- Renaming member D10010 to Dept_Catering:
UPDATE HSP_OBJECT 
SET OBJECT_NAME = 'Dept_Catering' 
WHERE OBJECT_ID = 10542;
```

Forms, task lists, and security groups store `OBJECT_ID = 10542` — the internal numeric ID. Since the ID never changes, renaming a member **never breaks** any references.

`[Oracle Documented]`

---

## Implied Sharing

When a parent has exactly **one child**, Essbase automatically creates an implied sharing relationship — both members point to the same physical cell. This saves storage but can cause unexpected behavior.

```
Implied Sharing Scenarios:

Scenario 1: Single child
  Revenue (parent)
    └── Rooms Revenue (only child)
  Result: Revenue and Rooms Revenue share the SAME cell
  Risk: Changing one changes the other; locking conflicts

Scenario 2: One stored child among dynamic siblings
  Total Expense (Dynamic Calc)
    ├── Operating Expense (Dynamic Calc)
    └── Salaries (Store) ← only stored child
  Result: Total Expense and Salaries may share

Prevention: Set the child to "Never Share" data storage
```

`[Oracle Documented]`

---

## Shared Members and Alternate Hierarchies

Shared members allow a single member to appear in **multiple locations** within a dimension without duplicating data:

```
Primary Hierarchy:
  Revenue
    └── Rooms Revenue
        ├── 100110: Standard Room (base member, Store)
        ├── 100120: Deluxe Room (base member, Store)
        └── 100130: Suite (base member, Store)

Alternate Hierarchy (by Geography):
  Revenue by Region
    ├── India Revenue
    │   └── 100110: Standard Room (SHARED — points to base)
    └── US Revenue
        ├── 100120: Deluxe Room (SHARED)
        └── 100130: Suite (SHARED)
```

**Rules for shared members:**
- The **base member** (Store) must appear before any shared references in outline order
- Shared members consume **zero additional storage**
- Editing a shared member edits the base member's data
- Shared members cannot have member formulas — they inherit from the base

`[Oracle Documented]`

---

## Solve Order

When multiple Dynamic Calc members from different dimensions intersect, **Solve Order** determines which formula evaluates first.

### The Problem

```
Account dimension: Variance = Actual - Budget (Dynamic Calc formula)
Scenario dimension: Variance scenario (Dynamic Calc formula)

At intersection [Variance account, Variance scenario]:
  Which formula runs? Account's or Scenario's?
```

### How Solve Order Works

- Range: **0 to 127** (default is 0)
- **Higher Solve Order wins** — it calculates last, overriding earlier results
- Set on the dimension, not on individual members

```
Example:
  Account dimension Solve Order = 0 (lower)
  Scenario dimension Solve Order = 10 (higher)
  
  At the Variance intersection:
  → Account formula runs first (lower solve order)
  → Scenario formula runs last and overrides (higher solve order)
```

> [!IMPORTANT]
> In most Planning applications, you rarely need to change Solve Order unless you have Dynamic Calc members on multiple dimensions that intersect. The default (0) works for single-dimension formulas.

`[Oracle Documented]`

---

## Member Formula Compilation

Member formulas are stored as text in `HSP_MEMBER_FORMULA` and compiled during Cube Refresh:

```
Human-readable formula:
  "Revenue" - "COGS"

After Essbase compilation:
  → Validated against outline member names
  → Converted to internal byte-code references
  → Stored in .OTL binary format
  → Executed in Dynamic Calc Cache at query time
```

### Common Formula Patterns

```essbase
/* Simple subtraction */
"Revenue" - "COGS";

/* Cross-dimensional reference */
"Revenue" -> "Budget" / "Revenue" -> "Actual";

/* Conditional logic */
IF("Revenue" != 0)
  "COGS" / "Revenue" * 100;
ELSE
  #MISSING;
ENDIF;

/* Using @functions */
@PARENTVAL("Account");     /* Parent's value in Account dimension */
@PRIOR("Revenue", 1);     /* Prior period value */
```

`[Oracle Documented]`

---

## Design Patterns

### Pattern 1: Driver-Based Planning

```
Statistical Accounts (Saved Assumption, ~):
  Rooms Available (Store)
  Average Room Rate (Store)
  Occupancy % (Store)

Calculated Revenue (Dynamic Calc):
  Room Revenue = Rooms Available × Occupancy % × Average Room Rate
```

### Pattern 2: Multi-Cube Dimension Strategy

```
FinPlan cube:     Account × Entity × Period × Year × Scenario × Version × Department
Manpower cube:    Account × Entity × Period × Year × Scenario × Version × Employee
Capital cube:     Account × Entity × Period × Year × Scenario × Version × Asset Class

Shared dimensions: Account, Entity, Period, Year, Scenario, Version
Cube-specific:     Department (FinPlan), Employee (Manpower), Asset Class (Capital)
```

### Pattern 3: Alternate Rollup for Matrix Reporting

```
Entity Primary:    By Geography (US → Northeast → NYC)
Entity Alternate:  By Product Line (Hotels → Luxury → NYC [Shared])
Entity Alternate:  By Legal Entity (Corp → US Hotels Inc → NYC [Shared])
```

`[Recommendation]`

---

## Troubleshooting Common Dimension Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Variance shows favorable when it should be unfavorable | Wrong Variance Reporting setting (Expense vs Non-Expense) | Correct the Account Type or Variance Reporting property |
| Q1 shows sum of months for a Balance Sheet account | Time Balance set to Flow instead of Balance | Change Time Balance to Balance |
| Parent and child show identical values unexpectedly | Implied sharing (single child) | Set child to Never Share |
| New member doesn't appear in forms | Member not enabled for the relevant Plan Type | Check Plan Type checkboxes in Dimension Editor |
| Currency values not translating | Exchange Rate Type set to "No Rate" | Set appropriate rate type (Average/Ending/Historical) |
| Two-Pass checkbox is grayed out | Member is not Dynamic Calc, or it's on a Sparse dimension | Verify Data Storage = Dynamic Calc on a Dense dimension |
| Member formula causes #ERROR | Syntax error or reference to non-existent member | Check formula in Calc Manager; verify all referenced members exist in the cube |
| Block explosion after adding members | Too many Sparse dimension combinations | Review custom dimension cardinality; disable members in unused cubes |

---

## Quick Recall

1. **What are HSP_ tables and why should you never modify them directly?**
   → They are internal Planning relational tables that store all metadata. Direct modification bypasses validation and can corrupt the Essbase-to-Planning mapping.

2. **When does implied sharing occur and how do you prevent it?**
   → When a parent has exactly one child. Prevent it by setting the child to Never Share.

3. **Explain Solve Order in one sentence:**
   → "When Dynamic Calc formulas from different dimensions intersect, the formula on the dimension with the higher Solve Order number wins."

---

**See also:**
- [Essbase Architecture](../07_Essbase_Architecture/01_Essbase_Overview.md) — for block storage, index, and calculation details
- [Calc Manager Overview](../05_Calc_Manager_and_Business_Rules/01_Calc_Manager_Overview.md) — for business rules that manipulate dimension members

