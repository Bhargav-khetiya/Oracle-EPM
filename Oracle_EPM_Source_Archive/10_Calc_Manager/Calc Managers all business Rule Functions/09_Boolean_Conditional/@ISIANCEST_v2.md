# @ISIANCEST

## Overview

`@ISIANCEST` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member and returns `TRUE` or `FALSE` based on whether the current member is an **Ancestor** (parent, grandparent, root) of a specified target member, **OR if it is the target member itself.**

*(The "I" stands for Inclusive).*

### Why Does This Function Exist?

When building hierarchical algorithms, you often need to execute identical logic on an entire vertical branch of a tree, starting from a base input node and working all the way up to the top.
If a user inputs data at `"Store_101"`, you might need to trigger a custom scaling factor on the Store, the District, the Region, and the Total Company. 
If you use the native `@ISANCEST("Store_101")` function, it will trigger on the District, Region, and Company, but it will skip the Store (because you cannot be your own ancestor). To trigger the Store as well, you would have to write a cumbersome `OR` statement: `IF(@ISANCEST("Store_101") OR @ISMBR("Store_101"))`.
`@ISIANCEST` natively fuses these checks together. It evaluates the entire lineage inclusively, returning `TRUE` for the entire vertical slice of the outline.

### When to Use It

- **Vertical Overrides**: Applying a specific mathematical override to an entire vertical lineage path (from the base input up to the global total) to force a custom aggregation behavior.
- **Top-Down Security Checks**: Validating that the current calculating member resides anywhere within the direct lineage of a protected base member before allowing data manipulation.
- **Custom Auditing**: Flagging a boolean "Modified" tracking account to `1` for a specific Store and all of its parent holding companies to alert the system that the branch has been altered.

---

## Category

**Boolean & Conditional / Hierarchy Relationships / Essbase Native Functions**

---

## Syntax

```essbase
@ISIANCEST(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member that serves as the bottom anchor. The function checks if the *current* block being calculated is an ancestor of this target, or if it IS this target. |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the currently calculating member is an ancestor of the `MemberName` OR is identical to the `MemberName`. Returns `FALSE` (0) otherwise.
- **Inclusive Behavior**: Unlike `@ISANCEST`, if the engine is calculating `"Store_101"` and you use `@ISIANCEST("Store_101")`, it will return `TRUE`.
- **Directionality**: This function always looks DOWN from the current block to see if the target is below it (or equal to it).

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the `IF(@ISIANCEST(...))` block during a calculation sweep.
2. **Context Query**: It identifies the specific member it is currently calculating.
3. **Equality Check**: It first checks if the current member is exactly identical to the `MemberName` parameter. If yes, it immediately returns `TRUE`.
4. **Outline Trace**: If not identical, it locates the target `MemberName` in the `.otl` outline and begins climbing upward (checking parents).
5. **Match Evaluation**: If it hits the current calculating member during its upward climb, it returns `TRUE`.
6. **Fail State**: If it hits the root of the dimension without finding a match, it returns `FALSE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking Inclusive Ancestry

```essbase
/* 
   If the engine is currently calculating "Store_101", Returns TRUE.
   If the engine is currently calculating "New_York" (Parent), Returns TRUE.
   If the engine is currently calculating "Boston", Returns FALSE.
*/
IF(@ISIANCEST("Store_101"))
```

---

## Practical Examples

### Example 1: Tagging a Modified Branch

**Scenario**: A massive global model aggregates nightly. However, a user can trigger an "On-Demand Adjust" script for a specific Store (passed as a runtime prompt). To save time, the script shouldn't re-aggregate the entire world; it should only aggregate the exact lineage above that Store. The script uses `@ISIANCEST` to write a `1` into a `"Needs_Aggregation"` tracking account exclusively for that Store and its direct parents.

```essbase
/* 
   1. The FIX sweeps across ALL entities globally.
*/
FIX("FY25", "Working", @IDESCENDANTS("Total_Global"))
    
    /* 
       2. Check if the current entity is in the direct, inclusive lineage 
       of the specific Store that was adjusted.
       (e.g., Store_101, New_York, East_Region, USA, Total_Global)
    */
    IF(@ISIANCEST({Adjusted_Store}))
        
        /* 
           3. Flag this specific member as needing aggregation.
           This flag can be used by a subsequent script to run a highly 
           targeted partial aggregation.
        */
        "Needs_Aggregation" = 1;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `IF` inside a massive `FIX` | Performance Bottleneck | If you put `IF(@ISIANCEST("Target"))` inside a `FIX` covering 100,000 members, Essbase has to perform 100,000 outline traces. It is almost always exponentially faster to use the member selection equivalent in the `FIX` statement itself: `FIX(@IALLANCESTORS("Target"))`. Only use the boolean `IF` version when you are forced to branch logic inside an already constrained `FIX` block |
| Backward Logic | `IF(@ISIANCEST("Parent"))` | The parameter must be the member at the BOTTOM of the desired lineage. The function asks "Am I an ancestor of the target?" If you put the Parent in the parameter, and the engine calculates the Child, it asks "Am I an ancestor of my Parent?", returning `FALSE`. If you want to check if the current member rolls up to a parent, use `@ISIDESC` |
| Confusing with Siblings | "Give me the uncles" | Ancestor checks strictly trace the direct vertical bloodline. They do not trace horizontally. If you are calculating `"Store_102"` (a sibling of `"Store_101"`), `@ISIANCEST("Store_101")` will return `FALSE`. It only returns `TRUE` for the shared parent |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISANCEST`](./@ISANCEST.md) | The non-inclusive version. Checks the lineage, but strictly returns `FALSE` when evaluating the target member itself |
| [`@ISIDESC`](./@ISIDESC.md) | The exact opposite inclusive logic. Returns `TRUE` if the current member is a descendant of the target OR is the target |
| [`@IALLANCESTORS`](../04_Member_Navigation/@IALLANCESTORS.md) | The member selection array version (used in `FIX` blocks) rather than the boolean version (used in `IF` blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISIANCEST](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isiancest.html)
