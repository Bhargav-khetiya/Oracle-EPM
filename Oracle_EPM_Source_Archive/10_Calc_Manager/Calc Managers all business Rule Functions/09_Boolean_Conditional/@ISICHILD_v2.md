# @ISICHILD

## Overview

`@ISICHILD` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member and returns `TRUE` or `FALSE` based on whether the current member is an **Immediate Child** (exactly one generation below) of a specified target parent member, **OR if it is the target parent member itself.**

*(The "I" stands for Inclusive).*

### Why Does This Function Exist—

When building hierarchical calculations, administrators often need to execute targeted logic on a parent holding bucket and its immediate sub-components simultaneously.
If you are allocating a budget from `"Total_Marketing"` down to its direct children (`"Digital"`, `"Print"`, `"Events"`), you might want to apply a specific calculation flag to all of those entities.
If you use the native `@ISCHILD("Total_Marketing")` function, it will trigger on Digital, Print, and Events, but it will explicitly skip `"Total_Marketing"` (because you cannot be your own child). To trigger the parent as well, you would have to write a cumbersome `OR` statement: `IF(@ISCHILD("Total_Marketing") OR @ISMBR("Total_Marketing"))`.
`@ISICHILD` natively fuses these checks together. It evaluates the immediate 1-generation lineage inclusively, returning `TRUE` for both the parent and the direct children in a single, clean boolean check.

### When to Use It

- **Targeted Branch Overrides**: Applying a specific mathematical driver rate to a parent consolidation node and its direct immediate reporting children, while ignoring grandchildren.
- **Parent/Child Zero-Out Validations**: Ensuring that data clears happen simultaneously at the parent holding bucket and the child receiving buckets before allowing an aggregation routine to run.
- **Custom Reporting Thresholds**: Applying conditional formatting flags or scaling factors to a specific consolidation tier and the first-level breakdown beneath it.

---

## Category

**Boolean & Conditional / Hierarchy Relationships / Essbase Native Functions**

---

## Syntax

```essbase
@ISICHILD(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target parent member. The function checks if the *current* block being calculated is a direct child of this specific parent, or if it IS this specific parent. |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the currently calculating member is an immediate, first-generation child of the `MemberName` OR is identical to the `MemberName`. Returns `FALSE` (0) otherwise.
- **Inclusive Behavior**: Unlike `@ISCHILD`, if the engine is calculating `"Total_Company"` and you use `@ISICHILD("Total_Company")`, it will return `TRUE`.
- **Grandchildren Excluded**: As stated, this is strictly a 1-generation check. Grandchildren return `FALSE`.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the `IF(@ISICHILD(...))` block during a calculation sweep.
2. **Context Query**: It identifies the specific member it is currently calculating (e.g., `"Digital_Marketing"`).
3. **Equality Check**: It first checks if the current member is exactly identical to the `MemberName` parameter. If yes, it immediately returns `TRUE`.
4. **Outline Trace**: If not identical, it queries the active `.otl` outline. It looks at the current member and asks: "Who is my direct parent—
5. **Match Evaluation**: It compares the direct parent it found against the `MemberName`. If they match perfectly, it returns `TRUE`.
6. **Fail State**: If the parent does not match, it returns `FALSE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking Inclusive Immediate Parentage

```essbase
/* 
   If the engine is currently calculating "Total_OpEx" (The Target). Returns TRUE.
   If the engine is currently calculating "Marketing" (A Direct Child). Returns TRUE.
   If the engine is currently calculating "Promo_Events" (A Grandchild). Returns FALSE.
*/
IF(@ISICHILD("Total_OpEx"))
```

---

## Practical Examples

### Example 1: Isolating a Targeted Calculation Run

**Scenario**: A massive consolidation script calculates `"Net_Income"` across a global hierarchy. However, the Finance team wants to apply a 2% `"Currency_Hedge"` adjustment exclusively to the `"European_HQ"` parent bucket and its immediate direct-reporting country buckets (like `"France"`, `"Germany"`). It should NOT apply to the individual stores (grandchildren) beneath those countries, because the stores do not hold foreign debt.

```essbase
/* 
   1. The FIX sweeps across ALL Descendants of European_HQ to ensure 
   we have access to the entire branch.
*/
FIX("FY25", "Working", @IDESCENDANTS("European_HQ"))
    
    /* 
       2. As the engine evaluates each entity, it checks its relationship.
       - Evaluating European_HQ (Parent): Returns TRUE.
       - Evaluating France (Child): Returns TRUE.
       - Evaluating Paris_Store_01 (Grandchild): Returns FALSE.
    */
    IF(@ISICHILD("European_HQ"))
        
        /* 
           3. Apply the 2% currency hedge adjustment ONLY to the 
           parent and its direct country-level children.
        */
        "Currency_Hedge" = "Debt_Balance" * 0.02;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with Descendants | Missing the Grandchildren | This is the most common logic flaw. `@ISICHILD` strictly checks the 1st generation. If your intent is to execute logic on a parent and EVERY SINGLE member beneath it all the way down to the leaf nodes, you MUST use `@ISIDESC` (Inclusive Descendant). Using `@ISICHILD` will completely ignore all grandchildren |
| Backward Logic | `IF(@ISICHILD("Store"))` | The parameter must be the PARENT. The function asks "Is the current member a child of the parameter— If you put a Level-0 Store in the parameter, it will only return `TRUE` when it calculates that specific Store (because of inclusivity). It will return `FALSE` for everything else, rendering the child-check useless. Always pass the parent |
| Performance in Large Dimensions | Running on every block | If you put `IF(@ISICHILD("Target"))` inside a `FIX` covering 100,000 members, Essbase has to perform 100,000 outline checks. It is almost always exponentially faster to use the member selection equivalent in the `FIX` statement itself: `FIX(@ICHILDREN("Target"))`. Only use the boolean `IF` version when you must branch logic inside an already constrained `FIX` block |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISCHILD`](./@ISCHILD.md) | The non-inclusive version. Checks the parentage, but strictly returns `FALSE` when evaluating the target parent member itself |
| [`@ISIDESC`](./@ISIDESC.md) | The deep-traversal version. Returns `TRUE` for the parent, the direct children, the grandchildren, and all subsequent generations below it |
| [`@ICHILDREN`](../04_Member_Navigation/@ICHILDREN.md) | The member selection array version (used in `FIX` blocks) rather than the boolean version (used in `IF` blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISICHILD](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isichild.html)
