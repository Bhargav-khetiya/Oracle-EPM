# @CalcMgrExcelVAR

## Overview

`@CalcMgrExcelVAR` is a **custom Calc Manager statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `VAR` (specifically `VAR.S` for samples) function directly inside an Essbase calculation script. 
It analyzes a list or array of data points and calculates the **Sample Variance**, which measures how far a set of numbers is spread out from their average value.

### Why Does This Function Exist—

Variance is the fundamental mathematical building block of almost all risk and probability modeling. It is the average of the squared differences from the Mean. (Taking the square root of the Variance gives you the Standard Deviation).
Calculating Variance manually in an Essbase calc script is extremely inefficient. You must calculate the mean across the array, loop through every single member to subtract that mean, square the difference, sum all the squares, and finally divide by `(N - 1)`. 
`@CalcMgrExcelVAR` eliminates this manual loop. It dynamically streams the array into the Java engine, executes the summation of squares, and instantly returns the Variance, guaranteeing perfect parity with legacy Excel statistical sheets.

### When to Use It

- **Manufacturing & Quality Control**: Measuring the variance in product defect rates across different factories to isolate quality control failures.
- **Sales Forecasting**: Analyzing historical sales variance to determine the mathematical stability of a product line before relying on predictive trendlines.
- Whenever you need to migrate an Excel spreadsheet containing the `VAR` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelVAR(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelVAR(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("Forecast_Months")`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first number or array in the sample. |
| `val2` | Numeric | ✅ Yes | The second number. (Requires at least 2 valid numbers to calculate variance). |
| `[valN]` | Array/List| ❌ No  | Any subsequent numbers or ranges forming the dataset. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Sample Variance of the provided data points.
- If all values in the array are perfectly identical (e.g., `[10, 10, 10]`), there is no spread, and the function returns `0`.
- Because the math involves squaring the differences, the Variance will *always* be a positive number (or 0).
- If there is only `1` valid data point in the entire array, the math `(N-1)` results in a division by zero, and the function returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine ingests the array of data points.
2. **Missing Handling**: It drops `#MISSING` values from the list and counts the total number of valid remaining items (`N`).
3. **Mean Calculation**: It sums all valid items and divides by `N` to find the sample mean.
4. **Variance Calculation**: It loops through the array again, subtracting the mean from each item and squaring the result. It sums these squared differences.
5. **Sample Division**: It divides that massive sum by `(N - 1)`. *(Note: Dividing by N-1 instead of N is what makes this a "Sample" calculation, mathematically correcting for the bias that occurs when you don't have data for the entire population).*
6. **Return**: Passes the finalized metric back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Monthly Sales Variance

```essbase
/* Analyzes sales across all 12 months. Returns a single variance metric. */
"Historical_Sales_Variance" = @CalcMgrExcelVAR("Units_Sold"->@CHILDREN("YearTotal"));
```

---

## Practical Examples

### Example 1: Isolating High-Risk Volatile Products

**Scenario**: A corporate supply chain team wants to flag products that are highly erratic and unpredictable. If a product sells a steady 100 units a month, it is low risk. If it sells 500 one month and 0 the next, it is high risk. The team calculates the Variance of the last 6 months of sales. If the variance exceeds a specific threshold, the product is flagged for manual review by a demand planner.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* Ensure there is actually sales data to measure */
    IF(@SUM("Actual_Sales"->@CHILDREN("H1")) > 0)
        
        /* 
           1. Calculate the Variance across the 6 months of H1.
        */
        "Sales_Variance_Score" = @CalcMgrExcelVAR(
            "Actual_Sales"->"Jan", "Actual_Sales"->"Feb", "Actual_Sales"->"Mar",
            "Actual_Sales"->"Apr", "Actual_Sales"->"May", "Actual_Sales"->"Jun"
        );
        
        /* 
           2. Evaluate the score against a corporate volatility threshold.
           (Variance numbers get very large because the differences are squared).
        */
        IF("Sales_Variance_Score" > 1000000)
            "High_Volatility_Flag" = 1;
        ELSE
            "High_Volatility_Flag" = 0;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Zero vs Missing | The database contains actual `0`s | `VAR` safely ignores `#MISSING` values. However, if empty months are hardcoded as `0`s, the engine treats those as massive drops in sales. They will pull the mean down and violently increase the variance metric, throwing off your risk scoring. Ensure empty data is truly `#MISSING` |
| Small Datasets | `VAR(A)` | Variance measures the difference *between* data points. If your array only has 1 valid data point, there is no difference to measure, and the `N-1` math triggers a divide-by-zero error. Ensure your arrays have at least 2 valid numbers |
| Population vs Sample | Using `VAR` for an entire population | `VAR` divides by `(N-1)`. It assumes the data provided is only a sample. If you are calculating variance for every single employee in a company (the entire population) and want absolute mathematical variance (dividing by `N`), you should use `@CalcMgrExcelVARP` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelVARP`](./@CalcMgrExcelVARP.md) | Calculates Variance for an entire *Population* (divides by N instead of N-1) |
| [`@CalcMgrExcelSTDEV`](./@CalcMgrExcelSTDEV.md) | Calculates the Standard Deviation (which is just the square root of the Variance) |
| [`@CalcMgrExcelSUMSQ`](./@CalcMgrExcelSUMSQ.md) | Purely squares and sums an array, without calculating the mean or dividing by N-1 |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelvar.html)
