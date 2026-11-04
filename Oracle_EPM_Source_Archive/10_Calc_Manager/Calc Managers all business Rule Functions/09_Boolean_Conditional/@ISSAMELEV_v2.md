# @ISSAMELEV

## Overview

`@ISSAMELEV` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member and returns `TRUE` or `FALSE` based on whether that member resides at the **exact same Level** (measured from the bottom-up) as a specified target member.

### Why Does This Function Exist—

When writing generalized, dynamic scripts that can be applied to massive, ragged hierarchies, hardcoding levels is dangerous. 
For example, if you want to apply a specific driver rate exclusively to the "Regional Managers", you might assume they are at Level 2. So you write `IF(@ISLEV("Entity", 2))`. But in a ragged hierarchy, some Regional Managers might be at Level 2 (managing stores), while others might be at Level 3 (managing districts which manage stores). 
If the Finance team designates `"New_York"` as the "Gold Standard" Regional Manager node, you don't care what mathematical Level it is at; you just want to find all other members that share its structural depth. 
`@ISSAMELEV("New_York")` solves this. It dynamically looks up the structural Level of `"New_York"` at runtime, and then checks if the current calculating member matches that depth, ensuring your logic adapts instantly even if the outline structure is rebuilt.

### When to Use It

- **Peer Group Alignments**: Executing a benchmarking script on all entities that share the exact same structural depth as a dynamically selected baseline entity.
- **Dynamic Aggregation Halts**: Instructing an `@CALCMODE(BOTTOMUP)` script to stop calculating once it reaches the same consolidation tier as a specific control member.
- **Attribute / Driver Overlays**: Applying a flat corporate assumption (like a standard tax rate) horizontally across a specific level of the organization, anchored to a representative node.

---

## Category

**Boolean & Conditional / Hierarchy Relationships / Essbase Native Functions**

---

## Syntax

```essbase
@ISSAMELEV(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member that serves as the depth anchor. The function checks if the *current* block being calculated is at the same Level (bottom-up depth) as this target. |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the currently calculating member is at the exact same Level (e.g., Level 0, Level 1) as the `MemberName`. Returns `FALSE` (0) otherwise.
- **Inclusive Behavior**: If the engine is currently calculating the target member itself (e.g., evaluating `"New_York"`, and checking `@ISSAMELEV("New_York")`), it returns `TRUE`, because a member is always at the same level as itself.
- **Unrelated Branches**: The members DO NOT need to share a parent or even be in the same branch. As long as they are mathematically at the same structural depth from the bottom of the tree, they will return `TRUE`.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the `IF(@ISSAMELEV(...))` block.
2. **Context Query**: It identifies the specific member it is currently calculating (e.g., `"Boston"`). It queries the outline and determines its Level (e.g., Level 1).
3. **Target Trace**: It locates the `MemberName` provided in the parameter (e.g., `"New_York"`). It queries the outline and determines its Level (e.g., Level 1).
4. **Match Evaluation**: It compares the two integers (`1 == 1`).
5. **Return**: If the Levels match perfectly, it returns `TRUE`. If they do not match, it returns `FALSE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking Baseline Depth

```essbase
/* 
   If "Store_101" is Level 0 (a leaf node).
   If the engine is currently calculating "Store_105" (Level 0), Returns TRUE.
   If the engine is currently calculating "USA" (Level 3), Returns FALSE.
*/
IF(@ISSAMELEV("Store_101"))
```

---

## Practical Examples

### Example 1: Creating a Dynamic Peer Tier

**Scenario**: A forecasting application allows users to set a "Driver Entity" via a substitution variable (`&TargetEntity`). The script must apply the mathematical assumptions held at that Target Entity to EVERY other entity in the database that sits at the exact same management tier (Level), regardless of what Region they belong to.

```essbase
/* 
   1. The FIX sweeps across ALL entities globally.
*/
FIX("FY25", "Working", @DESCENDANTS("Total_Global"))
    
    /* 
       2. As the engine evaluates each entity, it checks its depth.
       It dynamically looks at &TargetEntity. If &TargetEntity is Level 2, 
       this function will return TRUE for EVERY Level 2 entity in the database.
    */
    IF(@ISSAMELEV(&TargetEntity))
        
        /* 
           3. Apply the peer logic.
           (e.g., pulling the growth rate from the target and applying it locally).
        */
        "Forecast_Growth" = "Growth_Rate"->&TargetEntity;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing Levels and Generations | Bottom-Up vs Top-Down | This function strictly checks **LEVELS** (counting from the bottom-up, where Leaf Nodes = Level 0). It does NOT check Generations (Top-Down, where Root = Gen 1). In a ragged hierarchy, two members might both report directly to the CEO (Generation 2), but one might be Level 1 and the other Level 5. They will return `FALSE`. If you need top-down structural alignment, you MUST use `@ISSAMEGEN` |
| Assuming Family Relationships | "But they aren't siblings" | `@ISSAMELEV` ignores ancestry completely. A Level 1 node in the `"Products"` branch and a Level 1 node in the `"Services"` branch will return `TRUE` if evaluated against each other, even if they have completely different parents. If you want peer members under the SAME parent, use `@ISISIBLING` |
| Using it inside `FIX` | `FIX(@ISSAMELEV("Target"))` | `@ISSAMELEV` is a Boolean function designed for `IF` statements. You cannot use it as an array selector inside a `FIX` statement. If you need to fix on all members at the same level, you must use the selection version: `@SAMELEV("Target")` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISSAMEGEN`](./@ISSAMEGEN.md) | The Top-Down equivalent. Checks if members are exactly the same distance from the root of the outline (Generation 1), rather than distance from the bottom |
| [`@ISLEV`](./@ISLEV.md) | Checks if a member is at a specific, hardcoded Level integer (e.g., `IF(@ISLEV("Entity", 0))`), rather than anchoring against a target member |
| [`@SAMELEV`](@ISSAMELEV.md) | The member selection array version (used directly in `FIX` blocks) rather than the boolean version (used in `IF` blocks) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISSAMELEV](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/issamelev.html)
