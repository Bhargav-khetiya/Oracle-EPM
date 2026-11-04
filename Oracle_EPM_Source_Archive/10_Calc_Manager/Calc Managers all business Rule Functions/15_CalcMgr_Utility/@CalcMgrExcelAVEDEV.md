# @CalcMgrExcelAVEDEV

## Overview

`@CalcMgrExcelAVEDEV` is a **custom Calc Manager statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `AVEDEV` function directly inside an Essbase calculation script. 
It calculates the **average of the absolute deviations** of data points from their mean. In simple terms, it measures the variability or volatility of a dataset—telling you, on average, how far off each data point is from the center (mean) of the dataset, regardless of whether the deviation is positive or negative.

### Why Does This Function Exist—

Essbase natively supports `@AVG` (to find the mean) and `@STDDEV` (to find standard deviation). However, `AVEDEV` is a highly specific statistical measure often preferred in operational forecasting or supply chain models because it is less sensitive to extreme outliers than standard deviation (since it does not square the deviations).
If an FP&A analyst built a sales forecasting model in Excel using `=AVEDEV(Jan:Dec)` to measure the volatility of product sales, recreating this mathematically in an Essbase block would require multiple passes:
1. Find the Average.
2. Subtract the Average from every month.
3. Take the Absolute Value of every result.
4. Average those absolute values.
`@CalcMgrExcelAVEDEV` condenses all of this complex mathematical looping into a single, highly optimized Java function. It guarantees that the volatility score calculated in the Essbase cube matches the legacy Excel spreadsheet exactly.

### When to Use It

- In **Supply Chain or Demand Planning** models to measure the volatility of historical demand, which informs safety stock calculations.
- In **Financial Forecasting** to analyze the historical stability of revenue streams (identifying highly erratic vs. stable products).
- Whenever you need to migrate an Excel spreadsheet containing the `AVEDEV` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelAVEDEV(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelAVEDEV(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, variables, or Essbase accounts. You can also pass a range of members (like `@CHILDREN("Q1")` or `@IDESCENDANTS("YearTotal")`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first number or data pointer in the dataset. |
| `val2` | Numeric | ✅ Yes | The second number or data pointer in the dataset. |
| `[valN]` | Numeric | ❌ No  | Any subsequent numbers or ranges forming the dataset. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the average absolute deviation of the dataset.
- Automatically ignores `#MISSING` values without throwing calculation errors, preventing blank months from artificially dragging down the mean.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the list or array of values (e.g., 12 months of sales data).
2. **Missing Handling**: It drops or ignores `#MISSING` flags.
3. **Pass 1 (Mean)**: It calculates the simple arithmetic average (mean) of the valid numbers.
4. **Pass 2 (Deviation)**: It iterates through every number, subtracts the mean, and takes the absolute value (converting negatives to positives).
5. **Pass 3 (Final Average)**: It calculates the average of those absolute differences and returns the final score to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Measuring Volatility of a Specific Array

```essbase
/* Equivalent to Excel's =AVEDEV(Jan:Dec) */
"Sales_Volatility" = @CalcMgrExcelAVEDEV("Sales"->@IDESCENDANTS("YearTotal"));
```

---

## Practical Examples

### Example 1: Demand Volatility for Safety Stock Planning

**Scenario**: You have a Supply Chain model. For every product, you have 12 months of historical `"Units_Sold"`. If a product sells a steady 100 units every month, its volatility is 0, and you don't need much safety stock. If it sells 500 one month and 0 the next, its volatility is high, requiring higher safety stock. You calculate the `AVEDEV` score and assign a classification.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* Calculate the average absolute deviation across all 12 months */
    "Demand_Volatility_Score" = @CalcMgrExcelAVEDEV("Units_Sold"->@IDESCENDANTS("YearTotal"));
    
    /* Calculate the standard Average (Mean) */
    "Average_Monthly_Demand" = @AVG(SKIPNONE, "Units_Sold"->@IDESCENDANTS("YearTotal"));
    
    /* Calculate a Volatility Index (Deviation as a % of Average Demand) */
    IF("Average_Monthly_Demand" > 0)
        
        "Volatility_Index" = "Demand_Volatility_Score" / "Average_Monthly_Demand";
        
        /* Assign classifications for the procurement team */
        IF("Volatility_Index" > 0.5)
            "Safety_Stock_Tier" = 3; /* Highly Volatile - High Safety Stock */
        ELSEIF("Volatility_Index" > 0.2)
            "Safety_Stock_Tier" = 2; /* Moderate */
        ELSE
            "Safety_Stock_Tier" = 1; /* Stable - Low Safety Stock */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misinterpreting the result | Confusing `AVEDEV` with Standard Deviation (`STDDEV`) | Standard deviation squares the differences, which heavily penalizes massive outliers. `AVEDEV` takes absolute differences, treating all deviations linearly. They will yield different results. Ensure you are using the exact statistical model your business requested |
| Passing Strings | `@CalcMgrExcelAVEDEV("10", "20")` | This function expects numeric references or literal numbers. If you pass a hardcoded string `"10"`, it will fail. Ensure variables are numeric |
| Array Target Mismatches | Assigning to a single cell while looping | This function aggregates data. It is usually placed in a dense block pointing to a specific cross-dimensional target (e.g., `"No_Period"` or `"YearTotal"`) to store the final summary score, rather than being calculated *within* a time loop |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@STDDEV`](./@STDDEV.md) | The native Essbase function for Standard Deviation (the most common alternative to AVEDEV) |
| [`@AVG`](./@AVG.md) | The native Essbase function for simple Arithmetic Mean |
| [`@CalcMgrExcelVAR`](./@CalcMgrExcelVAR.md) | Calculates the statistical Variance of a sample dataset |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelavedev.html)
