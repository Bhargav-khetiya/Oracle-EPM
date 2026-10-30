# @CalcMgrExcelSUMSQ

## Overview

`@CalcMgrExcelSUMSQ` is a **custom Calc Manager mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `SUMSQ` function directly inside an Essbase calculation script. 
It takes an array of data points, mathematically **squares** each individual number, and then **sums** all of those squared values together into a single total.

### Why Does This Function Exist?

The "Sum of Squares" is a foundational calculation in advanced statistics, regression analysis, and machine learning models (like Ordinary Least Squares). When measuring the error or deviation of a dataset from a trendline, you must square the deviations before summing them so that negative errors (e.g., `-5`) and positive errors (`+5`) do not artificially cancel each other out to `0`. 
Doing this manually in an Essbase calc script requires creating a temporary variable array, looping through the data to square each number, and then summing the temporary array. `@CalcMgrExcelSUMSQ` eliminates the need for looping and temporary variables. It streams the data into the Java engine, squares every element on the fly, and returns the final aggregate sum, guaranteeing parity with legacy Excel statistical modeling.

### When to Use It

- **Regression Analysis**: Calculating the Sum of Squared Errors (SSE) to determine how well a linear trendline fits historical sales data.
- **Custom Statistics**: Building custom variance or standard deviation formulas that fall outside the bounds of the standard `@CalcMgrExcelSTDEV` function.
- Whenever you need to migrate an Excel spreadsheet containing the `SUMSQ` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelSUMSQ(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelSUMSQ(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("Forecast_Months")`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first number or array in the dataset. |
| `val2` | Numeric | ❌ No  | The second number or array. |
| `[valN]` | Array/List| ❌ No  | Any subsequent numbers or ranges forming the dataset. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the aggregated sum of the squares.
- Because every number (positive or negative) becomes positive when squared, the result of this function will *always* be a positive number (or 0).
- E.g., `@CalcMgrExcelSUMSQ(3, -4)` mathematically evaluates to `(3^2) + (-4^2) = 9 + 16 = 25`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine ingests the array of data points.
2. **Missing Handling**: It drops or ignores `#MISSING` values from the list.
3. **Execution Loop**: It iterates through the array. For each number, it executes `Math.pow(number, 2)` to square it, and adds the result to a running total.
4. **Return**: Passes the massive finalized sum back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Squaring and Summing

```essbase
/* Squares the numbers (16, 25, 36) and sums them. Returns 77. */
"Result" = @CalcMgrExcelSUMSQ(4, 5, 6);
```

### Variant 2: Array Evaluation

```essbase
/* Analyzes all 12 months of variance data, squares them, and sums them. */
"Sum_of_Squared_Variance" = @CalcMgrExcelSUMSQ("Volume_Variance"->@CHILDREN("YearTotal"));
```

---

## Practical Examples

### Example 1: Calculating Sum of Squared Errors (SSE)

**Scenario**: A corporate supply chain model uses a machine learning trendline to forecast demand. It stores the `"Actual_Sales"` and the `"Trendline_Forecast"`. The FP&A team calculates the `"Forecast_Error"` every month (Actual - Forecast). To score how accurate the model is over the entire year, they need to calculate the Sum of Squared Errors (SSE) across all 12 months.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* 
       Step 1: The 'Forecast_Error' account is already populated with 
       values like -15, 10, -5, etc.
    */
    
    /* 
       Step 2: Calculate the SSE for the entire year. 
       This squares the errors (so -15 becomes 225) and sums them all up.
    */
    "Annual_SSE_Score" = @CalcMgrExcelSUMSQ("Forecast_Error"->@CHILDREN("YearTotal"));
    
    /* Note: A lower SSE score means the forecasting model is highly accurate. */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Floating Point Limits | Passing massive currency numbers | If you pass an array of fifty different `$1,000,000` values, squaring them creates absolutely astronomical numbers (`10^12`), and summing them up can quickly breach the 64-bit floating point precision limits of the Essbase engine, returning `Infinity` or `#MISSING`. `SUMSQ` is typically used for smaller metrics, errors, or ratios, not raw enterprise currency blocks |
| Confusing with SUMPRODUCT | Wanting `Array 1 * Array 2` | `SUMSQ` takes a single array and squares the numbers inside it (`Array1 * Array1`). If you need to multiply two completely different arrays together (e.g., `Units * Price`) and sum the results, you must use `@CalcMgrExcelSUMPRODUCT` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelSUMPRODUCT`](./@CalcMgrExcelSUMPRODUCT.md) | Multiplies two different arrays against each other and sums the results |
| [`@SUM`](../06_Mathematical/@SUM.md) | Standard addition of a single array (no squaring) |
| [`@CalcMgrExcelSTDEV`](./@CalcMgrExcelSTDEV.md) | Calculates Standard Deviation (which natively uses sum-of-squares logic behind the scenes) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelsumsq.html)
