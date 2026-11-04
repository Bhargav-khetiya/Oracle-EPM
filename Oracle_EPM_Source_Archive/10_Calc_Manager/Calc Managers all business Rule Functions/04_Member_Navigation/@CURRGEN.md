# @CURRGEN

## Overview

`@CURRGEN` is a **native Essbase hierarchical function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the database outline and returns the **exact Generation number (integer)** of the member that is currently being processed by the calculation engine. 
*(Note: `@CURRGEN` and `@CURGEN` are exact aliases of one another. Both execute identical underlying C-code in the Essbase kernel).*

### Why Does This Function Exist—

When executing Top-Down allocations or dynamic currency translations, business logic often changes depending on how high up in the hierarchy a member sits. 
In Essbase, a **Generation** counts Top-Down. The absolute highest root member of a dimension (e.g., `Total_Geography`) is always Generation 1. Its children (`North_America`, `Europe`) are Generation 2. Its grandchildren (`USA`, `Canada`) are Generation 3. 
If an administrator writes a script that calculates a corporate tax rate, but the tax rate is only applied to Generation 3 entities (Countries), they cannot easily use `@LEVEL0`, because some countries might have states below them, and some might not (a ragged hierarchy). 
`@CURRGEN` provides absolute structural awareness. Inside an `IF` statement, you can check `IF(@CURRGEN("Entity") == 3)`. The engine will instantly query the outline, see if the member currently being calculated resides on Generation 3, and route the calculation accordingly.

### When to Use It

- **Tiered Allocations**: Running a waterfall allocation where Generation 2 overhead pools are pushed down to Generation 3 regional pools, and Generation 3 pools are pushed to Generation 4 local pools.
- **Security & Validation**: Preventing users from copying data into upper-level members by aborting the calculation if `@CURRGEN` is `< 3`.
- **Dynamic Calculation Flags**: Setting a specific "Consolidation Flag" on all Generation 2 members to trigger a specialized aggregation script later in the batch.

---

## Category

**Hierarchy & Outline / Member Attributes & Evaluation / Essbase Native Functions**

---

## Syntax

```essbase
@CURRGEN(DimensionName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimensionName` | String | ✅ Yes | The exact name of the dimension you want to evaluate (e.g., `"Entity"`, `"Account"`). <br>*Note: This must be the actual Dimension Name, not a specific member name within that dimension.* |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the integer number representing the Generation of the current member being evaluated in the specified dimension.
- **Top-Down Counting**: 
  - `1` = The absolute root of the dimension (e.g., `Total_Entity`).
  - `2` = The immediate children of the root.
  - `3` = The grandchildren.
- **Note**: This function does NOT return the member name. It strictly returns a math integer, making it highly optimized for `IF` statement equality checks.

---

## How It Works (Behind the Scenes)

1. **Context Awareness**: As the Essbase engine loops through the data blocks defined in your `FIX` statement, it focuses on one specific intersection (e.g., `"Working"`, `"FY25"`, `"USA"`, `"Sales"`).
2. **Dimension Query**: When it hits `@CURRGEN("Entity")`, the engine queries the outline index in memory to find the current active member for the `"Entity"` dimension (which is `"USA"`).
3. **Generation Resolution**: It traverses straight up the tree from `"USA"` to the root, counting the steps. 
4. **Return**: It returns the integer step count (`3`) back to the calculation block, allowing the `IF` statement to evaluate the condition instantly.

---

## Syntax Variants & Scenarios

### Variant 1: Checking Hierarchy Depth in an IF Statement

```essbase
/* 
   Applies a specific logic ONLY to Generation 2 entities. 
*/
IF(@CURRGEN("Entity") == 2)
    "Tax_Rate" = 0.35;
ENDIF
```

---

## Practical Examples

### Example 1: Dynamic Top-Down Corporate Allocation

**Scenario**: Corporate IT Expenses are loaded at Generation 2 nodes (`"North_America_IT"`, `"Europe_IT"`). A script must push these expenses down. However, the script is executed globally. To prevent the script from accidentally trying to allocate Level-0 local expenses (which are Generation 4), it uses `@CURRGEN` to ensure the allocation formula only fires when the engine is actively sitting on a Generation 2 member.

```essbase
FIX("FY25", "Actual", "IT_Allocations")
    
    /* 
       1. We FIX on all entities. But we only want to trigger the math 
       when the engine lands on a Generation 2 entity.
    */
    FIX(@DESCENDANTS("Total_Geography"))
        
        IF(@CURRGEN("Entity") == 2 AND "IT_Expense" > 0)
            
            /* 
               2. The engine is on a Gen 2 member (e.g. North_America_IT).
               Allocate the expense down to its base descendants 
               based on headcount.
            */
            @ALLOCATE(
                "IT_Expense", 
                @RELATIVE(@CURRMBR("Entity"), 0), 
                "Headcount", 
                , 
                share
            );
            
            /* 3. Clear the Gen 2 pool to prevent double counting */
            "IT_Expense" = 0;
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a Member Name | `@CURRGEN("USA")` | This is the most frequent compilation error. This function strictly expects the **Dimension Name**, not the member name. The engine already knows what member it is on; you are just telling it *which dimension* you want it to evaluate. You must write `@CURRGEN("Entity")` |
| Confusing Generation with Level | Expecting Level 0 to be Generation 0 | **Generations count TOP-DOWN.** (Root = 1). **Levels count BOTTOM-UP.** (Leaf = 0). If you have a ragged hierarchy, Generation 3 might be Level 0 for some branches, and Level 2 for other branches. If you want to explicitly check if a member has no children (is a leaf node), you MUST use `@ISLEV("Entity", 0)` or `@CURRLEV("Entity") == 0`. Never use Generations to check for leaf nodes |
| Dynamic Dimensions | Evaluating sparse vs dense | Evaluating generations on dense dimensions inside a block is extremely fast. However, if your `FIX` statement relies heavily on sparse generation evaluations in Top-Down calculation mode, the performance can degrade significantly. Always try to limit your `FIX` to specific generations using `@GENMBRS` if possible, rather than looping the whole dimension and using `IF(@CURRGEN...)` inside the block |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CURGEN`](./@CURGEN.md) | Exact alias of `@CURRGEN`. They do the exact same thing |
| [`@CURRLEV`](./@CURRLEV.md) | The inverted counterpart. Evaluates the hierarchy Bottom-Up (Level 0 = Leaf Node) instead of Top-Down |
| [`@GENMBRS`](./@GENMBRS.md) | A selection function that returns an array of ALL members at a specific generation, often used inside a `FIX` statement to avoid needing `@CURRGEN` entirely |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — CURRGEN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/currgen.html)
