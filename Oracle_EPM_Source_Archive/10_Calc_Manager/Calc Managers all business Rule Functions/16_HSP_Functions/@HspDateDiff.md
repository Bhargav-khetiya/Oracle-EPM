# @HspDateDiff

## Overview

`@HspDateDiff` is a **Hyperion Planning (HSP) custom date function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It calculates the mathematical difference (in days) between two **`YYYYMMDD` formatted integers** (e.g., `20240515`). 

### Why Does This Function Exist—

Historically, Essbase only understood dates as Unix timestamps (seconds since 1970). If an administrator loaded a user-friendly `YYYYMMDD` date (like `20240515`) into an account, and tried to subtract it from `20240101` using native math, Essbase would return `404` (basic integer subtraction), which is mathematically meaningless for calendars (May 15th is not 404 days after Jan 1st). 
The native `@DATEDIFF` function exists, but it ONLY accepts Unix timestamps. 
`@HspDateDiff` was introduced by the Hyperion Planning layer to bridge this gap. It natively intercepts two `YYYYMMDD` integers, translates them into true calendar dates in memory, calculates the exact days between them (accounting for leap years and month lengths), and returns the correct integer.

*Note: In modern EPM Cloud (Calc Manager), this function has been almost entirely superseded by the Java-based `@CalcMgrDaysBetween` function, which is faster and supports far more robust error handling. `@HspDateDiff` is largely considered legacy, but is still fully supported for backward compatibility.*

### When to Use It

- **Legacy Model Migration**: Maintaining older On-Premise Planning applications that heavily relied on HSP date functions.
- **Basic Day Counts**: Calculating the number of days a temporary contractor has been active by comparing their `Start_Date` (in `YYYYMMDD` format) against `@HspDateToString(@TODAY())`.
- **Accrual Proration**: Finding the exact number of days between an asset purchase date and the end of the month to calculate fractional depreciation.

---

## Category

**Date & Time / Date Differences / Custom HSP Functions**

---

## Syntax

```essbase
@HspDateDiff(date1, date2)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date1` | Numeric | ✅ Yes | The first date, strictly formatted as a `YYYYMMDD` integer (e.g., `20240515`). |
| `date2` | Numeric | ✅ Yes | The second date, strictly formatted as a `YYYYMMDD` integer (e.g., `20241231`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the exact number of days between the two dates.
- **Directionality**: This function generally calculates `date1 - date2`.
  - If `date1` is the NEWER date (e.g., `20241231`) and `date2` is the OLDER date (e.g., `20240101`), it usually returns a **positive** number (e.g., `365`).
  - If you invert the order, it returns a negative number. *(Always test directionality in your specific patch version, as legacy functions occasionally alter signs).*

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine evaluates the two input integers, validating that they conform to the `YYYYMMDD` structure.
2. **Calendar Conversion**: It splits the integers (e.g., `2024`, `05`, `15`) and maps them to an internal Gregorian calendar array.
3. **Delta Math**: It calculates the exact days between the two calendar plots, accounting for February 29th leap days.
4. **Return**: It returns the integer delta back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Standard YYYYMMDD Difference

```essbase
/* 
   Calculates days between May 15, 2024 and May 1, 2024.
   Returns 14.
*/
VAR vDaysElapsed = @HspDateDiff(20240515, 20240501);
```

---

## Practical Examples

### Example 1: Calculating Project Aging with YYYYMMDD

**Scenario**: A project management cube stores `Project_Launch_Date` in a standard `YYYYMMDD` account. The administrator needs to know exactly how many days have passed since the launch to determine if the project is "Overdue". Since `@TODAY()` returns a Unix timestamp, the script must first convert Today into `YYYYMMDD`, and then use `@HspDateDiff` to compare them.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    IF("Project_Launch_Date" != #MISSING)
        
        /* 
           1. Generate Today's date, but we must force it into YYYYMMDD format 
           so it matches our stored data format.
        */
        VAR vTodayYYYYMMDD = @HspDateToString(@TODAY());
        
        /* 
           2. Calculate the difference in days. 
           We put the newer date (Today) first to yield a positive number.
        */
        "Total_Days_Active" = @HspDateDiff(vTodayYYYYMMDD, "Project_Launch_Date");
        
        /* 
           3. Execute logic based on the aging.
        */
        IF("Total_Days_Active" > 90)
            "Project_Status" = -1; /* Flag as Overdue */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Unix Timestamps | `@HspDateDiff(@TODAY(), "Launch_Date")` | This function STRICTLY requires `YYYYMMDD` integers. `TODAY()` outputs a massive 10-digit Unix timestamp (e.g., `1715731200`). If you pass a Unix timestamp into this function, it will attempt to parse it as a year (Year `1715`, Month `73`, Day `12`), which is an invalid calendar date, causing the function to fail or return `#MISSING`. You must convert timestamps using `@HspDateToString` first |
| Relying on Legacy Functions for New Builds | Using `@Hsp` instead of `@CalcMgr` | If you are building a *brand new* application, do not use this function. Use the modern Java `@CalcMgrDaysBetween` function. The Java engine is significantly more robust, handles fractional days better, and has explicit error logging. Use `@HspDateDiff` only when maintaining legacy scripts |
| Missing Error Trapping | Comparing `#MISSING` to a Date | If an account is empty (`#MISSING`), Essbase treats it as `0`. If you try to calculate the difference between `20240515` and `0`, the function will attempt to parse `0` as a calendar date, which will fail. Always wrap date math in `IF("Account" != #MISSING)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | The modern, Java-based replacement for this function. It requires wrapping inputs in `@CalcMgrIntegerToDate`, but is far more stable |
| [`@DATEDIFF`](./@DATEDIFF.md) | The native Essbase equivalent that STRICTLY calculates differences between Unix timestamps (seconds since 1970) |
| [`@HspDateToString`](./@HspDateToString.md) | The companion function used to convert Unix timestamps (like `@TODAY()`) into `YYYYMMDD` format so they can be consumed by `@HspDateDiff` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspdatediff.html)
