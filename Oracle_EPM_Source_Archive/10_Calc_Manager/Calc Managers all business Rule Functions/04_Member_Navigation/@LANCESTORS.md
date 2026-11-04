# @LANCESTORS

## Overview

`@LANCESTORS` is a **member set function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **left ancestors** of a specified member. "Left ancestors" are the ancestors of the member that appear to the **left** (or before) the member's direct ancestry path in the outline, following the left-branch lineage. More precisely, it returns all ancestors of a member, navigating up the hierarchy through the **leftmost** (first child) path.

### Why Does This Function Exist—

In complex multi-level hierarchies, you may need to navigate or reference specific branches of the ancestor chain:
- Building roll-up calculations that follow a specific branch path
- Creating FIX statements that target left-branch ancestor members
- Implementing hierarchy-aware reporting that needs positional ancestor information
- Working with asymmetric hierarchies where left vs. right ancestry matters

### When to Use It

- When you need to build member sets that include left-branch ancestors
- In FIX statements to scope calculations to a specific hierarchy path
- When building reports that follow the left (first-child) path up the hierarchy
- Use `@LANCESTORS` for left ancestors; use `@ANCESTORS` for all ancestors

---

## Category

**Member Set / Relationship / Hierarchy**

---

## Syntax

```essbase
@LANCESTORS(member)
```

### Formal Syntax

```
@LANCESTORS(mbrName)
```

Where:
- `mbrName` — Any valid member in the outline

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name | ✅ Yes | The member whose left ancestors you want to retrieve. Can be a literal member name or `@CURRMBR(dimName)`. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Member has ancestors | Member set of left-branch ancestors (excluding the member itself) |
| Member is the dimension root | Empty set |

**Return Type**: Member set (used in FIX, member ranges, loops — NOT in arithmetic expressions)

---

## How It Works (Behind the Scenes)

1. **Hierarchy Navigation**: Essbase traverses upward from the given member through the outline hierarchy, collecting ancestors along the left (first-child) branch path.

2. **Exclusive**: The specified member itself is NOT included in the returned set. Use `@ILANCESTORS` for the inclusive version.

3. **Left-Branch Logic**: "Left" refers to outline order. The leftmost child of a parent is the first child listed in the outline. Left ancestors follow the first-child path upward.

4. **Member Set Function**: Returns a set of members, not data values. Use in FIX, LOOP, or other set contexts.

5. **Static Resolution**: The member set is determined at the start of calculation and does not change during execution.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Member

```essbase
FIX(@LANCESTORS("Product_X"))
    /* Calculates for all left-branch ancestors of Product_X */
ENDFIX
```

### Variant 2: With @CURRMBR

```essbase
@LANCESTORS(@CURRMBR("Entity"))
```
Returns the left ancestors of the currently-processing entity member.

### Variant 3: In Member Count

```essbase
@COUNT(@LANCESTORS("Leaf_Member"))
```
Counts the number of left-branch ancestors.

---

## Practical Examples

### Example 1: Left-Branch Ancestor Aggregation

**Scenario**: Recalculate totals for all left-branch ancestors of a specific leaf member after data changes.

```essbase
FIX(@LANCESTORS("US_East_Region_1"))
    AGG("Entity");
ENDFIX
```

---

### Example 2: Targeted Roll-Up

**Scenario**: Aggregate data only along the left path of the hierarchy.

```essbase
FIX("FY24", "Actual", @LANCESTORS("Product_SKU_001"))
    "Revenue" = @SUM(@CHILDREN(@CURRMBR("Product")));
ENDFIX
```

---

### Example 3: Hierarchy Path Reporting

**Scenario**: Flag all left-branch ancestors for inclusion in a management report.

```essbase
FIX(@LANCESTORS("Dept_Finance_Team_A"))
    "Include_In_Report" = 1;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with `@ANCESTORS` | `@ANCESTORS` returns ALL ancestors; `@LANCESTORS` returns only left-branch ancestors | Use `@ANCESTORS` when you need the complete ancestor chain |
| Expecting inclusive behavior | `@LANCESTORS` excludes the member itself | Use `@ILANCESTORS` for inclusive |
| Using in arithmetic | `@LANCESTORS` returns a member SET, not a value | Use in FIX, LOOP, or set functions only |
| Root member | Root has no ancestors — returns empty set | Add a guard condition if the member could be root |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ILANCESTORS`](./@ILANCESTORS.md) | **Inclusive** left ancestors (includes the member itself) |
| [`@ANCESTORS`](./@ANCESTORS.md) | Returns ALL ancestors (not just left branch) |
| [`@IALLANCESTORS`](./@IALLANCESTORS.md) | Inclusive all ancestors |
| [`@ALLANCESTORS`](./@ALLANCESTORS.md) | All ancestors from all branches |
| [`@PARENT`](./@PARENT.md) | Returns only the immediate parent |
| [`@LDESCENDANTS`](./@LDESCENDANTS.md) | Left descendants — reverse direction |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @LANCESTORS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/lancestors.html)
- [Oracle Essbase Technical Reference — @LANCESTORS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
