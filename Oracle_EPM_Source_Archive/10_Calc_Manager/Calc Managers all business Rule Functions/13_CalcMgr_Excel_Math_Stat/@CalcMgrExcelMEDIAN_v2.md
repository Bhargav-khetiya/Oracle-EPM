# @CalcMgrExcelMEDIAN

## Overview

`@CalcMgrExcelMEDIAN` is a **custom Calc Manager statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `MEDIAN` function directly inside an Essbase calculation script. 
It analyzes a list or array of data points and returns the **Median** value—the number perfectly in the middle of the dataset when sorted from lowest to highest.

### Why Does This Function Exist—

Standard averages (`@AVG`) are highly susceptible to outliers. If a retail chain has 4 stores that sell $1,000 a month, and 1 flagship store that sells $100,000 a month, the "Average" store sales is $20,800. This average is mathematically true, but operationally useless for setting baseline quotas for standard stores. 
The Median, however, sorts the data (`$1k, $1k, $1k, $1k, $100k`) and picks the exact middle number (`$1,000`). This perfectly filters out massive outliers and provides a much more realistic picture of standard operational performance. 
Writing a custom sorting algorithm in an Essbase calc script to dynamically find the median of a multi-dimensional array is incredibly complex. `@CalcMgrExcelMEDIAN` offloads this entirely to the Java engine, running high-speed array sorts and returning the true median instantly.

### When to Use It

- **Quota Planning**: Establishing baseline sales quotas or operational targets that are immune to massive historical outliers.
- **Salary Banding**: Analyzing employee compensation where a few executives (outliers) heavily skew the standard "average" salary.
- Whenever you need to migrate an Excel spreadsheet containing the `MEDIAN` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelMEDIAN(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelMEDIAN(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, variables, or Essbase accounts. You can also pass a range of members (like `@CHILDREN("Stores")`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first number. |
| `val2` | Numeric | ✅ Yes | The second number. |
| `[valN]` | Array/List| ❌ No  | Any subsequent numbers or ranges forming the dataset. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the true statistical median of the dataset.
- **Odd Count**: If the array has an odd number of valid data points (e.g., 5 items), it returns the exact middle number.
- **Even Count**: If the array has an even number of valid data points (e.g., 4 items), it calculates the standard average of the two middle numbers and returns that decimal.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine ingests the array of data points.
2. **Missing Handling**: It rigorously strips out `#MISSING` values so they do not count as `0` and skew the median downwards. (If a store didn't exist yet, its `#MISSING` sales are ignored).
3. **Sorting**: It sorts the remaining valid numbers in ascending order.
4. **Extraction**: It identifies the middle index. If the length is odd, it returns the value at the exact center index. If the length is even, it adds the two center indices and divides by 2.
5. **Return**: Passes the resulting median value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Median across a Time Range

```essbase
/* Analyzes Jan through Dec. Ignores #MISSING months. Returns the Median monthly sales */
"Baseline_Sales_Target" = @CalcMgrExcelMEDIAN("Actual_Sales"->@CHILDREN("YearTotal"));
```

---

## Practical Examples

### Example 1: Setting Outlier-Resistant Store Quotas

**Scenario**: You are generating FY25 sales quotas for 50 different retail stores. Last year, several stores experienced massive one-time anomalies (e.g., a store next to a stadium during the Superbowl). Using `@AVG` to set their new baseline would unfairly punish them with a massive quota. Using `MEDIAN` filters out the anomaly month completely.

```essbase
FIX("FY25", "Working", @LEVEL0("Stores"))
    
    /* 
       Calculate the Median of the 12 months from FY24.
       This acts as a safe, outlier-resistant baseline for standard performance. 
    */
    "Safe_Baseline" = @CalcMgrExcelMEDIAN("Actuals"->"FY24"->@IDESCENDANTS("YearTotal"));
    
    /* Multiply the safe baseline by a 5% growth target to set the new monthly quota */
    FIX(@IDESCENDANTS("YearTotal"))
        
        "Calculated_Quota" = "Safe_Baseline" * 1.05;
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Zero vs Missing | The database contains actual `0`s | `MEDIAN` safely ignores `#MISSING` values. However, if your data load process populated empty months with hardcoded `0`s, the Java engine will treat those as valid data points. A large block of `0`s will severely drag the Median down. Ensure empty data is truly `#MISSING` |
| Block Calculation Mode | Iterating inside a Dense block | Like most array aggregation functions, `MEDIAN` should typically be targeted at a specific summary variable or cross-dimensional member (e.g., `"Baseline_Metric" = @CalcMgrExcelMEDIAN(@CHILDREN("Time"))`). If you try to calculate it "in-line" across an expanding block without proper FIX statements, you might get erratic performance or overwrite issues |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@AVG`](../07_Statistical/@AVG.md) | Native Essbase function that calculates the standard arithmetic mean (highly susceptible to outliers) |
| [`@CalcMgrExcelMODE`](../07_Statistical/@MODE.md) | Calculates the Mode (the number that appears most frequently in a dataset) |
| [`@CalcMgrExcelLARGE`](../15_CalcMgr_Utility/@CalcMgrExcelLARGE.md) | Allows you to find specific ranks (e.g., the 2nd highest number), which provides granular control beyond just finding the middle |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelmedian.html)
