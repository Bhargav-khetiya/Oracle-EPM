# @CalcMgrExcelPERCENTRANK

## Overview

`@CalcMgrExcelPERCENTRANK` is a **custom Calc Manager statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `PERCENTRANK` (specifically `PERCENTRANK.INC`) function directly inside an Essbase calculation script. 
It analyzes an array of data, takes a specific numerical value, and returns the **Percentile Rank** of that value within the dataset (e.g., "If a store sold $450,000, what percentile does that store fall into compared to the rest of the company?").

### Why Does This Function Exist?

While `PERCENTILE` calculates the dollar threshold for a given target, `PERCENTRANK` is the exact inverse. It evaluates a specific individual's performance and scores them relative to their peers. 
For example, if you want to grade 50 different subsidiary companies from 0% to 100% based on their profit margins, calculating this manually in Essbase requires massive looping logic: counting exactly how many companies had a lower profit margin, dividing that by the total number of companies, and handling interpolation if the specific margin isn't an exact match to the dataset.
`@CalcMgrExcelPERCENTRANK` offloads this complex array comparison to the Java engine. It instantly sorts the dataset, evaluates where the target value fits, and returns the precise percentile decimal, perfectly matching legacy Excel performance dashboards.

### When to Use It

- **Performance Dashboards**: Scoring every sales rep, store, or region on a `0.00` to `1.00` relative scale to highlight over- and under-performers.
- **Dynamic Grading**: Automatically assigning letter grades (A, B, C) to operational units based on where their efficiency metrics rank compared to the rest of the company.
- Whenever you need to migrate an Excel spreadsheet containing the `PERCENTRANK` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelPERCENTRANK(x, val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelPERCENTRANK(x, numericList)
```

Where:
- `x` — The target numerical value you want to rank (e.g., `$450,000`).
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("Stores")` that acts as the baseline comparison array.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | Numeric | ✅ Yes | The value you want to find the rank for. **Must be passed as the VERY FIRST parameter.** |
| `val1, val2...` | Array/List | ✅ Yes | The baseline array of data to sort and compare `x` against. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the percentile rank as a decimal between `0` and `1`.
- E.g., Returns `0.85`, meaning the value `x` is greater than 85% of the values in the dataset.
- If `x` falls between two values in the array, the function calculates proportional interpolation.
- If `x` is smaller than the smallest number in the array, or larger than the largest number, the function returns `#MISSING`. (It cannot rank a number that is outside the known bounds of the dataset).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine isolates the `x` parameter and ingests the remaining array.
2. **Missing Handling**: It drops `#MISSING` values from the array.
3. **Sorting & Bounding**: It sorts the array ascending. It checks if `x` is out of bounds (less than the min, or greater than the max). If out of bounds, it aborts.
4. **Interpolation Math**: It finds the exact position of `x` within the sorted array. If it doesn't match an element exactly, it calculates the proportional distance between the two adjacent elements. It then divides the count of elements below `x` by `(Total Elements - 1)`.
5. **Return**: Passes the resulting decimal percentage back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Rank of a Specific Store

```essbase
/* 
   Assuming the current store's sales are $450k. 
   Compares $450k against the array of all stores. Returns ~0.82 
*/
"Percentile_Score" = @CalcMgrExcelPERCENTRANK("Total_Sales", "Total_Sales"->@CHILDREN("All_Stores"));
```

---

## Practical Examples

### Example 1: Dynamic Relative Letter Grading (A, B, C)

**Scenario**: A corporate dashboard grades 200 operational units based on their `"Efficiency_Score"`. The CEO doesn't care about the absolute score; they only care about relative performance. The Top 20% (80th percentile and above) get an "A" (stored as `1`). The middle 60% get a "B" (stored as `2`). The bottom 20% get a "C" (stored as `3`). 

```essbase
FIX("FY25", "Working", @LEVEL0("Operational_Units"))
    
    /* Ensure the unit has a valid efficiency score */
    IF("Efficiency_Score" != #MISSING)
        
        /* 
           1. Calculate exactly where this unit ranks compared to all 200 units.
           Pass the current unit's score as the 'x' parameter, and the 
           full array of all units as the baseline.
        */
        VAR vRankDecimal = @CalcMgrExcelPERCENTRANK(
            "Efficiency_Score", 
            "Efficiency_Score"->"No_Entity"->@CHILDREN("All_Operational_Units")
        );
        
        /* 
           2. Apply relative grading based on the calculated percentile.
        */
        IF(vRankDecimal >= 0.80)
            "Letter_Grade_Index" = 1; /* A */
        ELSEIF(vRankDecimal < 0.80 AND vRankDecimal >= 0.20)
            "Letter_Grade_Index" = 2; /* B */
        ELSE
            "Letter_Grade_Index" = 3; /* C */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Parameter Ordering | `@CalcMgrExcelPERCENTRANK(@CHILDREN("Sales"), "Total_Sales")` | The `x` parameter (the value you want to rank) **MUST** be the very first parameter passed to the function. If you pass the array first, the function will attempt to use the first value in the array as the `x` parameter, ruining the calculation |
| Values Out of Bounds | Calculating rank for a hypothetical target | If you are projecting a hypothetical future sales goal (`$10M`) and want to see where it would rank against *last year's* actuals, if `$10M` is higher than the absolute maximum achieved last year, `PERCENTRANK` will fail and return `#MISSING`. It cannot extrapolate percentiles beyond the bounds of the provided array |
| Small Datasets | `PERCENTRANK(A, [A, B])` | The math of `PERCENTRANK.INC` divides by `N-1`. If your array only has 1 or 2 items, the percentiles will simply be `0.00` and `1.00`. This function is meant for statistically significant datasets (e.g., 20+ items) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPERCENTILE`](../13_CalcMgr_Excel_Math_Stat/@CalcMgrExcelPERCENTILE.md) | The direct inverse function: You provide the percentile (`0.90`), and it returns the exact dollar value threshold |
| [`@CalcMgrExcelRANK`](../13_CalcMgr_Excel_Math_Stat/@CalcMgrExcelRANK.md) | Returns an absolute integer rank (e.g., "You are #4 out of 100"), rather than a percentile decimal |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelpercentrank.html)
