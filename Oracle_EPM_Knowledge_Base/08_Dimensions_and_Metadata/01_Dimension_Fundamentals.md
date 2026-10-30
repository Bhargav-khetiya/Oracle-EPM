# Dimension Fundamentals

> **Prerequisites:** [What Is EPM](../00_Foundation/01_What_Is_EPM.md), [EPM Architecture](../00_Foundation/02_EPM_Architecture.md)  
> **Evidence Labels:** `[Oracle Documented]` = confirmed in official docs · `[Illustrative]` = example for learning · `[Recommendation]` = consultant best practice

---

## What Is a Dimension?

A **dimension** is a structural axis used to organize and analyze data in an Essbase multidimensional cube. Think of it as one category of analysis — "what are we measuring?" (Account), "where?" (Entity), "when?" (Period/Year), "which scenario?" (Scenario).

```
Imagine a spreadsheet:
  Rows     = Account dimension   (Revenue, COGS, Salaries…)
  Columns  = Period dimension    (Jan, Feb, Mar…)
  Sheets   = Entity dimension    (US, UK, India…)
  Workbooks = Scenario dimension (Budget, Actual, Forecast…)

Essbase supports 10–25+ dimensions simultaneously —
something impossible in flat spreadsheets.
```

Every data cell in the cube sits at the intersection of one member from each dimension. You cannot leave any dimension unspecified — this is why "No" members (like "No Department") exist for custom dimensions.

`[Oracle Documented]`

---

## Standard vs Custom Dimensions

### Standard Dimensions (System-Created)

These are created automatically when you build an EPM Cloud Planning application. You **cannot** delete them.

| Dimension | Purpose | Always Present? |
|-----------|---------|----------------|
| **Account** | Financial line items (Revenue, Expense, Assets…) | ✅ Yes (except Free Form) |
| **Entity** | Organizational units (companies, departments, cost centers) | ✅ Yes (except Free Form) |
| **Period** | Intra-year time granularity (Jan, Q1, YearTotal…) | ✅ Yes |
| **Year** | Multi-year timeline (FY24, FY25, FY26…) | ✅ Yes |
| **Scenario** | Business context (Actual, Budget, Forecast) | ✅ Yes (except Free Form) |
| **Version** | Workflow stages (Working, Final, Target) | ✅ Yes (except Free Form) |
| **Currency** | Reporting currencies (USD, INR, GBP) | Only if multi-currency enabled |

`[Oracle Documented]`

### Custom Dimensions (User-Created)

Administrators create these to model additional business categories:

| Example | Purpose |
|---------|---------|
| **Department** | Catering, Front Office, Finance, HR |
| **Product** | Room types, F&B categories, event types |
| **Channel** | Direct booking, OTA, corporate |
| **Project** | CapEx projects, IT initiatives |
| **Driver** | Units, rate, occupancy %, price |

### Dimension Limits

| Application Type | Max Custom Dimensions |
|------------------|-----------------------|
| Standard (PBCS) | Up to 7 custom dimensions |
| Enterprise (EPBCS) | Module-dependent (3–5 additional) |
| Free Form | Up to 20 total dimensions |

`[Oracle Documented]`

---

## Dimension Terminology

```
Account (Dimension)
  │
  ├── Total P&L (Root / Generation 1)
  │   │
  │   ├── Revenue (Parent / Generation 2 / Level 2)
  │   │   │
  │   │   ├── 100110: Rooms Revenue (Leaf / Level 0 / Generation 3)
  │   │   ├── 100120: Banquet Revenue (Leaf / Level 0 / Generation 3)
  │   │   └── 100130: F&B Revenue (Leaf / Level 0 / Generation 3)
  │   │
  │   └── Expense (Parent / Generation 2 / Level 2)
  │       ├── 200000: Salaries (Leaf / Level 0)
  │       └── 200010: Benefits (Leaf / Level 0)
  │
  └── KPIs (Parent, separate branch)
      ├── Gross Margin % (Leaf with formula)
      └── RevPAR (Leaf with formula)
```

| Term | Definition |
|------|-----------|
| **Root** | Top-most member of the dimension |
| **Parent** | Any member that has children |
| **Child** | Any member directly under a parent |
| **Sibling** | Members sharing the same immediate parent |
| **Leaf (Level 0)** | Bottom member with no children — data entry happens here |
| **Ancestor** | Any member above in the hierarchy chain |
| **Descendant** | Any member below in the hierarchy chain |
| **Generation** | Distance from root counting downward (root = Gen 1) |
| **Level** | Distance from leaf counting upward (leaf = Level 0) |

---

## Dense vs Sparse Dimensions

Every dimension in a BSO cube is classified as either **Dense** or **Sparse**. This is the most important performance decision in cube design.

```
DENSE DIMENSIONS: Define the INTERNAL structure of each data block
  → Account (always Dense)
  → Period (always Dense)
  → Small dimensions with high data population

SPARSE DIMENSIONS: Define the INDEX of which blocks exist
  → Entity (always Sparse)
  → Scenario, Version, Year
  → Custom dimensions (Department, Product, etc.)

Physical layout:
  ┌─────────────────────────────────────────┐
  │  SPARSE INDEX (.IND file) — B-Tree      │
  │  Points to which blocks actually exist  │
  │  [US, Budget, Working, FY26] → Block 1  │
  │  [UK, Budget, Working, FY26] → Block 2  │
  └─────────────┬───────────────────────────┘
                │
                ▼
  ┌─────────────────────────────────────────┐
  │  DATA BLOCKS (.PAG files)               │
  │  Each block = Dense dim1 × Dense dim2   │
  │  Block 1: [Account × Period] = 8 bytes  │
  │  per cell intersection                  │
  └─────────────────────────────────────────┘
```

**Why it matters:** If you accidentally make a large custom dimension Dense, the block size explodes. If you make Account Sparse, the index becomes enormous. The general rule:

- **Dense:** Dimensions with few members and high data population (Account, Period)
- **Sparse:** Dimensions with many members or low data population (Entity, custom dims)

`[Oracle Documented]` — See also [Essbase Architecture](../07_Essbase_Architecture/01_Essbase_Overview.md)

---

## Dimension Ordering and Performance

The order dimensions appear in the Essbase outline affects query and calculation performance:

```
Outline Order Best Practice (top to bottom):

  Dense Dimensions First:
    1. Account (always first Dense)
    2. Period
    3. Any small Dense custom dimensions

  Then Sparse Dimensions:
    4. Entity (largest variation)
    5. Year
    6. Scenario
    7. Version
    8. Custom dimensions (Sparse)
```

> [!TIP]
> Within the sparse dimensions, placing the dimension with the **most** members first generally improves query performance because Essbase's B-tree index is organized by outline order.

`[Recommendation]`

---

## The Two Architectural Layers

Every member exists simultaneously in two systems:

```
┌──────────────────────────────────────┬───────────────────────────────────────┐
│  PLANNING RELATIONAL REPOSITORY      │  ESSBASE ENGINE                       │
│  (Oracle RDBMS Schema)               │  (MOLAP Physical Kernel)              │
├──────────────────────────────────────┼───────────────────────────────────────┤
│ Tables: HSP_OBJECT, HSP_MEMBER,      │ Outline: binary .OTL file             │
│ HSP_ACCOUNT, HSP_ALIAS               │ Data: .PAG files (8-byte cells)       │
│                                      │ Index: .IND B-tree for sparse combos  │
│ Validates constraints, uniqueness,   │                                       │
│ security. Stores forms, task lists,  │ Executes intra-block and cross-block  │
│ workflow states, audit logs.         │ calculations.                         │
│                                      │                                       │
│ Manages metadata sync and generates  │                                       │
│ Essbase outline updates.             │                                       │
└──────────────────────────────────────┴───────────────────────────────────────┘
```

When an admin edits a member in the Dimension Editor and clicks **Save**, Planning updates the relational tables. When an **Application Refresh (Cube Refresh)** is executed, Planning compiles these definitions into the binary Essbase outline file.

`[Oracle Documented]`

---

## Quick Recall

1. **What is the difference between a dimension and a member?**
   → A dimension is a category of analysis (e.g., Account); a member is a specific item within that category (e.g., Revenue).

2. **Why can't you leave a dimension blank when entering data?**
   → Every cell requires an intersection of exactly one member from every dimension. The "No" members serve as neutral placeholders.

3. **What happens if you make a large custom dimension Dense?**
   → Block size explodes because Dense dimensions define the internal structure of every block, dramatically increasing memory and disk usage.

---

**Next:** [Universal Member Properties](02_Universal_Member_Properties.md) — the properties every member carries regardless of dimension type

