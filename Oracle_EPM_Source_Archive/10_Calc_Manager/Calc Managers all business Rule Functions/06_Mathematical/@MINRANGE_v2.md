# @MINRANGE

## Overview

`@MINRANGE` is a **statistical/mathematical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **minimum value** across a specified range of members. Unlike `@MIN` which takes a list of explicit member–value pairs or cross-dimensional references, `@MINRANGE` operates across a contiguous **range** of members within a single dimension, making it ideal for finding the lowest value across time periods, scenarios, or entity hierarchies.

### Why Does This Function Exist—

In financial planning and budgeting, you frequently need to identify the lowest value across a series:
- Finding the month with the lowest revenue in a fiscal year
- Identifying the minimum headcount across quarters for capacity planning
- Determining the lowest exchange rate in a period for risk analysis
- Finding floor values across scenarios for conservative forecasting

### When to Use It

- When you need the minimum across a **range** of consecutive members (e.g., Jan through Dec)
- When you want to find the floor value across time periods for a specific account
- When building dashboards or KPI calculations that need worst-case values
- Use `@MINRANGE` instead of `@MIN` when the members form a contiguous range within one dimension

---

## Category

**Mathematical / Statistical / Aggregation**

---

## Syntax

```essbase
@MINRANGE(expression, rangeList)
```

### Formal Syntax

```
@MINRANGE(numericExpression, memberRange)
```

Where:
- `numericExpression` — The data value or calculation to evaluate at each point in the range
- `memberRange` — A range of members, typically expressed as `member1:member2` or using member set functions

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric expression | ✅ Yes | The value to evaluate at each member in the range. Can be a member name, cross-dimensional reference, or formula. Evaluated once per member in the range. |
| `rangeList` | Member range | ✅ Yes | Defines the set of members to evaluate. Typically a range like `Jan:Dec`, or a member set function like `@CHILDREN(Year)`. Can include multiple ranges separated by commas. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| All values are numeric | The smallest numeric value in the range |
| Some values are `#MISSING` | The smallest non-missing value (missing values are skipped) |
| All values are `#MISSING` | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Evaluation Order**: Essbase iterates through each member in the specified range. For each member, it evaluates the `expression` in the context of that member. After evaluating all members, it returns the smallest value found.

2. **Range Resolution**: The range `member1:member2` resolves to all members between `member1` and `member2` at the **same level** in the outline, in outline order. This includes both endpoints.

3. **Missing Value Handling**: `#MISSING` values are **ignored** during the minimum calculation. Only non-missing values participate. If every value in the range is `#MISSING`, the result is `#MISSING`.

4. **Block-Level Behavior**: `@MINRANGE` reads values from blocks but does not create new blocks. It operates within the current calculation context (FIX statement scope).

5. **Sparse vs. Dense**: When the range dimension is dense, `@MINRANGE` scans within the data block. When the range dimension is sparse, it must read across multiple blocks, which is slower. For performance, prefer ranges on dense dimensions.

6. **Calc Mode**: `@MINRANGE` is a **read** function — it reads values from the database. It is typically used on the right side of a formula assignment.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Time Range

```essbase
@MINRANGE(Sales, Jan:Dec)
```
Returns the minimum `Sales` value from January through December.

### Variant 2: Cross-Dimensional Expression in Range

```essbase
@MINRANGE("Actual" -> Sales, Jan:Dec)
```
Returns the minimum Actual Sales from January through December.

### Variant 3: Using Member Set Functions

```essbase
@MINRANGE(Revenue, @CHILDREN("FY24"))
```
Returns the minimum Revenue across all children of FY24 (e.g., Q1, Q2, Q3, Q4).

### Variant 4: Multiple Ranges

```essbase
@MINRANGE(Sales, Jan:Mar, Jul:Sep)
```
Returns the minimum Sales across Q1 months and Q3 months combined.

### Variant 5: With @DESCENDANTS

```essbase
@MINRANGE(Headcount, @DESCENDANTS("Total_Entity"))
```
Returns the minimum headcount across all descendant entities.

---

## Practical Examples

### Example 1: Minimum Monthly Revenue

**Scenario**: Find the lowest monthly revenue in FY24 for each product.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Products"))
    "Min_Monthly_Revenue" = @MINRANGE(Revenue, Jan:Dec);
ENDFIX
```

**What Happens**: For each product at each intersection, Essbase scans Revenue from Jan to Dec and stores the smallest value in `Min_Monthly_Revenue`.

---

### Example 2: Minimum Headcount for Capacity Planning

**Scenario**: Determine the minimum headcount across all quarters to plan for minimum resource availability.

```essbase
FIX("FY24", "Working", @DESCENDANTS("All_Departments"))
    "Min_Headcount" = @MINRANGE(Headcount, Q1:Q4);
ENDFIX
```

---

### Example 3: Floor Exchange Rate

**Scenario**: Find the lowest exchange rate across months for worst-case currency conversion.

```essbase
FIX("FY24", @CHILDREN("All_Currencies"))
    "Floor_Rate" = @MINRANGE("Exch_Rate", Jan:Dec);
    "Conservative_Revenue" = "USD_Revenue" * "Floor_Rate";
ENDFIX
```

---

### Example 4: Combined with IF for Threshold Alerts

**Scenario**: Flag if the minimum cash balance in any month drops below a threshold.

```essbase
FIX("FY24", "Forecast")
    IF(@MINRANGE("Cash_Balance", Jan:Dec) < 100000)
        "Liquidity_Alert" = 1;
    ELSE
        "Liquidity_Alert" = 0;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing `@MINRANGE` with `@MIN` | `@MIN` takes explicit values/expressions; `@MINRANGE` takes a range of members | Use `@MINRANGE` for ranges like `Jan:Dec`, use `@MIN` for comparing two specific values |
| Range on sparse dimension — slow | If the range dimension is sparse, Essbase reads many blocks | Move range calculation to dense dimensions when possible, or pre-aggregate |
| Expecting `#MISSING` to be treated as zero | `#MISSING` is skipped, not treated as 0 | If you want missing = 0, wrap with: `IF(@ISMBR(...)) ... ENDIF` and handle missing explicitly |
| Range order matters | `Dec:Jan` may not work as expected — range must be in outline order | Always specify ranges in outline order (first member : last member) |
| Using on left side of equation | `@MINRANGE` is a read function, it cannot be a target | Place `@MINRANGE` on the right side of the `=` assignment |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MIN`](./@MIN.md) | Returns minimum of explicit values — use when you have specific members, not a range |
| [`@MINS`](../07_Statistical/@MINS.md) | Returns minimum skipping `#MISSING` — similar skip behavior |
| [`@MINSRANGE`](./@MINSRANGE.md) | Minimum across range, skipping missing — closely related |
| [`@MAXRANGE`](./@MAXRANGE.md) | Returns **maximum** across a range — complementary function |
| [`@AVGRANGE`](../07_Statistical/@AVGRANGE.md) | Returns **average** across a range — same range pattern |
| [`@SUMRANGE`](./@SUMRANGE.md) | Returns **sum** across a range — same range pattern |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MINRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/minrange.html)
- [Oracle Essbase Technical Reference — @MINRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
