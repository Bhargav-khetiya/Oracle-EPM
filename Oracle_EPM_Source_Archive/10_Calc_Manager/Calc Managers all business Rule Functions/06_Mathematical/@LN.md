# @LN

## Overview

`@LN` is a **mathematical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **natural logarithm** (base *e*) of a given numeric expression. The natural logarithm is the inverse of the exponential function (`@EXP`) — if `@EXP(x) = y`, then `@LN(y) = x`.

### Why Does This Function Exist?

Natural logarithms are essential in financial mathematics and statistical analysis:
- Calculating continuous compound growth rates (CAGR using continuous compounding)
- Log-linear regression and trend analysis
- Transforming skewed data distributions for statistical modeling
- Converting between different compounding periods
- Modeling exponential decay (depreciation, amortization curves)

### When to Use It

- When you need to compute continuous growth rates or returns
- In log-linear forecasting models
- When performing mathematical transformations for statistical analysis
- When converting between exponential and linear scales
- When reversing an `@EXP` calculation

---

## Category

**Mathematical / Numeric**

---

## Syntax

```essbase
@LN(expression)
```

### Formal Syntax

```
@LN(numericExpression)
```

Where:
- `numericExpression` — Any expression that evaluates to a positive numeric value

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric expression | ✅ Yes | The value to compute the natural logarithm of. Must be **positive** (> 0). Can be a constant, member reference, cross-dimensional reference, or formula. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Positive number | The natural logarithm (ln) of the value |
| `1` | `0` (because ln(1) = 0) |
| Value ≤ 0 | Error / undefined — logarithm is not defined for zero or negative numbers |
| `#MISSING` | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

**Key Values**: `@LN(1) = 0`, `@LN(e) = 1` where e ≈ 2.71828

---

## How It Works (Behind the Scenes)

1. **Mathematical Foundation**: `@LN(x)` computes logₑ(x), where e ≈ 2.71828. It is the inverse of `@EXP(x)`.

2. **Cell-Level**: Operates on each cell independently.

3. **Domain Restriction**: The input MUST be positive. Zero and negative numbers produce errors. Always guard with an `IF` check.

4. **Precision**: Uses double-precision floating-point arithmetic (approximately 15-16 significant digits).

5. **Missing Value Handling**: `@LN(#MISSING)` returns `#MISSING`.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Value

```essbase
@LN(100)
```
Returns approximately 4.60517 (the natural log of 100).

### Variant 2: Member Reference

```essbase
@LN(Revenue)
```
Returns the natural logarithm of the Revenue value at the current intersection.

### Variant 3: Nested with Other Functions

```essbase
@LN(@ABS(Growth_Factor))
```
Takes the absolute value first (ensuring positive), then computes ln.

### Variant 4: Continuous Growth Rate

```essbase
@LN(End_Value / Start_Value) / Years
```
Computes the continuously compounded annual growth rate.

---

## Practical Examples

### Example 1: Continuous Compound Annual Growth Rate (CAGR)

**Scenario**: Calculate the continuously compounded growth rate of revenue over 5 years.

```essbase
FIX("Working", @DESCENDANTS("Total_Products"))
    IF("Revenue" -> "FY19" > 0 AND "Revenue" -> "FY24" > 0)
        "Continuous_CAGR" = @LN("Revenue" -> "FY24" / "Revenue" -> "FY19") / 5;
    ENDIF
ENDFIX
```

**What Happens**: If FY19 Revenue = 1,000,000 and FY24 Revenue = 1,500,000, then CAGR = ln(1.5) / 5 = 0.4055 / 5 = 0.08109 ≈ 8.1% continuously compounded.

---

### Example 2: Log Transformation for Trend Analysis

**Scenario**: Transform revenue values to log scale for linear trend fitting.

```essbase
FIX("FY24", "Actual", @CHILDREN("Year"))
    IF(Revenue > 0)
        "Log_Revenue" = @LN(Revenue);
    ELSE
        "Log_Revenue" = #MISSING;
    ENDIF
ENDFIX
```

---

### Example 3: Doubling Time Calculation

**Scenario**: How many periods does it take for an investment to double at the current growth rate?

```essbase
FIX("FY24", "Analysis")
    IF("Growth_Rate" > 0)
        "Doubling_Periods" = @LN(2) / @LN(1 + "Growth_Rate");
    ENDIF
ENDFIX
```

---

### Example 4: Converting Between Compounding Periods

**Scenario**: Convert a monthly rate to a continuously compounded rate.

```essbase
FIX("FY24", "Assumptions")
    "Continuous_Rate" = 12 * @LN(1 + "Monthly_Rate");
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Input ≤ 0 | `@LN(0)` and `@LN(-5)` are mathematically undefined | Always guard: `IF(value > 0) ... ENDIF` |
| Confusing `@LN` with `@LOG` | `@LN` = natural log (base e). `@LOG` = custom base log. `@LOG10` = base 10. | Use `@LN` for base e; `@LOG10` for base 10 |
| Forgetting #MISSING check | If input is `#MISSING`, result is `#MISSING` | Check for `#MISSING` before using in further calculations |
| Precision expectations | Floating-point arithmetic has rounding limitations | Don't expect exact integer results; use `@ROUND` if needed |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@EXP`](./@EXP.md) | Inverse of `@LN` — computes e^x |
| [`@LOG`](./@LOG.md) | Logarithm with custom base |
| [`@LOG10`](./@LOG10.md) | Base-10 logarithm |
| [`@POWER`](./@POWER.md) | Raises a value to a power |
| [`@GROWTH`](./@GROWTH.md) | Growth calculation — may be simpler for basic growth rates |
| [`@COMPOUNDGROWTH`](./@COMPOUNDGROWTH.md) | Compound growth — alternative for CAGR |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @LN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ln.html)
- [Oracle Essbase Technical Reference — @LN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
