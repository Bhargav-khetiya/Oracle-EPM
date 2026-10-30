# @GENMBRS

## Overview

`@GENMBRS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates a comprehensive array of all members within a specified dimension that exist exactly at a specified **Generation number**. 

### Why Does This Function Exist?

When building calculation scripts, it is highly inefficient to loop through every single member in a massive dimension just to apply logic to a small subset. 
If an administrator needs to execute a Top-Down allocation rule specifically on all Regional Managers (who all sit at Generation 3 in the `Entity` dimension), they could technically write `FIX(@DESCENDANTS("Total_Entity"))` and then put `IF(@CURGEN("Entity") == 3)` inside the formula. However, this forces the engine to visit every single Base store and every single Country parent, only to skip them. 
`@GENMBRS` solves this performance bottleneck. By placing `@GENMBRS("Entity", 3)` directly inside the `FIX` statement, Essbase queries the outline *before* calculating data, instantly isolates the 50 Regional Managers, and completely ignores the other 10,000 entities in the hierarchy. This drastically reduces calculation times for tiered allocations.

### When to Use It

- **Tiered Waterfall Allocations**: Fixing on Generation 2 members to push overhead down to Generation 3, then fixing on Generation 3 to push down to Level 0.
- **Dynamic Cross-Dimensional Rollups**: Selecting all members at a specific Generation to act as targets for an `@ALLOCATE` function without explicitly naming their shared parent.
- **Reporting & Data Export**: Creating a clean `DATAEXPORT` array that outputs data exclusively for Generation 4 Cost Centers, preventing the file from being bloated with lower-level detail.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@GENMBRS(DimensionName, gen_num | gen_name)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimensionName` | String | ✅ Yes | The exact name of the dimension to query (e.g., `"Entity"`, `"Account"`). |
| `gen_num` (or `gen_name`) | Integer / String | ✅ Yes | The target Generation to retrieve. <br>- **Integer**: The numeric generation level (e.g., `3`). Generation `1` is the absolute root of the dimension. <br>- **String**: If the administrator assigned a specific text Alias/Name to the generation in the Outline properties (e.g., `"Regional_Managers"`), you can pass that string in quotes. |

---

## Return Value

**Return Type**: Member List (Array)

Returns an array containing every single member in the specified dimension that natively resides on that specific generation.
- **Ragged Hierarchies**: Essbase counts strictly Top-Down. A member is Generation 3 if it is exactly two steps below the Root, regardless of whether it is a leaf node or a parent.
- **Empty Expansion**: If no members exist at the requested generation (e.g., asking for Generation 99 in a 5-generation tree), the function returns an empty set. If used in a `FIX`, the `FIX` silently terminates.

---

## How It Works (Behind the Scenes)

1. **Compilation Phase**: Before any data blocks are loaded, the Essbase compiler evaluates the `FIX` statement.
2. **Index Query**: It queries the memory-resident Outline metadata. It locates the root of the specified `DimensionName` (Generation 1).
3. **Traversal**: It steps down the tree exactly `gen_num - 1` times. It grabs every single node that sits on that horizontal plane of the hierarchy.
4. **Return**: It passes that comma-separated array of members back to the `FIX` block, allowing the calculation engine to build a hyper-optimized execution plan that only visits those specific blocks.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Generation Selection (Numeric)

```essbase
/* 
   Generates a list of all Generation 3 members in the Entity dimension.
*/
@GENMBRS("Entity", 3)
```

### Variant 2: Generation Selection (Named)

```essbase
/* 
   If Generation 2 was explicitly named "Divisions" in the Outline properties.
*/
@GENMBRS("Entity", "Divisions")
```

---

## Practical Examples

### Example 1: High-Performance Waterfall Allocation

**Scenario**: A company has a 3-tier structure: `Total_Entity` (Gen 1) -> `Divisions` (Gen 2) -> `Regions` (Gen 3) -> `Stores` (Level 0). Corporate expenses are loaded to the Divisions. The script must allocate the Division pools down to their respective Base Stores using Headcount. To avoid spinning through the thousands of stores looking for the Division expense, the script is strictly fixed on the Divisions (Generation 2).

```essbase
/* 
   1. Restrict the engine to ONLY evaluate Generation 2 entities.
      (This completely ignores Regions and Stores, saving massive time).
*/
FIX("FY25", "Working", @GENMBRS("Entity", 2))
    
    /* 
       2. We are now sitting on a Generation 2 Division.
       If it has an Overhead Expense, we push it down to the leaf nodes.
    */
    IF("Overhead_Expense" > 0)
        
        /* 
           @RELATIVE(@CURRMBR("Entity"),0) dynamically finds all 
           the stores under whichever Division we are currently calculating.
        */
        @ALLOCATE(
            "Overhead_Expense", 
            @RELATIVE(@CURRMBR("Entity"), 0), 
            "Headcount", 
            , 
            share
        );
        
        /* 3. Zero out the Division pool so it doesn't double-count */
        "Overhead_Expense" = 0;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using Inside an IF Statement | `IF(@GENMBRS("Entity", 3) == "USA")` | `GENMBRS` returns a massive array of members (a list). You cannot compare a list of members to a single string in an `IF` equality check. This will throw a syntax error. If you are inside an `IF` and want to check if the *current* member is Generation 3, use `@CURGEN("Entity") == 3`. Only use `@GENMBRS` inside `FIX` statements or array functions |
| Confusing Generation with Level | `@GENMBRS("Entity", 0)` | Generations count TOP-DOWN (Root = 1). Levels count BOTTOM-UP (Leaf = 0). Generation 0 does not exist. If you ask for Generation 0, the script will crash or throw a compilation error. If you want Level 0 members, you MUST use `@LEVMBRS("Entity", 0)` |
| Ragged Hierarchy Inconsistencies | Targeting Leaf Nodes | In a ragged hierarchy, one branch might end at Generation 3, while another branch ends at Generation 5. If you use `@GENMBRS("Entity", 3)`, you will capture some leaf nodes and some parent nodes. If your goal is to strictly target leaf nodes (data entry points), NEVER use Generations. Always use `@LEVEL0("Entity")` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@LEVMBRS`](./@LEVMBRS.md) | The inverted alternative. Returns all members at a specific Bottom-Up *Level* rather than a Top-Down *Generation* |
| [`@CURGEN`](./@CURGEN.md) | Evaluates a single member to determine its Generation number (returning an integer), designed specifically for `IF` statements |
| [`@DESCENDANTS`](./@DESCENDANTS.md) | Returns all members below a specific point, crossing multiple generations simultaneously |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — GENMBRS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/genmbrs.html)
