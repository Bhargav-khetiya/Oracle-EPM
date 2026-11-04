# @CalcMgrExcelToDateTime

## Overview

`@CalcMgrExcelToDateTime` is a **custom Calc Manager date/time conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of a Microsoft Excel date/time conversion, bridging the gap between legacy Excel serial numbers and modern enterprise Java architectures. 
It analyzes a massive decimal that Excel uses to track time (e.g., `45657.75`) and securely converts it into a **Java Date/Timestamp object**, fully preserving both the calendar day and the exact down-to-the-second time.

### Why Does This Function Exist—

Microsoft Excel tracks time using a continuous floating-point serial number starting from January 1, 1900. The integer portion represents the Day (e.g., `45657` is Dec 31, 2024), and the fractional decimal represents the Time of day (`0.75` is exactly 18:00:00, or 6:00 PM). 
While `@CalcMgrExcelToDate` chops off the fraction and returns a `YYYYMMDD` integer, that is useless if you are building High-Frequency Operational Models that require millisecond or second-level SLA tracking. You cannot store "6:00 PM" easily inside a `YYYYMMDD` integer without massive string manipulation. 
`@CalcMgrExcelToDateTime` completely resolves this. It ingests the raw Excel decimal, mathematically derives the exact day, hour, minute, and second, and packages them securely into a standard Java Timestamp object. This object can then be passed to advanced EPM time-difference functions (like `@CalcMgrDaysBetween` or `@CalcMgrDateTimeDiff`) for flawless execution.

### When to Use It

- **SLA Tracking**: Converting an Excel timestamp load into a format that Essbase can use to calculate exactly how many minutes elapsed between two events.
- **Micro-Batch Operations**: Extracting time-of-day data from raw ERP extracts to categorize transactions into morning vs. evening volume buckets.
- Whenever you need to migrate an Excel spreadsheet containing exact serial-time algebra directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelToDateTime(serial_number)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serial_number` | Numeric | ✅ Yes | The Excel Serial Date/Time decimal to evaluate (e.g., `45657.75`). |

---

## Return Value

**Return Type**: Object (Java Date / Timestamp)

Returns a highly precise Java Date Object representing the exact day and time.
- Note: You cannot store a Java Object directly into a standard Essbase numeric account cell. You must either use this object immediately inside another Calc Manager date function (like `HOUR` or `DaysBetween`), or convert it to a string/custom integer before saving it to the database.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the full floating-point decimal.
2. **Integer Math (The Day)**: It adds the integer portion (`45657`) to the Excel epoch baseline (Jan 1, 1900) to find the exact calendar day.
3. **Fractional Math (The Time)**: It isolates the decimal (`0.75`). It multiplies by 24 to find the hours, subtracts the integer remainder, multiplies by 60 to find the minutes, etc.
4. **Object Construction**: It creates a new `java.util.Date` or Timestamp object and injects all these exact values into it.
5. **Return**: Passes the resulting Object back to Essbase for use in other functions.

---

## Syntax Variants & Scenarios

### Variant 1: Creating a Java Object for Time Math

```essbase
/* 
   Assume 45657.75 is Dec 31, 2024 at 6:00 PM. 
   Creates a temporary Date Object in memory. 
*/
VAR vTimeObject = @CalcMgrExcelToDateTime(45657.75);
```

---

## Practical Examples

### Example 1: Calculating the Exact Minutes Between Two Excel Timestamps

**Scenario**: A telecom company tracks API response times. The "Request" and "Response" times are logged by an external system and loaded into Essbase as raw Excel serial numbers (`45657.1234` and `45657.1245`). The script must convert these raw decimals into Java Objects, and then calculate exactly how many minutes elapsed between them.

```essbase
FIX("FY25", "Working", "API_Transaction_Logs")
    
    IF("Request_Time_Raw" != #MISSING AND "Response_Time_Raw" != #MISSING)
        
        /* 
           1. Convert the raw Excel serial decimals into true Java Date objects.
           This preserves both the day and the exact time fraction.
        */
        VAR vStartObj = @CalcMgrExcelToDateTime("Request_Time_Raw");
        VAR vEndObj = @CalcMgrExcelToDateTime("Response_Time_Raw");
        
        /* 
           2. Pass the Date Objects into the standard DateTimeDiff function
           to calculate the exact difference in Minutes (parameter 'n').
        */
        "Total_Minutes_Elapsed" = @CalcMgrDateTimeDiff(vStartObj, vEndObj, "n");
        
        /* 3. Flag transactions that breached the 5-minute SLA */
        IF("Total_Minutes_Elapsed" > 5)
            "SLA_Breach_Flag" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Save the Object | `"Date_Stamp" = @CalcMgrExcelToDateTime(45657)` | Essbase standard numeric accounts cannot hold Java Objects. If you try to save the result of this function directly into an account block, it will either throw a Type Mismatch validation error, or force the object into a completely useless hash string. You must use this function *inside* a variable (`VAR`), or wrap it in an extraction function like `@CalcMgrExcelHOUR( ... )` |
| Passing Essbase Dates | `@CalcMgrExcelToDateTime(20241231.12)` | This function explicitly expects an *Excel* Serial Date decimal. Native Essbase `YYYYMMDD` formats are completely incompatible with this function. If you need to convert an Essbase date into a Java object, use `@CalcMgrIntegerToDate` instead |
| Assuming Millisecond Precision | Converting `.123456` | While Java Timestamps support milliseconds, Excel serial numbers suffer from extreme floating-point drift at the 5th and 6th decimal places. `ToDateTime` applies micro-rounding to guarantee accuracy down to the Second, but anything smaller than a second is not mathematically reliable in an Excel serial conversion |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelToDate`](./@CalcMgrExcelToDate.md) | Drops the time component and strictly returns a `YYYYMMDD` integer |
| [`@CalcMgrDateTimeDiff`](@CalcMgrDateDiff.md) | The primary function used downstream to calculate the difference between two Java Date objects |
| [`@CalcMgrIntegerToDate`](../15_CalcMgr_Utility/@CalcMgrConvertDateToJavaDate.md) | Converts a native Essbase `YYYYMMDD` integer into a Java Date object |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceltodatetime.html)
