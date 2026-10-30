# @CalcMgrExcelVARP

## Overview

`@CalcMgrExcelVARP` is a **custom Calc Manager statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `VARP` (or `VAR.P`) function directly inside an Essbase calculation script. 
It analyzes a list or array of data points and calculates the **Population Variance**, which measures how far a set of numbers is spread out from their average value.

### Why Does This Function Exist?

There is a subtle but critical mathematical difference between Sample Variance (`VAR`) and Population Variance (`VARP`). 
If you are evaluating 50 stores, but you only have data for 10 of them, you are evaluating a *Sample*. To account for the statistical uncertainty of the missing 40 stores, Sample Variance divides the sum of squares by `(N - 1)`, artificially inflating the variance to be conservative. 
However, if you are evaluating the exact salaries of all 50 employees in a 50-person company, there is zero uncertainty. You have the entire *Population*. You must use `VARP`, which divides the sum of squares exactly by `N`. 
`@CalcMgrExcelVARP` executes this absolute mathematical variance algorithm instantly in the Java engine, ensuring your HR, taxation, and physical capacity models maintain absolute mathematical precision.

### When to Use It

- **Total Population Analysis**: Calculating variance metrics for an entire closed system, such as analyzing the exact defect rates across all 10 machines in a 10-machine factory.
- **Macro-Economic Modeling**: Evaluating macroeconomic indicators (like analyzing GDP variance across all 50 US States).
- Whenever you need to migrate an Excel spreadsheet containing the `VARP` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelVARP(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelVARP(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("All_Employees")`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first number or array in the population. |
| `val2` | Numeric | ✅ Yes | The second number. (Requires at least 2 valid numbers). |
| `[valN]` | Array/List| ❌ No  | Any subsequent numbers or ranges forming the dataset. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the absolute Population Variance of the provided data points.
- If all values in the array are perfectly identical (e.g., `[10, 10, 10]`), there is no spread, and the function returns `0`.
- The returned variance will be strictly positive (or 0).
- Unlike `VAR`, `VARP` will successfully calculate a variance of `0` even if there is only 1 valid data point, because dividing by `N` (where N=1) does not cause a divide-by-zero error.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine ingests the array of data points.
2. **Missing Handling**: It drops `#MISSING` values from the list and counts the total number of valid remaining items (`N`).
3. **Mean Calculation**: It sums all valid items and divides by `N` to find the absolute population mean.
4. **Variance Calculation**: It loops through the array again, subtracting the mean from each item and squaring the result. It sums these squared differences.
5. **Population Division**: It divides that massive sum exactly by `N`. 
6. **Return**: Passes the finalized metric back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Global Headcount Variance

```essbase
/* Analyzes exact headcount across all global regions. Returns a single variance metric. */
"Global_Distribution_Variance" = @CalcMgrExcelVARP("Total_Headcount"->@CHILDREN("All_Regions"));
```

---

## Practical Examples

### Example 1: HR Salary Equality Index

**Scenario**: A corporate HR department wants to measure "Salary Equality" within specific departments. If a department has 5 employees, and they all make exactly $100,000, the equality is perfect (Variance = 0). If one person makes $200k and the others make $50k, the variance is massive. Because the HR department has the exact salary data for every single employee in the department, this is a Population, not a sample.

```essbase
FIX("FY25", "Working", @LEVEL0("Departments"))
    
    /* Ensure the department has active payroll */
    IF(@SUM("Base_Salary"->@CHILDREN("Total_Employees")) > 0)
        
        /* 
           1. Calculate the Population Variance across all employees 
           within this specific department.
        */
        "Department_Salary_Variance" = @CalcMgrExcelVARP(
            "Base_Salary"->@CHILDREN("Total_Employees")
        );
        
        /* 
           2. Standardize the score to Standard Deviation for easier reading 
           (Square Root of the Variance)
        */
        "Salary_Equality_Index" = @CalcMgrExcelSQRT("Department_Salary_Variance");
        
        /* 3. Flag departments with highly unequal pay bands */
        IF("Salary_Equality_Index" > 25000)
            "HR_Review_Flag" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for Future Forecasts | `VARP("Sales_Forecast"->@CHILDREN("Months"))` | `VARP` is mathematically designed for absolute, complete datasets (like historical actuals for a closed period). Forecasts are, by definition, samples of probability. Using `VARP` on a forecast artificially understates the risk. You should almost always use `VAR` for forecasting models to properly account for statistical uncertainty |
| Zero vs Missing | The database contains actual `0`s | `VARP` safely ignores `#MISSING` values. However, if an employee left the company and their salary is populated as `0` instead of `#MISSING`, the engine treats them as an active employee earning `$0`. This pulls the mean down, drastically inflates the variance, and counts toward the `N` denominator. Ensure empty data is truly `#MISSING` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelVAR`](./@CalcMgrExcelVAR.md) | Calculates Variance for a *Sample* (divides by N-1 instead of N, inflating the variance to account for uncertainty) |
| [`@CalcMgrExcelSTDEVP`](../07_Statistical/@STDEVP.md) | Calculates the Population Standard Deviation (which is just the square root of the Population Variance) |
| [`@CalcMgrExcelSUMSQ`](./@CalcMgrExcelSUMSQ.md) | Purely squares and sums an array, without calculating the mean or dividing by N |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelvarp.html)
