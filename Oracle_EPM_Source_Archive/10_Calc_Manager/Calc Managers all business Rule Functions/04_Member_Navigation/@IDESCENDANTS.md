# @IDESCENDANTS

## Overview

`@IDESCENDANTS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates a comprehensive, top-down array of all members residing strictly below a specified parent member, **and explicitly includes the target parent member itself at the very beginning of the array.**

*(The "I" stands for Inclusive).*

### Why Does This Function Exist—

When building robust EPM calculation scripts (like Aggregations, Clear Scripts, or targeted Allocations), it is nearly universal to execute logic on an entire branch of a hierarchy. For instance, an administrator might need to clear data for `"North_America"` and every single state and store beneath it before running a fresh data import.
If they use the native `@DESCENDANTS("North_America")` function, Essbase returns all the underlying states and stores, but it specifically ignores the `"North_America"` parent block itself. To clear both the children and the parent, the administrator would be forced to write `"North_America", @DESCENDANTS("North_America")`. 
`@IDESCENDANTS` simplifies this by fusing them together. By passing a single parent member, Essbase automatically bundles the parent and every single node underneath it into a contiguous calculation array, guaranteeing that the entire branch is addressed uniformly.

### When to Use It

- **Total Branch Clearances**: Zeroing out a parent holding bucket and all of its subordinate base accounts simultaneously using `CLEARBLOCK ALL`.
- **Custom Aggregations**: Using `@CALCMODE(BOTTOMUP)` to force an explicit, sequenced rollup of a specific ragged hierarchy branch, requiring the script to be fixed on both the base and parent members.
- **Reporting & Data Export**: Creating a `DATAEXPORT` selection that outputs a clean, hierarchical dataset (starting with the parent total, followed immediately by its detailed breakdown components).

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@IDESCENDANTS(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target parent member that serves as the starting anchor (the top) of the traversal branch. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members representing the entire hierarchical branch.
- **Order of Return**: The array ALWAYS begins with the target `MemberName`. It then proceeds Top-Down, listing children, grandchildren, and all descendants exactly as they are ordered structurally in the Outline.
- **Depth**: It traverses all the way down to Level 0 (the absolute bottom of the outline).
- **Empty Traversal**: If you pass a Level 0 member (which inherently has no descendants), the function simply returns the `MemberName` itself without throwing an error.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Outline Query**: It queries the active `.otl` outline. It locates the target member and initiates a recursive downward sweep of the hierarchical tree.
3. **Array Assembly**: It grabs every single node that rolls up into the target member, maintaining the outline's structural sorting.
4. **Inclusion**: It prepends the original `MemberName` to the absolute front of the list.
5. **Return**: It returns the concatenated array to the `FIX` statement or calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Branch Selection

```essbase
/* 
   Assuming Total_OpEx has two children: Salary and Travel.
   Returns: "Total_OpEx", "Salary", "Travel"
*/
@IDESCENDANTS("Total_OpEx")
```

---

## Practical Examples

### Example 1: Full-Branch Data Clearance Before Allocation

**Scenario**: A Top-Down allocation script distributes `"Corporate_Tax"` from the `"Global"` entity down to `"North_America"` and all of its individual stores. Before the allocation runs, the script must ensure that the entire `"North_America"` branch is completely cleared of any old data from the previous calculation run. If the parent isn't cleared, subsequent aggregations will double-count the data.

```essbase
/* 
   1. The FIX statement uses @IDESCENDANTS to lock onto North_America 
   AND every single state, region, and store beneath it simultaneously.
*/
FIX("FY25", "Working", @IDESCENDANTS("North_America"))
    
    /* 
       2. Clear the Tax Allocation account. 
       This zeroes out the base-level stores AND the parent consolidation 
       blocks in a single, highly optimized pass.
    */
    CLEARBLOCK ALL;
    
ENDFIX

/* 
   3. The script can now safely push new allocations down to the base stores, 
   knowing the environment is perfectly clean.
*/
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Allocation Logic Here */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with `@ICHILDREN` | `@IDESCENDANTS` vs `@ICHILDREN` | `@ICHILDREN` is strictly limited to the first generation below the parent. `@IDESCENDANTS` penetrates all the way to the bottom of the outline. If you just want the immediate children and not the 10,000 leaf nodes beneath them, DO NOT use `@IDESCENDANTS`. You will accidentally pull thousands of unwanted blocks into memory |
| Using it inside IF statements | `IF(@IDESCENDANTS("Entity") == "USA")` | This function returns a massive array (a list of multiple members). You cannot use standard mathematical equality (`==`) to compare an array to a single string inside an `IF` statement. If you want to check if the current member is a descendant of something, use `@ISDESC("Parent")` instead |
| Implicit Aggregation Conflicts | Assigning data to the array | If you write `"Account" = 50;` while fixed on `@IDESCENDANTS("Total")`, Essbase writes `50` to the base stores, AND writes `50` to the parents. When you run an `AGG("Entity")`, the base stores roll up and crush the `50` you wrote to the parent. Be very careful assigning raw math to a mixed parent/child array unless it is a zero-out operation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@DESCENDANTS`](./@DESCENDANTS.md) | The non-inclusive version. Returns the exact same branch of the tree, but strictly EXCLUDES the starting parent member |
| [`@ICHILDREN`](./@ICHILDREN.md) | The shallow-traversal version. Returns the parent and ONLY the immediate first-generation children below it |
| [`@IALLANCESTORS`](./@IALLANCESTORS.md) | The inverse traversal. Starting from the bottom, it returns the member and everything strictly ABOVE it up to the root |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — IDESCENDANTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/idescendants.html)
