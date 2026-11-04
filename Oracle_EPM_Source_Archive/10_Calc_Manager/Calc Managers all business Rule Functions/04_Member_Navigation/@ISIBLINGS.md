# @ISIBLINGS

## Overview

`@ISIBLINGS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates a horizontal array containing all of the siblings of a specified target member, **and explicitly includes the target member itself in the resulting array.**

*(The "I" stands for Inclusive).*

### Why Does This Function Exist—

In cross-dimensional allocations or peer-to-peer benchmarking, administrators often need to execute logic on an entire "family" of members that share the exact same parent. For example, if a script is calculating `"Q2"`, it might need to calculate the average of all the quarters in the year (`"Q1, Q2, Q3, Q4"`) to perform a smoothing allocation.
If you use the native `@SIBLINGS("Q2")` function, Essbase returns `"Q1", "Q3", "Q4"`, but it specifically *excludes* `"Q2"`. To get the full year, you would be forced to write `"Q2", @SIBLINGS("Q2")`. 
`@ISIBLINGS` natively fuses them together. By passing the target member, Essbase automatically bundles all the left siblings, the target member, and all the right siblings into a single, cohesive array. This guarantees that the entire horizontal generational tier (under that specific parent) is addressed uniformly.

### When to Use It

- **Peer Benchmarking**: Calculating an average across all sibling Cost Centers (e.g., all stores in the same region) to determine if a specific store is performing above or below the regional average.
- **Pro-Rata Allocations**: Summing up the headcount of all sibling entities to calculate a denominator for a proportional overhead distribution.
- **Reporting Arrays**: Creating a `DATAEXPORT` block that exports an entire horizontal tier of members (e.g., all the Months in a Quarter) simply by referencing one of the months.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@ISIBLINGS(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member that serves as the anchor. The function will find all members that share the exact same direct parent as this member. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members representing the entire sibling group.
- **Order of Return**: The array is returned in the exact Top-Down (or Left-to-Right) order defined by the outline. (e.g., if you ask for the Inclusive Siblings of `"Mar"`, it returns `"Jan", "Feb", "Mar", "Apr" ...`).
- **Inclusion**: The target `MemberName` is ALWAYS included in the array, situated in its correct structural position.
- **Only Child**: If you pass a member that is the *only* child of its parent (it has no siblings), the function will simply return the `MemberName` itself without throwing an error.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Outline Query**: It queries the active `.otl` outline. It finds the direct parent of the target member.
3. **Array Assembly**: It looks at that parent and grabs *every single one* of its immediate children, exactly as they are ordered in the outline.
4. **Return**: It returns that concatenated array (which naturally includes the target member) to the calculation engine or `FIX` statement.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Sibling Array

```essbase
/* 
   Assuming Q1, Q2, Q3, and Q4 all share the parent "Total_Year".
   Returns: "Q1", "Q2", "Q3", "Q4"
*/
@ISIBLINGS("Q3")
```

---

## Practical Examples

### Example 1: Pro-Rata Sibling Allocation

**Scenario**: A corporate expense is booked at the parent level (`"Total_Sales_Region"`). The script must allocate this expense down to the direct child regions (`"North"`, `"South"`, `"East"`, `"West"`). The allocation is based on proportional `"Headcount"`. To calculate the ratio for `"North"`, the script must divide North's Headcount by the SUM of the Headcount for ALL the siblings (North + South + East + West).

```essbase
FIX("FY25", "Working", @CHILDREN("Total_Sales_Region"))
    
    /* 
       1. Calculate the denominator.
       For every region we calculate, we sum the Headcount of ALL siblings.
       @ISIBLINGS ensures the current region's headcount is included in the total.
    */
    VAR vTotalSiblingHeadcount = @SUM(@ISIBLINGS(@CURRMBR("Entity"))->"Headcount");
    
    /* 
       2. Protect against Divide-By-Zero
    */
    IF(vTotalSiblingHeadcount > 0)
        
        /* 
           3. Execute the proportional allocation.
        */
        "Allocated_Expense" = "Total_Sales_Region"->"Corporate_Expense" 
                              * ("Headcount" / vTotalSiblingHeadcount);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting "Cousins" | Across different parents | Siblings are STRICTLY defined as members that share the EXACT same direct parent. If `"Store_A"` is in `"New_York"`, and `"Store_B"` is in `"Boston"`, they are NOT siblings, even if they are both at Level 0. `@ISIBLINGS("Store_A")` will never return `"Store_B"`. If you need to evaluate all Level 0 members regardless of parent, use `@LEVEL0` |
| Using it inside IF statements | `IF(@ISIBLINGS("Entity") == "USA")` | This function returns an array of multiple members. You cannot use standard mathematical equality (`==`) to compare an array to a single string inside an `IF` statement. This function belongs in `FIX` blocks or array processing functions like `@SUM`, `@MAX`, or `@AVG` |
| Confusing with Boolean | `@ISISIBLING` | If you are trying to write an `IF` statement to check *whether* a specific member is a sibling of another member, do NOT use this function. You must use the boolean equivalent: `@ISISIBLING("Target_Member")` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SIBLINGS`](./@SIBLINGS.md) | The non-inclusive version. Returns the exact same family array, but specifically EXCLUDES the starting target member |
| [`@ILSIBLINGS`](./@ILSIBLINGS.md) | Returns the target member and only the siblings physically ABOVE it in the outline (Left siblings) |
| [`@IRSIBLINGS`](./@IRSIBLINGS.md) | Returns the target member and only the siblings physically BELOW it in the outline (Right siblings) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISIBLINGS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isiblings.html)
