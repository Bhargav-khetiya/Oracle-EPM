# @RDESCENDANTS

## Overview

`@RDESCENDANTS` is a **member relationship function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns all **descendants** of a member **including the member itself**. The "R" stands for "Relative" or "Root-inclusive" — it's `@DESCENDANTS` plus the starting member.

### Why Does This Function Exist?

Many calculations need to process an entire sub-hierarchy including its root:
- Processing all entities INCLUDING the "Total Entity" parent
- Applying formulas to all accounts INCLUDING the summary account
- Scoping FIX blocks to include both parent and all children
- Building member sets that include the specified member and everything below it

### When to Use It

- When your FIX scope needs to include the parent member AND all its descendants
- When you need to process a complete sub-tree including the root
- When building allocation calculations that include the total level
- When you want to calculate at all levels of a hierarchy

---

## Category

**Member / Relationship / Navigation**

---

## Syntax

```essbase
@RDESCENDANTS(mbrName)
```

### Formal Syntax

```
@RDESCENDANTS(memberNameOrFunction)
```

Where:
- `memberNameOrFunction` — The root member of the sub-tree. This member IS included in the result, along with all its descendants.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name or function | ✅ Yes | The root member. @RDESCENDANTS returns this member AND all of its descendants at every level below it. If the member is a leaf (no children), returns only the member itself. |

---

## Return Value

**Return Type**: Member set (the specified member + all descendants at all levels)

---

## How It Works (Behind the Scenes)

1. **Full Sub-Tree**: @RDESCENDANTS traverses the entire sub-tree starting from the specified member. It includes every member at every generation level below.

2. **vs. @DESCENDANTS**: `@DESCENDANTS("X")` returns children, grandchildren, etc. but NOT "X" itself. `@RDESCENDANTS("X")` returns "X" AND all its descendants.

3. **vs. @IDESCENDANTS**: These are equivalent in most Essbase implementations — both return the member plus all descendants. @RDESCENDANTS and @IDESCENDANTS can be used interchangeably.

4. **FIX Performance**: Using @RDESCENDANTS in FIX on a sparse dimension processes blocks for the member AND all descendants. This can include upper-level blocks if they exist.

5. **Leaf Members**: If the specified member has no children, @RDESCENDANTS returns only the member itself (a set of one).

---

## Syntax Variants & Scenarios

### Variant 1: In FIX (Most Common)

```essbase
FIX(@RDESCENDANTS("Americas"))
    Revenue = Revenue * 1.10;
ENDFIX
```
Processes Americas AND all entities below it.

### Variant 2: In @SUM

```essbase
@SUM(Revenue, @RDESCENDANTS("Total Entity"))
```
Sums Revenue across Total Entity and all entities below.

### Variant 3: vs. @DESCENDANTS Comparison

```essbase
/* @DESCENDANTS: children, grandchildren only */
FIX(@DESCENDANTS("Americas"))  /* Entity_NA, Entity_CA, etc. — NOT Americas itself */
ENDFIX

/* @RDESCENDANTS: member + all descendants */
FIX(@RDESCENDANTS("Americas"))  /* Americas, Entity_NA, Entity_CA, etc. */
ENDFIX
```

### Variant 4: Nested in FIX

```essbase
FIX("FY25", "Working", @RDESCENDANTS("Total Entity"))
    Revenue = Units * Price;
ENDFIX
```

---

## Practical Examples

### Example 1: Apply Calculation to All Levels

**Scenario**: Calculate margin percentage at every level of the entity hierarchy.

```essbase
FIX("FY25", "Working", @RDESCENDANTS("Total Entity"))
    IF(Revenue > 0)
        "Margin_Pct" = "Gross Margin" / Revenue * 100;
    ELSE
        "Margin_Pct" = #MISSING;
    ENDIF
ENDFIX
```

**What Happens**:
- Calculates at leaf entities (Entity_NA, Entity_EU, etc.)
- ALSO calculates at Americas, EMEA, APAC (mid-level)
- ALSO calculates at Total Entity (top level)
- All hierarchy levels get their margin percentage

---

### Example 2: Variance at All Levels

```essbase
FIX("FY25", "Working", @RDESCENDANTS("Total Entity"))
    "Variance" = "Actual" - "Budget";
    IF(@ABS("Budget") > 0)
        "Var_Pct" = "Variance" / @ABS("Budget") * 100;
    ENDIF
ENDFIX
```

---

### Example 3: Data Validation Across Hierarchy

```essbase
FIX("FY25", @RDESCENDANTS("Total Entity"))
    IF(Revenue != #MISSING AND Revenue != 0)
        "Has_Data" = 1;
    ELSE
        "Has_Data" = 0;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| @RDESCENDANTS vs. @DESCENDANTS | @RDESCENDANTS INCLUDES the member; @DESCENDANTS excludes it | Use @RDESCENDANTS when you need the parent too |
| Upper-level calculations on sparse | Writing to upper-level sparse intersections can create unwanted blocks | Be intentional about which levels you write to |
| Performance with large hierarchies | @RDESCENDANTS on a top-level member includes everything — can be slow | Narrow with additional FIX dimensions |
| Redundant with @CHILDREN | For one-level-deep needs, @CHILDREN is clearer | Use @RDESCENDANTS only when you need multiple levels |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@DESCENDANTS`](./@DESCENDANTS.md) | Descendants WITHOUT the member itself |
| [`@IDESCENDANTS`](./@IDESCENDANTS.md) | Equivalent — inclusive descendants |
| [`@CHILDREN`](./@CHILDREN.md) | Immediate children only |
| [`@PARENT`](./@PARENT.md) | Navigate up |
| [`@ANCESTORS`](./@ANCESTORS.md) | All ancestors going up |
| [`@RELATIVE`](./@RELATIVE.md) | Members at a specific level |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @RDESCENDANTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/rdescendants.html)
