# @MOVSUM

## Overview

`@MOVSUM` is a **time-series aggregation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that calculates a **moving (rolling) sum** across a specified number of periods. It sums the values from the current period backward for a given number of consecutive periods, creating a rolling total that moves forward through time.

### Why Does This Function Exist—

Moving sums (rolling totals) are fundamental in financial analysis:
- Trailing twelve-month (TTM) revenue calculations
- Rolling quarterly totals for trend analysis
- Year-to-date-like calculations using a fixed window size
- Smoothing cumulative metrics over a consistent window

### When to Use It

- When you need a rolling/trailing sum across a fixed number of periods
- For TTM (trailing twelve months) or rolling quarterly calculations
- When building trend analyses that use consistent window sizes
- Use `@MOVSUM` for rolling sums; use `@MOVAVG` for rolling averages

---

## Category

**Time Series / Statistical / Aggregation**

---

## Syntax

```essbase
@MOVSUM(expression, numPeriods [, skipMissing])
```

### Formal Syntax

```
@MOVSUM(numericExpression, n [, skipMissingFlag])
```

Where:
- `numericExpression` — The value to sum over the rolling window
- `n` — Number of periods in the moving window
- `skipMissingFlag` — (Optional) Whether to skip `#MISSING` values

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric expression | ✅ Yes | The data value to sum. Typically a member like `Revenue` or a formula. |
| `numPeriods` | Integer | ✅ Yes | The number of periods in the rolling window. `n = 3` sums the current period and the 2 prior periods. Must be ≥ 1. |
| `skipMissing` | Boolean | ❌ No | If specified, controls how `#MISSING` values are handled. Default: `#MISSING` values contribute 0. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Sufficient periods exist | Sum of the last `n` periods' values |
| Fewer than `n` prior periods | Partial sum of available periods |
| All values in window are `#MISSING` | `#MISSING` or `0` depending on settings |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Rolling Window**: For each period, `@MOVSUM` looks backward `n` periods (including the current period) and sums the values.

2. **Window Slide**: As the calculation moves to the next period, the window shifts forward by one — the oldest period drops off and the new current period is added.

3. **Early Periods**: For the first few periods where there aren't `n` prior values available, `@MOVSUM` computes a partial sum using whatever periods are available.

4. **Same Level**: The moving window operates across members at the same level in the dimension (typically siblings in the time dimension).

5. **Dense Dimension**: Most efficient on the Time/Period dimension (typically dense), since all values are within the same data block.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling 3-Month Sum

```essbase
@MOVSUM(Revenue, 3)
```
Sums Revenue for the current month and the 2 prior months.

### Variant 2: Trailing 12-Month Sum

```essbase
@MOVSUM(Revenue, 12)
```
Sums Revenue for the last 12 months (TTM).

### Variant 3: With Cross-Dimensional Reference

```essbase
@MOVSUM("Actual" -> Revenue, 6)
```
Rolling 6-month sum of Actual Revenue.

---

## Practical Examples

### Example 1: Trailing Twelve-Month (TTM) Revenue

**Scenario**: Calculate rolling 12-month revenue for each product.

```essbase
FIX("Actual", @DESCENDANTS("Total_Products"))
    "TTM_Revenue" = @MOVSUM(Revenue, 12);
ENDFIX
```

**What Happens**:
- For Dec: sums Jan through Dec = annual total
- For Jan (next year): sums Feb(prev year) through Jan(current year)
- Window slides forward each month

---

### Example 2: Rolling Quarterly Total

**Scenario**: Calculate a rolling 3-month total for expense tracking.

```essbase
FIX("FY24", "Actual")
    "Rolling_Q_Expenses" = @MOVSUM("Total_Expenses", 3);
ENDFIX
```

---

### Example 3: Rolling Sum for Cash Flow

**Scenario**: Track rolling 6-month cash inflows.

```essbase
FIX("FY24", "Forecast")
    "Rolling_6M_Cash" = @MOVSUM("Cash_Inflows", 6);
ENDFIX
```

---

### Example 4: Compare Rolling Sum vs. Prior Year Rolling Sum

**Scenario**: Compare TTM revenue growth.

```essbase
FIX("Actual", @DESCENDANTS("Total_Products"))
    "TTM_Rev" = @MOVSUM(Revenue, 12);
    IF("TTM_Rev" -> "FY23" <> 0)
        "TTM_Growth" = ("TTM_Rev" - "TTM_Rev" -> "FY23") / @ABS("TTM_Rev" -> "FY23") * 100;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with `@MOVSUMX` | `@MOVSUMX` excludes `#MISSING` values from the sum. `@MOVSUM` may treat them as 0. | Use `@MOVSUMX` if you need strict missing-value exclusion |
| Window exceeds periods | Requesting 12-month rolling sum when only 6 months exist | First 11 months will have partial (shorter) rolling sums |
| Confusing with `@ACCUM` | `@ACCUM` is cumulative (no fixed window). `@MOVSUM` uses a fixed window. | Use `@ACCUM` for YTD; `@MOVSUM` for rolling windows |
| Cross-level navigation | `@MOVSUM` works within the same level/parent | Ensure all periods in the window are siblings |
| Performance on sparse dims | Rolling calculations on sparse dimensions read multiple blocks | Use on dense (Time) dimension for best performance |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MOVSUMX`](./@MOVSUMX.md) | Moving sum **excluding** missing values |
| [`@MOVAVG`](./@MOVAVG.md) | Moving **average** — sum divided by count |
| [`@MOVMAX`](./@MOVMAX.md) | Moving **maximum** across the window |
| [`@MOVMIN`](./@MOVMIN.md) | Moving **minimum** across the window |
| [`@MOVMED`](./@MOVMED.md) | Moving **median** across the window |
| [`@ACCUM`](./@ACCUM.md) | **Cumulative** sum (no fixed window — grows from start) |
| [`@SUM`](../06_Mathematical/@SUM.md) | Sum across all specified members (not rolling) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MOVSUM](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/movsum.html)
- [Oracle Essbase Technical Reference — @MOVSUM](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
