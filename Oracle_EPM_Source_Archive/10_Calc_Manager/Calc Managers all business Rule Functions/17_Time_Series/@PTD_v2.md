# @PTD

## Overview

`@PTD` is a **time series function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that stands for **Period-To-Date**. It calculates the cumulative value of a specified member from the beginning of the year (or quarter/half-year depending on context) up to the current period. 

### Why Does This Function Exist—

Financial reporting relies heavily on cumulative totals:
- **Year-To-Date (YTD)**: Total revenue from January through the current month
- **Quarter-To-Date (QTD)**: Total expenses from the start of the quarter through the current month
- **Half-To-Date (HTD)**: Accumulated figures for a 6-month period

Rather than writing complex dynamic ranges like `@SUM(@RANGE("Jan", @CURRMBR("Period")))`, `@PTD` provides a streamlined, built-in function to handle period-to-date accumulation.

### When to Use It

- To calculate Year-to-Date (YTD) balances for P&L accounts
- To calculate Quarter-to-Date (QTD) metrics
- When building reporting cubes that store both periodic and YTD data
- To average balances over a year-to-date period

---

## Category

**Time Series / Accumulation**

---

## Syntax

```essbase
@PTD(timePeriodList)
```

### Formal Syntax

```
@PTD(memberNameList)
```

Where:
- `memberNameList` — One or more members (usually from the Time/Period dimension) defining the scope of the accumulation. If multiple members are passed, it sums across all specified members for the period-to-date window.

*(Note: In practice, `@PTD` is most commonly used in conjunction with a specific time member, but Essbase's built-in time intelligence often makes `@PTD(Member)` sufficient to grab YTD values. However, `@TODATE` is frequently preferred for its explicit boundary control).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `timePeriodList` | Member list | ✅ Yes | The members to accumulate over the period-to-date range. For example, `@PTD("Revenue")` will accumulate Revenue from the start of the current year (or ancestor) up to the current period in the calculation context. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Valid periods with data | The accumulated numeric sum |
| No data in any period | `#MISSING` |
| Used outside a Time dimension | Error or unpredictable results |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Time Dimension Intelligence**: `@PTD` relies on the dimension tagged as `Time` in the outline. It traverses the outline to find the ancestor of the current period (usually the Year or Quarter total) and sums all children of that ancestor up to the current member.
2. **Current Context**: If the calc script is executing on `"Mar"`, `@PTD(Revenue)` sums `Jan + Feb + Mar` (assuming they share a parent like `Q1` or `Year`).
3. **vs @TODATE**: `@PTD` is an older function that relies heavily on the Time tag and outline structure. `@TODATE` provides much more explicit control over the accumulation boundary (e.g., forcing YTD vs QTD) and is generally recommended over `@PTD`.

---

## Syntax Variants & Scenarios

### Variant 1: Basic YTD/PTD Accumulation

```essbase
"YTD_Revenue" = @PTD(Revenue);
```
Assuming Revenue is evaluated against a time dimension, this accumulates Revenue up to the current period.

### Variant 2: Accumulating Multiple Accounts

```essbase
"YTD_Total_Expense" = @PTD("OpEx", "COGS");
```
Sums both OpEx and COGS from the start of the period to the current date.

---

## Practical Examples

### Example 1: Creating a YTD Reporting Measure

**Scenario**: A cube has a "Periodic" measure and needs to calculate a "YTD" measure dynamically.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "YTD_Amount" = @PTD("Periodic_Amount");
ENDFIX
```
**What Happens**: 
- In Jan: `YTD_Amount = Jan Periodic_Amount`
- In Feb: `YTD_Amount = Jan + Feb Periodic_Amount`
- In Mar: `YTD_Amount = Jan + Feb + Mar Periodic_Amount`

---

### Example 2: YTD Average

**Scenario**: Calculate the average monthly revenue for the year-to-date.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vMonthNum = @COUNT(SKIPNONE, @RANGE("Jan", @CURRMBR("Period")));
    
    IF(vMonthNum > 0)
        "YTD_Avg_Revenue" = @PTD(Revenue) / vMonthNum;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not tagging the Time dimension | `@PTD` fails or gives wrong results if the outline doesn't have a dimension explicitly tagged as "Time" | Ensure dimension properties are set correctly, or use `@SUM(@RANGE(...))` |
| Unpredictable boundary | `@PTD` resets based on the immediate parent. If months roll up to Quarters, `@PTD` calculates QTD, not YTD | Use `@TODATE` which allows you to explicitly define the reset boundary (e.g., Year vs Quarter) |
| Using on Balance Sheet accounts | Summing closing balances YTD (Jan + Feb = 2x balance) is mathematically incorrect | Don't use `@PTD` on Flow/Balance accounts; use `@PRIOR` for opening balances |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@TODATE`](./@TODATE.md) | Modern, more explicit equivalent of @PTD (Highly Recommended) |
| [`@TODATEEX`](./@TODATEEX.md) | Extended version of @TODATE |
| [`@SUMRANGE`](../06_Mathematical/@SUMRANGE.md) | Can be used to build custom PTD logic |
| [`@RANGE`](../18_Range_Set_Operations/@RANGE.md) | Used to build manual YTD logic (`@SUM(@RANGE("Jan", @CURRMBR("Period")))`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @PTD](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ptd.html)
