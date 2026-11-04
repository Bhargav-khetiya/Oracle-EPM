# @MOVMAX

## Overview

`@MOVMAX` is a **time-series statistical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that calculates the **moving (rolling) maximum** over a specified number of consecutive time periods. For each period, it returns the highest value seen in the current period and the preceding N-1 periods.

### Why Does This Function Exist—

Rolling maximum is essential for:
- **Peak detection** — identifying the highest revenue, cost, or demand within a rolling window
- **Capacity planning** — understanding peak load over trailing periods
- **Risk analysis** — worst-case (highest expense) over rolling windows
- **Bollinger Band-style analysis** — upper bound of rolling range
- **Compliance** — checking if any period in the last N exceeded a threshold

### When to Use It

- Finding the peak monthly revenue in the last 6 months
- Tracking maximum inventory level over rolling quarters
- Calculating high-water marks for performance benchmarks
- Risk assessment — maximum drawdown or exposure

---

## Category

**Statistical / Time Series / Moving Window**

---

## Syntax

```essbase
@MOVMAX(expression, numPeriods)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric expression | ✅ Yes | The value to evaluate (e.g., an account member). |
| `numPeriods` | Integer | ✅ Yes | The size of the rolling window (number of periods including current). Must be ≥ 1. |

---

## Return Value

Returns the **maximum value** found within the rolling window of `numPeriods` ending at the current period.

| Scenario | Behavior |
|----------|----------|
| All periods have data | Maximum of the N values |
| Some periods `#MISSING` | Missing values are ignored; max of non-missing values |
| All periods `#MISSING` | `#MISSING` |
| Fewer than N periods available (start of time) | Max of available periods |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Rolling Window**: For each time period member, `@MOVMAX` looks at the current period and the N-1 preceding periods (in outline order within the time dimension).

2. **Time Dimension Awareness**: Operates along the dimension tagged as "Time" in the outline. The window slides forward as each successive period is processed.

3. **Boundary Behavior**: For the first few periods where the full window is not available:
   - Period 1 with `@MOVMAX(expr, 3)`: Returns the value of Period 1 only
   - Period 2: Returns max of Period 1 and 2
   - Period 3+: Returns max of 3 consecutive periods

4. **Missing Handling**: `#MISSING` values within the window are skipped — they don't affect the maximum.

---

## Practical Examples

### Example 1: 3-Month Peak Revenue

```essbase
FIX("Actual", "FY24", @DESCENDANTS("Total_Entity"))
    "Peak_3M_Revenue" = @MOVMAX("Revenue", 3);
ENDFIX
```

**Result**:
| Month | Revenue | @MOVMAX(Revenue, 3) |
|-------|---------|---------------------|
| Jan | 100 | 100 |
| Feb | 150 | 150 |
| Mar | 120 | 150 |
| Apr | 200 | 200 |
| May | 180 | 200 |
| Jun | 130 | 200 |
| Jul | 160 | 180 |

### Example 2: Rolling 12-Month High-Water Mark

```essbase
FIX("Actual", "FY24")
    "Rolling_12M_Peak" = @MOVMAX("Revenue", 12);
ENDFIX
```

### Example 3: Peak Demand for Capacity Planning

```essbase
FIX("Actual", "FY24", @DESCENDANTS("All_Products"))
    "Peak_6M_Demand" = @MOVMAX("Units_Sold", 6);
    /* Use peak demand for capacity allocation */
    IF(@MOVMAX("Units_Sold", 6) > "Max_Capacity")
        "Capacity_Alert" = 1;
    ENDIF
ENDFIX
```

### Example 4: Combining with @MOVMIN for Range

```essbase
FIX("Actual", "FY24")
    "Rolling_Range" = @MOVMAX("Revenue", 6) - @MOVMIN("Revenue", 6);
    /* Volatility indicator — larger range = more volatile */
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| numPeriods = 0 | Invalid — must be at least 1 | Use 1 or greater |
| Expecting cross-dimensional | `@MOVMAX` only works along the Time dimension | Use `@MAX` for non-time comparisons |
| Large window exceeds data | If window > available periods, uses what's available | Not an error, but results may be misleading for early periods |
| Confusing with @MAX | `@MAX` works across member sets; `@MOVMAX` works along time | Use `@MAX` for cross-entity, `@MOVMAX` for time-series |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MOVMIN`](@MOVMIN.md) | Moving minimum (lower bound of rolling window) |
| [`@MOVAVG`](@MOVAVG.md) | Moving average (center of rolling window) |
| [`@MOVMED`](@MOVMED.md) | Moving median |
| [`@MOVSUM`](@MOVSUM.md) | Moving sum (rolling total) |
| [`@MAX`](../06_Mathematical/@MAX.md) | Maximum across a member set (non-time) |
| [`@MAXRANGE`](../06_Mathematical/@MAXRANGE.md) | Maximum over a range specification |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MOVMAX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/movmax.html)
