# @IANCESTORS

## Overview

`@IANCESTORS` (Inclusive Ancestors) is a **member selection function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It returns a specified member *and* all of its ancestors (parents, grandparents, up to the top of the dimension).

### Why Does This Function Exist?

When a calculation alters a data value at a base level (Level 0), the parent totals above it are now mathematically incorrect until an aggregation (`AGG` or `CALC DIM`) is run.
Running a full `AGG` on a massive dimension just to fix one branch is highly inefficient.
`@IANCESTORS` allows you to select a specific base member and precisely walk up its family tree, calculating only the exact parents that were affected by the change.

### When to Use It

- For **targeted aggregations** (Partial Aggs) to optimize performance.
- When you need to clear data from a specific branch of the hierarchy without touching the rest of the outline.
- In reporting functions to pull all parent totals for a specific node.

---

## Category

**Member Selection / Hierarchy / Aggregation**

---

## Syntax

```essbase
@IANCESTORS(mbrName)
```

### Formal Syntax

```
@IANCESTORS(memberExpression)
```

Where:
- `memberExpression` — The starting member (the lowest node you want to walk up from).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The starting member. Because this is the "Inclusive" version, this member is included in the output list. |

---

## Return Value

**Return Type**: Member Set (List)

Returns a list consisting of `mbrName` plus all of its ancestors (parent, grandparent, great-grandparent) all the way to Generation 1 of the dimension. 
The list is typically ordered from the member itself up to the highest ancestor.

---

## How It Works (Behind the Scenes)

1. **Bottom-Up Search**: Essbase identifies the `mbrName`.
2. **Ascension**: It looks at the immediate parent, adds it to the list, then looks at that parent's parent, and continues until it hits the root of the dimension.
3. **Execution Order**: When used in a calculation block (like aggregating), Essbase is smart enough to aggregate bottom-up, ensuring the parent is calculated before the grandparent.

---

## Syntax Variants & Scenarios

### Variant 1: Targeted Aggregation

```essbase
FIX(@IANCESTORS("Store_101"))
    /* Rolls up only the branch containing Store 101 */
ENDIF
```

---

## Practical Examples

### Example 1: High-Performance Partial Aggregation

**Scenario**: A user submits a data change for a single Cost Center (`CC_Marketing_NY`) via a web form. You want a Business Rule attached to "Save" that instantly rolls up the data so the user sees the new regional and global totals, but a full `CALC DIM("Entity")` takes 5 minutes.

```essbase
/* Focus the calculation ONLY on the submitted Cost Center and its direct lineage */
FIX("FY25", "Working", @IANCESTORS("CC_Marketing_NY"))
    
    /* Re-aggregate the sparse dimensions for this specific slice */
    /* This will calculate NY_State, East_Coast, USA, and Total_Entity in milliseconds */
    AGG("Product", "Customer"); 
    
    /* Note: If Entity is sparse, a simple AGG doesn't work on a partial list 
       the same way. You often use a targeted CALC DIM or dense rollup logic. */
ENDFIX
```
*(A more accurate Essbase BSO approach for a sparse partial agg is to use `@ANCESTORS` in a calculation loop, or rely on Dynamic Calc parents for instant aggregation).*

---

### Example 2: Clearing a Specific Branch

**Scenario**: A division ("Wholesale") was reorganized and its historical budget data needs to be wiped clean from the base level all the way to the top of its specific branch, without clearing the "Retail" division.

```essbase
FIX("FY25", "Budget")
    FIX(@IANCESTORS("Div_Wholesale"))
        CLEARDATA "Total_Expenses";
    ENDFIX
ENDFIX
```
*(This clears `Div_Wholesale`, its parent, its grandparent, etc., ensuring no residual data is stuck at upper levels).*

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing `IANCESTORS` with `ANCESTORS` | The `I` stands for Inclusive. `@IANCESTORS` includes the starting member. `@ANCESTORS` excludes the starting member | Use `@ANCESTORS` if you only want the parents and not the base member |
| Multiple Parents (Shared Members) | If a member is a Shared Member, `@IANCESTORS` walks up the tree of the *primary* instance unless explicitly targeted | Ensure you know which branch of a shared hierarchy you are walking |
| Using for single parent retrieval | `@IANCESTORS("Store")` returns a list of 5 members. You cannot assign data to it directly | Use `@ANCEST(mbr, 1)` or `@PARENT(mbr)` if you just want the immediate parent |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ANCESTORS`](./@ANCESTORS.md) | Same function, but excludes the starting member |
| [`@ANCEST`](./@ANCEST.md) | Returns exactly one specific ancestor, rather than the whole list |
| [`@PARENT`](./@PARENT.md) | Returns the immediate parent |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @IANCESTORS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/iancestors.html)
