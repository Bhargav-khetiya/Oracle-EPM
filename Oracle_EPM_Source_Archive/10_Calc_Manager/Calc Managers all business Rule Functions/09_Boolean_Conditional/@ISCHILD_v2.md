# @ISCHILD

## Overview

`@ISCHILD` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member and returns `TRUE` or `FALSE` based on whether the current member is an **Immediate Child** (exactly one generation below) of a specified target parent member.

### Why Does This Function Exist—

When building hierarchical conditional logic, administrators often need precise control over which tier of a dimension receives an allocation or mathematical override.
If you are iterating through all regions and stores in a massive outline, and you want to apply a 5% bonus specifically to the immediate regional managers reporting directly to the `"Global_CEO"`, you need a way to identify them. 
If you use `@ISDESC("Global_CEO")`, you will accidentally apply the bonus to the managers, the store directors, and the base cashiers, because they are all descendants. 
`@ISCHILD("Global_CEO")` solves this by natively querying the outline and enforcing a strict, 1-generation boundary constraint. It checks if the currently calculating member rolls up *directly* to the target parent. If there is even one intermediate level between them (making it a grandchild), the function returns `FALSE`.

### When to Use It

- **Direct-Report Allocations**: Distributing a corporate overhead pool strictly to the immediate Vice Presidents (first-generation children of the President), ignoring the lower-level cost centers.
- **Hierarchical Math Overrides**: Applying a specific driver rate only to a specific tier in a ragged hierarchy.
- **Reporting Validation**: Ensuring that an aggregated data point only pulls from direct, first-level components rather than deeply nested leaf nodes.

---

## Category

**Boolean & Conditional / Hierarchy Relationships / Essbase Native Functions**

---

## Syntax

```essbase
@ISCHILD(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target parent member. The function checks if the *current* block being calculated is a direct child of this specific parent. |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the currently calculating member is an immediate, first-generation child of the `MemberName`. Returns `FALSE` (0) if it is not.
- **Non-Inclusive**: If the engine is currently calculating the target parent itself (e.g., evaluating `"Total_Company"`, and checking `@ISCHILD("Total_Company")`), it returns `FALSE`. You cannot be your own child. If you want inclusive logic, you must use `@ISICHILD`.
- **Grandchildren Excluded**: As stated, this is strictly a 1-generation check. Grandchildren return `FALSE`.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the `IF(@ISCHILD(...))` block during a calculation pass.
2. **Context Query**: It identifies the specific member it is currently calculating (e.g., `"North_America"`).
3. **Outline Trace**: It queries the active `.otl` outline. It looks at the current member and immediately asks: "Who is my direct parent—
4. **Match Evaluation**: It compares the direct parent it found against the `MemberName` provided in the parameter. 
5. **Return**: If they match perfectly, it returns `TRUE`. If they do not match, it returns `FALSE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking Immediate Parentage

```essbase
/* 
   If the engine is currently calculating "Marketing", 
   and "Marketing" rolls directly into "Total_OpEx".
   Returns TRUE.
*/
IF(@ISCHILD("Total_OpEx"))
```

---

## Practical Examples

### Example 1: Direct-Report Bonus Distribution

**Scenario**: The `"Global_Sales"` division has received a `"Quarterly_Bonus_Pool"` of `$500,000`. The CFO wants to distribute this pool evenly, but ONLY to the immediate Regional Directors that report directly to `"Global_Sales"`. The bonus should NOT be pushed down to the individual stores beneath those directors. 

```essbase
/* 
   1. The FIX sweeps across ALL Descendants of Global_Sales to ensure 
   we have access to the entire branch.
*/
FIX("FY25", "Working", @DESCENDANTS("Global_Sales"))
    
    /* 
       2. As the engine evaluates each entity, it checks its direct parent.
       - If evaluating a Store (grandchild), it returns FALSE.
       - If evaluating a Regional Director (direct child), it returns TRUE.
    */
    IF(@ISCHILD("Global_Sales"))
        
        /* 
           3. Distribute the bonus ONLY to these direct children.
           (Assuming we already calculated how many children exist).
        */
        "Allocated_Bonus" = "Quarterly_Bonus_Pool"->"Global_Sales" / "Total_Directors"->"Global_Sales";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it for Base Level Checks | `IF(@ISCHILD("Total"))` | Sometimes developers use `@ISCHILD` thinking it means "Is this a child/leaf node—. That is incorrect. `@ISCHILD` checks if it is a child *of a specific parent*. A child of a high-level parent could still have 50 descendants beneath it. If you want to check if a member is at the absolute bottom of the outline (a leaf node), you MUST use `@ISLEV(Dimension, 0)` or `@ISMBR(@LEVEL0("Dim"))` |
| Backward Logic | `IF(@ISCHILD("Store"))` | The parameter is the PARENT. The function asks: "Is the current member a child of the parameter— If you put a Level-0 Store in the parameter, it will always return `FALSE`, because leaf nodes have no children. Ensure you are passing the parent |
| Confusing with `@ISDESC` | Missing the Grandchildren | If you write an allocation rule using `@ISCHILD("USA")`, it will hit `"New_York"`, but it will COMPLETELY IGNORE `"NYC_Store_01"`. If your intent was to allocate to the entire branch (everyone underneath the parent), you must use `@ISDESC("USA")` (Is Descendant) instead of `ISCHILD` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISICHILD`](./@ISICHILD.md) | The inclusive version. Returns `TRUE` if the current member is a direct child of the target OR if it IS the exact target parent itself |
| [`@ISDESC`](./@ISDESC.md) | The deep-traversal version. Returns `TRUE` for direct children, grandchildren, and all subsequent generations below the parent |
| [`@CHILDREN`](../04_Member_Navigation/@CHILDREN.md) | The member selection version (used in `FIX` blocks) rather than the boolean version (used in `IF` blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISCHILD](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ischild.html)
