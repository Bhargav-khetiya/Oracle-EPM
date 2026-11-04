# @CalcMgrGetCurrentDateTimeTZ

## Overview

`@CalcMgrGetCurrentDateTimeTZ` is a **custom Calc Manager timezone-aware date/time function** in Oracle EPM Cloud (PBCS/EPBCS). It pings the underlying EPM Java application server for the current UTC time, and then **automatically shifts that time** to perfectly match a specified local timezone, returning a highly precise Java Timestamp object.

### Why Does This Function Exist—

Oracle EPM Cloud servers are hosted in massive global data centers. To maintain consistency, Oracle hardcodes all EPM Cloud server clocks to **UTC (Coordinated Universal Time)**. 
If an administrator in New York executes a calculation script at exactly 4:00 PM Eastern Standard Time, and the script uses standard `@CalcMgrGetCurrentDateTime`, the server will return 9:00 PM (UTC). If the script has a hardcoded SLA rule that says `"Reject data if time > 5:00 PM"`, the script will incorrectly reject the New York user's data because 9:00 PM UTC > 5:00 PM. 
`@CalcMgrGetCurrentDateTimeTZ` completely resolves this global deployment nightmare. By explicitly passing the timezone parameter (e.g., `"America/New_York"`), the Java engine dynamically calculates the offset—automatically accounting for complex rules like Daylight Saving Time—and returns the exact local time the user expects.

### When to Use It

- **Global SLA Enforcement**: Checking if a specific regional office missed their local 5:00 PM submission deadline, regardless of what time it is on the UTC server.
- **Audit Trails**: Stamping calculation executions into a text log using the local time of the regional controller, making the logs readable for local auditors.
- **Shift-Based Workforce Planning**: Determining if the current time falls into the "Night Shift" bucket for a specific factory located in Tokyo.

---

## Category

**Date & Time / System Queries / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetCurrentDateTimeTZ(timezone)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `timezone` | String | ✅ Yes | The standard Java Timezone ID (e.g., `"America/New_York"`, `"Europe/London"`, `"Asia/Tokyo"`, or simply `"EST"`). |

*(Note: It is highly recommended to use Region/City formats rather than 3-letter abbreviations, because Region/City formats automatically handle Daylight Saving Time shifts).*

---

## Return Value

**Return Type**: Object (Java Date / Timestamp)

Returns a Java Timestamp Object representing the exact current date and time in the specified timezone.
- **CRITICAL**: Because this returns a Java Object, it **cannot** be saved directly into a standard Essbase numeric account cell. It must either be formatted into a readable text string (using `@CalcMgrFormatDate`), extracted into integers, or passed directly into a difference calculator.

---

## How It Works (Behind the Scenes)

1. **Server Ping**: The Java engine queries the host EPM server's operating system clock (UTC).
2. **Timezone Evaluation**: It evaluates the provided `timezone` string against the native Java `TimeZone` registry. It determines the base offset (e.g., -5 hours) and checks if the current date falls inside the local Daylight Saving Time rules (shifting it to -4 hours).
3. **Offset Application**: It mathematically applies the exact offset to the UTC timestamp.
4. **Object Instantiation**: It creates a new `java.util.Date` or Timestamp object locked to that shifted time.
5. **Return**: Passes the resulting Object back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Querying New York Local Time

```essbase
/* Dynamically captures the current time in New York, adjusting for DST */
VAR vNYTimeObj = @CalcMgrGetCurrentDateTimeTZ("America/New_York");
```

---

## Practical Examples

### Example 1: Enforcing Local Submission Deadlines

**Scenario**: A global company requires the London office and the Tokyo office to run their final Allocations script before 6:00 PM (18:00) local time. If they run it after 18:00, the script must abort and throw an error. Because they share a single EPM Cloud instance (on UTC time), standard time functions will not work. The script must dynamically check the local time based on the active Entity being calculated.

```essbase
FIX("FY25", "Working")
    
    /* Evaluate London */
    FIX("Entity_London")
        
        /* 1. Get the current exact time in London */
        VAR vLocalTimeObj = @CalcMgrGetCurrentDateTimeTZ("Europe/London");
        
        /* 2. Extract strictly the Hour (0-23 format) */
        VAR vLocalHour = @CalcMgrExcelHOUR(vLocalTimeObj);
        
        /* 3. Enforce the 6:00 PM (18) deadline */
        IF(vLocalHour >= 18)
            @RETURN("Error: You have missed the 6:00 PM London submission deadline.", ERROR);
        ENDIF
        
        /* Proceed with allocations... */
        
    ENDFIX
    
    /* Evaluate Tokyo */
    FIX("Entity_Tokyo")
        
        /* 1. Get the current exact time in Tokyo */
        VAR vLocalTimeObj = @CalcMgrGetCurrentDateTimeTZ("Asia/Tokyo");
        
        /* 2. Extract strictly the Hour */
        VAR vLocalHour = @CalcMgrExcelHOUR(vLocalTimeObj);
        
        /* 3. Enforce the deadline */
        IF(vLocalHour >= 18)
            @RETURN("Error: You have missed the 6:00 PM Tokyo submission deadline.", ERROR);
        ENDIF
        
        /* Proceed with allocations... */
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using Static Abbreviations | Passing `"EST"` | If you pass `"EST"` (Eastern Standard Time), Java will permanently lock the offset to UTC-5. When summer arrives and New York shifts to EDT (Eastern Daylight Time, UTC-4), your script will be exactly 1 hour behind reality. Always use geographic IDs like `"America/New_York"` which have DST calendars built-in |
| Attempting Direct Storage | `"Time_Stamp" = @CalcMgrGetCurrentDateTimeTZ(...)` | Essbase accounts cannot hold Java Objects. If you try to save the result directly, it will fail. You must extract the components or use a text formatting function |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetCurrentDateTime`](./@CalcMgrGetCurrentDateTime.md) | Returns the pure UTC server time without any timezone shifting |
| [`@CalcMgrGetCurrentDateTZ`](./@CalcMgrGetCurrentDateTZ.md) | Returns the local date, but zeroes out the Hours/Minutes/Seconds |
| [`@CalcMgrExcelHOUR`](./@CalcMgrExcelHOUR.md) | Extracts strictly the Hour integer (0-23) from the resulting timezone object |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getcurrentdatetimetz.html)
