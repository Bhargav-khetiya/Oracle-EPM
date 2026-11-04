# @LEVMBRS

## Overview

`@LEVMBRS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates a comprehensive, horizontal array containing **every single member** in a specified dimension that resides at a specific **Level** (distance from the bottom of the tree).

### Why Does This Function Exist—

When executing horizontal allocations or peer benchmarking, an administrator often needs to target all members of a specific management tier across the entire company. For example, they might need to apply a default tax rate to every single "Regional Manager" in the world.
If the outline is ragged (different depths), but the Regional Managers have all been structurally aligned to Level 1, you need a way to extract them.
If you use `@CHILDREN("Total_Company")`, you only get the direct children (e.g., the Division leaders). If you use `@DESCENDANTS("Total_Company")`, you get the Regional Managers, but you also accidentally get the base Stores, the Directors, and the Division leaders all mixed together. 
`@LEVMBRS` solves this by acting as a horizontal slice. You give it a dimension (`"Entity"`) and a Level integer (`1`), and it sweeps the entire outline, plucking out every single Level 1 member and assembling them into a clean calculation array, completely ignoring all other structural tiers.

### When to Use It

- **Global Target Settings**: Pushing a top-down corporate target (held at the root) down to exactly one specific tier of management globally, without pushing it all the way down to the leaf nodes.
- **Global Benchmarking**: Creating a `"Global_Average"` by summing all members at a specific tier (e.g., all Level 0 stores) and dividing by their count.
- **Data Clearances**: Executing a `CLEARBLOCK` script that zeroes out all base-level data (`@LEVMBRS("Entity", 0)`) prior to an automated data load, ensuring no legacy data remains.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@LEVMBRS(DimName, levelNumber)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimName` | Dimension | ✅ Yes | The name of the dimension you want to sweep (e.g., `"Entity"`, `"Product"`). Must be the exact dimension name, not a member name within the dimension. |
| `levelNumber` | Integer | ✅ Yes | The structural Level you want to extract. Levels are counted **Bottom-Up**. <br>- `0` = Leaf nodes (members with no children).<br>- `1` = Direct parents of leaf nodes, etc. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members.
- **Global Scope**: It returns ALL members in the entire dimension that sit at that level, regardless of who their parents are or what branch they sit in.
- **Empty Result**: If you ask for a Level that does not exist (e.g., asking for Level 15 in a dimension that is only 5 levels deep), the function returns an empty set. If used inside a `FIX`, the `FIX` will safely bypass calculation.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: Essbase locks onto the specified dimension (`DimName`).
2. **Horizontal Sweep**: It initiates a full-outline scan of that dimension.
3. **Depth Calculation**: For every single member it encounters, it calculates the member's mathematical Level (distance from its deepest leaf node).
4. **Filtering**: If the member's Level exactly matches `levelNumber`, it is added to the internal array.
5. **Return**: Once the entire dimension is scanned, it returns the massive concatenated list to the `FIX` statement or calculation function.

---

## Syntax Variants & Scenarios

### Variant 1: Selecting All Leaf Nodes

```essbase
/* 
   Returns every single base-level store, product, or cost center 
   in the Entity dimension, globally.
*/
@LEVMBRS("Entity", 0)
```
*(Note: `@LEVEL0("Entity")` is often used as a shorthand alias for this specific, extremely common use case).*

---

## Practical Examples

### Example 1: Creating a Tier-Specific Driver Assignment

**Scenario**: Corporate Finance issues a `"Management_Fee_Rate"`. The rate must be applied to every "District" in the company. Districts are universally structured at Level 1 of the `"Geography"` dimension. The script uses `@LEVMBRS` to instantly isolate all Level 1 Districts and apply the driver.

```essbase
/* 
   1. The FIX statement uses @LEVMBRS to slice the entire 
   Geography dimension horizontally, grabbing only Level 1 members.
*/
FIX("FY25", "Working", @LEVMBRS("Geography", 1))
    
    /* 
       2. Because the FIX is so perfectly constrained, we can write the math 
       directly without needing any IF statements.
       (Every member being calculated is guaranteed to be a Level 1 District).
    */
    "Management_Fee_Expense" = "Total_Revenue" * "Management_Fee_Rate"->"Total_Geography";
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing Levels with Generations | Bottom-Up vs Top-Down | This is the most catastrophic mistake. `LEVELS` count from the bottom up (Leaf = 0). `GENERATIONS` count from the top down (Root = 1). If you have a ragged hierarchy, Level 1 might be a District in one branch, but a Region in another branch (if that branch is shallower). If you want structural alignment from the top (e.g., "Give me all direct reports to the CEO"), you MUST use `@GENMBRS("Entity", 2)` |
| Passing a Member Name | `@LEVMBRS("USA", 1)` | The first parameter MUST be a Dimension name. You cannot pass a specific parent member like `"USA"`. If you want to find all Level 1 members that exist *specifically underneath* `"USA"`, you must intersect them: `@INTERSECT(@DESCENDANTS("USA"), @LEVMBRS("Entity", 1))` |
| Using it inside `IF` Statements | `IF(@LEVMBRS("Entity", 0) == "Store_1")` | This function generates a massive array of members. You cannot use it inside a standard Boolean `IF` statement. If you want to check if the currently calculating member is at a specific level, you must use the boolean equivalent: `IF(@ISLEV("Entity", 0))` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@GENMBRS`](./@GENMBRS.md) | The Top-Down equivalent. Slices the dimension horizontally based on distance from the root, rather than distance from the bottom |
| [`@ISLEV`](./@ISLEV.md) | The Boolean equivalent. Used inside `IF` statements to check if the *current* member is at a specific level |
| [`@LEVEL0`](./@LEVEL0.md) | A dedicated shorthand macro that behaves exactly like `@LEVMBRS(Dimension, 0)` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — LEVMBRS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/levmbrs.html)
