# @ISLEV

## Overview

`@ISLEV` is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether a specified member (or the current member of a dimension) belongs to a specific hierarchical Level (counted from the bottom up). It returns `TRUE` or `FALSE`.

### Why Does This Function Exist?

When looping through large blocks of data in a `FIX` statement, you often want to execute mathematical logic *only* at the lowest level (Level 0) so that parents can aggregate naturally without being overridden by driver-based math. 
Alternatively, you might want to execute logic *only* on parents.
While you can use `IF(@LEV(mbr) == 0)`, `@ISLEV` is natively optimized for Boolean checks inside `IF` statements and is generally faster and cleaner to read.

### When to Use It

- Inside `IF` statements to isolate calculations to base-level members (Level 0).
- To execute specific calculation logic only for parent members (e.g., `IF(NOT @ISLEV("Entity", 0))`).
- When parsing through dynamic hierarchies where the specific member name is unknown, but its relative depth is important.

---

## Category

**Logical / Boolean / Hierarchy Context**

---

## Syntax

```essbase
@ISLEV(dimName, levelNum)
```

### Formal Syntax

```
@ISLEV(dimensionName, levelNumber)
```

Where:
- `dimensionName` — The dimension you are evaluating.
- `levelNumber` — The integer representing the level (e.g., `0` for leaf nodes).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension | ✅ Yes | The name of the dimension to check (must be a string or member reference). |
| `levelNum` | Integer | ✅ Yes | The level number to check against. **0** is always the bottom-most leaf member. Higher numbers are parents. |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member of `dimName` is exactly at `levelNum` | `TRUE` (1) |
| Current member is at any other level | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current intersection being calculated.
2. **Dimension Targeting**: It identifies the member belonging to the `dimName` specified.
3. **Level Verification**: It calculates the longest path from that member down to its lowest leaf descendant. If that path length equals `levelNum`, it returns `TRUE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking for Level 0 (Leaf Nodes)

```essbase
IF(@ISLEV("Product", 0))
    /* Execute base-level driver logic */
ENDIF
```

### Variant 2: Checking for Parent Nodes

```essbase
IF(NOT @ISLEV("Entity", 0))
    /* Execute parent-level overrides or protection logic */
ENDIF
```

---

## Practical Examples

### Example 1: Preventing Parent Overwrites (ASP Calculation)

**Scenario**: You are calculating Average Selling Price (ASP). If you calculate this at the parent level, it sums up the ASPs mathematically rather than letting the parent derive a weighted ASP. You must restrict the calc to Level 0.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Product"))
    /* If we are at the base product level */
    IF(@ISLEV("Product", 0))
        IF("Units" > 0)
            "ASP" = "Revenue" / "Units";
        ENDIF
    ENDIF
ENDFIX

/* Later, a custom aggregation script might calculate the parent ASP 
   as Parent_Revenue / Parent_Units, rather than Sum(Child_ASPs) */
```

---

### Example 2: Differentiated Commission Rates by Management Level

**Scenario**: Sales Reps (Level 0) get 10% commission. Sales Managers (Level 1) get an override pool of 2%. Regional Directors (Level 2) get 1%.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Sales Team"))
    IF(@ISLEV("Employee", 0))
        "Commission" = "Sales" * 0.10;
    ELSEIF(@ISLEV("Employee", 1))
        "Commission" = "Sales" * 0.02;
    ELSEIF(@ISLEV("Employee", 2))
        "Commission" = "Sales" * 0.01;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for `FIX` statements | `FIX(@ISLEV("Entity", 0))` is invalid syntax | Use `@LEVEL0("Entity")` or `@RELATIVE("Entity", 0)` for `FIX` blocks. Use `@ISLEV` only in `IF` statements |
| Unbalanced Hierarchies | In an unbalanced hierarchy, Level 1 might represent a Region on one branch, but a Country on another | Use `@ISGEN` if you need horizontal alignment from the top down |
| Missing Dimension | `@ISLEV(0)` is invalid | You must explicitly state which dimension: `@ISLEV("Entity", 0)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@LEV`](./@LEV.md) | Returns the integer level number (useful for `>` or `<` comparisons) |
| [`@ISGEN`](./@ISGEN.md) | Checks if a member is at a specific top-down Generation |
| [`@LEVEL0`](./@LEVEL0.md) | Returns the *list* of Level 0 members (used in FIX blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISLEV](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/islev.html)
