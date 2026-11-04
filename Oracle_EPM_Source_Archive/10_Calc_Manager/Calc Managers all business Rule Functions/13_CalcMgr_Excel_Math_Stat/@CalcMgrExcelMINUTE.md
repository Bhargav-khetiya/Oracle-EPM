# @CalcMgrExcelMINUTE

## Overview

`@CalcMgrExcelMINUTE` is a **custom Calc Manager time extraction function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `MINUTE` function directly inside an Essbase calculation script. 
It analyzes an Excel Serial Date/Time decimal (or a Java Timestamp object) and extracts solely the **Minute of the Hour**, returning it as an integer between `0` and `59`.

### Why Does This Function Exist—

In operational planning models (like call centers, manufacturing plants, or logistics hubs), events are often logged down to the exact second. In EPM Cloud, this data is usually passed as an Excel Serial Time format, where time is represented as a decimal fraction of a day (e.g., `0.5` is exactly 12:00 PM, `0.510416` is 12:15 PM).
If a factory model needs to measure the exact downtime of a machine that broke at `0.510416` and came back online at `0.53125`, extracting the specific "Minute" components to build a user-readable dashboard requires complex fractional math (`Fraction * 24`, isolate remainder, `* 60`). 
`@CalcMgrExcelMINUTE` entirely skips the fractional math by utilizing the Java engine. It evaluates the decimal and instantly extracts the minute component, ensuring perfect parity with legacy operational Excel models.

### When to Use It

- **Manufacturing Planning**: Analyzing machine cycle times or factory downtime logs.
- **Logistics**: Calculating the exact minute a delivery truck arrived versus its scheduled arrival time to calculate vendor penalties.
- Whenever you need to migrate an Excel spreadsheet containing the `MINUTE` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelMINUTE(serial_number)
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

Returns an integer between `0` and `59` representing the minute of the hour.
- E.g., `@CalcMgrExcelMINUTE(0.510416)` returns `15`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the decimal (or object).
2. **Fraction Isolation**: If a full Serial Date is provided (e.g., `45657.510416`), it isolates the fractional component (`0.510416`).
3. **Extraction**: It multiplies the fraction by 24 to find the hours, takes the remainder, and multiplies by 60 to find the minutes, truncating any trailing seconds.
4. **Return**: Passes the resulting integer (0-59) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting from a Serial Date/Time

```essbase
/* Assume 45657.64583 is Dec 31, 2024 at 3:30 PM. Returns 30. */
"Minute_Component" = @CalcMgrExcelMINUTE(45657.64583);
```

### Variant 2: Extracting from Current System Time

```essbase
/* Gets the exact current minute from the EPM Cloud server */
"Current_System_Minute" = @CalcMgrExcelMINUTE(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Calculating Machine Downtime Penalties

**Scenario**: A factory has a strict SLA with its maintenance vendor. If a machine breaks, the vendor has exactly 45 minutes to fix it. Any delay beyond 45 minutes incurs a cash penalty. The system logs the exact `Break_Time` and `Fix_Time` as Serial decimal values.

```essbase
FIX("FY25", "Working", @LEVEL0("Machines"))
    
    IF("Break_Time" != #MISSING AND "Fix_Time" != #MISSING)
        
        /* 1. Extract the exact Hours */
        VAR vBreakHour = @CalcMgrExcelHOUR("Break_Time");
        VAR vFixHour = @CalcMgrExcelHOUR("Fix_Time");
        
        /* 2. Extract the exact Minutes */
        VAR vBreakMin = @CalcMgrExcelMINUTE("Break_Time");
        VAR vFixMin = @CalcMgrExcelMINUTE("Fix_Time");
        
        /* 3. Calculate total elapsed minutes */
        /* Note: This simplistic formula assumes the break and fix occur on the same day */
        VAR vElapsedMinutes = ((vFixHour - vBreakHour) * 60) + (vFixMin - vBreakMin);
        
        /* 4. Calculate Penalty */
        IF(vElapsedMinutes > 45)
            "Vendor_Penalty_Accrual" = (vElapsedMinutes - 45) * "Penalty_Rate_Per_Minute";
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Staggering Batch Calculation Exports

**Scenario**: A massive corporate model exports data to a data warehouse every hour. To prevent overwhelming the network, the exports are staggered by region based on the current minute of the hour. NA exports at :00, EMEA exports at :15, and APAC exports at :30.

```essbase
FIX("Working", "Current_Year")
    
    /* Extract the current minute from the server */
    VAR vCurrentMinute = @CalcMgrExcelMINUTE(@CalcMgrGetCurrentDate());
    
    /* Determine if this region is allowed to export right now */
    IF(@ISMBR("NA") AND vCurrentMinute < 15)
        /* Trigger NA Export Logic */
    ELSEIF(@ISMBR("EMEA") AND vCurrentMinute >= 15 AND vCurrentMinute < 30)
        /* Trigger EMEA Export Logic */
    ELSEIF(@ISMBR("APAC") AND vCurrentMinute >= 30 AND vCurrentMinute < 45)
        /* Trigger APAC Export Logic */
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrExcelMINUTE(20241231)` | This function explicitly expects an Excel Serial Date decimal or a Java Date. Standard 8-digit Essbase date integers do not contain time data. The function will fail or return `0` |
| Direct Subtraction Math | `MINUTE(Time2) - MINUTE(Time1)` | If a machine breaks at 1:55 PM (Minute = 55) and is fixed at 2:10 PM (Minute = 10), calculating `10 - 55` yields `-45`. You must always calculate the *Hour* difference alongside the Minute difference to accurately measure elapsed time |
| Expecting 2 Digits | Returning `05` for 3:05 PM | The function returns an integer (e.g., `5`). It does not format it as a string with a leading zero. If you are concatenating this into a time string for a dashboard, you must write `IF(vMin < 10)` logic to manually prepend a `"0"` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelHOUR`](./@CalcMgrExcelHOUR.md) | Extracts the Hour component (`0-23`) from a Serial Time decimal |
| [`@CalcMgrExcelSECOND`](./@CalcMgrExcelSECOND.md) | Extracts the Second component (`0-59`) from a Serial Time decimal |
| [`@CalcMgrExcelTIME`](./@CalcMgrExcelTIME.md) | Re-assembles extracted Hour, Minute, and Second integers back into a valid Excel Serial Time decimal |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelminute.html)
