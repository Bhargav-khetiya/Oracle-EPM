# @ILDESCENDANTS

## Overview

`@ILDESCENDANTS` (Inclusive Level Descendants) is a **member selection function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It returns a specified member *and* all of its descendants down to a specific hierarchical level.

### Why Does This Function Exist?

Standard functions like `@DESCENDANTS("Parent")` return every single child, grandchild, and great-grandchild down to Level 0. 
But what if your hierarchy is deep, and you only want to process calculations down to the Regional level (Level 2), ignoring the individual Store level (Level 0)?
- Calculating regional management bonus pools without overriding store-level bonuses.
- Aggregating data up to a specific intermediate level.
- Pushing data from a top-level node down to an intermediate tier without flooding the base levels.

`@ILDESCENDANTS` allows you to stop the descendant search at a specific depth, and the "Inclusive" (`I`) prefix means it also includes the starting member in the list.

### When to Use It

- To restrict Top-Down allocations to a specific intermediate tier (e.g., allocating to Regions but not to Countries).
- In `FIX` statements to group a parent and a specific subset of its descendants.
- When generating member lists for reporting or cross-dimensional aggregations that shouldn't go all the way to Level 0.

---

## Category

**Member Selection / Hierarchy**

---

## Syntax

```essbase
@ILDESCENDANTS(mbrName, genLevNum | genLevName)
```

### Formal Syntax

```
@ILDESCENDANTS(memberExpression, generationOrLevelParameter)
```

Where:
- `memberExpression` — The starting parent member (e.g., `"Total Geography"`).
- `generationOrLevelParameter` — A number or name specifying the boundary. The function returns all descendants *down to and including* this boundary.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The starting parent member. Because this is the "Inclusive" version, this member is included in the output list. |
| `genLevNum` | Integer/String| ✅ Yes | The generation or level boundary. E.g., `2` (Level 2) or `"Region"`. |

---

## Return Value

**Return Type**: Member Set (List)

Returns a list consisting of `mbrName` plus all of its descendants down to the specified generation or level. 

---

## How It Works (Behind the Scenes)

1. **Top-Down Search**: Essbase starts at the specified `mbrName` and adds it to the list.
2. **Descension**: It looks at the children of that member and adds them to the list.
3. **Boundary Check**: Before looking at the grandchildren, it checks their level/generation against the `genLevNum` parameter. If they are within the boundary, it keeps going. Once it hits the boundary, it stops descending that branch.

*Note: If the `mbrName` itself is already below the specified boundary, it just returns the `mbrName`.*

---

## Syntax Variants & Scenarios

### Variant 1: Down to a Specific Level

```essbase
FIX(@ILDESCENDANTS("Total Entity", 1))
/* Includes Total Entity, plus all its descendants down to Level 1 
   (Ignores Level 0 base entities) */
```

### Variant 2: Down to a Specific Generation

```essbase
FIX(@ILDESCENDANTS("Total Entity", 3))
/* Includes Total Entity (Gen 1), Gen 2 members, and Gen 3 members.
   Ignores Gen 4+ */
```

---

## Practical Examples

### Example 1: Regional Management Overhead Allocation

**Scenario**: You have a pool of corporate overhead. You want to push it down to the Regions (Generation 3), but you do NOT want it pushed down to the individual stores (Generation 4/Level 0).

```essbase
/* We want to calculate on Corporate and the Regions, but not the stores */
FIX("FY25", "Working", @ILDESCENDANTS("Total Geography", 3))
    
    /* Because we used the "Inclusive" version, Total Geography is in our FIX.
       We only want to run the allocation ON the regions, so we filter out the parent. */
    IF(NOT @ISMBR("Total Geography"))
        "Allocated_Overhead" = @ALLOCATE(
            "Overhead_Pool" -> "Total Geography", 
            @DESCENDANTS("Total Geography", 3), /* The target regions */
            spread
        );
    ENDIF
    
ENDFIX
```
*(Note: Often `@LDESCENDANTS` (non-inclusive) is easier if you don't want the parent, but `ILDESCENDANTS` is perfect if the parent also needs calculation, such as an aggregation block).*

---

### Example 2: Intermediate Aggregation

**Scenario**: A massive cube takes too long to fully aggregate. You want to run a quick agg script that only rolls up Level 0 to Level 1, leaving the top-level parents un-aggregated for now.

```essbase
FIX("FY25", "Working")
    /* This calculates Level 1 members based on their Level 0 children.
       Using @ILDESCENDANTS("Total Entity", 1) includes Level 1 and Level 0. */
       
    AGG("Entity"); /* Standard AGG rolls up the whole tree, so we wouldn't use it here. */
    
    /* Better approach: Calculate Level 1 explicitly */
    FIX(@ILDESCENDANTS("Total Entity", 1))
        /* Custom rollup logic for intermediate tiers only */
    ENDFIX
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing `ILDESCENDANTS` with `LDESCENDANTS` | The `I` stands for Inclusive. `@ILDESCENDANTS` includes the starting parent. `@LDESCENDANTS` excludes the starting parent | Use `@LDESCENDANTS` if you only want the descendants and not the parent |
| Gen vs Level boundaries | Gen counts from Top (1). Level counts from Bottom (0) | Ensure you know whether your integer is targeting a Level or a Generation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@LDESCENDANTS`](./@LDESCENDANTS.md) | Same function, but excludes the starting parent member |
| [`@DESCENDANTS`](./@DESCENDANTS.md) | Goes all the way down to Level 0 |
| [`@RELATIVE`](./@RELATIVE.md) | Can return members at a specific level without returning the intermediate tiers |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ILDESCENDANTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ildescendants.html)
