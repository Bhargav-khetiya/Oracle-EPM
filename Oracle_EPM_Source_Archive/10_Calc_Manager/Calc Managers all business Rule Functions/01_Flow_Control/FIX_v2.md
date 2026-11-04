# FIX

## Overview

`FIX` is the **most important and most frequently used command** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager business rules. It defines a **scope of calculation** by restricting which members are included in the calculation block. Every data point not within the FIX scope is completely ignored — making calculations faster, safer, and more targeted.

### Why Does This Command Exist—

Without `FIX`, every calculation would run against the **entire database** — every member of every dimension. This would be:
- **Dangerously slow**: Processing millions of unnecessary intersections
- **Risky**: Accidentally overwriting data in scenarios, versions, or periods you didn't intend
- **Resource-wasteful**: Consuming server compute for cells that don't need updating

`FIX` solves all of this by creating a "fence" around exactly the data you want to touch.

### When to Use It

- **Always.** Every well-written business rule uses at least one FIX block
- When you want to calculate only specific Scenarios (e.g., "Working" but not "Final")
- When you want to target specific periods (e.g., "FY25" only)
- When you want to target specific Entity hierarchies
- When nesting calculations that apply to different member combinations
- To improve performance by reducing the calculation scope

---

## Category

**Calc Script Command / Flow Control / Scope**

---

## Syntax

```essbase
FIX(member1, member2, ...)
    /* calculation statements */
ENDFIX
```

### Formal Syntax

```
FIX(memberSpec [, memberSpec]...)
    calcStatements
ENDFIX
```

Where:
- `memberSpec` — A member name, member function (like `@CHILDREN`, `@DESCENDANTS`), cross-dimensional operator, or a member range. Multiple members from the same dimension are comma-separated. Members from different dimensions are also comma-separated.
- `calcStatements` — Any valid calculation statements, including nested FIX blocks, IF statements, formulas, or other commands.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `memberSpec` | Member name, function, or range | ✅ Yes (at least one) | Specifies which members to include in the calculation scope. Can be a literal member name (in quotes if it contains spaces), a member function like `@DESCENDANTS("Total Entity")`, a member range like `"Jan":"Dec"`, or a combination. Each dimension should ideally appear only once in a FIX statement. |

---

## Return Value

`FIX` does not return a value — it is a **scoping command** that defines which cells are processed by the statements inside the block.

---

## How It Works (Behind the Scenes)

1. **Scope Resolution**: When Essbase encounters a FIX statement, it first resolves all member specifications. Member functions like `@DESCENDANTS` are expanded into their full member lists. The resulting set of member combinations defines the "calculation cube" — the exact set of data blocks that will be processed.

2. **Block-Level Filtering**: In BSO (Block Storage Option), data is stored in blocks defined by sparse dimension intersections. FIX works by filtering which blocks are loaded into memory for calculation. If your FIX includes sparse members, only blocks matching those sparse combinations are processed. This is the primary performance benefit.

3. **Dense Dimension Behavior**: If your FIX includes dense dimension members (like Period or Account), ALL cells in matching blocks are still loaded — but calculations only execute on the specified dense members within those blocks.

4. **Nesting**: FIX blocks can be nested. Inner FIX blocks further restrict the scope of the outer FIX. This is extremely common and powerful — for example, fixing on a year, then within that, fixing on different entity groups for different calculations.

5. **Order of Dimensions**: The order of dimensions in the FIX statement does not affect the result, but listing sparse dimensions first can marginally improve performance because the block filter is applied earlier.

6. **Missing Blocks**: If a FIX scope targets a sparse intersection where no data block exists, that intersection is simply skipped. No empty blocks are created (unless `SET CREATEBLOCKONEQ ON` is active and a formula writes to that intersection).

---

## Syntax Variants & Scenarios

### Variant 1: Simple Member Fix

```essbase
FIX("FY25", "Working")
    Revenue = Units * Price;
ENDFIX
```
Restricts calculation to FY25 Working scenario only.

### Variant 2: Member Function in FIX

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    Revenue = Units * Price;
ENDFIX
```
Processes all leaf-level entities under "Total Entity".

### Variant 3: Multiple Members from Same Dimension

```essbase
FIX("Jan", "Feb", "Mar", "FY25")
    Revenue = Units * Price;
ENDFIX
```
Processes only Q1 months.

### Variant 4: Member Range

```essbase
FIX("Jan":"Dec", "FY25", "Working")
    Revenue = Units * Price;
ENDFIX
```
Processes all months from Jan to Dec using range syntax.

### Variant 5: Nested FIX Blocks

```essbase
FIX("FY25", "Working")
    FIX(@DESCENDANTS("North America"))
        Revenue = Revenue * 1.10;  /* 10% increase for NA */
    ENDFIX
    FIX(@DESCENDANTS("Europe"))
        Revenue = Revenue * 1.05;  /* 5% increase for Europe */
    ENDFIX
ENDFIX
```
Different calculations for different entity groups within the same year/scenario.

### Variant 6: FIX with Cross-Dimensional Operator

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Bonus Expense" = "Salary" -> "Actual" * 0.15;
ENDFIX
```
Uses cross-dimensional reference inside a FIX block to pull Actual salary for bonus calculation.

---

## Practical Examples

### Example 1: Revenue Calculation with Entity Scope

**Scenario**: Calculate Revenue = Units × Price for all entities in the Working scenario for FY25.

```essbase
FIX("FY25", "Working", "Local", @DESCENDANTS("Total Entity"))
    Revenue = Units * Price;
ENDFIX
```

**What Happens**:
- Essbase resolves `@DESCENDANTS("Total Entity")` to all child entities
- Only blocks matching FY25 + Working + Local + each entity are loaded
- For each loaded block, Revenue cell = Units × Price
- All other scenarios, years, and currencies are untouched

---

### Example 2: Expense Allocation Across Departments

**Scenario**: Allocate corporate overhead to departments based on headcount ratio.

```essbase
FIX("FY25", "Working", "Jan":"Dec")
    FIX(@DESCENDANTS("Operating Departments"))
        "Allocated_Overhead" = "Total_Overhead" -> "Corporate" *
            ("Headcount" / "Headcount" -> "Total Departments");
    ENDFIX
ENDFIX
```

**What Happens**:
- Outer FIX scopes to FY25, Working, all months
- Inner FIX targets only operating departments (not Corporate itself)
- Each department gets overhead proportional to its headcount share

---

### Example 3: Conditional Logic Inside FIX

**Scenario**: Calculate tax only for entities flagged as taxable via UDA.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@UDA("Entity", "Taxable"))
        "Tax_Expense" = "Pre_Tax_Income" * "Tax_Rate";
    ELSE
        "Tax_Expense" = 0;
    ENDIF
ENDFIX
```

---

### Example 4: Period-Specific Calculations

**Scenario**: Apply different growth rates for H1 vs H2.

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    FIX("Jan":"Jun")
        Revenue = Revenue -> "FY24" * 1.08;  /* 8% growth H1 */
    ENDFIX
    FIX("Jul":"Dec")
        Revenue = Revenue -> "FY24" * 1.12;  /* 12% growth H2 */
    ENDFIX
ENDFIX
```

---

### Example 5: Aggregation After Calculation

**Scenario**: Calculate base data, then aggregate Account dimension.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    Revenue = Units * Price;
    COGS = Units * "Unit Cost";
    "Gross Margin" = Revenue - COGS;
ENDFIX

CALC DIM("Account");
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing ENDFIX | Every FIX must have a matching ENDFIX or the script will error | Always write FIX/ENDFIX as a pair before adding content |
| Fixing on an upper-level member | `FIX("Total Entity")` only targets that specific member, not its children | Use `@DESCENDANTS("Total Entity")` or `@CHILDREN("Total Entity")` |
| Fixing on dense AND sparse members without understanding blocks | Fixing on dense members doesn't reduce blocks loaded — only sparse members reduce block count | Put sparse members in FIX for performance; handle dense members with IF or formulas |
| Not fixing on Scenario/Version | Without scenario scope, calculations may overwrite Actual, Budget, and Forecast simultaneously | Always include Scenario and Version in your FIX |
| Using FIX on a member with special characters | Member names with spaces or special chars need quotes | Always quote member names: `FIX("North America")` |
| Overlapping FIX scopes in nested blocks | Inner FIX can only narrow the outer scope — it cannot expand it | The inner FIX is always an intersection with the outer FIX |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`ENDFIX`](./ENDFIX.md) | Required closing pair for every FIX block |
| [`IF`](./IF.md) | Conditional logic within FIX — filters at cell level vs FIX at block level |
| [`@DESCENDANTS`](../04_Member_Navigation/@DESCENDANTS.md) | Most commonly used member function inside FIX |
| [`@CHILDREN`](../04_Member_Navigation/@CHILDREN.md) | Returns immediate children — common in FIX |
| [`@RELATIVE`](../04_Member_Navigation/@RELATIVE.md) | Returns members at specific generation — used in FIX |
| [`@UDA`](../09_Boolean_Conditional/@UDA.md) | User-Defined Attribute filter — often combined with FIX |
| [`SET CREATEBLOCKONEQ`](../02_SET_Commands/SET CREATEBLOCKONEQ.md) | Controls block creation behavior within FIX |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — FIX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/fix.html)
- [Oracle Essbase Technical Reference — FIX/ENDFIX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/fix_endfix.html)
