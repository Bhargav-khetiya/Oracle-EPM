# @CalcMgrSplit

## Overview

`@CalcMgrSplit` is a **custom Calc Manager string-to-array conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a powerful data shredder. It takes a single, massive, comma-delimited text string (or any character-delimited string) and forcefully splits it into a **Java String Array**, where each chunk of text becomes an independent, indexed item in a list.

### Why Does This Function Exist—

In modern cloud architectures, external REST API payloads or Smart View runtime prompts often send data to Essbase as a single massive string. For example, a user might select multiple products in a prompt, and EPM passes the string `"Prod1,Prod2,Prod3"` into the calculation script. 
Essbase calculation scripts cannot natively iterate through a comma-delimited string. You cannot loop a `FIX` statement across `"Prod1,Prod2,Prod3"`. 
`@CalcMgrSplit` resolves this by taking that static string and tearing it apart based on the comma delimiter. It converts `"Prod1,Prod2,Prod3"` into a true Java Array: `[Prod1] [Prod2] [Prod3]`. This array can then be passed to specialized string-array macros (like `@CalcMgrStringsToString`) or iterated through using custom Java `FOR` loops, unlocking the ability to process multi-select prompt data dynamically.

### When to Use It

- **Multi-Select User Prompts**: Parsing a single text variable containing multiple comma-separated department IDs into a usable array.
- **Data Integration**: Shredding a pipe-delimited (`|`) data row imported from an external SQL flat file so each column becomes an independent variable.
- **Hierarchical Path Parsing**: Splitting a folder path string (e.g., `"Finance/US/West"`) by the slash (`/`) to extract the exact regional node (e.g., `"West"` at Index 2).

---

## Category

**String / Text Manipulation & Arrays / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrSplit(text, delimiter)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The massive source string you want to shred (e.g., `"Jan,Feb,Mar"`). |
| `delimiter` | String | ✅ Yes | The specific character or sequence of characters that separates the items (e.g., `","` or `"|"`). |

---

## Return Value

**Return Type**: Array (String List)

Returns a newly constructed Java String Array containing all the separated chunks.
- **CRITICAL**: Because this function returns an **Array of Strings**, it CANNOT be saved directly into a standard Essbase numeric account cell, nor can it be saved into a single Text Account (a text account can only hold one string, not an array of strings). The output must be passed directly into other array-processing functions.
- If the delimiter is not found in the string, it returns an array containing exactly 1 item (the original unbroken string).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the source string and the delimiter.
2. **Regex Splitting**: It executes the native Java `String.split(delimiter)` method.
3. **Execution**: It scans the string. Every time it hits the delimiter, it deletes the delimiter and pushes the text preceding it into a new bucket in a Java String Array.
4. **Return**: It returns the fully populated Java String Array back to Essbase memory.

---

## Syntax Variants & Scenarios

### Variant 1: Splitting by Commas

```essbase
/* 
   Splits "Apples,Oranges,Bananas" into an array of 3 items. 
   Index 0 = "Apples". Index 1 = "Oranges". Index 2 = "Bananas".
*/
VAR vFruitArray = @CalcMgrSplit("Apples,Oranges,Bananas", ",");
```

---

## Practical Examples

### Example 1: Parsing and Reformatting a Multi-Select Prompt

**Scenario**: A user selects multiple Target Departments in a runtime prompt. EPM passes them as a comma-separated string (e.g., `"101,102,103"`). However, the database outline requires the prefix `"Dept_"`. The script must shred the string, add the prefix to every item, and stitch it back together into a valid Essbase list string: `"Dept_101","Dept_102","Dept_103"`.

```essbase
FIX("FY25", "Working", "No_Entity")
    
    /* 
       1. The user prompt arrives as "101,102,103".
       Split the single string into a Java String Array using the comma delimiter.
       Array Result: [101] [102] [103]
    */
    VAR vDeptArray = @CalcMgrSplit({Target_Departments}, ",");
    
    /* 
       2. Use the StringsToString array macro to process the entire array.
       We tell the macro to prepend "Dept_" to every item, wrap them in quotes, 
       and stitch them back together with commas.
    */
    VAR vFinalEssbaseList = @CalcMgrStringsToString(vDeptArray, ",", "\"", "Dept_", "");
    
    /* 
       3. Log the final safe string.
       (Result: "Dept_101","Dept_102","Dept_103").
       This string can now be safely pushed into a FIX statement dynamically.
    */
    VAR vLog = @CalcMgrLogStrings("Formatted Department List: ", vFinalEssbaseList);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Save the Array | `"Target" = @CalcMgrSplit(...)` | You cannot assign an array directly to an Essbase database cell. A cell holds a single number or a single string. If you try to save a String Array into a cell, the script will throw a Type Mismatch validation error. You must process the array in memory using other functions |
| Regex Delimiters | Splitting by a literal period `.` | In Java, the `String.split()` method natively expects a Regular Expression as the delimiter. In Regex, a period (`.`) means "split by any character". If you try to split `"File.txt"` by `"."`, it will shred the entire string into nothingness. You must escape special regex characters: `@CalcMgrSplit("File.txt", "\\.")` |
| Space Padding Issues | Splitting `"Jan, Feb, Mar"` | If your comma-delimited string has spaces after the commas, the resulting array will include those spaces (e.g., `[Jan] [ Feb] [ Mar]`). When you try to map `" Feb"` to an outline member, it will fail because of the leading space. Ensure your source string is stripped of spaces first, or split by `", "` (comma + space) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrStringsToString`](./@CalcMgrStringsToString.md) | The exact inverse function. It takes a String Array and stitches it back together into a single, massive concatenated string |
| [`@CalcMgrGetListItem`](./@CalcMgrGetListItem.md) | Can be used to extract a specific item (e.g., Index `0`) from the string array generated by this function |
| [`@CalcMgrReplaceAll`](./@CalcMgrReplaceAll.md) | A safer alternative if you don't actually need an array, but just want to replace all commas with a different character (like an underscore) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_split.html)
