# @CalcMgrExcelPERCENTILE

## Overview

`@CalcMgrExcelPERCENTILE` is a **custom Calc Manager statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `PERCENTILE` (specifically `PERCENTILE.INC`) function directly inside an Essbase calculation script. 
It analyzes an array of data and returns the specific numerical **value** that corresponds to a target percentile (e.g., "What was the exact dollar amount of sales that separates the bottom 90% of stores from the top 10%—).

### Why Does This Function Exist—

Averages and medians are useful for finding the "middle" of a dataset, but in performance banding, executives often want to measure against the extremes. For example, an HR department might want to ensure that all salaries are above the 25th percentile of the market data. 
To calculate a percentile manually in an Essbase calc script, you would have to sort the entire array of data in memory, calculate the exact interpolative index (`k * (N-1) + 1`), and then write complex fraction-based math to blend the two adjacent numbers if the index doesn't land perfectly on a whole number. 
`@CalcMgrExcelPERCENTILE` offloads this complex array-sorting and interpolation math to the Java engine. It instantly returns the precise interpolated threshold value, ensuring perfect parity with legacy HR and FP&A Excel spreadsheets.

### When to Use It

- **Performance Banding**: Calculating the exact sales threshold required for a store to be considered in the "Top 10%" (the 90th percentile).
- **Salary Benchmarking**: Determining the 25th, 50th, and 75th percentiles of market salary data to establish corporate pay bands.
- Whenever you need to migrate an Excel spreadsheet containing the `PERCENTILE` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelPERCENTILE(k, val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelPERCENTILE(k, numericList)
```

Where:
- `k` — The target percentile value, expressed as a decimal between `0` and `1` (e.g., `0.90` for the 90th percentile).
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("Stores")`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `k` | Numeric | ✅ Yes | The target percentile decimal. **Must be passed as the VERY FIRST parameter.** |
| `val1, val2...` | Array/List | ✅ Yes | The array of data to sort and evaluate. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the precise numerical value corresponding to the `k-th` percentile.
- If the exact percentile falls *between* two data points in the array, the function automatically interpolates the value.
- E.g., If the array is `[10, 20]` and you ask for the 50th percentile (`0.50`), it returns `15`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine isolates the `k` parameter and validates that it is strictly between `0` and `1`.
2. **Missing Handling**: It drops any `#MISSING` values from the remaining array.
3. **Sorting**: It sorts the valid numbers in ascending order.
4. **Interpolation Math**: It calculates the exact array index position using the formula `Index = k * (N - 1)`. If the index is a decimal (e.g., `2.3`), it grabs the values at Index 2 and Index 3, and blends them based on the `0.3` remainder.
5. **Return**: Passes the interpolated threshold value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the 90th Percentile Threshold

```essbase
/* Analyzes all stores. Returns the sales dollar amount representing the 90th percentile */
"Top_Tier_Threshold" = @CalcMgrExcelPERCENTILE(0.90, "Total_Sales"->@CHILDREN("All_Stores"));
```

---

## Practical Examples

### Example 1: Dynamic Top-Tier Bonus Payouts

**Scenario**: A company has 100 sales reps. They do not have fixed quotas. Instead, the bonus pool is distributed dynamically. Any rep who finishes the year in the Top 10% (the 90th percentile) gets a $50,000 bonus. Any rep between the 75th and 90th percentile gets $20,000. The script dynamically calculates these dollar thresholds, and then evaluates every rep against them.

```essbase
FIX("FY25", "Working", @LEVEL0("Sales_Reps"))
    
    /* 
       Step 1: Calculate the exact dollar thresholds.
       We run this at the parent level, evaluating all children.
    */
    "Threshold_90th" = @CalcMgrExcelPERCENTILE(0.90, "Total_Sales"->@CHILDREN("Total_Reps"));
    "Threshold_75th" = @CalcMgrExcelPERCENTILE(0.75, "Total_Sales"->@CHILDREN("Total_Reps"));
    
    /* Step 2: Evaluate the current Rep against those calculated dollar thresholds */
    IF("Total_Sales" >= "Threshold_90th")
        "Bonus_Payout" = 50000;
    ELSEIF("Total_Sales" >= "Threshold_75th")
        "Bonus_Payout" = 20000;
    ELSE
        "Bonus_Payout" = 0;
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Parameter Ordering | `@CalcMgrExcelPERCENTILE(@CHILDREN("Sales"), 0.90)` | The `k` parameter (the percentile target) **MUST** be the very first parameter passed to the function. If you pass the array first, the function will attempt to use the first value in the array as the `k` parameter, which will likely crash the function because it expects a decimal `< 1` |
| Using Integers | Passing `90` instead of `0.90` | The `k` parameter strictly expects a decimal. If you pass `90`, the Java engine recognizes it as being `> 1` and instantly returns `#MISSING`. You must pass `0.90` |
| Zero vs Missing | The database contains actual `0`s | `PERCENTILE` safely ignores `#MISSING` values. However, if your data load process populated empty stores with hardcoded `0`s, those `0`s will be included in the sort. A large block of `0`s will severely drag all percentiles downward, ruining your thresholds. Ensure empty data is truly `#MISSING` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPERCENTRANK`](../15_CalcMgr_Utility/@CalcMgrExcelPERCENTRANK.md) | The direct inverse function: You provide a specific dollar amount (e.g., `$500,000`), and it tells you what percentile rank it holds within the array |
| [`@CalcMgrExcelMEDIAN`](./@CalcMgrExcelMEDIAN.md) | Calculates the median, which is mathematically identical to `@CalcMgrExcelPERCENTILE(0.50, ...)` |
| [`@CalcMgrExcelLARGE`](../15_CalcMgr_Utility/@CalcMgrExcelLARGE.md) | Returns a specific absolute rank (e.g., the 3rd highest number), rather than a percentile interpolation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelpercentile.html)
