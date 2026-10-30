# @CalcMgrRemoveDQuotes

## Overview

`@CalcMgrRemoveDQuotes` is a **custom Calc Manager string cleansing function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a text string and systematically searches for and **removes all double-quotation marks** (`"`), returning a clean, unquoted text string.

### Why Does This Function Exist?

When EPM applications interface with external systems (like Oracle GL, Workday, or flat-file data loads), text fields such as user comments or descriptions are frequently wrapped in double quotes to protect internal commas (e.g., `"Department of Revenue, North America"`).
If an automated load rule imports that string exactly as it appears into a Text Account, the literal quote marks (`"`) are saved into the database. 
If an administrator later tries to extract that text and use it inside a string macro (like `@CONCATENATE`) or pass it to a custom formatting function, the embedded double-quotes will prematurely close the string in memory, causing catastrophic compilation failures or syntax errors. 
`@CalcMgrRemoveDQuotes` acts as a fast, hardcoded data scrubber. By wrapping imported text fields in this function, you strip away the dangerous quotation marks before they can corrupt your string manipulation logic.

### When to Use It

- **Data Load Cleansing**: Removing quotes from imported employee names (e.g., `"O'Connor"`) so they can be safely processed.
- **Commentary Extraction**: Stripping quotes from user commentary loaded via REST API payloads before saving them to the database.
- **Filename Sanitization**: Cleaning dynamically imported string variables before attempting to use them as MaxL export filenames.

---

## Category

**String / Text Manipulation & Cleansing / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrRemoveDQuotes(text)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string containing the double quotes (e.g., `"\"Approved\""`). |

---

## Return Value

**Return Type**: String

Returns a cleansed version of the string with all `"` characters removed.
- **Global Removal**: It does not just remove leading or trailing quotes. It aggressively removes EVERY double-quote character found anywhere within the string.
- E.g., `"He said \"Hello\" to me"` becomes `"He said Hello to me"`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Regex Substitution**: It executes the native Java `String.replace("\"", "")` method.
3. **Execution**: It scans every character in the array. Every time it encounters ASCII 34 (the double-quote character), it deletes it and collapses the string.
4. **Return**: It returns the cleansed string back to Essbase for safe downstream use.

---

## Syntax Variants & Scenarios

### Variant 1: Cleansing an Imported Variable

```essbase
/* Assuming vImportedText = "\"Final_Version\"" */
VAR vCleanText = @CalcMgrRemoveDQuotes(vImportedText);
/* Result: "Final_Version" */
```

---

## Practical Examples

### Example 1: Cleansing User Commentary for Export

**Scenario**: A business rule exports user commentary to a CSV file. However, if a user accidentally typed a double-quote into their comment (e.g., `The "New" Project`), it will corrupt the CSV structure when exported. The script must cleanse the text account before passing it to the export string.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    IF(@ISMBR(@LIST("User_Commentary")))
        
        /* 
           1. Scrub the text account. 
           If it contains any double quotes, they will be deleted.
        */
        VAR vCleanComment = @CalcMgrRemoveDQuotes("User_Commentary");
        
        /* 
           2. Build the safe export string.
           (Notice we can safely wrap the cleansed comment in our OWN 
           controlled quotes for the CSV file).
        */
        VAR vExportRow = @CONCATENATE("Project_101,", @CONCATENATE("\"", @CONCATENATE(vCleanComment, "\"")));
        
        /* 3. Log the safe string for the audit trail */
        VAR vLog = @CalcMgrLogStrings("Exporting Row: ", vExportRow);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Single Quote Removal | `RemoveDQuotes("'Status'")` | The "D" in `RemoveDQuotes` stands for Double. This function ONLY targets `"` characters. If your text is wrapped in single quotes (apostrophes), this function will do absolutely nothing. You must use `@CalcMgrRemoveQuotes` instead to target single quotes |
| Escaping Quotes in Hardcoded Strings | `@CalcMgrRemoveDQuotes(""Hello"")` | If you are manually passing a string containing quotes into this function for testing, you cannot just type two quotes. Essbase will crash with a syntax error. You must escape internal quotes using backslashes: `@CalcMgrRemoveDQuotes("\"Hello\"")` |
| Attempting to Cleanse Numbers | `@CalcMgrRemoveDQuotes(12345)` | This function strictly requires a text string. If you pass a numeric Essbase account (like `"Sales"`) into it, the Java engine will crash because numbers do not have quotes to remove |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRemoveQuotes`](./@CalcMgrRemoveQuotes.md) | The exact counterpart to this function. It removes SINGLE quotes (`'`) instead of double quotes |
| [`@CalcMgrReplace`](./@CalcMgrReplace.md) | If you only want to remove quotes from the *beginning* of a string, but leave quotes inside the string intact, you must use Regex or Replace logic instead, because this function aggressively removes ALL of them |
| [`@CalcMgrRemoveAll`](./@CalcMgrRemoveAll.md) | A general-purpose removal tool that can remove any arbitrary character (e.g., commas or dashes) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_removedquotes.html)
