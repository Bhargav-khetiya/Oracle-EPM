# @CalcMgrDateTimeToExcel

## Overview

`@CalcMgrDateTimeToExcel` is a **custom Calc Manager data transformation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a single massive timestamp integer (formatted as `YYYYMMDDHHMMSS`) and converts it into a Microsoft Excel Serial DateTime number (a decimal float).

### Why Does This Function Exist—

Essbase stores granular timestamps as massive 14-digit integers (e.g., `20241025143045` representing Oct 25, 2024 at 2:30:45 PM). This format is excellent for database sorting, but totally unreadable to business users in Smart View. 
Microsoft Excel processes time mathematically using a "Serial Date" system, where the whole number represents days elapsed since Jan 1, 1900, and the decimal fraction represents the percentage of the 24-hour day that has elapsed (e.g., `0.5` = Noon).
`@CalcMgrDateTimeToExcel` executes a mathematical translation on a single timestamp, converting the 14-digit Essbase number into an Excel decimal. When this decimal is pulled into Smart View, users can apply standard Excel Date/Time formatting to view it correctly.

### When to Use It

- When formatting a single Audit Timestamp ("Last_Modified_Time") so a user can read it in a Smart View form.
- When generating a single compliance metric (like a "Submission Deadline") for a specific entity that must be exported to an Excel-based regulatory report.
- When you only need to process one cell at a time (inside an `IF` statement or formula), rather than processing an entire array of time periods at once.

---

## Category

**Date & Time / Type Conversion / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDateTimeToExcel(dateTime)
```

### Formal Syntax

```
@CalcMgrDateTimeToExcel(numericExpression)
```

Where:
- `numericExpression` — A single 14-digit integer formatted strictly as `YYYYMMDDHHMMSS`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dateTime`| Integer | ✅ Yes | The 14-digit timestamp. Can be a hardcoded number, a variable, or a pointer to an Essbase data account holding the timestamp. |

---

## Return Value

**Return Type**: Numeric (Floating-Point Decimal)

Returns a decimal number representing the Excel Serial DateTime (e.g., `45657.60468`). 

---

## How It Works (Behind the Scenes)

1. **Extraction**: The function receives the 14-digit integer.
2. **De-construction**: It breaks the number down mathematically, separating the year (`2024`), month (`10`), day (`25`), hour (`14`), minute (`30`), and second (`45`).
3. **Excel Math**: 
   - It calculates the days elapsed since 1900 for the date portion.
   - It calculates `(Hours * 3600 + Minutes * 60 + Seconds) / 86400` to find the exact decimal percentage of the day.
4. **Return Generation**: It merges the two numbers together (e.g., `45657` + `0.60468`) and returns the final float to the Essbase calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Converting an Account Value

```essbase
/* Converts the 14-digit integer stored in 'Raw_Timestamp' */
"Excel_Timestamp" = @CalcMgrDateTimeToExcel("Raw_Timestamp");
```

---

## Practical Examples

### Example 1: Formatting an SLA Deadline for Smart View Users

**Scenario**: A Helpdesk planning model tracks the exact deadline for resolving high-priority tickets. The deadline is calculated by adding 48 hours to the creation time, resulting in a 14-digit integer stored in `"Resolution_Deadline_Raw"`. 
Users complain that they cannot read `20241027143000` on their dashboard. You create a secondary account, `"Resolution_Deadline_Formatted"`, and run a script to convert the raw number into an Excel decimal so they can apply a standard `mm/dd/yyyy hh:mm` format in Smart View.

```essbase
FIX("FY25", "Working", @LEVEL0("Tickets"))
    
    /* Ensure the raw deadline has been calculated */
    IF("Resolution_Deadline_Raw" != #MISSING AND "Resolution_Deadline_Raw" != 0)
        
        /* Translate the 14-digit integer into an Excel decimal */
        "Resolution_Deadline_Formatted" = @CalcMgrDateTimeToExcel("Resolution_Deadline_Raw");
        
    ENDIF
    
ENDFIX
```
*(In Smart View, `20241027143000` becomes `45653.60416`. When formatted, it clearly displays as `10/27/2024 2:30 PM`)*

---

### Example 2: Checking Execution Time Before Export

**Scenario**: You have a master consolidation script. Before it pushes data to a downstream system, you want to stamp the exact time it finished.

```essbase
FIX("FY25", "Working", "Admin_Entity")
    
    /* 1. Get the current Java Date (Right Now) */
    VAR vNowJava = @CalcMgrGetCurrentDate();
    
    /* 2. Convert Java Date to a 14-digit Essbase Integer */
    VAR vNowInt = @CalcMgrConvertJavaDateToDateTime(vNowJava);
    
    /* 3. Convert the 14-digit integer directly into an Excel decimal for the export file */
    "Consolidation_Finished_Time" = @CalcMgrDateTimeToExcel(vNowInt);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing 8-digit Dates | Feeding `YYYYMMDD` into this function | If you pass `20241025` into this function, it will interpret it as the year 0000, month 20, day 24... scrambling the result completely. This function STRICTLY expects 14-digit timestamps. For 8-digit dates, use `@CalcMgrDateToExcel` |
| Precision Loss (Truncation) | Saving the result to an Integer-only account | The Excel Serial Date relies entirely on the decimal fraction to track the time of day. If your cube or target account strips decimals, the hours and minutes will be permanently destroyed. Ensure the target cell supports decimal precision |
| Passing Java Dates | `@CalcMgrDateTimeToExcel(vJavaDate)` | This function expects an Essbase integer. If you pass a raw Java Date object, it will fail. You must route it through `@CalcMgrConvertJavaDateToDateTime` first |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDateTimesToExcel`](./@CalcMgrDateTimesToExcel.md) | The array version of this function (converts multiple timestamps in a single pass) |
| [`@CalcMgrDateToExcel`](./@CalcMgrDateToExcel.md) | The sister function designed specifically for pure calendar dates (`YYYYMMDD`) without time components |
| [`@CalcMgrExcelToDateTime`](./@CalcMgrExcelToDateTime.md) | The reverse operation (imports an Excel decimal and turns it back into a 14-digit Essbase integer) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_datetimetoexcel.html)
