# @PRIORS

## Overview

`@PRIORS` is a **native Essbase time-series array function** in Oracle EPM Cloud (PBCS/EPBCS). Unlike `@PRIOR` (which returns a single data value from a single historical period), `@PRIORS` generates a **dynamic array** of multiple historical periods based on a defined look-back integer. It is specifically designed to feed historical ranges into other array functions (like `@SUM` or `@MAX`) when calculating moving windows.

### Why Does This Function Exist?

When building moving averages or trailing totals, you typically use `@MOVAVG` or `@MOVSUM`. However, those functions inherently *include* the current period in their window. 
What if you need to calculate a trailing sum of the *past* 3 months, explicitly EXCLUDING the current month? 
If you are calculating `"Apr"`, and you need the sum of `"Jan", "Feb", "Mar"`, you cannot use `@MOVSUM(3)` because that gives you `(Feb + Mar + Apr)`. You cannot use standard sibling functions because they don't cross year boundaries.
`@PRIORS` solves this natively. You pass it the number of periods to look backward (e.g., `3`). It steps back from the current period, collects exactly 3 historical periods into a contiguous array, and hands that array off to `@SUM` or `@AVG`. It explicitly excludes the current period, providing perfect, offset historical arrays.

### When to Use It

- **Offset Moving Averages**: Calculating a "Trailing 6-Month Average" that explicitly excludes the current month's highly volatile preliminary data.
- **Prior-Period Thresholding**: Finding the highest peak value (`@MAX`) over the last 90 days before today to set an operational ceiling for today's forecast.
- **Accrual Reversals**: Creating a dynamic array of all prior periods in the year to sweep and reverse any lingering un-booked accruals.

---

## Category

**Mathematical / Array Processing & Shifting / Essbase Native Functions**

---

## Syntax

```essbase
@PRIORS(n, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `n` | Integer | ✅ Yes | The size of the historical array (how many periods to look backward). Must be $\ge 1$. |
| `XrangeList`| Member List | ❌ No  | A custom time range over which the array is generated. If omitted, Essbase uses the Level-0 Time members. **Required if the historical array must cross year boundaries.** |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of the structural time periods that precede the current calculating member.
- **Exclusion**: The current calculating member is NEVER included in this array.
- **Ramp-Up Periods**: If `n = 3`, and the engine is calculating `"Feb"`, there is only one prior month (`"Jan"`). The function will simply return `["Jan"]`. It dynamically shrinks if it hits the beginning of the range.
- **Array Passthrough**: Because it returns an array of members, it does NOT return data. It must be wrapped in a mathematical function (like `@SUM(@PRIORS(3))`) to actually retrieve the data.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The C-engine hits `@PRIORS(3)` while calculating a specific block (e.g., `"May"`).
2. **Range Tracking**: It looks at the `XrangeList` (e.g., `"Jan":"Dec"`).
3. **Step Backward**: It steps back from `"May"`. It grabs `"Apr"` (1), `"Mar"` (2), and `"Feb"` (3).
4. **Assembly**: It bundles those three members into an array object.
5. **Handoff**: It hands that array object to the parent function (e.g., `@SUM`), which then queries the data for those three blocks and returns the total.

---

## Syntax Variants & Scenarios

### Variant 1: Pure Historical Sum

```essbase
/* 
   If calculating "Apr", this resolves to @SUM("Jan", "Feb", "Mar").
*/
"Historical_3M_Total" = @SUM(SKIPMISSING, @PRIORS(3, "Jan":"Dec"));
```

---

## Practical Examples

### Example 1: Offset Moving Average (Crossing Years)

**Scenario**: The FP&A team uses a rolling 4-month average to predict future costs. However, the current active forecast month is always incomplete (bills are still arriving). Therefore, the 4-month window MUST look at the 4 months *prior* to the current month, and it must cross the fiscal year boundary seamlessly.

```essbase
FIX(@LEVEL0("Entity"))
    
    /* 
       1. We use @XRANGE to fuse FY24 and FY25 into a single continuous time stream.
       2. We use @PRIORS(4) to generate an array of the 4 months PRECEDING the current block.
       3. We wrap the array in @AVG to calculate the mathematical mean.
       4. We use SKIPMISSING so empty months don't destroy the average.
    */
    "Offset_4M_Average" = @AVG(SKIPMISSING, 
        @PRIORS(4, @XRANGE("FY24"->"Jan", "FY25"->"Dec"))
    );
    
    /* 
       Results for FY25 -> Feb:
       @PRIORS steps back 4 months: FY25-Jan, FY24-Dec, FY24-Nov, FY24-Oct.
       @AVG receives that exact array.
       It sums them and divides by 4.
       The result is written to FY25-Feb.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it like `@PRIOR` | Expecting Data | The standard `@PRIOR` function returns a numeric data value (e.g., `$500`). `@PRIORS` (with an S) returns an ARRAY of dimension members (e.g., `["Jan", "Feb"]`). If you write `"Sales" = @PRIORS(3)`, the script will crash because you cannot assign an array of members to a single data block. You MUST wrap `@PRIORS` in an aggregation function like `@SUM` or `@AVG` |
| Trapped by the Year Boundary | Not using `XrangeList` | If you write `@SUM(@PRIORS(3, "Jan":"Dec"))`, the calculation for `"Jan"` has no prior months in the range. It returns an empty array, and the `@SUM` returns `#MISSING`. You MUST use `@XRANGE` to stitch years together if you want historical arrays in Q1 |
| Confusing with `@MOVAVG` | Over-complicating | If your logic dictates that the moving average SHOULD include the current month, do not use `@AVG(@PRIORS(3)) + Current_Month`. That is incredibly inefficient. Just use the standard `@MOVAVG("Sales", 4)` function, which inherently handles the current month plus the history |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PRIOR`](./@PRIOR.md) | Returns a single data value from a single historical period, rather than an array of periods |
| [`@NEXTS`](./@NEXTS.md) | The forward-looking equivalent. Generates an array of periods that come AFTER the current calculating member |
| [`@XRANGE`](../18_Range_Set_Operations/@XRANGE.md) | The critical utility function used to stitch multiple years together for the `XrangeList` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — PRIORS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/priors.html)
