# Member Formula Patterns — Reusable Templates

> **Section:** 18 — Reference  
> **File:** 04 — Member Formula Patterns  
> **Difficulty:** Intermediate → Advanced

---

## What Are Member Formulas?

Member formulas are calculations attached directly to outline members (typically in the Account dimension). They execute automatically during aggregation or when data is retrieved, without needing a separate business rule.

---

## Common Patterns

### Pattern 1: Ratio / Percentage

```
/* Profit Margin */
IF("Revenue" <> 0)
    "Net_Income" / "Revenue" * 100;
ENDIF
```

### Pattern 2: Variance Calculation

```
/* Budget vs Actual Variance */
"Actual" - "Budget";
```

### Pattern 3: Variance Percentage

```
/* Variance % */
IF("Budget" <> 0)
    ("Actual" - "Budget") / @ABS("Budget") * 100;
ENDIF
```

### Pattern 4: Year-over-Year Growth

```
/* YoY Growth % */
IF(@PRIOR("Year") <> #MISSING AND "Revenue" -> @PRIOR("Year") <> 0)
    ("Revenue" - "Revenue" -> @PRIOR("Year")) / @ABS("Revenue" -> @PRIOR("Year")) * 100;
ENDIF
```

### Pattern 5: Cumulative / YTD

```
/* Year-to-Date Revenue */
@SUMRANGE("Revenue", @TODATE("Period", "YearTotal"));
```

### Pattern 6: Per-Unit Calculation

```
/* Revenue Per Room */
IF("Room_Count" <> 0)
    "Total_Revenue" / "Room_Count";
ENDIF
```

### Pattern 7: Weighted Average

```
/* Weighted Average Rate */
IF("Total_Revenue" <> 0)
    "Rate_Revenue" / "Total_Revenue";
ENDIF
```

### Pattern 8: Conditional Aggregation

```
/* Only aggregate if positive */
IF("Revenue" > 0)
    "Revenue";
ELSE
    0;
ENDIF
```

### Pattern 9: Cross-Dimensional Reference

```
/* Budget Revenue × Actual Exchange Rate */
"Revenue" -> "Budget" * "Exchange_Rate" -> "Actual";
```

### Pattern 10: Moving Average

```
/* 3-Month Moving Average */
@MOVAVG(3);
```

---

## Time Balance Formulas

For Account dimension members with Time Balance properties:

| Pattern | Time Balance | Skip | Result |
|---------|-------------|------|--------|
| Revenue (flow) | None | None | Sums periods |
| Cash Balance | Last | None | Takes last period value |
| Average Headcount | Average | None | Averages periods |
| Average Rate (skip zeros) | Average | Zeros | Averages non-zero periods |

### Setting Time Balance via Member Properties

```
Member: Cash_Balance
  Time Balance: Last
  Skip Value: None

Member: Avg_Headcount
  Time Balance: Average
  Skip Value: Missing
```

---

## Expense vs Non-Expense Variance

The Variance Reporting property determines how variance is calculated:

| Property | Formula | Example |
|----------|---------|---------|
| **Non-Expense** | Actual - Budget | Revenue: Actual 110, Budget 100 → Variance = +10 (favorable) |
| **Expense** | Budget - Actual | Expense: Actual 90, Budget 100 → Variance = +10 (favorable) |

This ensures positive variance always means "favorable" regardless of account type.

---

## Formula Best Practices

1. **Always guard division** with `IF(denominator <> 0)` — division by zero returns #ERROR
2. **Check for #MISSING** before referencing cross-dimensional values
3. **Use @ABS** in percentage calculations to handle negative denominators
4. **Keep formulas simple** — complex logic belongs in business rules, not member formulas
5. **Test with Dynamic Calc** — member formulas on Dynamic Calc members execute during retrieval

---

## Source Provenance

| Source | Files |
|--------|-------|
| Claude | `32_Member_Formula_Encyclopedia/` |
| ChatGPT | `Dimension_Properties/` member formula references |
| Gemini | `Dimension_Properties/` (mirrors ChatGPT) |

