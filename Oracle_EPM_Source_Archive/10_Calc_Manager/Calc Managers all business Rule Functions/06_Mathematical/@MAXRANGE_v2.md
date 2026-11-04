# @MAXRANGE

## Overview

`@MAXRANGE` is a **statistical/mathematical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **maximum value** across a specified range of members. It scans a contiguous range within a single dimension and returns the highest value found.

### Why Does This Function Exist—

Finding peak values across time periods, entities, or products is fundamental in planning:
- Identifying the month with the highest revenue for capacity planning
- Finding peak headcount across quarters for resource management
- Determining the highest exchange rate for risk assessment
- Identifying best-case values across scenarios

### When to Use It

- When you need the maximum across a **range** of consecutive members
- For peak/ceiling analysis across time periods
- When building KPIs that require best-case or maximum values
- Use `@MAXRANGE` for ranges; use `@MAX` for explicit value comparisons

---

## Category

**Mathematical / Statistical / Aggregation**

---

## Syntax

```essbase
@MAXRANGE(expression, rangeList)
```

### Formal Syntax

```
@MAXRANGE(numericExpression, memberRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric expression | ✅ Yes | The value to evaluate at each member in the range. |
| `rangeList` | Member range | ✅ Yes | The range of members to scan. Format: `member1:member2` or member set functions. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| All values numeric | The largest numeric value in the range |
| Some values `#MISSING` | The largest non-missing value |
| All values `#MISSING` | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Range Iteration**: Essbase iterates through each member in the range, evaluates the expression, and tracks the maximum value found.

2. **Missing Handling**: `#MISSING` values are skipped — only non-missing values participate in the maximum calculation.

3. **Range Resolution**: `member1:member2` resolves to all members between the two endpoints at the same level, in outline order.

4. **Dense vs. Sparse**: Most efficient on dense dimensions where all data is in a single block.

5. **Read Function**: Used on the right side of formula assignments.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Time Range

```essbase
@MAXRANGE(Revenue, Jan:Dec)
```

### Variant 2: Using Member Set Functions

```essbase
@MAXRANGE(Sales, @CHILDREN("FY24"))
```

### Variant 3: Cross-Dimensional

```essbase
@MAXRANGE("Actual" -> Revenue, Jan:Dec)
```

### Variant 4: Multiple Ranges

```essbase
@MAXRANGE(Sales, Jan:Mar, Oct:Dec)
```

---

## Practical Examples

### Example 1: Peak Monthly Revenue

**Scenario**: Find the highest monthly revenue in the fiscal year.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Products"))
    "Peak_Revenue" = @MAXRANGE(Revenue, Jan:Dec);
ENDFIX
```

---

### Example 2: Maximum Headcount for Budget Planning

**Scenario**: Determine peak headcount across all quarters for facilities planning.

```essbase
FIX("FY24", "Forecast")
    "Peak_Headcount" = @MAXRANGE(Headcount, Q1:Q4);
    "Desk_Requirement" = "Peak_Headcount" * 1.1; /* 10% buffer */
ENDFIX
```

---

### Example 3: Best-Case Scenario Analysis

**Scenario**: Find the highest revenue across different forecast scenarios.

```essbase
FIX("FY24", @DESCENDANTS("Total_Products"))
    "Best_Case_Rev" = @MAXRANGE(Revenue, @CHILDREN("All_Scenarios"));
ENDFIX
```

---

### Example 4: Ceiling Rate for Risk Management

**Scenario**: Find the highest exchange rate in the year for worst-case cost analysis.

```essbase
FIX("FY24")
    "Ceiling_Rate" = @MAXRANGE("Exch_Rate", Jan:Dec);
    "WorstCase_Import_Cost" = "Import_Volume" * "Ceiling_Rate";
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with `@MAX` | `@MAX` takes explicit values; `@MAXRANGE` takes a member range | Use `@MAXRANGE` for `Jan:Dec` style ranges |
| Range order | Must be in outline order | Specify as `first_member:last_member` in outline sequence |
| Sparse dimension performance | Scanning sparse ranges reads multiple blocks | Prefer dense dimensions for range scans |
| All missing returns `#MISSING` | If every value in range is `#MISSING`, result is `#MISSING` | Handle `#MISSING` result in subsequent calculations |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MAX`](./@MAX.md) | Maximum of explicit values |
| [`@MAXS`](../07_Statistical/@MAXS.md) | Maximum skipping missing (explicit values) |
| [`@MAXSRANGE`](./@MAXSRANGE.md) | Maximum across range, skipping missing |
| [`@MINRANGE`](./@MINRANGE.md) | Minimum across range — complementary |
| [`@AVGRANGE`](../07_Statistical/@AVGRANGE.md) | Average across range |
| [`@SUMRANGE`](./@SUMRANGE.md) | Sum across range |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MAXRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/maxrange.html)
- [Oracle Essbase Technical Reference — @MAXRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
