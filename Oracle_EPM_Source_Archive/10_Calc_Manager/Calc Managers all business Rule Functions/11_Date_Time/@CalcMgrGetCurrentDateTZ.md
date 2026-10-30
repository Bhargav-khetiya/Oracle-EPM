# @CalcMgrGetCurrentDateTZ

## Overview

`@CalcMgrGetCurrentDateTZ` is a **custom Calc Manager timezone-aware date function** in Oracle EPM Cloud (PBCS/EPBCS). It pings the underlying EPM Java application server for the current UTC time, **shifts that time** to match a specified local timezone, and then zeroes out the time-of-day, returning strictly the **Local Calendar Date** as a Java Date Object.

### Why Does This Function Exist?

Timezone differences don't just affect the hour of the day; they frequently change the *actual calendar day*. If it is 9:00 PM on Monday night in New York, it is already 10:00 AM on **Tuesday** morning in Tokyo. 
Oracle EPM Cloud servers run on UTC time. If an administrator in Tokyo runs a script on Tuesday morning to pull the "Current Date", standard `@CalcMgrGetCurrentDate` will ask the UTC server what day it is. The UTC server will reply that it is still Monday. The script will pull the wrong day's data, causing a massive reconciliation failure.
`@CalcMgrGetCurrentDateTZ` prevents this calendar misalignment. By passing `"Asia/Tokyo"`, the engine pulls the UTC time, shifts it forward to Tokyo time, verifies that it crosses the midnight threshold into Tuesday, zeroes out the hours/minutes, and returns the correct Tuesday Java Date Object.

### When to Use It

- **Global Roll-Forwards**: Ensuring that automated "Copy Actuals to Forecast" scripts run on the correct local calendar day for international business units, rather than the UTC server day.
- **Daily Foreign Exchange**: Looking up the correct daily FX rate from a master repository based on the local trading date in London or Singapore, not the server date in the US.
- Whenever you have a globally distributed EPM application that relies on strict daily processing boundaries.

---

## Category

**Date & Time / System Queries / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetCurrentDateTZ(timezone)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `timezone` | String | ✅ Yes | The standard Java Timezone ID (e.g., `"America/New_York"`, `"Europe/London"`, `"Asia/Tokyo"`). |

---

## Return Value

**Return Type**: Object (Java Date)

Returns a Java Date Object representing the exact current calendar day in the specified timezone.
- **CRITICAL**: Because this returns a Java Object, it **cannot** be saved directly into a standard Essbase numeric account cell. It must be converted into an integer (e.g., using `@CalcMgrFormatDate` to force `YYYYMMDD` format) or passed directly into a difference calculator.
- Note: This function zeros out the *time* component (Hours, Minutes, Seconds). It represents the start of the local day.

---

## How It Works (Behind the Scenes)

1. **Server Ping**: The Java engine queries the host EPM server's operating system clock (UTC).
2. **Timezone Evaluation**: It evaluates the provided `timezone` string and calculates the exact local offset.
3. **Offset Application**: It mathematically applies the offset to the UTC timestamp, ensuring it correctly rolls the calendar day forward or backward if it crosses midnight.
4. **Truncation**: It zeroes out the hour, minute, and second fields on the new local object, isolating just the Calendar Day.
5. **Return**: Passes the resulting Object back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Querying Tokyo's Calendar Date

```essbase
/* Dynamically captures the current calendar day in Tokyo */
VAR vTokyoDateObj = @CalcMgrGetCurrentDateTZ("Asia/Tokyo");
```

---

## Practical Examples

### Example 1: Dynamic Daily FX Rate Lookup

**Scenario**: A massive EPM application stores daily Foreign Exchange (FX) rates at a granular `YYYYMMDD` level in the Time dimension. Regional offices run their calculations at different times of the day. When the Tokyo office runs their script at 9:00 AM on October 2nd, the script must ensure it uses the October 2nd FX rate, even though the UTC server still thinks it is October 1st.

```essbase
FIX("FY25", "Working")
    
    /* Evaluate Tokyo Data */
    FIX("Entity_Tokyo")
        
        /* 
           1. Get the current calendar date in Tokyo.
           This will correctly roll forward to Oct 2nd if it crossed midnight locally.
        */
        VAR vLocalDateObj = @CalcMgrGetCurrentDateTZ("Asia/Tokyo");
        
        /* 
           2. Convert the Java Date Object into a YYYYMMDD string, 
           and then into a pure integer so we can use it to map FX data.
        */
        VAR vLocalDateInt = @CalcMgrDoubleFromString(
            @CalcMgrFormatDate(vLocalDateObj, "yyyyMMdd")
        );
        
        /* 
           3. (Conceptual downstream logic)
           The script can now safely use vLocalDateInt (e.g., 20241002) 
           to look up the correct day's FX rate.
        */
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using Static Abbreviations | Passing `"EST"` | If you pass `"EST"`, Java permanently locks the offset to UTC-5. When Daylight Saving Time arrives, the offset changes. While being 1 hour off rarely changes the *calendar day*, if a user runs the script at exactly 11:30 PM, that 1-hour DST mistake could cause the script to pull the wrong day. Always use geographic IDs like `"America/New_York"` |
| Expecting Time Data | Asking for the local hour | `GetCurrentDateTZ` strictly zeroes out the time. If you need to know if it is 5:00 PM locally, you must use `@CalcMgrGetCurrentDateTimeTZ` instead |
| Direct Database Storage | `"Today_Date" = @CalcMgrGetCurrentDateTZ(...)` | Essbase standard numeric accounts cannot hold Java Objects. You must format it into a `YYYYMMDD` string and convert it to an integer before saving it to a cell |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetCurrentDateTimeTZ`](./@CalcMgrGetCurrentDateTimeTZ.md) | Captures the local timezone date AND perfectly preserves the local time (Hours/Minutes) |
| [`@CalcMgrGetCurrentDate`](./@CalcMgrGetCurrentDate.md) | Captures the current day of the UTC Server, completely ignoring local timezones |
| [`@CalcMgrFormatDate`](./@CalcMgrFormatDate.md) | Safely converts the resulting Java Date Object into a formatted text string (like `"yyyyMMdd"`) so it can be transformed into an Essbase integer |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getcurrentdatetz.html)
