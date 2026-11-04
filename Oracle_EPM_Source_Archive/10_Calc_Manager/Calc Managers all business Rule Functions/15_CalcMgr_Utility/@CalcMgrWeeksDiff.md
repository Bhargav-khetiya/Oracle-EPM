# @CalcMgrWeeksDiff

## Overview

`@CalcMgrWeeksDiff` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the mathematical **difference in weeks** between two provided **Java Date Objects**, returning the result as a precise floating-point decimal (a Double).

### Why Does This Function Exist—

While `@CalcMgrWeeksBetween` is excellent for integer-based counting (e.g., calculating exactly 3 full weeks for payroll), it completely ignores remainders. If a project lasts 3 weeks and 5 days, `WeeksBetween` rounds down to `3`.
If you are prorating costs, allocating weekly manufacturing overhead, or calculating HR benefit accruals, throwing away those 5 days causes severe financial under-allocation.
`@CalcMgrWeeksDiff` solves this by calculating the exact calendar delta and preserving the fractional remainder. It divides the total elapsed days by 7 and returns a highly precise decimal (e.g., `3.714`). This allows FP&A teams to execute exact, fractional weekly proration logic natively within Essbase without losing a single day of value.

### When to Use It

- **Fractional Proration**: Calculating exact fractional week utilization (e.g., `2.75` weeks) for short-term equipment rentals or SaaS allocations.
- **Accurate HR Accruals**: Determining the exact weekly tenure of an employee to calculate hyper-accurate, pro-rated benefit allocations.
- **Manufacturing Overhead**: Spreading fixed monthly factory overhead costs across the exact fractional number of weeks that a production run occupied.

---

## Category

**Date & Time / Date Differences / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrWeeksDiff(date1, date2)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date1` | Object | ✅ Yes | The first Java Date Object. |
| `date2` | Object | ✅ Yes | The second Java Date Object. |

---

## Return Value

**Return Type**: Numeric (Floating Point / Double)

Returns the absolute decimal difference in weeks.
- **Absolute Value (CRITICAL)**: Unlike `WeeksBetween`, this function operates using absolute variance. It does NOT matter which date you pass first. `(Jan 1, Jan 15)` and `(Jan 15, Jan 1)` will both return `2.0`. It will never return a negative number.
- **Fractional Precision**: Returns numbers like `1.5` or `3.857` (representing exactly `3` weeks and `6` days).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the two Date Objects.
2. **Delta Extraction**: It extracts the exact milliseconds of both dates and calculates the absolute mathematical difference, effectively stripping any negative directionality.
3. **Fractional Math**: It divides the millisecond delta by `604800000.0` (the exact number of milliseconds in a 7-day week, cast as a Double).
4. **Return**: It passes the resulting precise fractional decimal back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating a Fractional Week Gap

```essbase
/* 
   Assumes Start is Jan 1, 2024. End is Jan 11, 2024.
   Exactly 10 days elapsed. 10 / 7 = 1.42857.
   Returns 1.42857.
*/
VAR vWeeksElapsed = @CalcMgrWeeksDiff(vStartObj, vEndObj);
```

---

## Practical Examples

### Example 1: Pro-Rated Weekly Equipment Rental

**Scenario**: A construction company rents heavy machinery. The rate is strictly `$5,000` per week. However, if they return the equipment mid-week, they are billed a fractional pro-rated amount. The script must calculate exactly how many fractional weeks the equipment was on site to accrue the correct daily liability.

```essbase
FIX("FY25", "Working", @LEVEL0("Equipment"))
    
    IF("Weekly_Rental_Rate" > 0 AND "Return_Date" != #MISSING)
        
        /* 1. Convert the integer dates into Java Objects */
        VAR vStartObj = @CalcMgrIntegerToDate("Rental_Start_Date");
        VAR vReturnObj = @CalcMgrIntegerToDate("Return_Date");
        
        /* 
           2. Calculate exactly how many fractional weeks it was rented.
           (e.g., 10 days = 1.428 weeks)
        */
        VAR vFractionalWeeks = @CalcMgrWeeksDiff(vStartObj, vReturnObj);
        
        /* 
           3. Calculate the exact pro-rated liability.
           $5,000 * 1.428 = $7,140
        */
        "Accrued_Liability" = "Weekly_Rental_Rate" * vFractionalWeeks;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrWeeksDiff(20240101, 20240111)` | This function strictly requires **Java Date Objects**. If you pass native Essbase integers, the script will crash. Always use `@CalcMgrIntegerToDate` to wrap your integers first |
| Relying on Negative Returns | `IF(Diff < 0)` | Because `WeeksDiff` uses absolute variance, it will NEVER return a negative number, even if you pass the End Date before the Start Date. If your script relies on negative numbers to determine if a date is in the past, you must use `@CalcMgrWeeksBetween`, which preserves directionality |
| Rounding Errors in Integers | Using it for array indexing | If you need an exact integer (e.g., `3`) to use in an `@SHIFT` array function or a `FOR` loop, do not use `WeeksDiff`. Because of millisecond precision, it might return `3.0001` or `2.9999` depending on the time of day the timestamp was generated, causing array OutOfBounds errors. Use `@CalcMgrWeeksBetween` when you need strict integers |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrWeeksBetween`](./@CalcMgrWeeksBetween.md) | Calculates the strict integer difference between weeks, rounding down and preserving directionality (allows negative returns) |
| [`@CalcMgrDaysDiff`](./@CalcMgrDaysDiff.md) | Calculates the fractional difference in days rather than fractional weeks |
| [`@CalcMgrExcelYEARFRAC`](./@CalcMgrExcelYEARFRAC.md) | Highly similar fractional concept, but calculates the fractional difference in *Years* (e.g., `1.5` years) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_weeksdiff.html)
