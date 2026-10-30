# @CalcMgrMonthsBetween

## Overview

`@CalcMgrMonthsBetween` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the exact **integer number of full months** that exist between two provided **Java Date Objects**.

### Why Does This Function Exist?

When building amortization schedules, depreciation models, or employee vesting periods, administrators must calculate how many months a contract has been active. 
If an asset was purchased on `20230515` (May 15th, 2023) and today is `20240810` (August 10th, 2024), standard Essbase subtraction (`20240810 - 20230515`) yields `10295`, which is mathematically useless. You cannot divide a balance by `10295` to get a monthly rate. 
`@CalcMgrMonthsBetween` resolves this by relying on the Java Calendar engine. By passing two Date Objects (a start date and an end date), it mathematically calculates the calendar delta, correctly accounting for leap years, differing month lengths, and year boundaries, and returns exactly how many full months sit between the two dates (e.g., `15`). This integer can then be used directly as a denominator in financial models.

### When to Use It

- **Amortization Scheduling**: Calculating the remaining months on a prepaid expense to dynamically spread the remaining balance across future periods.
- **Depreciation**: Determining if an asset has reached the end of its useful life by comparing the `Purchase_Date` against the `Current_Date`.
- **Contract Billing**: Determining how many months a SaaS customer should be retroactively billed for if their start date was in the past.

---

## Category

**Date & Time / Date Differences / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrMonthsBetween(from_date, to_date)
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

Returns the pure integer number of full months between the two dates.
- **Directionality (CRITICAL)**: Unlike basic subtraction, this function is NOT absolute. 
  - If `from_date` is BEFORE `to_date` (e.g., May to August), it returns a **positive** integer (e.g., `3`).
  - If `from_date` is AFTER `to_date` (e.g., August to May), it returns a **negative** integer (e.g., `-3`).
- **Rounding Logic**: This function rounds *down* to the nearest full month based on calendar days. If the gap is 1 month and 29 days, it still returns `1`. It does not return decimals.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the two Date Objects.
2. **Calendar Instantiation**: It converts both objects into `java.util.Calendar` instances.
3. **Component Extraction**: It extracts the Year and Month from both instances.
4. **Mathematical Delta**: It calculates the difference: `((Year2 - Year1) * 12) + (Month2 - Month1)`.
5. **Day Evaluation**: It checks the actual day of the month. If `to_date`'s day is *less* than `from_date`'s day, it subtracts 1 from the total to ensure only *completed* months are counted.
6. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Positive Month Gap

```essbase
/* 
   Assumes Start is Jan 1, 2024. End is April 1, 2024.
   Returns 3. 
*/
VAR vMonthsElapsed = @CalcMgrMonthsBetween(vStartObj, vEndObj);
```

---

## Practical Examples

### Example 1: Straight-Line Software Amortization

**Scenario**: A company pays `$120,000` upfront for a 3-year software license. The `Start_Date` and `End_Date` are stored as `YYYYMMDD` integers. The script must calculate exactly how many months the contract spans, and divide the total cost by that integer to calculate the monthly amortization expense.

```essbase
FIX("Working", @LEVEL0("Software_Contracts"))
    
    IF("Total_Contract_Value" > 0)
        
        /* 1. Convert the integer dates into Java Objects */
        VAR vStartObj = @CalcMgrIntegerToDate("Contract_Start_Date");
        VAR vEndObj = @CalcMgrIntegerToDate("Contract_End_Date");
        
        /* 
           2. Calculate the total number of months the contract covers.
           (e.g., Jan 1 2024 to Dec 31 2026 = 36 months).
           We add 1 because standard delta math (End - Start) excludes the final month. 
        */
        VAR vTotalMonths = @CalcMgrMonthsBetween(vStartObj, vEndObj) + 1;
        
        /* 3. Calculate the Monthly Amortization Expense */
        "Monthly_Expense" = "Total_Contract_Value" / vTotalMonths;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrMonthsBetween(20240101, 20240501)` | This is the most common error. This function strictly requires **Java Date Objects**. If you pass native Essbase integers, the script will crash or calculate massive negative numbers. Always use `@CalcMgrIntegerToDate` first |
| Swapping Parameters | Passing `(End_Date, Start_Date)` | Order is critical. If you accidentally pass the newer date first, the function will output a **negative number**. If you divide an expense by `-36` instead of `36`, your entire financial model will invert. Always pass the older date first, or use `@ABS()` to force the result positive |
| Forgetting Inclusive Offsets | Expecting Jan 1 to Jan 31 to equal 1 | If you pass Jan 1 and Jan 31 of the same year, `MonthsBetween` will return `0` because a full calendar month (to Feb 1) has not elapsed. If you are using this function to count total active periods (e.g., spreading data across 12 periods), you generally need to add `+1` to the result, as shown in the Example |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrMonthsDiff`](./@CalcMgrMonthsDiff.md) | Practically identical function, but behaves slightly differently on fractional boundaries depending on the EPM version. Generally used interchangeably |
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | Calculates the exact number of days (e.g., `105`) between two dates rather than months |
| [`@CalcMgrIntegerToDate`](../15_CalcMgr_Utility/@CalcMgrConvertDateToJavaDate.md) | The mandatory wrapper required to convert Essbase integer dates into the objects required by this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_monthsbetween.html)
