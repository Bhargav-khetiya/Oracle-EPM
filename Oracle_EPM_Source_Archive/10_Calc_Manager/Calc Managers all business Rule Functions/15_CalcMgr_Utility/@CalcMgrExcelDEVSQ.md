# @CalcMgrExcelDEVSQ

## Overview

`@CalcMgrExcelDEVSQ` is a **custom Calc Manager statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DEVSQ` function directly inside an Essbase calculation script. 
It calculates the **Sum of Squares of Deviations** of data points from their sample mean. In statistical terms, it is a core building block used to measure the variance or dispersion within a dataset.

### Why Does This Function Exist?

When analyzing historical data (like sales volume, manufacturing defect rates, or employee churn), statisticians look at variance to understand how erratic the data is. To calculate variance manually, you must:
1. Find the Average (Mean) of the dataset.
2. Subtract the Mean from every single data point (finding the deviation).
3. **Square** every single deviation (to turn negative differences into positives and penalize large outliers).
4. Sum all of those squared numbers together.

Steps 1-4 describe the exact mathematical output of `DEVSQ`. In Essbase, doing this manually requires iterating through arrays, creating temporary variables to hold the mean, and running heavy multiplication loops. `@CalcMgrExcelDEVSQ` bypasses all of this. It ingests an array of data points, and the Java engine executes all 4 steps instantly, returning the precise Sum of Squared Deviations.

### When to Use It

- **Statistical Analysis**: When building custom regression models or custom variance calculators where the native `@VAR` or `@STDDEV` functions don't provide the exact mathematical building blocks you need.
- **Data Smoothing**: Identifying how far a specific time series (like monthly revenue) fluctuates away from its average baseline.
- Whenever you need to migrate an Excel spreadsheet containing the `DEVSQ` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDEVSQ(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelDEVSQ(numericList)
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

Returns the mathematical sum of the squared deviations from the mean.
- Automatically ignores `#MISSING` values without throwing calculation errors, preventing blank months from artificially dragging down the mean.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the list or array of values (e.g., 12 months of sales data).
2. **Missing Handling**: It drops or ignores `#MISSING` flags.
3. **Pass 1 (Mean)**: It calculates the simple arithmetic average (mean) of the valid numbers.
4. **Pass 2 (Square & Sum)**: It iterates through every number, subtracts the mean, squares the result (multiplying it by itself), and accumulates that into a running total.
5. **Return**: It passes the final sum back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Measuring Dispersion of a Specific Array

```essbase
/* Equivalent to Excel's =DEVSQ(Jan:Dec) */
"Sum_Of_Squares" = @CalcMgrExcelDEVSQ("Sales"->@IDESCENDANTS("YearTotal"));
```

---

## Practical Examples

### Example 1: Custom Quality Control Variance

**Scenario**: A manufacturing plant tracks `"Defect_Count"` daily. You are tasked with determining how erratic the defect rate is over the course of a month. You need the Sum of Squared Deviations as an intermediate variable to feed into a custom Six Sigma probability model.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* Calculate the DEVSQ across all days in the current month */
    "Defect_Dispersion_Index" = @CalcMgrExcelDEVSQ("Defect_Count"->@CHILDREN("Current_Month"));
    
    /* If the dispersion is massive, it means defects are highly erratic (e.g., machines breaking down), 
       rather than a steady, predictable failure rate. Flag it. */
    IF("Defect_Dispersion_Index" > "Six_Sigma_Threshold")
        "Process_Review_Required" = 1;
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing DEVSQ with Variance | Expecting DEVSQ to output final Variance | `DEVSQ` is only the *numerator* of the Variance equation. To find actual statistical Variance, you must divide the output of `DEVSQ` by `N` (Population Variance) or `N-1` (Sample Variance). If you just want Variance, use `@CalcMgrExcelVAR` or `@CalcMgrExcelVARP` instead |
| Passing Strings | `@CalcMgrExcelDEVSQ("10", "20")` | This function expects numeric references or literal numbers. If you pass a hardcoded string `"10"`, it will fail. Ensure variables are numeric |
| Array Target Mismatches | Assigning to a single cell while looping | This function aggregates data across a list. It is usually placed in a dense block pointing to a specific cross-dimensional target (e.g., `"No_Period"` or `"YearTotal"`) to store the final summary score, rather than being calculated *within* a time loop |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelVAR`](./@CalcMgrExcelVAR.md) | Calculates the actual Sample Variance (which internally uses DEVSQ / N-1) |
| [`@CalcMgrExcelVARP`](./@CalcMgrExcelVARP.md) | Calculates the Population Variance (which internally uses DEVSQ / N) |
| [`@CalcMgrExcelAVEDEV`](./@CalcMgrExcelAVEDEV.md) | Calculates the average of the absolute deviations (a different, non-squared measure of data dispersion) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldevsq.html)
