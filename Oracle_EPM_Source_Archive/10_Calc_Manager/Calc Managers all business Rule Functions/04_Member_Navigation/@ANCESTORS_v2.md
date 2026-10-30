# @ANCESTORS

## Overview

`@ANCESTORS` is a **member set function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **set of ancestors** of a specified member, optionally limited to a specific generation or level. Unlike `@ALLANCESTORS` which always returns every ancestor up to the root, `@ANCESTORS` can be constrained to return ancestors only up to a certain point.

### Why Does This Function Exist?

When building calculations that need to operate on multiple levels of a hierarchy but not necessarily all the way to the root, `@ANCESTORS` provides the needed control. For example:
- Get all ancestors up to the regional level (but not the global root)
- Process ancestors within a specific range of generations
- Build member sets for targeted FIX blocks

### When to Use It

- When you need ancestors up to a specific generation or level
- In FIX statements to limit processing to a portion of the hierarchy
- When building partial rollup logic
- In combination with other set functions for complex member selections

---

## Category

**Member Set / Relationship**

---

## Syntax

```essbase
@ANCESTORS(member)
@ANCESTORS(member, generation)
@ANCESTORS(member, levelOrGenName)
```

### Formal Syntax Variants

```
@ANCESTORS(memberExpression)
@ANCESTORS(memberExpression, genNumber)
@ANCESTORS(memberExpression, genOrLevelName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name or expression | ✅ Yes | The member whose ancestors to retrieve. Can be a literal name, `@CURRMBR`, or another member function. |
| `generation` | Integer or Name | ❌ No | Optional. Limits the ancestors returned. If an integer, specifies the topmost generation to include. If a named generation/level, uses that as the boundary. If omitted, returns ALL ancestors (same as `@ALLANCESTORS`). |

---

## Return Value

Returns a **member set** containing ancestors of the specified member. The specified member itself is **NOT** included.

| Condition | Returns |
|-----------|---------|
| No generation limit | All ancestors up to root (same as `@ALLANCESTORS`) |
| With generation limit | Ancestors from parent up to the specified generation |
| Member is root | Empty set |

**Return Type**: Member set

---

## How It Works (Behind the Scenes)

1. **Upward Traversal**: Starts at the specified member's parent and walks up the hierarchy.
2. **Generation Boundary**: If a generation is specified, traversal stops when it reaches that generation level. Members at or above the boundary generation are included.
3. **Exclusive of Source**: The starting member is never included in the result set. Use `@IANCESTORS` for the inclusive version.
4. **Order**: Results are ordered from the immediate parent upward.

---

## Syntax Variants & Scenarios

### Variant 1: All Ancestors (No Limit)

```essbase
@ANCESTORS("New_York")
```
Returns all ancestors: `US_East, North_America, Total_Entity`

### Variant 2: Ancestors Up to Generation 2

```essbase
@ANCESTORS("New_York", 2)
```
If hierarchy is Gen1=Total_Entity, Gen2=North_America, Gen3=US_East, Gen4=New_York:
Returns: `US_East, North_America` (stops at Gen 2)

### Variant 3: In a FIX Block

```essbase
FIX(@ANCESTORS("Product_X", 2))
    "Status" = 1;
ENDFIX
```

### Variant 4: Dynamic with @CURRMBR

```essbase
@ANCESTORS(@CURRMBR("Entity"), 2)
```

---

## Practical Examples

### Example 1: Update Status Flags for All Ancestors

**Scenario**: When a leaf entity submits data, flag all its ancestors (up to region level) as "Pending Review".

```essbase
FIX("Actual", "FY24", "Jan")
    @LEVMBRS("Entity", 0)(
        IF("Submit_Flag" == 1)
            FIX(@ANCESTORS(@CURRMBR("Entity"), 2))
                "Review_Status" = 2; /* 2 = Pending Review */
            ENDFIX
        ENDIF
    )
ENDFIX
```

### Example 2: Partial Rollup Calculation

**Scenario**: Calculate an average metric at each intermediate ancestor level.

```essbase
FIX("Actual", "FY24")
    @LEVMBRS("Product", 0)(
        FIX(@ANCESTORS(@CURRMBR("Product")))
            "Avg_Price" = @AVG("Unit_Price", @CHILDREN(@CURRMBR("Product")));
        ENDFIX
    )
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting the source member in results | `@ANCESTORS` excludes the starting member | Use `@IANCESTORS` for inclusive |
| Confusing generation vs level numbers | Generation counts from top (root=1); Level counts from bottom (leaf=0) | Verify your dimension's numbering |
| Using on root member | Returns empty set — no ancestors exist | Check member position first |
| Wrong generation boundary | If generation number is too high (below member), no ancestors match | Ensure generation < member's own generation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@IANCESTORS`](@IANCESTORS.md) | Inclusive version — includes the member itself |
| [`@ALLANCESTORS`](@ALLANCESTORS.md) | Always returns all ancestors to root |
| [`@ANCEST`](@ANCEST.md) | Returns a single ancestor at a specific generation |
| [`@ANCESTVAL`](../05_Data_Access/@ANCESTVAL.md) | Returns the data value at an ancestor |
| [`@PARENT`](@PARENT.md) | Returns only the immediate parent |
| [`@DESCENDANTS`](@DESCENDANTS.md) | Inverse — returns children/descendants going downward |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ANCESTORS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ancestors.html)
