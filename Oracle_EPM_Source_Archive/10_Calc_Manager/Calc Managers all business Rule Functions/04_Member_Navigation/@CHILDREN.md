# @CHILDREN

## Overview

`@CHILDREN` is one of the most **fundamental and frequently used member set functions** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It returns the **immediate children** (one level below) of a specified member. It does NOT return grandchildren or further descendants — only the direct children.

### Why Does This Function Exist?

Hierarchies are the backbone of EPM applications. Almost every calculation needs to reference "the members directly under" a parent. `@CHILDREN` is the primary way to get this set of members:
- Loop through departments under a division
- Sum revenue from product children
- Allocate costs to entity children
- Aggregate metrics from child members

### When to Use It

- In FIX statements to process all children of a parent
- As the member set for `@SUM`, `@AVG`, `@MAX`, `@MIN`, etc.
- In allocations for target/basis ranges
- In loops to iterate through direct children
- Anywhere you need "the members directly under this parent"

---

## Category

**Member Set / Relationship**

---

## Syntax

```essbase
@CHILDREN(member)
```

### Formal Syntax

```
@CHILDREN(memberExpression)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name or expression | ✅ Yes | The parent member whose children to return. Must be a member that has children (non-leaf). If the member is a leaf (no children), returns an empty set. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Member has children | Set of all immediate children |
| Member is a leaf (no children) | Empty set |
| Invalid member | Error |

**Return Type**: Member set

---

## How It Works (Behind the Scenes)

1. **One Level Only**: Unlike `@DESCENDANTS` which can go multiple levels deep, `@CHILDREN` returns ONLY the immediate children — one generation below the parent.

2. **Order**: Children are returned in their outline order (the order they appear in the dimension hierarchy).

3. **Includes All Children**: Returns ALL children regardless of storage type (stored, Dynamic Calc, shared, etc.).

4. **Does NOT Include the Parent**: The specified parent member is NOT included. Use `@ICHILDREN` for the inclusive version.

5. **Shared Members**: If any children are shared members, they are included in the returned set.

6. **Commonly Paired**: `@CHILDREN` is almost always used inside FIX, as a parameter to aggregation functions, or in allocation functions.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Children Reference

```essbase
@CHILDREN("Total_Entity")
```
Returns all direct children of `Total_Entity` (e.g., `North_America, EMEA, APAC`).

### Variant 2: In a FIX Statement

```essbase
FIX(@CHILDREN("Total_Revenue"))
    /* Process only the immediate children of Total_Revenue */
ENDFIX
```

### Variant 3: As Parameter to Aggregation

```essbase
@SUM("Revenue", @CHILDREN("Total_Entity"))
```
Sums Revenue across the children of Total_Entity.

### Variant 4: Dynamic with @CURRMBR

```essbase
@CHILDREN(@CURRMBR("Entity"))
```
Returns the children of whatever Entity member is currently being processed.

### Variant 5: In Allocation

```essbase
@ALLOCATE(1200, SPREAD, @CHILDREN("FY24"), =, 0, ROUND, 2, @CHILDREN("FY24"))
```
Spreads 1200 equally across all children of FY24 (months).

### Variant 6: Nested with Other Functions

```essbase
@COUNT(@CHILDREN("Total_Entity"))
```
Returns the number of direct children.

---

## Practical Examples

### Example 1: Sum Children Revenue

```essbase
FIX("Actual", "FY24", "Jan")
    "Total_Entity" = @SUM("Revenue", @CHILDREN("Total_Entity"));
ENDFIX
```

### Example 2: Process All Departments

```essbase
FIX("Budget", "FY25")
    @CHILDREN("All_Departments")(
        "Budget_Amount" = "Budget_Amount" -> "FY24" * 1.05;
    )
ENDFIX
```

### Example 3: Average Across Product Children

```essbase
FIX("Actual", "FY24")
    "Avg_Product_Price" = @AVG("Unit_Price", @CHILDREN("Product_Line_A"));
ENDFIX
```

### Example 4: Count Children for Equal Allocation

```essbase
FIX("Budget", "FY25")
    IF(@COUNT(@CHILDREN("Total_Dept")) > 0)
        @CHILDREN("Total_Dept")(
            "Budget" = "Total_Budget" / @COUNT(@CHILDREN("Total_Dept"));
        )
    ENDIF
ENDFIX
```

### Example 5: Compare to Siblings

```essbase
FIX("Actual", "FY24", "Jan")
    @CHILDREN("Total_Entity")(
        IF(@SUM("Revenue", @CHILDREN(@PARENT(@CURRMBR("Entity")))) > 0)
            "Pct_of_Total" = "Revenue" / @SUM("Revenue", @CHILDREN(@PARENT(@CURRMBR("Entity")))) * 100;
        ENDIF
    )
ENDFIX
```

### Example 6: Nested — Children of Children

```essbase
/* Get grandchildren by combining with @DESCENDANTS or nesting */
FIX(@CHILDREN("North_America"))
    /* Now within each child of North_America */
    @CHILDREN(@CURRMBR("Entity"))(
        /* Process the grandchildren */
        "Status" = 1;
    )
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting grandchildren | `@CHILDREN` returns only ONE level down | Use `@DESCENDANTS` for all levels or `@DESCENDANTS(mbr, level)` for specific depth |
| Calling on a leaf member | Returns empty set — no error, but nothing to process | Check if member has children first with `@ISPARENT` |
| Including the parent | `@CHILDREN` excludes the parent | Use `@ICHILDREN` if you need parent + children |
| Assuming alphabetical order | Children are in outline order, not alphabetical | Reorder outline if order matters |
| Performance with many children | Using @CHILDREN in deeply nested loops can create large Cartesian products | Flatten logic where possible |
| FIX with empty set | If `@CHILDREN` returns empty set in FIX, the block does nothing | Verify the parent has children |

---

## @CHILDREN vs @DESCENDANTS vs @ICHILDREN Comparison

| Function | Returns | Includes Parent? |
|----------|---------|-------------------|
| `@CHILDREN(X)` | Immediate children only | ❌ No |
| `@ICHILDREN(X)` | X + immediate children | ✅ Yes |
| `@DESCENDANTS(X)` | All descendants at all levels | ❌ No |
| `@IDESCENDANTS(X)` | X + all descendants | ✅ Yes |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ICHILDREN`](./@@ICHILDREN.md) | Inclusive — returns the parent PLUS its children |
| [`@DESCENDANTS`](./@@DESCENDANTS.md) | Returns ALL descendants (children, grandchildren, etc.) |
| [`@IDESCENDANTS`](./@@IDESCENDANTS.md) | Inclusive descendants |
| [`@PARENT`](./@@PARENT.md) | Returns the parent of a member (opposite direction) |
| [`@SIBLINGS`](./@@SIBLINGS.md) | Returns siblings (same-level members under same parent) |
| [`@ISPARENT`](./@@ISPARENT.md) | Checks if a member has children |
| [`@ISCHILD`](./@@ISCHILD.md) | Checks if a member is a child of another |
| [`@COUNT`](./@@COUNT.md) | Often used with @CHILDREN to count them |
| [`@SUM`](./@@SUM.md) | Often used with @CHILDREN to sum them |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @CHILDREN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/children.html)
