# @CalcMgrGetStringFormattedDateTime

## Overview

`@CalcMgrGetStringFormattedDateTime` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a fully constructed **Java Timestamp Object** (which contains both the calendar date and the exact time of day) and seamlessly converts it into a highly customizable **Text String** based on standard Java date formatting patterns.

### Why Does This Function Exist—

When capturing audit trails, system performance logs, or executing automated daily flat-file exports from Essbase, administrators must include exact Timestamps. 
While functions like `@CalcMgrGetCurrentDateTime()` perfectly capture the current timestamp, they return it as a Java Object in memory. Essbase cannot export Java Objects to a CSV file, nor can it save them directly into a cell. 
`@CalcMgrGetStringFormattedDateTime` serves as the final bridge. It intercepts the Java Timestamp Object, applies a precise format mask (e.g., `"yyyy-MM-dd HH:mm:ss"`), and returns a perfect Text String (e.g., `"2024-12-31 18:30:00"`). This string can then be saved into a Text Account, embedded in an `@RETURN` error message, or exported to a downstream SQL warehouse.

### When to Use It

- **Automated Audit Logging**: Stamping the exact date and time an allocation script was executed directly into a "Last_Run_Time" Text Account.
- **Dynamic File Naming**: Generating dynamic timestamp strings (e.g., `"20241231_1830"`) to append to the end of automated MaxL file exports.
- **Executive Error Alerts**: Displaying human-readable times (e.g., `"Fail Time: 06:30 PM"`) inside pop-up validation messages.

---

## Category

**Date & Time / Text Formatting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetStringFormattedDateTime(date_object, format_pattern)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date_object` | Object | ✅ Yes | The Java Date or Timestamp Object to be formatted. |
| `format_pattern` | String | ✅ Yes | The exact `java.text.SimpleDateFormat` mask that tells the engine how to draw the string (e.g., `"yyyy-MM-dd HH:mm:ss"`). |

### Common Pattern Symbols

| Symbol | Description | Example Pattern | Result String |
|--------|-------------|-----------------|---------------|
| `yyyy` | 4-digit Year | `"yyyy/MM/dd"` | `"2024/12/31"` |
| `MM` | 2-digit Month | `"MM-dd-yyyy"` | `"12-31-2024"` |
| `MMM` | 3-letter Month | `"dd-MMM-yyyy"` | `"31-Dec-2024"` |
| `HH` | 24-hour Time | `"HH:mm:ss"` | `"18:30:00"` (6:30 PM) |
| `hh` | 12-hour Time | `"hh:mm:ss a"` | `"06:30:00 PM"` |

---

## Return Value

**Return Type**: String

Returns the perfectly formatted Timestamp as a Text String.
- Because the output is a string, it **cannot** be saved directly into a standard Essbase numeric account cell. It must be saved into a Smart List / Text Account or used dynamically in a string concatenation.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Timestamp Object and the pattern string.
2. **Formatting Engine**: It instantiates a `java.text.SimpleDateFormat` object using the provided pattern.
3. **Execution**: It passes the Timestamp Object through the formatter, translating the internal binary calendar data into the exact visual character layout requested.
4. **Return**: Passes the resulting Text String back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Creating a Loggable Timestamp

```essbase
/* Captures the exact current time and formats it as a readable string */
VAR vLogString = @CalcMgrGetStringFormattedDateTime(
    @CalcMgrGetCurrentDateTime(), 
    "yyyy-MM-dd HH:mm:ss"
);
/* Result: "2024-12-31 18:45:00" */
```

---

## Practical Examples

### Example 1: Dynamic Validation Error Messages

**Scenario**: A company has a strict SLA. Data submissions must occur before 6:00 PM. If a user submits late, the script rejects the data and throws an error message containing the exact time they attempted the load. 

```essbase
FIX("FY25", "Working", "No_Entity")
    
    /* 1. Capture the exact submission timestamp */
    VAR vSubmissionTimeObj = @CalcMgrGetCurrentDateTime();
    
    /* 2. Extract just the Hour to evaluate the SLA */
    VAR vHour = @CalcMgrGetDateTimePart(vSubmissionTimeObj, "hour");
    
    /* 3. If they are late (>= 18:00) */
    IF(vHour >= 18)
        
        /* 
           4. Format the raw timestamp object into a human-readable 12-hour string 
           so the executive understands the error. 
        */
        VAR vTimeString = @CalcMgrGetStringFormattedDateTime(vSubmissionTimeObj, "hh:mm:ss a");
        
        /* 
           5. Concatenate the string into the final error message and Abort.
        */
        VAR vErrorMessage = @CONCATENATE("Submission Rejected. Deadline is 6:00 PM. Your load time was: ", vTimeString);
        @RETURN(vErrorMessage, ERROR);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a YYYYMMDD Integer | `@CalcMgrGetStringFormattedDateTime(20241231, "yyyy")` | This function explicitly requires a **Java Timestamp Object**. If you pass a native Essbase integer or text string as the first parameter, the Java engine will fail. You must pass an object (e.g., generated by `@CalcMgrGetCurrentDateTime`) |
| Case Sensitivity | Using `"mm"` for Months | In Java formatting, `MM` (capital) means Months. `mm` (lowercase) means Minutes. If you use `"yyyy-mm-dd"`, the engine will output the Minutes where the Month should be, resulting in an entirely corrupted string. Always follow strict Java capitalization rules |
| Missing Time Data | Passing a Date Object instead of a Timestamp Object | If you pass an object generated by `@CalcMgrGetCurrentDate()` (which intentionally zeroes out the time) and apply an `"HH:mm:ss"` mask, the output will stubbornly say `"00:00:00"`. If you want real time data, you must supply a true Timestamp object |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrFormatDate`](./@CalcMgrFormatDate.md) | An identical wrapper function that does the exact same thing. (Often used for Date objects rather than Timestamps, but technically identical under the hood) |
| [`@CalcMgrGetFormattedDate`](./@CalcMgrGetFormattedDate.md) | The exact inverse function: Takes a formatted Text String and parses it backward into a Java Date Object |
| [`@CalcMgrFormatDouble`](./@CalcMgrFormatDouble.md) | Applies similar formatting mask rules, but specifically for converting numeric decimals into readable strings (like currencies) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getstringformatteddatetime.html)
