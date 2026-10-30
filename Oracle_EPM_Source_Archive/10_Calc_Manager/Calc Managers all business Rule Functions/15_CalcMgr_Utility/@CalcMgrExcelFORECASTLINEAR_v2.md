# @CalcMgrExcelFORECASTLINEAR

## Overview

`@CalcMgrExcelFORECASTLINEAR` is a **custom Calc Manager predictive mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It replicates the behavior of the Microsoft Excel `FORECAST.LINEAR` (or simply `FORECAST`) function directly inside an Essbase calculation script. 
It predicts a future value along a linear trend by using existing historical data points. It essentially calculates the "line of best fit" (linear regression) through a known set of X and Y values, and then determines what the Y value will be at a specific future X coordinate.

### Why Does This Function Exist?

Predictive planning is a massive component of EPM Cloud. FP&A analysts constantly need to extrapolate future sales, expenses, or headcount based on historical trends. 
In Excel, analysts simply use `=FORECAST(Future_Month, Known_Sales, Known_Months)`. To calculate linear regression manually in Essbase, a developer would have to write massive algebraic formulas to find the Slope (using covariances and variances) and the Y-Intercept, and then apply `Y = mx + b`. This requires dozens of lines of code and massive iterative loops for every single product they want to forecast.
`@CalcMgrExcelFORECASTLINEAR` condenses the entire linear regression algorithm into a single Java call. It takes the target X value, the array of historical Y values (e.g., Sales), and the array of historical X values (e.g., Month Index), and instantly returns the mathematically perfect trendline projection.

### When to Use It

- **Sales Forecasting**: Predicting next quarter's revenue based on a linear regression of the past 12 months.
- **Expense Modeling**: Estimating future utility costs based on a historical correlation between production volume (X) and energy spend (Y).
- Whenever you need to migrate an Excel spreadsheet containing the `FORECAST` or `FORECAST.LINEAR` function directly into an Essbase calculation.

---

## Category

**Statistical / Predictive / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelFORECASTLINEAR(x, known_y's, known_x's)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | Numeric | ✅ Yes | The target data point (e.g., Month 13) for which you want to predict a value. |
| `known_y's` | Array/List | ✅ Yes | The dependent array of historical data (e.g., Historical Sales Dollars). This is usually passed as a cross-dimensional range like `"Sales"->@CHILDREN("FY23")`. |
| `known_x's` | Array/List | ✅ Yes | The independent array of historical data (e.g., Month Index 1-12, or Historical Production Units). Must be exactly the same size/length as the `known_y's` array. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the predicted value (Y) along the linear trendline.
- E.g., If sales are climbing by exactly $100 every month, and month 12 was $1,200, asking it to forecast Month 13 will return `1300`.

---

## How It Works (Behind the Scenes)

1. **Parameter Alignment**: The Java engine ingests the two arrays (`known_y's` and `known_x's`) and ensures they are exactly the same length. If they are mismatched, the function fails.
2. **Missing Handling**: It typically pairs the data points. If a `#MISSING` value exists in either array at position *N*, it usually drops position *N* from both arrays to prevent skewing the regression.
3. **Regression Math**: It calculates the Mean of X and Mean of Y. It then calculates the Slope (`m`) and the Y-Intercept (`b`).
4. **Projection**: It takes the target `x` parameter you provided, plugs it into `Y = mx + b`, and passes the resulting predicted `Y` back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Forecasting Next Month's Sales

```essbase
/* 
   Target X: Month 13 (January FY25)
   Known Ys: The actual sales dollars for Jan-Dec FY24
   Known Xs: An index metric (1 through 12) stored in Jan-Dec FY24
*/
"Forecasted_Sales" = @CalcMgrExcelFORECASTLINEAR(
    13, 
    "Actual_Sales"->@CHILDREN("FY24"), 
    "Month_Index"->@CHILDREN("FY24")
);
```

---

## Practical Examples

### Example 1: Creating a Baseline Predictive Forecast for Expenses

**Scenario**: You are building the FY25 Budget. For standard operating expenses (like "Office Supplies"), the FP&A director wants a system-generated baseline that strictly follows the linear trend of the previous 12 months. You have a statistical metric called `"Time_Index"` that simply counts up (e.g., Jan FY24 is 1, Dec FY24 is 12, Jan FY25 is 13).

```essbase
FIX("FY25", "Working", @LEVEL0("OpEx_Accounts"))
    
    /* Iterate through the forecast months (Jan - Dec) */
    FIX(@IDESCENDANTS("YearTotal"))
        
        /* 
           For every month in FY25, we look at its specific Time_Index (e.g., 13, 14, 15).
           We use the historical FY24 Actuals as the foundation for the regression. 
        */
        "Baseline_Forecast" = @ROUND(
            @CalcMgrExcelFORECASTLINEAR(
                "Time_Index",                      /* Target X (The future month) */
                "Actuals"->"FY24"->@IDESCENDANTS("YearTotal"), /* Known Ys (Historical $) */
                "Time_Index"->"FY24"->@IDESCENDANTS("YearTotal") /* Known Xs (Historical 1-12) */
            )
        , 2);
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Array Sizes | Y has 12 members, X has 11 | The `known_y's` and `known_x's` must map exactly 1-to-1. If you use `@CHILDREN("Q1")` for Y, you must use `@CHILDREN("Q1")` for X. If the arrays are different lengths, the Java engine cannot pair the data points and the regression will fail |
| Using Linear for Exponential Data | Forecasting viral adoption | `FORECASTLINEAR` strictly draws a straight line. If your business is experiencing exponential growth (like a viral SaaS product) or intense cyclical seasonality (like a toy company in December), a linear regression will provide terrible, highly inaccurate forecasts. Ensure the data mathematically suits a linear model |
| Lack of X-Axis Metrics | Trying to pass raw member names | You cannot pass `@CHILDREN("FY24")` as the X array and expect the function to know that "Jan" equals 1 and "Feb" equals 2. You must have an actual numeric metric in the cube (e.g., a `"Month_Index"` account) populated with `1, 2, 3...` to serve as the mathematical X-axis |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelSLOPE`](../07_Statistical/@TREND.md) | Calculates just the slope (`m`) of the linear regression line |
| [`@CalcMgrExcelINTERCEPT`](../07_Statistical/@TREND.md) | Calculates just the Y-intercept (`b`) of the linear regression line |
| [`@CalcMgrExcelTREND`](@CalcMgrExcelFORECASTLINEAR.md) | An advanced array-based forecasting function that can project multiple values at once |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelforecastlinear.html)
