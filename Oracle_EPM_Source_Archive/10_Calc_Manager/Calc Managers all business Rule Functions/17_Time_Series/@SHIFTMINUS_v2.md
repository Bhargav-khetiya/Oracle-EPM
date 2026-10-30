# @SHIFTMINUS

## Overview

`@SHIFTMINUS` is a **time series function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **shifts data backward** across time periods by a specified offset. It is functionally similar to `@SHIFT` but is explicitly designed to only move backward (into the past) along the time dimension.

### Why Does This Function Exist?

Referencing historical data is a core requirement in financial planning:
- **Lag indicators**: Analyzing prior period actuals to drive current forecasts
- **Trailing averages**: Calculating moving averages over past periods
- **Collections modeling**: Determining cash receipts based on past sales
- **Clearer syntax**: `@SHIFTMINUS(Revenue, 1)` is sometimes preferred over `@SHIFT(Revenue, -1)` to make the backward direction explicit.

### When to Use It

- When you need to reference past periods
- To calculate cash collections based on historical sales
- To compute trailing moving averages or rolling sums
- For year-over-year or month-over-month comparisons
- When you want explicit, readable syntax for backward time shifts

---

## Category

**Time Series / Data Movement**

---

## Syntax

```essbase
@SHIFTMINUS(mbrName, offset)
```

### Formal Syntax

```
@SHIFTMINUS(memberNameOrFunction, periodOffset)
```

Where:
- `memberNameOrFunction` — The data member whose backward-shifted value to retrieve.
- `periodOffset` — A positive integer indicating how many periods backward to shift.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name or function | ✅ Yes | The member whose value to retrieve from the past period. |
| `offset` | Positive Integer | ✅ Yes | How many periods to shift backward. `1` = prior period, `12` = same period prior year (for monthly). Must be a positive integer (the function inherently applies the minus). |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Past period has data | Numeric value from offset period |
| Past period is #MISSING | `#MISSING` |
| Past period doesn't exist (start of time) | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Backward Only**: `@SHIFTMINUS` strictly navigates backward in the Time/Period dimension. It moves `offset` positions backward in the outline order.
2. **Equivalent to @SHIFT**: `@SHIFTMINUS(mbrName, n)` produces the exact same result as `@SHIFT(mbrName, -n)`.
3. **Offset Sign**: You provide a *positive* integer for the offset; the function name implies the negative direction. `@SHIFTMINUS(Revenue, 1)` means 1 period back.
4. **Cross-Year Boundary**: It can cross year boundaries if the time hierarchy supports it.
5. **Start of Time**: If the shift goes before the first available period in the outline, it returns `#MISSING`.

---

## Syntax Variants & Scenarios

### Variant 1: Prior Period

```essbase
"Prior_Month_Sales" = @SHIFTMINUS("Sales", 1);
```

### Variant 2: Same Period Prior Year

```essbase
"Prior_Year_Sales" = @SHIFTMINUS("Sales", 12);
```

### Variant 3: Variable Offset

```essbase
VAR vLag = 3;
"Delayed_Impact" = @SHIFTMINUS("Expense", vLag);
```

### Variant 4: Rolling Past Sum

```essbase
"Trailing_3_Month_Sales" = @SHIFTMINUS("Sales", 1) + 
                           @SHIFTMINUS("Sales", 2) + 
                           @SHIFTMINUS("Sales", 3);
```

---

## Practical Examples

### Example 1: Cash Collections (Payment Terms)

**Scenario**: 40% of sales are collected in the month of sale, 50% in the following month, and 10% two months later.

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    "Cash_Collected" = ("Sales" * 0.40) + 
                       (@SHIFTMINUS("Sales", 1) * 0.50) + 
                       (@SHIFTMINUS("Sales", 2) * 0.10);
ENDFIX
```

**What Happens**:
- Calculates current month cash by taking 40% of current sales, 50% of 1-month-ago sales, and 10% of 2-months-ago sales.

---

### Example 2: Subscription Renewals

**Scenario**: Subscriptions booked 12 months ago are up for renewal this month.

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    /* Assume 80% renewal rate */
    "Renewed_Subscriptions" = @SHIFTMINUS("New_Subscriptions", 12) * 0.80;
ENDFIX
```

---

### Example 3: Moving Average

**Scenario**: Calculate a 3-month trailing average for expenses to smooth out volatility.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "3M_Avg_Expense" = (@SUM("Expense", @CURRMBR("Period")) + 
                        @SHIFTMINUS("Expense", 1) + 
                        @SHIFTMINUS("Expense", 2)) / 3;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using a negative offset | `@SHIFTMINUS(x, -1)` might shift forward or error out because the minus is already implied | Always use a positive integer: `@SHIFTMINUS(x, 1)` |
| @SHIFTMINUS vs @PRIOR | They do exactly the same thing | Use whichever makes your code more readable |
| Start of timeline | Shifting before January (if cross-year isn't set up) returns #MISSING | Handle #MISSING values explicitly in formulas |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SHIFT`](./@SHIFT.md) | Flexible shift (forward or backward) |
| [`@SHIFTPLUS`](./@SHIFTPLUS.md) | Shift forward only |
| [`@PRIOR`](./@PRIOR.md) | Retrieves the value from the prior period (identical behavior) |
| [`@PREVSIBLING`](../04_Member_Navigation/@PREVSIBLING.md) | Previous sibling — any dimension |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @SHIFTMINUS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/shiftminus.html)
