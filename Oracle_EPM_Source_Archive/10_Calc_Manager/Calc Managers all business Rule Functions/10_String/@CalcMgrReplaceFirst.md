# @CalcMgrReplaceFirst

## Overview

`@CalcMgrReplaceFirst` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a targeted, single-use search-and-replace engine. It scans a source text string from left to right, locates the **very first occurrence** of a specific target substring, replaces it with a new string, and then immediately halts—ignoring any subsequent matches in the text.

### Why Does This Function Exist?

When formatting hierarchical text strings or complex file paths, you often want to modify the prefix while preserving the suffix exactly as it is. 
For example, if you have a string `"Total_Product_Total_Sales"`, and you want to rename the root from `"Total"` to `"All"`, using `@CalcMgrReplaceAll` would brutally change the string to `"All_Product_All_Sales"`. This destroys the suffix hierarchy.
`@CalcMgrReplaceFirst` gives you surgical control. By strictly targeting only the first occurrence, you can safely execute prefix swaps (changing `"Total"` to `"All"`) resulting in `"All_Product_Total_Sales"`. The rest of the string is completely protected from the substitution algorithm.

### When to Use It

- **Prefix Replacement**: Updating the root identifier in a concatenated hierarchy string (e.g., changing the first `"US_"` to `"Global_"`) without corrupting identical substrings deeper in the tree.
- **Initial Cleansing**: Removing just the first comma or first dash in a messy data string to align with specific offset requirements.
- **Path Re-Routing**: Changing the first occurrence of a folder directory in a dynamically generated URL or file path string.

---

## Category

**String / Text Manipulation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrReplaceFirst(text, search_string, replacement_string, ignore_case)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be modified (e.g., `"NA_Sales_NA_Returns"`). |
| `search_string` | String | ✅ Yes | The target substring you want to find and replace (e.g., `"NA"`). |
| `replacement_string` | String | ✅ Yes | The text you want to insert in its place (e.g., `"Global"`). |
| `ignore_case` | Boolean | ❌ No  | Optional flag. <br>`true` = Case-insensitive search. <br>`false` (Default) = Strictly case-sensitive. |

---

## Return Value

**Return Type**: String

Returns a modified string where ONLY the first instance of the search string has been replaced.
- If the `search_string` is NOT found anywhere in the text, the function safely returns the exact original `text` unmodified.
- E.g., `ReplaceFirst("A_A_A", "A", "Z", false)` returns `"Z_A_A"`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text, search target, replacement, and case flag.
2. **Regex Compilation**: It compiles a substitution algorithm using `java.lang.String.replaceFirst()`.
3. **Execution**: It scans the string from left to right. The moment it finds a sequence that matches the search target, it excises those characters and splices in the replacement string.
4. **Halt**: It instantly halts the search algorithm, leaving the rest of the string entirely untouched.
5. **Return**: It returns the newly constructed string back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Targeted Prefix Replacement (Case-Sensitive)

```essbase
/* Turns "Q1_Forecast_Q1" into "Actuals_Forecast_Q1" */
VAR vReplacedStr = @CalcMgrReplaceFirst("Q1_Forecast_Q1", "Q1", "Actuals", false);
```

---

## Practical Examples

### Example 1: Updating Root Member Names

**Scenario**: A script loops through a dynamic list of members. The strings are loaded from a text attribute, such as `"Dept1_Sales_Dept1_Support"`. The administrator needs to dynamically swap out the root `"Dept1"` with `"Corporate"`, but they must ensure they don't accidentally overwrite the `"Dept1"` in the middle of the string, because the destination account strictly requires that suffix.

```essbase
FIX("FY25", "Working", "No_Entity")
    
    IF(@ISMBR(@LIST("Source_String")))
        
        /* 
           1. Replace ONLY the first occurrence of "Dept1".
           "Dept1_Sales_Dept1_Support" becomes "Corporate_Sales_Dept1_Support"
           If we used ReplaceAll, it would ruin the string.
        */
        VAR vTargetMember = @CalcMgrReplaceFirst("Source_String", "Dept1", "Corporate", false);
        
        /* 
           2. Validate and Copy.
        */
        IF(@CalcMgrIsValidMember(vTargetMember))
            
            FIX(@MEMBER(vTargetMember))
                "Data" = 1000;
            ENDFIX
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it for Global Cleansing | `ReplaceFirst("1,000,000", ",", "")` | If you use this function to cleanse numbers by removing commas, it will only remove the FIRST comma. `"1,000,000"` will become `"1000,000"`, which will still crash any numerical parser. Always use `@CalcMgrReplaceAll` for global data cleansing |
| Right-to-Left Expectations | Replacing the *last* occurrence | This function strictly scans from left to right. There is no `ReplaceLast` function in standard Calc Manager. If you need to replace only the suffix (the final occurrence), you must use `@CalcMgrLastIndexOf` to find its position, slice the string using `@CalcMgrSubstring`, and manually concatenate the new suffix |
| Regex Interpretation | Passing Regex tokens | In Java, `replaceFirst` uses regex evaluation under the hood. If your `search_string` contains regex meta-characters (like `.` or `*`), it may produce unexpected behavior (e.g., replacing a random character instead of a literal dot). If you need to replace a literal period, ensure you escape it appropriately based on your exact EPM version |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrReplaceAll`](./@CalcMgrReplaceAll.md) | The global alternative. Replaces EVERY occurrence of the target string, rather than just stopping after the first match |
| [`@CalcMgrReplaceRegex`](./@CalcMgrReplaceRegex.md) | A powerful alternative that uses full Regular Expressions to execute highly complex conditional replacements |
| [`@CalcMgrStartsWith`](./@CalcMgrStartsWith.md) | If you only want to replace a string IF it happens to be at the very beginning of the text, you can use `StartsWith` as a boolean check before running `ReplaceFirst` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_replacefirst.html)
