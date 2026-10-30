# @CalcMgrRemoveSQuotes

## Overview

`@CalcMgrRemoveSQuotes` is a **custom Calc Manager string cleansing function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a text string and systematically searches for and **removes all single-quotation marks / apostrophes** (`'`), returning a clean, unquoted text string.

### Why Does This Function Exist?

When exporting data to relational SQL databases, single quotes (`'`) are highly dangerous. In SQL syntax, single quotes are used to define the start and end of a text string (`INSERT INTO table VALUES ('Data')`). 
If a user types an apostrophe into a text field in EPM (e.g., `"O'Connor"` or `"Don't do this"`), and that text is pushed to a SQL database, the apostrophe in `"O'Connor"` will prematurely close the SQL string. The database will attempt to execute the word `Connor"` as a SQL command, instantly crashing the database integration and throwing a massive SQL Syntax Exception. 
`@CalcMgrRemoveSQuotes` acts as a targeted data sanitizer. By wrapping text fields in this function, you strip away the dangerous apostrophes before they can be exported to relational databases, ensuring smooth, error-free integrations.

### When to Use It

- **SQL Integration Protection**: Cleansing employee names or project descriptions before exporting them to a relational database, preventing SQL injection breaks.
- **Smart View File Cleansing**: Stripping apostrophes from text so that Excel doesn't misinterpret the text as a special formula or formatting command.
- **Macro Syntax Safety**: Removing single quotes from dynamically generated strings before using them in older MaxL command-line scripts.

---

## Category

**String / Text Manipulation & Cleansing / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrRemoveSQuotes(text)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string containing the single quotes (e.g., `"O'Connor"`). |

---

## Return Value

**Return Type**: String

Returns a cleansed version of the string with all `'` characters completely deleted.
- **Global Removal**: It aggressively removes EVERY single-quote character found anywhere within the string.
- E.g., `"Don't let 'them' in"` becomes `"Dont let them in"`.
- **Preserves Double Quotes**: It completely ignores `"` characters, leaving them perfectly intact.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Regex Substitution**: It executes the native Java `String.replace("'", "")` method.
3. **Execution**: It scans every character in the array. Every time it encounters ASCII 39 (the single-quote/apostrophe character), it deletes it and collapses the string.
4. **Return**: It returns the cleansed string back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Cleansing an Imported Variable

```essbase
/* Assuming vText = "'Q1_Adjust'" */
VAR vCleanText = @CalcMgrRemoveSQuotes(vText);
/* Result: "Q1_Adjust" */
```

---

## Practical Examples

### Example 1: Cleansing Data for a SQL Export

**Scenario**: A business rule exports new Project Names to a staging table in an Oracle SQL Database. Users frequently use apostrophes in the names (e.g., `"CEO's Initiative"`). The administrator knows that single quotes will break the SQL `INSERT` statement. They use this function to sanitize the name before passing it to the export macro.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    IF(@ISMBR(@LIST("Project_Name")))
        
        /* 
           1. Scrub the text account. 
           If it contains any single quotes, they will be deleted.
           "CEO's Initiative" becomes "CEOs Initiative"
        */
        VAR vSafeProjectName = @CalcMgrRemoveSQuotes("Project_Name");
        
        /* 
           2. Build the safe SQL export string.
           Notice we use single quotes to wrap the data, which is why 
           we couldn't have internal single quotes inside the text.
        */
        VAR vExportString = @CONCATENATE("INSERT INTO projects VALUES ('", @CONCATENATE(vSafeProjectName, "')"));
        
        /* 3. Log the safe string */
        VAR vLog = @CalcMgrLogStrings("SQL Safe String: ", vExportString);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Double Quote Removal | `RemoveSQuotes("\"Status\"")` | The "S" in `RemoveSQuotes` stands for Single. This function ONLY targets `'` characters. If your text contains double quotes (`"`), this function will do absolutely nothing. You must use `@CalcMgrRemoveDQuotes` instead |
| Destroying Grammatical Words | `"He's"` becoming `"Hes"` | Because this function deletes the character without replacing it with a space, words can be mashed together if the user used a quote as a separator. If you want to replace quotes with spaces, use `@CalcMgrReplaceAll(text, "'", " ")` instead of this deletion function |
| Attempting to Cleanse Numbers | `@CalcMgrRemoveSQuotes(12345)` | This function strictly requires a text string. If you pass a numeric Essbase account into it, the Java engine will crash because numbers do not have quotes |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRemoveDQuotes`](./@CalcMgrRemoveDQuotes.md) | The exact counterpart to this function. It removes DOUBLE quotes (`"`) instead of single quotes |
| [`@CalcMgrRemoveQuotes`](./@CalcMgrRemoveQuotes.md) | The "nuclear option." It aggressively removes BOTH single quotes and double quotes in a single pass |
| [`@CalcMgrReplaceAll`](./@CalcMgrReplaceAll.md) | Allows you to replace the single quote with a different character (like an underscore or space) rather than just deleting it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_removesquotes.html)
