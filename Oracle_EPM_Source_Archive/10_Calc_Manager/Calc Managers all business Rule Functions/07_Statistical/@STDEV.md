# @STDEV

## Overview

`@STDEV` is a **statistical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that calculates the **sample standard deviation** of a specified set of values. Standard deviation measures the amount of variation or dispersion of a set of values relative to its mean.

### Why Does This Function Exist?

Standard deviation is critical for risk analysis, quality control, and volatility measurement:
- **Financial Volatility**: Measuring how wildly revenue or expenses fluctuate month-over-month.
- **Forecasting Confidence**: A high standard deviation in historical sales indicates lower predictability for future forecasts.
- **Outlier Detection**: Identifying entities or products whose performance falls outside 2 standard deviations from the mean (the "normal" range).

### When to Use It

- To analyze the historical volatility of a financial metric.
- When you are evaluating a **sample** of a larger population (e.g., looking at 12 months of data to infer behavior for a multi-year product lifecycle).
- In statistical driver-based planning models.

---

## Category

**Statistical / Dispersion**

---

## Syntax

```essbase
@STDEV(value, rangeList [, SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH])
```

### Formal Syntax

```
@STDEV(valueExpression, memberRange, [skipOption])
```

Where:
- `valueExpression` — The specific value/measure to evaluate (e.g., `"Revenue"`).
- `memberRange` — The list of members over which to calculate the standard deviation.
- `skipOption` — (Optional) Instructions on how to handle `#MISSING` or `0` values.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Numeric/Member | ✅ Yes | The value to evaluate (typically an Account or Measure). |
| `rangeList` | Member list | ✅ Yes | The group of members to evaluate against. E.g., `@CHILDREN("Total Entity")` or `@RANGE("Jan", "Dec")`. |
| `skipOption`| Keyword | ❌ No | Defines how to treat zero or missing data: `SKIPNONE` (default, missing treated as 0), `SKIPMISSING` (ignores missing), `SKIPZERO` (ignores 0), `SKIPBOTH` (ignores both). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the sample standard deviation of the values in the range. If the number of valid (non-skipped) data points is less than 2, the function returns `#MISSING`, as sample standard deviation requires `N-1` in the denominator.

---

## How It Works (Behind the Scenes)

1. **Sample Formula**: `sqrt [ Σ(x - mean)² / (N - 1) ]`
2. **N - 1 Denominator**: Because `@STDEV` calculates the *sample* standard deviation, it divides by `N - 1` (Bessel's correction). This provides an unbiased estimate of the population variance.
3. **Filtering**: It first filters the array based on the `skipOption`. The `N` in the formula is the count of the *remaining* valid data points.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Time Series Volatility

```essbase
"Rev_Volatility" = @STDEV(Revenue, @RANGE("Jan", "Dec"), SKIPMISSING);
```

### Variant 2: Peer Group Variation

```essbase
"Peer_StDev" = @STDEV("Gross_Margin", @SIBLINGS(@CURRMBR("Entity")), SKIPBOTH);
```

---

## Practical Examples

### Example 1: Historical Sales Volatility

**Scenario**: Calculate the standard deviation of monthly sales over the past year to determine how volatile the product is.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Products"))
    /* Calculate STDEV over the 12 months of the prior year */
    "Sales_Volatility" = @STDEV("Units_Sold" -> "FY24", @CHILDREN("YearTotal"), SKIPBOTH);
    
    /* Classify the product risk based on volatility vs average */
    VAR vAvg = @AVG(SKIPBOTH, "Units_Sold" -> "FY24", @CHILDREN("YearTotal"));
    
    IF(vAvg > 0)
        VAR vCoefOfVariation = "Sales_Volatility" / vAvg;
        IF(vCoefOfVariation > 0.5)
            "Volatility_Rating" = 3; /* High Volatility */
        ELSEIF(vCoefOfVariation > 0.2)
            "Volatility_Rating" = 2; /* Medium Volatility */
        ELSE
            "Volatility_Rating" = 1; /* Low Volatility */
        ENDIF
    ENDIF
ENDFIX
```

---

### Example 2: Outlier Detection

**Scenario**: Flag entities whose expenses are more than 2 standard deviations above the corporate mean.

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    VAR vCorpMean = @AVG(SKIPBOTH, "Total_Expenses", @CHILDREN("Total Entity"));
    VAR vCorpStDev = @STDEV("Total_Expenses", @CHILDREN("Total Entity"), SKIPBOTH);
    
    /* If an entity's expense is > Mean + (2 * StDev) */
    IF("Total_Expenses" > (vCorpMean + (2 * vCorpStDev)))
        "Requires_Audit" = 1;
    ELSE
        "Requires_Audit" = 0;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing Sample vs Population | `@STDEV` uses `N-1`. If you have the data for the entire population (e.g., you want the exact STDEV of just these 12 months, not as a sample of a trend), you should use `@STDEVP` | Use `@STDEVP` for population standard deviation |
| Not handling `#MISSING` | Default is `SKIPNONE`. A missing month is treated as `0`, which artificially drags down the mean and artificially spikes the standard deviation | Always use `SKIPMISSING` or `SKIPBOTH` unless `0` is a mathematically valid input for your specific dataset |
| N < 2 | If `SKIPBOTH` filters the data down to 1 or 0 points, `N-1` becomes 0 or negative, returning `#MISSING` | Ensure the range has sufficient data points |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@STDEVP`](./@STDEVP.md) | Population standard deviation (divides by N instead of N-1) |
| [`@VARIANCE`](./@VARIANCE.md) | Sample variance (which is just STDEV squared) |
| [`@AVG`](./@AVG.md) | The mean used inside the standard deviation calculation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @STDEV](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/stdev.html)
