# @REMOVE

## Overview

`@REMOVE` is a **native Essbase member array function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a mathematical set-theory subtraction on two lists of dimension members. It takes a primary list of members, takes a secondary list of members, and mathematically subtracts the second list from the first. The resulting array contains only the members from the primary list that did NOT exist in the secondary list.

### Why Does This Function Exist—

When defining massive calculation blocks using `FIX` statements, or when passing arrays to functions like `@SUM`, administrators often need to include "everyone EXCEPT" a specific group. 
For example, you need to execute a calculation on EVERY level 0 Entity (`@LEVEL0("Total_Geography")`), EXCEPT for the Entities located in the `"Holding_Companies"` branch. 
Natively, you would have to write out every single valid branch manually: `FIX(@DESCENDANTS("North_America"), @DESCENDANTS("Europe"), @DESCENDANTS("Asia"))`. If the company adds a `"South_America"` branch later, the script completely misses it and the math fails.
`@REMOVE` allows for dynamic exclusion. You give it the entire universe of members (`@LEVEL0("Geography")`), and tell it to subtract the bad members (`@DESCENDANTS("Holding_Companies")`). If the outline changes, the function dynamically adapts, guaranteeing that your inclusion block is always mathematically perfect.

### When to Use It

- **Dynamic Exclusion Blocks**: Using it inside a `FIX` statement to globally lock down a calculation, explicitly preventing the math engine from touching specific placeholder accounts or closed cost centers.
- **Set Theory Logic**: Subtracting a list of "Completed Projects" from a list of "All Projects" to generate a dynamic, real-time list of "Active Projects" to feed into an aggregation.
- **Reporting Arrays**: Building a dynamic `DATAEXPORT` list that exports every month of the year *except* the active forecast month (so as not to overwrite live data in the target system).

---

## Category

**Member Selection / Set Theory & Array Manipulation / Essbase Native Functions**

---

## Syntax

```essbase
@REMOVE(list1, list2)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `list1` | Member List | ✅ Yes | The primary, master array of members (the starting universe). Can be a range (`Jan:Dec`), a hierarchy function (`@CHILDREN("Products")`), or a hardcoded list. |
| `list2` | Member List | ✅ Yes | The secondary array of members that you want to **delete/exclude** from `list1`. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members representing the mathematical subtraction (`list1 - list2`).
- **Order Preservation**: The returned members are typically output in the exact same physical outline order they appeared in `list1`.
- **No Overlap**: If `list2` contains members that don't even exist in `list1`, the function safely ignores them. It does not crash. It simply removes the intersections it finds.
- **Empty Result**: If `list2` perfectly mirrors `list1` (or is larger and encompasses it), the mathematical subtraction results in `0` members. The function returns an empty set. If used in a `FIX`, the `FIX` will safely execute zero blocks.

---

## How It Works (Behind the Scenes)

1. **Array Generation**: The engine compiles `list1` into Memory Array A. It compiles `list2` into Memory Array B.
2. **Intersection Scan**: It iterates through Array A. For every single member, it checks if that exact member exists anywhere in Array B.
3. **Subtraction**: If the member exists in Array B, it is instantly deleted from Array A. If it does not exist in Array B, it is kept.
4. **Return**: Once the scan is complete, it returns the surviving members of Array A to the `FIX` statement or mathematical function.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Subtraction

```essbase
/* 
   Starts with Jan, Feb, Mar, Apr.
   Subtracts Feb, Mar.
   Returns: "Jan", "Apr"
*/
@REMOVE(@LIST("Jan", "Feb", "Mar", "Apr"), @LIST("Feb", "Mar"))
```

---

## Practical Examples

### Example 1: Global Fixing with Specific Exclusions

**Scenario**: A massive corporate allocation script distributes `"Overhead"` to every single Level-0 Cost Center in the company. However, the Finance team dictates that `"CC_Admin"`, `"CC_Holding"`, and any cost centers under the `"Discontinued_Operations"` branch must NEVER receive allocations. The administrator uses `@REMOVE` inside the `FIX` statement to perfectly carve out the calculation universe.

```essbase
/* 
   1. The FIX statement uses @REMOVE to build the block constraint.
   - list1: EVERY Level-0 Cost Center in the database.
   - list2: We use @LIST to bundle the specific exclusions together:
            the Admin center, the Holding center, and all Discontinued centers.
*/
FIX("FY25", "Working", 
    @REMOVE(
        @LEVEL0("Cost_Centers"), 
        @LIST("CC_Admin", "CC_Holding", @DESCENDANTS("Discontinued_Operations"))
    )
)
    
    /* 
       2. The math executes safely. The excluded centers will never be touched.
    */
    "Allocated_Overhead" = "Total_Overhead"->"No_Cost_Center" * ("Headcount" / "Total_Headcount");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Reverse Order | `@REMOVE(Bad_List, Master_List)` | Set subtraction is NOT commutative. `A - B` is not the same as `B - A`. If you write `@REMOVE("CC_Admin", @LEVEL0("Cost_Centers"))`, you are asking the engine to take the Admin center, and subtract every cost center in the company from it. This will always result in an empty list. `list1` MUST be the Master universe. `list2` MUST be the items you want to delete |
| Omitting `@LIST` | `@REMOVE(A, B, C)` | `@REMOVE` accepts exactly TWO arguments: `list1` and `list2`. If you want to remove two distinct members (e.g., `B` and `C`) from `A`, you cannot write `@REMOVE(A, B, C)`. The compiler will crash with a parameter error. You MUST wrap the exclusions into a single list object: `@REMOVE(A, @LIST(B, C))` |
| Performance Strain | Massive Intersections | `@REMOVE` is an array-processing function. If `list1` has 500,000 members, and `list2` has 100,000 members, Essbase has to perform 50,000,000,000 internal string comparisons before the calculation even starts. In massively sparse dimensions, it is sometimes faster to `FIX` on the universe, and just put an `IF` statement inside to skip the exclusions |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@INTERSECT`](../04_Member_Navigation/@INTERSECT.md) | The mathematical inverse (Set Intersection). Takes two lists and returns ONLY the members that exist in BOTH lists |
| [`@MERGE`](./@MERGE.md) | Set Addition. Takes two lists and mathematically fuses them together into a single, unified list with duplicates removed |
| [`@LIST`](./@LIST.md) | The required container function used to bundle multiple distinct exclusions into `list2` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — REMOVE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/remove.html)
