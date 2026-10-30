# @CalcMgrConvertDateTimeToJavaDate

## Overview

`@CalcMgrConvertDateTimeToJavaDate` is a **custom Calc Manager date conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a fully detailed date-time string (like `"2024-12-31 23:59:59"`) and converts it into an internal Java `Date` object, allowing the Calc Manager engine to perform complex calendar math on it.

### Why Does This Function Exist?

In modern cloud architectures, data often flows into EPM from external systems (ERP, HRIS, CRM) via flat files or REST APIs. These external systems frequently provide timestamps in string formats (e.g., `"YYYY-MM-DD HH:MM:SS"`). 
Essbase natively cannot perform math on a string like `"2024-12-31 23:59:59"`. If you want to know how many hours have passed since that timestamp, or if you want to add 3 days to it, you must first translate that text string into a mathematical object the engine understands.
This function acts as a translator, reading the text string, parsing the specific date and time components, and generating a highly accurate Java `Date` object (which is stored as a serialized integer representing milliseconds since the Unix epoch).

### When to Use It

- When importing system-generated timestamps from external systems (like Oracle Fusion or Workday) and performing duration math on them.
- When you need to capture the exact time of day, not just the calendar date.
- When generating detailed SLA (Service Level Agreement) compliance metrics (e.g., checking if a task was completed within 48 hours of the creation timestamp).
- Inside Groovy-backed Business Rules that require strict `Date` objects rather than `YYYYMMDD` integers.

---

## Category

**Date & Time / String / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrConvertDateTimeToJavaDate(dateTimeString, "formatPattern")
```

### Formal Syntax

```
@CalcMgrConvertDateTimeToJavaDate(dateTimeStringExpression, "javaSimpleDateFormatString")
```

Where:
- `dateTimeStringExpression` — The raw text string containing the date and time.
- `"javaSimpleDateFormatString"` — The specific pattern map (in quotes) that tells the engine how to read the string (e.g., `"yyyy-MM-dd HH:mm:ss"`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dateTimeString`| String | ✅ Yes | The text string containing the timestamp (e.g., `"2024/10/25 14:30:00"`). |
| `"format"` | String | ✅ Yes | A standard Java `SimpleDateFormat` string that maps to the text input. Must be in double quotes. |

### Common Format Patterns
- `yyyy` : 4-digit Year
- `MM` : 2-digit Month (Must be capitalized to differentiate from minutes)
- `dd` : 2-digit Day
- `HH` : 2-digit Hour (24-hour military format)
- `mm` : 2-digit Minute (lowercase)
- `ss` : 2-digit Second

---

## Return Value

**Return Type**: Date (Serialized Integer)

Returns a highly precise serialized integer (milliseconds) representing the exact Java `Date` object. 

---

## How It Works (Behind the Scenes)

1. **Pattern Matching**: The function takes the `formatPattern` and lays it over the `dateTimeString`.
   - String: `"2024-10-25 14:30:00"`
   - Pattern: `"yyyy-MM-dd HH:mm:ss"`
2. **Parsing**: It extracts `2024` as the year, `10` as the month, `14` as the hour, etc.
3. **Object Initialization**: It feeds these extracted integers into the Java `java.util.Date` class, initializing a true calendar object.
4. **Serialization**: It converts the object into a serialized number (Unix time) so it can be passed around in the calculation engine or stored in a numeric block.

---

## Syntax Variants & Scenarios

### Variant 1: Parsing Standard ISO 8601 Timestamps

```essbase
/* Converts a standard hyphenated timestamp */
VAR vJavaDate = @CalcMgrConvertDateTimeToJavaDate("2024-12-31 18:45:00", "yyyy-MM-dd HH:mm:ss");
```

### Variant 2: Parsing Slash-Delimited Timestamps

```essbase
/* Converts an Excel-style American timestamp */
VAR vJavaDate = @CalcMgrConvertDateTimeToJavaDate("12/31/2024 18:45:00", "MM/dd/yyyy HH:mm:ss");
```

---

## Practical Examples

### Example 1: Calculating SLA Compliance (Hours Between)

**Scenario**: A helpdesk IT planning model tracks the exact time a ticket was created, and the exact time it was resolved (stored as Text Attributes or String Accounts). You need to calculate the total resolution time in hours to measure SLA compliance.

```essbase
FIX("FY25", "Actual", @LEVEL0("Tickets"))
    
    /* 1. Extract the raw string timestamps from the cube */
    VAR vCreateStr = @ATTRIBUTESVAL("Create_Timestamp");
    VAR vResolveStr = @ATTRIBUTESVAL("Resolve_Timestamp");
    
    /* 2. Ensure both strings exist */
    IF(vCreateStr != "" AND vResolveStr != "")
        
        /* 3. Convert both strings into mathematical Java Date objects */
        VAR vCreateDate = @CalcMgrConvertDateTimeToJavaDate(vCreateStr, "yyyy-MM-dd HH:mm:ss");
        VAR vResolveDate = @CalcMgrConvertDateTimeToJavaDate(vResolveStr, "yyyy-MM-dd HH:mm:ss");
        
        /* 4. Use a Calc Manager datetime math function to find the difference in hours */
        "Resolution_Hours" = @CalcMgrDateTimeDiff(vCreateDate, vResolveDate, "hour");
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Shifting Time Zones

**Scenario**: A global company stores all timestamps in UTC. The regional controller in New York wants to run a calculation based on Eastern Standard Time (EST). You must convert the UTC string to a Date object, subtract 5 hours (for EST), and output the result.

```essbase
FIX("FY25", "Actual", @LEVEL0("Transactions"))
    
    VAR vUTCStr = @ATTRIBUTESVAL("Transaction_Time_UTC");
    
    IF(vUTCStr != "")
        /* Convert to Date Object */
        VAR vUTCDate = @CalcMgrConvertDateTimeToJavaDate(vUTCStr, "yyyy-MM-dd HH:mm:ss");
        
        /* Add -5 Hours to the Date object using a theoretical AddDateTime function */
        VAR vESTDate = @CalcMgrAddDatePart(vUTCDate, -5, "hour");
        
        /* Note: Once manipulated, the date is often formatted back to a string for reporting */
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched `MM` vs `mm` | Using `"yyyy-mm-dd HH:MM:ss"` | In Java SimpleDateFormat, lowercase `mm` is **minutes**, and uppercase `MM` is **Months**. If you swap them, the parser will think January is the 1st minute of the hour, causing catastrophic data corruption. Always use `MM` for month and `mm` for minutes |
| Missing quotes | Passing the pattern without quotes | The pattern must be a string: `"yyyy-MM-dd HH:mm:ss"` |
| Format mismatch | Using pattern `"yyyy-MM-dd"` on string `"2024/10/25"` | The delimiters (slashes vs hyphens) must match exactly. The parser is completely rigid and will fail if the pattern does not map 1-to-1 with the text string |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrConvertDateToJavaDate`](./@CalcMgrConvertDateToJavaDate.md) | The equivalent function for dates that do not have a time component (e.g., just "2024-12-31") |
| [`@CalcMgrDateTimeToExcel`](./@CalcMgrDateTimeToExcel.md) | Converts a Java Date object into an Excel Serial Date for reporting exports |
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | Commonly used to calculate the math between two converted Java Date objects |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_convertdatetimetojava.html)
