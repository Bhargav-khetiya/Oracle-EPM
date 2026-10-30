# @CalcMgrIndexOf

## Overview

`@CalcMgrIndexOf` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a precise search engine, scanning a source text string and returning the **starting index position** of the *very first* occurrence of a specific target substring. 
*(Note: This function is functionally identical to `@CalcMgrFindFirst`. It exists as an alias to directly map to the standard Java/JavaScript `indexOf()` naming convention).*

### Why Does This Function Exist?

When dealing with dynamically loaded text data (like `"DataLoad_Error_Row_5"` or `"Account_10045_Active"`), administrators often need to slice the string apart to extract IDs or statuses using `@CalcMgrSubstring`. 
Because the length of the prefix can change dynamically, you cannot hardcode the slice integer (e.g., "Slice at character 8"). You must first locate the delimiter (e.g., the underscore `_`). 
`@CalcMgrIndexOf` scans the text left-to-right, finds the exact location of that delimiter, and returns its integer position. This allows you to feed that precise integer directly into a substring function, ensuring robust text parsing regardless of string length.

### When to Use It

- **ETL Parsing**: Finding the exact location of a `-` or `_` delimiter so you can cleanly extract prefixes or suffixes from concatenated dimensions.
- **Smart Validation**: Scanning user commentary strings to see if a specific prohibited keyword exists anywhere in the text.
- **Cross-Dimensional Mapping**: Finding the start of a token to dynamically construct Essbase member references.

---

## Category

**String / Text Manipulation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrIndexOf(text, search_string, ignore_case)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be searched (e.g., `"New_York_City"`). |
| `search_string` | String | ✅ Yes | The target substring you are looking for (e.g., `"_"`). |
| `ignore_case` | Boolean | ❌ No  | Optional flag. <br>`true` = Case-insensitive search (e.g., "A" matches "a"). <br>`false` (Default) = Strictly case-sensitive. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the zero-based starting index position of the *first* occurrence of the target string.
- E.g., `@CalcMgrIndexOf("Apple", "p")` returns `1`. (Because Java strings are 0-indexed: `A=0`, `p=1`).
- If the target string is NOT found anywhere in the source text, the function securely returns `-1`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the source string, the target, and the optional case flag.
2. **Execution**: It executes the native Java `String.indexOf(target)` method. It scans the string array from left to right.
3. **Match**: The moment it finds the first character that perfectly matches the sequence, it halts the scan and captures the integer position of that character.
4. **Return**: It instantly passes the resulting integer index (or `-1`) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding a Delimiter (Case-Sensitive)

```essbase
/* Searches for the first underscore. Returns 6. (0-indexed). */
"First_Underscore_Pos" = @CalcMgrIndexOf("Vendor_12345_Final", "_", false);
```

### Variant 2: Keyword Presence Check (Case-Insensitive)

```essbase
/* Looks for 'error'. Returns 10. */
"Keyword_Pos" = @CalcMgrIndexOf("Data Load ErRoR line 5", "error", true);
```

---

## Practical Examples

### Example 1: Keyword Validation on User Commentary

**Scenario**: A web form allows users to enter justification commentary when overriding a budget. The administrator wants to ensure users aren't just typing `"TBD"` or `"test"`. The script uses `IndexOf` to scan the text account. If it finds those prohibited words, it fails the validation.

```essbase
FIX("FY25", "Working", @LEVEL0("Departments"))
    
    IF(@ISMBR(@LIST("Justification_Comment")))
        
        /* 
           1. Search for "TBD" ignoring case.
           If the word exists anywhere, it will return an index >= 0.
           If it does not exist, it returns -1.
        */
        VAR vPosTBD = @CalcMgrIndexOf("Justification_Comment", "tbd", true);
        
        /* 
           2. Search for "TEST" ignoring case.
        */
        VAR vPosTest = @CalcMgrIndexOf("Justification_Comment", "test", true);
        
        /* 
           3. Validate. If either variable is NOT -1, the user violated the rule.
        */
        IF(vPosTBD != -1 OR vPosTest != -1)
            @RETURN("Error: Your justification comment contains prohibited words (TBD or TEST).", ERROR);
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding 0-Indexing | Expecting `"Apple", "p"` to return `2` | `IndexOf` is strictly **zero-indexed**. The very first character in a string is at position `0`. Always account for this 1-character offset when feeding this output into other mathematical functions |
| Forgetting to Check for `-1` | Feeding the output directly into `Substring` | If the target string is NOT found, `IndexOf` returns `-1`. If you immediately pass `-1` into a `@CalcMgrSubstring` function without checking it first, the script will instantly fail with an "Index Out of Bounds" Java exception. Always wrap your downstream logic in an `IF(vIndex != -1)` block |
| Confusing with LastIndexOf | Trying to find the *last* underscore | `IndexOf` strictly scans left-to-right. If your text is `"Vendor_12345_TX"`, it will return the position of the *first* underscore. If you are trying to extract `"TX"` (the suffix after the *final* underscore), you must use `@CalcMgrFindLast` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrFindFirst`](./@CalcMgrFindFirst.md) | The exact same function. It is literally an alias for `IndexOf` |
| [`@CalcMgrFindLast`](./@CalcMgrFindLast.md) | Scans the string right-to-left, returning the position of the *last* occurrence of the target |
| [`@CalcMgrSubstring`](./@CalcMgrSubstring.md) | Extracts text from a string based on the start and end integer positions provided by the `IndexOf` function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_indexof.html)
