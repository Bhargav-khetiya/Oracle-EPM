# @CalcMgrGetMonth

## Overview

`@CalcMgrGetMonth` is a **custom Calc Manager date extraction wrapper function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a unified **Java Date Object** (or Java Timestamp Object) and precisely extracts the **Month**, returning it as a human-readable, 1-indexed integer (e.g., `1` through `12`).

### Why Does This Function Exist?

When you use dynamic functions like `@CalcMgrGetCurrentDate()` to find out what today's date is, the engine returns a unified Java Object. While Java Objects are perfect for executing advanced calendar math, they are completely unreadable to standard Essbase arithmetic. 
If an allocation script needs to route current-month Actuals into the correct Time member (e.g., `"Jan"`, `"Feb"`), it must crack open the Java Date Object and isolate just the Month integer.
While you *could* use the generic `@CalcMgrGetDatePart(date, "month")` function to do this, `@CalcMgrGetMonth` serves as a dedicated, hardcoded wrapper. It eliminates the need to remember and pass string keywords, ensuring faster script compilation, fewer syntax errors, and cleaner calculation scripts. 

### When to Use It

- **Dynamic Cross-Dimensional Lookups**: Extracting the current month integer (e.g., `3`) and using an `@MEMBER` string concatenation macro to dynamically push data into the `"Period_3"` member.
- **Quarterly Logic**: Using the month integer to mathematically determine what Quarter you are in (e.g., `IF(vMonth <= 3) "Q1"`).
- **Data Conversion**: Shredding a Java Date Object into Year, Month, and Day integers so they can be mathematically recombined into a standard `YYYYMMDD` integer.

---

## Category

**Date & Time / Component Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetMonth(date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The Java Date/Timestamp Object to be dissected. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the exact Month as a pure, human-readable integer.
- E.g., January = `1`. December = `12`.
- **CRITICAL NOTE**: While Java Calendar objects internally store months as 0-indexed (Jan = 0), this specific Calc Manager wrapper automatically adds `+1` to the result before returning it. It completely shields the Essbase user from Java's confusing 0-index logic.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Date Object.
2. **Object Interrogation**: It calls the native Java `Calendar.get(Calendar.MONTH)` method directly against the object in memory. (This returns `0-11`).
3. **Translation**: The wrapper function intercepts the internal Java value and mathematically adds `+1` to it.
4. **Return**: Passes the finalized, 1-indexed integer (`1-12`) back to Essbase for immediate use in mathematical logic.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the Month from the Current Date

```essbase
/* Assumes Today is December 15, 2024. Returns 12. */
VAR vMonth = @CalcMgrGetMonth(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Dynamic Rolling Forecast Initialization

**Scenario**: A corporate FP&A team runs a "Roll Forecast" script on the 1st of every month. The script checks the current server date. If the current month is May (`5`), the script must dynamically copy Actuals data into `Jan:Apr`, and clear the Forecast data in those same historical months.

```essbase
FIX("FY25", "Working", @LEVEL0("Accounts"))
    
    /* 1. Get Today's Date as a Java Object */
    VAR vTodayObj = @CalcMgrGetCurrentDate();
    
    /* 
       2. Extract specifically the Month. 
       This returns a simple integer like 5 (May).
    */
    VAR vCurrentMonth = @CalcMgrGetMonth(vTodayObj);
    
    /* 
       3. Evaluate the Month integer to trigger dynamic period logic.
    */
    IF(vCurrentMonth == 5) /* We are in May */
        
        /* Copy Actuals to Forecast for historical months */
        FIX("Jan", "Feb", "Mar", "Apr")
            "Forecast" = "Actuals";
        ENDFIX
        
    ELSEIF(vCurrentMonth == 6) /* We are in June */
        
        FIX("Jan", "Feb", "Mar", "Apr", "May")
            "Forecast" = "Actuals";
        ENDFIX
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a YYYYMMDD Integer | `@CalcMgrGetMonth(20241215)` | This function explicitly requires a **Java Date Object**. If you pass a native Essbase `YYYYMMDD` integer, the Java engine will fail or return a completely invalid number. If you just need to extract the month from `20241215`, use native Essbase modulo math: `@INT((Date - (@INT(Date/10000)*10000))/100)` |
| Adding +1 manually | `VAR vMonth = @CalcMgrGetMonth(vObj) + 1` | Because many administrators know that Java month arrays are 0-indexed, they reflexively add `+1` to the output of month functions. Do NOT do this here. Oracle already built the `+1` correction into this wrapper function. If you add `+1` yourself, January will incorrectly report as February (`2`) |
| Passing an Excel Serial Number | `@CalcMgrGetMonth(45657.0)` | A floating-point serial number is not a Java Object. If your date is an Excel serial number, you must use the entirely separate `@CalcMgrExcelMONTH()` function, which is designed specifically to parse Excel decimals |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetDatePart`](./@CalcMgrGetDatePart.md) | The underlying generic extraction function. `@CalcMgrGetDatePart(date, "month")` does the exact same thing as this function |
| [`@CalcMgrGetDay`](./@CalcMgrGetDay.md) | The sibling wrapper function used to extract the Day component (`1-31`) |
| [`@CalcMgrGetYear`](./@CalcMgrGetYear.md) | The sibling wrapper function used to extract the Year component (`YYYY`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getmonth.html)
