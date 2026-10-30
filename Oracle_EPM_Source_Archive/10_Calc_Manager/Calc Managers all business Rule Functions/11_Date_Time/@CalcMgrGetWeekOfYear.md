# @CalcMgrGetWeekOfYear

## Overview

`@CalcMgrGetWeekOfYear` is a **custom Calc Manager calendar logic function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a unified **Java Date Object** (or Java Timestamp Object) and calculates the **absolute Week of the Year** that specific date falls into, returning it as an integer (e.g., `1` through `52` or `53`).

### Why Does This Function Exist?

While `GetWeekOfMonth` is useful for monthly bucketing, many manufacturing, logistics, and continuous-delivery organizations completely ignore months. They operate on absolute "Week of the Year" numbering. 
A manufacturing plant might schedule a critical turbine replacement during "Week 42". If an administrator is generating a multi-year forecast, they need to know exactly which dates correspond to Week 42 in 2024 versus 2025. 
Calculating this manually in Essbase is impossible without immense custom looping logic to detect leap years and the specific day of the week January 1st landed on. 
`@CalcMgrGetWeekOfYear` resolves this. It taps into the Java Calendar engine, natively evaluates the continuous Julian calendar grid, and returns exactly which week bucket (`1-53`) the date falls into, completely standardizing year-over-year operational comparisons.

### When to Use It

- **Manufacturing Planning**: Dynamically pushing daily production metrics into a `"Week_1"` through `"Week_52"` aggregate block.
- **Year-Over-Year Analytics**: Comparing sales in Week 15 of the current year against Week 15 of the prior year, completely eliminating the monthly calendar shift where dates fall on different weekends.
- **HR Accruals**: Tracking exactly how many weeks an employee has worked YTD to calculate vesting schedules.

---

## Category

**Date & Time / Component Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetWeekOfYear(date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The Java Date/Timestamp Object to be dissected. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the absolute Week of the Year as a pure integer.
- The return value will be between `1` and `53`.
- **CRITICAL**: The Java Calendar engine considers **Sunday** to be the start of a new week. 

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Date Object.
2. **Object Interrogation**: It calls the native Java `Calendar.get(Calendar.WEEK_OF_YEAR)` method directly against the object.
3. **Execution**: It calculates the week index based on standard Gregorian rules, where Week 1 is the first week containing January 1st.
4. **Return**: Passes the finalized integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the Week from the Current Date

```essbase
/* Assumes Today is Thursday, October 19th, 2023. Returns 42. */
VAR vWeekNumber = @CalcMgrGetWeekOfYear(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Dynamic 52-Week Revenue Rollup

**Scenario**: A global shipping company records daily container revenue using `YYYYMMDD` dates. The FP&A dashboard does not use Months; it strictly requires a 52-week view (`"Wk_01"`, `"Wk_02"` ... `"Wk_52"`). The calculation script must read the date, determine the absolute Week of the Year, format it into a clean member name, and push the revenue.

```essbase
FIX("FY25", "Working", @LEVEL0("Routes"))
    
    IF("Daily_Revenue" > 0 AND "Ship_Date" != #MISSING)
        
        /* 
           1. Convert the integer Date into a Java Object 
        */
        VAR vDateObj = @CalcMgrIntegerToDate("Ship_Date");
        
        /* 
           2. Extract specifically the absolute Week of the Year. 
           This returns an integer between 1 and 53.
        */
        VAR vWeekInt = @CalcMgrGetWeekOfYear(vDateObj);
        
        /* 
           3. Cap the week at 52 for standard reporting purposes.
           (If it hits 53 due to calendar overflow, force it into 52).
        */
        IF(vWeekInt > 52)
            vWeekInt = 52;
        ENDIF
        
        /* 
           4. Format the integer so it has a leading zero for single digits.
           (e.g., 5 becomes "05")
        */
        VAR vWeekString = @CalcMgrFormatDouble(vWeekInt, "00");
        
        /* 
           5. Construct the target member name (e.g., "Wk_05") and write the data.
        */
        VAR vTargetMember = @CONCATENATE("Wk_", vWeekString);
        
        @MEMBER(vTargetMember) = @MEMBER(vTargetMember) + "Daily_Revenue";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a YYYYMMDD Integer | `@CalcMgrGetWeekOfYear(20241019)` | This function explicitly requires a **Java Date Object**. If you pass a native Essbase integer, the Java engine will crash. You must use `@CalcMgrIntegerToDate` first |
| Misunderstanding ISO 8601 | Expecting Monday to be the start of the week | By default, the EPM Java container considers **Sunday** to be the first day of the week. If your company uses the strict ISO 8601 calendar (where weeks start on Monday, and Week 1 MUST contain Thursday), this native Java function will produce slightly different results than your European ERP system. You will need custom offset math to force ISO compliance |
| Week 53 Overflow | Crashing on `IF` statements | Some years legitimately contain 53 weeks. If your Essbase outline only has members up to `"Wk_52"`, your cross-dimensional concatenation macro will throw an Invalid Member error when `GetWeekOfYear` returns `53`. Always build a cap (`IF(Week > 52) Week = 52`) or ensure your outline can handle Week 53 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetWeekOfMonth`](./@CalcMgrGetWeekOfMonth.md) | The sibling function used to calculate the relative week of the Month (e.g., `1` to `6`) |
| [`@CalcMgrExcelWEEKNUM`](./@CalcMgrExcelWEEKNUM.md) | Explicitly mimics the Microsoft Excel week calculation algorithm. If you need absolute parity with an existing Excel model, use `WEEKNUM` instead of this function |
| [`@CalcMgrFormatDouble`](./@CalcMgrFormatDouble.md) | Highly useful for appending leading zeros (e.g., `"01"`) to the integer output so it matches standard outline member names |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getweekofyear.html)
