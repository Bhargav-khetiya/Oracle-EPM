# MDX Scripts in Oracle EPM — Complete Deep-Dive Guide

> [!NOTE]
> This document covers MDX (Multi-Dimensional Expressions) in Oracle EPM — what it is, where it's used, how to create MDX scripts, syntax, functions, and practical examples across Hyperion, PBCS, and EPBCS.

---

## Table of Contents

1. [What is MDX—](#1-what-is-mdx)
2. [MDX vs Calc Scripts vs Groovy](#2-mdx-vs-calc-scripts-vs-groovy)
3. [Where is MDX Used in Oracle EPM—](#3-where-is-mdx-used-in-oracle-epm)
4. [MDX Fundamentals](#4-mdx-fundamentals)
5. [MDX Query Syntax (SELECT)](#5-mdx-query-syntax-select)
6. [MDX Calculation Syntax (Business Rules)](#6-mdx-calculation-syntax-business-rules)
7. [MDX Functions — Complete Reference](#7-mdx-functions--complete-reference)
8. [Practical Examples](#8-practical-examples)
9. [MDX in Calc Manager (Step-by-Step)](#9-mdx-in-calc-manager-step-by-step)
10. [MDX in Smart View](#10-mdx-in-smart-view)
11. [MDX in Data Forms & Reports](#11-mdx-in-data-forms--reports)
12. [MDX Performance Tips](#12-mdx-performance-tips)
13. [Common Mistakes & Troubleshooting](#13-common-mistakes--troubleshooting)

---

## 1. What is MDX—

### 1.1 Definition

**MDX (Multi-Dimensional Expressions)** is a query and calculation language designed specifically for **OLAP (Online Analytical Processing) databases**. In Oracle EPM, MDX works with **Essbase cubes** — the multi-dimensional databases that power Hyperion Planning, PBCS, and EPBCS.

Think of it this way:
- **SQL** is for relational databases (Oracle DB, SQL Server) — rows and columns
- **MDX** is for multi-dimensional databases (Essbase) — cubes with dimensions

### 1.2 Two Uses of MDX in EPM

| Use | What It Does | Where Used |
|-----|-------------|-----------|
| **MDX Queries** | Retrieve/read data from Essbase cubes | Smart View, Reports, Member Formulas |
| **MDX Scripts** | Write/calculate data in Essbase cubes | Calc Manager Business Rules |

### 1.3 Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Cube** | The multi-dimensional database | `Plan1`, `OEP_FS` |
| **Dimension** | A category of data | `Account`, `Entity`, `Period` |
| **Member** | A specific item within a dimension | `Revenue`, `East`, `Jan` |
| **Tuple** | A specific intersection of members | `(Revenue, East, Jan)` |
| **Set** | A collection of members or tuples | `{Jan, Feb, Mar}` |
| **Measure** | The numeric values stored in the cube | Data value at an intersection |
| **Axis** | Row, Column, or Filter in a query | `ON ROWS`, `ON COLUMNS` |

---

## 2. MDX vs Calc Scripts vs Groovy

| Feature | MDX Scripts | Calc Scripts (Essbase) | Groovy Scripts |
|---------|------------|----------------------|----------------|
| **Available in** | Hyperion, PBCS, EPBCS | Hyperion, PBCS, EPBCS | PBCS, EPBCS only |
| **Primary use** | Set-based calculations, queries | Procedural calculations | Advanced logic, REST APIs |
| **Calculation style** | Set-based (like SQL) | Procedural (step-by-step) | Object-oriented programming |
| **Works with ASO cubes** | ✅ Yes (the ONLY calc option for ASO) | ❌ No (BSO only) | ✅ Yes (via data grids) |
| **Works with BSO cubes** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Learning curve** | Medium-High | Medium | High |
| **Performance** | Excellent for targeted calcs | Good for large block calcs | Varies |
| **Member formulas** | ✅ Yes (MDX-based in ASO) | ✅ Yes (Essbase calc formulas in BSO) | ❌ No |
| **Data queries** | ✅ Yes | ❌ No (calc only) | ✅ Yes |
| **External API calls** | ❌ No | ❌ No | ✅ Yes |
| **Cross-cube operations** | Limited | Limited (XREF/XWRITE) | ✅ Full support |

> [!IMPORTANT]
> **Key Rule:** For **ASO (Aggregate Storage) cubes**, MDX is the **only way** to write calculation scripts. Calc Scripts do NOT work on ASO cubes.

---

## 3. Where is MDX Used in Oracle EPM—

### 3.1 MDX Usage Points

| Location | Purpose | Products |
|----------|---------|----------|
| **Calc Manager — MDX Script** | Business rules that calculate data | Hyperion, PBCS, EPBCS |
| **Calc Manager — Member Formulas (ASO)** | Dynamic calculations on ASO members | Hyperion, PBCS, EPBCS |
| **Smart View — MDX Query** | Ad hoc data retrieval in Excel | Hyperion, PBCS, EPBCS |
| **Data Form — Member Selection** | Dynamic member selection formulas | PBCS, EPBCS |
| **Reports** | Query data for report grids | PBCS, EPBCS |
| **Runtime Prompts** | Dynamic member filtering | Hyperion, PBCS, EPBCS |
| **Essbase — MaxL MDX** | Direct Essbase queries | Hyperion (on-prem) |
| **Groovy — MDX within Groovy** | Embedded MDX queries in Groovy rules | PBCS, EPBCS |

---

## 4. MDX Fundamentals

### 4.1 Cube Anatomy for MDX

```
                    ┌─────────────────────────────────────┐
                    │          ESSBASE CUBE                │
                    │                                      │
  Dimension:        │    Period ──────────────────────►    │
  Account           │    │  Jan    Feb    Mar    Q1        │
       │            │    │                                 │
       ▼            │  Revenue  100    120    130   350    │
                    │  COGS      60     70     75   205    │
                    │  Margin    40     50     55   145    │
                    │                                      │
                    │  (Filtered by: Entity=East,          │
                    │   Scenario=Budget, Version=Working,  │
                    │   Year=FY25)                         │
                    └─────────────────────────────────────┘
```

### 4.2 Member Referencing

```
// Basic member reference — just the member name
[Revenue]

// Dimension-qualified reference — when member names might conflict
[Account].[Revenue]

// Fully qualified reference with hierarchy
[Account].[Total Revenue].[Product Revenue]

// Using the dimension's default member
[Account].DefaultMember

// Current member (context-sensitive)
[Account].CurrentMember
```

### 4.3 Core MDX Objects

#### Tuples — A Single Point in the Cube

A tuple identifies **one cell** (one intersection):

```
// Tuple = combination of one member from each dimension
// Wrapped in parentheses ()
([Revenue], [Jan], [East], [Budget], [Working], [FY25])

// Partial tuple (other dims come from context/defaults)
([Revenue], [Jan])
```

#### Sets — A Collection of Members

A set identifies **multiple members** from the same dimension:

```
// Set = collection of members, wrapped in braces {}
{[Jan], [Feb], [Mar]}

// Set from a function
{[Account].Children}

// Set with range
{[Jan] : [Jun]}
```

---

## 5. MDX Query Syntax (SELECT)

### 5.1 Basic SELECT Structure

```
SELECT
    {set_expression} ON COLUMNS,
    {set_expression} ON ROWS
FROM
    [CubeName]
WHERE
    (slicer_tuple)
```

### 5.2 Query Examples

#### Example 1: Simple Query — Revenue by Month

```
SELECT
    {[Jan], [Feb], [Mar], [Apr], [May], [Jun]} ON COLUMNS,
    {[Revenue], [COGS], [Gross Margin]} ON ROWS
FROM
    [Plan1]
WHERE
    ([East], [Budget], [Working], [FY25], [Local])
```

**Result:**

| | Jan | Feb | Mar | Apr | May | Jun |
|---|-----|-----|-----|-----|-----|-----|
| Revenue | 100 | 120 | 130 | 140 | 150 | 160 |
| COGS | 60 | 70 | 75 | 80 | 85 | 90 |
| Gross Margin | 40 | 50 | 55 | 60 | 65 | 70 |

#### Example 2: Using Functions — Children of an Entity

```
SELECT
    {[Q1], [Q2], [Q3], [Q4]} ON COLUMNS,
    {[Total Entity].Children} ON ROWS
FROM
    [Plan1]
WHERE
    ([Revenue], [Budget], [Working], [FY25])
```

#### Example 3: CrossJoin — Multiple Dimensions on One Axis

```
SELECT
    {[Jan], [Feb], [Mar]} ON COLUMNS,
    CrossJoin(
        {[Revenue], [COGS]},
        {[East], [West]}
    ) ON ROWS
FROM
    [Plan1]
WHERE
    ([Budget], [Working], [FY25])
```

**Result:**

| | Jan | Feb | Mar |
|---|-----|-----|-----|
| Revenue / East | 100 | 120 | 130 |
| Revenue / West | 200 | 220 | 240 |
| COGS / East | 60 | 70 | 75 |
| COGS / West | 110 | 120 | 130 |

#### Example 4: Filtering — Top 5 Entities by Revenue

```
SELECT
    {[Revenue]} ON COLUMNS,
    TopCount(
        [Entity].Members,
        5,
        [Revenue]
    ) ON ROWS
FROM
    [Plan1]
WHERE
    ([YearTotal], [Budget], [Working], [FY25])
```

#### Example 5: Calculated Member in Query

```
WITH
    MEMBER [Account].[Variance] AS
        '[Revenue] - [COGS]'
    MEMBER [Account].[Margin Pct] AS
        'IIF([Revenue] = 0, 0, ([Revenue] - [COGS]) / [Revenue])',
        FORMAT_STRING = "0.00%"
SELECT
    {[Q1], [Q2], [Q3], [Q4]} ON COLUMNS,
    {[Revenue], [COGS], [Variance], [Margin Pct]} ON ROWS
FROM
    [Plan1]
WHERE
    ([Total Entity], [Budget], [Working], [FY25])
```

---

## 6. MDX Calculation Syntax (Business Rules)

### 6.1 MDX Calc Scripts vs MDX Queries

| Aspect | MDX Query (SELECT) | MDX Calc Script |
|--------|-------------------|-----------------|
| **Purpose** | Read/retrieve data | Write/calculate data |
| **Keyword** | `SELECT ... FROM` | No SELECT; uses direct assignments |
| **Where used** | Smart View, Reports | Calc Manager Business Rules |
| **Modifies data—** | No (read-only) | Yes (writes to cube) |

### 6.2 MDX Calculation Script Structure

MDX calc scripts in Essbase/EPM Cloud do NOT use SELECT. Instead, they use **direct member assignments** or **ALTER DATABASE** statements.

#### Basic Assignment Syntax

```
// Assign a value to a member intersection
[Measure] = expression;
```

#### Using FIX-like Scoping (Non-Empty Tuples)

In cloud MDX business rules, you use Calc Manager's MDX Script type:

```
// Calculate Gross Margin = Revenue - COGS
// For all periods, all entities, Budget scenario

FIX([Budget], [Working], [FY25])
    [Gross Margin] = [Revenue] - [COGS];
ENDFIX
```

> [!NOTE]
> In Calc Manager MDX rules, you can mix MDX syntax with some Essbase calc-like constructs. The actual syntax depends on whether you're writing a **pure MDX script** or a **Calc Manager graphical/template rule that uses MDX expressions**.

### 6.3 MDX in Calc Manager — The Practical Way

In practice, MDX is most commonly used in Calc Manager in these forms:

#### Form 1: MDX Script Type (Calc Manager)

When you create a business rule in Calc Manager and choose **"MDX Script"** as the rule type:

```
// MDX Script Rule: Calculate Variance
// This runs as a business rule

ALTER DATABASE [Plan1] ADD MEMBER [Account].[Budget Variance]
AS '[Account].[Actual] - [Account].[Budget]';
```

#### Form 2: MDX Expression in Member Formula (ASO)

For ASO cubes, member formulas MUST be written in MDX:

```
// Member formula for "Gross Margin" in an ASO cube
// This is set in the member's formula property

CASE
    WHEN [Revenue] = 0 THEN 0
    ELSE ([Revenue] - [COGS]) / [Revenue]
END
```

#### Form 3: MDX within Graphical Rules (Conditional Logic)

In Calc Manager's graphical rule designer, you can use MDX expressions in conditions:

```
// Condition expression using MDX
IsAncestor([Entity].CurrentMember, [Total Entity])
```

---

## 7. MDX Functions — Complete Reference

### 7.1 Navigation Functions

These functions help you navigate the dimension hierarchy:

| Function | Description | Example | Result |
|----------|-------------|---------|--------|
| `Parent` | Returns the parent member | `[East].Parent` | `[Total Entity]` |
| `Children` | Returns all children | `[Total Entity].Children` | `{East, West, Central}` |
| `FirstChild` | Returns first child | `[Total Entity].FirstChild` | `[East]` |
| `LastChild` | Returns last child | `[Total Entity].LastChild` | `[Central]` |
| `Siblings` | Returns all siblings | `[East].Siblings` | `{East, West, Central}` |
| `PrevMember` | Returns previous member | `[Feb].PrevMember` | `[Jan]` |
| `NextMember` | Returns next member | `[Feb].NextMember` | `[Mar]` |
| `Lag(n)` | Goes back n members | `[Mar].Lag(2)` | `[Jan]` |
| `Lead(n)` | Goes forward n members | `[Jan].Lead(2)` | `[Mar]` |
| `Ancestor(mbr, dim/gen)` | Returns ancestor at level/gen | `Ancestor([Dept1], [Entity], 2)` | Grandparent entity |
| `Ancestors(mbr, distance)` | Returns set of ancestors | `Ancestors([Dept1], 3)` | Set of 3 ancestors |
| `Descendants(mbr)` | Returns all descendants | `Descendants([Total Entity])` | All entities below |
| `DefaultMember` | Returns dimension default | `[Scenario].DefaultMember` | Usually first member |
| `CurrentMember` | Returns current context member | `[Account].CurrentMember` | Context-dependent |

### 7.2 Set Functions

Functions that return **sets** (collections of members):

| Function | Description | Example |
|----------|-------------|---------|
| `Members` | All members of a dimension | `[Account].Members` |
| `AllMembers` | All members including calculated | `[Account].AllMembers` |
| `Children` | Children of a member | `[Total Revenue].Children` |
| `Descendants(mbr, level)` | Descendants at a specific level | `Descendants([Total Entity], 2)` |
| `Ancestors(mbr)` | Ancestor set | `Ancestors([Dept1])` |
| `Siblings` | Same-level members under same parent | `[East].Siblings` |
| `CrossJoin(set1, set2)` | Cartesian product of two sets | `CrossJoin({[Jan],[Feb]}, {[East],[West]})` |
| `Union(set1, set2)` | Combine two sets | `Union({[Jan]}, {[Feb]})` |
| `Intersect(set1, set2)` | Common members | `Intersect(set1, set2)` |
| `Except(set1, set2)` | Members in set1 not in set2 | `Except({[Q1].Children}, {[Mar]})` |
| `Filter(set, condition)` | Filter members by condition | `Filter([Entity].Members, [Revenue] > 1000)` |
| `Order(set, expr, flag)` | Sort members | `Order([Entity].Members, [Revenue], BDESC)` |
| `TopCount(set, n, expr)` | Top N members | `TopCount([Entity].Members, 5, [Revenue])` |
| `BottomCount(set, n, expr)` | Bottom N members | `BottomCount([Entity].Members, 5, [Revenue])` |
| `Head(set, n)` | First N members from set | `Head([Period].Members, 3)` |
| `Tail(set, n)` | Last N members from set | `Tail([Period].Members, 3)` |
| `Distinct(set)` | Remove duplicates | `Distinct(set_expression)` |
| `Generate(set, expr)` | Iterate and generate | `Generate([Entity].Children, {[Revenue]})` |
| `PeriodsToDate(level, mbr)` | Period accumulation set | `PeriodsToDate([Year], [Mar])` returns `{Jan, Feb, Mar}` |

### 7.3 Member Functions

Functions that return a **single member**:

| Function | Description | Example |
|----------|-------------|---------|
| `CurrentMember` | Current member in context | `[Period].CurrentMember` |
| `DefaultMember` | Default member of dimension | `[Scenario].DefaultMember` |
| `Parent` | Parent of a member | `[Jan].Parent` → `[Q1]` |
| `FirstChild` | First child | `[Q1].FirstChild` → `[Jan]` |
| `LastChild` | Last child | `[Q1].LastChild` → `[Mar]` |
| `PrevMember` | Previous sibling | `[Feb].PrevMember` → `[Jan]` |
| `NextMember` | Next sibling | `[Feb].NextMember` → `[Mar]` |
| `Lag(n)` | N positions back | `[Apr].Lag(3)` → `[Jan]` |
| `Lead(n)` | N positions forward | `[Jan].Lead(3)` → `[Apr]` |
| `ClosingPeriod(level, mbr)` | Last period at a level | `ClosingPeriod([Months], [Q1])` → `[Mar]` |
| `OpeningPeriod(level, mbr)` | First period at a level | `OpeningPeriod([Months], [Q1])` → `[Jan]` |
| `Ancestor(mbr, level)` | Ancestor at a specific level | `Ancestor([Jan], [Year])` → `[FY25]` |
| `Cousin(mbr, ancestorMbr)` | Equivalent member under diff parent | `Cousin([Jan], [Q2])` → `[Apr]` |
| `ParallelPeriod(level, n, mbr)` | Same relative position N periods ago | `ParallelPeriod([Year], 1, [Mar])` → Mar of prior year |

### 7.4 Numeric / Value Functions

Functions that return **numeric values**:

| Function | Description | Example |
|----------|-------------|---------|
| `Sum(set, expr)` | Sum of values | `Sum([Q1].Children, [Revenue])` |
| `Avg(set, expr)` | Average | `Avg([Q1].Children, [Revenue])` |
| `Max(set, expr)` | Maximum value | `Max([Period].Members, [Revenue])` |
| `Min(set, expr)` | Minimum value | `Min([Period].Members, [Revenue])` |
| `Count(set)` | Count of members | `Count([Entity].Children)` |
| `Aggregate(set)` | Aggregates using member's agg rule | `Aggregate([Q1].Children)` |
| `Median(set, expr)` | Median value | `Median([Period].Members, [Revenue])` |
| `Rank(set, mbr)` | Position of member in set | `Rank([Entity].Members, [East])` |
| `Abs(value)` | Absolute value | `Abs([Variance])` |
| `Round(value, digits)` | Round a number | `Round([Margin Pct], 2)` |
| `Int(value)` | Integer part | `Int(3.7)` → `3` |
| `Val(member)` | Returns stored value | `Val([Revenue])` |

### 7.5 Logical / Conditional Functions

| Function | Description | Example |
|----------|-------------|---------|
| `IIF(condition, true, false)` | If-then-else | `IIF([Revenue] > 0, [COGS]/[Revenue], 0)` |
| `CASE WHEN` | Multi-condition | See example below |
| `IsEmpty(value)` | Check if cell is empty | `IsEmpty([Revenue])` |
| `IsAncestor(mbr, ancestor)` | Is ancestor— | `IsAncestor([Entity].CurrentMember, [East])` |
| `IsGeneration(mbr, gen)` | Check generation | `IsGeneration([Entity].CurrentMember, 3)` |
| `IsLevel(mbr, level)` | Check level | `IsLevel([Entity].CurrentMember, 0)` |
| `IsLeaf(mbr)` | Is leaf member— | `IsLeaf([Entity].CurrentMember)` |
| `IsValid(tuple)` | Is valid intersection— | `IsValid(([Revenue], [East]))` |
| `NOT` | Negation | `NOT IsEmpty([Revenue])` |
| `AND` | Logical AND | `[Revenue] > 0 AND [COGS] > 0` |
| `OR` | Logical OR | `[Revenue] > 0 OR [COGS] > 0` |

#### CASE WHEN Example

```
CASE
    WHEN [Revenue] > 1000000 THEN "Large"
    WHEN [Revenue] > 500000 THEN "Medium"
    WHEN [Revenue] > 0 THEN "Small"
    ELSE "No Revenue"
END
```

### 7.6 Time-Related Functions

| Function | Description | Example |
|----------|-------------|---------|
| `PeriodsToDate(level, mbr)` | YTD/QTD members | `PeriodsToDate([Year], [Jun])` → `{Jan..Jun}` |
| `ParallelPeriod(level, n, mbr)` | Prior period at same relative position | `ParallelPeriod([Year], 1, [Mar])` |
| `OpeningPeriod(level, mbr)` | First period | `OpeningPeriod([Months], [Q2])` → `[Apr]` |
| `ClosingPeriod(level, mbr)` | Last period | `ClosingPeriod([Months], [Q2])` → `[Jun]` |
| `LastPeriods(n, mbr)` | Last N periods | `LastPeriods(3, [Jun])` → `{Apr, May, Jun}` |
| `Cousin(mbr, ancestorMbr)` | Same position under different ancestor | See navigation above |

### 7.7 String Functions (Limited in Essbase MDX)

| Function | Description | Example |
|----------|-------------|---------|
| `MemberName` | Name of member | `[Entity].CurrentMember.MEMBER_NAME` |
| `MemberUniqueName` | Unique name | `[Entity].CurrentMember.MEMBER_UNIQUE_NAME` |
| `Properties(prop)` | Member property | `[Entity].CurrentMember.Properties("MEMBER_ALIAS")` |

---

## 8. Practical Examples

### 8.1 Revenue Variance Analysis

```
// MDX Query: Compare Budget vs Actual with Variance and Variance %
WITH
    MEMBER [Scenario].[Variance] AS
        '[Actual] - [Budget]'
    MEMBER [Scenario].[Variance Pct] AS
        'IIF([Budget] = 0, 0, ([Actual] - [Budget]) / [Budget])',
        FORMAT_STRING = "0.00%"
SELECT
    {[Actual], [Budget], [Variance], [Variance Pct]} ON COLUMNS,
    {Descendants([Total Revenue], 2)} ON ROWS
FROM
    [Plan1]
WHERE
    ([YearTotal], [Total Entity], [Working], [FY25])
```

### 8.2 Year-to-Date (YTD) Calculation

```
// MDX: Calculate YTD Revenue
WITH
    MEMBER [Account].[YTD Revenue] AS
        'Sum(PeriodsToDate([Year], [Period].CurrentMember), [Revenue])'
SELECT
    {[Jan], [Feb], [Mar], [Apr], [May], [Jun]} ON COLUMNS,
    {[Revenue], [YTD Revenue]} ON ROWS
FROM
    [Plan1]
WHERE
    ([East], [Budget], [Working], [FY25])
```

**Result:**

| | Jan | Feb | Mar | Apr | May | Jun |
|---|-----|-----|-----|-----|-----|-----|
| Revenue | 100 | 120 | 130 | 140 | 150 | 160 |
| YTD Revenue | 100 | 220 | 350 | 490 | 640 | 800 |

### 8.3 Prior Year Comparison

```
// MDX: Compare current year vs prior year
WITH
    MEMBER [Year].[Prior Year] AS
        '([Year].CurrentMember.PrevMember)',
        FORMAT_STRING = "#,##0"
    MEMBER [Year].[YoY Growth] AS
        'IIF(([Year].CurrentMember.PrevMember) = 0, 0,
            ([Year].CurrentMember - [Year].CurrentMember.PrevMember)
            / [Year].CurrentMember.PrevMember)',
        FORMAT_STRING = "0.0%"
SELECT
    {[FY24], [FY25], [Prior Year], [YoY Growth]} ON COLUMNS,
    {[Revenue], [COGS], [Gross Margin], [Operating Expenses], [Net Income]} ON ROWS
FROM
    [Plan1]
WHERE
    ([YearTotal], [Total Entity], [Budget], [Working])
```

### 8.4 Rolling 3-Month Average

```
// MDX: Rolling 3-month average revenue
WITH
    MEMBER [Account].[Rolling 3M Avg] AS
        'Avg(LastPeriods(3, [Period].CurrentMember), [Revenue])',
        FORMAT_STRING = "#,##0.00"
SELECT
    {[Jan], [Feb], [Mar], [Apr], [May], [Jun],
     [Jul], [Aug], [Sep], [Oct], [Nov], [Dec]} ON COLUMNS,
    {[Revenue], [Rolling 3M Avg]} ON ROWS
FROM
    [Plan1]
WHERE
    ([East], [Budget], [Working], [FY25])
```

### 8.5 Top 10 Entities by Revenue

```
// MDX: Find top 10 revenue-generating entities
SELECT
    {[Revenue], [COGS], [Gross Margin]} ON COLUMNS,
    TopCount(
        Filter(
            [Entity].Members,
            IsLeaf([Entity].CurrentMember)
        ),
        10,
        [Revenue]
    ) ON ROWS
FROM
    [Plan1]
WHERE
    ([YearTotal], [Budget], [Working], [FY25])
```

### 8.6 Allocation — Spread Total to Children by Percentage

```
// MDX: Allocate corporate overhead to entities based on revenue share
// In a Calc Manager MDX script

// Step 1: Calculate each entity's share of total revenue
// Step 2: Multiply corporate overhead by that share

WITH
    MEMBER [Account].[Revenue Share] AS
        'IIF([Total Entity].[Revenue] = 0, 0,
            [Revenue] / ([Revenue], [Total Entity]))',
        FORMAT_STRING = "0.00%"
    MEMBER [Account].[Allocated Overhead] AS
        '[Account].[Revenue Share] * ([Corporate Overhead], [Total Entity])',
        FORMAT_STRING = "#,##0"
SELECT
    {[Revenue], [Revenue Share], [Allocated Overhead]} ON COLUMNS,
    {[Total Entity].Children} ON ROWS
FROM
    [Plan1]
WHERE
    ([YearTotal], [Budget], [Working], [FY25])
```

### 8.7 ASO Member Formula — Gross Margin %

```
// This is set as the member formula for "Gross Margin %" in an ASO cube
// (In PBCS/EPBCS: OEP_REP or any ASO reporting cube)

CASE
    WHEN IsEmpty([Revenue]) OR [Revenue] = 0
    THEN NULL
    ELSE
        ([Revenue] - [COGS]) / [Revenue]
END
```

### 8.8 Conditional Calculation with IIF

```
// MDX: Calculate bonus based on performance tier
WITH
    MEMBER [Account].[Calculated Bonus] AS
        'IIF([Revenue Achievement] >= 1.2,
            [Base Salary] * 0.25,
            IIF([Revenue Achievement] >= 1.0,
                [Base Salary] * 0.15,
                IIF([Revenue Achievement] >= 0.8,
                    [Base Salary] * 0.05,
                    0
                )
            )
        )',
        FORMAT_STRING = "#,##0"
SELECT
    {[Q1], [Q2], [Q3], [Q4]} ON COLUMNS,
    {[Revenue Achievement], [Base Salary], [Calculated Bonus]} ON ROWS
FROM
    [Plan1]
WHERE
    ([East], [Budget], [Working], [FY25])
```

### 8.9 Cumulative Sum (Running Total)

```
// MDX: Running total of expenses
WITH
    MEMBER [Account].[Cumulative Expenses] AS
        'Sum(
            PeriodsToDate([Year], [Period].CurrentMember),
            [Total Expenses]
        )',
        FORMAT_STRING = "#,##0"
SELECT
    {[Jan] : [Dec]} ON COLUMNS,
    {[Total Expenses], [Cumulative Expenses]} ON ROWS
FROM
    [Plan1]
WHERE
    ([Total Entity], [Budget], [Working], [FY25])
```

### 8.10 Percentage of Parent

```
// MDX: Each entity's revenue as a percentage of its parent
WITH
    MEMBER [Account].[Pct of Parent] AS
        'IIF(
            IsEmpty(([Revenue], [Entity].CurrentMember.Parent)) OR
            ([Revenue], [Entity].CurrentMember.Parent) = 0,
            0,
            [Revenue] / ([Revenue], [Entity].CurrentMember.Parent)
        )',
        FORMAT_STRING = "0.0%"
SELECT
    {[Revenue], [Pct of Parent]} ON COLUMNS,
    Descendants([Total Entity], 2) ON ROWS
FROM
    [Plan1]
WHERE
    ([YearTotal], [Budget], [Working], [FY25])
```

---

## 9. MDX in Calc Manager (Step-by-Step)

### 9.1 Creating an MDX Business Rule

#### Step 1: Open Calc Manager

- **Hyperion**: Navigate → Workspace → Calc Manager
- **PBCS/EPBCS**: Navigator → Rules (or Tools → Business Rules)

#### Step 2: Create New Rule

1. Right-click on the application → **New Rule**
2. Enter **Rule Name** (e.g., `Calculate_Variance`)
3. Select **Plan Type** (e.g., `Plan1` or `OEP_FS`)
4. Click **OK**

#### Step 3: Choose Rule Type

In the rule designer, you have options:

| Option | When to Use |
|--------|------------|
| **Script** → **Calc Script** | BSO procedural calculations |
| **Script** → **MDX Script** | ASO calculations or set-based BSO calcs |
| **Graphical** | Visual drag-and-drop rule builder |

Select **"Script"** and change the script type to **"MDX Script"**.

#### Step 4: Write MDX Script

```
// Example MDX Business Rule: Calculate Variance

// For BSO cube - direct assignment style
FIX([Budget], [Working], [FY25])
    "Variance" = "Actual" - "Budget";
    "Variance Pct" =
        IIF("Budget" == 0, 0,
            ("Actual" - "Budget") / "Budget");
ENDFIX
```

> [!WARNING]
> The exact syntax depends on whether you're using a **pure MDX script** or **Calc Script with MDX expressions**. In Calc Manager, many users use Calc Script syntax (FIX/ENDFIX) with occasional MDX functions embedded. Pure MDX scripts are more common for ASO cubes.

#### Step 5: Validate and Deploy

1. Click **Validate** to check syntax
2. Click **Save**
3. Right-click → **Deploy** to make it available
4. Assign to data forms or task lists as needed

### 9.2 MDX Rule in Calc Manager — ASO Example

For ASO cubes (like `OEP_REP`, `OEP_WFREP`), you MUST use MDX:

```
// ASO MDX Script: Custom aggregation for reporting cube
// This creates a calculated member in the ASO cube

ALTER DATABASE [OEP_REP]
ADD MEMBER [Account].[Adjusted Revenue]
AS 'IIF(
    IsEmpty([Revenue]),
    0,
    [Revenue] * (1 + [Adjustment Rate])
)';
```

### 9.3 MDX in Graphical Rules (Conditional Component)

When building a **Graphical Rule** in Calc Manager, you can use MDX in:

1. **Condition blocks** — to check IF conditions using MDX functions
2. **Formula blocks** — to use MDX expressions in calculations
3. **Member Range blocks** — to dynamically select members

```
// Inside a Condition component in Graphical Rule
// Check if the entity is a leaf-level entity
Condition: IsLeaf([Entity].CurrentMember) = TRUE
    → Run calculation branch
Else:
    → Skip
```

---

## 10. MDX in Smart View

### 10.1 Running MDX Queries in Smart View

1. Open **Smart View** in Excel
2. Connect to your EPM Cloud or Hyperion instance
3. **Ad Hoc Analysis** → Select your application and cube

#### Using MDX Directly in Smart View

- Go to **Smart View** ribbon → **Query Designer** (if available)
- Or use the **Free-Form** mode and enter MDX queries

#### Smart View MDX Example

```
// In Smart View's MDX query window:
SELECT
    {[Jan], [Feb], [Mar]} ON COLUMNS,
    {[Revenue], [Expenses], [Net Income]} ON ROWS
FROM
    [Plan1]
WHERE
    ([East], [Budget], [Working], [FY25])
```

### 10.2 MDX in Smart View Functions

You can use certain MDX-like functions in Smart View member selection:

```
// In Smart View member selection dialog:
// Use these to dynamically select members

Children of [Total Entity]     → Shows all children
Descendants of [Q1]            → Shows all descendants
Level 0 of [Entity]            → Shows leaf members
```

---

## 11. MDX in Data Forms & Reports

### 11.1 MDX in Data Form Member Selection

In PBCS/EPBCS, when designing data forms, you can use MDX-style functions for dynamic member selection in rows/columns:

| Function | Usage in Form Designer | Result |
|----------|----------------------|--------|
| `Children of` | `Children of [Total Entity]` | Shows all child entities |
| `Descendants of` | `Descendants of [Total Entity]` | Shows all descendants |
| `Level 0 Descendants` | `ILvl0Descendants of [Total Entity]` | Shows leaf-level entities |
| `Siblings of` | `Siblings of [East]` | Shows East, West, Central |
| `Parent of` | `Parent of [East]` | Shows Total Entity |
| `Ancestors of` | `Ancestors of [Dept1]` | Shows hierarchy path |

### 11.2 MDX in Reports (Cloud Reports)

In Oracle EPM Cloud Reports (replacement for Financial Reporting):

```
// In the report grid's row/column definition:
// Use MDX-based member selection

// Dynamic rows showing all entities with Revenue > 100000
Filter(
    [Entity].Members,
    [Revenue] > 100000
)
```

### 11.3 MDX in Narrative Reporting

Narrative Reporting can embed data grids that use MDX-based queries to pull data from Planning cubes.

---

## 12. MDX Performance Tips

### 12.1 Do's

| Tip | Why |
|-----|-----|
| **Use specific members instead of `.Members`** | `.Members` iterates all members — very expensive |
| **Filter early, not late** | Reduce the set size before complex operations |
| **Use `NON EMPTY` keyword** | Skips empty cells, faster queries |
| **Use `Descendants(mbr, level)` with level** | More targeted than just `Descendants(mbr)` |
| **Pre-calculate in BSO, report in ASO** | BSO for write; ASO for read performance |
| **Use `IIF` instead of nested `CASE`** | `IIF` is often faster for simple conditions |
| **Limit CrossJoin results** | CrossJoin can create massive result sets |

#### NON EMPTY Example

```
// Without NON EMPTY — returns all rows including empty
SELECT
    {[Revenue]} ON COLUMNS,
    [Entity].Members ON ROWS
FROM [Plan1]

// With NON EMPTY — skips empty rows (much faster)
SELECT
    {[Revenue]} ON COLUMNS,
    NON EMPTY [Entity].Members ON ROWS
FROM [Plan1]
```

### 12.2 Don'ts

| Anti-Pattern | Why It's Bad | Better Alternative |
|-------------|-------------|-------------------|
| `[Dimension].Members` without filter | Scans entire dimension | Use `Children`, `Descendants` with level |
| Nested `CrossJoin` of large sets | Exponential growth | Filter sets before CrossJoin |
| Complex `WITH MEMBER` on large sets | Calculated for every cell | Pre-calculate and store if possible |
| Using MDX for procedural calcs on BSO | Calc scripts are faster for BSO procedures | Use Calc Scripts for BSO procedural calcs |
| Multiple `IIF` nesting (10+ levels) | Hard to read and slow | Use `CASE WHEN` instead |

---

## 13. Common Mistakes & Troubleshooting

### 13.1 Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Member [X] not found` | Typo in member name or wrong cube | Check member name exactly (case-sensitive) |
| `Dimension [X] not found` | Wrong dimension name | Verify dimension names in your application |
| `Syntax error near...` | Missing brackets, quotes, or commas | Check all `[]`, `{}`, `()` are matched |
| `Cannot resolve member` | Member doesn't exist in specified dimension | Use `[Dimension].[Member]` qualified name |
| `Query returns empty` | Wrong slicer (WHERE clause) | Check all dimensions have valid members in WHERE |
| `#MISSING in results` | No data at that intersection | Use `IIF(IsEmpty(...), 0, ...)` to handle |
| `Too many members on axis` | Set is too large | Use `Filter`, `TopCount`, or `Head` to limit |
| `MDX not supported on BSO` | Some MDX features are ASO-only | Use Calc Scripts for BSO-specific operations |

### 13.2 Debugging MDX

| Technique | How |
|-----------|-----|
| **Test in Smart View** | Run MDX queries in Smart View before putting in rules |
| **Start simple** | Write a basic query first, then add complexity |
| **Use WITH MEMBER** | Create calculated members to test formulas |
| **Check member names** | Copy exact member names from the dimension editor |
| **Validate in Calc Manager** | Use the Validate button before deploying |
| **Check logs** | Review Essbase logs for detailed error messages |
| **Use NON EMPTY** | To quickly see if your query returns any data |

### 13.3 Quick Syntax Reference Card

```
// ═══════════════════════════════════════════════
// MDX QUICK REFERENCE
// ═══════════════════════════════════════════════

// MEMBER REFERENCE
[DimensionName].[MemberName]
[Account].[Revenue]

// TUPLE (single cell intersection)
([Revenue], [Jan], [East])

// SET (collection of members)
{[Jan], [Feb], [Mar]}

// RANGE
{[Jan] : [Jun]}

// QUERY STRUCTURE
SELECT
    {columns} ON COLUMNS,
    {rows} ON ROWS
FROM [CubeName]
WHERE (filters)

// CALCULATED MEMBER
WITH MEMBER [Dim].[Name] AS 'expression'

// CONDITIONAL
IIF(condition, true_value, false_value)
CASE WHEN cond1 THEN val1 WHEN cond2 THEN val2 ELSE val3 END

// COMMON NAVIGATION
.Parent  .Children  .FirstChild  .LastChild
.PrevMember  .NextMember  .Lag(n)  .Lead(n)

// COMMON SET FUNCTIONS
Members  Children  Descendants  Siblings
CrossJoin  Union  Intersect  Except  Filter
TopCount  BottomCount  Order  Head  Tail

// COMMON AGGREGATE FUNCTIONS
Sum  Avg  Max  Min  Count  Median  Aggregate

// COMMON CHECKS
IsEmpty  IsLeaf  IsAncestor  IsGeneration  IsLevel

// TIME INTELLIGENCE
PeriodsToDate  ParallelPeriod  OpeningPeriod
ClosingPeriod  LastPeriods  Cousin

// NON EMPTY (skip empty results)
SELECT {measures} ON COLUMNS,
NON EMPTY {members} ON ROWS
FROM [Cube]
```

---

> [!TIP]
> **Best Practice Summary:**
> - Use **MDX** for ASO cubes (it's the only option), for queries/reporting, and for set-based calculations
> - Use **Calc Scripts** for BSO procedural calculations (faster for bulk operations)
> - Use **Groovy** (cloud only) when you need REST APIs, cross-cube operations, or complex programming logic
> - **Test MDX queries in Smart View** before embedding them in business rules
> - Always use **NON EMPTY** in queries to improve performance
