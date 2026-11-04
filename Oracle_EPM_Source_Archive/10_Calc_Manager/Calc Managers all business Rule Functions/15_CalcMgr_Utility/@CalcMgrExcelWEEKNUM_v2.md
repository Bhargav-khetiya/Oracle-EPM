# @CalcMgrExcelWEEKNUM

## Overview

`@CalcMgrExcelWEEKNUM` is a **custom Calc Manager date conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `WEEKNUM` function directly inside an Essbase calculation script. 
It analyzes an Excel Serial Date decimal (or a Java Timestamp) and calculates exactly which **Week of the Year** that date falls into, returning an integer between `1` and `53`.

### Why Does This Function Exist—

Retail, manufacturing, and supply chain industries operate heavily on weekly reporting cycles, often comparing "Week 42" of this year to "Week 42" of last year. 
Calculating the week number manually in Essbase is excruciatingly difficult. You must figure out what day of the week January 1st fell on, count how many days have elapsed since then, divide by 7, and apply rounding logic based on whether you consider Sunday or Monday the start of the week. 
`@CalcMgrExcelWEEKNUM` eliminates all of this custom calendar math. It taps directly into the Java engine's calendar object, evaluates the date against international standard week numbering systems, and instantly returns the exact week integer, ensuring your Essbase forecasting models align perfectly with legacy weekly Excel reports.

### When to Use It

- **Retail 4-5-4 Calendars**: Mapping daily granular POS data up into summary "Week" buckets for year-over-year reporting.
- **Manufacturing Schedules**: Generating week-based production run IDs from daily sales forecasts.
- Whenever you need to migrate an Excel spreadsheet containing the `WEEKNUM` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelWEEKNUM(serial_number, return_type)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serial_number` | Numeric | ✅ Yes | The Excel Serial Date decimal to evaluate (e.g., `45657.0`), or a Java Date Object. |
| `return_type` | Numeric | ❌ No  | Determines what day starts a new week. <br>`1` (Default) = Week begins on Sunday. <br>`2` = Week begins on Monday. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the Week of the Year (typically `1` to `52`, sometimes `53` depending on leap years and calendar alignment).
- E.g., A date in mid-October will likely return a number like `42`.
- **Note on Week 1**: In standard US/Excel logic (System 1), the week containing January 1st is *always* Week 1, regardless of what day of the week Jan 1st falls on.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the serial date decimal and the `return_type` flag.
2. **Calendar Initialization**: It adds the decimal value to Excel's epoch baseline (Jan 1, 1900) and instantiates a highly precise Java Calendar object.
3. **Configuration**: It configures the Java Calendar's `firstDayOfWeek` setting based on the `return_type` flag (Sunday vs. Monday).
4. **Extraction**: It calls the native Java `get(Calendar.WEEK_OF_YEAR)` method.
5. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Sunday-Start Week

```essbase
/* Assumes 45657 is near the end of December 2024. Using type 1 (default). Returns 53. */
"Week_Index" = @CalcMgrExcelWEEKNUM(45657, 1);
```

### Variant 2: Standard Business Week (Monday-Start)

```essbase
/* Assumes 45657 is Dec 31, 2024. Using type 2 (Monday start). */
"Business_Week_Index" = @CalcMgrExcelWEEKNUM(45657, 2);
```

---

## Practical Examples

### Example 1: Rolling Daily Sales into Weekly Buckets

**Scenario**: A grocery chain forecasts sales at the absolute daily level for fresh produce. The database has 365 daily members (`Jan_01`, `Jan_02`, etc.). The executives don't want to see 365 columns on a dashboard; they want to see 52 columns (`Week_01`, `Week_02`). The script evaluates the exact date of every daily member, determines its week number, and dynamically pushes the sales volume into the correct weekly summary member.

```essbase
FIX("FY25", "Working", @LEVEL0("Produce"))
    
    /* Iterate through every single day of the year */
    FIX(@LEVEL0("Time"))
        
        IF("Daily_Forecast_Units" > 0 AND "Excel_Serial_Date" != #MISSING)
            
            /* 
               1. Get the Week of the Year index.
               Using Return_Type = 2 (Monday start) because it is a B2B business.
            */
            VAR vWeekIndex = @CalcMgrExcelWEEKNUM("Excel_Serial_Date", 2);
            
            /* 
               2. Map the daily volume up into the correct Weekly summary member.
               We use standard IF routing.
            */
            IF(vWeekIndex == 1)
                "Weekly_Summary"->"Week_01" = "Weekly_Summary"->"Week_01" + "Daily_Forecast_Units";
            ELSEIF(vWeekIndex == 2)
                "Weekly_Summary"->"Week_02" = "Weekly_Summary"->"Week_02" + "Daily_Forecast_Units";
            /* ... continued for all 52 weeks ... */
            ENDIF
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Essbase Dates | `@CalcMgrExcelWEEKNUM(20241231, 1)` | This function explicitly expects an *Excel* Serial Date decimal. If you pass a native Essbase `YYYYMMDD` integer (like `20241231`), the Java engine thinks you are asking for a date 57,000 years in the future. Use `@CalcMgrExcelDATE` to convert your `YYYYMMDD` integers into a serial number first |
| ISO 8601 Compliance | Expecting the European Week System | In standard Excel `WEEKNUM` logic, the week containing Jan 1st is *always* Week 1. However, the ISO 8601 European standard dictates that Week 1 is the first week containing a Thursday. If you need strict ISO 8601 compliance, you cannot use this standard function; you must use `@CalcMgrExcelISOWEEKNUM` |
| Year Boundaries | Jan 1st falling on a Saturday | Because Jan 1st is always Week 1, if Jan 1st is a Saturday, Week 1 will only be 1 day long. Sunday, Jan 2nd, will immediately trigger the start of Week 2. Be very careful if you are running weekly average calculations; Week 1 and Week 52/53 are frequently partial weeks |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelISOWEEKNUM`](@CalcMgrExcelWEEKNUM.md) | Extracts the Week of the Year using the strict European ISO 8601 standard (Thursday rules) |
| [`@CalcMgrExcelWEEKDAY`](../11_Date_Time/@CalcMgrExcelWEEKDAY.md) | Extracts the Day of the Week (e.g., Tuesday=3) rather than the Week of the Year |
| [`@CalcMgrExcelDATE`](../11_Date_Time/@CalcMgrExcelDATE.md) | Converts a YYYYMMDD string or integers into the Serial Date required for this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelweeknum.html)
