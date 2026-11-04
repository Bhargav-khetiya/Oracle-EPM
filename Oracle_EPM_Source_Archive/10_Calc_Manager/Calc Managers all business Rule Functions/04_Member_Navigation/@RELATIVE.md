# @RELATIVE

## Overview

`@RELATIVE` is a **member selection function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns all members of a specified hierarchy that are at a **specific generation or level** relative to a starting member. It is extremely versatile for grabbing all "leaf" members under a parent or all members at a specific tier (e.g., all Regions, all Departments).

### Why Does This Function Exist—

Standard hierarchical functions like `@CHILDREN` (one level down) or `@DESCENDANTS` (all levels down) lack precision when you need members from exactly one specific tier of the hierarchy:
- You want all base-level (level 0) entities under "Total Company" for data entry validations.
- You need to allocate corporate costs down to the "Region" level (Generation 2), but not down to the individual stores.
- You want to sum up data only from a specific level of the Account dimension.

`@RELATIVE` gives you exact vertical targeting in the dimension tree.

### When to Use It

- To dynamically select all Level 0 (leaf) members under a parent (`@RELATIVE(member, 0)`).
- In `FIX` statements to scope calculations exactly to a specific tier (e.g., Generation 3).
- To build allocation drivers that push data to a specific summary level.
- When creating drop-down lists or validation rules that must be restricted to a specific hierarchy depth.

---

## Category

**Member Selection / Hierarchy Navigation**

---

## Syntax

```essbase
@RELATIVE(mbrName, genLevNum)
@RELATIVE(mbrName, genLevName)
```

### Formal Syntax

```
@RELATIVE(memberName, levelOrGeneration_NumberOrName)
```

Where:
- `memberName` — The starting member (parent) in the hierarchy.
- `levelOrGeneration_NumberOrName` — The specific level or generation to target. Levels count up from the bottom (Level 0 = leaves). Generations count down from the top (Generation 1 = dimension root).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name | ✅ Yes | The ancestor member. `@RELATIVE` looks beneath this member. |
| `genLevNum` | Integer | ✅ Yes* | An integer representing the target Level or Generation. **Level 0** is the most common use case (all leaf members). If using a Generation number, it must be the exact generation depth from the root. |
| `genLevName` | String | ✅ Yes* | Instead of a number, you can pass the explicit name of the Generation or Level if defined in the outline (e.g., `"Regions"`, `"Base_Entities"`). |

*\* Must provide either the number or the name.*

---

## Return Value

**Return Type**: Member Set (a list of all members under `mbrName` that exist at the specified level or generation).

---

## How It Works (Behind the Scenes)

1. **Levels vs. Generations**: 
   - **Level 0** means bottom-level members (no children). Level 1 means parents of Level 0 members, etc. 
   - **Generation 1** is the dimension name. Gen 2 is its immediate children.
2. **Ragged Hierarchies**: If a hierarchy is ragged (branches have different depths), `@RELATIVE(..., Level)` and `@RELATIVE(..., Generation)` behave differently. `Level 0` always gets the bottom leaves, regardless of how deep they are. `Generation 3` strictly gets members exactly 3 steps from the root, which might be leaves in one branch but parents in another.
3. **Execution**: In a `FIX`, `@RELATIVE` resolves to a static list of members before block calculation begins, making it highly efficient.
4. **Zero Level Special Case**: `@RELATIVE(mbrName, 0)` is synonymous with `@ILDESCENDANTS(mbrName)` (Inclusive Level Descendants) if the member itself is Level 0, or `@LDESCENDANTS(mbrName)` if not. It is the most common way to say "give me the base members".

---

## Syntax Variants & Scenarios

### Variant 1: Level 0 Descendants (Most Common)

```essbase
FIX(@RELATIVE("Total Entity", 0))
```
Selects all leaf (base-level) entities under Total Entity.

### Variant 2: Specific Generation Number

```essbase
FIX(@RELATIVE("Total Product", 3))
```
Selects all products exactly at Generation 3.

### Variant 3: Using Generation/Level Name

```essbase
FIX(@RELATIVE("All Geographies", "Country_Level"))
```
Selects members at the named level "Country_Level".

### Variant 4: In an Aggregation/Sum

```essbase
"Total_Regional_Sales" = @SUM("Sales" -> @RELATIVE("Total Geography", 2));
```

---

## Practical Examples

### Example 1: Calculating Only at Base Level

**Scenario**: A complex driver-based calculation should only execute for input-level (Level 0) entities.

```essbase
FIX("FY25", "Working", @RELATIVE("Total Entity", 0))
    /* Calculate Revenue for base entities */
    Revenue = Units * Price;
    
    /* Calculate COGS */
    COGS = Units * "Unit_Cost";
ENDFIX

/* Roll up the calculated base data to parents */
AGG("Entity");
```

---

### Example 2: Allocating to a Specific Tier

**Scenario**: Corporate overhead needs to be allocated to the Division level (Generation 2), but not pushed all the way down to individual cost centers.

```essbase
FIX("FY25", "Working", @RELATIVE("Total Company", 2))
    /* Allocation logic applied only to Gen 2 entities */
    "Allocated_Overhead" = "Corporate_Overhead" -> "Corporate_Entity" *
                           (Revenue / Revenue -> "Total Company");
ENDFIX
```

---

### Example 3: Verifying Data Completeness

**Scenario**: Check if all regions (Level 1) have submitted their forecasts.

```essbase
FIX("FY25", "Forecast", @RELATIVE("Total Geography", 1))
    IF(Revenue == #MISSING)
        "Submission_Status" = 0; /* Incomplete */
    ELSE
        "Submission_Status" = 1; /* Complete */
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using Generation instead of Level 0 for leaves | In a ragged hierarchy, `Generation 4` might miss some leaves and include some parents | Use `@RELATIVE(member, 0)` to guarantee you get all base-level members |
| Invalid Generation Number | Passing a generation number that doesn't exist under the member | Ensure the generation depth actually exists within the target branch |
| Omitting the level parameter | `@RELATIVE("Entity")` is invalid syntax | Always include the level/gen: `@RELATIVE("Entity", 0)` |
| Using string for numbers | `@RELATIVE("Entity", "0")` might fail or be parsed incorrectly | Use raw integer for numeric levels: `@RELATIVE("Entity", 0)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@LDESCENDANTS`](./@LDESCENDANTS.md) | Specifically returns Level 0 descendants (Equivalent to `@RELATIVE(mbr, 0)`) |
| [`@DESCENDANTS`](./@DESCENDANTS.md) | Returns ALL descendants across ALL levels |
| [`@CHILDREN`](./@CHILDREN.md) | Returns immediate children (Equivalent to generation + 1 of the parent) |
| [`@ISLEV`](./@ISLEV.md) | Boolean test to check if a member is at a specific level |
| [`@ISGEN`](./@ISGEN.md) | Boolean test to check if a member is at a specific generation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @RELATIVE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/relative.html)
