# @CalcMgrExcelEDATE

## Overview

`@CalcMgrExcelEDATE` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `EDATE` function directly inside an Essbase calculation script. 
It takes a starting date and calculates a new date that is exactly a specified number of months in the **future** (or in the **past**), while preserving the exact day of the month. 

### Why Does This Function Exist—

When forecasting contract renewals, warranty expirations, or employee vesting schedules, you often need to shift a date exactly *X* months forward. If an employee is hired on January 15th, and they have a 6-month probationary period, their probation ends exactly on July 15th. 
Attempting to shift dates mathematically in Essbase by adding days (e.g., `Start_Date + 180`) is highly inaccurate because months have different numbers of days. Adding exactly 6 months means you must manipulate the month component directly and handle the year rollover (e.g., if you add 3 months to November, it becomes February of the next year). 
Furthermore, you must handle edge cases where the day doesn't exist in the target month (e.g., shifting January 31st forward by 1 month results in February 28th/29th). `@CalcMgrExcelEDATE` offloads this complex calendar math to the Java engine, shifting the date perfectly and safely.

### When to Use It

- **HR Models**: Calculating precise probationary end dates, vesting dates, or review dates based on an employee's hire date.
- **Contract Planning**: Shifting a subscription start date forward by 12, 24, or 36 months to generate exact renewal dates.
- Whenever you need to migrate an Excel spreadsheet containing the `EDATE` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelEDATE(start_date, months)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | Integer | ✅ Yes | The starting date. Can be passed as an Excel Serial Date or a standard `YYYYMMDD` Essbase integer. |
| `months` | Numeric | ✅ Yes | The number of months to shift. Pass a positive number to shift into the future, or a negative number to shift into the past. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the shifted date.
- **Crucial Note**: The function typically returns the date in the exact same format it was provided. If you pass a Serial Date, you get a Serial Date. If you pass `YYYYMMDD`, you get `YYYYMMDD`. (However, to be safe, always wrap the output in `@CalcMgrExcelToDate` if you strictly need Essbase format, just in case the Java library defaults to Serial).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the date and the shift integer.
2. **Calendar Math**: It initializes a calendar object and uses the native `add(Calendar.MONTH, months)` Java method.
3. **Rollover Handling**: The engine automatically rolls the year forward or backward if the month shift crosses the December/January boundary.
4. **Boundary Truncation**: If the source date is the 31st, and the target month only has 30 days, the engine truncates the day down to the 30th (e.g., shifting Oct 31 by 1 month yields Nov 30).
5. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Shifting Forward (Probation End Date)

```essbase
/* 
   Start: Jan 15, 2024 (20240115)
   Shift: 6 Months Forward
   Result: 20240715 (July 15, 2024)
*/
"Probation_End_Date" = @CalcMgrExcelEDATE(20240115, 6);
```

### Variant 2: Shifting Backward (Historical Baseline)

```essbase
/* 
   Start: March 1, 2024
   Shift: -12 Months (1 Year backward)
   Result: 20230301
*/
"Prior_Year_Date" = @CalcMgrExcelEDATE(20240301, -12);
```

---

## Practical Examples

### Example 1: Handling End-of-Month Edge Cases (Jan 31 to Feb)

**Scenario**: You have a 1-month rolling software subscription. A user subscribes on January 31, 2024 (a leap year). If you blindly add 30 days, you might end up in March. You use `EDATE` to shift exactly 1 month.

```essbase
FIX("FY25", "Working", @LEVEL0("Subscriptions"))
    
    IF("Sub_Start_Date" != #MISSING)
        
        /* 
           Sub_Start_Date = 20240131
           We shift forward 1 month. 
           Since February 31st doesn't exist, the Java engine intelligently 
           truncates it to the last valid day of that month (February 29).
        */
        "Next_Billing_Date" = @CalcMgrExcelEDATE("Sub_Start_Date", 1);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Three-Year Warranty Expiration

**Scenario**: A manufacturing model tracks the `"Ship_Date"` of heavy machinery. Every machine comes with a strict 36-month warranty. You need to calculate the exact `"Warranty_Exp_Date"` to forecast future servicing liabilities.

```essbase
FIX("FY25", "Working", @LEVEL0("Machinery"))
    
    IF("Ship_Date" != #MISSING)
        
        /* Shift the ship date forward by exactly 36 months */
        "Warranty_Exp_Date" = @CalcMgrExcelEDATE("Ship_Date", 36);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatching Formats | Passing `20241025` but expecting a Serial Date | The EPM Calc Manager Excel wrapper attempts to return the date in the same format it was passed. If you need absolute certainty that the output is an Essbase integer (`YYYYMMDD`), explicitly cast it: `@CalcMgrExcelToDate(@CalcMgrExcelEDATE(...))` |
| Using EDATE for "End of Month" logic | Shifting Jan 15 and expecting Jan 31 | `EDATE` explicitly tries to preserve the *exact day* (15th stays 15th). If your goal is actually to shift months and then force the date to the very last day of that new month, you must use `@CalcMgrExcelEOMONTH` instead |
| Passing Decimals | `@CalcMgrExcelEDATE(Date, 2.5)` | You cannot shift a date by a fractional month. The Java engine will truncate `2.5` to `2`. Only pass whole integers for the month parameter |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelEOMONTH`](./@CalcMgrExcelEOMONTH.md) | Shifts the date forward by `X` months, but forces the day to the *last day* of the target month (e.g., shifting Jan 15 forward 1 month yields Feb 28, not Feb 15) |
| [`@CalcMgrExcelDATE`](./@CalcMgrExcelDATE.md) | Manually constructs a date from individual Year, Month, Day integers |
| [`@CalcMgrDateDiff`](./@CalcMgrDateDiff.md) | Standard Essbase function for calculating the difference between two dates |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceledate.html)
