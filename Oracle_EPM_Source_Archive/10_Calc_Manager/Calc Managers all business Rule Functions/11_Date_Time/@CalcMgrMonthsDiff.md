# @CalcMgrMonthsDiff

## Overview

`@CalcMgrMonthsDiff` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the mathematical **difference in months** between two provided **Java Date Objects**, returning the result as a precise floating-point decimal (a Double).

### Why Does This Function Exist?

While `@CalcMgrMonthsBetween` is perfect for calculating integer-based amortization schedules (e.g., a contract lasts exactly `36` months), it fails entirely when dealing with fractional accounting. 
If an employee starts on January 15th, and you run a report on March 1st, they haven't worked 2 full months. They have worked exactly `1.5` months. If you use `MonthsBetween`, the engine rounds down and tells you they worked `1` month, causing your HR accrual models to under-allocate payroll taxes.
`@CalcMgrMonthsDiff` solves this by calculating the exact calendar delta and preserving the fractional remainder. It divides the remaining days by the length of the specific month, returning a highly precise decimal (e.g., `1.516`). This allows FP&A teams to execute exact, day-level proration logic without having to manually calculate leap years or variable month lengths.

### When to Use It

- **Fractional Proration**: Calculating exact fractional month utilization (e.g., `2.75` months) for partial-period SaaS subscriptions.
- **Accurate HR Accruals**: Determining the exact tenure of an employee to calculate pro-rated bonus payouts.
- **Depreciation True-Ups**: Calculating the exact decimal lifespan of an asset that was retired mid-month, ensuring the final depreciation entry perfectly zeroes out the balance.

---

## Category

**Date & Time / Date Differences / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrMonthsDiff(date1, date2)
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

Returns the absolute decimal difference in months.
- **Absolute Value (CRITICAL)**: Unlike `MonthsBetween`, this function operates using absolute variance. It does NOT matter which date you pass first. `(Jan, March)` and `(March, Jan)` will both return `2.0`. It will never return a negative number.
- **Fractional Precision**: Returns numbers like `1.5` or `3.784`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the two Date Objects.
2. **Delta Extraction**: It extracts the exact milliseconds of both dates and calculates the absolute difference, effectively ignoring directionality.
3. **Integer Month Math**: It calculates how many full months exist between the two periods.
4. **Fractional Day Math**: It takes the remaining days, queries the calendar to determine exactly how many days are in the current specific boundary month (e.g., 28 for Feb, 31 for March), and divides the remainder to create a precise decimal.
5. **Return**: Passes the resulting Double back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating a Fractional Month Gap

```essbase
/* 
   Assumes Start is Jan 1, 2024. End is Feb 15, 2024.
   Because Feb has 29 days in 2024, 14 days / 29 = 0.482.
   Returns 1.482.
*/
VAR vMonthsElapsed = @CalcMgrMonthsDiff(vStartObj, vEndObj);
```

---

## Practical Examples

### Example 1: Pro-Rated Bonus Accrual

**Scenario**: An HR model accrues annual bonuses for executives. However, the executive must work the full year to get 100%. If they are hired mid-year, the bonus is pro-rated based on exactly how many months they worked. The script compares their `Hire_Date` to the `Fiscal_Year_End` to determine their fractional tenure.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    IF("Bonus_Target_Amount" > 0 AND "Hire_Date" != #MISSING)
        
        /* 1. Convert the integer dates into Java Objects */
        VAR vHireDateObj = @CalcMgrIntegerToDate("Hire_Date");
        VAR vYearEndObj = @CalcMgrIntegerToDate("Fiscal_Year_End");
        
        /* 
           2. Calculate exactly how many fractional months they worked this year.
           (e.g., Hired July 15th. Total Months = 5.5)
        */
        VAR vTenureMonths = @CalcMgrMonthsDiff(vHireDateObj, vYearEndObj);
        
        /* 
           3. Cap the tenure at 12 months (in case they were hired years ago).
        */
        IF(vTenureMonths > 12)
            vTenureMonths = 12;
        ENDIF
        
        /* 
           4. Calculate the pro-rated percentage and the final bonus.
        */
        VAR vProRataPct = vTenureMonths / 12;
        "Accrued_Bonus" = "Bonus_Target_Amount" * vProRataPct;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrMonthsDiff(20240101, 20240501)` | This function strictly requires **Java Date Objects**. If you pass native Essbase integers, the script will crash. Always use `@CalcMgrIntegerToDate` to wrap your integers first |
| Relying on Negative Returns | `IF(Diff < 0)` | Because `MonthsDiff` uses absolute variance, it will NEVER return a negative number, even if you pass the End Date before the Start Date. If your script relies on negative numbers to determine if a date is in the past, you must use `@CalcMgrMonthsBetween`, which preserves directionality |
| Rounding Errors in Integers | Using it for array indexing | If you need an exact integer (e.g., `3`) to use in an `@SHIFT` array function or a `FOR` loop, do not use `MonthsDiff`. It will return `3.001` or `2.999` depending on time-of-day offsets, causing array errors. Use `@CalcMgrMonthsBetween` when you need strict integers |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrMonthsBetween`](./@CalcMgrMonthsBetween.md) | Calculates the strict integer difference between months, rounding down and preserving directionality (allows negative returns) |
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | Calculates the absolute difference in days rather than fractional months |
| [`@CalcMgrExcelYEARFRAC`](./@CalcMgrExcelYEARFRAC.md) | Highly similar concept, but calculates the fractional difference in *Years* (e.g., `1.5` years) rather than months, perfectly mimicking Microsoft Excel |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_monthsdiff.html)
