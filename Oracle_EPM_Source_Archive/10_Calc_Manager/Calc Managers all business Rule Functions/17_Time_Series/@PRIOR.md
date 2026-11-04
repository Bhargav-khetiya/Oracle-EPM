# @PRIOR

## Overview

`@PRIOR` is a **time series function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the data value from a **previous time period**. It navigates backward in the time dimension by a specified number of periods, enabling period-over-period comparisons, growth calculations, and trend analysis.

### Why Does This Function Exist—

Time-based comparisons are fundamental to financial analysis:
- **YoY comparisons**: Comparing this year's Q1 to last year's Q1
- **Sequential trends**: Month-over-month growth rates
- **Rolling calculations**: Moving averages, trailing sums
- **Opening balances**: Carrying forward prior period closing balances
- **Lag analysis**: Comparing revenue to AR collections with a time delay

### When to Use It

- For year-over-year variance calculations
- For month-over-month growth percentages
- When calculating period-to-period changes
- In rolling average or moving sum calculations
- When referencing prior period values for opening balances
- For seasonal comparison (same period, prior year)

---

## Category

**Time Series / Data Access**

---

## Syntax

```essbase
@PRIOR(mbrName, n)
```

### Formal Syntax

```
@PRIOR(memberNameOrFunction, numberOfPeriods)
```

Where:
- `memberNameOrFunction` — The data member (typically an Account) whose prior value to retrieve
- `numberOfPeriods` — How many periods to look back (positive integer)

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name or function | ✅ Yes | The member whose value to retrieve from the prior period. Typically an Account member like `"Revenue"` or `"Closing_Balance"`. |
| `n` | Integer | ✅ Yes | Number of periods to look back. `1` = immediately prior period, `12` = same period last year (for monthly), `4` = same quarter last year (for quarterly). Must be positive. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Prior period has data | Numeric value from n periods ago |
| Prior period is #MISSING | `#MISSING` |
| No prior period exists (beginning of time) | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Time Dimension Navigation**: @PRIOR navigates backward in the Time/Period dimension. It moves `n` positions backward in the outline order of time members under the same parent.

2. **Cross-Year Boundary**: @PRIOR can cross year boundaries. If you're in Jan FY25 and request `@PRIOR(Revenue, 1)`, it goes to Dec FY24 (if the outline supports it).

3. **Hierarchy Awareness**: @PRIOR operates within the same hierarchy level. If you're at the Month level, @PRIOR moves across months. If at Quarter level, it moves across quarters.

4. **Data Read**: @PRIOR is a read-only operation — it retrieves data but doesn't modify anything. The current period's context is maintained for all other dimensions.

5. **vs. @PREVSIBLING**: @PRIOR is specifically for time dimensions and understands time hierarchy. @PREVSIBLING navigates any dimension's outline order. For time-based calculations, @PRIOR is preferred.

6. **Performance**: Each @PRIOR call reads from a different data block (different time period). Multiple @PRIOR calls per formula can impact performance on large databases.

---

## Syntax Variants & Scenarios

### Variant 1: Previous Month

```essbase
"Prior_Month_Rev" = @PRIOR(Revenue, 1);
```

### Variant 2: Same Month Last Year

```essbase
"Prior_Year_Rev" = @PRIOR(Revenue, 12);
```

### Variant 3: In a Growth Calculation

```essbase
IF(@PRIOR(Revenue, 1) > 0)
    "MoM_Growth" = (Revenue / @PRIOR(Revenue, 1)) - 1;
ENDIF
```

### Variant 4: Opening Balance

```essbase
"Opening_Balance" = @PRIOR("Closing_Balance", 1);
```

### Variant 5: Year-Over-Year Variance

```essbase
"YoY_Variance" = Revenue - @PRIOR(Revenue, 12);
```

### Variant 6: Multiple Lookback

```essbase
"3_Month_Avg" = (Revenue + @PRIOR(Revenue, 1) + @PRIOR(Revenue, 2)) / 3;
```

---

## Practical Examples

### Example 1: Month-Over-Month Growth Rate

**Scenario**: Calculate the percentage growth from the previous month.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    FIX("Feb":"Dec")
        IF(@PRIOR(Revenue, 1) > 0)
            "MoM_Growth" = @ROUND((Revenue / @PRIOR(Revenue, 1) - 1) * 100, 1);
        ELSE
            "MoM_Growth" = #MISSING;
        ENDIF
    ENDFIX
ENDFIX
```

**What Happens**:
- Skips January (no prior month in FY25 without crossing years)
- For each month Feb-Dec, reads prior month's Revenue
- Calculates percentage change: (Current / Prior - 1) × 100
- Rounds to 1 decimal place

---

### Example 2: Year-Over-Year Comparison

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "YoY_Revenue_Change" = Revenue - @PRIOR(Revenue, 12);
    
    IF(@ABS(@PRIOR(Revenue, 12)) > 0)
        "YoY_Growth_Pct" = @ROUND("YoY_Revenue_Change" / @ABS(@PRIOR(Revenue, 12)) * 100, 1);
    ENDIF
ENDFIX
```

---

### Example 3: Balance Sheet — Opening Balance Carry Forward

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    FIX("Feb":"Dec")
        "Opening_Cash" = @PRIOR("Closing_Cash", 1);
        "Closing_Cash" = "Opening_Cash" + "Cash_Receipts" - "Cash_Payments";
    ENDFIX
    FIX("Jan")
        "Opening_Cash" = "Closing_Cash" -> "FY24" -> "Dec";  /* Cross-year */
        "Closing_Cash" = "Opening_Cash" + "Cash_Receipts" - "Cash_Payments";
    ENDFIX
ENDFIX
```

---

### Example 4: 3-Month Moving Average

```essbase
FIX("FY25", "Working", "Apr":"Dec", @DESCENDANTS("Total Entity"))
    "3M_Moving_Avg" = @ROUND(
        (Revenue + @PRIOR(Revenue, 1) + @PRIOR(Revenue, 2)) / 3, 2);
ENDFIX
```

---

### Example 5: Seasonal Index

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@PRIOR(Revenue, 12) > 0)
        "Seasonal_Index" = Revenue / @PRIOR(Revenue, 12);
    ENDIF
ENDFIX
```
Index > 1 means growth vs. same period last year.

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| @PRIOR at first period | @PRIOR("Revenue", 1) in Jan FY25 may return #MISSING if FY24 isn't in scope | Handle first periods separately or check for #MISSING |
| Division by @PRIOR | If prior period value is 0 or #MISSING, division fails | Always check: `IF(@PRIOR(Rev, 1) > 0)` |
| @PRIOR vs. @SHIFT | @PRIOR goes backward; @SHIFT can go forward or backward | Use @PRIOR for backward; @SHIFT for flexible direction |
| @PRIOR on non-time dimension | @PRIOR is designed for the time dimension | Use @PREVSIBLING for non-time dimensions |
| Cross-year boundary | @PRIOR may or may not cross year boundaries depending on outline | Test cross-year behavior in your specific application |
| Large lookback values | @PRIOR(Revenue, 24) requires data from 2 years ago | Ensure historical data exists for the lookback window |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PRIORS`](./@PRIORS.md) | Range of prior values |
| [`@NEXT`](./@NEXT.md) | Next period — opposite direction |
| [`@SHIFT`](./@SHIFT.md) | Flexible shift (forward or backward) |
| [`@PREVSIBLING`](./@PREVSIBLING.md) | Previous outline sibling — any dimension |
| [`@TODATE`](./@TODATE.md) | Period-to-date accumulation |
| [`@MOVSUM`](./@MOVSUM.md) | Moving sum |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @PRIOR](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/prior.html)
