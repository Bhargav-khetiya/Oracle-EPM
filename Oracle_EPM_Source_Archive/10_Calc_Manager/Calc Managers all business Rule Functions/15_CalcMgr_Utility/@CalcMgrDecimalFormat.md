# @CalcMgrDecimalFormat

## Overview

`@CalcMgrDecimalFormat` is a **custom Calc Manager string conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a raw mathematical number (like `1234.5678`) and converts it into a highly polished, human-readable Text String (like `"1,234.57"`) according to a specific formatting pattern you provide.

### Why Does This Function Exist—

Essbase natively stores all data as double-precision floating-point numbers. If an account holds the value `1000`, the underlying engine just sees `1000.0`. It does not inherently know about currency symbols, commas, or fixed decimal places—that formatting is traditionally handled on the frontend by Smart View or Financial Reporting.
However, sometimes you need to generate polished reports, email alerts, or audit logs *directly* from a Calc Script or Groovy Rule before the data ever reaches a frontend tool. If you pass raw Essbase numbers to an email script, the users will see ugly, unformatted data (e.g., `"Your budget is 1000000.456"`). 
`@CalcMgrDecimalFormat` bridges this gap. It utilizes the underlying Java `DecimalFormat` class to instantly apply commas, currency symbols, padding, and specific decimal rounding, outputting a beautiful literal string ready for text-based reporting.

### When to Use It

- When assembling dynamic audit logs inside a Business Rule (e.g., logging exactly how much a user adjusted an account).
- When passing numeric data from a Calc Script back to a Groovy script to be emailed to a department head.
- When generating string-based metadata descriptions that require embedded numbers (e.g., `"Tier 1: > $50,000"`).

---

## Category

**String / Type Conversion / Formatting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDecimalFormat(value, "formatPattern")
```

### Formal Syntax

```
@CalcMgrDecimalFormat(numericExpression, "javaDecimalFormatString")
```

Where:
- `numericExpression` — The raw number or data account you want to format.
- `"javaDecimalFormatString"` — A string indicating exactly how the number should look. Must be in double quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value`   | Numeric| ✅ Yes | The number to be formatted (e.g., `1234.5`). |
| `"format"`| String | ✅ Yes | A standard Java `DecimalFormat` pattern (e.g., `"#,##0.00"`). |

### Common Format Patterns
- `"0.00"` : Forces exactly 2 decimal places. `12` becomes `"12.00"`.
- `"#,##0"` : Adds comma separators for thousands, with no decimals. `1234` becomes `"1,234"`.
- `"#,##0.00"` : Adds commas and exactly 2 decimal places (Standard Currency format).
- `"$#,##0.00"` : Prefixes the number with a literal dollar sign.
- `"00000"` : Left-pads the number with zeros until it is 5 digits long (e.g., `45` becomes `"00045"`).

---

## Return Value

**Return Type**: String

Returns a literal text string representing the formatted number. 
*(Note: Because this is now a Text String, you can no longer perform math on it in Essbase. You cannot say `vString + 5`. It is strictly for display or logging purposes).*

---

## How It Works (Behind the Scenes)

1. **Extraction**: The function retrieves the raw floating-point number from the Essbase engine.
2. **Java DecimalFormat**: It passes the number and your format pattern into the Java `java.text.DecimalFormat` class.
3. **Rounding & Padding**: Java automatically rounds the number (using Half-Even rounding) to fit your decimal specification, inserts the requested commas, and applies any literal prefixes (like `$`).
4. **Return Generation**: It returns the resulting string to the Essbase calculation engine, typically to be assigned to a `VAR` or pushed into a text counter.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Currency Formatting

```essbase
/* Formats 1234567.891 to "1,234,567.89" */
VAR vFormattedStr = @CalcMgrDecimalFormat("Net_Income", "#,##0.00");
```

### Variant 2: Zero-Padding for ID Generation

```essbase
/* Formats the number 42 to "00042" */
VAR vPaddedID = @CalcMgrDecimalFormat("Sequence_Number", "00000");
```

---

## Practical Examples

### Example 1: Building a Readable Audit Log

**Scenario**: You have a business rule that allows users to override a system-generated forecast. If they do, you want to log exactly what they did into a global string memory bucket so it can be emailed to their manager. Raw numbers look unprofessional, so you format them first.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    IF("Manual_Adjustment" != #MISSING AND "Manual_Adjustment" != 0)
        
        /* 1. Format the adjustment amount as currency (e.g., "$15,000.00") */
        VAR vAdjStr = @CalcMgrDecimalFormat("Manual_Adjustment", "$#,##0.00");
        
        /* 2. Format the new total amount as currency */
        VAR vTotalStr = @CalcMgrDecimalFormat("Total_Forecast", "$#,##0.00");
        
        /* 3. Build the readable log string */
        VAR vProdName = @NAME(@CURRMBR("Product"));
        VAR vPart1 = @CalcMgrConcat(vProdName, " was adjusted by ");
        VAR vPart2 = @CalcMgrConcat(vPart1, vAdjStr);
        VAR vPart3 = @CalcMgrConcat(vPart2, ". New Total: ");
        VAR vFinalLog = @CalcMgrConcat(vPart3, vTotalStr);
        
        /* 4. Append the beautiful string to the global memory tracker */
        VAR vDummy = @CalcMgrCounterAddText("Audit_Trail", @CalcMgrConcat(vFinalLog, " | "));
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Generating a Standardized Employee ID String

**Scenario**: You are generating Employee IDs dynamically in the system. The IDs must be exactly 6 digits long, padded with leading zeros (e.g., `000104`). The system generates the raw integer `104`. You need to pad it before concatenating it with a prefix.

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    IF("Hire_Status" == 1 AND "Employee_ID_Num" != #MISSING)
        
        /* 1. Pad the raw integer 104 into the string "000104" */
        VAR vPaddedStr = @CalcMgrDecimalFormat("Employee_ID_Num", "000000");
        
        /* 2. Add a corporate prefix: "EMP-000104" */
        VAR vFinalID = @CalcMgrConcat("EMP-", vPaddedStr);
        
        /* Log it, or if using a Groovy bridge, save it to a Text attribute */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched `0` vs `#` | Using `"0,000.00"` instead of `"#,##0.00"` | In Java format patterns, `0` forces a digit to appear even if it's a zero (padding). `#` only shows a digit if it exists. If you use `"0,000.00"` on the number `15`, it will output `"0,015.00"`. Use `#` for optional thousands digits |
| Trying to do math with the result | `vString * 1.5` | The output is a String. Essbase cannot multiply a text string. Formatting should be the absolute final step in your logic chain after all math is completed |
| Missing quotes | Passing the pattern without quotes | The pattern must be a string: `#,##0.00` is invalid syntax; it must be `"#,##0.00"` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDoubleToString`](./@CalcMgrDoubleToString.md) | Converts a number to a string, but without the advanced formatting options (just outputs the raw digits) |
| [`@CalcMgrDoubleFromString`](./@CalcMgrDoubleFromString.md) | The exact reverse operation (takes a formatted string like `"1,234.50"` and strips it down to a raw mathematical number) |
| [`@CalcMgrConcat`](./@CalcMgrConcat.md) | Essential for appending your beautifully formatted number onto other text elements to build full sentences |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_decimalformat.html)
