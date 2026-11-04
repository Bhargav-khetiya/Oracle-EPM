# @CalcMgrGetWeekOfMonth

## Overview

`@CalcMgrGetWeekOfMonth` is a **custom Calc Manager calendar logic function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a unified **Java Date Object** (or Java Timestamp Object) and precisely calculates **which week of the month** that specific date falls into, returning it as an integer (e.g., `1` through `6`).

### Why Does This Function Exist—

While calculating the current month or current day is straightforward, calculating the exact *Week of the Month* is a logistical nightmare in standard Essbase. 
If today is Friday, November 3rd, is it Week 1— Or is it Week 2— That depends entirely on what day November 1st landed on. If November 1st was a Wednesday, then Friday the 3rd is still technically part of Week 1 in some regional calendars, but part of Week 2 in others (where weeks strictly begin on Sunday). 
Writing standard Essbase math to track this requires knowing the weekday of the 1st of every month, historically, for eternity. 
`@CalcMgrGetWeekOfMonth` completely eliminates this complexity. It queries the Java Calendar engine, natively evaluates the calendar matrix for that specific month, and returns exactly which week bucket (`1-6`) the date falls into. This allows FP&A administrators to easily model weekly sales run-rates, retail foot-traffic seasonality, or 4-4-5 accounting periods.

### When to Use It

- **Retail Seasonality Modeling**: Comparing sales volume for the "3rd week" of November this year against the "3rd week" of November last year.
- **Weekly Reporting**: Dynamically pushing daily sales transactions into a `"Week_1"` through `"Week_5"` summary block based on their exact transaction date.
- **Payroll Accruals**: Determining if a bi-weekly payroll cycle lands 3 times in the current month (e.g., Week 1, Week 3, Week 5) instead of the standard 2.

---

## Category

**Date & Time / Component Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetWeekOfMonth(date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The Java Date/Timestamp Object to be dissected. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the Week of the Month as a pure integer.
- The return value will be between `1` and `6`.
- **CRITICAL**: The Java Calendar engine natively considers **Sunday** to be the first day of the week. Therefore, a new week number begins every Sunday. If November 1st is a Saturday (Week 1), then November 2nd (Sunday) instantly triggers Week 2.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Date Object.
2. **Object Interrogation**: It calls the native Java `Calendar.get(Calendar.WEEK_OF_MONTH)` method directly against the object in memory.
3. **Execution**: It calculates the week index based on standard Gregorian calendar rules.
4. **Return**: Passes the finalized integer back to Essbase for immediate use in mathematical logic or IF statements.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the Week from the Current Date

```essbase
/* Assumes Today is Thursday, November 23rd, 2023. Returns 4. */
VAR vWeekIndex = @CalcMgrGetWeekOfMonth(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Dynamic Weekly Sales Aggregation

**Scenario**: A massive retail company tracks sales at a daily level using `YYYYMMDD` integers. The FP&A team wants to automatically bucket those daily sales into 5 distinct week members (`"Wk_1"`, `"Wk_2"`, `"Wk_3"`, `"Wk_4"`, `"Wk_5"`) inside the Period dimension so they can compare week-over-week growth. The script must parse the date, find the week number, and dynamically map the data.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    IF("Daily_Sales" > 0 AND "Transaction_Date" != #MISSING)
        
        /* 
           1. Convert the integer Date (e.g. 20241123) into a Java Object 
        */
        VAR vDateObj = @CalcMgrIntegerToDate("Transaction_Date");
        
        /* 
           2. Extract specifically the Week of the Month. 
           This returns an integer between 1 and 6.
        */
        VAR vWeekNumber = @CalcMgrGetWeekOfMonth(vDateObj);
        
        /* 
           3. Evaluate the Week integer to route the data into the correct member.
        */
        IF(vWeekNumber == 1)
            "Wk_1" = "Wk_1" + "Daily_Sales";
        ELSEIF(vWeekNumber == 2)
            "Wk_2" = "Wk_2" + "Daily_Sales";
        ELSEIF(vWeekNumber == 3)
            "Wk_3" = "Wk_3" + "Daily_Sales";
        ELSEIF(vWeekNumber == 4)
            "Wk_4" = "Wk_4" + "Daily_Sales";
        ELSEIF(vWeekNumber >= 5)
            /* Grouping Week 5 and (rare) Week 6 together */
            "Wk_5" = "Wk_5" + "Daily_Sales";
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a YYYYMMDD Integer | `@CalcMgrGetWeekOfMonth(20241123)` | This function explicitly requires a **Java Date Object**. If you pass a native Essbase `YYYYMMDD` integer, the Java engine will fail or return a completely invalid number. You must use `@CalcMgrIntegerToDate` first |
| Misunderstanding Monday-Start Calendars | Expecting Monday to be the start of the week | By default, the EPM Java container considers **Sunday** to be the first day of the week (standard US locale rules). If your company is based in Europe and uses Monday as the first day of the week (ISO 8601), this function will classify Sundays incorrectly for your specific business logic. You must build custom macro adjustments (e.g., subtracting a day) if strict ISO compliance is required |
| Handling Week 6 | Assuming max week is 5 | Depending on how the days fall (e.g., a 31-day month starting on a Saturday), a month can absolutely bleed into a 6th week in the Java calendar. If your target members only go up to `"Wk_5"`, ensure your `IF` statements use `>= 5` to capture the overflow, or your script will drop data |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetWeekOfYear`](./@CalcMgrGetWeekOfYear.md) | The sibling function used to calculate the absolute week of the Year (e.g., `1` to `52`) |
| [`@CalcMgrGetDatePart`](./@CalcMgrGetDatePart.md) | The underlying generic extraction function. `@CalcMgrGetDatePart(date, "week")` does the exact same thing as this function |
| [`@CalcMgrExcelWEEKNUM`](../15_CalcMgr_Utility/@CalcMgrExcelWEEKNUM.md) | Similar to `GetWeekOfYear`, but explicitly mimics the Microsoft Excel week calculation algorithm and parses Excel Serial Decimals rather than Java Objects |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getweekofmonth.html)
