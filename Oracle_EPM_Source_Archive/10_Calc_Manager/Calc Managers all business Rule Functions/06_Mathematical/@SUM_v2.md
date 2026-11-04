# @SUM

## Overview

`@SUM` is a **fundamental aggregation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **sum of values** across a specified member range or set. It is one of the most frequently used functions in Essbase calculations — essential for totaling values across children, siblings, or any member set.

### Why Does This Function Exist—

Summing values across members is the most basic operation in financial planning:
- Totaling monthly revenue to get quarterly or annual figures
- Summing departmental costs to get organizational totals
- Aggregating product-line revenue into business-unit totals
- Computing running totals or cumulative values

### When to Use It

- When you need to sum across children of a member
- When calculating totals across a range of time periods
- When building custom aggregation formulas
- When computing allocation denominators (total of a base measure)
- When creating weighted calculations that need a denominator sum

---

## Category

**Aggregation / Mathematical / Essbase**

---

## Syntax

```essbase
@SUM(memberRange)
@SUM(member1, member2, ...)
```

### Formal Syntax

```
@SUM(mbrNameOrFunction [, mbrNameOrFunction]...)
```

Where:
- `mbrNameOrFunction` — A member name, member function (like `@CHILDREN`, `@SIBLINGS`), cross-dimensional reference, or a range of members.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `memberRange` | Member set or range | ✅ Yes | Specifies which members to sum across. Can be: a member function like `@CHILDREN("Total Revenue")`, a range like `"Jan":"Dec"`, individual members like `"Q1", "Q2", "Q3", "Q4"`, or cross-dimensional references. `#MISSING` values are treated as zero in the sum (they are skipped). |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Valid member range with data | Sum of all non-missing values |
| All members are `#MISSING` | `#MISSING` |
| Empty member set | `#MISSING` |
| Mixed data and `#MISSING` | Sum of non-missing values (missing treated as 0) |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: @SUM first resolves its member argument. If you pass `@CHILDREN("Total Revenue")`, it expands to the list of child members. If you pass a range like `"Jan":"Dec"`, it expands to all members in that range.

2. **Summation**: For each resolved member, @SUM reads the data value at the current intersection (current block context). Non-missing values are accumulated. Missing values are skipped (treated as zero in the sum).

3. **Cross-Dimensional**: When used with cross-dimensional references (`@SUM("Revenue" -> @CHILDREN("Total Entity"))`), it sums the Revenue values across all child entities.

4. **vs. AGG**: @SUM is a **formula-level function** — it computes a value for use in an assignment. `AGG` is a **command** that physically writes aggregated values to parent members. Use @SUM in formulas; use AGG to update hierarchies.

5. **Missing Value Behavior**: If ALL members in the range are #MISSING, @SUM returns #MISSING (not zero). If at least one member has data, #MISSING members are treated as zero.

6. **Performance**: @SUM reads data from potentially many cells. For large member sets, this can be expensive. Consider whether the outline's built-in aggregation (via AGG) is more efficient than formula-based @SUM.

---

## Syntax Variants & Scenarios

### Variant 1: Sum of Children

```essbase
@SUM(@CHILDREN("Total Revenue"))
```
Sums all immediate children of Total Revenue.

### Variant 2: Sum of a Range

```essbase
@SUM("Jan":"Jun")
```
Sums January through June (H1 total).

### Variant 3: Sum of Specific Members

```essbase
@SUM("Product_A", "Product_B", "Product_C")
```
Sums exactly these three members.

### Variant 4: Sum with Cross-Dimensional Reference

```essbase
@SUM("Headcount" -> @CHILDREN("All_Departments"))
```
Sums Headcount across all departments.

### Variant 5: Nested @SUM

```essbase
@SUM(@SUM(@CHILDREN("Revenue")), @SUM(@CHILDREN("Other_Income")))
```
Sums revenue and other income totals.

### Variant 6: @SUM in an Allocation Formula

```essbase
"Allocated_Cost" = "Total_Cost" * (Revenue / @SUM(Revenue, @SIBLINGS("Current_Entity")));
```
Each entity gets cost proportional to its revenue share.

---

## Practical Examples

### Example 1: Revenue Share Allocation

**Scenario**: Allocate corporate overhead to entities based on each entity's share of total revenue.

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    "Allocated_Overhead" = "Corporate_Overhead" -> "Corporate" *
        (Revenue / @SUM(Revenue, @SIBLINGS(@CURRMBR("Entity"))));
ENDFIX
```

**What Happens**:
- For each entity, calculates its Revenue ÷ Total Revenue (all siblings)
- Multiplies corporate overhead by that ratio
- Entity with 30% of revenue gets 30% of overhead

---

### Example 2: Half-Year Total

**Scenario**: Calculate H1 total as the sum of Jan through Jun.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "H1_Total" = @SUM("Jan":"Jun");
ENDFIX
```

---

### Example 3: Year-to-Date Calculation

**Scenario**: Calculate YTD revenue by summing from Jan to the current month.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "YTD_Revenue" = @SUM("Jan":@CURRMBR("Period"));
ENDFIX
```

---

### Example 4: Weighted Average Using @SUM

**Scenario**: Calculate weighted average price (revenue / units).

```essbase
FIX("FY25", "Working")
    IF(@SUM("Units", @CHILDREN("Total Entity")) > 0)
        "Avg_Price" = @SUM("Revenue", @CHILDREN("Total Entity")) /
                      @SUM("Units", @CHILDREN("Total Entity"));
    ELSE
        "Avg_Price" = #MISSING;
    ENDIF
ENDFIX
```

---

### Example 5: Custom Aggregation Skipping Certain Members

```essbase
FIX("FY25", "Working")
    "Active_Revenue" = @SUM(Revenue, @REMOVE(@CHILDREN("Total Entity"), "Inactive_Entity"));
ENDFIX
```
Sums revenue excluding the inactive entity.

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| @SUM vs. AGG confusion | @SUM computes a value in a formula; AGG writes to parent members | Use @SUM in assignments; use AGG as a standalone command |
| @SUM on single member | `@SUM("Revenue")` just returns Revenue's value — no aggregation | Use with member sets: `@SUM(@CHILDREN("Revenue"))` |
| Divide by @SUM without zero check | If all members are #MISSING, @SUM returns #MISSING, causing division issues | Always check: `IF(@SUM(...) > 0)` before dividing |
| Assuming @SUM treats #MISSING as 0 always | If ALL members are #MISSING, result is #MISSING, not 0 | Check for #MISSING if you need a guaranteed numeric result |
| Using @SUM when AGG is better | @SUM in a formula recalculates each time; AGG stores the result | For hierarchy roll-ups, AGG is more efficient |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SUMRANGE`](./@SUMRANGE.md) | Sum over cross-dimensional range |
| [`@AVG`](../07_Statistical/@AVG.md) | Average instead of sum |
| [`@COUNT`](./@COUNT.md) | Count of non-missing values |
| [`AGG`](../03_Calc_Commands/AGG.md) | Aggregation command — writes parent values |
| [`@CHILDREN`](../04_Member_Navigation/@CHILDREN.md) | Common member function used inside @SUM |
| [`@SIBLINGS`](../04_Member_Navigation/@SIBLINGS.md) | Sum across siblings for allocation ratios |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @SUM](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/sum.html)
