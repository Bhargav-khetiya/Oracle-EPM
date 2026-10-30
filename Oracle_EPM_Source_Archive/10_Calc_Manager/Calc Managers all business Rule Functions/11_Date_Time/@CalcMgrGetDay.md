# @CalcMgrGetDay

## Overview

`@CalcMgrGetDay` is a **custom Calc Manager date extraction wrapper function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a unified **Java Date Object** (or Java Timestamp Object) and precisely extracts the **Day of the Month**, returning it as a pure integer (e.g., `1` through `31`).

### Why Does This Function Exist?

Calc Manager is built on top of a highly robust Java application server. When you use dynamic functions like `@CalcMgrGetCurrentDate()`, the engine returns a unified Java Object. While Java Objects are perfect for executing advanced Calendar math, they are completely useless to standard Essbase arithmetic. Essbase expects numbers.
If a corporate treasury script needs to verify if today is the "15th of the month" to trigger an automated mid-month accrual calculation, it must crack open the Java Date Object and isolate just the Day component.
While you *could* use the generic `@CalcMgrGetDatePart(date, "day")` function, `@CalcMgrGetDay` serves as a dedicated, hardcoded wrapper. It eliminates the need to remember and pass string keywords, ensuring faster script compilation, fewer syntax errors, and a cleaner, more readable calculation script.

### When to Use It

- **Mid-Month Processing**: Extracting the current day to dynamically trigger specific logic only if `Day == 15`.
- **Payment Terms**: Checking if a transaction date lands on the `31st` to trigger specialized end-of-month deferred revenue calculations.
- **Data Conversion**: Shredding a Java Date Object into Year, Month, and Day integers so they can be mathematically recombined into a standard `YYYYMMDD` integer for permanent storage in a numeric account.

---

## Category

**Date & Time / Component Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetDay(date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The Java Date/Timestamp Object to be dissected. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the exact Day of the Month as a pure integer.
- The return value will strictly be between `1` and `31`.
- It dynamically respects the maximum days of the month the object belongs to. (e.g., If the object is February 15th, it returns `15`).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Date Object.
2. **Object Interrogation**: It calls the native Java `Calendar.get(Calendar.DAY_OF_MONTH)` method directly against the object in memory.
3. **Execution**: It extracts the integer value.
4. **Return**: Passes the finalized integer back to Essbase for immediate use in mathematical logic or IF statements.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the Day from the Current Date

```essbase
/* Assumes Today is December 15, 2024. Returns 15. */
VAR vDay = @CalcMgrGetDay(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Dynamic Mid-Month Payroll Accruals

**Scenario**: A corporate workforce model calculates payroll accruals. Employees are paid on the 1st and the 15th of every month. The automated calculation script runs every single night. The script must ping the server for the current date, extract the exact day of the month, and ONLY execute the massive payroll calculation block if today is the 1st or the 15th.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    /* 1. Get Today's Date as a Java Object */
    VAR vTodayObj = @CalcMgrGetCurrentDate();
    
    /* 
       2. Extract specifically the Day of the Month. 
       This returns a simple integer like 1, 14, 15, 30.
    */
    VAR vCurrentDay = @CalcMgrGetDay(vTodayObj);
    
    /* 
       3. Evaluate the Day integer to trigger the payroll logic.
    */
    IF(vCurrentDay == 1 OR vCurrentDay == 15)
        
        /* 
           Execute massive Payroll Accrual Logic 
        */
        "Accrued_Payroll" = "Base_Salary" / 24;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a YYYYMMDD Integer | `@CalcMgrGetDay(20241215)` | This function explicitly requires a **Java Date Object**. If you pass a native Essbase `YYYYMMDD` integer, the Java engine will fail or return a completely invalid number. If you just need to extract the day from `20241215`, use native Essbase modulo math: `@MOD("Date", 100)` |
| Passing an Excel Serial Number | `@CalcMgrGetDay(45657.0)` | A floating-point serial number is not a Java Object. If your date is an Excel serial number, you must either convert it to an object first using `@CalcMgrExcelToDate()`, or use the entirely separate `@CalcMgrExcelDAY()` function, which is designed specifically for Excel decimals |
| Confusing with Day of Year | Expecting `365` | This function strictly returns the Day of the *Month* (`1-31`). If you need the Day of the Year (e.g., December 31st = `365`), you must use `@CalcMgrGetDayOfYear` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetDatePart`](./@CalcMgrGetDatePart.md) | The underlying generic extraction function. `@CalcMgrGetDatePart(date, "day")` does the exact same thing as this function |
| [`@CalcMgrGetMonth`](./@CalcMgrGetMonth.md) | The sibling wrapper function used to extract the Month component (`1-12`) |
| [`@CalcMgrGetDayOfYear`](./@CalcMgrGetDayOfYear.md) | Extracts the absolute Day of the Year (e.g., `1-365`) rather than resetting at the start of every month |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getday.html)
