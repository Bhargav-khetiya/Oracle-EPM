# @CalcMgrExcelSECOND

## Overview

`@CalcMgrExcelSECOND` is a **custom Calc Manager time extraction function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `SECOND` function directly inside an Essbase calculation script. 
It analyzes an Excel Serial Date/Time decimal (or a Java Timestamp object) and extracts solely the **Second of the Minute**, returning it as an integer between `0` and `59`.

### Why Does This Function Exist?

In high-frequency operational planning models (like automated manufacturing, high-frequency trading logs, or telecom bandwidth monitoring), events are logged down to the exact second. In EPM Cloud, this data is usually passed as an Excel Serial Time format, where time is represented as a massive decimal fraction of a day (e.g., `0.5104166667` is exactly 12:15:00 PM).
Extracting the specific "Second" component manually in an Essbase script requires taking that fraction, multiplying by 24 (hours), stripping the remainder, multiplying by 60 (minutes), stripping the remainder, and multiplying by 60 again (seconds), followed by aggressive rounding to account for floating-point drift. This is highly tedious and error-prone.
`@CalcMgrExcelSECOND` entirely skips the fractional math by utilizing the Java engine. It evaluates the decimal, initializes a highly precise calendar object, and instantly extracts the exact second component, ensuring perfect parity with legacy operational Excel models.

### When to Use It

- **High-Frequency SLA Tracking**: Calculating exact down-to-the-second response times for telecom or automated API SLA agreements.
- **Micro-batch Processing**: Evaluating timestamps to categorize events into specific 10-second buckets for volume heatmapping.
- Whenever you need to migrate an Excel spreadsheet containing the `SECOND` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelSECOND(serial_number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serial_number` | Numeric | ✅ Yes | The time value to evaluate. Must be passed as an Excel Serial Date/Time decimal (e.g., `45657.75034`), a pure time decimal (e.g., `0.75034`), or a Java Date object. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer between `0` and `59` representing the second of the minute.
- E.g., `@CalcMgrExcelSECOND(0.5104513888)` returns `30` (because that fraction represents 12:15:30 PM).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the decimal (or object).
2. **Fraction Isolation**: If a full Serial Date is provided (e.g., `45657.510451`), it isolates the fractional component (`0.510451`).
3. **Extraction & Rounding**: It calculates the Hours, subtracts them out, calculates the Minutes, subtracts them out, and multiplies the final remainder by 60. Due to how Excel stores fractions, the Java engine applies a microscopic rounding correction at the end to ensure `29.999999` correctly returns `30`.
4. **Return**: Passes the resulting integer (0-59) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting from a Serial Date/Time

```essbase
/* Assume 45657.6461805 is Dec 31, 2024 at 3:30:30 PM. Returns 30. */
"Second_Component" = @CalcMgrExcelSECOND(45657.6461805);
```

### Variant 2: Extracting from Current System Time

```essbase
/* Gets the exact current second from the EPM Cloud server */
"Current_System_Second" = @CalcMgrExcelSECOND(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Generating Unique Micro-Batch IDs

**Scenario**: A massive aggregation script runs repeatedly throughout the day. The architect wants to stamp the exact time the script ran into a variable, so they can trace performance logs back to a specific run. They construct a custom "Batch ID" integer by extracting the Hour, Minute, and Second.

```essbase
FIX("FY25", "Working")
    
    /* Get the exact server time */
    VAR vCurrentTime = @CalcMgrGetCurrentDate();
    
    /* Extract all components */
    VAR vHour = @CalcMgrExcelHOUR(vCurrentTime);
    VAR vMin = @CalcMgrExcelMINUTE(vCurrentTime);
    VAR vSec = @CalcMgrExcelSECOND(vCurrentTime);
    
    /* 
       Construct a unique ID integer (e.g., 143045 for 2:30:45 PM).
       Math: (Hour * 10000) + (Min * 100) + Sec
    */
    "Batch_Execution_ID" = (vHour * 10000) + (vMin * 100) + vSec;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrExcelSECOND(20241231)` | This function explicitly expects an Excel Serial Date decimal or a Java Date. Standard 8-digit Essbase date integers do not contain time data. The function will fail or return `0` |
| Floating-Point Drift | Returning 29 instead of 30 | Because Essbase stores time fractions as 64-bit floats, very small precision errors can occur if a script artificially generates the time decimal (e.g., `1 / 86400`). If your script mathematically derives a time decimal, wrap the calculation in `@ROUND(..., 10)` before passing it to this function to ensure clean parsing |
| Expecting Milliseconds | Wanting `30.45` | This function strictly returns a whole integer between `0` and `59`. It truncates milliseconds entirely. If you need millisecond-level SLA tracking, you cannot use Excel date equivalents; you must use Java Timestamps and pure epoch math |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelHOUR`](./@CalcMgrExcelHOUR.md) | Extracts the Hour component (`0-23`) from a Serial Time decimal |
| [`@CalcMgrExcelMINUTE`](./@CalcMgrExcelMINUTE.md) | Extracts the Minute component (`0-59`) from a Serial Time decimal |
| [`@CalcMgrExcelTIME`](./@CalcMgrExcelTIME.md) | Re-assembles extracted Hour, Minute, and Second integers back into a valid Excel Serial Time decimal |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelsecond.html)
