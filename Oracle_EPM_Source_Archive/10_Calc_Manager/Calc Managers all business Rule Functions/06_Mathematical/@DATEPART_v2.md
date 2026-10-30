# @DATEPART

## Overview

`@DATEPART` is a **native Essbase date extraction function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a **native Essbase Date Integer** (a Unix epoch timestamp representing seconds since Jan 1, 1970) and mathematically extracts a specific calendar component from it, such as the exact Year, Month, Day of the Month, or Day of the Week.

### Why Does This Function Exist?

Standard Essbase block storage is incredibly efficient, but it does not natively understand complex calendar concepts. If an HR system loads a `Hire_Date` into Essbase as a Unix timestamp (`1715731200`), the database just sees a massive 10-digit number. 
If an administrator needs to write a rule that says "Give all employees hired in the month of May a 5% bonus," they cannot execute that logic against the number `1715731200`. 
`@DATEPART` solves this by bridging the gap between timestamps and human calendars. By passing the timestamp and a specific flag (like `DP_MONTH`), Essbase mathematically dissects the seconds, analyzes the Gregorian calendar, and returns the pure integer `5` (for May). This allows administrators to build dynamic seasonal or annual logic based on highly compressed timestamp data.

### When to Use It

- **Seasonal Logic**: Extracting the `DP_MONTH` from a project start date to apply different seasonal overhead assumptions (e.g., Summer projects vs Winter projects).
- **Annual True-Ups**: Extracting the `DP_YEAR` from a Unix timestamp to see if an asset was purchased in the current fiscal year before applying depreciation.
- **Day-of-Week Modeling**: Extracting the `DP_WEEKDAY` to identify if a transaction occurred on a weekend (Saturday/Sunday) to apply overtime rates.

---

## Category

**Date & Time / Native Essbase Date Math / Essbase Native Functions**

---

## Syntax

```essbase
@DATEPART(date, date_part_flag)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Numeric | ✅ Yes | The Unix Epoch timestamp integer you want to analyze (e.g., `1715731200`). |
| `date_part_flag` | Keyword | ✅ Yes | A strict keyword defining what piece of the calendar you want to extract: <br>`DP_YEAR` = The 4-digit Year (e.g., `2024`) <br>`DP_MONTH` = The Month (1-12) <br>`DP_DAY` = The Day of the Month (1-31) <br>`DP_WEEKDAY` = The Day of the Week (1 = Sunday, 7 = Saturday) <br>`DP_DAYOFYEAR` = The cumulative day of the year (1-366) |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns a pure integer representing the requested component.
- **1-Indexed**: Unlike Java functions (which often treat January as `0`), `@DATEPART` is natively 1-indexed. January = `1`. Sunday = `1`. 
- **Missing Data Handling**: If the input date is `#MISSING`, the function will usually return `#MISSING`, but depending on the block structure, it may attempt to evaluate `0` (which is Jan 1, 1970). Always validate that data exists before running.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: Essbase evaluates the Unix integer.
2. **Flag Interpretation**: It checks the requested `date_part_flag`.
3. **Algorithm Execution**: 
   - It divides the seconds to determine the exact date on the Gregorian calendar (accounting for leap years).
   - It isolates the specific component requested by the flag.
4. **Return**: It returns that singular integer (e.g., `2024` or `5`) back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the Year

```essbase
/* 
   Assumes vTimestamp is a valid Unix epoch date.
   Returns the 4-digit year (e.g., 2024).
*/
VAR vYear = @DATEPART(vTimestamp, DP_YEAR);
```

---

## Practical Examples

### Example 1: Seasonal Bonus Logic Based on Hire Month

**Scenario**: A company offers a signing bonus, but the bonus amount changes based on the season. If hired in Q1 (Months 1-3), the bonus is $5,000. If hired in Q2 (Months 4-6), the bonus is $4,000. The `Hire_Date` is stored as a Unix timestamp. The script must extract the month integer to route the logic.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    IF("Hire_Date" != #MISSING)
        
        /* 
           1. Dissect the Unix Timestamp and extract just the Month integer.
           (e.g., If hired in May, vHireMonth becomes 5).
        */
        VAR vHireMonth = @DATEPART("Hire_Date", DP_MONTH);
        
        /* 
           2. Route the bonus logic based on the extracted month.
        */
        IF(vHireMonth >= 1 AND vHireMonth <= 3)
            "Signing_Bonus" = 5000;
        ELSEIF(vHireMonth >= 4 AND vHireMonth <= 6)
            "Signing_Bonus" = 4000;
        ELSE
            "Signing_Bonus" = 2000;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@DATEPART(20240515, DP_MONTH)` | This is the most catastrophic mistake. `@DATEPART` DOES NOT understand `YYYYMMDD`. It assumes the number is seconds since 1970. If you pass `20240515`, Essbase thinks you mean a date in the year 1970, and will extract the month for that 1970 date (which is usually January). If your data is `YYYYMMDD`, you MUST use `@CalcMgrGetDatePart` instead, or manually extract the month using integer division: `@INT(Date / 100) - (@INT(Date / 10000) * 100)` |
| Confusing `DP_DAY` with `DP_WEEKDAY` | Using `DP_DAY` to find Mondays | `DP_DAY` returns the day of the *month* (e.g., the 15th). `DP_WEEKDAY` returns the day of the *week* (e.g., 2 = Monday). Ensure you are using the correct flag for your specific business logic |
| Java 0-Index Confusion | Expecting Monday to be 1 | Because `@DATEPART` is a native Essbase function, it uses 1-indexed calendars (Jan = 1, Sunday = 1). Many modern Calc Manager Java functions use 0-indexed calendars (Jan = 0). Do not mix up the indexing logic if you are transitioning between native Essbase date math and Java date math in the same script |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetDatePart`](../11_Date_Time/@CalcMgrGetDatePart.md) | The modern Java equivalent. It natively handles `YYYYMMDD` inputs (via conversion) and is vastly superior if you are not using Unix timestamps |
| [`@DATEDIFF`](./@DATEDIFF.md) | The companion native function used to mathematically compare two Unix timestamps |
| [`@DATEROLL`](./@DATEROLL.md) | Modifies a Unix timestamp by adding or subtracting calendar components (like Months or Years) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — DATEPART](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/datepart.html)
