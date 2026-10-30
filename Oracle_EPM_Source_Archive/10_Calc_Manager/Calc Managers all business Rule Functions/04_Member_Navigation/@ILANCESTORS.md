# @ILANCESTORS

## Overview

`@ILANCESTORS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates a top-down array of ancestor members (parents, grandparents) for a specific target member **up to a specified Level or Generation**, and it explicitly includes the target member itself in the resulting array.

*(The "I" stands for Inclusive, and the "L" stands for Level-bound).*

### Why Does This Function Exist?

The standard `@IALLANCESTORS` function blindly traces a lineage all the way to the absolute root of the dimension (Generation 1). However, in massive EPM applications, tracing all the way to the root is often unnecessary or mathematically dangerous. 
For example, if you are allocating regional overhead to a store (`"Store_101"`), you might need to find its Parent (`"New_York"`) and its Grandparent (`"East_Region"`). But you explicitly DO NOT want to pull `"Total_Global_Company"` (the root) into the calculation, because that would pull global data into a localized regional script. 
`@ILANCESTORS` solves this by acting as a bounded lineage tracer. You pass the target member (`"Store_101"`) and a ceiling limit (like Level 2 or Generation 3). Essbase walks up the tree, collects the ancestors, stops exactly at the boundary you defined, and returns the bounded array (including the target store).

### When to Use It

- **Bounded Lineage Logging**: Writing a specific, truncated error path to the Job Console (e.g., `Region -> State -> Store`) without cluttering the log with useless `Total_Company` root members.
- **Localized Overhead Clearing**: Clearing a branch of data from a specific node up to the Regional holding bucket, without accidentally clearing Global holding buckets.
- **Dynamic Cross-Dimensional Lookups**: Using an array function to pull a driver rate that is stored exactly 2 levels above the current member, regardless of how deep the outline goes.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@ILANCESTORS(MemberName, level | gen | mbrName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member serving as the starting point (the bottom) of the lineage trace. |
| `Boundary` | Integer / Member | ✅ Yes | The stopping point for the upward climb. <br>- **Level Integer**: A bottom-up level number (e.g., `2`). <br>- **Generation Integer**: A top-down generation number (e.g., `3`). <br>- **Member Name**: A specific named ancestor to stop at (e.g., `"Total_US"`). |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members representing the direct, bounded lineage.
- **Order of Return**: The array is returned **Top-Down**. It starts with the highest allowed ancestor (the boundary), proceeds down the tree, and ends with the `MemberName` itself.
- **Inclusion**: The target `MemberName` is ALWAYS the final member in the array.
- **Out of Bounds**: If you set a boundary that the member does not belong to (e.g., asking for Generation 2, but the member only goes up to Generation 3), the function will return an empty set or throw a compilation warning.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Boundary Resolution**: It determines the absolute structural position of the defined boundary limit.
3. **Outline Query**: It initiates an upward climb of the `.otl` outline, looking for parents.
4. **Constraint Check**: At every step, it checks if it has reached the boundary. If it has, it stops climbing.
5. **Array Assembly**: It reverses the trace, assembling the members in a Top-Down order.
6. **Inclusion**: It appends the original `MemberName` to the bottom of the list.
7. **Return**: It returns the bounded array to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Level-Bound Lineage

```essbase
/* 
   If Store_101 (Level 0) rolls up to New_York (Level 1), 
   which rolls up to East_Region (Level 2).
   Returns: "East_Region", "New_York", "Store_101"
*/
@ILANCESTORS("Store_101", 2)
```

---

## Practical Examples

### Example 1: Localized Branch Zero-Out

**Scenario**: A forecasting rule allows users to trigger an "Adjust Region" calculation. The script must clear out any previously calculated adjustment data for the active store and its direct regional parents, but it MUST NOT clear the `"Global_Consolidation"` bucket at the top of the tree. The script uses `@ILANCESTORS` bounded to Generation 3 (the Regional Level) to ensure the clear script is safely contained.

```essbase
/* 
   1. The FIX statement targets the active Store passed by a runtime prompt.
   2. It uses @ILANCESTORS bound to Generation 3. 
   This grabs the Store, its State (Gen 4), and its Region (Gen 3).
   It explicitly STOPS before hitting Global (Gen 1).
*/
FIX("FY25", "Working", @ILANCESTORS({Active_Store}, 3))
    
    /* 
       3. Safely zero out the adjustment buckets for this specific branch.
    */
    "Manual_Adjustments" = 0;
    
ENDFIX

/* 
   4. The script can now safely run the adjustment logic.
*/
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing Levels and Generations | `@ILANCESTORS("Store", 1)` | Levels count Bottom-Up (Leaf = 0). Generations count Top-Down (Root = 1). If you ask to stop at Level 1, it will only climb one step above the leaf node. If you ask to stop at Generation 1, it will climb all the way to the root. Mixing these up is the #1 cause of failed lineage arrays. Always trace your outline visually before assigning boundaries |
| Using it inside IF statements | `IF(@ILANCESTORS("X", 2) == "Y")` | This function returns a massive array (a list of multiple members). You cannot use standard mathematical equality (`==`) to compare an array to a single string inside an `IF` statement. This function belongs in `FIX` blocks, `@SUM` ranges, or array processing CDFs |
| Target is Above Boundary | `@ILANCESTORS("Total_Company", 0)` | If your target member is structurally higher than your boundary (e.g., asking for the ancestors of the Root, but capping it at Level 0), the function logically fails because it cannot climb "up" to a lower level. It will likely return just the target member or an empty set |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@IALLANCESTORS`](./@IALLANCESTORS.md) | The unbounded version. Climbs all the way to the absolute root of the dimension without stopping |
| [`@LANCESTORS`](./@LANCESTORS.md) | The non-inclusive version. Returns the exact same bounded tree, but strictly EXCLUDES the starting target member |
| [`@ILDESCENDANTS`](./@ILDESCENDANTS.md) | The inverse traversal. Starting from a parent, it returns the target member and everything strictly BELOW it, bounded by a specified level limit |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ILANCESTORS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ilancestors.html)
