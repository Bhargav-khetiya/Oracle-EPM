# @SHIFT

## Overview

`@SHIFT` is a **time series function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **shifts data** across time periods by a specified offset — both **forward and backward**. Unlike `@PRIOR` which only looks backward, `@SHIFT` can navigate in both directions, making it more flexible for time-based calculations.

### Why Does This Function Exist—

Business calculations often need to reference values at different time offsets:
- **Lead indicators**: Looking at next month's committed pipeline
- **Lag indicators**: Looking at previous period actuals
- **Time-shifted comparisons**: Comparing offset periods for seasonality analysis
- **Flexible forecasting**: Seeding future periods from historical patterns
- **Shifted baselines**: Applying growth with time-shifted starting points

### When to Use It

- When you need to reference future periods (positive offset)
- When you need to reference past periods (negative offset)
- When the direction of the time shift is dynamic or variable-driven
- When building flexible period offset calculations
- When @PRIOR's backward-only limitation is insufficient

---

## Category

**Time Series / Data Movement**

---

## Syntax

```essbase
@SHIFT(mbrName, offset)
```

### Formal Syntax

```
@SHIFT(memberNameOrFunction, periodOffset)
```

Where:
- `memberNameOrFunction` — The data member whose shifted value to retrieve
- `periodOffset` — Integer offset: positive = forward in time, negative = backward in time

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name or function | ✅ Yes | The member whose value to retrieve from the shifted period. |
| `offset` | Integer | ✅ Yes | How many periods to shift. **Positive**: forward in time (future). **Negative**: backward in time (past). **Zero**: current period (no shift). Can be a variable or expression. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Shifted period has data | Numeric value from offset period |
| Shifted period is #MISSING | `#MISSING` |
| Shifted period doesn't exist | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Bidirectional**: Unlike @PRIOR (backward only), @SHIFT handles both directions. Positive offset = future; negative offset = past.

2. **Time Dimension**: @SHIFT operates on the Time/Period dimension, navigating the outline order.

3. **Boundary Behavior**: If the shift goes beyond available periods (before first month or after last month), #MISSING is returned.

4. **Cross-Year**: @SHIFT can cross year boundaries if the time hierarchy supports it.

5. **Variable Offset**: The offset can be a variable or expression, enabling dynamic time shifting based on calculation context.

---

## Syntax Variants & Scenarios

### Variant 1: Look Forward

```essbase
"Next_Month_Pipeline" = @SHIFT("Pipeline", 1);
```

### Variant 2: Look Backward (Same as @PRIOR)

```essbase
"Prior_Month_Rev" = @SHIFT(Revenue, -1);
```

### Variant 3: Variable Offset

```essbase
VAR vLag = 3;
"Lagged_Value" = @SHIFT(Revenue, -1 * vLag);
```

### Variant 4: Year-Over-Year

```essbase
"Prior_Year" = @SHIFT(Revenue, -12);
```

### Variant 5: Lead-Lag Analysis

```essbase
"Lead_1" = @SHIFT("Orders", 1);   /* Next period orders */
"Lag_1" = @SHIFT("Collections", -1);  /* Prior period collections */
```

---

## Practical Examples

### Example 1: Lead-Lag Revenue Recognition

**Scenario**: Revenue is recognized one month after the order is booked.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    Revenue = @SHIFT("Booked_Orders", -1);  /* Revenue = last month's orders */
ENDFIX
```

---

### Example 2: Forward-Looking Pipeline

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Next_3_Month_Pipeline" = @SHIFT("Pipeline", 1) +
                               @SHIFT("Pipeline", 2) +
                               @SHIFT("Pipeline", 3);
ENDFIX
```

---

### Example 3: Seasonal Pattern Application

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    /* Apply last year's seasonal pattern */
    IF(@SHIFT(Revenue, -12) > 0 AND @SHIFT(Revenue, -24) > 0)
        VAR vSeasonalFactor = @SHIFT(Revenue, -12) / @SHIFT(Revenue, -24);
        Revenue = @SHIFT(Revenue, -12) * vSeasonalFactor;
    ENDIF
ENDFIX
```

---

### Example 4: Dynamic Offset Based on Variable

```essbase
VAR vMonthsBack = 6;
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Trailing_Avg" = (@SUM(Revenue, @CURRMBR("Period")) +
        @SHIFT(Revenue, -1) + @SHIFT(Revenue, -2) +
        @SHIFT(Revenue, -3) + @SHIFT(Revenue, -4) +
        @SHIFT(Revenue, -5)) / vMonthsBack;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Positive vs. negative confusion | Positive = forward (future), Negative = backward (past) | Remember: `@SHIFT(x, -1)` = prior period |
| Boundary overflow | Shifting beyond available periods returns #MISSING | Check for #MISSING before using shifted values |
| @SHIFT vs. @PRIOR | @PRIOR(x, 1) = @SHIFT(x, -1) — they use opposite sign conventions | Pick one convention and be consistent |
| Performance with many shifts | Multiple @SHIFT calls read multiple blocks | Minimize shift calls; consider staging data |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SHIFTPLUS`](./@SHIFTPLUS.md) | Shift forward only |
| [`@SHIFTMINUS`](./@SHIFTMINUS.md) | Shift backward only |
| [`@SHIFTSIBLING`](./@SHIFTSIBLING.md) | Shift across siblings |
| [`@PRIOR`](./@PRIOR.md) | Backward-only time navigation |
| [`@NEXT`](./@NEXT.md) | Forward-only time navigation |
| [`@PREVSIBLING`](./@PREVSIBLING.md) | Previous sibling — any dimension |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @SHIFT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/shift.html)
