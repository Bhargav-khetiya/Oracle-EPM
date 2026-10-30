# @CalcMgrFindFirst

## Overview

`@CalcMgrFindFirst` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a powerful search tool that scans a source string and returns the **starting index position** of the *very first* occurrence of a specified target substring.

### Why Does This Function Exist?

Standard Essbase calculates numbers perfectly, but it is notoriously terrible at parsing Text/String data. When external systems load unformatted text strings into Essbase (like `"VendorID_12345_TX"`, or `"Jan_Actuals_Final"`), administrators often need to slice that string apart to extract meaningful data.
Before you can slice a string using `@CalcMgrSubstring`, you must know exactly *where* to slice it. If the target substring (like an underscore `_` or a specific word like `"Final"`) moves around dynamically depending on the text length, hardcoding index numbers (like "slice at position 5") will fail. 
`@CalcMgrFindFirst` resolves this by dynamically scanning the text and telling you exactly where the target word begins. This dynamically feeds the exact integer needed into your substring extraction logic, making string parsing completely resilient to varying data lengths.

### When to Use It

- **Text Parsing / ETL Cleanup**: Finding the exact location of a delimiter (like `-` or `_`) so you can cleanly extract the prefix or suffix of a concatenated text string.
- **Smart Validation**: Checking if a specific flag or keyword (like `"ERROR"` or `"REJECTED"`) exists *anywhere* inside a long comment string.
- **Dynamic Member Naming**: Finding the location of a string token to dynamically construct Essbase cross-dimensional references.

---

## Category

**String / Text Manipulation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrFindFirst(text, search_string, ignore_case)
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
- E.g., `@CalcMgrFindFirst("Apple", "p")` returns `1`. (Because Java strings are 0-indexed: `A=0`, `p=1`).
- If the target string is NOT found anywhere in the source text, the function returns `-1`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the source string, the target, and the case flag.
2. **Case Normalization**: If `ignore_case` is true, the engine temporarily converts both the source and target strings to `.toLowerCase()` in memory.
3. **Execution**: It executes the native Java `String.indexOf(target)` method, which scans from left to right.
4. **Return**: It instantly passes the resulting integer index (or `-1`) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding a Delimiter

```essbase
/* Searches for the first underscore. Returns 6. (0-indexed). */
"First_Underscore_Pos" = @CalcMgrFindFirst("Vendor_12345_Final", "_", false);
```

### Variant 2: Case-Insensitive Keyword Search

```essbase
/* Looks for 'error' regardless of capitalization. Returns 10. */
"Keyword_Pos" = @CalcMgrFindFirst("Data Load ErRoR line 5", "error", true);
```

---

## Practical Examples

### Example 1: Dynamic Prefix Extraction

**Scenario**: An HR system loads employee IDs into a Text Account called `"Raw_Emp_String"`. The format is `<RegionCode>_123456`. The Region Code can be 2 letters (`"TX_123"`) or 4 letters (`"APAC_123"`). The administrator needs to dynamically extract just the Region Code. They cannot hardcode a substring of length 2. They must find the `_` delimiter first, and slice dynamically.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    IF(@ISMBR(@LIST("Raw_Emp_String")))
        
        /* 
           1. Find the exact position of the first underscore.
           For "TX_123", vIndex = 2.
           For "APAC_123", vIndex = 4.
        */
        VAR vIndex = @CalcMgrFindFirst("Raw_Emp_String", "_", false);
        
        /* 
           2. Ensure the underscore actually exists before attempting to slice.
        */
        IF(vIndex != -1)
            
            /* 
               3. Extract the text starting from position 0 up to (but not including) the underscore.
            */
            "Region_Code" = @CalcMgrSubstring("Raw_Emp_String", 0, vIndex);
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding 0-Indexing | Expecting `"Apple", "p"` to return `2` | Like all Java-backed Calc Manager string functions, `FindFirst` is strictly **zero-indexed**. The very first character in a string is at position `0`. Always account for this offset when feeding this output into other mathematical functions |
| Forgetting to Check for `-1` | Feeding the output directly into `Substring` | If the target string is NOT found, `FindFirst` returns `-1`. If you immediately pass `-1` into a `@CalcMgrSubstring` function without checking it first, the script will instantly fail with an "Index Out of Bounds" Java exception. Always wrap your downstream logic in an `IF(vIndex != -1)` safety block |
| Confusing with FindLast | Trying to find the *last* underscore | `FindFirst` scans left-to-right. If your text is `"Vendor_12345_TX"`, it will return the position of the *first* underscore. If you are trying to extract `"TX"` (the suffix after the *final* underscore), you must use `@CalcMgrFindLast` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrFindLast`](./@CalcMgrFindLast.md) | Scans the string right-to-left, returning the position of the *last* occurrence of the target |
| [`@CalcMgrSubstring`](./@CalcMgrSubstring.md) | Extracts text from a string based on the start and end integer positions provided by the Find functions |
| [`@CalcMgrStartsWith`](./@CalcMgrStartsWith.md) | A simpler Boolean function that just checks if the text *begins* with the target string |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_findfirst.html)
