# @TREND

## Overview

`@TREND` is a **statistical forecasting function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that predicts future values based on a series of historical data points. It uses mathematical trending algorithms (like Linear Regression, Exponential Smoothing, or Moving Average) to project past trends into the future.

### Why Does This Function Exist—

Forecasting often starts with a baseline projected from history before human adjustments are applied:
- **Baseline Budgeting**: Using the last 3 years of actual sales to pre-populate next year's budget.
- **Seasonality**: Forecasting monthly revenue by finding the historical trend and applying a seasonal overlay.
- **Data Smoothing**: Stripping out random historical noise to find the underlying trajectory of an account.

### When to Use It

- To generate automated statistical baseline forecasts (Seed forecasting).
- When projecting expense run-rates based on historical actuals.
- In predictive planning models where machine learning isn't available, but statistical trending is required.

---

## Category

**Statistical / Forecasting / Predictive**

---

## Syntax

```essbase
@TREND(value, rangeList, [trendMethod], [param1, param2...])
```

### Formal Syntax

```
@TREND(valueExpression, dataRange, [methodName], [methodParameters...])
```

Where:
- `valueExpression` — The measure (e.g., `"Revenue"`) to analyze.
- `dataRange` — The historical time range to base the trend on (e.g., `@XRANGE("FY23", "FY24")`).
- `methodName` — (Optional) The statistical algorithm to use. Defaults to `LR` (Linear Regression).
- `methodParameters` — (Optional) Parameters specific to the chosen method (like alpha/beta for smoothing).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Numeric/Member | ✅ Yes | The historical data to evaluate. |
| `rangeList` | Member list | ✅ Yes | The historical time range. Cannot contain missing data unless the method supports interpolation. |
| `trendMethod` | Keyword | ❌ No | The algorithm. Valid values: `LR` (Linear Regression - Default), `SMA` (Simple Moving Average), `WMA` (Weighted Moving Average), `EMA` (Exponential Moving Average), `SES` (Single Exponential Smoothing), `DES` (Double Exponential Smoothing). |
| `params` | Numeric | ❌ No | Depending on the method, you must provide extra parameters (e.g., for `SMA`, you provide the number of periods to average). |

---

## Supported Methods & Parameters

| Method | Description | Required Parameters |
|--------|-------------|---------------------|
| **LR** (Default) | Linear Regression (fits a straight line `y = mx + b`) | None |
| **SMA** | Simple Moving Average | `n` (number of periods to average) |
| **WMA** | Weighted Moving Average | `n` (number of periods) and `w1, w2... wn` (weights) |
| **EMA** | Exponential Moving Average | `n` (number of periods) |
| **SES** | Single Exponential Smoothing (no trend/seasonality) | `alpha` (smoothing constant between 0 and 1) |
| **DES** | Double Exponential Smoothing (handles linear trend) | `alpha`, `beta` (constants between 0 and 1) |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the projected value for the current member being calculated based on the trend established in the `rangeList`.

---

## How It Works (Behind the Scenes)

1. **Algorithm Execution**: When evaluated on a future period (e.g., `FY25`), Essbase looks back at the `rangeList` (e.g., `FY23` and `FY24`), applies the specified mathematical formula (like Linear Regression) to the historical data points, and plots the `y` value for the current period `x`.
2. **Current Context**: The function is executed *in the future period* you want to populate, but references the *past periods* in the parameters.
3. **Data Integrity**: If the historical data has massive gaps (`#MISSING`), the math will often fail or return `#MISSING` for the forecast. You must ensure the historical series is continuous.

---

## Syntax Variants & Scenarios

### Variant 1: Default Linear Regression

```essbase
"Forecast" = @TREND("Actual", @RANGE("Jan", "Dec"));
```

### Variant 2: Double Exponential Smoothing

```essbase
"Forecast" = @TREND("Actual", @RANGE("Jan", "Dec"), DES, 0.3, 0.2);
```

### Variant 3: 3-Period Simple Moving Average

```essbase
"Forecast" = @TREND("Actual", @RANGE("Jan", "Dec"), SMA, 3);
```

---

## Practical Examples

### Example 1: Seeding Next Year's Budget with Linear Regression

**Scenario**: Generate a baseline budget for FY25 using the actual trend from FY23 and FY24.

```essbase
FIX("FY25", "Budget", @DESCENDANTS("Total Entity"))
    FIX("Jan":"Dec")
        /* Assuming a cross-year historical dataset */
        "Baseline_Revenue" = @TREND("Actual", @XRANGE("FY23"->"Jan", "FY24"->"Dec"), LR);
    ENDFIX
ENDFIX
```
**What Happens**: 
- Essbase plots the 24 months of actual data, calculates the slope and intercept.
- For Jan FY25 (month 25), it calculates the projected value on that line.
- For Feb FY25 (month 26), it calculates the next point on that line, and so on.

---

### Example 2: Run-Rate Forecasting (Moving Average)

**Scenario**: Forecast OPEX for the rest of the year based on the average of the last 3 months.

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    /* Assuming Actuals exist for Jan-Mar, forecasting Apr-Dec */
    FIX("Apr":"Dec")
        "OPEX" = @TREND("OPEX", @RANGE("Jan", "Mar"), SMA, 3);
    ENDFIX
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| `#MISSING` history | Trend algorithms break if historical data has holes | Use `@FILLMISSING` or similar functions to clean historical data before trending |
| Over-fitting | Linear regression on highly volatile or seasonal data will yield a straight, meaningless line | Use predictive planning (Auto Predict) in EPM Cloud which handles seasonality natively |
| Wrong Context | Running `@TREND` in the historical periods instead of the future periods | `FIX` on the future (Forecast) and pass the past (Actuals) into the `rangeList` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SPLINE`](./@SPLINE.md) | Interpolates missing data points within a range |
| [`@XRANGE`](../18_Range_Set_Operations/@XRANGE.md) | Required for cross-year historical ranges |
| Predictive Planning | EPM Cloud's native machine learning forecasting tool (often replaces custom `@TREND` scripts) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @TREND](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/trend.html)
