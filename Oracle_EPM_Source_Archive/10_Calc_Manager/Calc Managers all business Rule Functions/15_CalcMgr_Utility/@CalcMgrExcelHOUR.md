# @CalcMgrExcelHOUR

## Overview

`@CalcMgrExcelHOUR` is a **custom Calc Manager time extraction function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `HOUR` function directly inside an Essbase calculation script. 
It analyzes an Excel Serial Date/Time decimal (or a Java Timestamp object) and extracts solely the **Hour of the Day**, returning it as an integer between `0` (12:00 AM) and `23` (11:00 PM).

### Why Does This Function Exist—

In EPM Cloud, time tracking is often stored using Excel Serial Time format, where dates are integers and time is represented as a decimal fraction of a day (e.g., `0.5` is 12:00 PM noon, `0.75` is 6:00 PM). 
If a call center workforce model imports a massive log of timestamped support tickets and needs to determine peak operational hours, extracting the exact hour from a decimal like `45657.64583` requires complex fractional multiplication and modulus math (`0.64583 * 24`). 
`@CalcMgrExcelHOUR` utilizes the Java engine to evaluate the decimal fraction and instantly extract the exact hour component in 24-hour format, zero mathematical hacking required, ensuring perfect parity with legacy Excel models.

### When to Use It

- **Workforce/Capacity Planning**: Categorizing timestamped operational events (like manufacturing batches or support tickets) into hourly buckets to determine shift staffing requirements.
- **System Auditing**: Extracting the hour from `@CalcMgrGetCurrentDate()` to trigger specific calculations only during certain times of the day (e.g., overnight batch windows).
- Whenever you need to migrate an Excel spreadsheet containing the `HOUR` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelHOUR(serial_number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serial_number` | Numeric | ✅ Yes | The time value to evaluate. Must be passed as an Excel Serial Date/Time decimal (e.g., `45657.75`), a pure time decimal (e.g., `0.75`), or a Java Date object. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer between `0` and `23` representing the hour of the day in a 24-hour format.
- E.g., `@CalcMgrExcelHOUR(0.75)` returns `18` (which is 6:00 PM).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the decimal (or object).
2. **Fraction Isolation**: If a full Serial Date is provided (e.g., `45657.645`), it isolates the fractional component (`0.645`).
3. **Extraction**: It multiplies the fraction by 24 and truncates the remainder to find the whole hour component.
4. **Return**: Passes the resulting integer (0-23) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting from a Serial Date/Time

```essbase
/* Assume 45657.64583 is Dec 31, 2024 at 3:30 PM. Returns 15. */
"Hour_Component" = @CalcMgrExcelHOUR(45657.64583);
```

### Variant 2: Extracting from Current System Time

```essbase
/* Gets the exact current hour from the EPM Cloud server */
"Current_System_Hour" = @CalcMgrExcelHOUR(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Hourly Call Center Staffing Allocation

**Scenario**: A call center planning model ingests a flat file of historical phone calls. Every call has a `"Call_Timestamp"` loaded as an Excel Serial Time. The FP&A analyst needs to allocate the calls into 24 distinct accounts (`"Hour_0"` through `"Hour_23"`) to build a heat map of daily call volume, which drives the hiring forecast for different shifts.

```essbase
FIX("FY24", "Working", @LEVEL0("Call_Logs"))
    
    IF("Call_Timestamp" != #MISSING)
        
        /* Extract the hour (0-23) */
        VAR vCallHour = @CalcMgrExcelHOUR("Call_Timestamp");
        
        /* 
           Dynamically increment a global bucket based on the hour.
           (Note: In reality, you might use a Groovy script to map the variable 
           to a specific member name dynamically, or use a series of IF statements)
        */
        IF(vCallHour == 14)
            "Total_Calls"->"Hour_14" = "Total_Calls"->"Hour_14" + 1;
        ELSEIF(vCallHour == 15)
            "Total_Calls"->"Hour_15" = "Total_Calls"->"Hour_15" + 1;
        /* ... continued for all hours ... */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Restricting Execution to the Overnight Window

**Scenario**: A specific heavy aggregation script is attached to a web form. To prevent users from crashing the server during business hours, the script checks the current time. If it is between 8:00 AM (`8`) and 6:00 PM (`18`), the script immediately aborts.

```essbase
FIX("FY25", "Working", "Total_Entity")
    
    /* Extract the current hour from the server (Note: Server is likely in UTC) */
    VAR vCurrentHour = @CalcMgrExcelHOUR(@CalcMgrGetCurrentDate());
    
    /* If between 8 AM and 5:59 PM */
    IF(vCurrentHour >= 8 AND vCurrentHour < 18)
        
        /* Do nothing, bypass logic */
        
    ELSE
        
        /* Execute the heavy aggregation */
        CALC DIM("Entity", "Product");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrExcelHOUR(20241231)` | This function explicitly expects an Excel Serial Date decimal or a Java Date. Standard 8-digit Essbase date integers do not contain time data. The function will fail or return `0` |
| Server Time Zones | Using `@CalcMgrGetCurrentDate()` | Oracle EPM Cloud servers usually operate in UTC. If you are extracting the hour from the system date to trigger logic for users in New York (EST), you must manually adjust the hour offset before evaluating it |
| 12-Hour vs 24-Hour | Expecting `3` for 3:00 PM | This function strictly returns military (24-hour) time. 3:00 PM will return `15`. Do not write `IF(Hour == 3)` for afternoon logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelMINUTE`](./@CalcMgrExcelMINUTE.md) | Extracts the Minute component (`0-59`) from a Serial Time decimal |
| [`@CalcMgrExcelSECOND`](./@CalcMgrExcelSECOND.md) | Extracts the Second component (`0-59`) from a Serial Time decimal |
| [`@CalcMgrExcelTIME`](./@CalcMgrExcelTIME.md) | Re-assembles extracted Hour, Minute, and Second integers back into a valid Excel Serial Time decimal |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelhour.html)
