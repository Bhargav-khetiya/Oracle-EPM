# @CalcMgrDateToString

## Overview

`@CalcMgrDateToString` is a **custom Calc Manager string conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes an internal Java `Date` object (often generated dynamically during a calculation) and converts it directly into a human-readable Text String formatted precisely how you want it.

### Why Does This Function Exist?

When executing complex date math in Calc Manager (like adding 3 months to a start date using `@CalcMgrAddDatePart`), the result is a massive, unreadable Java Date object. 
If you want to stamp that result into an Essbase data cell, you use `@CalcMgrConvertJavaDateToDate` to turn it into an integer (e.g., `20241231`).
However, what if you need to output that date into a log file? Or append it to a string for a dynamic member name (e.g., `"Actuals_As_Of_Dec-2024"`)? Or pass it back to an external API via a Groovy script?
`@CalcMgrDateToString` solves this. It acts as a strict formatter, looking at the Java Date object and rendering it as a highly customizable string based on a formatting mask you provide (like `"MM/dd/yyyy"` or `"yyyy-MMM-dd"`).

### When to Use It

- When dynamically constructing member names or target pointers that require a date component (e.g., generating `"Sales_2024-10-25"`).
- To build human-readable audit logs or string attributes inside a Business Rule.
- To format a date exactly to match an external API specification before passing the string back into a Groovy payload.

---

## Category

**Date & Time / String / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDateToString(javaDate, "formatPattern")
```

### Formal Syntax

```
@CalcMgrDateToString(javaDateExpression, "javaSimpleDateFormatString")
```

Where:
- `javaDateExpression` — A serialized Java Date object.
- `"javaSimpleDateFormatString"` — The specific pattern map (in quotes) that tells the engine exactly how you want the string rendered.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `javaDate`| Java Date | ✅ Yes | The Java Date object you wish to convert. |
| `"format"`| String | ✅ Yes | A standard Java `SimpleDateFormat` string. Must be enclosed in double quotes. |

### Common Format Patterns
- `"yyyyMMdd"` : Yields `"20241025"`
- `"MM/dd/yyyy"` : Yields `"10/25/2024"`
- `"MMM-dd-yyyy"` : Yields `"Oct-25-2024"`
- `"yyyy-MM-dd HH:mm:ss"` : Yields `"2024-10-25 14:30:00"` (Includes time data if the Java object possesses it)

---

## Return Value

**Return Type**: String

Returns a literal text string representing the date, fully formatted according to the pattern provided.
*(Note: Because Calc Scripts natively operate on numbers, this string is usually captured in a `VAR` for concatenation, or passed to a text counter).*

---

## How It Works (Behind the Scenes)

1. **Object Inspection**: The function receives the serialized Java Date object.
2. **Pattern Application**: It feeds the object and your `"formatPattern"` into the internal Java `SimpleDateFormat` class.
3. **String Rendering**: Java extracts the year, month, and day from the object and constructs a literal string, inserting your requested delimiters (like slashes or dashes).
4. **Return**: It passes the finalized text string back to the Essbase calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Dashboard Format

```essbase
/* Renders as "12/31/2024" */
VAR vDateStr = @CalcMgrDateToString(vJavaDate, "MM/dd/yyyy");
```

### Variant 2: Generating a Name Suffix

```essbase
/* Renders as "2024_12_31" for use in a dynamic concatenation */
VAR vSuffixStr = @CalcMgrDateToString(vJavaDate, "yyyy_MM_dd");
```

---

## Practical Examples

### Example 1: Creating a Dynamic Member Target

**Scenario**: You have a Daily Sales reporting application. Every time the script runs, it needs to copy data from `"Input_Bucket"` into a daily archival member. The archival members are named literally by their date, like `"Archive_2024-10-25"`. You need to dynamically generate the correct member name based on today's system date.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* 1. Get today's exact date as a Java Object */
    VAR vTodayJava = @CalcMgrGetCurrentDate();
    
    /* 2. Render that date into a string matching our outline format: "yyyy-MM-dd" */
    VAR vDateSuffix = @CalcMgrDateToString(vTodayJava, "yyyy-MM-dd");
    
    /* 3. Concatenate the prefix with the generated date string */
    VAR vTargetStr = @CalcMgrConcat("Archive_", vDateSuffix);
    
    /* 4. Use @MEMBER to point the data to the dynamic destination */
    @MEMBER(vTargetStr) = "Input_Bucket";
    
ENDFIX
```

---

### Example 2: Building an Audit Log String

**Scenario**: When an automated adjustment hits an entity, you want to build a readable string to store in a memory map so a Groovy script can email it to the Controller.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Automated_Adj" != 0)
        
        VAR vEntityStr = @NAME(@CURRMBR("Entity"));
        
        /* Render current time to string: "2024-10-25 14:30:00" */
        VAR vTimeStr = @CalcMgrDateToString(@CalcMgrGetCurrentDate(), "yyyy-MM-dd HH:mm:ss");
        
        /* Build the log: "EntityA updated at 2024-10-25 14:30:00, " */
        VAR vPart1 = @CalcMgrConcat(vEntityStr, " updated at ");
        VAR vPart2 = @CalcMgrConcat(vPart1, vTimeStr);
        VAR vFinalLog = @CalcMgrConcat(vPart2, ", ");
        
        /* Append to the global text counter */
        VAR vDummy = @CalcMgrCounterAddText("Adjustment_Log", vFinalLog);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched `MM` vs `mm` | Using `"yyyy-mm-dd"` | In Java SimpleDateFormat, lowercase `mm` is **minutes**, and uppercase `MM` is **Months**. If you use `mm`, the function will output the minute of the hour instead of the month. Always use `MM` for month |
| Passing Essbase Integers | `@CalcMgrDateToString(20241231, "MM/dd/yyyy")` | This function strictly expects a Java Date object, not an Essbase `YYYYMMDD` integer. If you have an integer, you must first convert it to a Java Date using `@CalcMgrIntegerToDate` or similar functions |
| Missing quotes | Passing the pattern without quotes | The pattern must be a string: `"yyyy-MMM-dd"` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrConvertDateToJavaDate`](../15_CalcMgr_Utility/@CalcMgrConvertDateToJavaDate.md) | The reverse operation (takes a string and turns it into a Java Date) |
| [`@CalcMgrConvertJavaDateToDate`](../15_CalcMgr_Utility/@CalcMgrConvertJavaDateToDate.md) | Converts the Java Date object into an Essbase Integer rather than a String |
| [`@CalcMgrConcat`](../15_CalcMgr_Utility/@CalcMgrConcat.md) | Essential for appending the newly generated date string onto other text elements |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_datetostring.html)
