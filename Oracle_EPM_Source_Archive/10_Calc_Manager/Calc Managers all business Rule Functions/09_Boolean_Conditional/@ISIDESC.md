# @ISIDESC

## Overview

`@ISIDESC` (Inclusive Is Descendant) is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated is a descendant (child, grandchild) of a specified parent member, **OR if it is that exact parent member itself**. It returns `TRUE` or `FALSE`.

### Why Does This Function Exist—

Standard `@ISDESC` returns `FALSE` if it evaluates the actual parent node. If you want a calculation to fire for a whole branch of a hierarchy *including the top-level parent of that branch*, you would normally have to write:
`IF(@ISDESC("North_America") OR @ISMBR("North_America"))`

`@ISIDESC` combines these two checks into a single, natively optimized function. 

### When to Use It

- Inside `IF` statements to route logic for an entire branch of a hierarchy, top to bottom.
- When applying a global assumption or driver that should mathematically hit both the base members and the parent (in cases where the parent does not naturally aggregate).
- As a faster, cleaner alternative to an `OR` statement combining `@ISDESC` and `@ISMBR`.

---

## Category

**Logical / Boolean / Hierarchy Context**

---

## Syntax

```essbase
@ISIDESC(mbrName)
```

### Formal Syntax

```
@ISIDESC(memberExpression)
```

Where:
- `memberExpression` — The specific parent member you are testing the current context against.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target parent. The function asks: "Is the current member a descendant of, or equal to, this `mbrName`— |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member is a child, grandchild, etc. of `mbrName` | `TRUE` (1) |
| Current member is exactly `mbrName` | `TRUE` (1) *(Difference from @ISDESC)* |
| Current member is not in that branch of the tree | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current cell being evaluated.
2. **Identity Check**: It first checks if the current member is exactly `mbrName`. If yes, returns `TRUE`.
3. **Hierarchy Trace**: If no, it traces the ancestry of the current member upward. If it encounters `mbrName` at any point, it returns `TRUE`.
4. **Efficiency**: Because this is a single C-level function call in the Essbase engine, it evaluates slightly faster than `A OR B` logic.

---

## Syntax Variants & Scenarios

### Variant 1: Routing Logic for a Full Branch

```essbase
IF(@ISIDESC("Total_Marketing"))
    /* Executes for Total_Marketing and all departments under it */
ENDIF
```

---

## Practical Examples

### Example 1: Global Data Clearing

**Scenario**: You want to clear a specific slice of the database (e.g., a discontinued product line) across all levels. Because parents can hold manual adjustments (Top-Side entries) that don't roll up from base, you must clear the parent as well as the children.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Product"))
    
    /* If the current product is anywhere in the Discontinued branch, including the root */
    IF(@ISIDESC("Discontinued_Products"))
        "Revenue" = #MISSING;
    ENDIF
    
ENDFIX
```
*(Note: For simple clearing, `FIX(@IDESCENDANTS("Discontinued_Products")) CLEARDATA;` is better, but `IF` logic is required if the clearing condition is based on complex intersection data).*

---

### Example 2: Setting Flags on an Entire Hierarchy

**Scenario**: You want to flag every account in the "Non_Operating" branch so that downstream reporting tools know to exclude them from operating metrics, regardless of whether they are parents or base accounts.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Account"))
    
    IF(@ISIDESC("Non_Operating_Income"))
        "Operating_Flag" = 0;
    ELSE
        "Operating_Flag" = 1;
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Overusing it to protect parents | If you want to protect a parent from being overwritten, `IF(@ISIDESC(...))` will *target* the parent, which is the opposite of protection | Use `IF(@ISDESC(...))` if you want to skip the parent and only target the children |
| Using for `FIX` statements | `FIX(@ISIDESC("Q1"))` is invalid syntax | Use `@IDESCENDANTS("Q1")` for `FIX` blocks. Use `@ISIDESC` only in `IF` statements |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISDESC`](./@ISDESC.md) | The *Exclusive* version. Returns FALSE for the parent member itself |
| [`@IDESCENDANTS`](./@IDESCENDANTS.md) | Returns the *list* of members (used in FIX blocks) |
| [`@ISIANC`](./@ISIANC.md) | The reverse check (Is the current member an ancestor of, or equal to, X—) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISIDESC](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isidesc.html)
