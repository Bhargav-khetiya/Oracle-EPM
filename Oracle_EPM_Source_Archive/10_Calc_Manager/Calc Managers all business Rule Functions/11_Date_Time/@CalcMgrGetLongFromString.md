# @CalcMgrGetLongFromString

## Overview

`@CalcMgrGetLongFromString` is a **custom Calc Manager string conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a **Text String** that contains numeric digits (e.g., `"4000000000"`) and forcefully converts it into a pure mathematical **64-bit Long Integer** (e.g., `4000000000`) that can be safely used in massive global aggregations or high-precision timestamp math.

### Why Does This Function Exist—

When parsing external text data loaded into Essbase (like `"TransactionID_89324589234"`), administrators often use substring functions to extract the numeric portion. 
However, standard 32-bit integers in Java (and by extension Calc Manager) crash at roughly `2.14 Billion`. If you use standard `@CalcMgrGetIntegerFromString` to parse the string `"4000000000"`, the Java engine will trigger a catastrophic "Integer Overflow," either throwing a `NumberFormatException` or silently wrapping the number into a massive negative integer, destroying your calculation.
`@CalcMgrGetLongFromString` resolves this by explicitly invoking the 64-bit Java Long parser (`Long.parseLong()`). It reads the text string and maps it into a memory space capable of holding numbers up to `9 Quintillion`. This ensures that parsing massive text-based identifiers, global revenue strings, or 13-digit Unix timestamps will never crash your EPM application.

### When to Use It

- **Massive Identifiers**: Parsing global, enterprise-wide serial numbers or SKU barcodes from a text field into a calculable numeric format.
- **Timestamp Parsing**: Converting raw 13-digit Unix millisecond timestamps (loaded as strings from an external JSON payload) into numbers so they can be mathematically converted into Java Date Objects.
- **Global Consolidations**: Parsing text-based file imports containing multi-billion-dollar corporate revenue figures.

---

## Category

**String / Type Casting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetLongFromString(string)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `string` | String | ✅ Yes | The text string containing massive numeric digits (e.g., `"89324589234"`). |

---

## Return Value

**Return Type**: Numeric (Long Integer)

Returns a pure mathematical 64-bit integer.
- E.g., `"4000000000"` returns `4000000000`.
- **Decimal Truncation**: If the string contains a decimal (e.g., `"4000000000.95"`), the function aggressively truncates the decimal and returns just the whole number. It does NOT round.
- **Failure**: If the string contains non-numeric alphabetical characters (e.g., `"4000A"`), the Java parsing engine throws a `NumberFormatException` and crashes.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Parsing Engine**: It executes the native Java `Long.parseLong(string)` method.
3. **Execution**: The engine converts the characters into a massive 64-bit binary value, safely holding numbers far beyond the 2.14 billion limit.
4. **Return**: Passes the resulting 64-bit integer back to Essbase for use in standard numeric accounts or advanced math.

---

## Syntax Variants & Scenarios

### Variant 1: Parsing a Massive Identifier

```essbase
/* Converts the massive string into a safe number. Returns 9999999999. */
"Transaction_ID" = @CalcMgrGetLongFromString("9999999999");
```

---

## Practical Examples

### Example 1: Parsing Unix Millisecond Timestamps

**Scenario**: An external IoT tracking system pushes data into EPM via an automated flat-file integration. The exact time of the transaction is loaded as a pure text string representing Unix Milliseconds since 1970 (e.g., `"1704067200000"`). A 13-digit number cannot fit in a standard integer. The script must safely parse this text string into a massive 64-bit Long Integer, so it can be passed to a date converter.

```essbase
FIX("FY25", "Working", @LEVEL0("Transactions"))
    
    /* Ensure the text account is populated */
    IF(@ISMBR(@LIST("Unix_Timestamp_Text")))
        
        /* 
           1. Parse the 13-digit text string into a 64-bit Long Integer.
           Standard GetIntegerFromString would crash instantly here.
        */
        VAR vUnixLong = @CalcMgrGetLongFromString("Unix_Timestamp_Text");
        
        /* 
           2. Convert the Long Integer into a human-readable Excel Serial Date.
           (Assumes a custom macro or function is handling the UTC epoch math)
        */
        "Parsed_Excel_Date" = (vUnixLong / 86400000) + 25569;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Alphabetical Characters | `GetLongFromString("4Billion")` | This function is strictly a numeric parser. It cannot filter out letters. If you pass a string containing letters, spaces, or currency symbols, the Java engine will crash. You MUST use string manipulation functions (`Substring`, `Replace`) to clean the text string first |
| Expecting Decimals | `GetLongFromString("4000000000.95")` | The word "Long" explicitly means a whole 64-bit integer. This function will aggressively truncate decimals. If you need to preserve the `.95`, you must use `@CalcMgrDoubleFromString` instead, which preserves floating-point precision |
| Defaulting to GetLong | Using it for `"2024"` | While `GetLongFromString` will perfectly parse `"2024"`, it allocates 64 bits of memory to do so instead of 32 bits. If you are parsing small numbers (like years, month indexes, or array positions), it is faster to use standard `@CalcMgrGetIntegerFromString` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetIntegerFromString`](./@CalcMgrGetIntegerFromString.md) | Parses a string into a standard 32-bit integer (caps at 2.14B) |
| [`@CalcMgrDoubleFromString`](./@CalcMgrDoubleFromString.md) | Parses a string into a number, preserving all decimal precision |
| [`@CalcMgrGetLong`](./@CalcMgrGetLong.md) | Performs the exact same 64-bit integer truncation, but takes a numeric float as the input instead of a text string |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getlongfromstring.html)
