# @ISIANC

## Overview

`@ISIANC` (Inclusive Is Ancestor) is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated is an ancestor (parent, grandparent, etc.) of a specified target member, **OR if it is that exact target member itself**. It returns `TRUE` or `FALSE`.

### Why Does This Function Exist—

Standard `@ISANC` returns `FALSE` if it evaluates the actual target node. If you want a calculation to fire for a specific branch of a hierarchy from the bottom *all the way to the top*, you would normally have to write:
`IF(@ISANC("Store_101") OR @ISMBR("Store_101"))`

`@ISIANC` combines these two checks into a single, natively optimized function. 

### When to Use It

- Inside `IF` statements to route logic for the direct upward lineage of a specific node, including the node itself.
- When rolling up data or flags from a single base member all the way to the root dimension in a custom calculation loop.
- As a faster, cleaner alternative to an `OR` statement combining `@ISANC` and `@ISMBR`.

---

## Category

**Logical / Boolean / Hierarchy Context**

---

## Syntax

```essbase
@ISIANC(mbrName)
```

### Formal Syntax

```
@ISIANC(memberExpression)
```

Where:
- `memberExpression` — The specific descendant member you are testing the current context against.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target descendant. The function asks: "Is the current member an ancestor of, or equal to, this `mbrName`— |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member is a parent, grandparent, etc. of `mbrName` | `TRUE` (1) |
| Current member is exactly `mbrName` | `TRUE` (1) *(Difference from @ISANC)* |
| Current member is outside the direct upward lineage | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current cell being evaluated.
2. **Identity Check**: It first checks if the current member is exactly `mbrName`. If yes, returns `TRUE`.
3. **Hierarchy Trace**: If no, it traces the ancestry of `mbrName` upward. If it encounters the current member at any point, it returns `TRUE`.
4. **Efficiency**: Because this is a single C-level function call in the Essbase engine, it evaluates slightly faster than `A OR B` logic.

---

## Syntax Variants & Scenarios

### Variant 1: Routing Logic for a Full Upward Branch

```essbase
IF(@ISIANC("Store_101"))
    /* Executes for Store_101, NY_Region, USA, and Total_Entity */
ENDIF
```

---

## Practical Examples

### Example 1: Wiping a Specific Branch (Including the Leaf Node)

**Scenario**: A division ("Wholesale") was reorganized and its historical budget data needs to be wiped clean from the base level all the way to the top of its specific branch, without clearing the "Retail" division.

```essbase
FIX("FY25", "Budget", @DESCENDANTS("Total Entity"))
    
    /* If the current member is Wholesale, or any parent above it */
    IF(@ISIANC("Div_Wholesale"))
        "Total_Expenses" = #MISSING;
    ENDIF
    
ENDFIX
```
*(Note: For simple clearing, `FIX(@IANCESTORS("Div_Wholesale")) CLEARDATA;` is better, but `IF` logic is required if the clearing condition is based on complex intersection data).*

---

### Example 2: Rolling Up a Status Flag

**Scenario**: If a specific critical project ("Proj_Alpha") is marked as "Delayed", you want to flag every parent portfolio above it as "At_Risk" so executive dashboards highlight the issue at the top level.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Portfolio"))
    
    /* Assume Proj_Alpha's status is evaluated elsewhere. We just want to tag the lineage. */
    IF(@ISIANC("Proj_Alpha"))
        /* Check if Alpha is delayed (assuming status is stored at the base level) */
        IF("Status" -> "Proj_Alpha" == 0)
            "Risk_Flag" = 1;
        ENDIF
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing `ISIANC` and `ISIDESC` | `@ISIANC` looks UP the tree (is current member above X). `@ISIDESC` looks DOWN the tree (is current member below X) | Ensure you know which direction your logic needs to flow |
| Using for `FIX` statements | `FIX(@ISIANC("Store"))` is invalid syntax | Use `@IANCESTORS("Store")` for `FIX` blocks. Use `@ISIANC` only in `IF` statements |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISANC`](./@ISANC.md) | The *Exclusive* version. Returns FALSE for the base member itself |
| [`@IANCESTORS`](./@IANCESTORS.md) | Returns the *list* of members (used in FIX blocks) |
| [`@ISIDESC`](./@ISIDESC.md) | The reverse check (Is the current member a descendant of, or equal to, X—) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISIANC](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isianc.html)
