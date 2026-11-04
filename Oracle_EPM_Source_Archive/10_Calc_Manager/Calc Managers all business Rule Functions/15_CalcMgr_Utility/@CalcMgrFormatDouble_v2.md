# @CalcMgrFormatDouble

## Overview

`@CalcMgrFormatDouble` is a **custom Calc Manager string manipulation and formatting function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a raw numeric value (a double-precision floating point number) and perfectly formats it into a highly customizable **Text String** based on standard Java/Excel numeric formatting patterns.

### Why Does This Function Exist—

Essbase natively stores and calculates pure numbers (e.g., `1234567.89`). However, when building dynamic alerts, automated commentary narratives, or exporting data to flat files via calc scripts, humans do not want to read pure raw floats. They want to read `$1,234,567.89`. 
Trying to dynamically insert commas and dollar signs into a number using basic Essbase algebra or string concatenation is impossible without thousands of lines of code. 
`@CalcMgrFormatDouble` resolves this instantly. By passing the raw number and a standard format mask (like `"$#,##0.00"`), the Java engine intercepts the number, applies the exact string masking rules, and returns a perfectly formatted human-readable text string.

### When to Use It

- **Automated Commentary**: Dynamically generating text explanations (e.g., `"Revenue exceeded forecast by $45,000.00"`).
- **Data Exports**: Converting raw numbers into strictly formatted string metrics required by rigid downstream ERP integration files.
- **Dynamic Naming Conventions**: Using numeric data (like a year or an index) to dynamically generate cleanly formatted target member names.

---

## Category

**String / Text Manipulation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrFormatDouble(number, pattern)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The raw number to be formatted (e.g., `1234.5`). |
| `pattern` | String | ✅ Yes | The Java DecimalFormat pattern to apply (e.g., `"$#,##0.00"`). |

### Common Pattern Symbols

| Symbol | Description | Example Pattern | Result on `1234.5` |
|--------|-------------|-----------------|--------------------|
| `0` | Digit (Forces a 0 if missing) | `00000.00` | `01234.50` |
| `#` | Digit (Omitted if missing) | `#,###.##` | `1,234.5` |
| `.` | Decimal separator | `0.00` | `1234.50` |
| `,` | Grouping separator | `#,###` | `1,234` |
| `$` | Currency symbol | `"$#,##0.00"` | `$1,234.50` |
| `%` | Multiplies by 100 and adds `%` | `#0.0%` | `123450.0%` |

---

## Return Value

**Return Type**: String

Returns the perfectly formatted number as a Text String.
- Because the output is a string, it **cannot** be saved directly back into a standard Essbase numeric account cell. It must either be saved into a Text Account, used inside a `@RETURN` message, or concatenated with other strings.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the raw double and the pattern string.
2. **Formatting Engine**: It instantiates a `java.text.DecimalFormat` object using the provided pattern.
3. **Execution**: It passes the number through the formatter, generating the masked string. (Note: Java's standard rounding rules apply if the pattern demands fewer decimal places than the raw number has).
4. **Return**: Passes the resulting Text String back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Currency Formatting

```essbase
/* Formats 1234567.8 into a clean currency string. Returns "$1,234,567.80" */
"Formatted_Currency" = @CalcMgrFormatDouble(1234567.8, "$#,##0.00");
```

### Variant 2: Leading Zero Padding

```essbase
/* Forces the number 42 to be exactly 4 digits. Returns "0042" */
"Padded_ID" = @CalcMgrFormatDouble(42, "0000");
```

---

## Practical Examples

### Example 1: Dynamic Validation Error Messages

**Scenario**: An administrator runs a daily balancing script. Total Assets must equal Total Liabilities & Equity. If they do not match, the script must abort and instantly alert the user with the *exact* dollar amount of the imbalance, formatted perfectly so the executive can read it.

```essbase
FIX("FY25", "Working", "No_Entity")
    
    /* Calculate the absolute variance */
    VAR vImbalance = @ABS("Total_Assets" - "Total_Liabilities_Equity");
    
    /* If the variance is greater than $1, trigger the error */
    IF(vImbalance > 1)
        
        /* 
           1. Format the raw number into a human-readable currency string.
           E.g., 450000.12 becomes "$450,000.12"
        */
        VAR vImbalanceString = @CalcMgrFormatDouble(vImbalance, "$#,##0.00");
        
        /* 
           2. Concatenate the string into the final error message.
        */
        VAR vErrorMessage = @CONCATENATE("Validation Failed! Balance Sheet is out of balance by: ", vImbalanceString);
        
        /* 
           3. Abort the script and display the message to the user.
        */
        @RETURN(vErrorMessage, ERROR);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting Numeric Storage | `"Target_Account" = @CalcMgrFormatDouble(10, "$0")` | Standard Essbase accounts strictly hold pure numbers. They cannot hold dollar signs, commas, or strings. If you attempt to save the output of this function into a standard account, the script will fail with a Type Mismatch validation error. You must either save the result to a Smart List/Text Account or use it dynamically in a string/macro |
| Bad Pattern Syntax | `"#,#,#.00"` | The `pattern` must conform perfectly to standard Java `DecimalFormat` rules. If you pass an invalid pattern (like putting commas in weird places), the Java engine will throw a formatting exception and the script will fail |
| Misunderstanding `%` | Passing `.05` with a `#%` pattern | The `%` symbol in Java DecimalFormat *automatically* multiplies the number by 100 before formatting. If your raw data is `.05` (5%), and you use `#%`, it will correctly display `5%`. Do not manually multiply by 100 first, or it will display `500%` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDoubleFromString`](./@CalcMgrDoubleFromString.md) | The exact inverse function: Takes a formatted string (like `"1,234.50"`) and converts it back into a raw Essbase number (`1234.5`) |
| [`@CalcMgrFormatDate`](../11_Date_Time/@CalcMgrGetFormattedDate.md) | Applies similar formatting mask rules, but specifically for converting Java Date objects into readable strings |
| [`@CONCATENATE`](../18_Range_Set_Operations/@CONCATENATE.md) | Standard Essbase string function frequently used to combine the formatted number into a larger narrative sentence |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_formatdouble.html)
