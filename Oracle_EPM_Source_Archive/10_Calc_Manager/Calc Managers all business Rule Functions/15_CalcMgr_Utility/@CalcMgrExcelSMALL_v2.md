# @CalcMgrExcelSMALL

## Overview

`@CalcMgrExcelSMALL` is a **custom Calc Manager statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `SMALL` function directly inside an Essbase calculation script. 
It analyzes a list or array of data points and returns the **k-th smallest value**. For example, it can find the 1st smallest (the absolute minimum), the 2nd smallest, or the 3rd smallest number in a dataset.

### Why Does This Function Exist—

While Essbase has native functions like `@MIN` (to find the absolute smallest number), it has absolutely no native way to find the *second* smallest or *third* smallest number in a cross-dimensional range. 
In operations and supply chain modeling, you frequently need to identify the "Bottom 3" performing vendors based on defect rates, or the 2nd lowest sales month of the year to establish a conservative baseline. 
Attempting to find the second smallest number manually in Essbase requires complex sorting algorithms, temporary variable arrays, and massive `IF` loops. `@CalcMgrExcelSMALL` handles this instantly. It ingests an array of data, automatically sorts it ascending in Java memory, and pulls the exact `k-th` value you requested.

### When to Use It

- **Vendor Scorecards**: Identifying the top 3 cheapest suppliers for a specific raw material to prioritize procurement contracts.
- **Outlier Smoothing**: Finding the 2nd or 3rd smallest sales volume in a year to verify if the absolute minimum was an anomaly (like a hurricane closing stores) or a legitimate trend.
- Whenever you need to migrate an Excel spreadsheet containing the `SMALL` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelSMALL(k, val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelSMALL(k, numericList)
```

Where:
- `k` — The position (from the bottom) to return. `1` = Minimum, `2` = Second smallest, etc.
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("Vendors")`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `k` | Numeric | ✅ Yes | The rank parameter (e.g., `2` for the second smallest). **Must be passed as the VERY FIRST parameter.** |
| `val1, val2...` | Array/List | ✅ Yes | The array of data to sort and evaluate. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the exact value of the `k-th` smallest number in the array.
- **Duplicate Handling**: If the array is `[10, 10, 20, 30]`, the 1st smallest is `10`. The 2nd smallest is *also* `10`. The 3rd smallest is `20`. The function correctly preserves duplicate values during its internal sort.
- If `k` is greater than the total number of valid data points in the array, the function returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine isolates the `k` parameter and ingests the remaining `numericList`.
2. **Missing Handling**: It drops any `#MISSING` values from the list.
3. **Sorting**: It runs an optimized array sort in ascending order (lowest to highest).
4. **Extraction**: It accesses the array index corresponding to `k-1` (because Java arrays are zero-indexed) and returns that specific value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Second Smallest Defect Rate

```essbase
/* Analyzes all factories. Returns the 2nd lowest defect rate percentage */
"Runner_Up_Quality" = @CalcMgrExcelSMALL(2, "Defect_Rate"->@CHILDREN("All_Factories"));
```

---

## Practical Examples

### Example 1: Prioritizing the Top 3 Cheapest Suppliers

**Scenario**: A manufacturing plant sources copper from 20 different global suppliers. Prices fluctuate monthly. The procurement system must automatically identify the exact price points of the 3 cheapest suppliers so they can allocate 80% of their purchase orders to those specific price tiers.

```essbase
FIX("FY25", "Working", @LEVEL0("Raw_Materials"))
    
    /* 
       Step 1: Calculate the top 3 cheapest price thresholds.
       These are calculated globally across all suppliers.
    */
    "Rank1_Cheapest_Price" = @CalcMgrExcelSMALL(1, "Price_Per_Ton"->@CHILDREN("All_Suppliers"));
    "Rank2_Cheapest_Price" = @CalcMgrExcelSMALL(2, "Price_Per_Ton"->@CHILDREN("All_Suppliers"));
    "Rank3_Cheapest_Price" = @CalcMgrExcelSMALL(3, "Price_Per_Ton"->@CHILDREN("All_Suppliers"));
    
    /* Step 2: Evaluate each specific supplier against those thresholds */
    IF("Price_Per_Ton" == "Rank1_Cheapest_Price")
        "PO_Allocation_Pct" = 0.50; /* Allocate 50% volume to the cheapest */
    ELSEIF("Price_Per_Ton" == "Rank2_Cheapest_Price")
        "PO_Allocation_Pct" = 0.20; /* Allocate 20% to #2 */
    ELSEIF("Price_Per_Ton" == "Rank3_Cheapest_Price")
        "PO_Allocation_Pct" = 0.10; /* Allocate 10% to #3 */
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Parameter Ordering | `@CalcMgrExcelSMALL(@CHILDREN("Q1"), 2)` | The `k` parameter (the rank you want to find) **MUST** be the very first parameter passed to the function. If you pass the array first, the function will attempt to use the first value in the array as the `k` parameter, completely destroying the calculation |
| K Exceeds Array Size | Asking for `k=5` in a 4-item array | If you ask for the 5th smallest number in an array that only contains 4 valid numbers (or if there were 5 members, but one was `#MISSING`), the function will fail and return `#MISSING`. Always ensure `k` is safely within the bounds of your dataset |
| Expecting Member Names | Wanting to know *WHO* was cheapest | `SMALL` returns the numeric *value* (e.g., `$4.50`). It does not return the member name (e.g., `"Vendor_XYZ"`). If you need to know *who* achieved the smallest value, you must use `SMALL` to find the value, and then write an `IF` statement to check which vendor matches that exact value |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelLARGE`](./@CalcMgrExcelLARGE.md) | The direct inverse function: Returns the k-th *largest* value in a dataset (e.g., finding the 2nd highest month) |
| [`@MIN`](../06_Mathematical/@MIN.md) | Native Essbase function that returns the absolute minimum (equivalent to `SMALL(1, ...)` ) |
| [`@CalcMgrExcelRANK`](../13_CalcMgr_Excel_Math_Stat/@CalcMgrExcelRANK.md) | Given a specific number, tells you what integer rank it holds within an array |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelsmall.html)
