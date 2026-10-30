# @DESCENDANTS

## Overview

`@DESCENDANTS` is one of the **most critical member set functions** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It returns **all descendants** of a specified member — children, grandchildren, great-grandchildren, and so on down to the leaf level. Unlike `@CHILDREN` which returns only immediate children, `@DESCENDANTS` traverses the entire subtree.

### Why Does This Function Exist?

You very frequently need to process every member below a parent at all levels:
- Calculate formulas for all accounts under a total
- Process all entities in a region
- Clear data for all descendants
- Build FIX blocks that cover entire hierarchies

### When to Use It

- FIX statements that need to cover all levels of a hierarchy
- Aggregation across the entire subtree
- Data clearing operations
- Any operation that needs to touch every member below a parent

---

## Category

**Member Set / Relationship**

---

## Syntax

```essbase
@DESCENDANTS(member)
@DESCENDANTS(member, generationOrLevel)
@DESCENDANTS(member, generationOrLevelName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name or expression | ✅ Yes | The parent member whose descendants to return. |
| `generationOrLevel` | Integer or Name | ❌ No | Optional. Limits descendants to a specific generation or level. If omitted, returns ALL descendants at all levels. |

---

## Return Value

Returns a **member set** containing all descendants. The specified parent is **NOT** included (use `@IDESCENDANTS` for inclusive).

**Return Type**: Member set

---

## How It Works (Behind the Scenes)

1. **Full Subtree Traversal**: Starting from the specified member, `@DESCENDANTS` walks down every branch of the hierarchy, collecting every member at every level below.

2. **Outline Order**: Members are returned in their outline order — the order they appear in the dimension hierarchy (depth-first traversal).

3. **Excludes Parent**: The starting member is NOT included. For inclusive, use `@IDESCENDANTS`.

4. **Generation/Level Filtering**: When a generation or level is specified, only descendants at that specific level are returned.

---

## Syntax Variants & Scenarios

### Variant 1: All Descendants

```essbase
@DESCENDANTS("Total_Entity")
```
Returns every entity at every level below Total_Entity.

### Variant 2: Descendants at Specific Level (Leaf Only)

```essbase
@DESCENDANTS("Total_Entity", 0)
```
Returns only leaf-level (Level 0) descendants.

### Variant 3: Descendants at Specific Generation

```essbase
@DESCENDANTS("Total_Entity", 3)
```
Returns descendants at Generation 3 only.

### Variant 4: In FIX Block

```essbase
FIX(@DESCENDANTS("Total_Revenue"))
    "Forecast" = "Actual" * 1.05;
ENDFIX
```

### Variant 5: Dynamic with @CURRMBR

```essbase
@DESCENDANTS(@CURRMBR("Entity"))
```

---

## Practical Examples

### Example 1: Apply Growth to All Accounts

```essbase
FIX("Budget", "FY25", @DESCENDANTS("PL_Total"))
    "Amount" = "Amount" -> "FY24" * 1.05;
ENDFIX
```

### Example 2: Clear Data for All Descendants

```essbase
FIX("Working", "FY25", @DESCENDANTS("Total_Entity"))
    CLEARDATA "Revenue";
    CLEARDATA "Expense";
ENDFIX
```

### Example 3: Leaf-Level Only Processing

```essbase
FIX("Actual", "FY24", @DESCENDANTS("Total_Entity"))
    IF(@CURLEV("Entity") == 0)  /* Only leaf entities */
        "Tax" = "Pre_Tax_Income" * "Tax_Rate";
    ENDIF
ENDFIX
```

Or more efficiently:
```essbase
FIX("Actual", "FY24", @LEVMBRS("Entity", 0))
    "Tax" = "Pre_Tax_Income" * "Tax_Rate";
ENDFIX
```

### Example 4: Count All Descendants

```essbase
"Total_Entities" = @COUNT("Revenue", @DESCENDANTS("Total_Entity"));
```

### Example 5: Aggregation Across All Levels

```essbase
FIX("Actual", "FY24", "Jan")
    "Total_Entity" = @SUM("Revenue", @DESCENDANTS("Total_Entity"));
ENDFIX
```

---

## @DESCENDANTS vs @CHILDREN Comparison

| Feature | @CHILDREN | @DESCENDANTS |
|---------|-----------|-------------|
| Depth | 1 level only | All levels |
| Result for `Total > Region > Country > City` | Regions only | Regions + Countries + Cities |
| Use case | Immediate children | Full hierarchy below |
| Include parent | No (use @ICHILDREN) | No (use @IDESCENDANTS) |

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Very large member sets | `@DESCENDANTS` on a large hierarchy can return thousands of members | Filter with level/generation or use `@LEVMBRS` |
| Including the parent | `@DESCENDANTS` excludes the parent | Use `@IDESCENDANTS` for inclusive |
| Performance in FIX | FIX with huge descendant set can be slow | Consider parallel calc settings |
| Processing at all levels | If your formula is only valid at leaf level, running at parent level wastes time or produces errors | Filter to specific level with `@LEVMBRS` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@IDESCENDANTS`](./@@IDESCENDANTS.md) | Inclusive — includes the parent member |
| [`@CHILDREN`](./@@CHILDREN.md) | Only immediate children (one level) |
| [`@ICHILDREN`](./@@ICHILDREN.md) | Inclusive children |
| [`@LDESCENDANTS`](./@@LDESCENDANTS.md) | Left descendants |
| [`@RDESCENDANTS`](./@@RDESCENDANTS.md) | Right descendants |
| [`@ILDESCENDANTS`](./@@ILDESCENDANTS.md) | Inclusive left descendants |
| [`@IRDESCENDANTS`](./@@IRDESCENDANTS.md) | Inclusive right descendants |
| [`@ANCESTORS`](./@@ANCESTORS.md) | Opposite direction — upward |
| [`@LEVMBRS`](./@@LEVMBRS.md) | Members at a specific level (alternative) |
| [`@GENMBRS`](./@@GENMBRS.md) | Members at a specific generation (alternative) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @DESCENDANTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/descendants.html)
