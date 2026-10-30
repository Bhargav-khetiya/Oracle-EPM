# @CalcMgrDateTimesToExcel

## Overview

`@CalcMgrDateTimesToExcel` is a **custom Calc Manager data transformation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes an array (a range or list) of massive timestamp integers (formatted as `YYYYMMDDHHMMSS`) and simultaneously converts all of them into Microsoft Excel Serial DateTime numbers, returning an array of results.

### Why Does This Function Exist?

When developers need to track hours, minutes, and seconds inside standard Essbase data cells, they must format the timestamp into a massive 14-digit integer (e.g., `20241025143045` for Oct 25, 2024 at 14:30:45). 
While this preserves the data safely inside Essbase, Microsoft Excel uses an entirely different system. Excel tracks Date and Time as a "Serial Date"—a continuous float number starting from Jan 1, 1900. In Excel, the whole number represents the day, and the decimal fraction represents the time of day (e.g., `0.5` = Noon, `0.75` = 6:00 PM).
`@CalcMgrDateTimesToExcel` allows a developer to process an entire array of Essbase 14-digit timestamps and instantly translate them into Excel's decimal-based Serial DateTime system, ensuring that when the data is exported, Excel users can easily format the cells to show accurate Dates and Times natively.

### When to Use It

- When preparing a massive log of Audit Timestamps ("Last_Modified_Time") for export across an array of Time or Department members.
- When generating an SLA compliance extract for PowerBI or Excel that requires both the calendar date and the exact hour of completion.
- When you need to transform multiple timestamps simultaneously in a single pass to save processing time, rather than calling the singular `@CalcMgrDateTimeToExcel` repeatedly inside a dense loop.

---

## Category

**Date & Time / Array Transformation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDateTimesToExcel(dateTimeArray)
```

### Formal Syntax

```
@CalcMgrDateTimesToExcel(numericArrayExpression)
```

Where:
- `numericArrayExpression` — A range of members, a mathematical list, or a function that returns multiple `YYYYMMDDHHMMSS` integers.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dateTimeArray`| Numeric Array| ✅ Yes | A set of values representing timestamps in `YYYYMMDDHHMMSS` format. Often defined by pointing to an account across a range of Period/Time members using `@CHILDREN`. |

---

## Return Value

**Return Type**: Numeric Array (List of Floating-Point Numbers)

Returns a list/array of decimal numbers, where each number is the corresponding Excel Serial DateTime (e.g., `45657.60468`). 
*(Note: Because this function returns an array rather than a single number, it must be assigned to a target range matching the exact size of the input array).*

---

## How It Works (Behind the Scenes)

1. **Array Processing**: The function retrieves the array of 14-digit integers.
2. **Translation**: For each integer:
   - It calculates the whole number of days elapsed between Jan 1, 1900, and the `YYYYMMDD` portion.
   - It calculates the decimal fraction representing the `HHMMSS` portion (e.g., 12 hours is `0.5`, 6 hours is `0.25`).
   - It combines them into a single float (e.g., `45657.50`).
3. **Return Generation**: It packs all the new decimal values into a new array.
4. **Assignment**: Essbase assigns the new array sequentially to the specified target range.

---

## Syntax Variants & Scenarios

### Variant 1: Converting a Specific Range of Timestamps

```essbase
/* Converts the timestamps for all 12 months into Excel decimals in one pass */
"Excel_Timestamp"->@IDESCENDANTS("YearTotal") = 
    @CalcMgrDateTimesToExcel("Audit_Timestamp"->@IDESCENDANTS("YearTotal"));
```

---

## Practical Examples

### Example 1: Exporting System Run Times to Excel

**Scenario**: An IT administration cube tracks the exact time a massive aggregation script finishes running each month. The time is stored in an account called `"Job_Completion_Time"` as a 14-digit integer. The IT Director wants a CSV export of the whole year, but they want to open it in Excel and format it as `"mm/dd/yyyy hh:mm AM/PM"`. You must convert the 12 months of integers into Excel decimals before exporting.

```essbase
FIX("FY25", "Working", "Admin_Entity")
    
    /* 
       We target the 12 months (Jan..Dec) for the export account.
       We feed the 12 months of the raw 14-digit account into the function.
       The function translates all 12 simultaneously and writes them down the line. 
    */
    "Excel_Export_Time"->@IDESCENDANTS("YearTotal") = 
        @CalcMgrDateTimesToExcel("Job_Completion_Time"->@IDESCENDANTS("YearTotal"));
        
ENDFIX
```
*(If Jan's raw integer was `20240131230000` (11 PM), the export account will hold `45322.95833`)*

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Array Sizes | `"Target"->"Jan" = @CalcMgrDateTimesToExcel("Dates"->@CHILDREN("Q1"))` | If you feed 3 values into the function, but only provide 1 target cell, Essbase will throw an array size mismatch error. The target range must match the input range size perfectly |
| Passing 8-digit Dates | Feeding `YYYYMMDD` into this function | If you pass `20241025` into this function, it will interpret it as the year 0000, month 20, day 24, hour 10... it will completely scramble the result. This function STRICTLY expects 14-digit timestamps. For 8-digit dates, use `@CalcMgrDatesToExcel` |
| Precision Loss | Storing the result in an Integer account | The Excel Serial Date requires a decimal (floating-point) to track time. If your cube is configured to strip decimals from that specific account, you will lose the hours and minutes completely. Ensure the target account allows decimals |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDateTimeToExcel`](./@CalcMgrDateTimeToExcel.md) | The singular version of this function (converts exactly one timestamp instead of an array) |
| [`@CalcMgrDatesToExcel`](./@CalcMgrDatesToExcel.md) | The array function designed specifically for pure calendar dates (`YYYYMMDD`) without time components |
| [`@CalcMgrExcelToDateTime`](./@CalcMgrExcelToDateTime.md) | The reverse operation (imports an Excel decimal and turns it back into a 14-digit Essbase integer) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_datetimestoexcel.html)
