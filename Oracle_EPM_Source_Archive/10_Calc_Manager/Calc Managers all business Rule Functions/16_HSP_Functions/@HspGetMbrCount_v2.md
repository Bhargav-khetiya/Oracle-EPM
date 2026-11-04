# @HspGetMbrCount

## Overview

`@HspGetMbrCount` is a **Hyperion Planning (HSP) custom administrative function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It dynamically queries the internal Planning repository and returns an **integer count** representing the total number of members belonging to a specific dimension.

### Why Does This Function Exist—

When building highly dynamic allocation loops or validating metadata loads, administrators sometimes need to know the absolute scale of a dimension. 
If an automation script triggers an integration that imports new `"Employees"` every night, a subsequent script might need to divide a corporate bonus pool evenly across the entire workforce. If the administrator uses `@COUNT` inside Essbase, they must iterate through data blocks, which is slow and only counts members that have active data. 
`@HspGetMbrCount` bypasses the data blocks entirely. It sends a direct API request to the relational Planning repository and asks: "How many members exist in the Employee dimension right now— It instantly returns the structural count (e.g., `5420`), allowing the script to execute mathematical divisions instantly without having to scan the database.

### When to Use It

- **Flat Allocations**: Distributing a static `$1,000,000` expense perfectly evenly across every single Base Cost Center in the outline, regardless of whether they have data yet.
- **Metadata Validation Checks**: Logging the total number of Products to the Job Console before and after a dimension build to programmatically verify that the metadata load succeeded.
- **Loop Counters**: Establishing a strict maximum integer limit (`Max = Count`) for an iterative custom Java `while` loop parsing a dimension array.

---

## Category

**Planning Extensions / Outline Analytics / Custom HSP Functions**

---

## Syntax

```essbase
@HspGetMbrCount("Dimension_Name")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Dimension_Name"` | String | ✅ Yes | The exact text string name of the target dimension (e.g., `"Entity"`, `"Employee"`). Must be enclosed in double quotes. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the absolute total integer count of members in the dimension.
- **Includes Everything**: The count includes the root member, all parents, and all leaf nodes. It does NOT distinguish between Level 0 and Parent members unless specifically coded to do so via relational extensions.
- **Zero or Negative**: If the dimension name is invalid or the relational connection fails, it typically returns `0` or throws an error.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the function.
2. **Relational Query**: Unlike native Essbase functions (which query the `.otl` index), HSP functions communicate directly with the relational Planning repository. It executes a highly optimized equivalent of a `SELECT COUNT(*)` on the internal `HSP_OBJECT` table for that specific dimension ID.
3. **Return**: It instantly pipes the integer result back to the calculation thread in Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Retrieving the Dimension Scale

```essbase
/* 
   If there are 500 total Entities in the application, 
   vTotalEntities will equal 500.
*/
VAR vTotalEntities = @HspGetMbrCount("Entity");
```

---

## Practical Examples

### Example 1: Even Distribution Across an Entire Dimension

**Scenario**: A company has a `"Global_Bonus_Pool"` of `$5,000,000`. The CFO wants to allocate this perfectly evenly across every single Entity in the company, regardless of whether the Entity has existing expenses or headcount data. The script must query the total number of Entities to calculate the exact per-entity allocation amount.

```essbase
FIX("FY25", "Working")
    
    /* 
       1. Query the exact number of Entities currently in the database.
       (e.g., 2,500)
    */
    VAR vEntityCount = @HspGetMbrCount("Entity");
    
    /* 
       2. Protect against Divide-by-Zero errors.
    */
    IF(vEntityCount > 0)
        
        /* 
           3. Calculate the per-entity allocation amount.
           (e.g., 5,000,000 / 2,500 = $2,000 per Entity)
        */
        VAR vPerEntityAmount = "Global_Bonus_Pool"->"No_Entity" / vEntityCount;
        
        /* 
           4. Assign the calculated amount to all leaf-level Entities.
        */
        FIX(@LEVEL0("Entity"))
            
            "Allocated_Bonus" = vPerEntityAmount;
            
        ENDFIX
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Quotes | `@HspGetMbrCount(Entity)` | This function expects a literal text string. If you omit the quotes, Essbase will try to evaluate `Entity` as a variable or member pointer, causing a syntax error. Always wrap the dimension name in double quotes: `"Entity"` |
| Confusing with `@COUNT` | Trying to count data | `@HspGetMbrCount` counts metadata (structural members in the outline). It has absolutely no awareness of data. If you have 500 Cost Centers, but only 10 of them have actual expenses, `@HspGetMbrCount` will return `500`. If you need to count how many members *actually have data*, you MUST use the native `@COUNT(SKIPMISSING, ...)` function inside a block |
| Ignoring Parent Members | Using the count for Level 0 logic | The count returned by this function includes ALL members (Parents, Grandparents, and the Root). If you have 100 Level-0 stores, and 20 Parent regions, the function returns `120`. If you use `120` as the denominator to divide an allocation across the 100 stores, you will under-allocate the pool. If you need a strict count of ONLY Level-0 members, you must rely on advanced scripting arrays or native `@COUNT` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@COUNT`](../06_Mathematical/@COUNT.md) | The native Essbase equivalent used to count data blocks (e.g., how many members actually have data > 0), rather than counting structural outline members |
| [`@HspMbrList`](./@HspMbrList.md) | A companion function that retrieves the actual list of member names rather than just returning the integer count |
| [`@CalcMgrLogText`](../15_CalcMgr_Utility/@CalcMgrLogStrings.md) | Often used to print the integer returned by `@HspGetMbrCount` into the Job Console to validate metadata loads |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspgetmbrcount.html)
