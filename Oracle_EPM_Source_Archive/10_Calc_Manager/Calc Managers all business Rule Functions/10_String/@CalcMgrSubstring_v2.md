# @CalcMgrSubstring

## Overview

`@CalcMgrSubstring` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a precise text extraction tool. It takes a source text string and **slices out a specific section (a substring)** based on numeric starting and ending index positions. 

### Why Does This Function Exist—

When building dynamic logic based on complex, concatenated member names, you often need to extract a specific piece of the string to map data elsewhere. 
For example, if your application generates unique Project IDs formatted as `"P_2024_NY_105"`, and you need to isolate the Year (`"2024"`), you cannot easily do this using replacement or search functions. You need to tell the engine: "Go to character position 2, and cut out the next 4 characters."
`@CalcMgrSubstring` performs this exact surgical extraction. By leveraging Java's 0-indexed string arrays, you pass the text, the start position, and the end position, and it returns just the isolated slice of text. When combined with `@CalcMgrIndexOf`, it allows administrators to dynamically parse completely variable strings (like extracting everything after the first underscore) without hardcoding fixed lengths.

### When to Use It

- **Member Parsing**: Slicing the year prefix off of a Time dimension member (e.g., turning `"FY24_Jan"` into `"Jan"`).
- **Format Validation**: Extracting the last 4 characters of an imported string to check if it has a `.csv` extension.
- **Dynamic Cross-Dimensional Mapping**: Slicing the Account segment out of a concatenated ledger string (e.g., extracting `"Sales"` from `"101-Sales-US"`) to map data to the correct Essbase target block.

---

## Category

**String / Text Manipulation & Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrSubstring(text, start_index, end_index)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be sliced (e.g., `"FY24_Jan"`). |
| `start_index` | Numeric | ✅ Yes | The **0-indexed** position where the slice should BEGIN. (Inclusive). |
| `end_index` | Numeric | ❌ No  | The **0-indexed** position where the slice should END. (Exclusive). <br>*If omitted, the function automatically slices from the `start_index` all the way to the absolute end of the string.* |

---

## Return Value

**Return Type**: String

Returns the extracted text slice.
- **0-Indexing**: In Java, the very first character of a string is at position `0`.
- **Inclusive/Exclusive Rule**: The slice *includes* the character at the `start_index`, but *stops immediately before* the character at the `end_index`.
- E.g., `Substring("Essbase", 0, 3)` returns `"Ess"` (Characters at index 0, 1, 2). It stops before index 3 (`b`).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the string and the index constraints.
2. **Bounds Checking**: It calculates the `@CalcMgrTextLength` of the string. If the requested indexes exceed the length of the string, it safely adjusts the bounds to prevent a fatal OutOfBoundsException.
3. **Execution**: It executes `java.lang.String.substring(start, end)`.
4. **Return**: It returns the newly isolated String slice back to Essbase memory.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting a Fixed Suffix (Omitting End Index)

```essbase
/* 
   "FY24_Jan". We want everything from the underscore onward.
   The underscore is at index 4. The 'J' is at index 5.
   By omitting the end index, it slices to the end of the string.
   Result: "Jan"
*/
VAR vMonth = @CalcMgrSubstring("FY24_Jan", 5);
```

### Variant 2: Extracting a Specific Segment

```essbase
/* 
   "101-Sales-US". We want just "Sales".
   'S' is at index 4. The dash after 's' is at index 9.
   Result: "Sales"
*/
VAR vAccount = @CalcMgrSubstring("101-Sales-US", 4, 9);
```

---

## Practical Examples

### Example 1: Dynamic Parsing of Concatenated Strings

**Scenario**: A staging table loads data using concatenated string identifiers like `"Dept_105_New_York"`. The first segment (`Dept_105`) is highly variable in length; it could be `"Dept_5"`. The administrator needs to extract whatever comes AFTER the second underscore to find the physical Location member (`"New_York"`). The script must dynamically find the index of the underscores and slice the string.

```essbase
FIX("FY25", "Working", @LEVEL0("Staging"))
    
    IF(@ISMBR(@LIST("Raw_Data_String")))
        
        /* 
           1. The account contains "Dept_105_New_York".
           Find the position of the FIRST underscore.
        */
        VAR vFirstDash = @CalcMgrIndexOf("Raw_Data_String", "_");
        
        /* 
           2. Find the position of the SECOND underscore, 
           by starting the search after the first one.
        */
        VAR vSecondDash = @CalcMgrIndexOfEx("Raw_Data_String", "_", vFirstDash + 1);
        
        /* 
           3. Extract the Location.
           We start the slice exactly one character AFTER the second underscore.
           We omit the end_index so it just grabs everything until the end.
           Result: "New_York"
        */
        VAR vLocationStr = @CalcMgrSubstring("Raw_Data_String", vSecondDash + 1);
        
        /* 
           4. Route the data safely.
        */
        IF(@CalcMgrIsValidMember(vLocationStr))
            FIX(@MEMBER(vLocationStr))
                "Actuals" = 1000;
            ENDFIX
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting 0-Indexing | `Substring("Yes", 1)` to get the 'Y' | Java strings are 0-indexed. Position `1` is the SECOND character. If you ask for `Substring("Yes", 1)`, it will return `"es"`. Always start your counts at `0` |
| End-Index Confusion | Expecting `Substring("ABC", 0, 1)` to return `"AB"` | The `end_index` is EXCLUSIVE. It tells the engine where to *stop*, not what to include. If you ask for `0, 1`, it includes position 0 (`A`), and stops at position 1. The result is just `"A"`. If you want `"AB"`, you must use `0, 2` |
| Negative Indexes | Passing `-1` to count from the back | Unlike Python, standard Java substring does not natively support negative indexes to count backwards from the end of the string. You must use `@CalcMgrTextLength(text) - X` to dynamically calculate the correct positive index |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrIndexOf`](./@CalcMgrIndexOf.md) | The mandatory companion function. It finds the exact integer position of a character (like an underscore) so you can pass that integer into `Substring` |
| [`@CalcMgrTextLength`](./@CalcMgrTextLength.md) | Used to dynamically calculate where the end of a string is |
| [`@CalcMgrSplit`](../15_CalcMgr_Utility/@CalcMgrSplit.md) | An alternative approach. If a string has many delimiters (`"A-B-C-D"`), splitting it into an Array is often much easier than executing 4 complex `Substring` calculations |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_substring.html)
