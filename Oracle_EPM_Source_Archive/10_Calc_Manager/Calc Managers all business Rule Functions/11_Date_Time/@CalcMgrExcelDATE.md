# @CalcMgrExcelDATE

## Overview

`@CalcMgrExcelDATE` is a **custom Calc Manager date construction function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DATE` function directly inside an Essbase calculation script. 
It takes three separate integers representing the Year, Month, and Day, and combines them into a single valid date value. 

### Why Does This Function Exist—

In EPM Cloud, dates are typically stored as 8-digit integers (e.g., `20241231`). If you have three separate numeric components (e.g., a Year variable `2024`, a Month variable `12`, and a Day variable `31`), attempting to combine them manually using mathematical multiplication (e.g., `(Year * 10000) + (Month * 100) + Day`) is theoretically possible, but breaks down entirely if the day or month logic is dynamic and rolls over (e.g., trying to set the date to Month 13).
In Excel, `=DATE(2024, 13, 1)` automatically rolls over to January 1, 2025. `@CalcMgrExcelDATE` executes this exact same intelligent calendar math in the Java engine. It synthesizes the components, handles all leap-year and rollover logic effortlessly, and returns a perfect Excel Serial Date (a decimal number) that can be easily exported or further processed.

### When to Use It

- When dynamically constructing a Date based on User Input Prompts (RTPs) where the Year, Month, and Day were provided separately.
- When generating projected contract end dates (e.g., taking the Start Date, extracting the Year, adding 5 to the Year, and recombining them).
- When migrating an Excel model that relies on the `DATE(year, month, day)` formula.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDATE(year, month, day)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `year` | Numeric | ✅ Yes | The year. Can be 4 digits (e.g., `2024`) or 1-3 digits. (If between `0` and `1899`, the engine typically adds `1900` to it, mimicking Excel). |
| `month` | Numeric | ✅ Yes | The month of the year (e.g., `1` to `12`). If the number is greater than `12`, it automatically adds the excess months to the following year. |
| `day` | Numeric | ✅ Yes | The day of the month (e.g., `1` to `31`). If the number is greater than the total days in that specific month, it rolls over to the next month. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the **Excel Serial Date** (the number of days elapsed since January 1, 1900).
- e.g., `@CalcMgrExcelDATE(2024, 12, 31)` returns `45657`.
*(Note: Because this function returns an Excel Serial Date rather than a `YYYYMMDD` Essbase integer, you must use `@CalcMgrExcelToDate` if you want to store it in standard Essbase format).*

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the three integers.
2. **Rollover Math**: It evaluates the inputs. If `month` is `14`, it adds 1 to the `year` and sets the month to `2` (February). If `day` is `35`, it figures out how many days are in the evaluated month, subtracts them, and rolls into the next month.
3. **Serial Translation**: Once the final, valid calendar date is established, it calculates how many days have elapsed between January 1, 1900, and that date.
4. **Return**: Passes the resulting Serial Date integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Date Construction

```essbase
/* Constructs Dec 31, 2024. Returns 45657 */
"Excel_Date" = @CalcMgrExcelDATE(2024, 12, 31);
```

### Variant 2: Rollover Math (The 14th Month)

```essbase
/* Constructs Feb 1, 2025 by rolling the 14th month over. Returns 45689 */
"Excel_Date" = @CalcMgrExcelDATE(2024, 14, 1);
```

---

## Practical Examples

### Example 1: Creating a Uniform Expiration Date

**Scenario**: You have a list of software subscriptions. The system stores the `"Start_Date"` as an Excel Serial Date. Regardless of when a subscription started, you want to set the `"Renewal_Date"` to exactly December 31st of the *following* year. You can use `@CalcMgrExcelYEAR` to extract the year, add 1, and use `DATE` to rebuild it.

```essbase
FIX("FY25", "Working", @LEVEL0("Subscriptions"))
    
    IF("Start_Date_Serial" != #MISSING)
        
        /* 1. Extract the Year from the Start Date */
        VAR vStartYear = @CalcMgrExcelYEAR("Start_Date_Serial");
        
        /* 2. Rebuild the date: Next Year, Month 12, Day 31 */
        "Renewal_Date_Serial" = @CalcMgrExcelDATE(vStartYear + 1, 12, 31);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Converting to Essbase YYYYMMDD Format

**Scenario**: You built a date using `DATE`, which returned an Excel Serial Date (e.g., `45657`). However, your Essbase cube requires all dates to be stored as 8-digit integers (`20241231`) for reporting. You must nest the `DATE` function inside the `ExcelToDate` converter.

```essbase
FIX("FY25", "Working", "Assumptions")
    
    /* 
       1. @CalcMgrExcelDATE(2024, 12, 31) generates 45657.
       2. @CalcMgrExcelToDate(45657) generates 20241231.
    */
    "Standard_Essbase_Date" = @CalcMgrExcelToDate(
        @CalcMgrExcelDATE(2024, 12, 31)
    );
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misinterpreting the Output | Expecting `20241231` | This function strictly returns an **Excel Serial Date** (`45657`). If you stamp this directly into an Essbase cube that expects `YYYYMMDD`, the date will appear to be totally wrong (e.g., it looks like the year 4565). Always wrap this in `@CalcMgrExcelToDate` if you need the standard Essbase integer format |
| Negative Years | `@CalcMgrExcelDATE(-5, 1, 1)` | Excel date math breaks down completely before the year 1900. Passing negative years or years prior to 1900 will result in errors or unpredictable behavior |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelYEAR`](./@CalcMgrExcelYEAR.md) | Extracts the Year component from an Excel Serial Date |
| [`@CalcMgrExcelMONTH`](./@CalcMgrExcelMONTH.md) | Extracts the Month component from an Excel Serial Date |
| [`@CalcMgrExcelDAY`](./@CalcMgrExcelDAY.md) | Extracts the Day component from an Excel Serial Date |
| [`@CalcMgrExcelToDate`](./@CalcMgrExcelToDate.md) | Essential for converting the output of this function back into a standard Essbase `YYYYMMDD` integer |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldate.html)
