# 01 — Universal Member Properties: The Complete Foundation

---

## 1.1 Architectural Overview of Member Properties

Every member created in Oracle EPM Cloud Planning (PBCS, EPBCS) or Hyperion Planning exists simultaneously in two architectural worlds:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              ORACLE EPM CLOUD LAYERS                                   │
├──────────────────────────────────────────┬─────────────────────────────────────────────┤
│      PLANNING RELATIONAL REPOSITORY      │            ESSBASE ENGINE (ESSSVR)          │
│          (Oracle RDBMS Schema)           │            (MOLAP Physical Kernel)          │
├──────────────────────────────────────────┼─────────────────────────────────────────────┤
│ • Tables: HSP_OBJECT, HSP_MEMBER,        │ • Outline: Database schema definition       │
│   HSP_MEMBER_PROPERTIES.                 │   stored in binary `.OTL` file.             │
│ • Validates metadata constraints,        │ • Allocates 8-byte cell offsets for         │
│   uniqueness, and security access.       │   Dense dimensions.                         │
│ • Stores form layouts, task lists,       │ • Builds B-Tree index branches in `.IND`    │
│   workflow states, and audit logs.       │   for Sparse combinations.                  │
│ • Manages metadata synchronization       │ • Executes native intra-block and           │
│   and generates Essbase outline updates. │   cross-block calculation algorithms.       │
└──────────────────────────────────────────┴─────────────────────────────────────────────┘
```

When an administrator edits a member in the Dimension Editor and clicks **Save**, Planning updates the relational metadata tables. When an **Application Refresh (Cube Refresh)** is executed, Planning compiles these definitions into the binary Essbase outline file (`appname.otl`).

---

## 1.2 Identification: Name, Code, Alias, and Alias Tables

| Property | Screen State | Constraints & Technical Specifications |
| :--- | :--- | :--- |
| **Name / Code** | Text field (Max 80 chars) | Must be globally unique across the entire application (unless "Duplicate Member Names" is explicitly enabled). Cannot contain arithmetic operators (`+`, `-`, `*`, `/`), brackets (`[`, `]`, `(`, `)`), quotes (`"`, `'`), commas (`,`), or semicolon (`;`). Cannot match Essbase reserved words (`MISSING`, `ERROR`, `NONE`, `CALC`, `ALL`). |
| **Description** | Text area | Administrative documentation; stored only in the relational database. It is **never compiled into the Essbase `.OTL`** and consumes 0 bytes of Essbase RAM/disk. |
| **Alias Table** | Dropdown (`Default`, `Arabic`, etc.) | Defines the localization or reporting dictionary. EPM allows multiple alias tables (e.g., English, Arabic, Japanese, Regulatory Naming). A member can have exactly one alias per alias table. |
| **Alias** | Text field (Max 80 chars) | The display label presented on forms, Financial Reporting, Smart View, and dashboards. Must be unique within each alias table. |

---

## 1.3 Data Storage Types: Deep Physical Breakdown

The **Data Storage** setting is the single most critical property governing whether a member consumes disk space, exists in the index B-tree, or calculates in RAM on demand.

```
                               DATA STORAGE TYPES
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        ▼                              ▼                              ▼
     [STORE]                    [DYNAMIC CALC]                  [LABEL ONLY]
  • Allocates physical       • ZERO disk footprint           • Header/Organizer only
    8-byte cells in .PAG     • Evaluated in RAM              • No data cells exist
  • Aggregated during          at query time                 • Cannot enter data
    CALC/AGG batches         • Cached in Dynamic Calc Cache  • Children bypass to parent
        │                              │
        ▼                              ▼
  [NEVER SHARE]              [DYNAMIC CALC & STORE]
  • Forces distinct block     • Calculates on query and
    creation; prevents auto     writes back to disk
    single-child sharing      • Deprecated in modern cubes
```

### Physical Comparison Matrix

| Storage Option | Storage Location | In Index (.IND)? | User Data Input? | Essbase Internal Behavior | Best Consultant Use Case |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **`Store`** | `.PAG` disk files | Yes (if Sparse) | Yes (at Level 0) | Values are written to 8-byte cells during data entry, data load, or batch calculations (`CALC ALL`, `AGG`). | Base level input accounts, stored parent summaries. |
| **`Dynamic Calc`** | **0 Bytes on disk** (RAM only) | No | **No** (Calculated) | Computed dynamically when a query requests it using the **Dynamic Calc Cache**. Discarded after query finishes. | Summary rollups with few children, variance accounts, ratios, currency views. |
| **`Dynamic Calc and Store`** | `.PAG` disk files | Yes (if Sparse) | No | Evaluated upon first retrieval and written to disk. Subsequent queries read disk. | **Discouraged**: Causes severe page file fragmentation and cache thrashing. |
| **`Never Share`** | `.PAG` disk files | Yes (if Sparse) | Yes (at Level 0) | Physical stored member, but **explicitly turns off Essbase Auto-Share optimization**. | Single-child parents to prevent block collision and data locking issues. |
| **`Label Only`** | **0 Bytes on disk** | No | **No** | Acts strictly as an outline visual folder. Cannot hold values or formulas. Children rollup directly to **grandparent**. | Organizational headers (e.g., `P&L Summary Header`). |

### The "Never Share" Trap Explained
When an outline contains a parent with exactly **one child**, default Essbase optimization treats the parent as a "Shared Member" of the child to save space (since mathematically Parent = Child).
* In Planning forms and business rules, if parent and child share the same block, entering data at the child or running a rule can trigger lock errors or unexpected formula overwrites.
* Setting **`Never Share`** forces Essbase to generate distinct blocks for both parent and child, isolating their data.

---

## 1.4 Two-Pass Calculation

```
   Without Two-Pass:                  With Two-Pass (Correct):
   Gross Margin % = Sum(Children)    Gross Margin % = Pass 2 Recalculation
   East:   40%                       Total Sales = $2,000,000
   West:   60%                       Total COGS  = $1,200,000
   Total: 100% ❌ (NONSENSICAL!)     Total GM %  = ($2M - $1.2M) / $2M = 40.0% ✅
```

### Why Two-Pass Exists
During a standard BSO cube calculation pass, Essbase aggregates data along dimension hierarchies according to outline order. If a dynamic ratio member (like `Gross Profit % = Gross Profit / Sales`) is calculated during the normal rollup pass, the parent rollup will simply **add up the child percentages** (e.g., 40% + 60% = 100%), yielding absurd mathematical results.

### Two-Pass Mechanics
1. **Pass 1**: Essbase calculates all members, rolling up Base Sales, COGS, and Gross Profit across entities and accounts.
2. **Pass 2**: Essbase executes a secondary pass **only on members tagged with Two-Pass Calculation**, recalculating the ratio using the newly consolidated parent values.

### Technical Restrictions
* **Supported Dimensions**: Supported **only on Dense dimensions** (specifically **Account** and **Time/Period**).
* **Storage Requirement**: The member **must be set to `Dynamic Calc`**.
* **Why Disabled in the UI**: On any member with Data Storage set to `Store`, `Never Share`, or `Label Only`, the Two Pass Calculation checkbox is **grayed out / disabled** because stored members are pre-calculated during batch scripts, not evaluated dynamically.

---

## 1.5 Plan Type Enablement vs. Consolidation Operators

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PLAN TYPE CONFIGURATION                         │
├──────────────────────────────────┬─────────────────────────────────────┤
│      CUBE ENABLEMENT (CHECKBOX)  │    CONSOLIDATION OPERATOR (DROPDOWN)│
├──────────────────────────────────┼─────────────────────────────────────┤
│ Determines whether the member    │ Determines how this member rolls    │
│ is deployed into that cube's     │ up into its immediate parent member │
│ outline (.OTL file).             │ during outline aggregation.         │
└──────────────────────────────────┴─────────────────────────────────────┘
```

### Consolidation Operators Master Reference Table

| Operator Symbol | Name | Mathematical Action | Essbase Internal Behavior | When to Use |
| :---: | :--- | :--- | :--- | :--- |
| **`+`** | **Addition** | $\text{Parent} = \text{Parent} + \text{Child}$ | Positive rollup into parent accumulator. | Standard revenue/expense accounts, normal sub-entities, months into quarters. |
| **`-`** | **Subtraction** | $\text{Parent} = \text{Parent} - \text{Child}$ | Deducts value from parent accumulator. | Returns and allowances, discounts, expense offsets against gross revenue. |
| **`*`** | **Multiplication** | $\text{Parent} = \text{Parent} \times \text{Child}$ | Multiplies value into parent accumulator. | Units $\times$ Price drivers, tax rate multipliers. |
| **`/`** | **Division** | $\text{Parent} = \text{Parent} / \text{Child}$ | Divides parent accumulator by child value. | Weighted unit cost calculations. |
| **`%`** | **Percent** | $\text{Parent} = (\text{Child} / \text{Parent}) \times 100$ | Calculates child as a percentage of parent. | Margin contribution analysis. |
| **`~`** | **Ignore** | $\text{Parent} = \text{Parent} + 0$ | Value exists in the cube and is queryable, but contributes zero to parent rollup. | Statistical accounts (Headcount, Square Footage), memo accounts, KPI drivers. |
| **`^`** | **Never** | **Exempt from Consolidation** | Member is completely bypassed during outline aggregation passes. | Complex formula members calculated exclusively via calc scripts or Groovy rules. |

### Why Available Operators Differ Across Cubes
In production environments:
* **BSO Cubes (`FinPlan`, `Manpower`, `Capital`)**: Show all 7 operators (`+`, `-`, `*`, `/`, `%`, `~`, `^`).
* **ASO Cubes (`EPBCS`)**: Show **only Addition and Ignore**.
  * *Reason*: Aggregate Storage Option (ASO) engines do not support procedural procedural consolidation operators. ASO aggregates dimensions independently using MDX solve order sets.

---

## 1.6 Data Types & Smart Lists

```
Data Type Selected: [ Currency | Non-Currency | Percentage | Date | Text | SmartList ]
                                                                             │
                                              ┌──────────────────────────────┘
                                              ▼
                                 Smart Lists Dropdown:
                              [ Enabled & User-Selectable ]
```

1. **`Unspecified`**: Default generic numeric float.
2. **`Currency`**: Subject to currency conversion rules and exchange rate tables.
3. **`Non-Currency`**: Pure numbers (e.g., Headcount = 15, Units Sold = 400). Bypasses currency conversions.
4. **`Percentage`**: Formatted as percentages (e.g., entered as `0.15`, rendered as `15%`).
5. **`SmartList`**: Text dropdown stored as a numeric ID.
6. **`Date`**: Formatted as calendar date; stored internally as `YYYYMMDD` (e.g., `20261027`).
7. **`Text` / `Transient Text`**: Cell comments and strings managed by Planning relational tables.

### The 8-Byte Smart List Storage Physics
Essbase can **only store 64-bit double-precision floating-point numbers** in its data blocks. It has no native text string engine in BSO cells.
* When a user selects `"Full-Time"` (Entry ID = 1) from a Smart List, Planning converts the string to the number `1.00000000`.
* Essbase stores `1.00000000` inside the `.PAG` block cell.
* When a form is retrieved, Planning matches `1.0` back to the Smart List dictionary and renders the dropdown `"Full-Time"` in the browser.

---

## 1.7 Dynamic Children and Member Creator Access

```
┌─────────────────────────────────────────────────────────────┐
│                 DYNAMIC CHILDREN MECHANICS                  │
├─────────────────────────────────────────────────────────────┤
│ 1. Administrator enables "Enable for Dynamic Children"      │
│ 2. Sets "Number of Possible Dynamic Children" (e.g., 10)    │
│ 3. Essbase pre-reserves 10 placeholder slots in outline:   │
│    • child_placeholder_01, child_placeholder_02...          │
│ 4. Planner clicks "Add New Employee" in form grid           │
│ 5. Planning instantly binds the name to a reserved slot     │
│ 6. Access Granted to Member Creator dictates permissions:   │
│    • Inherit: Takes parent's access rights                  │
│    • Write: Creator can immediately edit data               │
│    • Read: Creator can view only                            │
└─────────────────────────────────────────────────────────────┘
```

* **Purpose**: Allows planners to add new projects, employees, or line items on the fly in forms without waiting for an administrator to run a metadata import and database refresh.
* **Why Disabled in Screen Extractions**: `Number of Possible Dynamic Children` and `Access Granted to Member Creator` are **disabled** until the parent checkbox `Enable for Dynamic Children` is checked.

---

## 1.8 UDAs (User-Defined Attributes) vs. Attribute Dimensions

* **User-Defined Attribute (UDA)**: A lightweight, free-form text string attached to an outline member (e.g., `HSP_NOLINK`, `Hsp_Currency`, `Major_Capex`).
  * Used in calculation scripts: `@ISUDA(Account, "Hsp_Currency")`.
  * Does not create additional dimensions or alter block storage.
* **Attribute Dimensions**: Separate multidimensional structures linked to base dimensions (e.g., `Color`, `Size`, `Package_Type`).
  * Creates dynamic rollup hierarchies and enables cross-dimensional slicing.

---

## 1.9 Member Formulas and Solve Order

* **Member Formula**: Procedural calculation logic attached to a dynamic calc member (e.g., `[Revenue] - [COGS]`).
* **Solve Order (0 to 127)**:
  * In multidimensional cubes with multiple dynamic calc dimensions (e.g., Account formula $\times$ Period variance formula), Solve Order dictates which dimension evaluates first.
  * Higher Solve Order wins and calculates last (overriding earlier formulas).
