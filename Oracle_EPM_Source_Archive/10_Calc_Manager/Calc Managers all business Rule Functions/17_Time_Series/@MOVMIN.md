# @MOVMIN

## Overview

`@MOVMIN` is a **native Essbase time-series array function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates a **Moving Minimum** (or rolling minimum) across a specified time series. For every member in the time range, it looks backward a defined number of periods, sweeps that isolated data window, identifies the absolute lowest numeric value, and writes that minimum value into the current block.

### Why Does This Function Exist?

In liquidity tracking, risk analysis, and contract enforcement, businesses often need to track the "lowest point" of a metric over a specific historical window. 
For example, a bank might enforce a debt covenant stating that a company's cash balance must never drop below a certain threshold on a "Rolling 3-Month" basis. To monitor this, the company needs to evaluate the trailing 3 months for every single month of the forecast and isolate the worst-case scenario (the lowest cash point).
Instead of writing complex nested `IF` statements combining `@PRIOR` functions (which are unmaintainable and break at year boundaries), `@MOVMIN` natively handles the sliding window. It automatically steps through the time dimension, creates the historical array, isolates the absolute minimum value within that specific array, and shifts forward to the next period.

### When to Use It

- **Liquidity Monitoring**: Calculating the lowest cash balance over a trailing 90-day window to trigger automated alerts for debt covenant breaches.
- **Inventory Safety**: Tracking the rolling 6-month minimum inventory level to establish a hard baseline for mandatory safety stock requirements.
- **Penalty Tracking**: Reviewing SLA (Service Level Agreement) metrics over a rolling 3-month window to find the lowest performance score and apply vendor penalties accordingly.

---

## Category

**Mathematical / Array Aggregation & Rolling / Essbase Native Functions**

---

## Syntax

```essbase
@MOVMIN(mbrName, n, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target account or metric whose minimum you want to calculate (e.g., `"Cash_Balance"`). |
| `n` | Integer | ✅ Yes | The size of the sliding window (how many periods to look backward, *including* the current period). Must be $\ge 1$. |
| `XrangeList`| Member List | ❌ No  | A custom time range over which the moving minimum is calculated (e.g., `"Jan":"Dec"`). If omitted, Essbase uses the Level-0 members of the Time dimension. **Required if crossing year/month boundaries.** |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the calculated minimum value for the sliding window and writes it to the current block.
- **Negative Values**: The function respects absolute math. If the trailing window is `[-10, 50, 100]`, the moving minimum is `-10`.
- **Missing Data Handling**: By default, `#MISSING` data inside the window is completely ignored. It does NOT evaluate to `0`. If a 3-month window contains `[100, #MISSING, 200]`, the minimum is `100`, not `0`.
- **Ramp-Up Periods**: If the engine is calculating `"Feb"`, and `n = 3` (but there is no January data), it simply calculates the minimum of whatever data it *can* find in the window.

---

## How It Works (Behind the Scenes)

1. **Window Initialization**: The C-engine reads the `n` parameter and creates an internal memory window.
2. **Iteration**: It steps through the `XrangeList` one period at a time.
3. **Data Fetch & Cleanse**: It fetches the data for the trailing `n` periods. It strips any `#MISSING` values out of the window so they don't skew the results to zero.
4. **Sweep**: It initializes a tracking variable with the highest possible number, then sweeps the window. Any value lower than the tracker replaces it.
5. **Write**: It writes the final minimum value to the current block, slides the window forward one step, and repeats.

---

## Syntax Variants & Scenarios

### Variant 1: Standard 3-Month Trailing Minimum

```essbase
/* 
   Calculates the lowest Sales figure achieved in the trailing 3 months.
*/
"Trailing_3M_Worst_Sales" = @MOVMIN("Sales", 3, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Monitoring Rolling Cash Covenants (Crossing Years)

**Scenario**: A corporate treasury department must ensure that the `"Operating_Cash"` balance never drops below $1,000,000 during any rolling 6-month window. The FP&A team creates a reporting metric called `"Rolling_6M_Low_Cash"`. Because this is a continuous metric, it MUST cross the year boundary (from FY24 into FY25) seamlessly.

```essbase
FIX(@LEVEL0("Entity"))
    
    /* 
       1. We use @XRANGE to fuse FY24 and FY25 into a single continuous time stream.
       2. We use @MOVMIN with a window of 6.
    */
    "Rolling_6M_Low_Cash" = @MOVMIN("Operating_Cash", 6, 
        @XRANGE("FY24"->"Jan", "FY25"->"Dec")
    );
    
    /* 
       3. We can then run a conditional check against this moving minimum.
    */
    IF("Rolling_6M_Low_Cash" < 1000000)
        "Covenant_Breach_Flag" = 1;
    ELSE
        "Covenant_Breach_Flag" = 0;
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Zeros vs Missing | Dropping the Floor | `@MOVMIN` ignores `#MISSING`, but it DOES NOT ignore `0`. If a cost center is shut down for a month, and you load a `0` instead of leaving the block `#MISSING`, the minimum for that 3-month window instantly drops to `0`. If `0` is a valid data point (e.g., zero units sold), this is correct. If it's just bad data handling, you must clear those zeros to `#MISSING` before running the function |
| Trapped by the Year Boundary | Not using `XrangeList` | If you write `@MOVMIN("Cash", 3, "Jan":"Dec")`, the calculation for `"Jan"` has nowhere to look backward to. It will just return Jan's data. To get a true rolling minimum that respects the end of the prior year, you MUST pass an `@XRANGE` into the third parameter |
| Assuming it Returns the Member | `@MOVMIN` returns the Number | This function returns the numeric *value* (e.g., `$10,000`). It does NOT return the *name* of the month that held the lowest value. If you need to know exactly *when* the lowest point occurred, you would need complex custom indexing logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MOVMAX`](./@MOVMAX.md) | The exact opposite. Calculates the rolling maximum value in the trailing window |
| [`@MOVMED`](./@MOVMED.md) | Calculates the rolling median, isolating the true center of the historical window |
| [`@XRANGE`](./@XRANGE.md) | The critical utility function used to stitch multiple years together to allow moving functions to cross year boundaries |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MOVMIN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/movmin.html)
