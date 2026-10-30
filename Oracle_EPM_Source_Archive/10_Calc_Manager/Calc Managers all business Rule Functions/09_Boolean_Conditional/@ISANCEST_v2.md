# @ISANCEST

## Overview

`@ISANCEST` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member and returns `TRUE` or `FALSE` based on whether the current member is an **Ancestor** (a parent, grandparent, or higher up to the root) of a specified target member. 
*(Crucially, it is non-inclusive; a member is not considered its own ancestor).*

### Why Does This Function Exist?

When executing recursive top-down allocations or complex `CLEARBLOCK` logic, administrators often need to know the structural relationship between the block currently being processed and another critical member in the outline. 
For example, if you are running an allocation that sweeps across the entire `"Entity"` dimension, you might want to execute a specific algorithm ONLY when the engine is actively sitting on a member that rolls up above `"Store_101"`. 
You could hardcode `IF(@ISMBR("New_York") OR @ISMBR("East_Region") OR @ISMBR("USA"))`, but that is brittle. If `"Store_101"` moves to `"Boston"`, the script breaks. `@ISANCEST("Store_101")` solves this by natively querying the outline. No matter where the script is currently calculating, it checks if that location sits directly above `"Store_101"` in the hierarchy. This allows for highly dynamic, top-down logic branching.

### When to Use It

- **Targeted Overhead Pools**: Applying an overhead distribution logic ONLY to the specific parent and grandparent holding buckets of a target entity, while ignoring other unrelated parent buckets.
- **Workflow / Status Validation**: Checking if the current aggregating parent node sits above a specific "Locked" or "Approved" base member before allowing an aggregation routine to alter its data.
- **Custom Reporting Rollups**: Branching logic during an `@CALCMODE(BOTTOMUP)` calculation to apply unique mathematical overlays specifically on the consolidation nodes of a target branch.

---

## Category

**Boolean & Conditional / Hierarchy Relationships / Essbase Native Functions**

---

## Syntax

```essbase
@ISANCEST(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member that serves as the bottom anchor. The function checks if the *current* block being calculated is an ancestor of this target. |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the currently calculating member is structurally above (an ancestor of) the `MemberName`. Returns `FALSE` (0) if it is not.
- **Non-Inclusive**: If the engine is currently calculating `"Store_101"`, and you use `@ISANCEST("Store_101")`, it returns `FALSE`. You cannot be your own ancestor. (If you want inclusive logic, use `@ISIANCEST`).
- **Directionality**: This function always looks DOWN from the current block to see if the target is below it.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the `IF(@ISANCEST(...))` block during a calculation sweep.
2. **Context Query**: It identifies the specific member it is currently calculating (e.g., `"East_Region"`).
3. **Outline Trace**: It locates the target `MemberName` in the `.otl` outline. It begins climbing the tree upward from the target.
4. **Match Evaluation**: If, during its upward climb, it bumps into the current calculating member (`"East_Region"`), it stops and returns `TRUE`.
5. **Fail State**: If it climbs all the way to the root of the dimension without encountering the current member, it returns `FALSE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking Ancestry

```essbase
/* 
   If the engine is currently calculating "USA", and "New_York" rolls up to "USA".
   Returns TRUE.
*/
IF(@ISANCEST("New_York"))
```

---

## Practical Examples

### Example 1: Isolating Parent Holding Buckets

**Scenario**: A company has a massive, ragged Entity hierarchy. A specific project (`"Proj_Alpha"`) is executed exclusively in `"Texas"`. The expenses are input at the `"Texas"` level. The administrator writes a custom consolidation script that needs to add a 5% "Management Fee" to every single parent consolidation level directly above `"Texas"` (`"South_Region"`, `"USA"`, `"Global"`), but they do not want to apply it to `"Texas"` itself, nor to unrelated regions like `"Europe"`.

```essbase
/* 
   1. The FIX sweeps across ALL Parent-level entities to ensure 
   we catch every possible consolidation node.
*/
FIX("FY25", "Working", "Proj_Alpha", @IDESCENDANTS("Global"))
    
    /* 
       2. As the engine evaluates each entity, it checks its relationship to Texas.
       - If it's evaluating "Texas", it returns FALSE.
       - If it's evaluating "Europe", it returns FALSE.
       - If it's evaluating "South_Region", it returns TRUE.
    */
    IF(@ISANCEST("Texas"))
        
        /* 
           3. Apply the 5% Management Fee ONLY to the valid ancestors.
           (Note: In reality, applying flat math to parents requires 
           careful aggregation handling, but conceptually this isolates the nodes).
        */
        "Management_Fee" = "Total_Expense" * 0.05;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Backward Logic | `IF(@ISANCEST("Parent"))` | This is the most common error. The parameter is the *target* at the bottom. The function asks: "Am I an ancestor of the target?" If you put the Parent in the parameter, and the engine is calculating a child, it asks "Am I an ancestor of my Parent?" which is logically impossible and will always return `FALSE`. If you want to check if the current member is a *child/descendant* of a parent, you MUST use `@ISDESC("Parent")` |
| Misunderstanding Inclusivity | Expecting `TRUE` on the target | `@ISANCEST` strictly evaluates parents and grandparents. If you want the logic to apply to the ancestors AND the base target itself simultaneously, you must use `@ISIANCEST` (Inclusive Ancestor) |
| Performance in Large Dimensions | Running on every block | Tracing ancestry requires traversing the outline. If you put `IF(@ISANCEST("Target"))` inside a `FIX` that touches 1,000,000 blocks, Essbase has to perform that outline trace 1,000,000 times. It is usually much faster to write the `FIX` statement as `FIX(@ANCESTORS("Target"))`, restricting the engine before it even starts calculating, rather than using `IF` logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISIANCEST`](./@ISIANCEST.md) | The inclusive version. Returns `TRUE` if the current member is an ancestor of the target OR if it IS the exact target member itself |
| [`@ISDESC`](./@ISDESC.md) | The exact opposite logic. Returns `TRUE` if the currently calculating member is a child/descendant of the specified target |
| [`@ANCESTORS`](../04_Member_Navigation/@ANCESTORS.md) | The member selection version (used in `FIX` blocks) rather than the boolean version (used in `IF` blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISANCEST](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isancest.html)
