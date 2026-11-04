# @CalcMgrLastIndexOf

## Overview

`@CalcMgrLastIndexOf` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a precise search engine, scanning a source text string in reverse (right-to-left) and returning the **starting index position** of the *very last* occurrence of a specific target substring. 
*(Note: This function is functionally identical to `@CalcMgrFindLast`. It exists as an alias to directly map to the standard Java/JavaScript `lastIndexOf()` naming convention).*

### Why Does This Function Exist—

When dealing with dynamically loaded text strings that contain multiple identical delimiters (like `"Account_100_US_Active"` or `"/Finance/US/OperatingEx"`), you cannot use standard left-to-right search tools (like `IndexOf` or `FindFirst`). A left-to-right scan will stop at the *first* underscore or slash, breaking your logic if you are trying to extract the final suffix (e.g., `"Active"` or `"OperatingEx"`).
`@CalcMgrLastIndexOf` solves this by executing a right-to-left scan. It finds the exact integer position of the final delimiter in the array. This allows you to feed that precise integer directly into a `@CalcMgrSubstring` function, cleanly slicing the string *after* the final delimiter, ensuring robust parsing no matter how many identical delimiters preceded it.

### When to Use It

- **Hierarchical Path Parsing**: Extracting just the final member name from a full URL or hierarchical string path.
- **Suffix Extraction**: Pulling the final ID code or version tag from a dynamically named data file string containing multiple underscores.
- **Extension Slicing**: Finding the final `.` in a filename string (e.g., `"Data_Export.v2.csv"`) to isolate and extract the file extension.

---

## Category

**String / Text Manipulation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrLastIndexOf(text, search_string, ignore_case)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be searched (e.g., `"/Finance/US/OperatingEx"`). |
| `search_string` | String | ✅ Yes | The target substring you are looking for (e.g., `"/"`). |
| `ignore_case` | Boolean | ❌ No  | Optional flag. <br>`true` = Case-insensitive search (e.g., "A" matches "a"). <br>`false` (Default) = Strictly case-sensitive. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the zero-based starting index position of the *last* occurrence of the target string.
- E.g., `@CalcMgrLastIndexOf("Apple_Apple", "A")` returns `6`. (Because Java strings are 0-indexed, and it found the second "A").
- If the target string is NOT found anywhere in the source text, the function securely returns `-1`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the source string, the target, and the optional case flag.
2. **Execution**: It executes the native Java `String.lastIndexOf(target)` method. It scans the string array from right to left.
3. **Match**: The moment it finds the first character (from the right) that perfectly matches the sequence, it halts the scan and captures the integer position of that character relative to the start of the string.
4. **Return**: It instantly passes the resulting integer index (or `-1`) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Last Delimiter (Case-Sensitive)

```essbase
/* Searches for the final underscore. Returns 13. (0-indexed). */
"Last_Underscore_Pos" = @CalcMgrLastIndexOf("Vendor_12345_TX", "_", false);
```

---

## Practical Examples

### Example 1: Dynamic File Extension Extraction

**Scenario**: A centralized logging system records flat-file data loads in a Text Account called `"Filename_Log"`. The files have highly variable names with multiple dots (e.g., `"HR_Data.v2.1.final.csv"`). The administrator wants to run a script that scans the log and extracts just the final file extension (e.g., `"csv"`) to verify the correct file types were loaded. They must find the position of the *last* dot, and extract everything after it.

```essbase
FIX("FY25", "Working", "No_Entity")
    
    IF(@ISMBR(@LIST("Filename_Log")))
        
        /* 
           1. Find the exact position of the LAST dot.
           For "HR_Data.v2.1.final.csv", vIndex = 18.
        */
        VAR vIndex = @CalcMgrLastIndexOf("Filename_Log", ".", false);
        
        /* 
           2. Ensure the dot actually exists before attempting to slice.
           If vIndex == -1, the file has no extension.
        */
        IF(vIndex != -1)
            
            /* 
               3. Extract the text starting from ONE CHARACTER AFTER the dot, 
               all the way to the end of the string.
               We add +1 so we don't include the dot itself in the output.
            */
            "File_Extension" = @CalcMgrSubstring("Filename_Log", vIndex + 1);
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding 0-Indexing | Forgetting to add `+1` | `LastIndexOf` returns the exact position of the delimiter itself. If you pass that index directly into a `@CalcMgrSubstring` function without modifying it, your extracted suffix will start with the delimiter (e.g., `".csv"`). If you want just the text *after* the delimiter, you must mathematically add `+1` to the index |
| Forgetting to Check for `-1` | Feeding the output directly into `Substring` | If the target string is NOT found, the function returns `-1`. If you immediately pass `-1` (or `(-1) + 1 = 0`) into a `@CalcMgrSubstring` function without checking it first, you will either trigger a Java exception or accidentally extract the entire unbroken string. Always wrap your logic in an `IF(vIndex != -1)` safety block |
| Left-to-Right Expectations | Using it to find prefixes | `LastIndexOf` strictly scans right-to-left. If you need the position of the *first* delimiter to extract a prefix, using `LastIndexOf` will break if the string has multiple delimiters. Use `@CalcMgrIndexOf` for prefixes |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrFindLast`](./@CalcMgrFindLast.md) | The exact same function. It is literally an alias for `LastIndexOf` |
| [`@CalcMgrIndexOf`](./@CalcMgrIndexOf.md) | Scans the string left-to-right, returning the position of the *first* occurrence of the target |
| [`@CalcMgrSubstring`](./@CalcMgrSubstring.md) | Extracts text from a string based on the start and end integer positions provided by the `LastIndexOf` function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_lastindexof.html)
