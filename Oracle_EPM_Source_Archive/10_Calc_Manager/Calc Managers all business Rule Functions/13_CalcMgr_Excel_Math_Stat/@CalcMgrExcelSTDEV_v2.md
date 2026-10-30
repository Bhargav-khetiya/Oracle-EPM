# @CalcMgrExcelSTDEV

## Overview

`@CalcMgrExcelSTDEV` is a **custom Calc Manager statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `STDEV` (specifically `STDEV.S` for samples) function directly inside an Essbase calculation script. 
It analyzes a list or array of data points and calculates the **Sample Standard Deviation**, providing a single metric that represents how widely spread out the data is from the average.

### Why Does This Function Exist?

Standard Deviation is the ultimate measure of volatility and risk. If a store sells exactly 100 units every single week, the standard deviation is 0. If it sells 200 one week and 0 the next, the average is still 100, but the standard deviation is extremely high. 
Calculating this manually in Essbase is a nightmare. You have to calculate the overall average, loop through every single data point to subtract the average, square that difference, sum all the squares together, divide by `(N - 1)`, and finally take the square root. 
`@CalcMgrExcelSTDEV` offloads this massive multi-step algorithm entirely to the Java engine. It ingests the array, instantly handles all the intermediate averaging and squaring, and returns the final standard deviation metric.

### When to Use It

- **Safety Stock Models**: Calculating the volatility of historical demand to determine exactly how many buffer units are required to prevent stock-outs.
- **Financial Risk Analysis**: Measuring the volatility of investment returns over time to calculate the Sharpe Ratio or Value at Risk (VaR).
- Whenever you need to migrate an Excel spreadsheet containing the `STDEV` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelSTDEV(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelSTDEV(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("Forecast_Months")`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first number or array in the sample. |
| `val2` | Numeric | ✅ Yes | The second number. (Requires at least 2 numbers to calculate variance). |
| `[valN]` | Array/List| ❌ No  | Any subsequent numbers or ranges forming the dataset. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the sample standard deviation of the provided data points.
- If all values are identical, it returns `0`.
- If there is only `1` valid data point in the entire array (or if all others are `#MISSING`), the math (`N-1`) results in a division by zero, and the function returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine ingests the array of data points.
2. **Missing Handling**: It drops `#MISSING` values from the list and counts the total number of valid remaining items (`N`).
3. **Mean Calculation**: It sums all valid items and divides by `N` to find the sample mean (average).
4. **Variance Calculation**: It loops through the array again, subtracting the mean from each item and squaring the result. It sums these squared differences and divides by `(N - 1)`. *(Note: Dividing by N-1 is what makes this a "Sample" calculation, accounting for uncertainty in smaller datasets, as opposed to a "Population" calculation).*
5. **Square Root**: It takes the square root of the variance to find the standard deviation.
6. **Return**: Passes the finalized metric back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Monthly Demand Volatility

```essbase
/* Analyzes demand across all 12 months. Returns a single standard deviation metric. */
"Demand_Volatility" = @CalcMgrExcelSTDEV("Units_Sold"->@CHILDREN("YearTotal"));
```

---

## Practical Examples

### Example 1: Dynamic Supply Chain Safety Stock

**Scenario**: A corporate supply chain model calculates physical safety stock requirements. The math for safety stock is `Z-Score * Standard Deviation of Lead-Time Demand`. The FP&A team has the target Z-Score (e.g., `1.64` for 95% confidence). They use `STDEV` to calculate the volatility of the past 12 months of actual sales.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* Calculate the standard deviation of the past 12 months of actual sales */
    "Demand_Standard_Deviation" = @CalcMgrExcelSTDEV(
        "Actual_Sales_Units"->@CHILDREN("Prior_Year_Months")
    );
    
    /* Ensure there was actually volatility before calculating safety stock */
    IF("Demand_Standard_Deviation" > 0 AND "Target_Z_Score" > 0)
        
        /* Multiply standard deviation by the Z-Score to find required buffer */
        "Required_Safety_Stock" = @ROUND("Target_Z_Score" * "Demand_Standard_Deviation", 0);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Zero vs Missing | The database contains actual `0`s | `STDEV` safely ignores `#MISSING` values. However, if your data load process populated empty months with hardcoded `0`s, those `0`s will be treated as massive drops in sales. They will pull the average down and violently increase the calculated standard deviation, causing your safety stock calculations to explode. Ensure empty data is truly `#MISSING` |
| Small Datasets | `STDEV(A)` | Standard deviation measures variance between data points. If your array only has 1 valid data point, there is no variance to measure, and the underlying `N-1` math triggers a divide-by-zero error. Ensure your arrays have at least 2 valid numbers |
| Population vs Sample | Using `STDEV` for an entire population | `STDEV` divides by `(N-1)`. It assumes the data you provided is only a sample of a larger trend. If you have the data for the *entire* population and want absolute mathematical variance (dividing by `N`), you should use `@CalcMgrExcelSTDEVP` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelSTDEVP`](../07_Statistical/@STDEVP.md) | Calculates Standard Deviation for an entire *Population* (divides by N instead of N-1) |
| [`@CalcMgrExcelVAR`](./@CalcMgrExcelVAR.md) | Calculates the Variance (which is just the Standard Deviation before the final square root is taken) |
| [`@CalcMgrExcelNORMSINV`](../15_CalcMgr_Utility/@CalcMgrExcelNORMSINV.md) | Calculates the Z-Score based on a probability target, which is typically multiplied by the Standard Deviation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelstdev.html)
