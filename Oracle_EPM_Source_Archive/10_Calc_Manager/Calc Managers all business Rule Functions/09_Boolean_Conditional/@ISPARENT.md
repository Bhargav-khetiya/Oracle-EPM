# @ISPARENT

## Overview

`@ISPARENT` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member and returns `TRUE` or `FALSE` based on whether the current member is the **Immediate Parent** (exactly one generation above) of a specified target child member.

### Why Does This Function Exist—

When building hierarchical validation rules or complex bottom-up allocations, administrators often need precise control over the direct supervisor/parent node of a data point. 
If a base store (`"Store_101"`) reports a massive loss, the script might need to flag the direct Regional Manager (`"New_York"`) for review. 
If you use `@ISANCEST("Store_101")`, the script will flag the Region, the Division, and the Global CEO, because they are all ancestors. 
`@ISPARENT("Store_101")` solves this by natively querying the outline and enforcing a strict, 1-generation boundary constraint moving *upward*. It checks if the currently calculating member is the *direct* parent of the target. If it is a grandparent or higher, the function returns `FALSE`. This allows for surgical, immediate-supervisor logic execution.

### When to Use It

- **Direct Supervisor Tagging**: Flagging a specific regional consolidation node for review based on a breach of rules at one of its direct reporting base nodes.
- **Hierarchical Math Overrides**: Applying a specific adjustment or driver rate exclusively to the first consolidation level above a target, without impacting the rest of the rollout.
- **Validation Constraints**: Ensuring that a data push or calculation ONLY executes when the engine is actively sitting on the direct parent of a dynamic runtime prompt.

---

## Category

**Boolean & Conditional / Hierarchy Relationships / Essbase Native Functions**

---

## Syntax

```essbase
@ISPARENT(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target child member. The function checks if the *current* block being calculated is the direct parent of this specific child. |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the currently calculating member is the immediate, first-generation parent of the `MemberName`. Returns `FALSE` (0) if it is not.
- **Non-Inclusive**: If the engine is currently calculating the target child itself (e.g., evaluating `"Store_101"`, and checking `@ISPARENT("Store_101")`), it returns `FALSE`. You cannot be your own parent.
- **Grandparents Excluded**: As stated, this is strictly a 1-generation check. Grandparents return `FALSE`.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the `IF(@ISPARENT(...))` block during a calculation pass.
2. **Context Query**: It identifies the specific member it is currently calculating (e.g., `"New_York"`).
3. **Outline Trace**: It queries the active `.otl` outline. It looks at the `MemberName` provided in the parameter and asks: "Who is the direct parent of this target—
4. **Match Evaluation**: It compares the direct parent it found against the current calculating member. 
5. **Return**: If they match perfectly, it returns `TRUE`. If they do not match, it returns `FALSE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking Immediate Parentage

```essbase
/* 
   If "Store_101" rolls directly into "New_York".
   If the engine is currently calculating "New_York", Returns TRUE.
   If the engine is currently calculating "USA", Returns FALSE.
*/
IF(@ISPARENT("Store_101"))
```

---

## Practical Examples

### Example 1: Immediate Supervisor Adjustment

**Scenario**: The business dictates that if a specific project (`"Proj_Alpha"`) incurs more than `$1,000,000` in expenses, the direct parent category (e.g., `"Total_Software_Projects"`) must automatically reserve a 5% contingency fund. The contingency should ONLY hit the direct parent, not the `"Global_Total_Projects"` root. 

```essbase
/* 
   1. The FIX sweeps across ALL Parent-level projects to ensure 
   we catch the consolidation nodes.
*/
FIX("FY25", "Working", @IDESCENDANTS("Total_Projects"))
    
    /* 
       2. We check if the current project category we are evaluating 
       is the direct parent of Proj_Alpha.
       - Evaluating Global_Total_Projects (Grandparent): Returns FALSE.
       - Evaluating Total_Software_Projects (Direct Parent): Returns TRUE.
    */
    IF(@ISPARENT("Proj_Alpha"))
        
        /* 
           3. Extract the total expenses of Proj_Alpha and check the threshold.
        */
        IF("Total_Expense"->"Proj_Alpha" > 1000000)
            
            /* Apply the 5% contingency exclusively to this parent node */
            "Contingency_Reserve" = "Total_Expense"->"Proj_Alpha" * 0.05;
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Backward Logic | `IF(@ISPARENT("New_York"))` | The parameter is the CHILD. The function asks "Is the current member the parent of the parameter— If you put the Parent in the parameter, and the engine calculates the Child, it asks "Am I the parent of my Parent—, returning `FALSE`. If you want to check if the current member is a child of a parent, you MUST use `@ISCHILD` |
| Confusing with `@ISANCEST` | Missing the Grandparents | If you write an allocation rule using `@ISPARENT("Store_101")`, it will hit `"New_York"`, but it will COMPLETELY IGNORE `"USA"`. If your intent was to apply logic to the parent and EVERY SINGLE member above it all the way to the root, you must use `@ISANCEST` (Is Ancestor) instead of `ISPARENT` |
| Top Level Execution | Target is the Root | If you pass the absolute root of a dimension (e.g., `@ISPARENT("Total_Company")`), it will ALWAYS return `FALSE`, because the root has no parent. The function will never find a match |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISCHILD`](./@ISCHILD.md) | The exact inverse logic. Checks if the current member is the child of the target, moving vertically downward rather than upward |
| [`@ISANCEST`](./@ISANCEST.md) | The deep-traversal version moving upward. Returns `TRUE` for direct parents, grandparents, and all subsequent generations above the target |
| [`@PARENT`](./@PARENT.md) | The member selection version (used in `FIX` blocks) rather than the boolean version (used in `IF` blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISPARENT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isparent.html)
