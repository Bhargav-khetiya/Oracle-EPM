# @CalcMgrConvertDateToJavaDate

## Overview

`@CalcMgrConvertDateToJavaDate` is a **custom Calc Manager date conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a date string (without a time component) and converts it into an internal Java `Date` object, enabling the Calc Manager engine to perform complex calendar math on it.

### Why Does This Function Exist?

In modern cloud architectures, data flows into EPM from external systems (ERP, HRIS, CRM) via flat files or APIs. These external systems frequently provide dates as text strings (e.g., `"YYYY-MM-DD"` or `"MM/DD/YYYY"`). 
Essbase natively cannot perform mathematical operations on a text string like `"2024-12-31"`. If you want to calculate exactly how many days have passed since that date, or if you want to add 6 months to it for a forecasting model, you must first translate that text string into a mathematical object that the engine understands.
Unlike `@CalcMgrConvertDateTimeToJavaDate` (which handles timestamps with hours and minutes), this function is streamlined specifically for plain calendar dates, ensuring that the time component is zeroed out (midnight UTC) to prevent rounding errors in daily math.

### When to Use It

- When importing system-generated dates from external systems and performing duration math on them.
- To validate string inputs in custom Calc Manager business rules (e.g., validating a user-provided date string).
- Inside Groovy-backed Business Rules that require strict Java `Date` objects rather than simple `YYYYMMDD` integer representations.
- When generating detailed SLA or lifecycle compliance metrics based purely on days, rather than hours.

---

## Category

**Date & Time / String / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrConvertDateToJavaDate(dateString, "formatPattern")
```

### Formal Syntax

```
@CalcMgrConvertDateToJavaDate(dateStringExpression, "javaSimpleDateFormatString")
```

Where:
- `dateStringExpression` — The raw text string containing the date.
- `"javaSimpleDateFormatString"` — The specific pattern map (in quotes) that tells the engine how to parse the string (e.g., `"yyyy-MM-dd"`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dateString`| String | ✅ Yes | The text string containing the date (e.g., `"2024/10/25"`). Can be hardcoded in quotes or pulled dynamically from a Text Attribute. |
| `"format"` | String | ✅ Yes | A standard Java `SimpleDateFormat` string that maps perfectly to the text input. Must be enclosed in double quotes. |

### Common Format Patterns
- `yyyy` : 4-digit Year (e.g., 2024)
- `yy` : 2-digit Year (e.g., 24)
- `MM` : 2-digit Month (Must be capitalized!)
- `MMM` : 3-letter Month abbreviation (e.g., Jan, Feb)
- `dd` : 2-digit Day

---

## Return Value

**Return Type**: Date (Serialized Integer)

Returns a highly precise serialized integer (milliseconds since the Unix epoch) representing the exact Java `Date` object, with the time component implicitly set to 00:00:00 (Midnight).

---

## How It Works (Behind the Scenes)

1. **Pattern Matching**: The function takes the `formatPattern` and applies it as a decoding mask over the `dateString`.
   - String: `"10/25/2024"`
   - Pattern: `"MM/dd/yyyy"`
2. **Parsing & Extraction**: It extracts `2024` as the year, `10` as the month, and `25` as the day.
3. **Object Initialization**: It feeds these extracted integers into the Java `java.util.Date` class, initializing a true calendar object set to Midnight.
4. **Serialization**: It converts the calendar object into a serialized number so it can be utilized mathematically by downstream Calc Manager functions like `@CalcMgrDaysBetween` or `@CalcMgrAddMonths`.

---

## Syntax Variants & Scenarios

### Variant 1: Parsing Standard ISO 8601 Dates

```essbase
/* Converts a standard hyphenated date string */
VAR vJavaDate = @CalcMgrConvertDateToJavaDate("2024-12-31", "yyyy-MM-dd");
```

### Variant 2: Parsing Slash-Delimited American Dates

```essbase
/* Converts an Excel-style American date */
VAR vJavaDate = @CalcMgrConvertDateToJavaDate("12/31/2024", "MM/dd/yyyy");
```

---

## Practical Examples

### Example 1: Calculating Days Outstanding for Accounts Receivable

**Scenario**: A working capital planning model tracks open invoices. The invoice date is imported from the ERP as a text attribute (`"yyyy-MM-dd"`). You need to calculate how many days the invoice has been outstanding relative to the current system date, so you can bucket it into an aging report (e.g., 0-30 Days, 31-60 Days).

```essbase
FIX("FY25", "Actual", @LEVEL0("Invoice"))
    
    /* 1. Extract the raw string date from the cube attribute */
    VAR vInvoiceStr = @ATTRIBUTESVAL("Invoice_Date_Text");
    
    /* 2. Get the current system date as a Java Date object */
    VAR vTodayJava = @CalcMgrGetCurrentDate();
    
    /* 3. Ensure the invoice string exists */
    IF(vInvoiceStr != "")
        
        /* 4. Convert the string into a mathematical Java Date object */
        VAR vInvoiceJava = @CalcMgrConvertDateToJavaDate(vInvoiceStr, "yyyy-MM-dd");
        
        /* 5. Calculate the difference in days */
        "Days_Outstanding" = @CalcMgrDaysBetween(vInvoiceJava, vTodayJava);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Normalizing Disparate Source Data Formats

**Scenario**: You have an HR model that pulls headcount data from two different systems. One system sends hire dates as `"MM/dd/yyyy"`, and the other sends them as `"yyyy-MM-dd"`. You need to standardize them into a single, clean `YYYYMMDD` integer for Essbase to use natively.

```essbase
FIX("FY25", "Actual", @LEVEL0("Employee"))
    
    VAR vSourceA = @ATTRIBUTESVAL("Hire_Date_SystemA"); /* Format: MM/dd/yyyy */
    VAR vSourceB = @ATTRIBUTESVAL("Hire_Date_SystemB"); /* Format: yyyy-MM-dd */
    
    VAR vJavaDate = #MISSING;
    
    IF(vSourceA != "")
        vJavaDate = @CalcMgrConvertDateToJavaDate(vSourceA, "MM/dd/yyyy");
    ELSEIF(vSourceB != "")
        vJavaDate = @CalcMgrConvertDateToJavaDate(vSourceB, "yyyy-MM-dd");
    ENDIF
    
    /* Once converted to a universal Java Date, we can push it into a standard Essbase integer */
    IF(vJavaDate != #MISSING)
        "Hire_Date_Standardized" = @CalcMgrConvertJavaDateToDate(vJavaDate);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched `MM` vs `mm` | Using `"yyyy-mm-dd"` | In Java SimpleDateFormat, lowercase `mm` is **minutes**, and uppercase `MM` is **Months**. If you use `mm`, the parser will fail or generate bad data. Always use `MM` for month |
| Including Time Components | Passing `"2024-10-25 14:30:00"` to this function | This function specifically expects date-only strings. If the string contains a time component, the parser will throw an exception. Use `@CalcMgrConvertDateTimeToJavaDate` instead |
| Missing quotes | Passing the pattern without quotes | The pattern must be a string: `"yyyy-MM-dd"` |
| Format mismatch | Using pattern `"yyyy-MM-dd"` on string `"2024/10/25"` | The delimiters (slashes vs hyphens) must match exactly. The parser is completely rigid and will fail if the pattern does not map perfectly to the text string |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrConvertDateTimeToJavaDate`](./@CalcMgrConvertDateTimeToJavaDate.md) | The equivalent function for strings that *do* contain a time component |
| [`@CalcMgrConvertJavaDateToDate`](./@CalcMgrConvertJavaDateToDate.md) | Converts the Java Date object back into a standard `YYYYMMDD` Essbase integer |
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | Commonly used to calculate the math between two converted Java Date objects |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_convertdatetojava.html)
