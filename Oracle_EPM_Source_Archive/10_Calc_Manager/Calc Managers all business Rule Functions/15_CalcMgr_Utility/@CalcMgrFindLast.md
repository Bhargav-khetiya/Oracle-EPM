# @CalcMgrFindLast

## Overview

`@CalcMgrFindLast` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a powerful search tool that scans a source string and returns the **starting index position** of the *very last* occurrence of a specified target substring.

### Why Does This Function Exist?

When parsing external text data loaded into Essbase (like `"USA_NY_NewYorkCity"` or `"/Finance/US/OperatingEx"`), administrators often need to extract the final suffix (like the City name, or the specific account name). 
If the string contains multiple identical delimiters (like multiple underscores or slashes), using `@CalcMgrFindFirst` will only find the first one, breaking the extraction logic. 
`@CalcMgrFindLast` solves this by scanning the string in reverse (right-to-left). It finds the final delimiter, returning its exact integer position in the array. This allows you to dynamically slice the string *after* the final delimiter, ensuring robust data parsing regardless of how many identical delimiters preceded it.

### When to Use It

- **Hierarchical Path Parsing**: Extracting just the final member name from a full hierarchical string path (e.g., getting `"OperatingEx"` from `"/Finance/US/OperatingEx"`).
- **Suffix Extraction**: Pulling the final ID code or version tag from a dynamically named data file string.
- Whenever you need to slice a string based on the final occurrence of a character.

---

## Category

**String / Text Manipulation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrFindLast(text, search_string, ignore_case)
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
- E.g., `@CalcMgrFindLast("Apple_Apple", "A")` returns `6`. (Because Java strings are 0-indexed, and it found the second "A").
- If the target string is NOT found anywhere in the source text, the function returns `-1`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the source string, the target, and the case flag.
2. **Case Normalization**: If `ignore_case` is true, the engine temporarily converts both the source and target strings to `.toLowerCase()` in memory.
3. **Execution**: It executes the native Java `String.lastIndexOf(target)` method, which scans the string array from right to left.
4. **Return**: It instantly passes the resulting integer index (or `-1`) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Last Delimiter

```essbase
/* Searches for the final underscore. Returns 13. (0-indexed). */
"Last_Underscore_Pos" = @CalcMgrFindLast("Vendor_12345_TX", "_", false);
```

### Variant 2: Case-Insensitive Keyword Search

```essbase
/* Looks for the final occurrence of 'error'. Returns 22. */
"Keyword_Pos" = @CalcMgrFindLast("Data Load error line 5 error check", "error", true);
```

---

## Practical Examples

### Example 1: Dynamic Suffix Extraction (Getting the City Name)

**Scenario**: A reporting system loads demographic strings into a Text Account called `"Raw_Location_String"`. The format is `Country_State_City`. The length of the Country and State varies wildly. The administrator only wants to extract the `"City"`. They must find the position of the *last* underscore, and extract everything after it.

```essbase
FIX("FY25", "Working", @LEVEL0("Demographics"))
    
    IF(@ISMBR(@LIST("Raw_Location_String")))
        
        /* 
           1. Find the exact position of the LAST underscore.
           For "USA_NY_NewYorkCity", vIndex = 6.
        */
        VAR vIndex = @CalcMgrFindLast("Raw_Location_String", "_", false);
        
        /* 
           2. Ensure the underscore actually exists before attempting to slice.
        */
        IF(vIndex != -1)
            
            /* 
               3. Extract the text starting from ONE CHARACTER AFTER the underscore, 
               all the way to the absolute end of the string.
               We add +1 so we don't include the underscore itself in the output.
            */
            "Clean_City_Name" = @CalcMgrSubstring("Raw_Location_String", vIndex + 1);
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding 0-Indexing | Forgetting to add `+1` | `FindLast` returns the exact position of the delimiter itself. If you pass that index directly into a `@CalcMgrSubstring` function without modifying it, your extracted suffix will start with the delimiter (e.g., `"_NewYorkCity"`). If you want just the text *after* the delimiter, you must mathematically add `+1` to the index |
| Forgetting to Check for `-1` | Feeding the output directly into `Substring` | If the target string is NOT found, the function returns `-1`. If you immediately pass `-1` (or `(-1) + 1 = 0`) into a `@CalcMgrSubstring` function without checking it first, you will either trigger a Java exception or accidentally extract the entire unbroken string. Always wrap your logic in an `IF(vIndex != -1)` safety block |
| Left-to-Right Expectations | Using it to find prefixes | `FindLast` strictly scans right-to-left. If you need the position of the *first* delimiter to extract a prefix, using `FindLast` will completely break if the string has multiple delimiters. Use `@CalcMgrFindFirst` for prefixes |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrFindFirst`](./@CalcMgrFindFirst.md) | Scans the string left-to-right, returning the position of the *first* occurrence of the target |
| [`@CalcMgrSubstring`](./@CalcMgrSubstring.md) | Extracts text from a string based on the start and end integer positions provided by the Find functions |
| [`@CalcMgrEndsWith`](./@CalcMgrEndsWith.md) | A simpler Boolean function that just checks if the text *ends* with the target string |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_findlast.html)
