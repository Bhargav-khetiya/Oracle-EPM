# @CalcMgrGetFormattedDate

## Overview

`@CalcMgrGetFormattedDate` is a **custom Calc Manager date instantiation and parsing function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a powerful bridge, taking a **Text String** that contains a date (like `"15-Jan-2024"` or `"2024/12/31 18:30"`) and securely parsing it into a highly precise **Java Date Object**.

### Why Does This Function Exist?

In the real world, date data rarely arrives in perfect `YYYYMMDD` Essbase integers or pristine Excel Serial Decimals. Dates loaded from external CRM systems (like Salesforce), HR systems (like Workday), or manual flat-file uploads usually arrive as raw text strings (e.g., `"12-31-2024"`). 
Essbase math functions cannot calculate "Days Between" if the input is a text string containing dashes or slashes. Before you can perform any calendar math, you must convert that text string into a Java Date Object. 
`@CalcMgrGetFormattedDate` completely resolves this. By providing the raw text string and the corresponding Java formatting mask (e.g., `"MM-dd-yyyy"`), the Java engine intercepts the string, maps the characters to the correct calendar fields, and instantiates a perfect Date Object ready for advanced downstream calculations.

### When to Use It

- **ETL / Data Integration**: Parsing raw text dates loaded from external ERP systems into valid Java Objects so they can be mathematically analyzed.
- **Smart View Input Validation**: Validating user text inputs on a web form (e.g., ensuring a user correctly typed a date as `DD/MM/YYYY`) and using that date to trigger accrual models.
- **Log Parsing**: Converting text timestamps from external system logs into calculable objects to evaluate SLAs.

---

## Category

**Date & Time / Object Instantiation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetFormattedDate(date_string, format_pattern)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date_string` | String | ✅ Yes | The raw text string containing the date (e.g., `"12-31-2024"`). |
| `format_pattern` | String | ✅ Yes | The exact `java.text.SimpleDateFormat` mask that tells the engine how to read the string (e.g., `"MM-dd-yyyy"`). |

### Common Pattern Symbols

| Symbol | Description | Example Pattern | Parses this String |
|--------|-------------|-----------------|--------------------|
| `yyyy` | 4-digit Year | `"yyyy/MM/dd"` | `"2024/12/31"` |
| `MM` | 2-digit Month | `"MM-dd-yyyy"` | `"12-31-2024"` |
| `dd` | 2-digit Day | `"dd/MM/yyyy"` | `"31/12/2024"` |
| `MMM` | 3-letter Month | `"dd-MMM-yyyy"` | `"31-Dec-2024"` |
| `HH` | 24-hour Time | `"yyyyMMdd HH:mm:ss"` | `"20241231 18:30:00"` |

---

## Return Value

**Return Type**: Object (Java Date / Timestamp)

Returns a highly precise Java Date Object representing the exact time provided in the string.
- **CRITICAL**: Because this returns a Java Object, it **cannot** be saved directly into a standard Essbase numeric account cell. It must either be converted into an integer (e.g., `YYYYMMDD`) or passed directly into a difference calculator like `@CalcMgrDateTimeDiff`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string and the format mask.
2. **Formatter Instantiation**: It creates a new `java.text.SimpleDateFormat` object using the mask you provided.
3. **Execution/Parsing**: It attempts to `.parse()` the text string. 
4. **Validation**: If the text string does not perfectly match the mask (e.g., you told it to expect `"MM-dd"`, but the string contains `"Jan-15"`), the Java engine will throw a `ParseException` and the calculation script will instantly fail.
5. **Return**: If successful, it passes the resulting Java Date Object back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Parsing a European Date Format

```essbase
/* Parses a text string formatted as DD/MM/YYYY into a Date Object */
VAR vDateObj = @CalcMgrGetFormattedDate("31/12/2024", "dd/MM/yyyy");
```

---

## Practical Examples

### Example 1: Calculating Late Fees from Text Invoices

**Scenario**: A company's invoicing system dumps data into Essbase via a flat file. The "Invoice Date" arrives as a pure text string in a Text Account (e.g., `"2024-12-31"`). The script must read this text, convert it into a Date Object, compare it to Today's date, and calculate if it is more than 30 days overdue.

```essbase
FIX("FY25", "Working", @LEVEL0("Invoices"))
    
    /* Ensure the text account is not empty */
    IF(@ISMBR(@LIST("Invoice_Date_Text")))
        
        /* 
           1. Parse the text string into a Java Date Object.
           The format mask strictly matches the hyphenated YYYY-MM-DD layout.
        */
        VAR vInvoiceObj = @CalcMgrGetFormattedDate("Invoice_Date_Text", "yyyy-MM-dd");
        
        /* 
           2. Get Today's Date as a Java Object.
        */
        VAR vTodayObj = @CalcMgrGetCurrentDate();
        
        /* 
           3. Calculate the exact number of days between them.
        */
        "Days_Past_Due" = @CalcMgrDateTimeDiff(vInvoiceObj, vTodayObj, "d");
        
        /* 4. Trigger Late Fee Logic */
        IF("Days_Past_Due" > 30)
            "Late_Fee_Accrual" = 50.00;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mask Mismatch | Parsing `"12/31/2024"` with `"MM-dd-yyyy"` | The format mask must match the text string *exactly*, including the delimiters. If the text string uses slashes (`/`) but your mask uses hyphens (`-`), the Java engine will fail to parse the string and the script will crash. Always validate your source data formats |
| Case Sensitivity | Using `"mm"` for Months | In Java formatting, `MM` (capital) means Months. `mm` (lowercase) means Minutes. If you use `"yyyy-mm-dd"`, the engine will parse the month as minutes, resulting in an entirely corrupted Date Object. Always follow strict Java capitalization rules |
| Saving the Object | `"Target" = @CalcMgrGetFormattedDate(...)` | Essbase standard numeric accounts cannot hold Java Objects. You must use the object in a calculation, or convert it to a standard `YYYYMMDD` integer |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrFormatDate`](@CalcMgrGetFormattedDate.md) | The exact inverse function: Takes a Java Date Object and converts it into a Text String |
| [`@CalcMgrIntegerToDate`](../15_CalcMgr_Utility/@CalcMgrConvertDateToJavaDate.md) | A much faster instantiation function if your source data is already a clean `YYYYMMDD` integer, rather than a text string |
| [`@CalcMgrDateTimeDiff`](@CalcMgrDateDiff.md) | The primary function used to calculate the difference between the object you just created and another date |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getformatteddate.html)
