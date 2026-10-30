# @CalcMgrReplaceAll

## Overview

`@CalcMgrReplaceAll` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a universal search-and-replace engine. It scans a source text string, searches for **ALL occurrences** of a specific target substring, and replaces every single one of them with a new replacement string.

### Why Does This Function Exist?

When formatting strings in EPM—such as generating clean outline member names from messy flat-file imports—data often contains invalid characters. For example, Essbase members cannot contain spaces or hyphens without causing calculation script syntax issues.
If an external HR system loads `"Dept - Sales - West"` into a text field, and you need to convert that into the physical outline member `"Dept_Sales_West"`, you cannot use a simple `@CalcMgrReplaceFirst` function, because that would only fix the first hyphen, leaving `"Dept_Sales - West"`.
`@CalcMgrReplaceAll` solves this by executing a global substitution. You pass the text, tell it to find `" - "`, and replace it with `"_ "`. It scans the entire string from beginning to end and executes the replacement on every single match, generating a perfectly sanitized, outline-ready member string in one pass.

### When to Use It

- **Member Construction**: Replacing all spaces (`" "`) with underscores (`"_"`) so imported text can be converted into valid Essbase cross-dimensional member names.
- **Data Cleansing**: Stripping out all formatting characters (like commas) from imported numeric strings (e.g., converting `"1,000,000"` into `"1000000"`).
- **Text Redaction**: Replacing all occurrences of a sensitive keyword with `"***"` before exporting commentary logs.

---

## Category

**String / Text Manipulation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrReplaceAll(text, search_string, replacement_string, ignore_case)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be modified (e.g., `"1,000,000"`). |
| `search_string` | String | ✅ Yes | The target substring you want to find and remove (e.g., `","`). |
| `replacement_string` | String | ✅ Yes | The text you want to insert in its place (e.g., `""` for deletion). |
| `ignore_case` | Boolean | ❌ No  | Optional flag. <br>`true` = Case-insensitive search (e.g., "A" matches "a"). <br>`false` (Default) = Strictly case-sensitive. |

---

## Return Value

**Return Type**: String

Returns a fully modified string where ALL instances of the search string have been replaced.
- If the `search_string` is NOT found anywhere in the text, the function safely returns the exact original `text` unmodified. No error is thrown.
- **Note**: To completely delete a character rather than replace it, pass an empty string (`""`) as the `replacement_string`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text, search target, replacement, and case flag.
2. **Regex Compilation**: It compiles a global substitution algorithm using `java.lang.String.replaceAll()`.
3. **Execution**: It scans the entire string from left to right. Every time it finds a sequence that matches the search target, it excises those characters and splices in the replacement string.
4. **Return**: It returns the newly constructed string back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Replacing Spaces with Underscores (Case-Sensitive)

```essbase
/* Turns "New York City" into "New_York_City" */
VAR vSafeMember = @CalcMgrReplaceAll("New York City", " ", "_", false);
```

### Variant 2: Complete Deletion

```essbase
/* Turns "1,000,000" into "1000000" by replacing commas with nothing */
VAR vSafeNumberStr = @CalcMgrReplaceAll("1,000,000", ",", "", false);
```

---

## Practical Examples

### Example 1: Generating Valid Essbase Members from Imported Text

**Scenario**: A data integration loads new employee names into a text account called `"Raw_Name"`. The administrator wants to use these names to dynamically build members in the database outline. However, the names contain spaces (e.g., `"John Doe Smith"`). Essbase strongly prefers member names to use underscores. The script must cleanse the text globally before attempting to use it.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    IF(@ISMBR(@LIST("Raw_Name")))
        
        /* 
           1. Replace ALL spaces with underscores.
           "John Doe Smith" becomes "John_Doe_Smith"
        */
        VAR vSafeName = @CalcMgrReplaceAll("Raw_Name", " ", "_", false);
        
        /* 
           2. Validate that the new member actually exists in the outline 
           before we attempt to copy data to it.
        */
        IF(@CalcMgrIsValidMember(vSafeName))
            
            /* Safe to copy data */
            FIX(@MEMBER(vSafeName))
                "Bonus" = 5000;
            ENDFIX
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using ReplaceFirst Accidentally | `"New York City"` becomes `"New_York City"` | A common mistake is using `@CalcMgrReplace` or `@CalcMgrReplaceFirst` when you actually intended to replace all occurrences. If your data contains multiple spaces, commas, or delimiters, you MUST use `ReplaceAll` to ensure global sanitization |
| Replacing with Space vs Deleting | Passing `" "` instead of `""` | If you want to delete a comma from `"1,000"`, you must pass an empty string `""` as the replacement. If you accidentally pass a space `" "`, the result will be `"1 000"`, which will still crash numerical parsers |
| Regex Interpretation | Passing Regex tokens | In older EPM versions, `ReplaceAll` utilized Java's regex engine under the hood. If your `search_string` contains special regex characters (like `.`, `*`, or `?`), it may produce unexpected behavior or replace the entire string. If you are doing advanced character matching, consider using `@CalcMgrReplaceRegex` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrReplace`](./@CalcMgrReplace.md) | Standard alias function that often defaults to `ReplaceAll` behavior, but explicit use of `ReplaceAll` is preferred for code clarity |
| [`@CalcMgrReplaceFirst`](./@CalcMgrReplaceFirst.md) | The narrower alternative. ONLY replaces the very first occurrence of the target string and ignores the rest |
| [`@CalcMgrRemoveAll`](./@CalcMgrRemoveAll.md) | Equivalent to using `ReplaceAll` with an empty replacement string (`""`). Explicitly built just for deleting characters |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_replaceall.html)
