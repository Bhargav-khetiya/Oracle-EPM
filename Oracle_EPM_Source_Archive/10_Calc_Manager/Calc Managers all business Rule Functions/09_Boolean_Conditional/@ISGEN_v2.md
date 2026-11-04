# @ISGEN

## Overview

`@ISGEN` is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether a specified member (or the current member of a dimension) belongs to a specific hierarchical Generation (counted from the top down). It returns `TRUE` or `FALSE`.

### Why Does This Function Exist—

While `@ISLEV` checks depth from the bottom up, `@ISGEN` checks depth from the top down.
In unbalanced hierarchies (where some branches go deeper than others), Level 1 might be a Country in one branch and a State in another. However, Generation 2 might be definitively designed to *always* be a Country across the entire dimension.
`@ISGEN` allows you to apply conditional logic horizontally across a dimension, ensuring you are targeting the correct conceptual tier regardless of how deep the branches go below it.

### When to Use It

- Inside `IF` statements to route logic based on a member's specific tier in an unbalanced hierarchy.
- To execute specific calculation logic only for top-level or mid-level parents (e.g., executing elimination logic only at Gen 2).

---

## Category

**Logical / Boolean / Hierarchy Context**

---

## Syntax

```essbase
@ISGEN(dimName, genNum | genName)
```

### Formal Syntax

```
@ISGEN(dimensionName, generationParameter)
```

Where:
- `dimensionName` — The dimension you are evaluating.
- `generationParameter` — The integer or string name representing the generation (e.g., `2` or `"Region"`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension | ✅ Yes | The name of the dimension to check (must be a string or member reference). |
| `genNum` | Integer/String| ✅ Yes | The generation to check against. **1** is the absolute root of the dimension. **2** is the immediate children of the root. |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member of `dimName` is exactly at the specified Generation | `TRUE` (1) |
| Current member is at any other generation | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current intersection being calculated.
2. **Dimension Targeting**: It identifies the member belonging to the `dimName` specified.
3. **Generation Verification**: It traces the path from the absolute root of the dimension down to the current member. If the number of steps matches `genNum`, it returns `TRUE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking for Generation 2 (Often the main Rollups)

```essbase
IF(@ISGEN("Entity", 2))
    /* Execute regional adjustment logic */
ENDIF
```

### Variant 2: Using Named Generations

```essbase
IF(@ISGEN("Product", "Category"))
    /* Executes if the current product is at the 'Category' generation */
ENDIF
```

---

## Practical Examples

### Example 1: Standardized Top-Down Assumptions in an Unbalanced Outline

**Scenario**: You have an Entity hierarchy where `Gen 1 = Total Global`, `Gen 2 = Region`, `Gen 3 = Country`. Some countries have states/cities below them, some do not. You want to apply a corporate tax rate assumption stored at the Country level, but you must ensure the calculation only fires exactly at the Country tier (Gen 3).

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Global"))
    
    /* We only want to calculate the Tax Provision at exactly the Country level */
    IF(@ISGEN("Entity", 3))
        /* Assuming 'Tax_Rate' is input at Gen 3 */
        IF("Tax_Rate" > 0)
            "Tax_Provision" = "PreTax_Income" * "Tax_Rate";
        ENDIF
    ENDIF
    
ENDFIX
```

---

### Example 2: Avoiding Root Node Overwrites

**Scenario**: You want to push a top-side adjustment to all parents, but you do *not* want to push it to the absolute root of the dimension (Gen 1) because the root is fed from a different cube.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Cost Centers"))
    /* Exclude Level 0 (base) and Gen 1 (Root) */
    IF(NOT @ISLEV("Cost_Center", 0) AND NOT @ISGEN("Cost_Center", 1))
        "Management_Adj" = 50000;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for `FIX` statements | `FIX(@ISGEN("Entity", 2))` is invalid syntax | Use `@GENMBRS("Entity", 2)` or `@RELATIVE("Entity", ...)` for `FIX` blocks. Use `@ISGEN` only in `IF` statements |
| Generation 0 | `@ISGEN("Entity", 0)` is invalid | Generations start at 1 (Top). Levels start at 0 (Bottom) |
| Shared Members | The Generation of a shared member is based on its placement in the shared branch, not its primary branch | Be aware of which branch your script is evaluating |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@GEN`](../04_Member_Navigation/@GEN.md) | Returns the integer generation number (useful for `>` or `<` comparisons) |
| [`@ISLEV`](./@ISLEV.md) | Checks if a member is at a specific bottom-up Level |
| [`@GENMBRS`](../04_Member_Navigation/@GENMBRS.md) | Returns the *list* of members at a generation (used in FIX blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISGEN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isgen.html)
