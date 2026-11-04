# @CalcMgrGetCurrentDateTime

## Overview

`@CalcMgrGetCurrentDateTime` is a **custom Calc Manager date/time function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a dynamic, high-precision system clock query, pinging the underlying EPM Java application server and returning the **Current Date and Exact Time** (down to the second) at the exact moment the calculation script is executed.

### Why Does This Function Exist—

While `@CalcMgrGetCurrentDate` is perfect for finding out what day it is (e.g., Dec 31, 2024), it intentionally erases the time-of-day. However, in modern EPM systems used for High-Frequency Operational Planning, daily tracking is not enough. You must track hours and minutes. 
For example, if an automated job runs every 4 hours, it needs to log exactly when it started and when it finished to calculate its own execution duration. If an SLA dictates that an external API feed must be processed within 60 minutes of receipt, the script must pull the exact current time to verify compliance.
`@CalcMgrGetCurrentDateTime` solves this. It pulls the full Timestamp (Year, Month, Day, Hour, Minute, Second) directly from the Java server clock as a robust Java Date Object. This object can then be passed to functions like `@CalcMgrDateTimeDiff` to calculate exact minute-level variances.

### When to Use It

- **Execution Logging**: Stamping the exact start time and end time of a massive allocation script to monitor system performance degradation over time.
- **SLA Monitoring**: Checking if the current time has surpassed a 5:00 PM cutoff to dynamically route late data submissions into the next day's bucket.
- **Unique IDs**: Using the exact millisecond-level timestamp to generate a unique batch ID for data exports.

---

## Category

**Date & Time / System Queries / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetCurrentDateTime()
```

*(Note: This function takes absolutely no parameters).*

---

## Parameters

**None.**

---

## Return Value

**Return Type**: Object (Java Date / Timestamp)

Returns a Java Timestamp Object representing the exact current server date and time.
- **CRITICAL**: Because this returns a Java Object, it **cannot** be saved directly into a standard Essbase numeric account cell. It must either be formatted into a readable text string (using `@CalcMgrFormatDate`), extracted into integers (using `@CalcMgrExcelHOUR`), or passed directly into a difference calculator.

---

## How It Works (Behind the Scenes)

1. **Server Ping**: The Java engine queries the host EPM server's operating system clock.
2. **Object Instantiation**: It creates a new `java.sql.Timestamp` or `java.util.Date` object.
3. **Preservation**: Unlike the standard `GetCurrentDate` function, it perfectly preserves all hours, minutes, seconds, and fractional milliseconds provided by the OS.
4. **Return**: Passes the resulting Object back to Essbase for immediate use in other formulas.

---

## Syntax Variants & Scenarios

### Variant 1: Storing the Start Time of a Script

```essbase
/* Captures the exact moment the script begins execution */
VAR vScriptStartTime = @CalcMgrGetCurrentDateTime();
```

---

## Practical Examples

### Example 1: Self-Monitoring Script Execution Duration

**Scenario**: An administrator has a massive driver-based allocation script that runs across 50 entities. They suspect the script is getting slower every month as data volume grows. They want the script to automatically calculate exactly how many seconds it took to run, and save that metric into a tracking cube (`"Admin_Metrics"`).

```essbase
/* 1. Capture the exact start time BEFORE the calculation begins */
VAR vStartTimeObj = @CalcMgrGetCurrentDateTime();

/* ------------------------------------------------ */
/* ... MASSIVE ALLOCATION BLOCK EXECUTES HERE ...   */
/* ------------------------------------------------ */
FIX("FY25", "Working", @IDESCENDANTS("Total_Geography"))
    /* Allocation logic */
    "Allocated_Expense" = "Corporate_Overhead" * "Driver_Pct";
ENDFIX
/* ------------------------------------------------ */

/* 2. Capture the exact end time AFTER the calculation finishes */
VAR vEndTimeObj = @CalcMgrGetCurrentDateTime();

/* 3. Calculate the exact duration in Seconds */
/* Note: We isolate the write-back to a single dummy intersection so it only writes once */
FIX("No_Year", "No_Scenario", "No_Entity")
    
    "Script_Duration_Seconds" = @CalcMgrDateTimeDiff(vStartTimeObj, vEndTimeObj, "s");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting Direct Storage | `"Time_Stamp" = @CalcMgrGetCurrentDateTime();` | Essbase standard numeric accounts cannot hold Java Objects. If you try to save the result of this function directly into an account block, it will fail or store a useless hash. You must format it into a string or extract specific integer components |
| Timezone Discrepancies | Assuming "5:00 PM" means the user's local time | This function returns the current time of the *physical Oracle EPM Server* (which is universally set to UTC in the Cloud), NOT the local timezone of the user running the rule. If a user in New York runs a rule at 3:00 PM, this function will return 7:00 PM (UTC) or 8:00 PM depending on Daylight Saving. If your SLA logic requires local timezone awareness, use `@CalcMgrGetCurrentDateTimeTZ` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetCurrentDateTimeTZ`](./@CalcMgrGetCurrentDateTimeTZ.md) | Captures the exact time, but automatically adjusts it to match a specific local Timezone |
| [`@CalcMgrGetCurrentDate`](./@CalcMgrGetCurrentDate.md) | Captures the current day, but intentionally zeroes out the Hours/Minutes/Seconds |
| [`@CalcMgrDateTimeDiff`](./@CalcMgrDateTimeDiff.md) | Calculates the exact seconds/minutes/hours between two timestamp objects |
| [`@CalcMgrFormatDate`](./@CalcMgrFormatDate.md) | Safely converts the Java Timestamp Object into a readable text string (like `"12/31/2024 18:45:00"`) for storage in a Text Account |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getcurrentdatetime.html)
