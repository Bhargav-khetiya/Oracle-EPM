# @CalcMgrExcelLARGE

## Overview

`@CalcMgrExcelLARGE` is a **custom Calc Manager statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `LARGE` function directly inside an Essbase calculation script. 
It analyzes a list or array of data points and returns the **k-th largest value**. For example, it can find the 1st largest (the maximum), the 2nd largest, or the 3rd largest number in a dataset.

### Why Does This Function Exist—

While Essbase has native functions like `@MAX` (to find the absolute largest number), it has absolutely no native way to find the *second* largest or *third* largest number in a range. 
In sales forecasting and operations, you frequently need to identify the "Top 3" performing regions, or the "Top 5" highest-selling products, to calculate specific bonus payouts or allocate specialized marketing budgets. 
Attempting to find the second largest number manually in Essbase requires complex sorting algorithms, temporary variable arrays, and massive `IF` loops. `@CalcMgrExcelLARGE` handles this instantly. It ingests an array of data, automatically sorts it descending in Java memory, and pulls the exact `k-th` value you requested.

### When to Use It

- **Sales Commissions**: Identifying the Top 3 sales reps in a territory to trigger tier-based bonus calculations.
- **Outlier Smoothing**: Finding the 2nd or 3rd largest expense in a year to verify if the absolute maximum was an anomaly or part of a trend.
- Whenever you need to migrate an Excel spreadsheet containing the `LARGE` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelLARGE(k, val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelLARGE(k, numericList)
```

Where:
- `k` — The position (from the top) to return. `1` = Maximum, `2` = Second largest, etc.
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("Products")`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `k` | Numeric | ✅ Yes | The rank parameter (e.g., `2` for the second largest). **Must be passed as the VERY FIRST parameter.** |
| `val1, val2...` | Array/List | ✅ Yes | The array of data to sort and evaluate. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the exact value of the `k-th` largest number in the array.
- **Duplicate Handling**: If the array is `[100, 100, 90, 80]`, the 1st largest is `100`. The 2nd largest is *also* `100`. The 3rd largest is `90`. The function correctly preserves duplicate values during its internal sort.
- If `k` is greater than the total number of valid data points in the array, the function returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine isolates the `k` parameter and ingests the remaining `numericList`.
2. **Missing Handling**: It drops any `#MISSING` values from the list.
3. **Sorting**: It runs an optimized array sort in descending order (highest to lowest).
4. **Extraction**: It accesses the array index corresponding to `k-1` (because Java arrays are zero-indexed) and returns that specific value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Second Largest Month of Sales

```essbase
/* Analyzes Jan through Dec. Returns the 2nd highest sales month */
"Runner_Up_Sales" = @CalcMgrExcelLARGE(2, "Sales"->@CHILDREN("YearTotal"));
```

---

## Practical Examples

### Example 1: Calculating a "Top 3" Commission Bonus

**Scenario**: A company pays a flat commission to all salespeople. However, they also pay a massive cash bonus pool to the absolute Top 3 performers in a region. The #1 rep gets $50k, the #2 rep gets $25k, and the #3 rep gets $10k. You must identify the specific sales threshold for those top 3 positions to trigger the bonus logic.

```essbase
FIX("FY25", "Working", @LEVEL0("Sales_Reps"))
    
    /* 
       Step 1: Calculate the top 3 thresholds for the current region.
       These are calculated at the Region level and pushed down to the reps.
    */
    "Rank1_Threshold" = @CalcMgrExcelLARGE(1, "Total_Sales"->@CHILDREN("Current_Region"));
    "Rank2_Threshold" = @CalcMgrExcelLARGE(2, "Total_Sales"->@CHILDREN("Current_Region"));
    "Rank3_Threshold" = @CalcMgrExcelLARGE(3, "Total_Sales"->@CHILDREN("Current_Region"));
    
    /* Step 2: Evaluate the current Rep against those thresholds */
    IF("Total_Sales" == "Rank1_Threshold")
        "Bonus_Payout" = 50000;
    ELSEIF("Total_Sales" == "Rank2_Threshold")
        "Bonus_Payout" = 25000;
    ELSEIF("Total_Sales" == "Rank3_Threshold")
        "Bonus_Payout" = 10000;
    ENDIF
    
ENDFIX
```

---

### Example 2: Outlier-Adjusted Baseline

**Scenario**: You are calculating a baseline forecast for next year's travel expenses. However, you know that the absolute highest month of travel this year was an anomaly (a massive global conference). To be safe, you want to base your monthly average on the *second* highest month, to act as a conservative ceiling.

```essbase
FIX("FY25", "Working", "Travel_Expense")
    
    /* Find the 2nd highest month of actuals from last year */
    VAR vConservativeCeiling = @CalcMgrExcelLARGE(2, "Actuals"->"FY24"->@IDESCENDANTS("YearTotal"));
    
    /* Ensure no forecasted month exceeds this conservative ceiling */
    FIX(@IDESCENDANTS("YearTotal"))
        IF("Forecast" > vConservativeCeiling)
            "Forecast" = vConservativeCeiling;
        ENDIF
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Parameter Ordering | `@CalcMgrExcelLARGE(@CHILDREN("Q1"), 2)` | The `k` parameter (the rank you want to find) **MUST** be the very first parameter passed to the function. If you pass the array first, the function will attempt to use the first value in the array as the `k` parameter, completely destroying the calculation |
| K Exceeds Array Size | Asking for `k=5` in a 4-item array | If you ask for the 5th largest number in an array that only contains 4 valid numbers (or if there were 5 members, but one was `#MISSING`), the function will fail and return `#MISSING`. Always ensure `k` is safely within the bounds of your dataset |
| Expecting Member Names | Wanting to know *WHO* was #2 | `LARGE` returns the numeric *value* (e.g., `$500,000`). It does not return the member name (e.g., `"John_Doe"`). If you need to know *who* achieved the 2nd largest value, you must use `LARGE` to find the value, and then write an `IF` statement to check which member matches that value |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelSMALL`](./@CalcMgrExcelSMALL.md) | The direct inverse function: Returns the k-th *smallest* value in a dataset (e.g., finding the 2nd lowest month) |
| [`@MAX`](./@MAX.md) | Native Essbase function that returns the absolute maximum (equivalent to `LARGE(1, ...)`) |
| [`@CalcMgrExcelRANK`](./@CalcMgrExcelRANK.md) | Given a specific number, tells you what rank it holds within an array |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excellarge.html)
