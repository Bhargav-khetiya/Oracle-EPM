# @ACCUM

## Overview

`@ACCUM` is a **time-series accumulation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **accumulates (running total)** values across time periods. It takes the value from the current time period and adds it to the accumulated total from all prior periods in the same consolidation path.

### Why Does This Function Exist?

In financial planning, you frequently need Year-to-Date (YTD) calculations. Instead of manually writing formulas like `Jan + Feb + Mar + ...`, `@ACCUM` automatically creates a running total across the time dimension.

### When to Use It

- **Year-to-Date (YTD) calculations** — Accumulated revenue, expenses, or any P&L metric
- **Cumulative KPIs** — Running total of units sold, hours worked, etc.
- **Progressive budgets** — Showing how budget consumption builds over time
- **Cash flow accumulation** — Running cash balance across periods

---

## Category

**Time Series / Accumulation**

---

## Syntax

```essbase
@ACCUM(memberExpression [, timeRange])
```

### Formal Syntax Variants

```
@ACCUM(expression)
@ACCUM(expression, timeMemberOrRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric expression / Member | ✅ Yes | The member or expression whose values are to be accumulated across time periods. This is typically a data cell reference or an account member. |
| `timeRange` | Member / Range | ❌ No | Optional. Specifies the time range for accumulation. If omitted, it defaults to the time dimension hierarchy (e.g., Jan through Dec within a year). Can be a specific member range like `"Jan":"Jun"`. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| First time period | Value of the first period (no prior periods to add) |
| Subsequent periods | Sum of the current period plus all prior period values |
| `#MISSING` in a period | That period is treated as 0 in the accumulation |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Time Dimension Awareness**: `@ACCUM` is "time-aware" — it knows which dimension in your outline is tagged as the Time dimension. It traverses members of this dimension in their outline order.

2. **Evaluation Flow**:
   - Identifies the current time period member
   - Looks backward through all preceding sibling time period members
   - Sums the expression value from each prior period plus the current period
   - Writes the accumulated result to the target cell

3. **Hierarchy Respect**: `@ACCUM` respects the time hierarchy. If your time dimension is structured as `Year > Quarter > Month`, accumulation happens within the level of the current member. So monthly accumulation stays within the quarter or year depending on your outline structure.

4. **Sparse/Dense Consideration**: The Time dimension is almost always a **dense** dimension in PBCS/EPBCS. Since `@ACCUM` operates along the dense Time dimension, it is efficient — it processes data within the same data block.

5. **Missing Value Treatment**: `#MISSING` values are treated as **zero** during accumulation. This means if Feb is `#MISSING`, the March YTD will equal Jan + 0 + Mar.

6. **Block Creation**: `@ACCUM` does NOT create new blocks. It only operates on existing data blocks.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Accumulation (Default Time Range)

```essbase
@ACCUM(Sales)
```
Accumulates `Sales` across all time periods within the current level of the time hierarchy.

### Variant 2: Accumulation with Specific Time Range

```essbase
@ACCUM(Sales, "Jan":"Jun")
```
Accumulates `Sales` only from January through June (first half of the year).

### Variant 3: Cross-Dimensional Accumulation

```essbase
@ACCUM("Revenue" -> "Actual")
```
Accumulates the Revenue–Actual intersection across time periods.

### Variant 4: Expression-Based Accumulation

```essbase
@ACCUM(Revenue - COGS)
```
Accumulates the result of the expression (Gross Profit) across time.

---

## Practical Examples

### Example 1: Year-to-Date Revenue

**Scenario**: Calculate YTD Revenue for all entities.

```essbase
FIX("Actual", "FY24", @DESCENDANTS("Total_Entity"))
    "YTD_Revenue" = @ACCUM("Revenue");
ENDFIX
```

**Result**:
| Period | Revenue (Monthly) | YTD_Revenue |
|--------|-------------------|-------------|
| Jan | 100 | 100 |
| Feb | 150 | 250 |
| Mar | 120 | 370 |
| Apr | 200 | 570 |

---

### Example 2: Cumulative Budget Consumption

**Scenario**: Show how much of the annual budget has been consumed each month.

```essbase
FIX("Working", "FY24")
    "Cum_Budget_Used" = @ACCUM("Actual_Spend");
    IF(@ABS("Annual_Budget") > 0)
        "Budget_Pct_Used" = @ACCUM("Actual_Spend") / "Annual_Budget" * 100;
    ENDIF
ENDFIX
```

---

### Example 3: Running Cash Balance

**Scenario**: Calculate cumulative cash flow to derive the running cash balance.

```essbase
FIX("Actual", "FY24", "No_Entity")
    "Running_Cash" = "Opening_Balance" + @ACCUM("Net_Cash_Flow");
ENDFIX
```

**What Happens**:
| Period | Opening | Net Cash Flow | @ACCUM(Net Cash Flow) | Running Cash |
|--------|---------|---------------|----------------------|--------------|
| Jan | 1000 | 200 | 200 | 1200 |
| Feb | 1000 | -50 | 150 | 1150 |
| Mar | 1000 | 300 | 450 | 1450 |

---

### Example 4: YTD vs Full Year Comparison

**Scenario**: Calculate YTD Actual and compare to Full Year Budget.

```essbase
FIX("FY24", @DESCENDANTS("All_Accounts"))
    "YTD_Actual" = @ACCUM("Actual");
    IF("Full_Year_Budget" != 0)
        "YTD_vs_Budget_Pct" = @ACCUM("Actual") / "Full_Year_Budget" * 100;
    ENDIF
ENDFIX
```

---

### Example 5: Handling Missing Data in Accumulation

**Scenario**: Some months may not have data entered yet (future months in forecast).

```essbase
FIX("Forecast", "FY24")
    "YTD_Forecast" = @ACCUM("Amount");
ENDFIX
```

**Result** (if data entry stops after March):
| Period | Amount | YTD_Forecast |
|--------|--------|-------------|
| Jan | 100 | 100 |
| Feb | 200 | 300 |
| Mar | 150 | 450 |
| Apr | #MISSING | 450 |
| May | #MISSING | 450 |

Note: `#MISSING` months add 0, so the YTD stays at 450.

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on non-Time dimensions | `@ACCUM` is designed for the Time dimension only | Use `@SUM` with explicit member ranges for non-time accumulation |
| Expecting quarter-level YTD across quarters | `@ACCUM` accumulates within the hierarchy level — Q1 months accumulate within Q1 | Use `@TODATE` for true YTD across quarters |
| Confusing with `@PTD` | `@PTD` (Period-to-Date) is similar but uses the account type tag | Choose based on your requirement |
| Double-counting at parent levels | If parent members are `Dynamic Calc`, accumulation may produce unexpected results | Apply `@ACCUM` only at the input (leaf) level |
| Not accounting for seasonality | `@ACCUM` is a simple running total — it doesn't adjust for seasonal patterns | Use `@ACCUM` for actual accumulation; use separate seasonal logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PTD`](@PTD.md) | Period-to-Date — similar but uses account type to determine accumulation behavior |
| [`@TODATE`](@TODATE.md) | To-Date — more flexible, supports Year-to-Date, Quarter-to-Date, etc. |
| [`@TODATEEX`](@TODATEEX.md) | Extended version of @TODATE |
| [`@SUM`](../06_Mathematical/@SUM.md) | Manual summation — less automatic but more control |
| [`@PRIOR`](@PRIOR.md) | Get prior period value — related time-series concept |
| [`@NEXT`](@NEXT.md) | Get next period value — related time-series concept |
| [`@MOVSUM`](@MOVSUM.md) | Moving sum — rolling window accumulation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ACCUM](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/accum.html)
- [Oracle Essbase Technical Reference — Time Series Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/time_series_reporting_functions.html)
