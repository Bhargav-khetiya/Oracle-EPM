# @CalcMgrGetYear

## Overview

`@CalcMgrGetYear` is a **custom Calc Manager date extraction wrapper function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a unified **Java Date Object** (or Java Timestamp Object) and precisely extracts the **Year**, returning it as a pure 4-digit integer (e.g., `2024`).

### Why Does This Function Exist?

When executing advanced calendar logic in Calc Manager, scripts rely heavily on Java Date Objects (via `@CalcMgrGetCurrentDate()`). However, Java Objects cannot be saved into the database, nor can they be used to dynamically generate standard Essbase dimensional member names like `"FY24"`. 
To build dynamic member names or execute year-over-year mathematical variance logic, you must isolate the Year component. 
While you *could* use the generic `@CalcMgrGetDatePart(date, "year")` function, `@CalcMgrGetYear` serves as a dedicated, hardcoded wrapper. It eliminates the need to pass string keywords, ensuring faster script execution, zero risk of spelling errors, and a cleaner, more readable calculation script.

### When to Use It

- **Dynamic Forecasting**: Extracting the current server year (`2024`) and adding `+1` to dynamically calculate `"FY25"` so you can copy Actuals into the new Forecast year automatically.
- **Contract Maturity**: Calculating the exact number of years remaining on a software license by extracting the Year from the Expiration Date Object and subtracting the Year from the Current Date Object.
- **Data Conversion**: Shredding a Java Date Object into Year, Month, and Day integers so they can be mathematically recombined into a `YYYYMMDD` integer.

---

## Category

**Date & Time / Component Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetYear(date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The Java Date/Timestamp Object to be dissected. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the exact Year as a pure 4-digit integer.
- E.g., `2024`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Date Object.
2. **Object Interrogation**: It calls the native Java `Calendar.get(Calendar.YEAR)` method directly against the object in memory.
3. **Execution**: It extracts the integer value.
4. **Return**: Passes the finalized 4-digit integer back to Essbase for immediate use in mathematical logic or string macros.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the Year from the Current Server Date

```essbase
/* Assumes Today is sometime in 2024. Returns 2024. */
VAR vYear = @CalcMgrGetYear(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Dynamic Rolling Year Setup

**Scenario**: A company automates their New Year Rollover process. On January 1st, a script runs to clear out the historical forecast and set up the new year. The script must ping the EPM Server, determine what year it actually is, calculate the target string `"FYXX"`, and execute a massive data clear.

```essbase
FIX("Working", @LEVEL0("Accounts"))
    
    /* 1. Get Today's Date as a Java Object */
    VAR vTodayObj = @CalcMgrGetCurrentDate();
    
    /* 
       2. Extract specifically the 4-digit Year. 
       This returns a simple integer (e.g., 2024).
    */
    VAR vCurrentYear = @CalcMgrGetYear(vTodayObj);
    
    /* 
       3. We need a 2-digit year (24) to match the Essbase outline (FY24).
       We use modulo math to strip the '20' off the front.
    */
    VAR vShortYear = @MOD(vCurrentYear, 100);
    
    /* 
       4. Convert the integer '24' into a string, and concatenate "FY".
    */
    VAR vTargetYearStr = @CONCATENATE("FY", @CalcMgrDoubleToString(vShortYear));
    
    /* 
       5. Dynamically clear the data in the target year.
    */
    FIX(@MEMBER(vTargetYearStr))
        
        "Forecast" = #MISSING;
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a YYYYMMDD Integer | `@CalcMgrGetYear(20241215)` | This function explicitly requires a **Java Date Object**. If you pass a native Essbase `YYYYMMDD` integer, the Java engine will fail. If you just need to extract the year from `20241215`, use native Essbase math: `@INT(Date / 10000)` |
| Passing an Excel Serial Number | `@CalcMgrGetYear(45657.0)` | A floating-point serial number is not a Java Object. If your date is an Excel serial number, you must use the entirely separate `@CalcMgrExcelYEAR()` function, which is designed specifically to parse Excel decimals |
| Expecting a 2-Digit String | `"Target" = @CalcMgrGetYear(...)` | This function returns a strict 4-digit integer (`2024`). It does not return `"24"` or `"FY24"`. If you need a short string, you must use math and string concatenation macros to reformat the output, as shown in Example 1 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetDatePart`](./@CalcMgrGetDatePart.md) | The underlying generic extraction function. `@CalcMgrGetDatePart(date, "year")` does the exact same thing as this function |
| [`@CalcMgrGetMonth`](./@CalcMgrGetMonth.md) | The sibling wrapper function used to extract the Month component (`1-12`) |
| [`@CalcMgrExcelYEAR`](./@CalcMgrExcelYEAR.md) | Performs the exact same conceptual extraction, but takes an Excel Serial Decimal as the input rather than a Java Object |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getyear.html)
