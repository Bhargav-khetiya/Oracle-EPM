# @LEV

## Overview

`@LEV` is a **hierarchy context function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It returns the integer level number of a specified member within its dimension.

### Why Does This Function Exist?

In Essbase, hierarchies are structured with **Levels** (counting from the bottom up, where 0 is a leaf node) and **Generations** (counting from the top down, where 1 is the root).
Many conditional calculations depend on knowing how deep in the hierarchy a member sits:
- "If this is a Level 0 member, calculate A * B."
- "If this is a parent (Level > 0), don't overwrite its aggregated value."
- Dynamically passing the level integer into other functions like `@ANCEST`.

While `@ISLEV` checks if a member is at a *specific* level, `@LEV` simply returns the *actual number* so you can use it mathematically or dynamically.

### When to Use It

- Inside `IF` statements to route logic based on hierarchical depth (e.g., `IF(@LEV(@CURRMBR("Entity")) > 1)`).
- When you need to pass an integer representing the current level into another function dynamically.
- To protect upper-level parent data from being overwritten by base-level driver calculations.

---

## Category

**Hierarchy / Member Context**

---

## Syntax

```essbase
@LEV(dimName, mbrName)
```

### Formal Syntax

```
@LEV(dimensionName, memberExpression)
```

Where:
- `dimensionName` — The dimension the member belongs to.
- `memberExpression` — The specific member you are checking (usually `@CURRMBR("Dimension")`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension | ✅ Yes | The dimension to check (must be a string or member reference). |
| `mbrName` | Member | ✅ Yes | The member whose level you want to find. |

---

## Return Value

**Return Type**: Integer

Returns the level number of the member.
- **Level 0**: A base member with no children.
- **Level 1**: A parent whose lowest descendant is 1 step away (immediate parent of Level 0).
- **Level N**: A higher-level parent. In unbalanced hierarchies, a parent's level is determined by its longest path to a Level 0 descendant.

---

## How It Works (Behind the Scenes)

1. **Context Lookup**: Essbase queries the outline metadata for `mbrName`.
2. **Bottom-Up Count**: It calculates the longest path from `mbrName` down to its lowest leaf descendant.
3. **Integer Return**: It returns that count as an integer, allowing you to use it in mathematical comparisons (`>`, `<`, `==`).

---

## Syntax Variants & Scenarios

### Variant 1: Checking the Current Member

```essbase
IF(@LEV("Entity", @CURRMBR("Entity")) == 0)
    /* Do something at Level 0 */
ENDIF
```
*(Note: `@ISLEV("Entity", 0)` is a cleaner, more efficient way to write this exact check).*

### Variant 2: Greater-Than Comparisons

```essbase
IF(@LEV("Product", @CURRMBR("Product")) > 1)
    /* Do something only for grandparents and higher */
ENDIF
```

---

## Practical Examples

### Example 1: Protecting Parent Data from Allocation Overwrites

**Scenario**: You are running an allocation that pushes data into various products. You want to ensure you only write to Level 0 products, and you want to throw an alert/flag if the script somehow targets a parent.

```essbase
FIX("FY25", "Working")
    /* We are looping through all products */
    FIX(@DESCENDANTS("Total Product"))
        
        VAR vCurrentLevel = @LEV("Product", @CURRMBR("Product"));
        
        IF(vCurrentLevel == 0)
            /* Safe to allocate */
            "Allocated_Expense" = "Corporate_Pool" * "Share_Pct";
        ELSE
            /* Do not write expense. Flag that a parent was targeted */
            "Allocation_Error_Flag" = 1;
        ENDIF
        
    ENDFIX
ENDFIX
```

---

### Example 2: Dynamic Ancestor Retrieval

**Scenario**: You need to pull the value from an ancestor that is exactly 2 levels higher than the current member, regardless of whether the current member is at Level 0, 1, or 2.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    /* Find current level */
    VAR vMyLevel = @LEV("Entity", @CURRMBR("Entity"));
    
    /* Calculate target level (2 steps up) */
    VAR vTargetLevel = vMyLevel + 2;
    
    /* Fetch the value from that dynamic level */
    "Ancestor_Value" = @ANCESTVAL("Entity", vTargetLevel, "Revenue");
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `@LEV` for simple equality checks | `IF(@LEV("Entity", @CURRMBR("Entity")) == 0)` forces the engine to calculate an integer and compare it | Use `IF(@ISLEV("Entity", 0))` which evaluates as a native Boolean much faster |
| Unbalanced Hierarchies | In an unbalanced hierarchy, two members that seem like peers might have different Levels because their children go down to different depths | Use `@GEN` (Generations) if you want to ensure peers align perfectly top-down |
| Missing Dimension | `@LEV(@CURRMBR("Entity"))` is invalid | You must provide the dimension name as the first argument |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISLEV`](./@ISLEV.md) | The Boolean equivalent for testing if a member is at a specific level (Faster for `IF` statements) |
| [`@GEN`](./@GEN.md) | Returns the top-down Generation number instead of the bottom-up Level number |
| [`@CURRLEV`](./@CURRLEV.md) | Specifically returns the level of the *current* member without needing the `mbrName` argument |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @LEV](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/lev.html)
