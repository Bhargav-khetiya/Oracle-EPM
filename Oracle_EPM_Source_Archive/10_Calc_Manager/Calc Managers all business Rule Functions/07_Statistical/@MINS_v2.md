# @MINS

## Overview

`@MINS` is a **mathematical/statistical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **minimum value** from a list of expressions while **skipping `#MISSING` values**. The "S" suffix stands for "Skip Missing." Unlike `@MIN`, which may return `#MISSING` if any argument is missing, `@MINS` ignores missing values and finds the minimum among the remaining non-missing values.

### Why Does This Function Exist?

In financial planning, data is often incomplete — not all scenarios, versions, or periods may have values:
- Comparing budget vs. forecast vs. actual where some versions may not yet be populated
- Finding the lowest cost across suppliers where some quotes haven't been received
- Computing conservative estimates from partially complete data sets
- Building dashboards that must handle incomplete periods gracefully

### When to Use It

- When you need the minimum of multiple values but some may be `#MISSING`
- When you want `#MISSING` values excluded from the comparison rather than propagated
- When working with partially populated scenarios, forecasts, or versions
- Use `@MINS` instead of `@MIN` when data completeness is not guaranteed

---

## Category

**Mathematical / Statistical / Aggregation**

---

## Syntax

```essbase
@MINS(expression1, expression2 [, expressionN...])
```

### Formal Syntax

```
@MINS(numericExpr1, numericExpr2 [, numericExpr3, ...])
```

Where each expression is independently evaluated and missing values are skipped.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression1` | Numeric expression | ✅ Yes | First value to compare. Can be a member, cross-dimensional reference, constant, or formula. |
| `expression2` | Numeric expression | ✅ Yes | Second value to compare. |
| `expressionN` | Numeric expression | ❌ No | Additional values to include in the comparison. No fixed limit. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Multiple non-missing values provided | The smallest non-missing value |
| Only one non-missing value exists | That value |
| All values are `#MISSING` | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Expression Evaluation**: Each argument expression is evaluated independently in the current cell context.

2. **Missing Skip Logic**: Before comparison, `#MISSING` values are filtered out. The minimum is then computed from the remaining non-missing values.

3. **Short-Circuit**: If all arguments evaluate to `#MISSING`, the result is `#MISSING` — there is no "default" fallback.

4. **Cell-Level Operation**: `@MINS` operates at each individual cell intersection — it does not aggregate across cells or members.

5. **Performance**: `@MINS` is a lightweight function with minimal overhead. Cross-dimensional references within arguments may add I/O cost.

---

## Syntax Variants & Scenarios

### Variant 1: Two Simple Members

```essbase
@MINS(Actual, Budget)
```
Returns the smaller of Actual and Budget, skipping whichever is `#MISSING`.

### Variant 2: Multiple Scenarios

```essbase
@MINS(Actual, Budget, Forecast, "What_If_1")
```
Returns the minimum across four scenarios, ignoring any that are `#MISSING`.

### Variant 3: Cross-Dimensional

```essbase
@MINS("Revenue" -> "Q1", "Revenue" -> "Q2", "Revenue" -> "Q3", "Revenue" -> "Q4")
```
Returns the minimum quarterly revenue.

### Variant 4: Mixed Constants and Members

```essbase
@MINS(Revenue, 0)
```
Returns the smaller of Revenue and 0 — effectively caps Revenue at 0 (returns 0 for positive Revenue, Revenue for negative). Missing Revenue returns 0.

---

## Practical Examples

### Example 1: Conservative Estimate Across Scenarios

**Scenario**: Use the most conservative (lowest) revenue projection from Budget, Forecast, and Stretch.

```essbase
FIX("FY24", @DESCENDANTS("Total_Products"))
    "Conservative_Rev" = @MINS("Budget" -> Revenue, "Forecast" -> Revenue, "Stretch" -> Revenue);
ENDFIX
```

**What Happens**: If Budget=1000, Forecast=#MISSING, Stretch=1200, result = 1000. If only Stretch has a value, it returns 1200.

---

### Example 2: Minimum Cost from Vendor Quotes

**Scenario**: Find the lowest vendor quote, handling vendors who haven't submitted quotes yet.

```essbase
FIX("FY24", "Procurement")
    "Best_Price" = @MINS("Vendor_A" -> "Unit_Cost", "Vendor_B" -> "Unit_Cost", "Vendor_C" -> "Unit_Cost");
ENDFIX
```

---

### Example 3: Floor Value with Zero Baseline

**Scenario**: Ensure a value never goes above zero (useful for tracking losses).

```essbase
FIX("FY24", "Actual")
    "Capped_Loss" = @MINS("Net_Income", 0);
ENDFIX
```

---

### Example 4: Minimum of Prior Year and Current Year

**Scenario**: Use the lower of this year's and last year's expense for conservative budgeting.

```essbase
FIX("FY24", "Budget")
    "Base_Expense" = @MINS("Actual" -> "FY23" -> "Total_Expenses", "Budget" -> "FY24" -> "Total_Expenses");
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing `@MINS` with `@MIN` | `@MIN` includes `#MISSING` in the comparison (and may return `#MISSING`). `@MINS` skips them. | Use `@MINS` when dealing with potentially incomplete data |
| Confusing with `@MINSRANGE` | `@MINSRANGE` operates across a **range** of members. `@MINS` takes explicit values. | Use `@MINSRANGE` for `Jan:Dec` style ranges |
| Expecting a member reference | `@MINS` returns a **value**, not the member that holds the minimum | Use `@RANK` or other functions to identify which member holds the minimum |
| All `#MISSING` result | If every argument is `#MISSING`, result is `#MISSING` — not zero | Add a fallback with: `IF(result == #MISSING) result = 0; ENDIF` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MIN`](../06_Mathematical/@MIN.md) | Minimum WITHOUT skipping missing — missing propagates |
| [`@MINSRANGE`](../06_Mathematical/@MINSRANGE.md) | Minimum across a member range, skipping missing |
| [`@MINRANGE`](../06_Mathematical/@MINRANGE.md) | Minimum across a member range (may include missing) |
| [`@MAXS`](./@MAXS.md) | Maximum skipping missing — complementary |
| [`@MAX`](../06_Mathematical/@MAX.md) | Maximum without skip logic |
| [`@AVG`](./@AVG.md) | Average — another aggregation function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MINS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mins.html)
- [Oracle Essbase Technical Reference — @MINS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
