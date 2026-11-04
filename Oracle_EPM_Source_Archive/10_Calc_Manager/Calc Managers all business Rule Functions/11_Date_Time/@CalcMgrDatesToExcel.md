# @CalcMgrDatesToExcel

## Overview

`@CalcMgrDatesToExcel` is a **custom Calc Manager data transformation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes an array (a range or list) of standard Essbase `YYYYMMDD` integers and simultaneously converts all of them into Microsoft Excel Serial Date numbers, returning an array of results.

### Why Does This Function Exist—

Standard Essbase dates (e.g., `20241231`) are easy for humans to read, but Microsoft Excel does not understand them natively. Excel tracks time using a "Serial Date" system—a continuous count of days starting from January 1, 1900 (which is Serial Date `1`). In Excel, December 31, 2024, is stored as `45657`.
If you export raw Essbase `YYYYMMDD` integers into an Excel-based report or a CSV file meant for downstream consumption, and a user tries to format the column as a "Short Date", Excel will fail completely (interpreting `20241231` as a date millions of years in the future).
`@CalcMgrDatesToExcel` allows a developer to grab an entire list of dates in one pass (such as all dates across all 12 months) and instantly convert them all into Excel-friendly numbers right before pushing them to a reporting cube or export file.

### When to Use It

- When preparing an ASO reporting cube where end-users will heavily utilize Smart View Date Formatting.
- When generating a CSV data extract that will be automatically ingested into PowerBI, Tableau, or Excel data models that expect standard Serial Dates.
- When you need to transform multiple dates at once (e.g., a "Start_Date", "End_Date", and "Audit_Date" tracked across an array of time periods) rather than calling the singular conversion function over and over.

---

## Category

**Date & Time / Array Transformation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDatesToExcel(dateArray)
```

### Formal Syntax

```
@CalcMgrDatesToExcel(numericArrayExpression)
```

Where:
- `numericArrayExpression` — A range of members, a mathematical list, or a function that returns multiple `YYYYMMDD` integers (e.g., an `@ALL` or `@CHILDREN` function returning values).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dateArray`| Numeric Array| ✅ Yes | A set of values representing dates in `YYYYMMDD` format. This is usually defined by pointing to a specific account across a range of Time or Period members. |

---

## Return Value

**Return Type**: Numeric Array (List of Numbers)

Returns a list/array of integers, where each integer is the corresponding Excel Serial Date (e.g., `45657`). 
*(Note: Because this function returns an array rather than a single number, it must typically be wrapped inside an array-processing loop or assigned to a range of target members matching the exact size of the input array).*

---

## How It Works (Behind the Scenes)

1. **Array Processing**: The function takes the array of `YYYYMMDD` integers and loops through them in Java memory.
2. **Translation**: For each integer, it calculates how many days have elapsed between January 1, 1900, and that specific date.
3. **Return Generation**: It packs all the new Serial Date numbers into a new array.
4. **Assignment**: Essbase assigns the new array sequentially to the target range you specify in your equation.

---

## Syntax Variants & Scenarios

### Variant 1: Converting a Specific Range

```essbase
/* Converts the dates in Q1 into Excel numbers and assigns them to a reporting account */
"Excel_Dates"->@CHILDREN("Q1") = @CalcMgrDatesToExcel("Essbase_Dates"->@CHILDREN("Q1"));
```

---

## Practical Examples

### Example 1: Preparing a Smart View Reporting Array

**Scenario**: You have an HR model tracking "Hire_Date" across the 12 months of the year (`"Jan"` through `"Dec"`). These dates are currently `YYYYMMDD` integers. Before the nightly backup runs, you want to push these dates into an ASO-friendly reporting account called `"Hire_Date_Export"` formatted specifically for Excel.

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    /* 
       We target the 12 months (Jan..Dec) for the export account.
       We feed the 12 months of the raw date account into the function.
       The function converts all 12 simultaneously and writes them down the line. 
    */
    "Hire_Date_Export"->@IDESCENDANTS("YearTotal") = 
        @CalcMgrDatesToExcel("Hire_Date"->@IDESCENDANTS("YearTotal"));
        
ENDFIX
```

---

### Example 2: Handling Invalid Dates in the Array

**Scenario**: If an employee hasn't been hired yet, their `"Hire_Date"` cell might be `#MISSING`, or worse, `0`. When you feed an array containing zeros or `#MISSING` into the Excel converter, you need to be aware of how Excel treats `0` (which is technically Jan 1, 1900, or a blank cell). 

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    /* Step 1: Execute the array conversion */
    "Hire_Date_Export"->@CHILDREN("Q1") = @CalcMgrDatesToExcel("Hire_Date"->@CHILDREN("Q1"));
    
    /* Step 2: Clean up any weird 1900 dates caused by zeros passing through the array */
    FIX(@CHILDREN("Q1"))
        IF("Hire_Date_Export" < 100)
            "Hire_Date_Export" = #MISSING;
        ENDIF
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Array Sizes | `"Target"->"Jan" = @CalcMgrDatesToExcel("Dates"->@CHILDREN("Q1"))` | If you feed 3 values into the function (Jan, Feb, Mar), but only provide 1 target cell ("Jan"), Essbase will either throw an array size mismatch error or unpredictably stuff the first value into the target and drop the rest. Ensure the target range matches the input range size perfectly |
| Passing Java Date Objects | Feeding massive millisecond timestamps into the function | This function strictly expects `YYYYMMDD` integers. If you have an array of Java Date objects, you must convert them down to `YYYYMMDD` first, or use a different array converter |
| Expecting Time Components | Hoping it handles hours and minutes | `YYYYMMDD` contains no time data. The resulting Excel Serial Date will always have a time of `12:00:00 AM`. If you need to export arrays of timestamps, use `@CalcMgrDateTimesToExcel` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDateToExcel`](./@CalcMgrDateToExcel.md) | The singular version of this function (converts exactly one date instead of an array) |
| [`@CalcMgrDateTimesToExcel`](./@CalcMgrDateTimesToExcel.md) | The array function that also handles Time components (hours, minutes, seconds) |
| [`@CalcMgrExcelToDate`](./@CalcMgrExcelToDate.md) | The reverse operation (imports an Excel Serial Date and turns it into `YYYYMMDD`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_datestoexcel.html)
