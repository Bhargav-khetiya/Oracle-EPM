# @ICHILDREN

## Overview

`@ICHILDREN` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates an array of the immediate, first-generation children below a specified parent member, **and explicitly includes the parent member itself in the resulting array.**

*(The "I" stands for Inclusive).*

### Why Does This Function Exist—

When building calculation logic, administrators frequently need to address a parent and its direct sub-components simultaneously. For example, if `"Total_Marketing"` has three direct children (`"Digital"`, `"Print"`, `"Events"`), you might need to apply an overhead factor to all four of those members.
Native `@CHILDREN` would return Digital, Print, and Events, but it would *exclude* `"Total_Marketing"`. To include the parent, you would have to write `"Total_Marketing", @CHILDREN("Total_Marketing")`. 
`@ICHILDREN` solves this by natively wrapping them into a single, cohesive array. It returns the parent member followed immediately by its direct children, making cross-dimensional allocations and block clearing significantly cleaner to write.

### When to Use It

- **Parent/Child Zero-Outs**: Clearing data at a specific parent node AND clearing the data of its immediate child inputs to ensure a clean slate before executing an aggregation.
- **Targeted Allocations**: Pushing a corporate reserve (held at a parent entity) down evenly strictly to its direct reporting children, without pushing it all the way down to the bottom of the hierarchy.
- **Reporting Groupings**: Creating a concise `DATAEXPORT` block that exports a summary line (the parent) immediately followed by the high-level breakdown (the children), without exporting the thousands of underlying leaf nodes.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@ICHILDREN(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target parent member serving as the starting anchor for the query. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members.
- **Order of Return**: The array ALWAYS begins with the target `MemberName` (the parent), followed by its immediate children in the exact top-down order they appear in the Outline.
- **Depth Limitation**: This function strictly goes **one level down**. If the children have children of their own (grandchildren), they are NOT included.
- **Empty Traversal**: If you pass a Level 0 member (a leaf node that has no children), the function simply returns the `MemberName` itself without throwing an error.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Outline Query**: It queries the active `.otl` outline. It locates the target member and asks: "Who are your direct descendants exactly one step below you—
3. **Array Assembly**: It grabs those direct children in outline order.
4. **Inclusion**: It prepends the original `MemberName` to the front of the list.
5. **Return**: It returns the concatenated array to the `FIX` statement or calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Parent/Child Selection

```essbase
/* 
   Assuming Total_Hardware has two children: Servers and Laptops.
   Returns: "Total_Hardware", "Servers", "Laptops"
*/
@ICHILDREN("Total_Hardware")
```

---

## Practical Examples

### Example 1: Localized Overhead Clearance

**Scenario**: A Top-Down allocation script distributes `"Admin_Overhead"` from `"Total_Region"` down to its direct sub-regions (`"North"`, `"South"`, `"East"`, `"West"`). Before the allocation runs, the script must ensure that both the Parent holding bucket and all the Child receiving buckets are completely cleared of any old data from the previous run to prevent double-counting.

```essbase
/* 
   1. The FIX statement uses @ICHILDREN to target Total_Region 
   AND its 4 direct sub-regions simultaneously.
*/
FIX("FY25", "Working", @ICHILDREN("Total_Region"))
    
    /* 
       2. Clear the Admin Overhead. 
       Because of ICHILDREN, this executes exactly 5 times.
       It clears the Parent, and then clears the 4 children.
    */
    "Admin_Overhead" = 0;
    
ENDFIX

/* 
   3. Now the script can safely run the @ALLOCATE function 
   knowing the blocks are zeroed out.
*/
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with Descendants | `@ICHILDREN` vs `@IDESCENDANTS` | `@ICHILDREN` is strictly limited to the first generation below the parent. If `"North"` has 50 individual stores underneath it, `@ICHILDREN("Total_Region")` will completely ignore those stores. If you want the parent and EVERY SINGLE member below it all the way to the bottom, you MUST use `@IDESCENDANTS` |
| Using it inside IF statements | `IF(@ICHILDREN("Entity") == "USA")` | This function returns a list (an array of members). You cannot use standard mathematical equality (`==`) to compare an array of multiple members to a single string inside an `IF` statement. It will throw a syntax error. Only use this inside `FIX` blocks, `@SUM` ranges, or as targets for allocation functions |
| Implicit Aggregation Conflicts | Calculating a parent while calculating its children | If you use `@ICHILDREN` inside a `FIX`, and your formula assigns data (`"Account" = 50`), it will write `50` to the children, AND `50` to the parent. If you subsequently run an `AGG("Entity")`, the children will roll up and crush the parent's data. Be very careful assigning data to parents and children simultaneously unless it's a clearing/zero-out operation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CHILDREN`](./@CHILDREN.md) | The non-inclusive version. Returns the exact same children, but specifically EXCLUDES the parent target member |
| [`@IDESCENDANTS`](./@IDESCENDANTS.md) | The deep-traversal version. Returns the parent and ALL descendants down to the absolute bottom of the outline, not just the first step |
| [`@IALLANCESTORS`](./@IALLANCESTORS.md) | The inverse traversal. Starting from the child, it returns the member and everything strictly ABOVE it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ICHILDREN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ichildren.html)
