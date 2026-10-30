# @CalcMgrExcelWEEKDAY

## Overview

`@CalcMgrExcelWEEKDAY` is a **custom Calc Manager date conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `WEEKDAY` function directly inside an Essbase calculation script. 
It analyzes an Excel Serial Date decimal (or a Java Timestamp) and extracts the **Day of the Week**, returning it as a simple integer (e.g., `1` for Sunday, `2` for Monday).

### Why Does This Function Exist?

In retail, supply chain, and workforce planning, operational requirements fluctuate wildly based on the day of the week. Retail stores require double staffing on Saturdays (`7`). B2B supply chains ship absolutely nothing on Sundays (`1`). 
When an EPM system runs a massive daily forecast out 365 days, it must systematically evaluate whether every single day is a weekday or a weekend to apply the correct Volume Multipliers. Determining if "July 14th, 2026" is a Tuesday or a Saturday using manual Essbase algebra requires incredibly complex Julian date modulo division (`(Date + Offset) % 7`).
`@CalcMgrExcelWEEKDAY` eliminates the need for modulo math. It taps into the internal Java calendar engine, instantly identifying the correct day of the week for any given Excel serial date, ensuring your workforce and retail models can dynamically scale logic based on the 7-day cycle.

### When to Use It

- **Workforce Planning**: Determining if a forecast day is a Saturday/Sunday to trigger overtime pay rates or double-staffing logic.
- **Supply Chain Logistics**: Automatically zeroing out `"Units_Shipped"` on Sundays for freight carriers that do not operate on weekends.
- Whenever you need to migrate an Excel spreadsheet containing the `WEEKDAY` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelWEEKDAY(serial_number, return_type)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serial_number` | Numeric | ✅ Yes | The Excel Serial Date decimal to evaluate (e.g., `45657.0`), or a Java Date Object. |
| `return_type` | Numeric | ❌ No  | Determines the numbering convention. <br>`1` (Default) = Sunday is 1, Saturday is 7. <br>`2` = Monday is 1, Sunday is 7. <br>`3` = Monday is 0, Sunday is 6. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the day of the week.
- Assuming the default `return_type` (1):
  - `1` = Sunday
  - `2` = Monday
  - `3` = Tuesday
  - `4` = Wednesday
  - `5` = Thursday
  - `6` = Friday
  - `7` = Saturday

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the serial date decimal and the `return_type` flag.
2. **Calendar Offset**: It adds the decimal value to Excel's epoch baseline (Jan 1, 1900) and instantiates a highly precise Java Calendar object for that specific date.
3. **Extraction**: It calls the native Java `get(Calendar.DAY_OF_WEEK)` method.
4. **Shift Math**: It applies basic addition/subtraction to shift the resulting integer based on the user's `return_type` flag.
5. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Sunday-to-Saturday Week

```essbase
/* Assumes 45657 is a Tuesday. Using type 1 (default). Returns 3. */
"Day_Index" = @CalcMgrExcelWEEKDAY(45657, 1);
```

### Variant 2: Standard Business Week (Monday is 1)

```essbase
/* Assumes 45657 is a Tuesday. Using type 2 (Monday=1). Returns 2. */
"Business_Day_Index" = @CalcMgrExcelWEEKDAY(45657, 2);
```

---

## Practical Examples

### Example 1: Dynamic Weekend Overtime Trigger

**Scenario**: A corporate workforce model projects labor costs for every single day of the month. The base hourly rate is $25/hr. However, union contracts dictate that any hours worked on a Saturday or Sunday must be paid at "Time and a Half" (1.5x multiplier). The model uses `WEEKDAY` to dynamically flag weekends.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    /* Iterate through every day in the month */
    FIX(@CHILDREN("January"))
        
        IF("Base_Hours_Worked" > 0 AND "Excel_Serial_Date" != #MISSING)
            
            /* 
               1. Get the Day of the Week index.
               Using Return_Type = 2 (Monday = 1, Sunday = 7).
               This makes identifying weekends incredibly easy: > 5.
            */
            VAR vDayIndex = @CalcMgrExcelWEEKDAY("Excel_Serial_Date", 2);
            
            /* 
               2. Evaluate if it is a weekend (Saturday=6, Sunday=7)
            */
            IF(vDayIndex > 5)
                /* Weekend: 1.5x Pay */
                "Calculated_Wages" = "Base_Hours_Worked" * ("Hourly_Rate" * 1.5);
            ELSE
                /* Weekday: Standard Pay */
                "Calculated_Wages" = "Base_Hours_Worked" * "Hourly_Rate";
            ENDIF
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Essbase Dates | `@CalcMgrExcelWEEKDAY(20241231, 1)` | This function explicitly expects an *Excel* Serial Date decimal. If you pass a native Essbase `YYYYMMDD` integer (like `20241231`), the Java engine thinks you are asking for a date 57,000 years in the future. While it will technically return a day-of-week integer, it will be completely wrong for your intended date. Use `@CalcMgrExcelDATE` to convert YYYYMMDD into a serial number first |
| Misunderstanding Return Types | Complaining that Tuesday returned `2` | If you leave the `return_type` parameter blank, it defaults to `1` (Sunday is 1, Tuesday is 3). However, if you explicitly pass `2` (Monday is 1), Tuesday will return `2`. Always ensure your downstream `IF` logic perfectly matches the `return_type` you chose |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelWEEKNUM`](./@CalcMgrExcelWEEKNUM.md) | Extracts the Week of the Year (e.g., Week 52) rather than the Day of the Week |
| [`@CalcMgrExcelDAY`](./@CalcMgrExcelDAY.md) | Extracts the Day of the Month (e.g., the 14th) rather than the Day of the Week |
| [`@CalcMgrExcelDATE`](./@CalcMgrExcelDATE.md) | Converts a YYYYMMDD string or integers into the Serial Date required for this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelweekday.html)
