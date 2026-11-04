# @HspNumToString

## Overview

`@HspNumToString` is a **Hyperion Planning (HSP) custom type-conversion function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It takes a standard numeric value (like an integer or a floating-point decimal) and explicitly casts it into a **Text String**. 

### Why Does This Function Exist—

Essbase calculation engines are natively mathematical. Almost all data blocks hold double-precision numbers. However, when an administrator needs to construct a dynamic member name (e.g., dynamically pointing a calculation to `"Asset_105"`), or when they need to log a specific numeric variance to the Job Console (e.g., `"Warning: Variance is 5000"`), they cannot easily mash a number into a string.
If you try to concatenate the string `"Asset_"` with the integer `105`, the Essbase compiler will throw a severe Type Mismatch error because it does not know how to add text to math.
`@HspNumToString` solves this. By passing the integer `105` into this function, the internal engine converts it into the pure text string `"105"`. This string can then be safely concatenated or logged without violating Essbase data-type rules.

*Note: While fully supported in modern environments, this legacy HSP function has been largely superseded by the Java-based `@CalcMgrIntegerToString` and `@CalcMgrDoubleToString`, which are slightly more robust in handling decimal formatting and edge cases.*

### When to Use It

- **Dynamic Member Generation**: Converting a numeric sequence counter (e.g., `1, 2, 3`) into text so it can be appended to a prefix (e.g., `"CostCenter_1"`).
- **Console Logging**: Converting calculated metrics (like `$1,000,000`) into strings so they can be embedded into readable text messages logged by `@CalcMgrLogText`.
- **Attribute Matching**: Converting a stored data integer into text so it can be used to query an attribute dimension that is defined as a String type.

---

## Category

**Planning Extensions / Data Type Conversion / Custom HSP Functions**

---

## Syntax

```essbase
@HspNumToString(numeric_value)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numeric_value` | Numeric | ✅ Yes | The mathematical number you want to convert. Can be a hardcoded integer (`10`), a decimal (`10.5`), or a reference to an account containing data (`"Variance_Amount"`). |

---

## Return Value

**Return Type**: String

Returns a text string representing the provided number.
- **Decimal Truncation**: Depending on the specific patch environment, this legacy function often truncates or formats trailing zeroes unexpectedly on floating-point numbers. (e.g., passing `10.0` might just return `"10"`).
- **Missing Data**: If you pass an empty block (`#MISSING`), Essbase evaluates it as `0`, and the function typically returns the string `"0"`.
- **Storage**: Because it returns a text string, you CANNOT save the output into a standard Essbase numeric account. It MUST be assigned to a `VAR` string variable.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine evaluates the mathematical input, resolving any block references to their raw double-precision numeric values.
2. **Buffer Allocation**: It allocates a character buffer in memory large enough to hold the characters of the number.
3. **Casting**: It executes a standard C-level `sprintf` (or similar casting algorithm) to convert the math bits into ASCII text characters.
4. **Return**: It passes that text string back to the calculation thread.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Integer Conversion

```essbase
/* 
   Converts the number 15 into the text string "15".
*/
VAR vStringValue = @HspNumToString(15);
```

---

## Practical Examples

### Example 1: Dynamic Destination Construction

**Scenario**: A forecasting model allows users to specify an `"Asset_Number"` as an integer input on a Web Form (e.g., they type `150`). The calculation script needs to take the `$5,000` purchase price and push it specifically to the member `"Asset_150"`. The script uses `@HspNumToString` to cast the user's integer into text, constructs the name, and routes the data.

```essbase
FIX("FY25", "Working", "IT_Hardware")
    
    IF("Asset_Number" > 0 AND "Purchase_Price" > 0)
        
        /* 
           1. Convert the user's integer input into a text string.
           (e.g., 150 becomes "150")
        */
        VAR vAssetString = @HspNumToString("Asset_Number");
        
        /* 
           2. Concatenate the prefix with the new string.
           (e.g., "Asset_" + "150" = "Asset_150")
        */
        VAR vTargetMemberStr = @HspConcat("Asset_", vAssetString);
        
        /* 
           3. Use @MEMBER to convert the final string into a structural 
           block target, and assign the Purchase Price to it.
        */
        @MEMBER(vTargetMemberStr)->"Allocated_Expense" = "Purchase_Price";
        
        /* Clear the holding buckets */
        "Asset_Number" = #MISSING;
        "Purchase_Price" = #MISSING;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Save to an Account | `"Label" = @HspNumToString(50);` | **Essbase Data Cells CANNOT store text strings.** If you try to assign the string `"50"` back to a standard numeric member, the block will reject it, throwing a compilation error or writing `#MISSING`. Strings must be kept in `VAR` memory variables or consumed by string-capable CDFs |
| Precision Loss on Decimals | `@HspNumToString(3.14159)` | Legacy HSP string converters are notoriously finicky with deep floating-point decimals. They may truncate the decimal early, leading to lost precision in your strings. If you need hyper-accurate decimal-to-string conversion, use `@CalcMgrDoubleToString` instead |
| Passing Member Objects | `@HspNumToString(@CURRMBR("Entity"))` | This function expects a number, not a structural Member Object. If you are trying to get the text string name of an Entity, you DO NOT use this function. You must use `@NAME(@CURRMBR("Entity"))` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrIntegerToString`](../15_CalcMgr_Utility/@CalcMgrIntegerToString.md) | The modern Java equivalent, specifically optimized for converting whole integers into strings |
| [`@CalcMgrDoubleToString`](../15_CalcMgr_Utility/@CalcMgrDoubleToString.md) | The modern Java equivalent optimized for safely converting complex floating-point numbers into text without unexpected rounding |
| [`@HspConcat`](./@HspConcat.md) | The primary consumer function. `NumToString` creates the string, and `HspConcat` joins it to another string to form a complete member name or log message |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspnumtostring.html)
