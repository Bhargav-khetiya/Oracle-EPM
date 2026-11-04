# @CalcMgrExcelDATEDIF

## Overview

`@CalcMgrExcelDATEDIF` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DATEDIF` function directly inside an Essbase calculation script. 
It calculates the exact mathematical difference between two Excel Serial Dates (or `YYYYMMDD` integers, depending on how they are cast) and returns the result in a specified unit of measurement (Years, Months, or Days), including advanced options for ignoring the year or month boundaries.

### Why Does This Function Exist—

Essbase already has `@CalcMgrDateDiff` for standard integer date subtraction. However, the legacy Excel `DATEDIF` function has highly specific, somewhat idiosyncratic behavior—especially regarding its string parameters (like `"ym"`, which calculates the difference in months while completely ignoring the years, or `"md"`, which calculates the difference in days while ignoring both years and months).
When migrating a complex HR model from Excel (e.g., calculating an employee's exact age as "34 Years, 5 Months, and 12 Days"), trying to recreate Excel's `"ym"` and `"md"` logic manually using Essbase math is incredibly tedious. 
`@CalcMgrExcelDATEDIF` leverages the underlying Java engine to execute the exact same algorithmic logic as Excel's hidden `DATEDIF` function, ensuring perfect parity with legacy spreadsheets.

### When to Use It

- **HR Models**: Calculating exact tenure or age broken down into Years, Months, and Days.
- **Contract Management**: Determining the remaining months on a contract *excluding* the current year.
- Whenever you need to migrate an Excel spreadsheet containing the `DATEDIF` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDATEDIF(start_date, end_date, "unit")
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | Integer | ✅ Yes | The starting date. Can be passed as an Excel Serial Date or a `YYYYMMDD` integer (the Java wrapper typically attempts to auto-resolve the format, but standard Essbase integers are safest). |
| `end_date` | Integer | ✅ Yes | The ending date. Must be >= `start_date`. |
| `"unit"` | String | ✅ Yes | The unit of measurement string (case-insensitive). Must be enclosed in double quotes. |

### Acceptable Unit Strings:
- `"Y"` : Total complete years between the dates.
- `"M"` : Total complete months between the dates.
- `"D"` : Total days between the dates.
- `"YM"` : The months between the dates, **ignoring years**. (e.g., Jan 15, 2023 to Mar 15, 2024 returns `2` months).
- `"YD"` : The days between the dates, **ignoring years**.
- `"MD"` : The days between the dates, **ignoring months and years**. (e.g., Jan 15, 2023 to Mar 20, 2024 returns `5` days).

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the mathematical difference based on the specified unit.
- If `end_date` is earlier than `start_date`, the function typically fails and returns `#MISSING`, mirroring Excel's `#NUM!` error.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures `end_date` >= `start_date`. 
2. **Calendar Initialization**: It spins up internal calendar objects to map the exact chronology.
3. **Unit Evaluation**: 
   - If `"M"` is passed, it calculates total elapsed months.
   - If `"YM"` is passed, it isolates the month components, subtracts them, and accounts for day-boundary rollovers without looking at the year difference.
4. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding Total Completed Years (Age)

```essbase
/* 
   Start: Jan 15, 1990
   End: Dec 31, 2024
   Result: Calculates complete years elapsed (Returns 34).
*/
"Employee_Age_Years" = @CalcMgrExcelDATEDIF(19900115, 20241231, "Y");
```

### Variant 2: Finding Months while Ignoring Years

```essbase
/* 
   Calculates the month remainder after the years are stripped away.
   Jan 15, 1990 to Dec 31, 2024. 
   Total Years is 34. The remainder is 11 full months (Feb->Dec). Returns 11.
*/
"Employee_Age_Months" = @CalcMgrExcelDATEDIF(19900115, 20241231, "YM");
```

---

## Practical Examples

### Example 1: Creating a Multi-Part Tenure String

**Scenario**: You have an HR dashboard. You want to display an employee's exact tenure as a text string (e.g., `"5 Years, 3 Months"`). You have their `"Hire_Date"` and the current system date. You must use `DATEDIF` to calculate the years, use it again to calculate the remainder months (`"YM"`), convert them to strings, and concatenate them.

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    IF("Hire_Date" != #MISSING)
        
        VAR vToday = @CalcMgrConvertJavaDateToDate(@CalcMgrGetCurrentDate());
        
        /* 1. Calculate Full Years */
        VAR vYears = @CalcMgrExcelDATEDIF("Hire_Date", vToday, "Y");
        
        /* 2. Calculate Remainder Months (Ignoring Years) */
        VAR vMonths = @CalcMgrExcelDATEDIF("Hire_Date", vToday, "YM");
        
        /* 3. Convert numbers to strings for concatenation */
        VAR vYearStr = @CalcMgrDoubleToString(vYears);
        VAR vMonthStr = @CalcMgrDoubleToString(vMonths);
        
        /* 4. Build the final string: "X Years, Y Months" */
        VAR vPart1 = @CalcMgrConcat(vYearStr, " Years, ");
        VAR vPart2 = @CalcMgrConcat(vPart1, vMonthStr);
        VAR vFinalStr = @CalcMgrConcat(vPart2, " Months");
        
        /* 5. Push to a global text counter or attribute (syntax simplified) */
        VAR vLog = @CalcMgrCounterUpdateText("Tenure_String", vFinalStr);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Start Date > End Date | Passing `20241231` as the start, and `20240101` as the end | Unlike `@CalcMgrDateDiff` (which will happily return a negative number), Excel's `DATEDIF` strictly requires the start date to be chronologically *before* the end date. If you reverse them, it fails |
| Using "MD" | Expecting perfect day tracking | In Excel, the `"MD"` parameter is notoriously buggy and can sometimes return negative numbers or skip days depending on leap years. The Calc Manager equivalent attempts to mimic it faithfully, which means it might inherit some of that weirdness. Use `"MD"` with caution |
| Missing Quotes | `@CalcMgrExcelDATEDIF(d1, d2, YM)` | The unit parameter MUST be enclosed in double quotes (e.g., `"YM"`) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDateDiff`](./@CalcMgrDateDiff.md) | The standard Essbase date difference function. Better for basic math, but lacks the `"YM"` or `"MD"` remainder logic |
| [`@CalcMgrDaysDiff`](./@CalcMgrDaysDiff.md) | Streamlined function for calculating strict calendar days between two integers |
| [`@CalcMgrExcelYEARFRAC`](./@CalcMgrExcelYEARFRAC.md) | Calculates the fraction of a year between two dates, often used alongside `DATEDIF` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldatedif.html)
