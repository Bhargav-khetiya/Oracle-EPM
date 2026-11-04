# Oracle EPM Cloud — Member and Dimension Properties Master Architecture Guide

> **Authoritative Technical Reference**: This guide provides exhaustive, consultant-grade analysis of Oracle EPM Cloud Planning member properties, Essbase block storage impacts, calculation behaviors, and multi-cube design patterns based on verified production UI extractions and official Oracle Enterprise Performance Management documentation.

---

## 1. Executive Overview & Architectural Taxonomy

In Oracle EPM Cloud Planning (including Enterprise Planning PBCS/EPBCS and Hyperion Planning), **Member Properties** define both the **relational metadata semantics** (how the member displays, behaves in forms, participates in workflows, and controls user security) and the **physical Essbase kernel behavior** (how blocks are created, indexed, compressed, aggregated, and stored in `.PAG` files).

### 1.1 The Dual-Repository Architecture

Every property configured in the Planning Web Studio or Dimension Editor is processed across two distinct architectural layers:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 ORACLE EPM CLOUD LAYERS                                │
├──────────────────────────────────────────┬─────────────────────────────────────┤
│      PLANNING RELATIONAL REPOSITORY      │            ESSBASE ENGINE (ESSSVR)          │
│          (Oracle RDBMS Schema)           │            (MOLAP Physical Kernel)          │
├──────────────────────────────────────────┼─────────────────────────────────────┤
│ • Tables: HSP_OBJECT, HSP_MEMBER,        │ • Outline: Database schema definition       │
│   HSP_ACCOUNT, etc.                      │   stored in binary `.OTL` file.             │
│ • Validates metadata constraints,        │ • Allocates 8-byte cell offsets for         │
│   uniqueness, and security access.       │   Dense dimensions.                         │
│ • Stores form layouts, task lists,       │ • Builds B-Tree index branches in `.IND`    │
│   workflow states, and audit logs.       │   for Sparse combinations.                  │
│ • Manages metadata synchronization       │ • Executes native intra-block and           │
│   and generates Essbase outline updates. │   cross-block calculation algorithms.       │
└──────────────────────────────────────────┴─────────────────────────────────────┘
```

When you click **Save** in the Dimension Editor:
1. Planning writes the changes into relational tables (`HSP_MEMBER`, `HSP_MEMBER_PROPERTIES`).
2. An **Application Refresh (Cube Refresh)** or **Restructure** compiles these definitions into the Essbase outline (`appname.otl`).
3. Essbase analyzes whether the change requires a **Dense Restructure** (rewriting all blocks in `.PAG`), a **Sparse Restructure** (updating `.IND`), or an **Outline-Only Restructure**.

---

## 2. Universal Member Properties (All Dimensions)

The following properties exist across almost all standard and custom dimensions in Oracle Planning.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          UNIVERSAL MEMBER PROPERTIES                        │
├──────────────────────┬──────────────────────────────────────────────────────┤
│ Name / Code          │ Unique internal identifier in cube & relational DB    │
│ Description / Alias  │ Human-readable reporting labels across alias tables  │
│ Data Storage         │ Store, Dynamic Calc, Dynamic Calc & Store,           │
│                      │ Never Share, Label Only                              │
│ Two-Pass Calculation │ Secondary calculation pass for ratio accuracy        │
│ Plan Type Settings   │ Multi-cube deployment (FinPlan, EPBCS, etc.)         │
│ Consolidation (+/-)  │ Parent rollup operators (+, -, *, /, %, ~, ^)        │
│ Data Type            │ Currency, Non-Currency, Percentage, SmartList, etc.  │
│ Smart Lists          │ Text-driven dropdowns backed by numeric IDs          │
│ Dynamic Children     │ On-the-fly planner member instantiation              │
│ UDAs                 │ Free-form text attributes for rules and filtering    │
└──────────────────────┴──────────────────────────────────────────────────────┘
```

---

### 2.1 Name, Code, Alias, and Alias Tables

| Property | UI State in Snapshot | Field Constraints & Mechanics |
| :--- | :--- | :--- |
| **Name / Code** | Text field (Max 80 chars) | Must be unique across the entire application (unless Duplicate Member Names is enabled). Cannot contain special characters like `+`, `-`, `*`, `/`, `[`, `]`, `(`, `)`, `,`, `"`, `;`, or tab characters. Cannot match reserved words (`MISSING`, `ERROR`, `NONE`, `CALC`). |
| **Description** | Text area | Administrative documentation; stored only in the relational repository. Does not impact Essbase calculation or storage. |
| **Alias Table** | Dropdown (`Default`, `Arabic`, etc.) | Allows multiple reporting languages or alternate naming conventions. A single member can have one alias per alias table. |
| **Alias** | Text field (Max 80 chars) | The display name presented on forms, Financial Reports, and Smart View sheets. Must be unique within each alias table. |

---

### 2.2 Data Storage Types: Deep Dive

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

#### Detailed Breakdown of Storage Options

| Storage Type | Physical Disk Footprint (.PAG) | Exists in Index (.IND)— | User Data Entry Allowed— | Calculation Mechanics | Best Used When... |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`Store`** | Yes (8 bytes per dense cell) | Yes (if Sparse) | Yes (at Level 0) | Values are permanently written to disk during data entry, data load, or batch aggregation (`CALC ALL`, `AGG`). | Base level input members, stored aggregations, and members requiring historical persistence. |
| **`Dynamic Calc`** | **Zero bytes** on disk | No | **No** (Derived only) | Evaluated dynamically at the moment a user opens a form or runs a Smart View query. Uses the **Dynamic Calc Cache**. | Summary parents with few children, simple member formulas, ratios, variance calculations, and currency conversions. |
| **`Dynamic Calc and Store`** | Yes (Written after calc) | Yes (if Sparse) | No | Calculates upon the first retrieval and saves the result to `.PAG` disk. Subsequent queries read the stored value. | **Largely discouraged** in modern EPM Cloud due to high disk fragmentation and cache synchronization overhead. |
| **`Never Share`** | Yes (8 bytes per dense cell) | Yes (if Sparse) | Yes (at Level 0) | Standard stored member, but **disables Essbase Auto-Share optimization**. | A parent has only one child, but you must prevent Essbase from treating them as the same physical block pointer. |
| **`Label Only`** | **Zero bytes** on disk | No | **No** | Acts strictly as an outline visual folder/header. Cannot hold values or formulas. Children aggregate directly to the **grandparent**. | Organizational headers in outline hierarchies (e.g., `Total Product Lines Header`). |

#### The "Never Share" Trap Explained
When an outline contains a parent with exactly **one child**, Essbase default optimization treats the parent as a "Shared Member" of the child to save space (since mathematically Parent = Child). 

However, in Planning:
* If both Parent and Child share the same block, inputting data at the child or running a business rule can cause block collisions or unexpected security locks.
* Setting `Never Share` forces Essbase to allocate a distinct block for the child and parent, ensuring independent data isolation.

---

### 2.3 Two-Pass Calculation

```
   Without Two-Pass:                  With Two-Pass (Correct):
   Gross Margin % = Sum(Children)    Gross Margin % = Pass 2 Recalculation
   East:   40%                       Total Sales = $2,000,000
   West:   60%                       Total COGS  = $1,200,000
   Total: 100% ❌ (NONSENSICAL!)     Total GM %  = ($2M - $1.2M) / $2M = 40.0% ✅
```

#### Why Two-Pass Exists
During a standard BSO cube calculation pass, Essbase aggregates data along dimension hierarchies according to outline order. If a dynamic ratio member (like `Gross Profit % = Gross Profit / Sales`) is calculated during the normal rollup pass, the parent rollup will simply **add up the child percentages** (e.g., 40% + 60% = 100%), yielding absurd mathematical results.

#### Two-Pass Mechanics
1. **Pass 1**: Essbase calculates all members, rolling up Base Sales, COGS, and Gross Profit across entities and accounts.
2. **Pass 2**: Essbase executes a secondary pass **only on members tagged with Two-Pass Calculation**, recalculating the ratio using the newly consolidated parent values.

#### Restrictions & Dependencies
* **Available Only On**: Dense dimensions (specifically **Account** and **Time/Period**).
* **Storage Requirement**: The member **must be set to `Dynamic Calc`**. (Notice in the extracted screens for `Net Profit`, `D10010`, `USD_Reporting`, where Storage is `Store`, the Two Pass Calculation checkbox is **grayed out / disabled**).

---

### 2.4 Plan Type Enablement vs. Consolidation Operators

In multi-cube applications (such as EPBCS with `FinPlan`, `EPBCS`, `Manpower`, and `Capital`), a member's configuration consists of two distinct components:

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

#### Consolidation Operators Master Reference Table

| Operator Symbol | Name | Mathematical Action | Essbase Internal Behavior | When to Use |
| :---: | :--- | :--- | :--- | :--- |
| **`+`** | **Addition** | $\text{Parent} = \text{Parent} + \text{Child}$ | Standard positive aggregation into parent accumulator. | Standard revenue/expense accounts, normal sub-entities, months into quarters. |
| **`-`** | **Subtraction** | $\text{Parent} = \text{Parent} - \text{Child}$ | Subtracts value from parent accumulator. | Returns and allowances, discounts, expense offsets against gross revenue. |
| **`*`** | **Multiplication** | $\text{Parent} = \text{Parent} \times \text{Child}$ | Multiplies value into parent accumulator. | Units $\times$ Price drivers, tax rate multipliers. |
| **`/`** | **Division** | $\text{Parent} = \text{Parent} / \text{Child}$ | Divides parent accumulator by child value. | Weighted unit cost calculations. |
| **`%`** | **Percent** | $\text{Parent} = (\text{Child} / \text{Parent}) \times 100$ | Calculates child as a percentage of parent. | Margin contribution analysis. |
| **`~`** | **Ignore** | $\text{Parent} = \text{Parent} + 0$ | Value exists in the cube and is queryable, but contributes zero to parent rollup. | Statistical accounts (Headcount, Square Footage), memo accounts, KPI drivers. |
| **`^`** | **Never** | **Exempt from Consolidation** | Member is completely bypassed during outline aggregation passes. | Complex formula members calculated exclusively via calc scripts or Groovy rules. |

#### Why Dropdowns Differ by Cube (The EPBCS UI Fact)
In the supplied screen extractions:
* **`FinPlan`**, **`Manpower`**, and **`Capital`** display **7 operators**: `Addition`, `Subtraction`, `Multiplication`, `Division`, `Percent`, `Ignore`, `Never`.
* **`EPBCS`** displays **only 2 operators**: `Addition` and `Ignore`.

**Reason**: The `EPBCS` plan type is an **Aggregate Storage (ASO)** reporting cube or an out-of-the-box seeded reporting cube. ASO engines natively only support additive or ignored hierarchies; complex mathematical operators (`*`, `/`, `%`) cannot be solved in ASO outline rollups because ASO solves dimensions independently using MDX solve orders rather than sequential procedural consolidation.

---

### 2.5 Data Type & Smart Lists

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

#### Smart List Mechanics: The 8-Byte Trick
Essbase can **only store 64-bit double-precision floating-point numbers** in its data blocks. It has no native text string engine in BSO cells.
* When a user selects `"Full-Time"` (Entry ID = 1) from a Smart List, Planning converts the string to the number `1.00000000`.
* Essbase stores `1.00000000` inside the `.PAG` block cell.
* When a form is retrieved, Planning matches `1.0` back to the Smart List dictionary and renders the dropdown `"Full-Time"` in the browser.

---

### 2.6 Dynamic Children and Member Creator Access

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
* **Why the control was disabled in the extract**: `Number of Possible Dynamic Children` and `Access Granted to Member Creator` are **disabled** until the parent checkbox `Enable for Dynamic Children` is checked.

---

## 3. Account Dimension Deep Dive (`Net Profit` Extraction)

In the extracted screen for `Net Profit`:
* **Account Type**: `Revenue`
* **Variance Reporting**: `Non-Expense`
* **Time Balance**: `Flow`
* **Skip**: `None` (disabled)
* **Exchange Rate Type**: `Average`
* **Source Cube**: `FinPlan`
* **Data Storage**: `Dynamic Calc`
* **Data Type**: `Currency`
* **UDA**: `HSP_NOLINK`, `Hsp_Currency`

---

### 3.1 Account Types

The Account Type dictates the default sign behavior and balance sheet vs. income statement accounting logic:

| Account Type | Normal Balance | Consolidates To Parent As | Financial Reporting Category |
| :--- | :---: | :---: | :--- |
| **`Expense`** | Debit | $+$ (Positive) | Income Statement expense lines |
| **`Revenue`** | Credit | $+$ (Positive) | Income Statement top line revenue |
| **`Asset`** | Debit | $+$ (Positive) | Balance Sheet assets |
| **`Liability`** | Credit | $+$ (Positive) | Balance Sheet liabilities |
| **`Equity`** | Credit | $+$ (Positive) | Balance Sheet owner's equity |
| **`Saved Assumption`** | Neutral | N/A (Often `~` Ignore) | Drivers, tax rates, growth rates, ratios |

---

### 3.2 Variance Reporting: Expense vs. Non-Expense

When computing budget variances in Smart View, Financial Reporting, or variance business rules:

$$\text{Variance for Non-Expense (Revenue)} = \text{Actual} - \text{Budget}$$
$$\text{Variance for Expense} = \text{Budget} - \text{Actual}$$

* If Revenue is budgeted at \$100 and Actual is \$120: $\text{Variance} = 120 - 100 = +\$20$ (**Favorable** / Green).
* If Expense is budgeted at \$100 and Actual is \$120: $\text{Variance} = 100 - 120 = -\$20$ (**Unfavorable** / Red).
* Setting `Net Profit` to **Non-Expense** ensures that higher profit generates positive variance.

---

### 3.3 Time Balance (Flow, Balance, First, Average)

The **Time Balance** property determines how accounts roll up along the **Period / Time dimension** (e.g., from January, February, March into Q1):

```
       TIME BALANCE: FLOW vs. BALANCE vs. FIRST
       
       Period:        Jan     Feb     Mar      Q1 Rollup
       ──────────────────────────────────────────────────
       FLOW (Rev):    100  +  150  +  200  =   450  (Sum of months)
       BALANCE (Cash): 50      75      90  =    90  (Ending month)
       FIRST (Inv):    30      40      45  =    30  (Opening month)
```

| Time Balance Setting | Rollup Value for Q1 (Jan, Feb, Mar) | Accounting Use Case |
| :--- | :--- | :--- |
| **`Flow`** | $\text{Q1} = \text{Jan} + \text{Feb} + \text{Mar}$ | **P&L Accounts** (Revenue, COGS, Travel Expense). Cash flows during the period. |
| **`Balance`** | $\text{Q1} = \text{Mar}$ (Last period with data) | **Ending Balance Sheet Accounts** (Bank Accounts, Accounts Receivable, Inventory). |
| **`First`** | $\text{Q1} = \text{Jan}$ (First period in quarter) | **Beginning Inventory, Opening Capital, Headcount at start of year**. |
| **`Average`** | $\text{Q1} = (\text{Jan} + \text{Feb} + \text{Mar}) / 3$ | **Headcount averages, average daily balances**. |
| **`Fill`** | Propagates parent balance down to empty children | Allocation assumption drivers. |
| **`Weighted Average`** | Weights by exact number of calendar days in month | Daily interest accruals, treasury yields. |

#### The "Skip" Setting & Why It Was Disabled
* **Options**: `None`, `Missing`, `Zeros`, `Missing And Zeros`.
* If a balance account has data in Jan (\$100), Feb (\$120), and Mar is `#MISSING`:
  * `Skip = None`: Q1 evaluates to `#MISSING` (strict).
  * `Skip = Missing`: Q1 skips March and evaluates to **February (\$120)**.
* **Why Disabled in Screen**: `Skip` is applicable **only when Time Balance is set to Balance, First, or Average**. Since `Net Profit` has `Time Balance = Flow`, Skip is mathematically irrelevant and locked to `None`.

---

### 3.4 UDAs: `HSP_NOLINK` and `Hsp_Currency`

* **`Hsp_Currency`**: Flags the member for participation in the Planning currency conversion processor (`Hsp_Rates`).
* **`HSP_NOLINK`**: Prevents Planning from automatically generating a dynamic data integration link between modules (e.g., stops automatic synchronization between Workforce/Capital and Financials for this specific line item).

---

## 4. Period Dimension Deep Dive (`Q1` Extraction)

In the extracted screen for member `Q1`:
* **Start Period**: `Jan`
* **End Period**: `Mar`
* **Data Storage**: `Dynamic Calc`
* **Two Pass Calculation**: `Unchecked` (Enabled)

```
┌────────────────────────────────────────────────────────────────────────┐
│                   PERIOD RANGE BINDING: Q1 (JAN - MAR)                 │
├────────────────────────────────────────────────────────────────────────┤
│ • Start Period = Jan                                                   │
│ • End Period   = Mar                                                   │
│ • Essbase outlines evaluate Q1 exclusively across the months           │
│   spanning January through March.                                      │
│ • Forms with dynamic column expansion restrict Q1 rollups strictly     │
│   within this bounded calendar interval.                               │
│ • Prevents out-of-boundary member rollups when customized fiscal       │
│   calendars (4-4-5, 5-4-4, 13-period) are implemented.                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Scenario Dimension Deep Dive (`Actual` Extraction)

In the extracted screen for `Actual`:
* **Start Yr.**: `FY24`, **Start Period**: `Jan`
* **End Yr.**: `FY40`, **End Period**: `Jul`
* **Include BegBal as Time Period**: `Checked`
* **Enabled for Approvals**: `Checked`
* **Data Storage**: `Never Share`
* **Operators**: `FinPlan = Addition`, `EPBCS = Addition`, `Manpower = Ignore`, `Capital = Ignore`

---

### 5.1 Year and Period Range Binding

```
   [Past / Archived]   [ACTIVE RANGE: FY24 Jan to FY40 Jul]   [Future Closed]
   ◄─── Prior FY23 ────┼─────────────────────────────────────┼──── Post FY40 ──►
     Read-Only / Lock    Open for Data Load & Forms Entry       Data Block Rejection
```

1. **Security & Data Integrity**: Essbase and Planning reject cell inputs and data forms outside the bounded range.
2. **Block Minimization**: Prevents accidental block creation for unneeded years, conserving disk and RAM.

---

### 5.2 Include BegBal as Time Period

* **`BegBal` (Beginning Balance)**: A specialized, non-calendar time period member created by Planning.
* Positioned **before January** in the time dimension.
* Used to store opening balance sheet positions, multi-year asset depreciations, and opening headcounts.
* When checked, forms and calc scripts treat `BegBal` as a valid column in financial statements.

---

### 5.3 Hierarchy Type: Not Set vs. Stored vs. Dynamic

* **`Not Set`**: Default standard behavior; follows the member's individual `Data Storage` property (`Never Share` / `Store`).
* **`Stored`**: Enforces strict stored block aggregation in hybrid/ASO environments.
* **`Dynamic`**: Forces dynamic calculation on the fly across the entire branch.

---

## 6. Version Dimension Deep Dive (`Working` Extraction)

In the extracted screen for `Working`:
* **Type**: `Standard Bottom Up`
* **Enabled for Approvals**: `Checked`
* **Enable Sandboxes**: `Unchecked`
* **Data Storage**: `Never Share`

---

### 6.1 Version Type: Bottom Up vs. Target

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│        STANDARD BOTTOM UP            │           STANDARD TARGET            │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Planners enter data at LEVEL 0     │ • Executives/Managers enter targets  │
│   (Cost Centers, Products, Details). │   at PARENT levels (e.g. Total US).  │
│ • Data aggregates UPWARD into        │ • Data is spread DOWNWARD to child   │
│   parent nodes.                      │   members using allocation rules.    │
│ • Level 0 is Read/Write;             │ • Parent nodes are Read/Write;       │
│   Parents are Read-Only (calculated).│   Level 0 reflects allocated target. │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

#### Numerical Walkthrough
* In **`Standard Bottom Up`**: Planner enters \$100 for Dept A and \$200 for Dept B $\rightarrow$ Total Dept dynamically displays \$300. Planner **cannot type directly into Total Dept**.
* In **`Standard Target`**: VP types \$500,000 directly into Total Dept $\rightarrow$ Planning triggers grid spreading or allocation scripts to distribute \$500,000 across Dept A, B, C.

---

### 6.2 Enable Sandboxes

* When enabled, each planner receives an isolated, private virtual copy of data blocks.
* Allows planners to test "What-If" assumptions (e.g., +10% salary uplift) without altering the shared baseline.
* Data is permanently committed only when the planner clicks **Publish Sandbox**.

---

## 7. Approval & System Dimensions Deep Dive (`HSP_` Members)

In the extracted screens:
* **`HSP_Approval Unit Hierarchy`**: Metric Type = `Approval Unit Hierarchy`
* **`HSP_Approval Unit Submission Group`**: Metric Type = `Approval Unit Submission Group`

The `HSP_` prefix designates **internal system members generated and maintained exclusively by Oracle Planning's kernel**.

> [!WARNING]
> Administrators and consultants must **NEVER** rename, delete, add children to, or repurpose `HSP_` system members. Doing so corrupts the Planning relational repository mapping.

---

### 7.1 The 17 Metric Types Master Reference

The **Metric Type** dropdown controls the internal workflow binding between Planning Approval Units (PUH) and Essbase storage:

| # | Metric Type | Internal Meaning | Real-World Workflow Function |
| :-: | :--- | :--- | :--- |
| **1** | **`None`** | Standard dimensional member | Normal account or entity; no approval tracking attached. |
| **2** | **`Data Value`** | Numeric budget data point | Stores the actual financial submission values. |
| **3** | **`Process State`** | Workflow progression status | Encodes approval status: `0=Under Review`, `1=Submitted`, `2=Approved`. |
| **4** | **`Approval Unit PM Member`** | Primary Member tracking | Identifies the primary entity/cost center bound to the approval unit. |
| **5** | **`Approval Unit Primary Member`**| Primary hierarchy reference | Links secondary approval hierarchies to the base entity tree. |
| **6** | **`Approval Unit Secondary Member`**| Secondary dimension filter | Used when approval units are split by Scenario, Version, or Custom dim. |
| **7** | **`Approval Unit Owner`** | Current user ownership | Stores the user ID of the planner/reviewer who currently holds write access. |
| **8** | **`Approval Unit Previous Owner`**| Previous reviewer audit | Tracks the user ID of the person who promoted/delegated the unit. |
| **9** | **`Approval Unit Last Action`** | Audit trail action code | Encodes the last event: `Promote`, `Reject`, `Sign Off`, `Submit`. |
| **10**| **`Approval Unit Substate`** | Granular workflow condition | Differentiates sub-statuses (e.g., `Validation Failed`, `Pending Sign-off`). |
| **11**| **`Approval Unit Submission Group`**| Sub-entity grouping | **Selected in Extract**: Allows partial submission of an entity budget. |
| **12**| **`Approval Unit Hierarchy`** | Approval tree binding | **Selected in Extract**: Binds the member to the Planning Approval Unit Hierarchy. |
| **13**| **`Entity Process State`** | Rollup entity workflow status | Identifies whether child entities are still open or completely signed off. |
| **14**| **`Approval Unit Total`** | Stored financial check total | Checksum value used for promotion threshold validation rules. |
| **15**| **`Approval Unit Total (Dynamic)`**| On-the-fly threshold check | Evaluated at runtime to verify if budget exceeds promotion approval limits. |
| **16**| **`Approval Unit Last Modified`** | Timestamp | Epoch timestamp recording the moment of the last promotional action. |
| **17**| **`Cell Level Security Access`** | Dynamic security overlay | Binds cell-level security definitions to approval workflow promotion states. |

---

## 8. Multi-Cube & Custom Dimension Design (`No Custom1` & `D10010`)

### 8.1 The "No Member" Architecture Pattern (`No Custom1`)
In multi-cube applications, some cubes utilize custom dimensions that do not exist or are irrelevant in other cubes:
* **`FinPlan`** might require `Custom1` (e.g., Project).
* **`EPBCS`** might not utilize `Custom1`.

To allow cross-cube calculations, data maps, and Smart Push to function without dimension mismatch errors:
1. Oracle creates a placeholder member named `No Custom1` (or `No Project`).
2. Data entered in general forms that do not specify a project is stored at the `No Custom1` intersection.
3. In plan type settings, `FinPlan` is **Enabled**, while `EPBCS` and `Capital` are **Disabled**.

---

## 9. Troubleshooting & Consultant Diagnostics Matrix

| Symptom Observed | Root Cause in Member Properties | Diagnostic Check | Resolution Step |
| :--- | :--- | :--- | :--- |
| **Parent ratio adds up instead of calculating formula** (e.g. 40% + 60% = 100%) | `Two Pass Calculation` is unchecked or member is `Store` instead of `Dynamic Calc`. | Open Account properties. Check Data Storage and Two Pass. | Change Storage to `Dynamic Calc` and check `Two Pass Calculation`. |
| **Cannot enter data into a Level 0 member** in a form | Member is set to `Dynamic Calc`, `Label Only`, or is in a `Standard Target` version. | Inspect Data Storage and Version Type. | Change Data Storage to `Store` (or `Never Share`). Ensure Version is `Bottom Up`. |
| **Smart List dropdown does not appear in form cell** | Account Data Type is set to `Currency` or `Unspecified` instead of `SmartList`. | Open Account properties; verify Data Type and Smart List assignment. | Set Data Type to `SmartList`, select the Smart List, and run an Application Refresh. |
| **Budget variance displays positive for expenses that exceeded budget** | `Variance Reporting` is incorrectly configured as `Non-Expense`. | Check Account properties $\rightarrow$ Variance Reporting. | Change Variance Reporting to `Expense`. |
| **Balance Sheet cash balance at Q1 shows 3x the actual cash** | `Time Balance` is set to `Flow` instead of `Balance`. | View Time Balance property on Asset account. | Set Time Balance to `Balance` and Skip to `Missing`. |
| **Cube refresh fails after adding a parent member** | Parent with single child auto-shared, causing block collision. | Check if parent has only one child and is set to `Store`. | Set the single child (or parent) to `Never Share`. |

---

## 10. Consultant Technical Interview Mastery

### Q1: What is the exact physical difference between `Store` and `Dynamic Calc` in Essbase—
> **Answer**: A `Store` member allocates an 8-byte IEEE double-precision floating-point slot within each dense data block stored in the physical `.PAG` files on disk (and creates an entry in `.IND` if sparse). A `Dynamic Calc` member consumes **0 bytes of disk space**; its value is computed dynamically in RAM during query execution using the Dynamic Calc Cache and discarded after the query completes.

### Q2: When MUST you use `Never Share` instead of `Store`—
> **Answer**: `Never Share` is required when a parent member has only one child. Under default Essbase optimization, Essbase marks single-child parents as "Auto-Shared" with the child to save space. In Planning, this shared pointer causes security evaluation errors, data input locks, and unexpected formula overwrites. Setting `Never Share` forces Essbase to generate distinct blocks.

### Q3: Why is the Two Pass Calculation checkbox disabled on stored members—
> **Answer**: Essbase executes Two-Pass calculations exclusively in RAM during runtime query evaluation. Stored members are calculated during pre-compiled batch calculation runs (`CALC ALL`, `AGG`). Therefore, Oracle EPM Cloud restricts Two-Pass calculations to dense `Dynamic Calc` members.

### Q4: What happens if an Account member has Data Type = `SmartList` but you change its Data Type to `Currency`—
> **Answer**: Essbase still holds the underlying numeric entry IDs (e.g., `1.0`, `2.0`) in the data blocks, but the Planning form will no longer display the text string from the Smart List. Instead, the form will render the raw number formatted as currency (e.g., `$1.00`, `$2.00`).

---

**Related Architecture Documents:**
* [03 — Sparse vs Dense Complete Guide](Essbase_Internal_Architecture/03_Sparse_vs_Dense_Complete_Guide.md)
* [04 — Block Storage Deep Dive](Essbase_Internal_Architecture/04_Block_Storage_Deep_Dive.md)
* [09 — EPM Forms, Rules, and Data Storage](Essbase_Internal_Architecture/09_EPM_Forms_Rules_Data_Storage.md)
* [Shared Members Master Guide](Reference_Materials/Oracle_EPM_Shared_Members_Master_Guide.md)
