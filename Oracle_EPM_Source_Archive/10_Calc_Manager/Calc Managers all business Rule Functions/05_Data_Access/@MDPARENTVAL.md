# @MDPARENTVAL

## Overview

`@MDPARENTVAL` is a **multi-dimensional data access function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **data value stored at the parent member** of the current member, with the ability to specify which dimension's parent to navigate to. It is the multi-dimensional version of `@PARENTVAL`, designed for use in applications with multiple dimensions where you need to clearly specify which dimension's hierarchy to navigate.

### Why Does This Function Exist—

In multi-dimensional planning applications with many dimensions, you often need to reference the parent's data:
- Computing each entity's share of the parent entity's total
- Inheriting rates or assumptions from the parent level
- Building variance calculations between a member and its parent
- Implementing percentage-of-parent calculations for waterfall charts

### When to Use It

- When you need the parent's data value in a **specific dimension** in a multi-dimensional context
- When `@PARENTVAL` is ambiguous because multiple dimensions could be the target
- For percentage-of-parent or contribution-margin calculations
- Use `@MDPARENTVAL` over `@PARENTVAL` in complex cubes to avoid ambiguity

---

## Category

**Data Access / Multi-Dimensional / Hierarchy**

---

## Syntax

```essbase
@MDPARENTVAL(dimName)
```

### Formal Syntax

```
@MDPARENTVAL(dimensionName)
```

Where:
- `dimensionName` — The name of the dimension in which to navigate to the parent

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension name | ✅ Yes | The dimension in which to navigate to the current member's parent. Specifies which hierarchy to traverse upward. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Current member has a parent | The data value at the parent member (in the specified dimension) |
| Current member is the root | Undefined — avoid on root members |
| Parent's value is `#MISSING` | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Dimension-Specific**: `@MDPARENTVAL` navigates to the parent member **only in the specified dimension**. All other dimensions retain their current member context.

2. **Value Retrieval**: After identifying the parent member, Essbase retrieves the data value at the intersection of (parent member in specified dim, current members in all other dims).

3. **Aggregation Dependency**: The parent's value must already be calculated/aggregated for `@MDPARENTVAL` to return correct results. If the parent hasn't been aggregated yet, the value may be stale or `#MISSING`.

4. **Multi-Dimensional vs. Single-Dimensional**: Unlike `@PARENTVAL`, which works within the current calc dimension, `@MDPARENTVAL` explicitly states which dimension, removing ambiguity in multi-dimension formulas.

5. **Read Function**: This is a read-only function — it retrieves data but does not modify the parent's value.

---

## Syntax Variants & Scenarios

### Variant 1: Entity Dimension Parent Value

```essbase
@MDPARENTVAL("Entity")
```
Returns the data value at the parent of the current Entity member.

### Variant 2: Product Dimension Parent Value

```essbase
@MDPARENTVAL("Product")
```
Returns the data value at the parent of the current Product member.

### Variant 3: In Arithmetic Expression

```essbase
"Pct_of_Parent" = Revenue / @MDPARENTVAL("Entity") * 100;
```

---

## Practical Examples

### Example 1: Percentage of Parent Entity

**Scenario**: Calculate each entity's revenue as a percentage of its parent entity's revenue.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Entity"))
    IF(@MDPARENTVAL("Entity") <> 0)
        "Pct_of_Parent" = Revenue / @MDPARENTVAL("Entity") * 100;
    ELSE
        "Pct_of_Parent" = 0;
    ENDIF
ENDFIX
```

**What Happens**: For "US_East" under "North_America", this computes `US_East Revenue / North_America Revenue * 100`.

---

### Example 2: Variance from Parent Level

**Scenario**: Calculate the deviation of each product's margin from the parent product group's margin.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("All_Products"))
    "Margin_Var_vs_Parent" = "Gross_Margin_Pct" - (@MDPARENTVAL("Product") / Revenue * 100);
ENDFIX
```

---

### Example 3: Inherit Parent Rate When Missing

**Scenario**: If a leaf entity doesn't have a tax rate, use the parent entity's rate.

```essbase
FIX("FY24", "Budget", @DESCENDANTS("Total_Entity"))
    IF("Tax_Rate" == #MISSING)
        "Tax_Rate" = @MDPARENTVAL("Entity");
    ENDIF
ENDFIX
```

---

### Example 4: Contribution Waterfall

**Scenario**: Calculate each department's contribution to its division total.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Departments"))
    IF(@MDPARENTVAL("Entity") <> 0)
        "Contribution_Pct" = "Operating_Income" / @MDPARENTVAL("Entity") * 100;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Parent not yet aggregated | `@MDPARENTVAL` reads the stored value — if parent hasn't been aggregated, it may be stale | Run AGG before formulas that use `@MDPARENTVAL` |
| Division by zero | Parent value could be 0 | Always check `IF(@MDPARENTVAL(dim) <> 0)` before dividing |
| Using on root member | Root has no parent — result is undefined | Guard with `IF(@LEV(@CURRMBR(dim)) < maxLevel)` |
| Confusing with `@PARENTVAL` | `@PARENTVAL` doesn't require a dimension name but may be ambiguous | Use `@MDPARENTVAL` for clarity in multi-dimensional models |
| Confusing with `@MBRPARENT` | `@MBRPARENT` returns the parent **member**, not its data value | Use `@MDPARENTVAL` for the value, `@MBRPARENT` for the member reference |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PARENTVAL`](./@PARENTVAL.md) | Single-dimension parent value — less explicit |
| [`@MDANCESTVAL`](./@MDANCESTVAL.md) | Multi-dimensional ancestor value at a specified generation |
| [`@MBRPARENT`](./@MBRPARENT.md) | Returns the parent **member** (not its value) |
| [`@PARENT`](./@PARENT.md) | Returns parent as a member set |
| [`@SPARENTVAL`](./@SPARENTVAL.md) | Parent value in the context of the current sparse dimension |
| [`@ANCESTVAL`](./@ANCESTVAL.md) | Value at a specific ancestor level |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MDPARENTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mdparentval.html)
- [Oracle Essbase Technical Reference — @MDPARENTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
