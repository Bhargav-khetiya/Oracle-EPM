# @CalcMgrExcelWORKDAY

## Overview

`@CalcMgrExcelWORKDAY` is a **custom Calc Manager date manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `WORKDAY` function directly inside an Essbase calculation script. 
It calculates an exact **Future or Past Date**, skipping over all Saturdays, Sundays, and custom defined corporate holidays.

### Why Does This Function Exist?

In supply chain logistics and HR planning, standard calendar math is useless. If an HR policy says an employee must be paid "5 days after termination", you cannot just add `+ 5` to the termination date. If the 5th day lands on a Saturday, the employee won't get paid until Monday. If Monday is Memorial Day, they won't get paid until Tuesday. 
Calculating this manually in Essbase requires massive iterative loops: add 1 day, check if it's a weekend, if yes add another day, check a massive cross-dimensional array of corporate holidays, if yes add another day, repeat. 
`@CalcMgrExcelWORKDAY` entirely bypasses this looping nightmare. It taps into the Java calendar engine, automatically skips weekends, processes an array of custom holiday dates, and instantly returns the exact valid business day in Excel Serial Date format, perfectly matching legacy HR and Logistics Excel sheets.

### When to Use It

- **Accounts Receivable**: Dynamically calculating the exact "Due Date" for an invoice based on a "Net 30 Business Days" contract term.
- **Supply Chain Lead Times**: Calculating the exact date a shipping container will arrive at a factory, assuming the trucking company does not drive on weekends or holidays.
- Whenever you need to migrate an Excel spreadsheet containing the `WORKDAY` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelWORKDAY(start_date, days, [holiday1...])
```

### Formal Syntax

```
@CalcMgrExcelWORKDAY(start_date, days, [holidaysList])
```

Where:
- `start_date` — The starting date (must be an Excel Serial Date decimal).
- `days` — The number of business days to add (positive) or subtract (negative).
- `holidaysList` — (Optional) A comma-separated list of Excel Serial Dates representing holidays, or a cross-dimensional range like `@CHILDREN("Corporate_Holidays")`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | Numeric | ✅ Yes | The Excel Serial Date decimal to start from (e.g., `45657.0`). |
| `days` | Numeric | ✅ Yes | The number of non-weekend, non-holiday days to move forward or backward. |
| `[holidays...]` | Array/List| ❌ No  | An array of Excel Serial Dates to skip over during the calculation. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the calculated future or past date as an Excel Serial Date decimal (e.g., `45672.0`).
- You will likely need to convert this serial decimal back into a `YYYYMMDD` integer using `@CalcMgrExcelToDate` before saving it to the database.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the starting serial date, the day count, and the holiday array.
2. **Missing Handling**: It ignores any `#MISSING` dates in the holiday array.
3. **Calendar Shifting**: It initializes a Java Calendar object. It begins moving forward (or backward) one day at a time.
4. **Validation Loop**: For each day it lands on, it checks `Calendar.DAY_OF_WEEK`. If it is Saturday (7) or Sunday (1), it skips it. It then checks the current date against the `holidaysList`. If it matches, it skips it. 
5. **Completion**: Once it has successfully landed on `days` number of valid business days, it stops.
6. **Return**: It converts the final Java Calendar date back into an Excel Serial Date decimal and passes it to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Lead Time (No Holidays)

```essbase
/* 
   Assumes start_date is a Thursday. We want 5 business days later. 
   It skips Saturday and Sunday, landing exactly on the next Thursday.
*/
"Arrival_Serial_Date" = @CalcMgrExcelWORKDAY("Departure_Serial_Date", 5);
```

---

## Practical Examples

### Example 1: Dynamic AR Invoice Due Dates

**Scenario**: A corporate treasury model tracks massive Accounts Receivable invoices. The standard contract is "Net 15 Business Days". The script must look at the `"Invoice_Creation_Date"`, add exactly 15 valid work days, skip over the corporate holidays stored in the `"Holiday_Schedule"` dimension, and save the final "Due Date" as a `YYYYMMDD` integer.

```essbase
FIX("FY25", "Working", @LEVEL0("Invoices"))
    
    IF("Invoice_Creation_Date" != #MISSING)
        
        /* 1. Convert the Essbase YYYYMMDD date into an Excel Serial Date */
        VAR vStartSerial = @CalcMgrExcelDATE(
            @CalcMgrExcelYEAR("Invoice_Creation_Date"),
            @CalcMgrExcelMONTH("Invoice_Creation_Date"),
            @CalcMgrExcelDAY("Invoice_Creation_Date")
        );
        
        /* 
           2. Add 15 Business Days, skipping weekends and skipping the 
           serial dates loaded into the Corporate Holidays array.
        */
        VAR vTargetSerial = @CalcMgrExcelWORKDAY(
            vStartSerial, 
            15, 
            "Holiday_Serial_Dates"->@CHILDREN("Corporate_Holidays")
        );
        
        /* 3. Convert the resulting Serial Date back into a YYYYMMDD integer */
        "Calculated_Due_Date" = @CalcMgrExcelToDate(vTargetSerial);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Essbase Dates | `@CalcMgrExcelWORKDAY(20241231, 5)` | This function explicitly expects the `start_date` and all `holiday` dates to be *Excel* Serial Date decimals (e.g., `45657`). If you pass native Essbase `YYYYMMDD` integers, the internal Java engine will attempt to calculate dates 57,000 years in the future, resulting in a timeout, a crash, or returning a useless number |
| Forgetting to Convert Back | Saving `45672` to the database | The function outputs an Excel Serial Date. If your downstream dashboards or integrations expect human-readable `YYYYMMDD` integers, you must wrap the output of this function inside `@CalcMgrExcelToDate` |
| Middle Eastern Workweeks | Friday-Saturday Weekends | The standard `WORKDAY` function assumes Saturday and Sunday are the weekend. If you are modeling operations in the Middle East where the weekend is Friday and Saturday, you cannot use this function. You must use `@CalcMgrExcelWORKDAY_INTL`, which allows you to define exactly which days of the week constitute a weekend |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelWORKDAY_INTL`](./@CalcMgrExcelWORKDAY_INTL.md) | A more advanced variant that allows you to specify custom weekends (e.g., only Sunday off, or Friday/Saturday off) |
| [`@CalcMgrExcelNETWORKDAYS`](./@CalcMgrExcelNETWORKDAYS.md) | The inverse logic: If you already know the Start Date and the End Date, this calculates the total number of business days *between* them |
| [`@CalcMgrExcelDATE`](./@CalcMgrExcelDATE.md) | Crucial for converting Essbase YYYYMMDD integers into the Serial Dates required by this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelworkday.html)
