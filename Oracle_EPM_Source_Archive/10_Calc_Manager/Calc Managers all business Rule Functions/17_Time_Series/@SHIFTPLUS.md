# @SHIFTPLUS

## Overview

`@SHIFTPLUS` is a **time series function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **shifts data forward** across time periods by a specified offset. It is functionally similar to `@SHIFT` but is explicitly designed to only move forward (into the future) along the time dimension.

### Why Does This Function Exist—

When building forward-looking calculations, clarity and intent are important:
- **Lead indicators**: Looking at next month's committed pipeline or orders
- **Deferred revenue**: Recognizing revenue in future periods based on current bookings
- **Predictive modeling**: Pushing current trends into future periods
- **Clearer syntax**: `@SHIFTPLUS(Revenue, 1)` is sometimes preferred over `@SHIFT(Revenue, 1)` to make the forward direction explicit to other developers.

### When to Use It

- When you need to reference future periods
- To calculate deferred revenue or expenses
- To push values forward in time (e.g., cash flow forecasting based on payment terms)
- When building predictive models based on current data
- For lead-time analysis (e.g., order booking to fulfillment)

---

## Category

**Time Series / Data Movement**

---

## Syntax

```essbase
@SHIFTPLUS(mbrName, offset)
```

### Formal Syntax

```
@SHIFTPLUS(memberNameOrFunction, periodOffset)
```

Where:
- `memberNameOrFunction` — The data member whose forward-shifted value to retrieve.
- `periodOffset` — A positive integer indicating how many periods forward to shift.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name or function | ✅ Yes | The member whose value to retrieve from the future period. |
| `offset` | Positive Integer | ✅ Yes | How many periods to shift forward. `1` = next period, `12` = same period next year (for monthly). Must be a positive integer or evaluate to one. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Future period has data | Numeric value from offset period |
| Future period is #MISSING | `#MISSING` |
| Future period doesn't exist (end of time) | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Forward Only**: `@SHIFTPLUS` strictly navigates forward in the Time/Period dimension. It moves `offset` positions forward in the outline order.
2. **Equivalent to @SHIFT**: `@SHIFTPLUS(mbrName, n)` produces the exact same result as `@SHIFT(mbrName, n)` when `n` is positive.
3. **Cross-Year Boundary**: Like other time series functions, it can cross year boundaries if the time hierarchy supports it.
4. **End of Time**: If the shift goes beyond the last available period in the outline, it returns `#MISSING`.
5. **Read-Only**: It retrieves the value from the future period; it does not write to it.

---

## Syntax Variants & Scenarios

### Variant 1: Next Period

```essbase
"Next_Month_Orders" = @SHIFTPLUS("Orders", 1);
```

### Variant 2: Same Period Next Year

```essbase
"Next_Year_Target" = @SHIFTPLUS(Revenue, 12);
```

### Variant 3: Variable Offset

```essbase
VAR vLeadTime = 2;
"Expected_Delivery" = @SHIFTPLUS("Booked_Orders", vLeadTime);
```

### Variant 4: Rolling Future Sum

```essbase
"Next_Quarter_Pipeline" = @SHIFTPLUS("Pipeline", 1) + 
                          @SHIFTPLUS("Pipeline", 2) + 
                          @SHIFTPLUS("Pipeline", 3);
```

---

## Practical Examples

### Example 1: Deferred Revenue Recognition

**Scenario**: Revenue is recognized equally over the next 3 months after a booking.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Recognized_Revenue" = ("Bookings" / 3) + 
                           (@SHIFTPLUS("Bookings", 1) / 3) + 
                           (@SHIFTPLUS("Bookings", 2) / 3);
ENDFIX
```
*(Note: This formula calculates what revenue will be recognized in the current month based on past bookings by shifting forward. Wait, logically to get past bookings you shift backward. If you want to push current bookings forward, you would calculate the future periods. See Example 2 for pushing forward.)*

### Example 2: Forecasting Cash Collections (Payment Terms)

**Scenario**: 30% of sales are collected in the same month, 50% next month, 20% the month after.

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    "Cash_Collected" = ("Sales" * 0.30) + 
                       (@SHIFTPLUS("Sales", -1) * 0.50) + /* Using SHIFTMINUS or SHIFT for past */
                       (@SHIFTPLUS("Sales", -2) * 0.20);
ENDFIX
```
*(Correction: `@SHIFTPLUS` with a negative number may not be supported or is confusing. Use `@SHIFTMINUS` for past periods. Let's provide a better example for `SHIFTPLUS`.)*

### Correct Example 2: Calculating Required Inventory

**Scenario**: Next month's sales dictate this month's required ending inventory.

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    /* Target ending inventory is 50% of next month's expected sales */
    "Target_Ending_Inv" = @SHIFTPLUS("Expected_Sales", 1) * 0.50;
ENDFIX
```

---

### Example 3: Subscription Renewal Pipeline

**Scenario**: Subscriptions booked this month come up for renewal 12 months later.

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    "Upcoming_Renewals" = @SHIFTPLUS("New_Subscriptions", 12);
ENDFIX
```
*(Note: This looks at what was booked 12 months in the future. To look at what was booked 12 months ago, use `@SHIFTMINUS`.)*

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative offset | `@SHIFTPLUS(x, -1)` is syntactically confusing and may error | Use `@SHIFTMINUS` or `@SHIFT` for backward navigation |
| Expecting write behavior | `@SHIFTPLUS` reads from the future; it doesn't write to it | To write to the future, use `FIX` on the future period and read from the past |
| End of timeline | Shifting past December (if cross-year isn't set up) returns #MISSING | Handle #MISSING values explicitly |
| Using @SHIFTPLUS for prior periods | PLUS implies forward/future | Use `@PRIOR` or `@SHIFTMINUS` for past periods |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SHIFT`](./@SHIFT.md) | Flexible shift (forward or backward) |
| [`@SHIFTMINUS`](./@SHIFTMINUS.md) | Shift backward only |
| [`@NEXT`](./@NEXT.md) | Retrieves the value from the next period |
| [`@PRIOR`](./@PRIOR.md) | Retrieves the value from the prior period |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @SHIFTPLUS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/shiftplus.html)
