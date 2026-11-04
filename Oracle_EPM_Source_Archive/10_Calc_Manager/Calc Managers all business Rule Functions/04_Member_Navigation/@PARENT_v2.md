# @PARENT

## Overview

`@PARENT` is a **member relationship function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **parent member** of a specified member in the outline hierarchy. It navigates one level up in the dimension tree.

### Why Does This Function Exist—

Essbase outlines are hierarchical — every member (except the dimension root) has a parent. Many calculations need to reference the parent level:
- Comparing a department's value to its division total
- Calculating a member's percentage contribution to its parent
- Navigating the hierarchy dynamically based on current member position
- Building dynamic formulas that work across different hierarchy levels

### When to Use It

- To calculate a member's share of its parent's total
- To reference a parent member in a cross-dimensional expression
- To build dynamic hierarchy-aware formulas
- When navigating up the outline programmatically
- In combination with other member functions for complex hierarchy traversal

---

## Category

**Member / Relationship / Navigation**

---

## Syntax

```essbase
@PARENT(mbrName)
```

### Formal Syntax

```
@PARENT(memberNameOrFunction)
```

Where:
- `memberNameOrFunction` — A member name or member function whose parent you want to find.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name or function | ✅ Yes | The member whose parent to find. Can be a literal name (`"Entity_001"`), `@CURRMBR("Entity")`, or another member function. If the member is the root (top) of its dimension, @PARENT returns the member itself (no parent exists). |

---

## Return Value

| Input | Returns |
|-------|---------|
| Leaf member | Its parent member |
| Mid-level member | Its parent member |
| Root/top member | Itself (no parent) |

**Return Type**: Member reference

---

## How It Works (Behind the Scenes)

1. **Outline Traversal**: @PARENT reads the outline hierarchy and moves exactly one level up. It's a simple lookup — very fast.

2. **Shared Members**: If the member is shared, @PARENT returns the parent of the shared member's occurrence in the context being processed, not necessarily the primary member's parent.

3. **Root Members**: If the member is the dimension root (e.g., "Total Entity"), @PARENT returns the member itself. Always check for this if your logic depends on a valid parent.

4. **Dynamic Context**: `@PARENT(@CURRMBR("Entity"))` dynamically finds the parent of whatever entity is currently being processed in the calculation loop.

5. **Multiple Parents**: In standard outlines, each member has exactly one parent (in its primary location). Shared members may appear under different parents.

---

## Syntax Variants & Scenarios

### Variant 1: Literal Member

```essbase
@PARENT("Sales_NA")
```
Returns the parent of Sales_NA (e.g., "Total Sales").

### Variant 2: Dynamic Current Member

```essbase
@PARENT(@CURRMBR("Entity"))
```
Returns the parent of the current entity being processed.

### Variant 3: In a Cross-Dimensional Reference

```essbase
Revenue -> @PARENT(@CURRMBR("Entity"))
```
Gets Revenue at the parent entity level.

### Variant 4: Nested — Grandparent

```essbase
@PARENT(@PARENT(@CURRMBR("Entity")))
```
Goes two levels up — the grandparent.

### Variant 5: In a Comparison

```essbase
IF(@ISMBR(@PARENT("Target_Entity")))
    /* We're at the parent level */
ENDIF
```

---

## Practical Examples

### Example 1: Percentage of Parent

**Scenario**: Calculate each entity's revenue as a percentage of its parent (division) total.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vParentRev = Revenue -> @PARENT(@CURRMBR("Entity"));
    
    IF(vParentRev > 0)
        "Rev_Pct_of_Parent" = Revenue / vParentRev * 100;
    ELSE
        "Rev_Pct_of_Parent" = #MISSING;
    ENDIF
ENDFIX
```

**What Happens**:
- For Entity_NA: gets Revenue at @PARENT("Entity_NA") = "Americas" level
- Calculates Entity_NA Revenue / Americas Revenue × 100
- Each entity shows its % contribution to its division

---

### Example 2: Variance to Parent Average

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vParent = @PARENT(@CURRMBR("Entity"));
    VAR vSiblingCount = @NUMCHILDREN(vParent);
    VAR vParentTotal = Revenue -> vParent;
    
    IF(vSiblingCount > 0)
        "Var_to_Avg" = Revenue - (vParentTotal / vSiblingCount);
    ENDIF
ENDFIX
```

---

### Example 3: Hierarchy-Aware Allocation

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    "Allocated_Cost" = "Corporate_Cost" -> @PARENT(@CURRMBR("Entity")) *
        ("Headcount" / "Headcount" -> @PARENT(@CURRMBR("Entity")));
ENDFIX
```

---

### Example 4: Top-Down Disaggregation

```essbase
FIX("FY25", "Forecast", @CHILDREN("Americas"))
    /* Push parent target down to children based on prior year mix */
    Revenue = Revenue -> @PARENT(@CURRMBR("Entity")) -> "Forecast" *
        (Revenue -> "FY24" / Revenue -> @PARENT(@CURRMBR("Entity")) -> "FY24");
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| @PARENT on root member | @PARENT("Total Entity") returns itself — may cause infinite recursion | Check with `@ISGEN("Entity", 1)` before using @PARENT |
| @PARENT vs. @PARENTVAL | @PARENT returns the member; @PARENTVAL returns the data value | Use @PARENT for member reference; @PARENTVAL for the numeric value |
| Using @PARENT in FIX | `FIX(@PARENT("X"))` targets only the parent member, not its children | Use @PARENT in formulas, not typically in FIX for scope |
| Shared member confusion | @PARENT may return different parents for shared members in different contexts | Be explicit about which occurrence you mean |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PARENTVAL`](../05_Data_Access/@PARENTVAL.md) | Returns the DATA VALUE of the parent (numeric) |
| [`@CHILDREN`](./@CHILDREN.md) | Returns children — opposite direction |
| [`@ANCESTORS`](./@ANCESTORS.md) | Returns all ancestors (parent, grandparent, ...) |
| [`@CURRMBR`](./@CURRMBR.md) | Gets current member — commonly used inside @PARENT |
| [`@SIBLINGS`](./@SIBLINGS.md) | Returns siblings (same parent) |
| [`@GEN`](./@GEN.md) | Returns generation number — useful with @PARENT |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @PARENT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/parent.html)
