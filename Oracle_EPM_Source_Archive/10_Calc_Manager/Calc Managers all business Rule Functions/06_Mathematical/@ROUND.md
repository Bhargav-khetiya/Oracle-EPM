# @ROUND

## Overview

`@ROUND` is a **mathematical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **rounds a number** to a specified number of decimal places. It uses standard rounding rules (round half up) — values at exactly .5 round away from zero.

### Why Does This Function Exist?

Financial calculations frequently produce values with many decimal places that need rounding for:
- **Currency precision**: Financial reports typically show 2 decimal places
- **Rate calculations**: Tax rates, percentage variances often need consistent precision
- **Allocation cleanup**: Allocated amounts often produce long decimal tails
- **Regulatory compliance**: Financial statements must report to specific decimal precision
- **Data consistency**: Preventing floating-point artifacts (e.g., 99.999999998 instead of 100)

### When to Use It

- After division operations to clean up decimal precision
- When calculating percentages for reporting
- When allocating amounts that must sum to a control total
- When storing rates or factors at consistent precision
- When comparing values that may differ due to floating-point rounding

---

## Category

**Mathematical / Numeric**

---

## Syntax

```essbase
@ROUND(expression [, numDigits])
```

### Formal Syntax

```
@ROUND(numericExpression [, numberOfDecimalPlaces])
```

Where:
- `numericExpression` — Any valid numeric expression, member, or function result
- `numberOfDecimalPlaces` — Optional integer specifying how many decimal places to keep. Default is 0 (round to whole number).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric | ✅ Yes | The value to round. Can be a constant, member reference, formula, or function result. If `#MISSING`, returns `#MISSING`. |
| `numDigits` | Integer | ❌ No | Number of decimal places to round to. Default: 0. **Positive values**: decimal places (2 = hundredths). **Zero**: round to integer. **Negative values**: round to powers of 10 (-1 = tens, -2 = hundreds). |

---

## Return Value

| Input | numDigits | Returns |
|-------|-----------|---------|
| 123.456 | 2 | 123.46 |
| 123.456 | 0 | 123 |
| 123.456 | -1 | 120 |
| -123.456 | 2 | -123.46 |
| 0.5 | 0 | 1 |
| `#MISSING` | any | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Rounding Method**: @ROUND uses "round half away from zero" (banker's rounding is NOT used). 2.5 rounds to 3, -2.5 rounds to -3.

2. **Evaluation Order**: The expression is fully evaluated first, then rounding is applied. `@ROUND(A + B, 2)` calculates A + B, then rounds the sum.

3. **Floating-Point Precision**: Essbase uses double-precision floating-point (64-bit IEEE 754). @ROUND minimizes but cannot completely eliminate floating-point artifacts in extreme cases.

4. **Negative numDigits**: Using negative values rounds to powers of 10. `-1` rounds to nearest 10, `-2` to nearest 100, `-3` to nearest 1000. Useful for financial summaries.

5. **Missing Values**: `@ROUND(#MISSING, 2)` returns `#MISSING`. @ROUND does NOT treat missing as zero.

6. **Default Behavior**: If `numDigits` is omitted, @ROUND rounds to the nearest integer (same as `numDigits = 0`).

---

## Syntax Variants & Scenarios

### Variant 1: Round to Integer

```essbase
@ROUND(Revenue)
```
Rounds Revenue to nearest whole number.

### Variant 2: Round to 2 Decimal Places

```essbase
@ROUND(Revenue / Units, 2)
```
Rounds average price to 2 decimal places (currency precision).

### Variant 3: Round to Nearest Thousand

```essbase
@ROUND(Revenue, -3)
```
`1,234,567` → `1,235,000`

### Variant 4: Round with @ABS

```essbase
@ROUND(@ABS("Actual" - "Budget"), 2)
```
Absolute variance rounded to 2 decimals.

### Variant 5: Nested Rounding

```essbase
@ROUND("Actual" / @ROUND("Budget", 0), 4)
```
Round Budget first, then calculate and round the ratio.

### Variant 6: Percentage Rounding

```essbase
@ROUND(("Actual" - "Budget") / @ABS("Budget") * 100, 1)
```
Variance percentage rounded to 1 decimal place.

---

## Practical Examples

### Example 1: Currency-Precise Revenue Calculation

**Scenario**: Calculate revenue and ensure it's stored at 2 decimal places (cents).

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    Revenue = @ROUND(Units * Price, 2);
ENDFIX
```

**What Happens**:
- Units (15) × Price (49.99) = 749.85 → stored as 749.85
- Units (7) × Price (33.333) = 233.331 → stored as 233.33
- Prevents floating-point tails from accumulating

---

### Example 2: Variance Percentage Report

**Scenario**: Calculate percentage variance rounded to 1 decimal for reporting.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@ABS("Budget") > 0)
        "Var_Pct" = @ROUND(("Actual" - "Budget") / @ABS("Budget") * 100, 1);
    ELSE
        "Var_Pct" = #MISSING;
    ENDIF
ENDFIX
```

**Result**: 8.33333% → displays as 8.3%

---

### Example 3: Allocation with Rounding Cleanup

**Scenario**: Allocate costs and round to prevent penny differences.

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    "Allocated_Cost" = @ROUND(
        "Total_Cost" -> "Corporate" * (Revenue / @SUM(Revenue, @SIBLINGS(@CURRMBR("Entity")))),
        2
    );
ENDFIX
```

---

### Example 4: Summary-Level Rounding

**Scenario**: Round revenue to nearest thousand for executive reporting.

```essbase
FIX("FY25", "Executive Summary")
    "Revenue_Rounded" = @ROUND(Revenue, -3);
    "EBITDA_Rounded" = @ROUND("EBITDA", -3);
ENDFIX
```
`$12,345,678` → `$12,346,000`

---

### Example 5: Rate Calculation with Precision

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(Revenue > 0)
        "Effective_Tax_Rate" = @ROUND("Tax_Expense" / Revenue * 100, 2);
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Rounding before division | `@ROUND(A, 2) / @ROUND(B, 2)` loses precision mid-calculation | Round only the FINAL result: `@ROUND(A / B, 2)` |
| Assuming @ROUND fixes floating-point perfectly | `@ROUND(0.1 + 0.2, 1)` should be 0.3, but floating-point can cause surprises | For critical comparisons, check with tolerance: `@ABS(x - target) < 0.001` |
| Rounding allocation amounts | Rounded allocations may not sum to the control total (penny differences) | Apply rounding, then adjust one entity for the remainder |
| @ROUND vs. @TRUNCATE confusion | @ROUND rounds to nearest; @TRUNCATE cuts toward zero | 2.7 → @ROUND = 3; @TRUNCATE = 2 |
| Forgetting #MISSING handling | @ROUND(#MISSING) = #MISSING, which may not display as expected | Check for #MISSING before rounding if you need 0 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@TRUNCATE`](./@TRUNCATE.md) | Truncates toward zero (no rounding) |
| [`@ABS`](./@ABS.md) | Absolute value — often used with @ROUND |
| [`@INT`](./@INT.md) | Returns integer part |
| [`@CalcMgrExcelROUND`](./@CalcMgrExcelROUND.md) | Excel-compatible ROUND |
| [`@CalcMgrExcelROUNDDOWN`](./@CalcMgrExcelROUNDDOWN.md) | Round down (toward zero) |
| [`@CalcMgrExcelROUNDUP`](./@CalcMgrExcelROUNDUP.md) | Round up (away from zero) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ROUND](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/round.html)
