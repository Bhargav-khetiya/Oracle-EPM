# @CalcMgrGetCustomDateTime

## Overview

`@CalcMgrGetCustomDateTime` is a **custom Calc Manager date/time instantiation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes six distinct integers (Year, Month, Day, Hour, Minute, Second) and systematically fuses them together into a highly precise **Java Timestamp Object**.

### Why Does This Function Exist—

When processing external API logs, manufacturing machine telemetry, or global SLA tracking data, the time-of-day is just as critical as the calendar date. If an administrator needs to simulate a specific cutoff time (e.g., "December 31st, 2024 at exactly 5:00 PM") to test whether incoming transactional data is late, they must construct that exact timestamp in memory.
While `@CalcMgrGetCustomDate` builds a day but forces the time to Midnight (`00:00:00`), `@CalcMgrGetCustomDateTime` allows you to explicitly control the time component. It perfectly constructs a true Java Timestamp Object from the raw integer components, instantly validating the calendar and clock logic (e.g., automatically rolling the hour over if you pass "65 minutes") and returning an object ready for advanced Java time-difference processing.

### When to Use It

- **SLA Threshold Generation**: Constructing hardcoded 5:00 PM cutoff objects to compare against actual transaction submission times.
- **Log Parsing**: Reassembling a full timestamp object from a flat file where Year, Month, Day, Hour, and Minute were loaded into five separate Essbase text/numeric accounts.
- **Shift Operations**: Creating dynamic start/end boundaries for manufacturing shifts (e.g., "Shift 3 ends at 06:00:00").

---

## Category

**Date & Time / Object Instantiation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetCustomDateTime(year, month, day, hour, minute, second)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `year` | Numeric | ✅ Yes | A four-digit integer representing the Year (e.g., `2024`). |
| `month` | Numeric | ✅ Yes | An integer representing the Month. <br>**CRITICAL RULE**: In Java Calendar architecture, months are 0-indexed. January is `0`, December is `11`. |
| `day` | Numeric | ✅ Yes | An integer representing the Day of the Month (e.g., `1` to `31`). |
| `hour` | Numeric | ✅ Yes | An integer representing the Hour in 24-hour format (e.g., `17` for 5:00 PM). Range `0-23`. |
| `minute` | Numeric | ✅ Yes | An integer representing the Minute (e.g., `0-59`). |
| `second` | Numeric | ✅ Yes | An integer representing the Second (e.g., `0-59`). |

---

## Return Value

**Return Type**: Object (Java Date / Timestamp)

Returns a highly precise Java Timestamp Object.
- **CRITICAL**: Because this returns a Java Object, it **cannot** be saved directly into a standard Essbase numeric account cell. It must either be converted into a readable string (using `@CalcMgrFormatDate`) or passed directly into a difference calculator like `@CalcMgrDateTimeDiff`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives all six integers.
2. **Object Instantiation**: It creates a new `java.util.Calendar` object.
3. **Property Injection**: It sets the `Calendar.YEAR`, `Calendar.MONTH`, `Calendar.DAY_OF_MONTH`, `HOUR_OF_DAY`, `MINUTE`, and `SECOND` properties using your integers.
4. **Clock Validation (Rollover)**: Java's calendar engine handles rollover automatically. If you pass `hour = 23` and `minute = 65`, it will realize 65 minutes is invalid. It will automatically roll the time forward to `hour = 00` (Midnight of the *next day*) and `minute = 5`.
5. **Return**: Passes the finalized Java Timestamp Object back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Creating a Strict 5:00 PM Cutoff Object

```essbase
/* 
   Year: 2024
   Month: 11 (December, 0-indexed)
   Day: 31
   Time: 17:00:00 (5:00 PM)
   Result: Creates a Java Timestamp Object for Dec 31, 2024 at 5:00 PM.
*/
VAR vDeadlineObj = @CalcMgrGetCustomDateTime(2024, 11, 31, 17, 0, 0);
```

---

## Practical Examples

### Example 1: Enforcing an End-of-Month 11:59 PM Data Submission Cutoff

**Scenario**: A corporate controller requires all regional offices to submit their data by 11:59 PM on the final day of the month. The EPM system logs the exact time the user clicked "Submit" in a timestamp variable. The calculation script must dynamically construct the 11:59 PM deadline object for the current month, compare it to the user's submission time, and reject the data if it is late.

```essbase
FIX("FY25", "Working")
    
    /* 1. Capture the exact moment the user hit Submit */
    VAR vSubmissionTimeObj = @CalcMgrGetCurrentDateTime();
    
    /* 2. Extract the current Year and Month */
    VAR vCurrentYear = @CalcMgrGetDatePart(vSubmissionTimeObj, "year");
    VAR vCurrentMonth = @CalcMgrGetDatePart(vSubmissionTimeObj, "month");
    
    /* 
       3. We need the Last Day of the Month.
       We can extract it from the current date object.
    */
    VAR vLastDay = @CalcMgrGetDatePart(vSubmissionTimeObj, "lastdayofmonth");
    
    /* 
       4. Construct the Absolute Deadline Object.
       Time is set to 23:59:59 (11:59:59 PM).
    */
    VAR vDeadlineObj = @CalcMgrGetCustomDateTime(
        vCurrentYear, 
        vCurrentMonth, 
        vLastDay, 
        23, 59, 59
    );
    
    /* 
       5. Calculate if the Submission happened AFTER the Deadline.
       If the difference in seconds is negative, they were late.
    */
    VAR vSecondsDifference = @CalcMgrDateTimeDiff(vDeadlineObj, vSubmissionTimeObj, "s");
    
    IF(vSecondsDifference < 0)
        @RETURN("Error: Data Submission Rejected. You missed the EOM deadline.", ERROR);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting Month is 0-Indexed | Passing `12` for December | Months are `0-11`. January is `0`. December is `11`. If you pass `12`, it rolls the year forward +1 and sets the month to January |
| Using 12-Hour Time | Passing `5` for 5:00 PM | The `hour` parameter strictly expects 24-hour (military) time. If you want 5:00 PM, you must pass `17`. If you pass `5`, the system will set the deadline to 5:00 AM in the morning |
| Attempting Direct Storage | `"Target" = @CalcMgrGetCustomDateTime(...)` | Essbase standard numeric accounts cannot hold Java Objects. If you try to save the result directly, it will fail |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetCustomDate`](./@CalcMgrGetCustomDate.md) | Constructs a Date Object but automatically zeroes out the time to 00:00:00 |
| [`@CalcMgrGetDateTimePart`](./@CalcMgrGetDateTimePart.md) | The exact inverse function: Takes a Java Timestamp Object and extracts the individual Hour, Minute, or Second integer |
| [`@CalcMgrDateTimeDiff`](./@CalcMgrDateTimeDiff.md) | The primary function used to compare the custom timestamp you just built against another timestamp |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getcustomdatetime.html)
