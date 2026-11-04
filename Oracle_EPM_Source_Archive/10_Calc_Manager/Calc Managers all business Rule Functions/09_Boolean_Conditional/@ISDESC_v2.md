# @ISDESC

## Overview

`@ISDESC` is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated is a descendant (child, grandchild, etc.) of a specified parent member. It returns `TRUE` or `FALSE`.

### Why Does This Function Exist—

While `FIX(@DESCENDANTS("Parent"))` isolates a calculation block to a specific branch of the hierarchy, there are times when you need branching logic *within* a broader calculation.
- You have a global `FIX` on "Total Entity", but you want to apply a 10% uplift to Europe and a 5% uplift to North America.
- You need to ensure a specific calculation only runs for descendants of a node, but ignores the node itself (to avoid overwriting an aggregated total).

`@ISDESC` allows you to dynamically test if the current cell belongs to a specific family tree.

### When to Use It

- Inside `IF` statements to route logic based on hierarchy branch (e.g., "Is this entity anywhere under 'Total_Europe'—).
- To protect parent members from being overwritten by base-level logic by ensuring the calculation only targets descendants.
- As a faster, natively optimized alternative to `IF(@ISMBR(@DESCENDANTS("Parent")))`.

---

## Category

**Logical / Boolean / Hierarchy Context**

---

## Syntax

```essbase
@ISDESC(mbrName)
```

### Formal Syntax

```
@ISDESC(memberExpression)
```

Where:
- `memberExpression` — The specific parent member you are testing the current context against.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target parent. The function asks: "Is the current member a descendant of this `mbrName`— |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member is a child, grandchild, etc. of `mbrName` | `TRUE` (1) |
| Current member is exactly `mbrName` | `FALSE` (0) *(Unlike @ISIDESC)* |
| Current member is not in that branch of the tree | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current cell being evaluated.
2. **Hierarchy Trace**: It traces the ancestry of the current member upward toward the root.
3. **Comparison**: If it encounters `mbrName` at any point in that upward trace, the current member is a descendant, and it returns `TRUE`.
4. **Exclusivity**: `@ISDESC` is *exclusive*. It does not return true for the parent member itself.

---

## Syntax Variants & Scenarios

### Variant 1: Routing Logic by Region

```essbase
IF(@ISDESC("North_America"))
    /* Executes for USA, Canada, NY, Toronto, etc. */
ENDIF
```

### Variant 2: Combining with Level Checks

```essbase
IF(@ISDESC("Total_Products") AND @ISLEV("Product", 0))
    /* Executes only for base-level leaf nodes under Total_Products */
ENDIF
```

---

## Practical Examples

### Example 1: Differential Tax Rates by Global Region

**Scenario**: You are running a global calculation block. Different regional branches have different baseline tax assumptions.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("PreTax_Income" > 0)
        /* Route the logic based on ancestry */
        IF(@ISDESC("North_America"))
            "Tax_Expense" = "PreTax_Income" * 0.25;
        ELSEIF(@ISDESC("Europe"))
            "Tax_Expense" = "PreTax_Income" * 0.20;
        ELSEIF(@ISDESC("APAC"))
            "Tax_Expense" = "PreTax_Income" * 0.15;
        ELSE
            "Tax_Expense" = "PreTax_Income" * 0.30; /* Default */
        ENDIF
    ENDIF
    
ENDFIX
```

---

### Example 2: Data Validation / Error Flagging

**Scenario**: Users sometimes incorrectly book manual journal adjustments to historical or closed nodes. You want to flag any data sitting under the "Closed_Entities" hierarchy.

```essbase
FIX("FY25", "Actual", @DESCENDANTS("Total Entity"))
    
    /* If data exists and it's under the closed node */
    IF("Manual_Adj" != #MISSING AND @ISDESC("Closed_Entities"))
        "Audit_Flag" = 1;
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for `FIX` statements | `FIX(@ISDESC("Q1"))` is invalid syntax | Use `@DESCENDANTS("Q1")` for `FIX` blocks. Use `@ISDESC` only in `IF` statements |
| Expecting TRUE on the Parent | `IF(@ISDESC("Total_Sales"))` will return FALSE when calculating "Total_Sales" itself | Use `@ISIDESC("Total_Sales")` (Inclusive) if you want it to return TRUE for the parent as well |
| Using `@ISMBR(@DESCENDANTS(x))` | While functionally identical, `@ISMBR(@DESCENDANTS("North_America"))` is slightly slower because it generates the full list first | Use `@ISDESC("North_America")` for optimized Boolean logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISIDESC`](./@ISIDESC.md) | The *Inclusive* version. Returns TRUE for the parent member as well as the descendants |
| [`@DESCENDANTS`](../04_Member_Navigation/@DESCENDANTS.md) | Returns the *list* of descendants (used in FIX blocks) |
| [`@ISANC`](./@ISANC.md) | The reverse check (Is the current member an ancestor of X—) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISDESC](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isdesc.html)
