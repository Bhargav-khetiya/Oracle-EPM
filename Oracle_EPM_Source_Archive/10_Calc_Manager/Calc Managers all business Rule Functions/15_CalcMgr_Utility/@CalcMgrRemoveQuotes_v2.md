# @CalcMgrRemoveQuotes

## Overview

`@CalcMgrRemoveQuotes` is a **custom Calc Manager string cleansing function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an aggressive, universal quotation sanitizer. It scans a text string and **simultaneously removes ALL double quotes (`"`) AND all single quotes/apostrophes (`'`)** found anywhere within the text, returning a perfectly clean string.

### Why Does This Function Exist—

When dealing with user-generated text inputs (like variance explanations or journal entry descriptions), users are entirely unpredictable. One user might type `"Q1 Adjustments"`, another might type `'Q1 Adjustments'`, and a third might type `"O'Connor's 'Approved' Budget"`. 
If you try to process this text using standard cleansing functions, you have a problem. `@CalcMgrRemoveDQuotes` will miss the single quotes, and `@CalcMgrRemoveSQuotes` will miss the double quotes. If you miss either, and attempt to inject this text into a CSV export or a SQL insert statement, the remaining quotes will destroy the syntax and crash the downstream system.
`@CalcMgrRemoveQuotes` is the "nuclear option" for quote cleansing. It obliterates both single and double quotes in a single pass, guaranteeing that the resulting string is 100% safe to export to strict text-delimited formats or relational databases.

### When to Use It

- **Total String Sanitization**: Cleansing highly volatile user commentary before exporting it to a strict comma-delimited flat file (CSV).
- **SQL Injection Prevention**: Stripping all quotes from text inputs before passing them to a Java relational database macro, preventing accidental SQL syntax breaks.
- **Master Data Cleansing**: Normalizing externally loaded Product Names (e.g., removing quotes from `"Men's 5\" Shorts"`) before loading them into a dimension.

---

## Category

**String / Text Manipulation & Cleansing / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrRemoveQuotes(text)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string containing the mixed quotes (e.g., `"O'Connor's \"Budget\""`). |

---

## Return Value

**Return Type**: String

Returns a fully cleansed string with all `"` and `'` characters completely deleted.
- **Global Removal**: This function searches the entire array. It deletes every instance it finds, regardless of whether they are at the beginning, middle, or end of the string.
- E.g., `"The 'New' 5\" TV"` becomes `"The New 5 TV"`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Regex Compilation**: It compiles a regular expression designed to match both `"` (ASCII 34) and `'` (ASCII 39).
3. **Execution**: It executes `String.replaceAll("[\"']", "")`.
4. **Return**: It returns the cleanly collapsed string back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Cleansing Mixed Quotes

```essbase
/* Assuming vText = "'He said \"Yes\"'" */
VAR vCleanText = @CalcMgrRemoveQuotes(vText);
/* Result: "He said Yes" */
```

---

## Practical Examples

### Example 1: Sanitizing User Explanations for CSV Export

**Scenario**: At month-end, department managers must type a Variance Explanation into a text cell. The corporate finance team runs a script that exports all explanations into a `.csv` file. Because CSV files use commas as column separators and double quotes as text qualifiers, any user who types a quote or apostrophe (e.g., `"We missed Q1 'Targets' due to..."`) will break the file. The script must fully sanitize the text.

```essbase
FIX("Working", @LEVEL0("Departments"))
    
    IF(@ISMBR(@LIST("Variance_Explanation")))
        
        /* 
           1. Apply the nuclear quote remover. 
           This guarantees NO quotes (single or double) survive.
        */
        VAR vSafeComment = @CalcMgrRemoveQuotes("Variance_Explanation");
        
        /* 
           2. (Optional) Because it's a CSV, we must also remove Commas.
           (Assumes a custom regex or replace function is used here).
        */
        VAR vSafeCSVComment = @CalcMgrReplaceAll(vSafeComment, ",", "");
        
        /* 
           3. Build the final export string and log it.
        */
        VAR vExportRow = @CONCATENATE("Dept_101,", vSafeCSVComment);
        VAR vLog = @CalcMgrLogStrings("CSV Row Safe: ", vExportRow);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Destroying Valid Punctuation | Removing apostrophes from `"O'Connor"` | Because this function is the "nuclear option", it removes ALL single quotes, including valid grammatical apostrophes. `"O'Connor"` becomes `"OConnor"`. If you are exporting data to a system that CAN handle single quotes but CANNOT handle double quotes, do NOT use this function. Use `@CalcMgrRemoveDQuotes` instead |
| Using it for Leading Quotes | Expecting `" 'Quote' "` to become `"Quote"` | This function does not trim spaces, and it removes ALL quotes. If you only want to remove quotes from the *ends* of a string, but leave internal grammatical quotes intact, you must use substring extraction instead of this function |
| Attempting to Cleanse Numbers | `@CalcMgrRemoveQuotes(12345)` | This function strictly requires a text string. If you pass a numeric Essbase account, the engine will crash. Ensure you only point this function at Smart Lists or Text Accounts |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRemoveDQuotes`](./@CalcMgrRemoveDQuotes.md) | A safer, narrower alternative that ONLY removes double quotes (`"`), preserving grammatical apostrophes |
| [`@CalcMgrRemoveSQuotes`](./@CalcMgrRemoveSQuotes.md) | A narrower alternative that ONLY removes single quotes/apostrophes (`'`) |
| [`@CalcMgrReplaceAll`](../10_String/@CalcMgrReplaceAll.md) | Can be used to replace quotes with a space (e.g., `" "`) instead of deleting them entirely, which prevents words from mashing together (e.g., `"He's"` becoming `"Hes"`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_removequotes.html)
