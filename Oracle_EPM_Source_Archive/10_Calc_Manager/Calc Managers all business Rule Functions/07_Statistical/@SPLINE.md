# @SPLINE

## Overview

`@SPLINE` is a **statistical interpolation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It is used to fill in missing data points (`#MISSING`) within a series of data by fitting a smooth curve (a cubic spline) through the known data points. 

### Why Does This Function Exist—

Real-world financial and operational data is rarely perfectly continuous. There may be gaps due to missing submissions, system errors, or irregular entry periods (e.g., quarterly data that needs to be smoothed into monthly data).
- **Data Cleansing**: Before running functions like `@TREND` or `@STDEV`, which fail or skew heavily on missing data, you must "fill the gaps."
- **Curve Fitting**: Simple averaging between two points creates jagged, unnatural straight lines. Spline interpolation creates a mathematically smooth curve that honors the trajectory of the surrounding data.

### When to Use It

- To interpolate missing values in a time series prior to forecasting.
- To smooth out irregular data inputs into a continuous trend.
- When expanding quarterly or annual totals into a smooth monthly distribution.

---

## Category

**Statistical / Interpolation / Data Cleansing**

---

## Syntax

```essbase
@SPLINE(value, rangeList)
```

### Formal Syntax

```
@SPLINE(valueExpression, dataRange)
```

Where:
- `valueExpression` — The measure containing gaps (e.g., `"Revenue"`).
- `dataRange` — The time range to evaluate and interpolate across.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Numeric/Member | ✅ Yes | The historical data measure to evaluate and fill. |
| `rangeList` | Member list | ✅ Yes | The time range containing the known points and the gaps. Usually `@XRANGE` or `@RANGE`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the interpolated numeric value for the current member being calculated, if that member's original value was `#MISSING`. If the current member already had a valid value, it generally returns that original value (though internal smoothing may adjust it depending on the exact spline implementation).

---

## How It Works (Behind the Scenes)

1. **Cubic Spline Mathematics**: Essbase uses a cubic spline algorithm. It takes all the *known* (non-missing) data points in the `rangeList` and calculates a series of cubic polynomials to connect them, ensuring that the connections between the polynomials are mathematically smooth (continuous first and second derivatives).
2. **Execution**: When evaluating a cell that is `#MISSING`, Essbase looks at the spline curve and calculates the exact `y` value for that specific `x` coordinate (time period).
3. **Endpoints**: Spline interpolation works best for filling gaps *between* known data points. If the missing data is at the very beginning or end of the series (extrapolation), the cubic spline can swing wildly and produce unrealistic numbers. Use `@TREND` for forecasting (extrapolation).

---

## Syntax Variants & Scenarios

### Variant 1: Filling Gaps in a Single Year

```essbase
"Smoothed_Sales" = @SPLINE("Sales", @RANGE("Jan", "Dec"));
```

### Variant 2: Cross-Year Interpolation

```essbase
"Cleaned_Data" = @SPLINE("Raw_Data", @XRANGE("FY23"->"Jan", "FY25"->"Dec"));
```

---

## Practical Examples

### Example 1: Cleansing Historical Data for Forecasting

**Scenario**: You want to use `@TREND` to forecast FY25, but the FY24 actuals have a `#MISSING` value in March and August due to an ERP glitch.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total Entity"))
    FIX("Jan":"Dec")
        /* Create a cleansed version of Actuals */
        IF("Revenue" == #MISSING)
            "Cleansed_Revenue" = @SPLINE("Revenue", @RANGE("Jan", "Dec"));
        ELSE
            "Cleansed_Revenue" = "Revenue";
        ENDIF
    ENDFIX
ENDFIX

/* Now use the cleansed data for forecasting */
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    FIX("Jan":"Dec")
        "Forecast_Revenue" = @TREND("Cleansed_Revenue", @XRANGE("FY24"->"Jan", "FY24"->"Dec"), LR);
    ENDFIX
ENDFIX
```

---

### Example 2: Quarterly to Monthly Smoothing

**Scenario**: You receive external market data quarterly (Jan, Apr, Jul, Oct). You need to estimate the missing months (Feb, Mar, May, etc.) on a smooth curve.

```essbase
FIX("FY25", "Working", "Market_Size")
    FIX("Jan":"Dec")
        /* If the month doesn't have data, interpolate it */
        IF(@CURRMBR("Account") == #MISSING)
            @CURRMBR("Account") = @SPLINE(@CURRMBR("Account"), @RANGE("Jan", "Dec"));
        ENDIF
    ENDFIX
ENDFIX
```
*Result: Feb and Mar will be populated with values that smoothly transition between the Jan actual and the Apr actual.*

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using Spline to Forecast | `@SPLINE` is for interpolation (filling gaps inside a range). Using it to extrapolate future periods can result in extreme, unrealistic spikes | Use `@TREND` for forecasting future periods |
| Not enough known points | A cubic spline requires at least 3 or 4 known data points to calculate the curves | Ensure the range has sufficient valid data |
| Overwriting Actuals directly | If you overwrite the source data with the spline result, you lose the audit trail of what was real vs estimated | Always write the result to a new measure or scenario (e.g., "Cleansed_Actuals") |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@TREND`](./@TREND.md) | Used for extrapolation (forecasting) |
| [`@PRIOR`](./@PRIOR.md) | Can be used for simple "carry-forward" gap filling (Step-function instead of smooth curve) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @SPLINE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/spline.html)
