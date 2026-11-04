# @CURLEV

## Overview

`@CURLEV` is a **native Essbase hierarchical function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the database outline and returns the **exact Level number (integer)** of the member that is currently being processed by the calculation engine. 
*(Note: `@CURLEV` and `@CURRLEV` are exact aliases of one another. Both execute identical underlying C-code in the Essbase kernel).*

### Why Does This Function Exist—

When constructing robust financial scripts, you frequently need to execute logic that behaves differently for parent members versus child members. 
In Essbase, a **Level** counts Bottom-Up. The absolute lowest "leaf" nodes (members that have absolutely no children below them) are ALWAYS Level 0. Their immediate parents are Level 1. Their grandparents are Level 2. 
If an administrator writes a script that calculates a local `Gross_Margin_Pct`, that percentage must be calculated at the base input level, but it *also* must be re-calculated at every parent level during consolidation. 
`@CURLEV` provides structural awareness. Inside an `IF` statement, you can check `IF(@CURLEV("Entity") > 0)`. The engine instantly queries the outline, detects if the current member is a parent, and if so, triggers a recalculation of the ratio at the parent level, ensuring your financial reporting is mathematically sound across the entire hierarchy.

### When to Use It

- **Ratio Recalculations**: Forcing percentages (like Margins, Tax Rates, or Price/Volume variances) to recalculate dynamically when the engine is sitting on a Level 1 or Level 2 parent.
- **Allocation Targeting**: Ensuring that overhead is only ever assigned to leaf nodes by aborting the math if `@CURLEV("Entity") != 0`.
- **Ragged Hierarchy Navigation**: Generating flags on Level 1 members, knowing definitively that they are the direct parents of leaf nodes, regardless of how many Generations sit above them in a ragged tree.

---

## Category

**Hierarchy & Outline / Member Attributes & Evaluation / Essbase Native Functions**

---

## Syntax

```essbase
@CURLEV(DimensionName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimensionName` | String | ✅ Yes | The exact name of the dimension you want to evaluate (e.g., `"Product"`, `"Entity"`). <br>*Note: This must be the actual Dimension Name, not a specific member name within that dimension.* |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the integer number representing the Level of the current member being evaluated in the specified dimension.
- **Bottom-Up Counting**: 
  - `0` = A leaf node (a member with zero children).
  - `1` = A parent whose children are all leaf nodes.
  - `2` = A grandparent.
- **Ragged Rules**: In a ragged hierarchy (where some branches go deeper than others), Essbase always anchors Level 0 at the absolute bottom. A parent might be Level 1 on one side of the tree, and Level 5 on a much deeper side of the tree.
- **Note**: This function strictly returns a math integer, making it highly optimized for `IF` statement equality checks.

---

## How It Works (Behind the Scenes)

1. **Context Awareness**: As the Essbase engine iterates through data blocks, it locks onto a specific intersection (e.g., `"Working"`, `"USA"`, `"Total_Products"`).
2. **Dimension Query**: When it hits `@CURLEV("Product")`, the engine queries the outline index to find the current active member for the `"Product"` dimension (which is `"Total_Products"`).
3. **Level Resolution**: It traverses straight down the tree from `"Total_Products"` to find the longest path to a leaf node, counting the steps. 
4. **Return**: It returns the integer step count (e.g., `4`) back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Checking for Parent Members

```essbase
/* 
   Applies a specific logic ONLY to parent members (Level 1 or higher). 
*/
IF(@CURLEV("Entity") > 0)
    "Consolidated_Adjustment" = "Gross_Profit" * 0.05;
ENDIF
```

---

## Practical Examples

### Example 1: Dynamic Ratio Recalculation on Consolidation

**Scenario**: A company calculates `"Gross_Margin_Pct"`. At Level 0, this is simply `"Gross_Profit" / "Total_Revenue"`. However, when you consolidate the database, Essbase natively adds up the percentages (`10% + 15% = 25%`), which is mathematically invalid. The percentage must be re-calculated at the parent level using the parent's consolidated dollars. The script uses `@CURLEV` to detect when it is calculating a parent, and overwrites the invalid aggregated percentage with the correct math.

```essbase
FIX("FY25", "Actual", "Working")
    
    /* 1. We FIX on all products, both Level 0 and Parents */
    FIX(@DESCENDANTS("Total_Products"))
        
        /* 
           2. Check if the current product is a parent.
           If Level > 0, it has children below it.
        */
        IF(@CURLEV("Product") > 0)
            
            /* 
               3. The engine is on a parent. The native aggregation is wrong.
               We overwrite the percentage by recalculating it using 
               the parent's newly consolidated dollars.
            */
            IF("Total_Revenue" != 0)
                "Gross_Margin_Pct" = "Gross_Profit" / "Total_Revenue";
            ELSE
                "Gross_Margin_Pct" = #MISSING;
            ENDIF
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a Member Name | `@CURLEV("New_York")` | This function strictly expects the **Dimension Name**, not the member name. The engine already knows what member it is on; you are just telling it *which dimension* to evaluate. You must write `@CURLEV("Entity")` |
| Confusing Level with Generation | Expecting Root to be Level 1 | **Levels count BOTTOM-UP.** (Leaf = 0). **Generations count TOP-DOWN.** (Root = 1). The Root member of the `"Entity"` dimension might be Generation 1, but it could be Level 9. If you want to check if you are exactly 2 steps down from the top of the tree, you MUST use `@CURGEN("Entity") == 3`. Never use Levels to measure distance from the top |
| Performance vs. ISLEV | `IF(@CURLEV("Entity") == 0)` | While functionally perfect, using `@ISLEV("Entity", 0)` is historically slightly faster at compile time because it operates as a native boolean rather than calculating an integer and then running an equality operator against it. For Level 0 checks, prefer `@ISLEV` or `@ISMBR(@LEVEL0("Entity"))` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CURRLEV`](./@CURRLEV.md) | Exact alias of `@CURLEV`. They do the exact same thing |
| [`@CURGEN`](./@CURGEN.md) | The inverted counterpart. Evaluates the hierarchy Top-Down (Root = 1) instead of Bottom-Up |
| [`@ISLEV`](./@ISLEV.md) | A boolean shortcut function that returns `true` or `false` if the current member matches a specific level, often preferred for simple `IF` statement checks |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — CURLEV](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/curlev.html)
