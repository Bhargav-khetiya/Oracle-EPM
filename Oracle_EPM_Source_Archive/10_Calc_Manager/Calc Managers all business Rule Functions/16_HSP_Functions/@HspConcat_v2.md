# @HspConcat

## Overview

`@HspConcat` is a **Hyperion Planning (HSP) custom string function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It concatenates (joins) two text strings together into a single, unified string. 

### Why Does This Function Exist—

In modern Calc Manager, EPM Cloud provides dozens of powerful string-processing functions (like `@CalcMgrStringsToString` and native concatenation operators). However, these did not always exist. In older versions of Hyperion Planning, manipulating text inside a calculation script was nearly impossible because Essbase is fundamentally a numeric database.
`@HspConcat` was introduced as an administrative bridge, allowing developers to dynamically construct strings (like piecing together `"Proj_"` and `"001"` into `"Proj_001"`) so they could dynamically reference members or log detailed error messages to the Job Console.

*Note: While fully supported in modern EPM Cloud, this function is largely considered legacy. It has been entirely superseded by the modern Calc Manager equivalent (`@CalcMgrStringsToString`), which supports unlimited string joins, whereas `@HspConcat` is strictly limited to joining exactly two strings at a time.*

### When to Use It

- **Legacy Scripts**: Maintaining or migrating older On-Premise Hyperion Planning calculation scripts that heavily rely on HSP custom functions.
- **Dynamic Naming**: Constructing member names on the fly (e.g., joining an entity prefix with a product suffix) to pass into `@MEMBER` for dynamic array targeting.
- **Error Formatting**: Prepending a static error message (e.g., `"Validation Failed for: "`) to a dynamically extracted member name for console logging.

---

## Category

**String Processing / Concatenation & Substrings / Custom HSP Functions**

---

## Syntax

```essbase
@HspConcat("String_1", "String_2")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"String_1"` | String | ✅ Yes | The first text string. Must be enclosed in double quotes or be a string variable. |
| `"String_2"` | String | ✅ Yes | The second text string. It will be appended exactly to the end of the first string with no spaces. |

---

## Return Value

**Return Type**: String

Returns the combined text string.
- **No Implicit Formatting**: It does not add spaces, commas, or delimiters. `"Apple"` + `"Tree"` returns `"AppleTree"`. If you want a space, you must include it in the source string (e.g., `"Apple "` + `"Tree"`).
- **Storage**: Essbase data blocks cannot store text. The output MUST be assigned to a `VAR` string variable or passed directly into another function that consumes strings.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine evaluates both inputs to ensure they are valid text strings (if you pass a raw number or member object, it will throw an error).
2. **Buffer Allocation**: It allocates a new memory buffer equal to the combined length of both strings.
3. **Execution**: It writes the characters of String 1 into the buffer, followed immediately by the characters of String 2.
4. **Return**: It passes the new composite string back to the script.

---

## Syntax Variants & Scenarios

### Variant 1: Basic String Joining

```essbase
/* 
   Returns the string: "New_York_Total"
*/
VAR vCombined = @HspConcat("New_York", "_Total");
```

---

## Practical Examples

### Example 1: Dynamic Destination Construction

**Scenario**: A company has a 1-to-1 mapping where every Entity has a corresponding Target Entity prefixed with `"TRG_"`. The script is `FIX`ed on the base entities. It must extract the name of the current entity, prepend `"TRG_"` to it, and use that constructed string to dynamically push data to the target.

```essbase
FIX("FY25", "Working", @RELATIVE("Total_Entity", 0))
    
    IF("Allocation_Pool" > 0)
        
        /* 
           1. Extract the name of the active entity.
           (e.g., "Chicago")
        */
        VAR vEntityStr = @NAME(@CURRMBR("Entity"));
        
        /* 
           2. Construct the Target name using @HspConcat.
           (e.g., "TRG_" + "Chicago" = "TRG_Chicago")
        */
        VAR vTargetStr = @HspConcat("TRG_", vEntityStr);
        
        /* 
           3. Convert the string BACK into a Member Object 
           using @MEMBER so Essbase can write data to it.
        */
        @MEMBER(vTargetStr) = "Allocation_Pool";
        
        /* 4. Clear the source */
        "Allocation_Pool" = 0;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting 3+ Strings | `@HspConcat("A", "B", "C")` | `@HspConcat` is strictly hardcoded to accept exactly TWO parameters. If you pass three strings, the compiler will instantly fail. If you need to join 3 strings using this legacy function, you must nest them: `@HspConcat("A", @HspConcat("B", "C"))`. Alternatively, upgrade to the modern `@CalcMgrStringsToString` which accepts an array |
| Passing Member Objects | `@HspConcat("TRG_", @CURRMBR("Entity"))` | `@CURRMBR` returns a mathematical Member Object, not text. `@HspConcat` only accepts text. You MUST wrap member objects in `@NAME()` to cast them to text before concatenating them |
| Trying to Save the Output | `"String_Account" = @HspConcat(...)` | Standard Essbase accounts only hold numbers. You cannot assign the word `"TRG_Chicago"` to a data intersection. Strings must stay in `VAR` memory or be cast back to members via `@MEMBER` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrStringsToString`](../10_String/@CalcMgrStringsToString.md) | The modern Java equivalent. It accepts an array of unlimited strings, making it vastly superior to `@HspConcat` for complex string building |
| [`@NAME`](../10_String/@NAME.md) | The mandatory native function used to convert Essbase member objects into text strings so they can be concatenated |
| [`@MEMBER`](../04_Member_Navigation/@MEMBER.md) | The inverse of `@NAME`. Used to convert a fully constructed text string back into a structural member so the engine can write data to it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspconcat.html)
