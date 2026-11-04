# @CalcMgrIntegerToString

## Overview

`@CalcMgrIntegerToString` is a **custom Calc Manager string conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as the exact inverse of `@CalcMgrGetIntegerFromString`. It takes a **pure mathematical integer** (e.g., `2024`) and systematically converts it into a **Text String** (e.g., `"2024"`).

### Why Does This Function Exist—

Essbase natively handles all data as numbers. You can easily calculate that next year is `2024 + 1 = 2025`. 
However, standard numbers cannot be used to dynamically point to a member in the database. You cannot tell Essbase to push data into member `2025`. You must tell it to push data into member `"FY25"` or `"2025"`. 
To dynamically construct cross-dimensional references or custom error messages using string macros (like `@CONCATENATE`), the number *must* be cast into a Text String first. If you try to concatenate the word `"FY"` with the raw number `25`, the Java engine will throw a strict Type Mismatch error and abort the calculation. 
`@CalcMgrIntegerToString` securely converts the integer into a character array (String), allowing it to be safely concatenated with prefixes, suffixes, or embedded inside readable text commentary.

### When to Use It

- **Dynamic Member Referencing**: Converting a mathematically calculated Year or Month index (e.g., `5`) into a string (`"5"`) so it can be concatenated into `"Period_5"`.
- **Custom Error Messages**: Converting a validation imbalance (e.g., `50000`) into a text string so it can be embedded into an `@RETURN` user alert.
- **Dynamic File Generation**: Taking a dynamically calculated `YYYYMMDD` integer and converting it into a string to use in the filename of a flat-file export.

---

## Category

**String / Type Casting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrIntegerToString(integer)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `integer` | Numeric | ✅ Yes | The mathematical integer to be converted (e.g., `2024`). |

---

## Return Value

**Return Type**: String

Returns a text string representation of the integer.
- E.g., `2024` returns `"2024"`.
- **Implicit Truncation**: If you pass a floating-point number (e.g., `14.95`) into this function, it expects an integer. It will aggressively truncate the decimal behind the scenes and return `"14"`. It will NOT return `"14.95"`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the numeric value.
2. **Type Coercion**: It physically casts the number to a strict 32-bit `int`, discarding any fractional payload.
3. **Execution**: It executes the native Java `String.valueOf(int)` method, converting the binary numerical data into a Unicode character array.
4. **Return**: Passes the resulting Text String back to Essbase for immediate use in string macros.

---

## Syntax Variants & Scenarios

### Variant 1: Pure Conversion

```essbase
/* Converts the number 42 into the text string "42" */
VAR vTextVal = @CalcMgrIntegerToString(42);
```

---

## Practical Examples

### Example 1: Dynamic Rolling Year Member Generation

**Scenario**: A dynamic forecast script needs to copy data from the current year to the next year. The current year is passed via a runtime prompt (e.g., `"FY24"`). The script extracts `"24"`, converts it to the number `24`, adds `1` (becoming `25`), and then must convert `25` back into a string so it can be concatenated into `"FY25"`.

```essbase
FIX("Working", @LEVEL0("Accounts"))
    
    /* 1. Extract the number from the user prompt "FY24" */
    VAR vYearString = @CalcMgrSubstring("{Target_Year}", 2);
    VAR vYearInteger = @CalcMgrGetIntegerFromString(vYearString);
    
    /* 2. Mathematically calculate the NEXT year (e.g. 24 + 1 = 25) */
    VAR vNextYearInteger = vYearInteger + 1;
    
    /* 
       3. Convert the integer '25' back into the STRING "25". 
       If you skip this step, the concatenate function will crash. 
    */
    VAR vNextYearString = @CalcMgrIntegerToString(vNextYearInteger);
    
    /* 4. Construct the target member name: "FY25" */
    VAR vTargetMember = @CONCATENATE("FY", vNextYearString);
    
    /* 5. Dynamically write data to the newly constructed member */
    FIX(@MEMBER(vTargetMember))
        "Forecast" = 1000;
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Losing Decimals | Passing `14.95` expecting `"14.95"` | The word "Integer" explicitly dictates the behavior of this function. It will cast the input to an integer (dropping the `.95`) before converting it to a string, returning `"14"`. If you need to preserve the decimals in the string, you MUST use `@CalcMgrDoubleToString` instead |
| Exceeding the Limit | Passing a 13-digit timestamp | Standard 32-bit integers cap out at roughly 2.14 billion. If you try to pass a massive number like `3000000000`, the underlying `int` cast will trigger an Integer Overflow, and you will get a string containing a random massive negative number (e.g., `"-1294967296"`). Use `@CalcMgrDoubleToString` for massive numbers |
| Direct Storage | `"Target" = @CalcMgrIntegerToString(15)` | Standard Essbase numerical accounts cannot hold strings. If you attempt to save the output of this function into a standard account, the script will throw a Type Mismatch validation error. You must save it into a Text Account, or use it dynamically in memory |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDoubleToString`](./@CalcMgrDoubleToString.md) | Performs string conversion but preserves decimals and handles massive numbers beyond the 2.14B limit |
| [`@CalcMgrGetIntegerFromString`](./@CalcMgrGetIntegerFromString.md) | The exact inverse function: Takes a string like `"2024"` and parses it into a mathematical integer |
| [`@CONCATENATE`](./@CONCATENATE.md) | The primary Essbase macro used to combine the resulting string with other text |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_integertostring.html)
