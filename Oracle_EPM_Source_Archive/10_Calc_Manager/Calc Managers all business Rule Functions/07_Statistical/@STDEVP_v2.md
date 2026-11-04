# @STDEVP

## Overview

`@STDEVP` is a **statistical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that calculates the **population standard deviation** of a specified set of values. It measures the dispersion of a dataset when that dataset represents the *entire population* being studied, rather than a sample.

### Why Does This Function Exist—

Standard deviation requires different mathematical formulas depending on the data:
- **Sample (`@STDEV`)**: You are looking at a subset of data (e.g., 3 months of sales) to predict a broader trend. Uses `N-1` in the denominator to correct for bias.
- **Population (`@STDEVP`)**: You are measuring the exact variance of a finite, complete dataset (e.g., comparing the exact performance of your 5 divisions last year). Uses `N` in the denominator.

### When to Use It

- When analyzing a complete dataset where you are not trying to infer trends about unmeasured data.
- When grading or ranking an entire, closed group (e.g., allocating a fixed bonus pool across all current employees).
- When exact mathematical population variance is required by a specific financial model.

---

## Category

**Statistical / Dispersion**

---

## Syntax

```essbase
@STDEVP(value, rangeList [, SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH])
```

### Formal Syntax

```
@STDEVP(valueExpression, memberRange, [skipOption])
```

Where:
- `valueExpression` — The specific value/measure to evaluate.
- `memberRange` — The list of members constituting the population.
- `skipOption` — (Optional) How to handle `#MISSING` or `0` values.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Numeric/Member | ✅ Yes | The value to evaluate (typically an Account or Measure). |
| `rangeList` | Member list | ✅ Yes | The complete population of members to evaluate. |
| `skipOption`| Keyword | ❌ No | `SKIPNONE` (default, missing treated as 0), `SKIPMISSING`, `SKIPZERO`, `SKIPBOTH`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the population standard deviation. If the number of valid data points is less than 1, it returns `#MISSING`. (Unlike `@STDEV`, which requires at least 2 data points, `@STDEVP` of a single point is mathematically `0`, though often `#MISSING` depending on internal engine handling).

---

## How It Works (Behind the Scenes)

1. **Population Formula**: `sqrt [ Σ(x - mean)² / N ]`
2. **N Denominator**: Because `@STDEVP` assumes it has the entire population, it divides by `N` (the total number of valid data points) rather than `N-1`. This results in a slightly smaller standard deviation than `@STDEV` for the same dataset.
3. **Filtering**: Applies the `skipOption` before calculating `N` and the mean.

---

## Syntax Variants & Scenarios

### Variant 1: Complete Peer Group Variance

```essbase
"Peer_StDevP" = @STDEVP("Gross_Margin", @CHILDREN("Total Entity"), SKIPBOTH);
```

### Variant 2: Complete Yearly Variance

```essbase
"Annual_StDevP" = @STDEVP(Revenue, @CHILDREN("YearTotal"), SKIPMISSING);
```

---

## Practical Examples

### Example 1: Employee Performance Normalization (Z-Score)

**Scenario**: You have a complete list of 100 sales reps. You want to calculate their "Z-Score" (how many standard deviations above or below the mean they are) for a closed-pool bonus distribution.

```essbase
FIX("FY25", "Working", @CHILDREN("Total_Sales_Reps"))
    /* Since we are evaluating the exact, complete pool of reps, use STDEVP */
    VAR vPopMean = @AVG(SKIPBOTH, "Sales_Total", @CHILDREN("Total_Sales_Reps"));
    VAR vPopStDev = @STDEVP("Sales_Total", @CHILDREN("Total_Sales_Reps"), SKIPBOTH);
    
    IF(vPopStDev > 0)
        /* Z-Score = (X - Mean) / StDev */
        "Performance_Z_Score" = ("Sales_Total" - vPopMean) / vPopStDev;
    ELSE
        "Performance_Z_Score" = 0;
    ENDIF
ENDFIX
```

---

### Example 2: Actuals Portfolio Volatility

**Scenario**: A holding company wants to measure the exact dispersion of EBITDA across its 5 subsidiary companies for the finalized fiscal year.

```essbase
FIX("FY24", "Actual", "EBITDA")
    "Portfolio_Dispersion" = @STDEVP(@CURRMBR("Account"), @CHILDREN("All_Subsidiaries"), SKIPBOTH);
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using STDEVP for forecasting | If you are using past months to predict future months, your data is a *sample* of time | Use `@STDEV` for forecasting and predictive models |
| Default `SKIPNONE` behavior | Treating `#MISSING` entities as `0` revenue will drastically lower the mean and increase the population standard deviation | Use `SKIPBOTH` or `SKIPMISSING` unless `0` is an accurate reflection of the entity's performance |
| Small N differences | For very large datasets (N > 100), the difference between `@STDEV` and `@STDEVP` is negligible. For small datasets (N = 5), the difference is significant | Choose carefully for small ranges (like 12 months) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@STDEV`](./@STDEV.md) | Sample standard deviation (divides by N-1) |
| [`@VARIANCEP`](../08_Financial/@VARIANCEP.md) | Population variance (which is STDEVP squared) |
| [`@AVG`](./@AVG.md) | The mean used in the calculation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @STDEVP](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/stdevp.html)
