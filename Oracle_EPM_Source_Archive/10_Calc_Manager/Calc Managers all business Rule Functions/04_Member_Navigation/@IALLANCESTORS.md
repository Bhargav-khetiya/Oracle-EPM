# @IALLANCESTORS

## Overview

`@IALLANCESTORS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates a top-down array of all ancestor members (parents, grandparents, up to the root) for a specific target member, **and it explicitly includes the target member itself in the resulting array.**

*(The "I" stands for Inclusive).*

### Why Does This Function Exist?

In complex allocations, administrators frequently need to trace a data point upward through its hierarchy. For example, if `"Store_101"` fails a profitability threshold, the script might need to log an error not just for the store, but for the `"District"`, `"Region"`, and `"Total_Company"` that own it. 
Native `@ANCESTORS` would return the District, Region, and Company, but it would *exclude* `"Store_101"`. To include the store, you would have to write `"Store_101", @ANCESTORS("Store_101")`. 
`@IALLANCESTORS` solves this by combining them perfectly. It generates a clean, contiguous lineage array (from the root down to the target member), guaranteeing that both the hierarchical rollout and the starting base point are included in a single selection command.

### When to Use It

- **Lineage Tracing & Logging**: Extracting the full hierarchical path of a member to write a detailed, fully-qualified error path (e.g., `Total -> USA -> East -> Store_101`) to the Job Console.
- **Top-Down Security Clearing**: Clearing data or attributes starting from the very top of a hierarchy down to a specific impacted node, ensuring the entire branch above it is reset.
- **Cross-Dimensional Allocations**: Applying a standard corporate driver (held at the root) and overriding it at every intermediate parent level all the way down to the base node.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@IALLANCESTORS(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member serving as the starting point (the bottom) of the lineage trace. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members representing the direct lineage.
- **Order of Return**: The array is returned **Top-Down**. It starts with the absolute root of the dimension, proceeds down through the grandparents and parents, and ends with the `MemberName` itself.
- **Inclusion**: The target `MemberName` is ALWAYS the final member in the array.
- **Empty Traversal**: If you pass the absolute root of a dimension (e.g., `@IALLANCESTORS("Total_Entity")`), it simply returns `"Total_Entity"`, because it has no higher ancestors.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Outline Query**: It queries the active `.otl` outline. It looks at the target member and asks: "Who is your parent?" It stores that parent. Then it asks the parent: "Who is your parent?"
3. **Root Detection**: It continues climbing the tree until it hits a member that has no parent (the Generation 1 root of the dimension).
4. **Array Assembly**: It reverses the trace, assembling the members in a Top-Down order.
5. **Inclusion**: It appends the original `MemberName` to the bottom of the list.
6. **Return**: It returns the full array to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Lineage Extraction

```essbase
/* 
   If Store_101 rolls up to New_York, which rolls up to USA, 
   which rolls up to Total_Entity.
   
   Returns: "Total_Entity", "USA", "New_York", "Store_101"
*/
@IALLANCESTORS("Store_101")
```

---

## Practical Examples

### Example 1: Full-Path Audit Logging

**Scenario**: A data validation script runs on Level-0 Stores. If a store has negative `"Net_Income"`, it must throw an error. However, the business users don't just want to know the store name; they want the full organizational lineage printed in the Job Console so they know exactly which Regional VP to call. The script uses a loop and `@IALLANCESTORS` to build a breadcrumb string.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Net_Income" < 0)
        
        /* 1. We need a variable to hold the breadcrumb string */
        VAR vLineageString = "Path: ";
        
        /* 
           2. We use @IALLANCESTORS to get the lineage (e.g. Total, Region, Store).
           We iterate through that list.
        */
        /* Note: In standard calc scripts, looping through a member list 
           requires specific CDFs or string builders, but conceptually: */
           
        /* Get the full inclusive lineage array */
        VAR vList = @CalcMgrListToCommaString(@IALLANCESTORS(@CURRMBR("Entity")));
        
        /* 3. Log the massive string to the console */
        VAR vLog = @CalcMgrLogMemberStrings("Negative Income Detected -> ", vList);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Bottom-Up Sorting | Assuming the array starts with the target | `@IALLANCESTORS` returns the list TOP-DOWN (Root first). If you are writing a script that applies an override logic (where the most specific level should win), Top-Down sorting means the Root calculates first, then the Parent overwrites it, then the Base overwrites it. If you need Bottom-Up evaluation, you must reverse the array |
| Confusing Ancestors with Relatives | "Give me my uncles" | Ancestors ONLY return the direct, vertical bloodline (Parent, Grandparent, Root). It does NOT return "Uncles" (siblings of the parent). If `"Store_101"` and `"Store_102"` share a parent, calculating the ancestors of `"Store_101"` will NEVER touch `"Store_102"`. If you need siblings, you must use `@SIBLINGS` |
| Using it inside IF statements | `IF(@IALLANCESTORS("X") == "Y")` | This function returns a massive array (a list of multiple members). You cannot use standard mathematical equality (`==`) to compare an array to a single string or member inside an `IF` statement. This function belongs in `FIX` blocks, `@SUM` ranges, or array processing CDFs |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ANCESTORS`](./@ANCESTORS.md) | The non-inclusive version. Returns the exact same lineage tree, but strictly EXCLUDES the starting target member |
| [`@IDESCENDANTS`](./@IDESCENDANTS.md) | The exact opposite. Starting from a parent, it returns the target member and everything strictly BELOW it |
| [`@IANCESTORS`](./@IANCESTORS.md) | A variation that typically allows bounding the ancestor climb to a specific number of generations, rather than climbing "ALL" the way to the root |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — IALLANCESTORS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/iallancestors.html)
