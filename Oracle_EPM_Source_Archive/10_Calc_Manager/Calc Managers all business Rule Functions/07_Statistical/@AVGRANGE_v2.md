# @AVGRANGE

## Overview

`@AVGRANGE` is a **statistical and cross-dimensional function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It calculates the average (mean) of a specified measure across a dynamic range of members from a different dimension.

### Why Does This Function Exist—

Standard `@AVG` requires you to pass the exact target intersections into it, often leading to clunky syntax like `@AVG(SKIPNONE, "Jan"->"Sales", "Feb"->"Sales")`. 
`@AVGRANGE` cleanly separates the *What* (the measure you are averaging) from the *Where* (the time periods or entities you are averaging it across). 
This makes it incredibly powerful when combined with dynamic range functions like `@CURRMBRRANGE` to create moving averages (e.g., trailing 3 months) or `@XRANGE` for cross-year averages.

### When to Use It

- To calculate Trailing/Moving Averages (e.g., a 6-month trailing average to smooth out seasonality).
- To calculate cross-year averages (e.g., Oct FY24 through Mar FY25).
- Whenever you need to average a specific Account across a dynamic or generated list of members from the Time/Period dimension.

---

## Category

**Statistical / Cross-Dimensional / Time Series**

---

## Syntax

```essbase
@AVGRANGE(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, mbrName, rangeList)
```

### Formal Syntax

```
@AVGRANGE(skipParameter, measureMember, rangeListExpression)
```

Where:
- `skipParameter` — Keyword dictating how to handle empty data (e.g., `SKIPMISSING`).
- `measureMember` — The member (usually an Account) whose data you want to average.
- `rangeListExpression` — The list of members (usually Time) to average across.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `skipParameter`| Keyword| ✅ Yes | `SKIPNONE`, `SKIPMISSING`, `SKIPZERO`, or `SKIPBOTH`. Determines how the denominator is counted. |
| `mbrName` | Member | ✅ Yes | The measure to average (e.g., `"Sales"`, `"Headcount"`). |
| `rangeList` | Member list| ✅ Yes | The list of members providing the context grid. Can be static `("Jan":"Mar")` or dynamic (`@CURRMBRRANGE(...)`). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the mathematical mean of `mbrName` evaluated across every member in `rangeList`.

---

## How It Works (Behind the Scenes)

1. **Context Separation**: Essbase takes the `measureMember` and prepares to evaluate it.
2. **Iteration**: It iterates through the `rangeListExpression`. For every member in that list, it looks up the value of `measureMember`.
3. **Aggregation**: It sums the values and counts the valid data points (based on the skip parameter).
4. **Division**: It divides the sum by the count.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Range Average

```essbase
"Q1_Avg_Sales" = @AVGRANGE(SKIPMISSING, "Sales", "Jan":"Mar");
```

### Variant 2: Trailing Moving Average (Using @CURRMBRRANGE)

```essbase
/* Averages the current month and the two prior months */
"3Mo_Avg" = @AVGRANGE(SKIPMISSING, "Sales", @CURRMBRRANGE("Period", LEV, 0, -2, 0));
```

---

## Practical Examples

### Example 1: Trailing 6-Month Moving Average (Smooth Forecasting)

**Scenario**: You want to forecast future utility expenses based on a rolling 6-month historical average to smooth out short-term spikes.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Assuming we are calculating the forecast months */
    FIX("Forecast_Months")
        
        /* Grab the Utility Expense, averaging the current month minus 6, up to current minus 1 */
        "Forecast_Utilities" = @AVGRANGE(
            SKIPNONE, 
            "Utility_Expense", 
            @CURRMBRRANGE("Period", LEV, 0, -6, -1)
        );
        
    ENDFIX
    
ENDFIX
```

---

### Example 2: Cross-Year Average (Using @XRANGE)

**Scenario**: Your fiscal year starts in July, but you need a calendar-year average of Headcount for a specific HR report (Jan through Dec across the FY boundary).

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Calculate average across the back half of FY24 and front half of FY25 */
    "CY24_Avg_Headcount" = @AVGRANGE(
        SKIPMISSING, 
        "Headcount", 
        @XRANGE("FY24"->"Jan", "FY25"->"Dec")
    );
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting the Skip Parameter | `@AVGRANGE("Sales", "Jan":"Mar")` | The skip parameter is mandatory. Always start with `SKIPNONE`, `SKIPMISSING`, etc. |
| Overcomplicating standard math | If you are just averaging children up to a parent, `@AVG(SKIPMISSING, @CHILDREN("Q1"))` is fine | Reserve `@AVGRANGE` for when you need to explicitly separate the measure from a complex range (like moving averages) |
| Using string/date accounts | You cannot average a date-formatted account or text measure | Ensure `mbrName` is a numeric measure |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@AVG`](./@AVG.md) | Standard average function where the measure and range are combined |
| [`@SUMRANGE`](../06_Mathematical/@SUMRANGE.md) | Does exactly the same thing, but Sums instead of Averages |
| [`@CURRMBRRANGE`](../05_Data_Access/@CURRMBRRANGE.md) | The most common function used to generate the `rangeList` for moving averages |
| [`@XRANGE`](../18_Range_Set_Operations/@XRANGE.md) | The best way to generate cross-year ranges for `@AVGRANGE` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @AVGRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/avgrange.html)
