# @HspStringCompare

## Overview

`@HspStringCompare` is a **Hyperion Planning (HSP) custom string function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It takes two text strings and compares them character-by-character to determine if they are **exactly identical**. It returns a mathematical integer representing the result of the comparison.

### Why Does This Function Exist—

Essbase calculation engines are built to perform high-speed math (`IF("Revenue" == 100)`). They are historically terrible at handling text. If you try to write `IF("StringA" == "StringB")` natively in Essbase, the compiler will often crash with a Type Mismatch error, because it does not know how to apply numeric equality operators (`==`) to alphabetical characters.
When extracting dynamic member names (e.g., `@NAME(@CURRMBR("Entity"))`) or reading attributes, administrators often need to execute string-based conditional logic. 
`@HspStringCompare` acts as the native string equality engine. It compares the two text payloads in memory and outputs a standard integer (`0` for a perfect match). Because the output is a number, you can safely wrap it inside a standard Essbase `IF` statement (e.g., `IF(@HspStringCompare(A, B) == 0)`), perfectly bridging the gap between text logic and numeric processing.

*Note: In modern EPM Cloud, this function has been almost entirely superseded by the Java-based `@CalcMgrCompare`. `@CalcMgrCompare` is preferred because it explicitly allows you to toggle Case-Sensitivity, whereas legacy HSP functions are often rigidly tied to the casing rules of the underlying OS.*

### When to Use It

- **Dynamic Prefix Routing**: Checking if the current entity name is exactly equal to `"HQ_NewYork"` before applying a specialized overhead logic rule.
- **Validation**: Comparing a dynamically generated string against a hardcoded control string to ensure a loop produced the expected text.
- **Legacy Migrations**: Maintaining older scripts that rely on HSP custom functions instead of the newer Calc Manager CDFs.

---

## Category

**String Processing / Comparisons & Equivalence / Custom HSP Functions**

---

## Syntax

```essbase
@HspStringCompare("String_1", "String_2")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"String_1"` | String | ✅ Yes | The first text string to evaluate. Must be in quotes or a string variable. |
| `"String_2"` | String | ✅ Yes | The second text string to evaluate against. Must be in quotes or a string variable. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer defining the exact relationship between the two strings.
- **`0` (Zero)**: The strings are **Identical** (e.g., `"Apple"`, `"Apple"`).
- **Non-Zero (`1` or `-1`)**: The strings are **Not Identical** (e.g., `"Apple"`, `"Banana"`). 
  - *Technical Note: The exact non-zero number returned is determined by standard C-level lexicographical sorting (ASCII value differences). `1` means String 1 is alphabetically greater than String 2. `-1` means String 1 is less. For EPM purposes, any return other than `0` simply means "Not Equal".*

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine evaluates both inputs, ensuring they are valid text arrays in memory.
2. **Character Scan**: It compares the strings character-by-character from left to right.
3. **Casing & Ascii Check**: It evaluates the strict ASCII values of the characters.
4. **Return**: If it reaches the end of both strings and every character was identical in value and length, it returns `0`. The moment it finds a mismatch, it stops and returns the ASCII delta (`1` or `-1`).

---

## Syntax Variants & Scenarios

### Variant 1: Checking for Equality

```essbase
/* 
   Because they match perfectly, this returns 0.
*/
VAR vIsEqual = @HspStringCompare("Target_HQ", "Target_HQ");
```

---

## Practical Examples

### Example 1: Bypassing Logic for Specific Entities

**Scenario**: A global allocation script runs on every Base Cost Center. However, Cost Center `"Admin_999"` is a specialized corporate holding bucket that should NEVER receive allocations. Instead of creating a complex UDA just for one member, the administrator converts the current member to a string and uses `@HspStringCompare` to explicitly exclude it from the logic.

```essbase
FIX("FY25", "Working", @LEVEL0("Cost_Centers"))
    
    /* 
       1. Extract the name of the current Cost Center.
       (e.g., "Admin_100")
    */
    VAR vCurrentCCStr = @NAME(@CURRMBR("Cost_Centers"));
    
    /* 
       2. Compare the current CC string against the forbidden target.
       If it is EXACTLY "Admin_999", the function returns 0.
    */
    VAR vIsForbidden = @HspStringCompare(vCurrentCCStr, "Admin_999");
    
    /* 
       3. If the result is NOT 0, they are different, so it is safe to proceed.
    */
    IF(vIsForbidden != 0)
        
        /* Apply standard allocation logic */
        "Allocated_Expense" = "Corporate_Pool" * "Headcount_Ratio";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting `1` for True | `IF(Compare == 1)` | In standard boolean logic, `1` means True and `0` means False. **String comparison functions do the exact opposite.** A return of `0` means "Zero Differences" (They Match). A return of `1` means "There is a difference" (They Do Not Match). If you write `IF(Compare == 1)` hoping to catch identical strings, your logic will fire backward |
| Case Sensitivity | `"apple"` vs `"Apple"` | `@HspStringCompare` is inherently tied to the C-engine's exact ASCII comparison, making it **strictly case-sensitive**. `"Apple"` and `"apple"` will NOT return `0`. If you have messy data entry and need to perform Case-Insensitive comparisons, you MUST use the modern `@CalcMgrCompare(A, B, ignoreCase)` function |
| Passing Member Objects | `@HspStringCompare(@CURRMBR("Entity"), "A")` | This function strictly requires text strings. You CANNOT pass a native Essbase Member Object. You must wrap dynamic references in `@NAME` (e.g., `@NAME(@CURRMBR("Entity"))`) to cast them to text before executing the comparison |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCompare`](../15_CalcMgr_Utility/@CalcMgrCompare.md) | The modern Java equivalent. It is vastly superior because it allows you to explicitly ignore case sensitivity by passing a boolean parameter |
| [`@HspStringCompareArray`](./@HspStringCompareArray.md) | The array counterpart. Instead of comparing two isolated strings, it compares a single string against a massive array of strings |
| [`@NAME`](../10_String/@NAME.md) | The mandatory function used to convert Essbase Member Objects into the text strings required for comparison |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspstringcompare.html)
