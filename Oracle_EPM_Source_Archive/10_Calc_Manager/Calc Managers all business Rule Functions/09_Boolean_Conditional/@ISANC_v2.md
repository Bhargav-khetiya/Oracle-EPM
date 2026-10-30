# @ISANC

## Overview

`@ISANC` (Is Ancestor) is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated is an ancestor (parent, grandparent, etc.) of a specified target member. It returns `TRUE` or `FALSE`.

### Why Does This Function Exist?

Usually, calculations flow top-down (e.g., `@ISDESC` asks "Am I under this parent?"). `@ISANC` reverses the perspective. It asks: "Am I *above* this child?"
- You might be looping through a list of parent entities and want to skip calculations on any parent that does not roll up a specific flagship store.
- You want to apply specific logic only to the direct lineage of a specific node.

### When to Use It

- Inside `IF` statements to route logic based on bottom-up ancestry.
- When applying logic to the lineage of a node without explicitly knowing the names of the parents.
- To execute targeted partial aggregations logically (though `FIX(@ANCESTORS)` is generally preferred for block-level performance).

---

## Category

**Logical / Boolean / Hierarchy Context**

---

## Syntax

```essbase
@ISANC(mbrName)
```

### Formal Syntax

```
@ISANC(memberExpression)
```

Where:
- `memberExpression` — The specific descendant member you are testing the current context against.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target descendant. The function asks: "Is the current member an ancestor of this `mbrName`?" |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member is a parent, grandparent, etc. of `mbrName` | `TRUE` (1) |
| Current member is exactly `mbrName` | `FALSE` (0) *(Unlike @ISIANC)* |
| Current member is outside the direct upward lineage | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current cell being evaluated.
2. **Hierarchy Trace**: It traces the ancestry of the *provided* `mbrName` upward toward the root.
3. **Comparison**: If it encounters the *current member* at any point in that upward trace, it returns `TRUE`.
4. **Exclusivity**: `@ISANC` is *exclusive*. It does not return true if the current member is the exact `mbrName` itself.

---

## Syntax Variants & Scenarios

### Variant 1: Lineage Check

```essbase
IF(@ISANC("Store_101"))
    /* Executes if current member is NY_Region, USA, or Total_Entity */
ENDIF
```

---

## Practical Examples

### Example 1: Tagging the Lineage of a Reorganized Node

**Scenario**: A specific cost center (`CC_Legal`) has been moved to a new division. You need to run a calculation that flags every parent above it so that a downstream system knows to re-aggregate those specific parents.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Cost Center"))
    
    /* If the current member sits anywhere above CC_Legal */
    IF(@ISANC("CC_Legal"))
        "Requires_Reagg_Flag" = 1;
    ENDIF
    
ENDFIX
```

---

### Example 2: Selective Parent Calculation

**Scenario**: You are calculating a custom KPI ("Regional Profitability Score") that is mathematically complex and only needs to be run on parents that contain "Retail" stores. You don't want to waste time calculating it for Wholesale branches.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Geography"))
    
    /* Ensure we are on a parent */
    IF(NOT @ISLEV("Entity", 0))
        /* Check if this parent has the flagship Retail store anywhere below it.
           (In reality, you might check a UDA on the children, but this shows ISANC logic) */
        IF(@ISANC("Flagship_Retail_NY"))
            "Regional_Score" = "Profit" / "Square_Footage";
        ENDIF
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for `FIX` statements | `FIX(@ISANC("Store"))` is invalid syntax | Use `@ANCESTORS("Store")` for `FIX` blocks. Use `@ISANC` only in `IF` statements |
| Expecting TRUE on the Child | `IF(@ISANC("Store"))` will return FALSE when calculating "Store" itself | Use `@ISIANC("Store")` (Inclusive) if you want it to return TRUE for the base member as well |
| Performance | Checking ancestry dynamically inside a massive `IF` loop across all parents can be slower than just using `FIX(@ANCESTORS(...))` | Isolate calculation blocks via `FIX` whenever possible rather than using cell-level `IF` routing |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISIANC`](./@ISIANC.md) | The *Inclusive* version. Returns TRUE for the base member as well as its ancestors |
| [`@ANCESTORS`](../04_Member_Navigation/@ANCESTORS.md) | Returns the *list* of ancestors (used in FIX blocks) |
| [`@ISDESC`](./@ISDESC.md) | The reverse check (Is the current member a descendant of X?) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISANC](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isanc.html)
