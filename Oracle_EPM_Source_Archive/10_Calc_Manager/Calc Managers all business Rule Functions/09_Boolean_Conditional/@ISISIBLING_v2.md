# @ISISIBLING

## Overview

`@ISISIBLING` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member and returns `TRUE` or `FALSE` based on whether the current member shares the exact same direct parent as a specified target member (i.e., whether they are siblings), **OR if it is the target member itself.**

*(The first "I" stands for Inclusive, checking Is-Inclusive-Sibling).*

### Why Does This Function Exist?

When building horizontal calculations across a dimension, you often need to execute identical logic on an entire "family" of members. For example, if the script is processing an allocation that should only apply to `"Q1"` and its siblings (`"Q2"`, `"Q3"`, `"Q4"`), you need a way to branch the logic.
If you use the native `@ISSIBLING("Q1")` function, it will trigger on Q2, Q3, and Q4, but it will explicitly skip `"Q1"` (because you cannot be your own sibling). To trigger the target member as well, you would have to write a cumbersome `OR` statement: `IF(@ISSIBLING("Q1") OR @ISMBR("Q1"))`.
`@ISISIBLING` natively fuses these checks together. It evaluates the entire horizontal family inclusively, returning `TRUE` for the target member and all of its siblings in a single, clean boolean check.

### When to Use It

- **Horizontal Overrides**: Applying a specific calculation rule to an entire generational tier under a specific parent, without having to explicitly name the parent.
- **Peer Group Validations**: Ensuring that data manipulation only occurs on members that belong to the exact same peer group as a dynamically selected baseline member.
- **Custom Reporting Thresholds**: Flagging a group of members for inclusion in a report based on their sibling relationship to a user-selected target.

---

## Category

**Boolean & Conditional / Hierarchy Relationships / Essbase Native Functions**

---

## Syntax

```essbase
@ISISIBLING(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member. The function checks if the *current* block being calculated is a sibling of this specific target, or if it IS this specific target. |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the currently calculating member is a sibling of the `MemberName` OR is identical to the `MemberName`. Returns `FALSE` (0) otherwise.
- **Inclusive Behavior**: Unlike `@ISSIBLING`, if the engine is calculating `"Q1"` and you use `@ISISIBLING("Q1")`, it will return `TRUE`.
- **Cousins Excluded**: Siblings must share the *exact same direct parent*. If `"Store_A"` is in New York, and `"Store_B"` is in Boston, they are not siblings. Evaluating Store_B against Store_A will return `FALSE`.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the `IF(@ISISIBLING(...))` block during a calculation sweep.
2. **Context Query**: It identifies the specific member it is currently calculating (e.g., `"Q3"`).
3. **Equality Check**: It first checks if the current member is exactly identical to the `MemberName` parameter (e.g., `"Q1"`). If yes, it immediately returns `TRUE`.
4. **Outline Trace**: If not identical, it queries the active `.otl` outline. It looks at the current member and asks: "Who is my direct parent?"
5. **Target Trace**: It looks at the `MemberName` parameter and asks: "Who is the target's direct parent?"
6. **Match Evaluation**: It compares the two parents. If they are exactly the same member, they are siblings, and it returns `TRUE`.
7. **Fail State**: If the parents do not match, it returns `FALSE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking Inclusive Sibling Relationships

```essbase
/* 
   If Q1, Q2, Q3, and Q4 all roll up to Total_Year.
   If the engine is currently calculating "Q1" (The Target). Returns TRUE.
   If the engine is currently calculating "Q3" (A Sibling). Returns TRUE.
   If the engine is currently calculating "Jan" (A Child of Q1). Returns FALSE.
*/
IF(@ISISIBLING("Q1"))
```

---

## Practical Examples

### Example 1: Isolating a Peer Group for Benchmarking

**Scenario**: A forecasting application runs a benchmarking script. The script calculates a `"Performance_Score"` for every store. However, the script is specifically triggered by a user analyzing `"Store_105"`. The business logic states that the calculation should only run on Store 105 and its direct peers (the other stores in the exact same region). The script uses `@ISISIBLING` to restrict the math.

```essbase
/* 
   1. The FIX sweeps across all Level 0 Stores globally.
*/
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       2. As the engine evaluates each Store, it checks its relationship to Store_105.
       - Evaluating Store_105 (Target): Returns TRUE.
       - Evaluating Store_106 (Same Region): Returns TRUE.
       - Evaluating Store_999 (Different Region): Returns FALSE.
    */
    IF(@ISISIBLING("Store_105"))
        
        /* 
           3. Apply the benchmarking math ONLY to the target and its valid peers.
        */
        "Performance_Score" = ("Total_Revenue" / "Regional_Average") * 100;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Performance in Large Dimensions | Running on every block | If you put `IF(@ISISIBLING("Target"))` inside a global `FIX`, Essbase has to perform the parent-comparison trace for every single member in the database. It is almost always exponentially faster to use the member selection equivalent in the `FIX` statement itself: `FIX(@ISIBLINGS("Target"))`. Only use the boolean `IF` version when you must branch logic inside a larger calculation block |
| Confusing with Same Level | "Give me all Level 0 members" | A very common mistake is assuming that "Siblings" means "all members at the same level". If you want to apply logic to EVERY store in the company, `@ISISIBLING("Store_101")` will fail, because it will only return the stores in Store 101's specific region. If you want all members at a specific level, you must use `@ISLEV(Dimension, 0)` |
| Top Level Execution | `@ISISIBLING` on a Root Member | If you pass a member that is the absolute root of a dimension (e.g., `"Total_Company"`), it has no parent, and therefore no siblings. The function will simply return `TRUE` when it calculates `"Total_Company"`, and `FALSE` for everything else |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISSIBLING`](./@ISSIBLING.md) | The non-inclusive version. Checks the sibling relationship, but strictly returns `FALSE` when evaluating the target member itself |
| [`@ISCHILD`](./@ISCHILD.md) | Checks if a member is a direct child of a target, moving vertically rather than horizontally |
| [`@ISIBLINGS`](../04_Member_Navigation/@ISIBLINGS.md) | The member selection array version (used in `FIX` blocks) rather than the boolean version (used in `IF` blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISISIBLING](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isisibling.html)
