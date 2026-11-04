# @LDESCENDANTS

## Overview

`@LDESCENDANTS` is a **member set function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **left descendants** of a specified member. "Left descendants" are the members in the left (first-child) branch of the hierarchy below the given member. It follows the leftmost child path downward through the hierarchy.

### Why Does This Function Exist—

In complex hierarchies, you may need to target only the first-child branch for specific calculations:
- Building waterfall calculations that follow the primary branch
- Targeting the "default" or "primary" path in an asymmetric hierarchy
- Creating hierarchical drill-down reports following the leftmost path
- Implementing specific aggregation patterns along the primary branch

### When to Use It

- When you need to scope a calculation to only the left-branch descendants
- In FIX statements to target the primary hierarchy path
- When building reporting member sets that follow the first-child lineage downward
- Use `@LDESCENDANTS` for exclusive; use `@ILDESCENDANTS` for inclusive

---

## Category

**Member Set / Relationship / Hierarchy**

---

## Syntax

```essbase
@LDESCENDANTS(member)
```

### Formal Syntax

```
@LDESCENDANTS(mbrName)
```

Where:
- `mbrName` — Any valid member in the outline

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name | ✅ Yes | The member whose left descendants you want to retrieve. Can be a literal member name or `@CURRMBR(dimName)`. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Member has children | Member set of left-branch descendants (excluding the member itself) |
| Member is a leaf (level 0, no children) | Empty set |

**Return Type**: Member set (used in FIX, member ranges, loops)

---

## How It Works (Behind the Scenes)

1. **Hierarchy Traversal**: Essbase navigates downward from the given member, following the **leftmost (first) child** at each level. It collects all members along this left-branch path.

2. **Exclusive**: The specified member itself is NOT included. Use `@ILDESCENDANTS` for inclusive.

3. **Left-Branch Only**: Only the first child at each level is followed. Other children (right branches) are excluded.

4. **Member Set**: Returns a set for use in FIX, LOOP, or other member set contexts.

5. **Static Resolution**: Resolved at calculation start time based on the current outline.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Usage

```essbase
FIX(@LDESCENDANTS("Total_Entity"))
    /* Only processes the left-branch descendants of Total_Entity */
ENDFIX
```

### Variant 2: With @CURRMBR

```essbase
@LDESCENDANTS(@CURRMBR("Product"))
```

### Variant 3: Count Left Descendants

```essbase
@COUNT(@LDESCENDANTS("Year"))
```

---

## Practical Examples

### Example 1: Primary Branch Aggregation

**Scenario**: Recalculate aggregations only along the primary (left) branch of the entity hierarchy.

```essbase
FIX("FY24", "Actual", @LDESCENDANTS("Total_Entity"))
    AGG("Entity");
ENDFIX
```

---

### Example 2: Default Path Data Population

**Scenario**: Populate default assumptions along the primary product branch.

```essbase
FIX("FY24", "Budget", @LDESCENDANTS("All_Products"))
    "Growth_Rate" = 0.05; /* 5% default for primary product line */
ENDFIX
```

---

### Example 3: Waterfall Report Members

**Scenario**: Mark left-branch members for inclusion in a waterfall chart.

```essbase
FIX(@LDESCENDANTS("Total_Revenue"))
    "Waterfall_Include" = 1;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with `@DESCENDANTS` | `@DESCENDANTS` returns ALL descendants. `@LDESCENDANTS` returns only the left branch. | Use `@DESCENDANTS` for the full subtree |
| Expecting inclusive behavior | `@LDESCENDANTS` excludes the member itself | Use `@ILDESCENDANTS` for inclusive |
| Using in arithmetic | Returns a member SET, not a value | Use in FIX, LOOP, or set functions only |
| Leaf members | A leaf member has no descendants — returns empty set | Check member level before calling |
| Assuming it includes all left members | It follows only the first-child path, not all "left" children at each level | Understand the outline hierarchy structure |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ILDESCENDANTS`](./@ILDESCENDANTS.md) | **Inclusive** left descendants (includes member itself) |
| [`@DESCENDANTS`](./@DESCENDANTS.md) | Returns ALL descendants (not just left branch) |
| [`@IDESCENDANTS`](./@IDESCENDANTS.md) | Inclusive all descendants |
| [`@RDESCENDANTS`](./@RDESCENDANTS.md) | Right-branch descendants |
| [`@LANCESTORS`](./@LANCESTORS.md) | Left ancestors — reverse direction |
| [`@CHILDREN`](./@CHILDREN.md) | Returns only direct children (all, not just left) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @LDESCENDANTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ldescendants.html)
- [Oracle Essbase Technical Reference — @LDESCENDANTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
