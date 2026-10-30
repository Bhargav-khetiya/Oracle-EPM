# @CalcMgrGetDayOfYear

## Overview

`@CalcMgrGetDayOfYear` is a **custom Calc Manager date extraction wrapper function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a unified **Java Date Object** (or Java Timestamp Object) and precisely extracts the **absolute Day of the Year** (the Julian day), returning it as a pure integer (e.g., `1` through `365`, or `366` in a leap year).

### Why Does This Function Exist?

While identifying the Day of the Month (`1-31`) is useful for payroll and rent, manufacturing, logistics, and agriculture industries operate on absolute "Days of the Year" (Julian days). A shipping container might be logged to arrive on "Day 215".
Calculating this manually in Essbase is nearly impossible. You have to evaluate the current month, manually sum all the days in the preceding months, evaluate if the current year is a leap year to add a day to February, and then add the current day of the month. 
`@CalcMgrGetDayOfYear` completely eliminates this complexity. It queries the Java Calendar engine, which natively tracks leap years and absolute offsets, and instantly returns the exact `1-366` integer for the specified date object, allowing your logistics scripts to execute flawlessly.

### When to Use It

- **Manufacturing & Logistics**: Validating delivery SLA compliance based on absolute Julian day tracking.
- **Retail Seasonality Modeling**: Comparing daily sales velocity on "Day 300" of this year vs. "Day 300" of last year, regardless of what day of the week it landed on.
- **Proration Models**: Quickly determining what fraction of the year has elapsed (e.g., `DayOfYear / 365`) to calculate YTD revenue recognition.

---

## Category

**Date & Time / Component Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetDayOfYear(date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The Java Date/Timestamp Object to be dissected. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the absolute Day of the Year as a pure integer.
- E.g., January 1st returns `1`.
- E.g., December 31st returns `365` (or `366` if it is a leap year).
- **Leap Year Aware**: The underlying Java engine automatically knows if the Year contained in the object is a leap year. If you pass an object for March 1st, 2024 (leap year), it returns `61`. If you pass March 1st, 2023, it returns `60`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Date Object.
2. **Object Interrogation**: It calls the native Java `Calendar.get(Calendar.DAY_OF_YEAR)` method directly against the object in memory.
3. **Execution**: It extracts the integer value, fully accounting for the specific year's leap calendar.
4. **Return**: Passes the finalized integer back to Essbase for immediate use in mathematical logic.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the Day of the Year from Today

```essbase
/* Assumes Today is February 1, 2024. Returns 32. */
VAR vJulianDay = @CalcMgrGetDayOfYear(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Calculating Year-To-Date (YTD) Revenue Proration

**Scenario**: A SaaS company signs an enterprise contract for `$1.2M` per year. The company uses daily revenue recognition. If they want to forecast their exact Recognized YTD Revenue based on today's date, they must divide the Annual Value by 365 (or 366), and then multiply it by the exact number of days that have elapsed so far this year.

```essbase
FIX("FY25", "Working", @LEVEL0("Customers"))
    
    IF("Annual_Contract_Value" > 0)
        
        /* 1. Get Today's Date as a Java Object */
        VAR vTodayObj = @CalcMgrGetCurrentDate();
        
        /* 
           2. Extract specifically the absolute Day of the Year. 
           (e.g., June 30th returns 181).
        */
        VAR vElapsedDays = @CalcMgrGetDayOfYear(vTodayObj);
        
        /* 
           3. Extract the total days in the current year.
           (Checking if it's 365 or 366).
           We construct a Dec 31st object for the current year, and ask for its Day of Year.
        */
        VAR vCurrentYear = @CalcMgrGetDatePart(vTodayObj, "year");
        VAR vDec31Obj = @CalcMgrGetCustomDate(vCurrentYear, 11, 31);
        VAR vTotalDaysInYear = @CalcMgrGetDayOfYear(vDec31Obj);
        
        /* 
           4. Calculate the Recognized Revenue YTD.
           Formula: Annual Value * (Elapsed Days / Total Days)
        */
        "Recognized_Revenue_YTD" = "Annual_Contract_Value" * (vElapsedDays / vTotalDaysInYear);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a YYYYMMDD Integer | `@CalcMgrGetDayOfYear(20241215)` | This function explicitly requires a **Java Date Object**. If you pass a native Essbase `YYYYMMDD` integer, the Java engine will fail or return a completely invalid number. You must convert it to an object first using `@CalcMgrIntegerToDate` |
| Confusing with Day of Month | Expecting `31` for Dec 31 | This function strictly returns the cumulative Day of the *Year* (`1-366`). If you need the Day of the Month (e.g., December 31st = `31`), you must use `@CalcMgrGetDay` instead |
| Static Leap Year Math | Hardcoding `/ 365` | Because `GetDayOfYear` adjusts for leap years dynamically, if you use the output of this function to calculate a percentage (e.g., `DayOfYear / 365`), your formula will mathematically break during a leap year (e.g., `366 / 365 = >100%`). Always dynamically calculate the denominator as shown in Example 1 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetDatePart`](./@CalcMgrGetDatePart.md) | The underlying generic extraction function. `@CalcMgrGetDatePart(date, "dayofyear")` does the exact same thing as this function |
| [`@CalcMgrGetDay`](./@CalcMgrGetDay.md) | Extracts strictly the Day of the Month (`1-31`) |
| [`@CalcMgrIntegerToDate`](./@CalcMgrIntegerToDate.md) | Converts a standard `YYYYMMDD` integer into the Java Date Object required by this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getdayofyear.html)
