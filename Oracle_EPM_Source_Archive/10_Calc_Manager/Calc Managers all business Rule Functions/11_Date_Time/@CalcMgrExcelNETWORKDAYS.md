# @CalcMgrExcelNETWORKDAYS

## Overview

`@CalcMgrExcelNETWORKDAYS` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `NETWORKDAYS` function directly inside an Essbase calculation script. 
It calculates the exact number of **working days** between two dates, automatically excluding all weekends (Saturdays and Sundays), and optionally excluding a custom list of corporate holidays.

### Why Does This Function Exist?

Standard date subtraction (`Date2 - Date1` or `@CalcMgrDaysDiff`) calculates pure calendar days. If a project starts on Jan 1st and ends on Jan 31st, it took 31 days. However, in corporate finance, employees don't work on weekends. To accurately forecast labor costs, you must know that there were exactly 22 *working days* in January (excluding 8 weekend days and 1 New Year's Day holiday).
Writing a custom Essbase script to figure out exactly how many weekends fell between two dynamic dates is nightmarish, requiring modulus math on Julian day indices. `@CalcMgrExcelNETWORKDAYS` completely offloads this to the Java engine. It rapidly maps the calendar between the two dates, strips out the weekends, strips out any holidays you pass to it, and returns the exact number of billable days.

### When to Use It

- **Labor Forecasting**: Calculating exact billable hours for consulting projects or hourly factory wages based on the true number of working days in a month.
- **SLA Tracking**: Measuring how many *business days* it took to resolve a customer ticket or ship a product, ignoring weekend delays.
- Whenever you need to migrate an Excel spreadsheet containing the `NETWORKDAYS` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelNETWORKDAYS(start_date, end_date, [holidays])
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | Integer | ✅ Yes | The starting date. Can be passed as an Excel Serial Date or a standard `YYYYMMDD` Essbase integer. |
| `end_date` | Integer | ✅ Yes | The ending date. Can be passed as an Excel Serial Date or a standard `YYYYMMDD` Essbase integer. |
| `holidays` | Array/List | ❌ No  | An array of dates (Serial or `YYYYMMDD`) that should be excluded from the working day count. Usually passed as a cross-dimensional range like `"Holiday_Dates"->@CHILDREN("All_Holidays")`. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the integer number of working days between the two dates (inclusive of both the start and end dates if they fall on weekdays).
- **Directional Note**: If `end_date` is earlier than `start_date`, the function returns a negative number.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the two anchor dates and the optional array of holidays.
2. **Date Resolution**: It normalizes all dates (handling Serial vs YYYYMMDD formats).
3. **Calendar Mapping**: It calculates the total gross days. It divides by 7 to instantly figure out how many full weekend blocks exist and strips them. It then evaluates the fractional week remainder to see if it lands on a Saturday or Sunday.
4. **Holiday Processing**: If holidays are provided, it loops through the array. If a holiday falls between the start and end dates AND it falls on a weekday, it subtracts 1 from the working day count (if the holiday falls on a Saturday, it is ignored because it was already removed in Step 3).
5. **Return**: Passes the final net working day integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Weekend Exclusion (No Holidays)

```essbase
/* 
   Start: Jan 1, 2024
   End: Jan 31, 2024
   Total Calendar Days: 31
   Result: 23 (8 weekend days removed)
*/
"Net_Working_Days" = @CalcMgrExcelNETWORKDAYS(20240101, 20240131);
```

### Variant 2: Including an Array of Corporate Holidays

```essbase
/* Pulls a dynamic list of dates from an assumptions block */
"Net_Working_Days" = @CalcMgrExcelNETWORKDAYS(
    "Project_Start", 
    "Project_End", 
    "Corporate_Holidays"->@CHILDREN("Holidays_List")
);
```

---

## Practical Examples

### Example 1: Forecasting Hourly Labor Budgets

**Scenario**: A manufacturing plant pays workers an hourly wage. To forecast the exact labor budget for every month in FY25, you cannot simply divide the annual budget by 12, because February has fewer working days than August. You must dynamically calculate the exact number of working days in every month, accounting for the company's 10 paid holidays.

```essbase
FIX("FY25", "Working", @LEVEL0("Factory_Labor"))
    
    FIX(@IDESCENDANTS("YearTotal"))
        
        /* 
           Assume 'Month_Start_Date' and 'Month_End_Date' are calculated metrics.
           E.g., For January: Start = 20240101, End = 20240131
        */
        
        "Calculated_Working_Days" = @CalcMgrExcelNETWORKDAYS(
            "Month_Start_Date", 
            "Month_End_Date", 
            "Corporate_Holidays"->"No_Entity"->@CHILDREN("Holiday_List")
        );
        
        /* Multiply working days by 8 hours, then by the hourly wage */
        "Monthly_Labor_Budget" = ("Calculated_Working_Days" * 8) * "Hourly_Wage_Rate";
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Middle Eastern Weekends | Expecting Friday/Saturday weekends | `NETWORKDAYS` strictly hardcodes Saturday and Sunday as the weekend. If your Essbase model is calculating labor for a subsidiary in the Middle East (where the weekend is typically Friday/Saturday), this function is completely useless. You MUST use `@CalcMgrExcelNETWORKDAYSINTL` instead, which allows you to define exactly which days of the week constitute a weekend |
| Inclusive Counting | Expecting `End - Start` math | Standard date subtraction (e.g., Jan 2 - Jan 1) yields `1` day. `NETWORKDAYS` is an *inclusive* count of days worked. If a project starts Jan 1 and ends Jan 2, you worked 2 days. The function returns `2`. Be aware of this if you are using the output to match historical `DaysDiff` metrics |
| `#MISSING` Holidays | Array contains blanks | The Java engine safely ignores `#MISSING` values in the holiday array, so you do not need to worry if some of the holiday slots are empty |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelNETWORKDAYSINTL`](./@CalcMgrExcelNETWORKDAYSINTL.md) | Advanced version of this function that allows you to specify custom weekends (e.g., Friday/Saturday, or just Sunday) |
| [`@CalcMgrExcelWORKDAY`](./@CalcMgrExcelWORKDAY.md) | The inverse logic: You provide a start date and a number of working days (e.g., "Add 15 business days"), and it returns the exact calendar date of the deadline |
| [`@CalcMgrDaysDiff`](./@CalcMgrDaysDiff.md) | Calculates the raw calendar days between two dates (ignoring weekends entirely) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelnetworkdays.html)
