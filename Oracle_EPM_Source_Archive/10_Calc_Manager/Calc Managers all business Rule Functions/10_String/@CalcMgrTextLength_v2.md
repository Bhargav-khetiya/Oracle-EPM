# @CalcMgrTextLength

## Overview

`@CalcMgrTextLength` is a **custom Calc Manager string evaluation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a character counter. It takes a source text string and returns the **exact integer number of characters** contained within that string, including letters, numbers, symbols, and spaces.

### Why Does This Function Exist—

When building dynamic EPM logic based on text variables, administrators must often ensure that a string conforms to specific formatting rules before executing database operations. 
For example, if your Essbase outline requires all Project IDs to be exactly 6 digits long (e.g., `"P10050"`), and a user submits `"P150"`, attempting to push data to `@MEMBER("P150")` will cause a fatal calculation error because the member does not exist. 
`@CalcMgrTextLength` provides critical structural validation. By passing the string into this function, you instantly retrieve its length (e.g., `4`). You can then use standard `IF` logic to dynamically pad the string (converting it to `"P00150"`) or reject the input entirely, ensuring pristine data integrity within your Essbase cubes.

### When to Use It

- **Format Validation**: Checking if a dynamically constructed member name meets the exact character length requirements of the outline before attempting to copy data.
- **Substring Mathematics**: Calculating the total length of a string so you can subtract an index position and extract a variable suffix from the end of the text.
- **Empty String Checks**: Validating if a Smart List text box is actually populated (Length `> 0`) before executing expensive string manipulation macros.

---

## Category

**String / Text Manipulation & Validation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrTextLength(text)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be evaluated (e.g., `"Hello"`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the absolute number of characters in the string.
- E.g., `"Hello"` returns `5`.
- **Space Inclusion**: Spaces count as characters. `"Hello World"` returns `11`.
- **Empty Strings**: `""` returns `0`.
- **Null Safety**: If the variable passed is completely null/missing, it returns `0`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Null Evaluation**: It checks if the string object is null. If so, it returns `0`.
3. **Execution**: It executes the native Java `String.length()` method, counting the absolute size of the character array in memory.
4. **Return**: It returns the integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Validation

```essbase
/* Validates that a user actually entered a 5-digit zip code */
IF(@CalcMgrTextLength(vZipCode) != 5)
    "Error_Flag" = 1;
ENDIF
```

---

## Practical Examples

### Example 1: Dynamic Suffix Extraction (Counting Backwards)

**Scenario**: An administrator needs to extract the very last 4 characters of an imported filename string (e.g., `"January_Actuals_File.csv"`) to check if the user uploaded a `.csv` or a `.txt`. Because EPM does not support negative substring indexes (like Python), the script must calculate the total length of the string, subtract 4, and slice from that position.

```essbase
FIX("FY25", "Working", @LEVEL0("Uploads"))
    
    IF(@ISMBR(@LIST("File_Name")))
        
        /* 
           1. Calculate the total length of the string.
           "January_Actuals_File.csv" has 24 characters.
        */
        VAR vTotalLen = @CalcMgrTextLength("File_Name");
        
        /* 
           2. Calculate the exact starting index for the last 4 characters.
           24 - 4 = Index 20.
        */
        VAR vStartIndex = vTotalLen - 4;
        
        /* 
           3. Extract the substring starting from Index 20 to the end.
           Result: ".csv"
        */
        VAR vExtension = @CalcMgrSubstring("File_Name", vStartIndex);
        
        /* 
           4. Validate the extension and route accordingly.
        */
        IF(vExtension == ".csv")
            "Process_Flag" = 1;
        ELSE
            "Process_Flag" = -99; /* Invalid File */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding 0-Indexing vs Length | `Index = Length` | In Java, arrays are 0-indexed. This means a 5-character string (`"Hello"`) has indexes `0, 1, 2, 3, 4`. If you try to extract the character at Index `5` (using the length), the script will throw an `OutOfBoundsException`. The very last character of ANY string is ALWAYS at `Length - 1` |
| Attempting to Evaluate Numbers | `@CalcMgrTextLength(10050)` | This function strictly evaluates text strings. If you pass a numerical Essbase account value (like Revenue `$100,000`), the engine will crash. If you need to know how many digits are in a number, you must use `@CalcMgrDoubleToString` to convert the number into text first |
| Ignoring Hidden Spaces | Expecting `"Sales"` to return `5`, but it returns `6` | If your source text contains trailing spaces (e.g., `"Sales "`), the length will be larger than you expect. This frequently ruins exact-match validations. If you suspect dirty data, always wrap the variable in `@CalcMgrTrim(text)` first to strip invisible spaces before calculating the length |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrSubstring`](./@CalcMgrSubstring.md) | The primary function that relies on `TextLength` math to dynamically isolate suffixes or prefixes |
| [`@CalcMgrPadText`](../15_CalcMgr_Utility/@CalcMgrPadText.md) | Automatically evaluates the length of a string under the hood to determine if it needs to add padding zeroes |
| [`@CalcMgrTrim`](./@CalcMgrTrim.md) | Removes invisible spaces from the string so `TextLength` provides an accurate count of the actual visible characters |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_textlength.html)
