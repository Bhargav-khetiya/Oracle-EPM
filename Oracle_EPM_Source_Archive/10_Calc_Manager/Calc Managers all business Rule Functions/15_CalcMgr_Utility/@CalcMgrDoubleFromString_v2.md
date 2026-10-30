# @CalcMgrDoubleFromString

## Overview

`@CalcMgrDoubleFromString` is a **custom Calc Manager string conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a text string that contains numeric characters (e.g., `"1234.56"`) and converts it into a true double-precision floating-point number (`1234.56`) that Essbase can use for mathematical operations.

### Why Does This Function Exist?

In EPM Cloud, you often import data from external systems or REST APIs where numbers are provided as literal text strings. Additionally, when extracting data from Essbase Text Attributes or string-based Smart Lists using `@ATTRIBUTESVAL` or similar functions, the engine returns a String object.
Essbase cannot perform math on a String. If you attempt `"100" * 1.5`, the calculation will fail or return zero. 
`@CalcMgrDoubleFromString` acts as a parser. It reads the text string, strips away the quotes, recognizes the digits and decimal points, and casts the result into a pure mathematical object (a "Double") so you can safely use it in multiplication, addition, or standard data storage.

### When to Use It

- When pulling numeric values stored inside Text Attributes (e.g., a "Square_Footage" attribute) to use in a driver-based calculation.
- When parsing strings retrieved from external systems via Groovy bridges.
- When retrieving a number that was temporarily stored inside a String Memory Counter (`@CalcMgrCounterGetText`).
- To convert Runtime Prompts (RTPs) that are passed as text strings back into usable numbers.

---

## Category

**String / Type Conversion / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDoubleFromString(textString)
```

### Formal Syntax

```
@CalcMgrDoubleFromString(stringExpression)
```

Where:
- `stringExpression` — A text string containing numbers. Can be a hardcoded string in quotes, a string variable, or a function that returns a string (like `@ATTRIBUTESVAL`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `textString`| String | ✅ Yes | The string to parse (e.g., `"100.5"`). The string must represent a valid number. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns a pure mathematical number.
- If the string cannot be parsed into a number (e.g., you pass `"Apple"` or `"100 USD"`), the function will typically throw an error or return `#MISSING`/`0` depending on the exact engine patch level. The string must be clean digits (and optionally a decimal point or negative sign).

---

## How It Works (Behind the Scenes)

1. **Extraction**: The function retrieves the text string.
2. **Java Parsing**: It passes the string into the Java `Double.parseDouble()` method.
3. **Casting**: Java strips away the string wrapper, interpreting the characters `-`, `0-9`, and `.` as a continuous mathematical value.
4. **Return Generation**: It returns this new floating-point number to the Essbase calculation engine, ready for immediate math.

---

## Syntax Variants & Scenarios

### Variant 1: Parsing a Hardcoded String

```essbase
/* Takes the string "50.25" and returns the number 50.25 */
"Numeric_Account" = @CalcMgrDoubleFromString("50.25");
```

### Variant 2: Immediate Math on a Parsed String

```essbase
/* Parses the string and immediately multiplies it by 2 */
"Total" = @CalcMgrDoubleFromString("100") * 2;
```

---

## Practical Examples

### Example 1: Using Text Attributes as Calculation Drivers

**Scenario**: A retail model assigns a "Square_Footage" value to every Store. Because the dimension already has a primary alias, the developer chose to store the square footage as a Text Attribute (e.g., `"15000"`) rather than a numeric data cell to save space. You need to calculate the "Rent_Expense" by multiplying the Square Footage by the "Rent_Per_SqFt" rate.

```essbase
FIX("FY25", "Working", @LEVEL0("Store"))
    
    /* 1. Extract the text string from the attribute */
    VAR vSqFtStr = @ATTRIBUTESVAL("Square_Footage");
    
    /* 2. Ensure the string is not blank */
    IF(vSqFtStr != "")
        
        /* 3. Convert the string into a true mathematical number */
        VAR vSqFtNum = @CalcMgrDoubleFromString(vSqFtStr);
        
        /* 4. Perform the math */
        "Rent_Expense" = vSqFtNum * "Rent_Per_SqFt";
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Cleaning Up and Parsing a Formatted String

**Scenario**: You have a string that came from a user input form formatted with commas (e.g., `"1,500.00"`). The standard parser will crash if it hits a comma. You must strip the comma out using a string replacement function, and then convert it to a number.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Assume vInputStr is "1,500.00" */
    
    /* 1. Use string manipulation to remove the comma. 
       (Theoretical syntax; relies on advanced string replacers) */
    VAR vCleanStr = @CalcMgrStringReplace(vInputStr, ",", "");
    
    /* vCleanStr is now "1500.00" */
    
    /* 2. Safely parse it into a number */
    "Numeric_Value" = @CalcMgrDoubleFromString(vCleanStr);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Unclean Strings | Passing `"$1,500.00"` | The parser expects pure numbers. If it encounters a `$` or a `,` or alphabetical characters, it will fail. You must use string manipulation functions to strip all non-numeric characters before passing the string to this function |
| Blank Strings | `@CalcMgrDoubleFromString("")` | Passing an empty string often causes an internal Java `NumberFormatException`. Always wrap this function in an `IF` statement checking that the string `!= ""` before attempting to parse it |
| Using on actual numbers | `@CalcMgrDoubleFromString("Sales")` | If `"Sales"` is a numeric account, Essbase will evaluate the account, see the number `100`, and then fail because this function explicitly requires a String as an input. This function is strictly for converting Text to Math |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDoubleToString`](./@CalcMgrDoubleToString.md) | The exact reverse operation (takes a raw number and converts it into a pure text string) |
| [`@ATTRIBUTESVAL`](../04_Member_Navigation/@ATTRIBUTESVAL.md) | The primary source of strings that usually require conversion into numbers |
| [`@CalcMgrDecimalFormat`](./@CalcMgrDecimalFormat.md) | Converts a number to a string, but applies beautiful formatting (commas, currency symbols) along the way |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_doublefromstring.html)
