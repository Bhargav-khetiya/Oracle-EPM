# @CalcMgrYearsBetween

## Overview

`@CalcMgrYearsBetween` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the exact **integer number of full years** that exist between two provided **Java Date Objects**.

### Why Does This Function Exist—

When building long-term models—such as workforce tenure analysis, capital asset depreciation, or 10-year strategic plans—business logic often depends on knowing exactly how many years have passed since an initial event. 
If an employee was hired on `20180515` (May 15th, 2018), and today is `20240810` (August 10th, 2024), standard Essbase subtraction (`20240810 - 20180515`) yields `60295`, which is a meaningless integer. 
`@CalcMgrYearsBetween` resolves this by utilizing the Java Calendar engine. By passing the two Date Objects, it mathematically calculates the calendar delta, correctly traversing leap years and month boundaries, and returns exactly how many full, 12-month cycles sit between the two dates (e.g., `6`). This integer can then be used directly to assign employee vesting tiers or calculate annual depreciation schedules.

### When to Use It

- **Workforce Tenure Tracking**: Calculating an employee's exact years of service (e.g., `5` years) to determine if they qualify for a higher vacation accrual tier or a 5-year anniversary bonus.
- **Depreciation Milestones**: Determining exactly how many full years an asset has been in service to trigger specific tax-bracket depreciation rules (like MACRS year-cutoffs).
- **Lease Amortization**: Calculating the elapsed years on a 20-year commercial property lease to dynamically determine remaining liabilities.

---

## Category

**Date & Time / Date Differences / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrYearsBetween(from_date, to_date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | Object | ✅ Yes | The starting Java Date Object (the older date). |
| `to_date` | Object | ✅ Yes | The ending Java Date Object (the newer date). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the pure integer number of full years between the two dates.
- **Directionality (CRITICAL)**: Unlike basic subtraction, this function is NOT absolute. 
  - If `from_date` is BEFORE `to_date` (e.g., 2018 to 2024), it returns a **positive** integer (e.g., `6`).
  - If `from_date` is AFTER `to_date` (e.g., 2024 to 2018), it returns a **negative** integer (e.g., `-6`).
- **Rounding Logic**: This function rounds *down* to the nearest full year based on calendar months and days. If the gap is 1 year and 364 days, it still returns `1` (because the second full year has not yet technically elapsed). It does not return decimals.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the two Date Objects.
2. **Calendar Instantiation**: It converts both objects into `java.util.Calendar` instances.
3. **Component Extraction**: It extracts the Year, Month, and Day from both instances.
4. **Mathematical Delta**: It calculates the Year difference (`Year2 - Year1`).
5. **Boundary Evaluation**: It checks the Month and Day. If the `to_date`'s month/day is *less* than the `from_date`'s month/day (meaning the anniversary has not yet occurred this year), it subtracts 1 from the Year total.
6. **Return**: Passes the resulting strict integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Positive Year Gap

```essbase
/* 
   Assumes Start is Jan 1, 2020. End is June 1, 2024.
   Returns 4. (The 5th year has not completed yet).
*/
VAR vYearsElapsed = @CalcMgrYearsBetween(vStartObj, vEndObj);
```

---

## Practical Examples

### Example 1: Triggering Employee Vesting Bonuses

**Scenario**: A company issues stock options that fully vest after an employee completes exactly 5 years of service. An HR planning model must check every employee's hire date against the current date. If their tenure is `>= 5`, the script triggers a financial vesting event and moves the unvested balance to the vested balance.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    IF("Unvested_Options" > 0 AND "Hire_Date" != #MISSING)
        
        /* 1. Convert the integer dates into Java Objects */
        VAR vHireObj = @CalcMgrIntegerToDate("Hire_Date");
        VAR vCurrentObj = @CalcMgrIntegerToDate("Current_Date");
        
        /* 
           2. Calculate exactly how many full years they have worked.
           (e.g., Hired Jan 2018. Current 2024. Returns 6).
        */
        VAR vTenureYears = @CalcMgrYearsBetween(vHireObj, vCurrentObj);
        
        /* 
           3. Evaluate the Tenure threshold.
        */
        IF(vTenureYears >= 5)
            
            /* The 5-year cliff has been met. Move the balance. */
            "Vested_Options" = "Vested_Options" + "Unvested_Options";
            "Unvested_Options" = 0;
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrYearsBetween(20180101, 20240101)` | This is the most common error. This function strictly requires **Java Date Objects**. If you pass native Essbase integers, the script will crash or calculate massive negative numbers. Always use `@CalcMgrIntegerToDate` first |
| Swapping Parameters | Passing `(End_Date, Start_Date)` | Order is critical. If you accidentally pass the newer date first, the function will output a **negative number**. If you are checking `IF(Tenure > 5)`, a `-5` will evaluate to false, skipping the calculation. Always pass the older date first, or use `@ABS()` |
| Anniversaries on Leap Days | Hired Feb 29th | The Java engine perfectly handles leap years. If you were hired on Feb 29th 2020, and the current year is 2021, the engine mathematically considers your 1-year anniversary to be March 1st, 2021. If you run the check on Feb 28th 2021, it correctly returns `0` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrYearsDiff`](./@CalcMgrYearsDiff.md) | The fractional counterpart. Returns precise decimals (e.g., `4.5` years) instead of rounding down to the nearest integer |
| [`@CalcMgrMonthsBetween`](./@CalcMgrMonthsBetween.md) | Calculates the strict integer difference between months rather than full years |
| [`@CalcMgrExcelYEARFRAC`](./@CalcMgrExcelYEARFRAC.md) | Calculates the fractional difference in years, but allows you to specify custom financial day-count basis logic (like 30/360 or Actual/360) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_yearsbetween.html)
