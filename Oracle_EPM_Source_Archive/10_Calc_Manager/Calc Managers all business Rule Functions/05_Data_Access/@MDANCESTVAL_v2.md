# @MDANCESTVAL

## Overview

`@MDANCESTVAL` is a **multi-dimensional data access function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **data value stored at an ancestor member** of the current member in a specified dimension, at a specified generation. It is the multi-dimensional version of `@ANCESTVAL`, designed for complex applications where you need to explicitly specify which dimension's hierarchy to navigate.

### Why Does This Function Exist—

Accessing ancestor-level data is essential for:
- Computing percentage-of-total calculations against any ancestor level
- Inheriting rates or assumptions from higher levels in the hierarchy
- Building variance analysis between detail and summary levels
- Creating KPIs that reference a specific ancestor generation's aggregated values

### When to Use It

- When you need an ancestor's data value at a **specific generation** in a **specific dimension**
- For percentage-of-total or contribution calculations at any hierarchy level
- When `@PARENTVAL` or `@MDPARENTVAL` only goes one level up and you need to go higher
- In multi-dimensional models where specifying the dimension avoids ambiguity

---

## Category

**Data Access / Multi-Dimensional / Hierarchy**

---

## Syntax

```essbase
@MDANCESTVAL(dimName, generation)
```

### Formal Syntax

```
@MDANCESTVAL(dimensionName, genNumber)
```

Where:
- `dimensionName` — The dimension in which to navigate to the ancestor
- `genNumber` — The target generation number (counted from top: root = 0 or 1)

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension name | ✅ Yes | The dimension in which to navigate upward to find the ancestor. |
| `generation` | Integer | ✅ Yes | The generation number of the target ancestor. Generation is counted from the top of the hierarchy. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Ancestor exists at specified generation | The data value at that ancestor's intersection |
| No ancestor at that generation (member is at or above) | Undefined — avoid by checking generation first |
| Ancestor's value is `#MISSING` | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Generation-Based Navigation**: Essbase identifies the current member in the specified dimension, then navigates upward to the ancestor at the given generation number.

2. **Dimension-Specific**: Only the specified dimension's member changes to the ancestor. All other dimensions retain their current context.

3. **Value Retrieval**: The data value at the intersection of (ancestor in specified dim, current members in all other dims) is returned.

4. **Aggregation Dependency**: The ancestor value must already be aggregated/calculated for accurate results. Run AGG before using `@MDANCESTVAL`.

5. **Read Function**: Does not modify any data — read-only access.

---

## Syntax Variants & Scenarios

### Variant 1: Root-Level Value

```essbase
@MDANCESTVAL("Entity", 0)
```
Returns the value at the root of the Entity dimension (e.g., "Total_Entity").

### Variant 2: Regional Level Value

```essbase
@MDANCESTVAL("Entity", 1)
```
Returns the value at generation 1 of Entity (e.g., regional level).

### Variant 3: In Arithmetic Expression

```essbase
"Pct_of_Total" = Revenue / @MDANCESTVAL("Entity", 0) * 100;
```

---

## Practical Examples

### Example 1: Percentage of Corporate Total

**Scenario**: Calculate each entity's revenue as a percentage of the corporate total (root level).

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Entity"))
    IF(@MDANCESTVAL("Entity", 0) <> 0)
        "Pct_of_Corp" = Revenue / @MDANCESTVAL("Entity", 0) * 100;
    ELSE
        "Pct_of_Corp" = 0;
    ENDIF
ENDFIX
```

**What Happens**: For "US_East" (gen 3), it retrieves the Revenue at "Total_Entity" (gen 0) and computes the percentage.

---

### Example 2: Regional Contribution

**Scenario**: Calculate each entity's contribution to its regional total (generation 1).

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Entity"))
    IF(@MDANCESTVAL("Entity", 1) <> 0)
        "Regional_Contribution" = Revenue / @MDANCESTVAL("Entity", 1) * 100;
    ENDIF
ENDFIX
```

---

### Example 3: Inherit Rate from Top Level

**Scenario**: All entities should use the corporate-level discount rate.

```essbase
FIX("FY24", "Budget", @DESCENDANTS("Total_Entity"))
    "Discount_Rate" = @MDANCESTVAL("Entity", 0);
ENDFIX
```

---

### Example 4: Variance from Division Total

**Scenario**: Compute each department's deviation from its division (gen 2) average.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Entity"))
    IF(@MDANCESTVAL("Entity", 2) <> 0)
        "Div_Var" = Revenue - @MDANCESTVAL("Entity", 2);
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Ancestor not yet aggregated | Returns stale or `#MISSING` values | Run `AGG` before formulas using `@MDANCESTVAL` |
| Generation number confusion | Gen 0 = root. Some outlines use gen 1 as root. | Verify your outline's generation numbering |
| Division by zero | Ancestor value could be 0 | Always guard with `IF(value <> 0)` |
| Using on root member | If current member IS at the requested generation, it returns its own value | This is expected behavior — not an error |
| Confusing with `@ANCESTVAL` | `@ANCESTVAL` doesn't require dimension specification | Use `@MDANCESTVAL` for explicit dimension control |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ANCESTVAL`](./@ANCESTVAL.md) | Single-dimension ancestor value |
| [`@MDPARENTVAL`](./@MDPARENTVAL.md) | Multi-dimensional parent value (one level up only) |
| [`@PARENTVAL`](./@PARENTVAL.md) | Parent value — one level up |
| [`@SANCESTVAL`](./@SANCESTVAL.md) | Ancestor value in sparse dimension context |
| [`@ANCEST`](../04_Member_Navigation/@ANCEST.md) | Returns the ancestor member (not its value) |
| [`@GEN`](../04_Member_Navigation/@GEN.md) | Returns the generation number of a member |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MDANCESTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mdancestval.html)
- [Oracle Essbase Technical Reference — @MDANCESTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
