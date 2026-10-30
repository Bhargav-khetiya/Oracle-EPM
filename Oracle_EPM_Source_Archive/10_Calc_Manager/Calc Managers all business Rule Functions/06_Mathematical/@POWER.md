# @POWER

## Overview

`@POWER` is a **mathematical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns a number raised to a **specified power** (exponent). It performs exponentiation — calculating baseᵉˣᵖᵒⁿᵉⁿᵗ.

### Why Does This Function Exist?

Exponentiation is essential for many financial and mathematical calculations:
- **Compound interest**: FV = PV × (1 + r)ⁿ
- **Growth calculations**: Compound Annual Growth Rate (CAGR)
- **Statistical functions**: Variance, standard deviation building blocks
- **Depreciation**: Declining balance methods
- **Time value of money**: Present value, future value calculations
- **Exponential growth/decay**: Population models, depreciation curves

### When to Use It

- When calculating compound growth or interest
- When computing CAGR (Compound Annual Growth Rate)
- When implementing declining balance depreciation
- When building time value of money calculations
- When you need square roots (`@POWER(x, 0.5)`)
- When implementing exponential smoothing or decay factors

---

## Category

**Mathematical / Numeric**

---

## Syntax

```essbase
@POWER(base, exponent)
```

### Formal Syntax

```
@POWER(numericExprBase, numericExprExponent)
```

Where:
- `numericExprBase` — The base number
- `numericExprExponent` — The power to raise the base to

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `base` | Numeric | ✅ Yes | The base number. Can be any numeric expression, member reference, or function result. If `#MISSING`, returns `#MISSING`. If base is negative and exponent is non-integer, the result is `#MISSING` (complex numbers not supported). |
| `exponent` | Numeric | ✅ Yes | The power to raise the base to. Can be positive, negative, zero, or fractional. Positive integers: repeated multiplication. Negative: reciprocal. Zero: returns 1. Fractional: roots (0.5 = square root). |

---

## Return Value

| Base | Exponent | Returns |
|------|----------|---------|
| 2 | 3 | 8 (2³) |
| 10 | 2 | 100 (10²) |
| 25 | 0.5 | 5 (√25) |
| 2 | -1 | 0.5 (1/2) |
| Any | 0 | 1 |
| 0 | Any positive | 0 |
| `#MISSING` | Any | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Computation**: @POWER uses the standard mathematical pow() function internally. It handles all combinations of positive, negative, zero, and fractional exponents.

2. **Evaluation Order**: Both base and exponent are fully evaluated before the power operation is applied.

3. **Edge Cases**: `@POWER(0, 0)` typically returns 1 (mathematical convention). `@POWER(0, negative)` results in an error or #MISSING (division by zero). Negative base with non-integer exponent produces #MISSING.

4. **Precision**: Results are double-precision floating-point. Very large exponents can cause overflow. Very small results can underflow to zero.

5. **Missing Values**: If either base or exponent is `#MISSING`, the result is `#MISSING`.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Power

```essbase
@POWER(2, 10)
```
Returns 1024 (2¹⁰).

### Variant 2: Square Root

```essbase
@POWER(144, 0.5)
```
Returns 12 (√144).

### Variant 3: Compound Growth Factor

```essbase
@POWER(1 + 0.08, 5)
```
Returns 1.469 — the compound factor for 8% growth over 5 years.

### Variant 4: Reciprocal (Negative Exponent)

```essbase
@POWER(1.10, -3)
```
Returns 0.751 — discount factor for 10% over 3 years.

### Variant 5: Cube Root

```essbase
@POWER(27, 1/3)
```
Returns 3 (∛27).

### Variant 6: Dynamic Exponent

```essbase
VAR vYears = 5;
@POWER(1 + "Growth_Rate", vYears)
```

---

## Practical Examples

### Example 1: CAGR Calculation

**Scenario**: Calculate Compound Annual Growth Rate between two years.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vStartValue = Revenue -> "FY20";
    VAR vEndValue = Revenue -> "FY25";
    VAR vYears = 5;
    
    IF(vStartValue > 0 AND vEndValue > 0)
        "CAGR" = @POWER(vEndValue / vStartValue, 1 / vYears) - 1;
    ELSE
        "CAGR" = #MISSING;
    ENDIF
ENDFIX
```

**What Happens**:
- CAGR = (EndValue / StartValue)^(1/N) - 1
- If Revenue grew from 100M to 147M over 5 years: CAGR = (147/100)^0.2 - 1 = 8%

---

### Example 2: Compound Interest / Future Value

**Scenario**: Calculate the future value of an investment with compound interest.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Investment Portfolio"))
    "Future_Value" = "Present_Value" * @POWER(1 + "Annual_Rate" / 12, "Num_Months");
ENDFIX
```

---

### Example 3: Declining Balance Depreciation

```essbase
FIX("FY25", "Working", @DESCENDANTS("Fixed Assets"))
    VAR vRate = 0.20;  /* 20% declining balance */
    VAR vYear = @LEVMBRS("Year") - 1;  /* Year offset */
    
    "Book_Value" = "Original_Cost" * @POWER(1 - vRate, vYear);
    "Depreciation" = "Book_Value" * vRate;
ENDFIX
```

---

### Example 4: Present Value Discount Factor

```essbase
FIX("FY25", "Working")
    VAR vDiscountRate = 0.10;
    VAR vPeriod = 3;
    
    "PV_Factor" = @POWER(1 + vDiscountRate, -1 * vPeriod);
    "Present_Value" = "Future_Cash_Flow" * "PV_Factor";
ENDFIX
```

---

### Example 5: Exponential Smoothing

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vAlpha = 0.3;
    VAR vDecay = @POWER(1 - vAlpha, 3);  /* Decay factor for 3 periods */
    
    "Smoothed_Value" = "Current_Value" * (1 - vDecay) + "Historical_Avg" * vDecay;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative base with fractional exponent | `@POWER(-4, 0.5)` is undefined (√-4 is complex) — returns #MISSING | Use @ABS if you need the root of a possibly-negative number |
| Integer division in exponent | `@POWER(x, 1/3)` — if 1/3 is integer-divided to 0, result is 1 | Ensure fractional: `@POWER(x, 1.0/3.0)` or use variables |
| Overflow with large exponents | `@POWER(10, 1000)` exceeds double precision | Limit exponents to reasonable ranges |
| Zero base with negative exponent | `@POWER(0, -2)` is 1/0² = division by zero | Check base > 0 before using negative exponents |
| Confusing @POWER with multiplication | `@POWER(x, 2)` is x², not x × 2 | x × 2 is multiplication; @POWER is exponentiation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPOWER`](./@CalcMgrExcelPOWER.md) | Excel-compatible POWER |
| [`@LN`](./@LN.md) | Natural logarithm — inverse of exponentiation |
| [`@EXP`](./@EXP.md) | e^x — Euler's number raised to a power |
| [`@ABS`](./@ABS.md) | Often used with @POWER for safe root calculations |
| [`@ROUND`](./@ROUND.md) | Round @POWER results for display |
| [`@NPV`](./@NPV.md) | Net present value — uses power internally |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @POWER](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/power.html)
