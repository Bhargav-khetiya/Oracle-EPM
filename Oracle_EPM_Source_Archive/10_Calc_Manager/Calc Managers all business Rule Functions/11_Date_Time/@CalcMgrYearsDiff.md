# @CalcMgrYearsDiff

## Overview

`@CalcMgrYearsDiff` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the mathematical **difference in years** between two provided **Java Date Objects**, returning the result as a precise floating-point decimal (a Double).

### Why Does This Function Exist?

While `@CalcMgrYearsBetween` is perfect for strict integer thresholds (e.g., did they hit their exact 5-year anniversary?), it is useless for continuous financial mathematics. 
If an enterprise software contract costs $100,000 annually, and a customer terminates the contract after exactly 1 year and 6 months, using `YearsBetween` will tell you they were active for `1` year, causing you to under-bill them for 6 months. 
`@CalcMgrYearsDiff` solves this by calculating the exact calendar delta and preserving the fractional remainder. It divides the total elapsed days by the exact length of the year, returning a highly precise decimal (e.g., `1.503`). This enables FP&A teams to execute exact, fractional proration logic (e.g., multiplying the annual rate by `1.503`) natively within Essbase.

### When to Use It

- **Fractional Proration**: Calculating exact fractional year utilization (e.g., `2.75` years) for mid-term contract terminations.
- **Accurate Compound Interest**: Passing the exact fractional time ($t$) into complex continuous compounding formulas.
- **Depreciation True-Ups**: Calculating the exact decimal lifespan of an asset that was retired mid-year, ensuring the final depreciation entry perfectly zeros out the balance based on the exact days active.

---

## Category

**Date & Time / Date Differences / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrYearsDiff(date1, date2)
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

Returns the absolute decimal difference in years.
- **Absolute Value (CRITICAL)**: Unlike `YearsBetween`, this function operates using absolute variance. It does NOT matter which date you pass first. `(2018, 2024)` and `(2024, 2018)` will both return `6.0`. It will never return a negative number.
- **Fractional Precision**: Returns numbers like `1.5` or `3.245` (representing exactly 3 years and roughly 3 months).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the two Date Objects.
2. **Delta Extraction**: It extracts the exact milliseconds of both dates and calculates the absolute mathematical difference, effectively stripping any negative directionality.
3. **Fractional Math**: It divides the millisecond delta by the length of the year. (The Java implementation intelligently handles leap year day counts to ensure the fractional precision remains accurate over multi-year spans).
4. **Return**: It passes the resulting precise fractional decimal back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating a Fractional Year Gap

```essbase
/* 
   Assumes Start is Jan 1, 2020. End is July 1, 2021.
   Exactly 1.5 years elapsed. 
   Returns ~1.50.
*/
VAR vYearsElapsed = @CalcMgrYearsDiff(vStartObj, vEndObj);
```

---

## Practical Examples

### Example 1: Pro-Rated Annual Contract Billing

**Scenario**: A SaaS company signs an enterprise customer to a multi-year contract at an `"Annual_Rate"` of $1,000,000. However, the customer negotiates an early termination. The script must calculate exactly how many fractional years the contract was active in order to calculate the final pro-rated invoice amount.

```essbase
FIX("FY25", "Working", @LEVEL0("Customers"))
    
    IF("Annual_Rate" > 0 AND "Termination_Date" != #MISSING)
        
        /* 1. Convert the integer dates into Java Objects */
        VAR vStartObj = @CalcMgrIntegerToDate("Contract_Start_Date");
        VAR vTermObj = @CalcMgrIntegerToDate("Termination_Date");
        
        /* 
           2. Calculate exactly how many fractional years they were active.
           (e.g., 2.5 years)
        */
        VAR vFractionalYears = @CalcMgrYearsDiff(vStartObj, vTermObj);
        
        /* 
           3. Calculate the exact pro-rated lifetime revenue.
           $1,000,000 * 2.5 = $2,500,000
        */
        "Total_Contract_Value" = "Annual_Rate" * vFractionalYears;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrYearsDiff(20200101, 20210701)` | This function strictly requires **Java Date Objects**. If you pass native Essbase integers, the script will crash. Always use `@CalcMgrIntegerToDate` to wrap your integers first |
| Relying on Negative Returns | `IF(Diff < 0)` | Because `YearsDiff` uses absolute variance, it will NEVER return a negative number, even if you pass the End Date before the Start Date. If your script relies on negative numbers to determine if a date is in the past, you must use `@CalcMgrYearsBetween`, which preserves directionality |
| Disagreeing with Bank Logic | Expecting 360-day logic | By default, this function uses the actual Gregorian calendar (Actual/Actual day count basis). If you are building banking or treasury logic that strictly requires 30/360 or Actual/360 day count conventions to calculate interest, you MUST use `@CalcMgrExcelYEARFRAC` instead, as it allows you to explicitly define the financial basis |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrYearsBetween`](./@CalcMgrYearsBetween.md) | Calculates the strict integer difference between years, rounding down and preserving directionality (allows negative returns) |
| [`@CalcMgrExcelYEARFRAC`](./@CalcMgrExcelYEARFRAC.md) | A superior alternative for financial models. It allows you to specify the exact day-count basis (e.g., 30/360) for precise banking compliance |
| [`@CalcMgrMonthsDiff`](./@CalcMgrMonthsDiff.md) | Calculates the fractional difference in months rather than fractional years |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_yearsdiff.html)
