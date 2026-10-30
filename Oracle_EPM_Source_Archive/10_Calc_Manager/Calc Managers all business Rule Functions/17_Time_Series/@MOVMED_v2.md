# @MOVMED

## Overview

`@MOVMED` is a **native Essbase time-series array function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates a **Moving Median** (or rolling median) across a specified time series. For every member in the time range, it looks backward a defined number of periods, isolates that window of data, sorts it, extracts the exact middle value (the 50th percentile), and writes that median into the current block.

### Why Does This Function Exist?

Standard moving averages (`@MOVAVG`) are excellent for smoothing trendlines, but they are highly susceptible to massive outlier spikes. 
Imagine a warehouse looking at a 3-month trailing window to set staffing levels. The units shipped were: `[Jan: 100, Feb: 100, Mar: 10,000]`. March had a massive, one-off clearance event. If you use a moving average, the resulting target for April is `3,400`. The warehouse will massively over-staff for April based on a single anomaly.
`@MOVMED` solves this by relying on central tendency rather than arithmetic means. It takes the window `[100, 100, 10,000]`, sorts it, and picks the middle value. The Moving Median is `100`. The warehouse staffs appropriately. This allows administrators to build highly resilient rolling forecasts that automatically ignore data spikes and data troughs without requiring complex error-handling logic.

### When to Use It

- **Outlier-Resilient Forecasting**: Generating a baseline forecast for inventory or sales that inherently ignores one-off marketing spikes or sudden supply chain shortages in the trailing data.
- **Pricing Smoothing**: Tracking the rolling 6-month median cost of a highly volatile raw material (like lumber or oil) to establish a stable internal transfer price.
- **Capacity Planning**: Establishing a baseline server load or call-center volume using a trailing 7-day median to prevent over-reacting to a single day of system downtime.

---

## Category

**Mathematical / Array Aggregation & Rolling / Essbase Native Functions**

---

## Syntax

```essbase
@MOVMED(mbrName, n, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target account or metric whose median you want to calculate (e.g., `"Daily_Volume"`). |
| `n` | Integer | ✅ Yes | The size of the sliding window (how many periods to look backward, *including* the current period). Must be $\ge 1$. |
| `XrangeList`| Member List | ❌ No  | A custom time range over which the moving median is calculated (e.g., `"Day1":"Day30"`). If omitted, Essbase uses the Level-0 members of the Time dimension. **Required if crossing year/month boundaries.** |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the calculated median for the sliding window and writes it to the current block.
- **Odd Windows**: If `n = 3`, it returns the 2nd value of the sorted window.
- **Even Windows**: If `n = 4`, it averages the 2nd and 3rd values of the sorted window and returns that result.
- **Ramp-Up Periods**: If the engine is calculating `"Feb"`, and `n = 3` (but there is no January data), it simply calculates the median of whatever data it *can* find in the window. 
- **Missing Data**: `#MISSING` blocks are completely excluded from the sorting and percentile calculations.

---

## How It Works (Behind the Scenes)

1. **Window Initialization**: The C-engine reads the `n` parameter and creates an internal memory window.
2. **Iteration**: It steps through the `XrangeList` one period at a time.
3. **Data Fetch & Cleanse**: It fetches the data for the trailing `n` periods. It strips any `#MISSING` values out of the window.
4. **Sort**: It runs an internal quick-sort on the remaining valid numerical values, ordering them from lowest to highest.
5. **Extract**: It isolates the median value from the sorted array.
6. **Write**: It writes the median to the current block, slides the window forward one step, and repeats.

---

## Syntax Variants & Scenarios

### Variant 1: Standard 3-Month Trailing Median

```essbase
/* 
   Calculates a 3-month trailing median of Sales to ignore monthly spikes.
*/
"Trailing_3M_Median" = @MOVMED("Sales", 3, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Stable Material Pricing (Crossing Years)

**Scenario**: A manufacturing company must establish a `"Budget_Price"` for raw steel every month. The price of steel fluctuates wildly. If they use a trailing average, a single month of hyper-inflation ruins the budget. They use a Rolling 5-Month Median to establish the budget. Because the budget runs continuously, the logic MUST cross the year boundary (using `@XRANGE`).

```essbase
FIX(@LEVEL0("Raw_Materials"))
    
    /* 
       1. We use @XRANGE to stitch FY24 and FY25 together so the 5-month 
       window can look backwards seamlessly.
       2. We use @MOVMED with a window of 5.
    */
    "Budget_Price" = @MOVMED("Actual_Price", 5, 
        @XRANGE("FY24"->"Jan", "FY25"->"Dec")
    );
    
    /* 
       Results for FY25 -> Mar:
       The engine looks at: Nov, Dec, Jan, Feb, Mar.
       Actual Prices: [50, 52, 180 (Spike!), 49, 51].
       Sorted: [49, 50, 51, 52, 180].
       The Median is 51. The 180 spike is safely ignored.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Zeros vs Missing | Sorting Errors | `@MOVMED` ignores `#MISSING`, but it DOES NOT ignore `0`. `0` is a valid number. If a store is closed for a month, and you load a `0` instead of clearing the block to `#MISSING`, that `0` will be sorted into the array. If the window has three `0`s, the median becomes `0`. You must ensure your data is properly cleansed (clearing `0` to `#MISSING`) before running moving medians |
| Performance Strain | Sorting Overhead | `@MOVAVG` is very fast because it just adds numbers and divides. `@MOVMED` requires the C-engine to perform a mathematical *sort* of the array for *every single block* in the time series. If you run a Moving Median on 1,000,000 products, the sorting overhead will cause the calculation to take significantly longer than an average. Use it only when outlier resilience is strictly required |
| Trapped by the Boundary | Not using `XrangeList` | Just like `@MOVAVG`, if you omit the `XrangeList` or use a standard `"Jan":"Dec"` range, the calculation for January has nowhere to look backward to. You MUST use `@XRANGE` to create a continuous multi-year time stream if you want accurate Q1 medians |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MOVAVG`](./@MOVAVG.md) | Calculates the moving arithmetic mean. Faster, but highly susceptible to outliers |
| [`@MOVMIN`](./@MOVMIN.md) | Calculates the rolling minimum value in the trailing window |
| [`@XRANGE`](../18_Range_Set_Operations/@XRANGE.md) | The critical utility function used to stitch multiple years together to allow moving functions to cross year boundaries |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MOVMED](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/movmed.html)
