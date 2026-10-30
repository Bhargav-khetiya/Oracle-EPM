# @CalcMgrGetDatePart

## Overview

`@CalcMgrGetDatePart` is a **custom Calc Manager date extraction function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a scalpel, dissecting a unified **Java Date Object** and extracting one specific calendar component (such as the Year, the Month, the Day, or even the Last Day of the Month), returning it as a usable integer.

### Why Does This Function Exist?

Calc Manager's advanced functions (like `GetCurrentDate` or `GetCustomDate`) deal entirely in Java Date Objects. While these objects are incredibly powerful for calculating exact day differences or validating leap years, they are completely unreadable to standard Essbase arithmetic and cannot be saved into a database cell.
If you use `@CalcMgrGetCurrentDate()` to find today's date, but you only want to know what the *Month* is so you can route data into the `"Jan"` or `"Feb"` member, you must crack the Java Object open. 
`@CalcMgrGetDatePart` does exactly this. It queries the Java Calendar architecture directly, pulls out the specific integer component you requested (e.g., returning `1` for February), and passes that pure integer back into the Essbase calc script, allowing you to execute dynamic cross-dimensional IF statements or save the integer directly to the database.

### When to Use It

- **Dynamic Member Routing**: Extracting the Month integer from a Java Date Object to dynamically map data into the correct period in the Time dimension.
- **End-of-Month Calculations**: Using the `"lastdayofmonth"` part to instantly determine if the current month has 28, 30, or 31 days.
- **Data Conversion**: Shredding a Java Date Object into Year, Month, and Day integers so they can be mathematically recombined into a standard `YYYYMMDD` integer for storage.

---

## Category

**Date & Time / Component Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetDatePart(date, date_part_ex)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The Java Date/Timestamp Object to be dissected. |
| `date_part_ex` | String | ✅ Yes | A text string specifying exactly which part to extract. Valid options: <br>`"year"` <br>`"month"` <br>`"day"` <br>`"dayofyear"` <br>`"weekday"` <br>`"week"` <br>`"lastdayofmonth"` |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the requested component as an integer.
- **CRITICAL NOTE ON MONTHS**: Unlike Java's internal 0-indexed calendar (where Jan = 0), this specific Calc Manager extraction function translates the output back into human-readable **1-indexed** integers. If you extract the `"month"` of February, it returns `2`, NOT `1`.
- `"weekday"`: Sunday = 1, Saturday = 7.
- `"lastdayofmonth"`: Returns the total number of days in that specific month (e.g., `31` or `28`), dynamically accounting for leap years.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Date Object and the string keyword.
2. **Keyword Routing**: It evaluates the string (e.g., `"month"`) and calls the corresponding native Java `Calendar.get()` method.
3. **Translation**: If you asked for `"month"`, it pulls the internal Java month (e.g., `1`), adds `+1` to it, and translates it to the human-readable `2`.
4. **Return**: Passes the finalized integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the Year

```essbase
/* Assumes vTodayObj is Dec 31, 2024. Returns 2024. */
VAR vYear = @CalcMgrGetDatePart(vTodayObj, "year");
```

### Variant 2: Extracting the Total Days in the Month

```essbase
/* Assumes vTodayObj is Feb 15, 2024 (a leap year). Returns 29. */
VAR vDaysInMonth = @CalcMgrGetDatePart(vTodayObj, "lastdayofmonth");
```

---

## Practical Examples

### Example 1: Dynamic "Days in Month" Accrual Division

**Scenario**: A corporate rent model calculates daily expense accruals. The company pays exactly `$10,000` a month in rent. To find the daily expense, the script must divide that `$10,000` by the exact number of days in the current month. The administrator does not want to write 12 different IF statements hardcoding `31`, `30`, and `28`. They use the `"lastdayofmonth"` parameter to calculate it dynamically.

```essbase
FIX("FY25", "Working", @LEVEL0("Rent_Expense"))
    
    IF("Monthly_Rent_Target" > 0)
        
        /* 1. Get the Current Date Object */
        VAR vTodayObj = @CalcMgrGetCurrentDate();
        
        /* 
           2. Dynamically extract how many days are in THIS specific month.
           (Java automatically knows if the current year is a leap year).
        */
        VAR vTotalDays = @CalcMgrGetDatePart(vTodayObj, "lastdayofmonth");
        
        /* 3. Calculate the daily accrual rate */
        "Daily_Rent_Accrual" = "Monthly_Rent_Target" / vTotalDays;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a YYYYMMDD Integer | `@CalcMgrGetDatePart(20241231, "month")` | This function explicitly requires a **Java Date Object** (usually generated by `GetCurrentDate` or `IntegerToDate`). If you pass a native Essbase `YYYYMMDD` integer, the Java engine will fail or return a completely invalid number. If you just need to extract the month from `20241231`, use native Essbase math: `@INT((Date - (@INT(Date/10000)*10000))/100)` |
| Misunderstanding Month Outputs | Expecting `0` for January | While the `GetCustomDate` creation function requires 0-indexed months, this *extraction* function returns standard 1-indexed months (January = `1`). Do not add `+1` to the output of this function, or February will become March |
| Spelling Errors | `"last_day"` instead of `"lastdayofmonth"` | The `date_part_ex` string must perfectly match the documented keywords. If you pass an invalid string, the Java engine will throw an IllegalArgumentException and crash the calc script |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetDateTimePart`](./@CalcMgrGetDateTimePart.md) | The sibling function used to extract Time components (Hours, Minutes, Seconds) |
| [`@CalcMgrGetCustomDate`](./@CalcMgrGetCustomDate.md) | The exact inverse function: Takes Year, Month, and Day integers and fuses them back into a unified Java Date Object |
| [`@CalcMgrExcelMONTH`](./@CalcMgrExcelMONTH.md) | A simpler function that extracts the Month directly from an *Excel Serial Date* decimal, rather than a Java Date Object |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getdatepart.html)
