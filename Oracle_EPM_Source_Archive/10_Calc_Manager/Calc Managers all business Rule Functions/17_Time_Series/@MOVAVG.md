# @MOVAVG

## Overview

`@MOVAVG` is a **native Essbase time-series array function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates a **Moving Average** (or rolling average) across a specified time series. For every member in the specified time range, it looks backward a defined number of periods, sums those periods together, divides by the count, and writes the average into the current block.

### Why Does This Function Exist?

Standard averages (`@AVG`) provide a static view of a dataset. However, businesses operate dynamically. A "Trailing 3-Month Average" is the gold standard for smoothing out volatile monthly sales spikes and identifying the true underlying trend of a business.
To calculate a 3-month trailing average for `"Mar"`, you need `(Jan + Feb + Mar) / 3`. But for `"Apr"`, the window must shift: `(Feb + Mar + Apr) / 3`. 
If you tried to write this manually, you would need an `IF` statement for every single month, utilizing complex `@PRIOR` functions to look backward, and the logic would completely break at the beginning of the year unless you wrote custom cross-year boundary logic.
`@MOVAVG` handles all of this natively. It automatically creates the sliding window. As the engine moves from Jan to Dec, the function continuously looks backward by the specified integer (e.g., `3`), calculates the average of that window, and shifts the window forward for the next month. It even seamlessly crosses year boundaries if provided with an `XrangeList`.

### When to Use It

- **Trend Smoothing**: Flattening highly volatile monthly revenue or expense data into a 3-month or 6-month trailing line for management reporting.
- **Run-Rate Forecasting**: Generating the baseline for next year's forecast by calculating the 3-month moving average of the final quarter of the current year.
- **Inventory Replenishment**: Establishing a dynamic "Safety Stock" level based on the average daily consumption over the last 14 days.

---

## Category

**Mathematical / Array Aggregation & Rolling / Essbase Native Functions**

---

## Syntax

```essbase
@MOVAVG(mbrName, n, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target account or metric you want to average (e.g., `"Gross_Sales"`). |
| `n` | Integer | ✅ Yes | The size of the moving window (how many periods to look backward, *including* the current period). Must be $\ge 1$. |
| `XrangeList`| Member List | ❌ No  | A custom time range over which the moving average is calculated (e.g., `"Jan":"Dec"`). If omitted, Essbase uses the Level-0 members of the Time dimension. **Crucially, providing an `XrangeList` is required if you want the average to cross year boundaries seamlessly.** |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the calculated average for the sliding window and writes it to the current block being evaluated.
- **Ramp-Up Periods**: If `n = 3`, and the engine is calculating `"Jan"`, it tries to look back to Nov/Dec. If those months don't exist in the provided range (or there is no data), Essbase averages whatever it *can* find. For Jan, it will just use Jan's value. For Feb, it will average Jan and Feb. For March, the window is fully populated.
- **Missing Data Handling**: By default, `#MISSING` data inside the window is completely ignored. It does NOT evaluate to `0`. If a 3-month window contains `[100, #MISSING, 200]`, the average is `150` (300 / 2), not `100` (300 / 3).

---

## How It Works (Behind the Scenes)

1. **Window Initialization**: The C-engine reads the `n` parameter and creates an internal tracking window in memory (e.g., 3 slots).
2. **Iteration**: It begins stepping through the `XrangeList` (or the Time dimension) one member at a time.
3. **Data Fetch**: For the current member, it attempts to fetch the current data point and the `n-1` previous data points.
4. **Missing Exclusion**: It strips any `#MISSING` blocks from the current window.
5. **Math Execution**: It sums the remaining valid data points and divides by the count of valid data points.
6. **Write**: It writes the result to the current block, slides the window forward one step, and repeats.

---

## Syntax Variants & Scenarios

### Variant 1: Standard 3-Month Trailing Average

```essbase
/* 
   Calculates a 3-month trailing average of Sales across the year.
*/
"Trailing_3M_Sales" = @MOVAVG("Sales", 3, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Crossing Year Boundaries (Rolling 6-Month)

**Scenario**: The FP&A team requires a Rolling 6-Month Average of `"Operating_Expenses"` to smooth out erratic quarterly vendor payments. If the calculation is running for `"Feb"` of `"FY25"`, it MUST look backward and include `"Sep"`, `"Oct"`, `"Nov"`, `"Dec"` of `"FY24"`. Standard functions trap you inside the current year. The administrator uses `@MOVAVG` combined with `@XRANGE` to create a continuous, multi-year time stream.

```essbase
FIX(@LEVEL0("Entity"))
    
    /* 
       1. We use @XRANGE to fuse FY24 and FY25 into a single continuous time stream.
       2. We tell @MOVAVG to use a window of 6.
       3. We place this calculation inside the account block.
    */
    "Rolling_6M_OpEx" = @MOVAVG("Operating_Expenses", 6, 
        @XRANGE("FY24"->"Jan", "FY25"->"Dec")
    );
    
    /* 
       Results for FY25 -> Feb:
       The engine looks at the XRANGE. It steps backward 6 periods from FY25-Feb.
       It perfectly grabs FY24-Sep through FY25-Feb, averages them, 
       and stores the result.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Zeros vs True `#MISSING` | Inflated Averages | As stated, `@MOVAVG` explicitly drops `#MISSING` values from the denominator. If a store has `[$10,000, #MISSING, $10,000]` because they didn't submit their data, the average is `$10,000`. If you actually want that missing month to drag the average down (treating missing data as a penalty of $0), you MUST use an `IF` statement to convert the `#MISSING` blocks to real `0` blocks *before* running the `@MOVAVG` |
| Trapped by the Year Boundary | Not using `XrangeList` | If you write `@MOVAVG("Sales", 3, "Jan":"Dec")`, the calculation for `"Jan"` has nowhere to look backward to (because the range explicitly stops at Jan). It will just return Jan's data. If you want a true rolling average that respects prior years, you MUST pass an `@XRANGE` into the third parameter |
| Placing it outside a `FIX` | Massive Calculation Overhead | `@MOVAVG` is an incredibly heavy array function. If you put `"Trailing_Avg" = @MOVAVG("Sales", 3);` without an `XrangeList` and without fixing on specific entities, Essbase will attempt to calculate the rolling average for every single Entity, Product, and Scenario in the entire database. ALWAYS constrain moving averages inside a strict `FIX` statement |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MOVMED`](./@MOVMED.md) | The Median equivalent. Calculates the rolling median rather than the rolling arithmetic mean, neutralizing massive outlier spikes in the window |
| [`@MOVSUM`](./@MOVSUM.md) | Calculates the rolling total (sum) of the window rather than the average (e.g., Trailing Twelve Months / TTM Revenue) |
| [`@XRANGE`](./@XRANGE.md) | The critical utility function used to stitch multiple years together to allow moving functions to cross year boundaries |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MOVAVG](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/movavg.html)
