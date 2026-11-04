# @CalcMgrGetIntegerFromString

## Overview

`@CalcMgrGetIntegerFromString` is a **custom Calc Manager string conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a **Text String** that contains numeric digits (e.g., `"2024"`) and forcefully converts it into a pure mathematical **Integer** (e.g., `2024`) that can be used in standard Essbase calculations.

### Why Does This Function Exist—

When parsing external text data loaded into Essbase (like `"VendorID_12345"` or `"FY2024"`), administrators often use substring functions to extract the numeric portion. For example, they might extract `"2024"`. 
However, the result of a substring extraction is still fundamentally a *Text String*. You cannot perform math on a string. You cannot add `+1` to `"2024"` to forecast the next year, because Essbase will either throw a Type Mismatch error or literally concatenate the string into `"20241"`. 
`@CalcMgrGetIntegerFromString` completely resolves this. It acts as a strict Java parsing engine (`Integer.parseInt()`), reading the characters inside the string, validating that they are digits, and converting them into a pure 32-bit integer that can be multiplied, added, or saved directly into a numeric account cell.

### When to Use It

- **Dynamic Member Slicing**: Extracting the year from a member name like `"FY24"` and converting `"24"` into a number so you can mathematically calculate `"FY25"`.
- **Text Account Processing**: Taking numeric input that users typed into a Smart View Text Cell (e.g., `"150"`) and converting it into a number to drive an allocation model.
- **Log Data Cleanup**: Parsing numeric telemetry IDs out of raw system error strings.

---

## Category

**String / Type Casting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetIntegerFromString(string)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `string` | String | ✅ Yes | The text string containing numeric digits (e.g., `"1234"`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns a pure mathematical integer.
- E.g., `"1234"` returns `1234`.
- **Decimal Truncation**: If the string contains a decimal (e.g., `"12.95"`), the function behaves like strict integer casting. It does NOT round. It simply truncates the decimal and returns `12`.
- **Failure**: If the string contains non-numeric characters (e.g., `"1234A"`), the Java parsing engine will throw a `NumberFormatException`, and the calculation script will crash.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Parsing Engine**: It executes the native Java `Integer.parseInt(string)` method (or equivalent `Double.valueOf(string).intValue()` to handle decimals).
3. **Execution**: The engine converts the characters into a binary mathematical value, explicitly discarding any fractional data to ensure it fits in a 32-bit integer space.
4. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Pure String Conversion

```essbase
/* Converts the string text into a number. Returns 2024. */
"Numeric_Year" = @CalcMgrGetIntegerFromString("2024");
```

---

## Practical Examples

### Example 1: Calculating the "Next Year" from a Member Name

**Scenario**: A dynamic rolling forecast script needs to copy data from the current year to the next year. The current year is passed via a runtime prompt (e.g., `"FY24"`). The script must dynamically calculate what the next year is (`"FY25"`). It cannot just add `+1` to `"FY24"`. It must slice off the `"FY"`, convert `"24"` to an integer, add 1, and then reconstruct the string.

```essbase
FIX("Working", @LEVEL0("Accounts"))
    
    /* 
       1. The user passes the prompt "{Target_Year}". (Assume it is "FY24").
       We extract the substring starting at position 2 (skipping 'F' and 'Y').
       Result is the STRING "24".
    */
    VAR vYearString = @CalcMgrSubstring("{Target_Year}", 2);
    
    /* 
       2. Convert the STRING "24" into the NUMBER 24.
    */
    VAR vYearInteger = @CalcMgrGetIntegerFromString(vYearString);
    
    /* 
       3. Mathematically add 1 to find the next year (25).
    */
    VAR vNextYearInteger = vYearInteger + 1;
    
    /* 
       4. Reconstruct the target member name.
       Convert the integer back to a string, and concatenate "FY" onto the front.
    */
    VAR vNextYearString = @CONCATENATE("FY", @CalcMgrDoubleToString(vNextYearInteger));
    
    /* 5. (Conceptual downstream logic) You can now use vNextYearString in cross-dims */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Alphabetical Characters | `GetIntegerFromString("123A")` | This function is strictly a numeric parser. It cannot filter out letters. If you pass a string containing letters, spaces, or currency symbols (like `"$100"`), the Java engine will completely crash. You MUST use string manipulation functions (like `Substring` or `Replace`) to clean the text string *before* passing it into this function |
| Expecting Decimals | `GetIntegerFromString("14.95")` | The word "Integer" explicitly means a whole number. This function will aggressively truncate decimals. If you need to preserve the `.95`, you must use `@CalcMgrDoubleFromString` instead |
| Exceeding the 32-bit Limit | Passing `"3000000000"` | Standard 32-bit integers cap out at roughly 2.14 billion. If you try to parse a massive ID string like `"9999999999"`, it will cause an Integer Overflow error. If you are parsing massive numbers, use `@CalcMgrGetLongFromString` or `@CalcMgrDoubleFromString` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDoubleFromString`](../15_CalcMgr_Utility/@CalcMgrDoubleFromString.md) | Parses a string into a number, but preserves all decimal precision (floating-point) |
| [`@CalcMgrDoubleToString`](../15_CalcMgr_Utility/@CalcMgrDoubleToString.md) | The exact inverse function: Takes a number and converts it back into a Text String |
| [`@CalcMgrGetInteger`](./@CalcMgrGetInteger.md) | Performs the exact same integer truncation, but takes a numeric float as the input instead of a string |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getintegerfromstring.html)
