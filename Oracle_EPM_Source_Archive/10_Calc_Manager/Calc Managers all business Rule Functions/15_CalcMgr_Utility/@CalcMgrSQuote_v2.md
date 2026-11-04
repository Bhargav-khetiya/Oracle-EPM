# @CalcMgrSQuote

## Overview

`@CalcMgrSQuote` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a plain text string and forcefully **wraps it in single quotation marks (apostrophes)** (`'`). 

### Why Does This Function Exist—

When building dynamic calculation scripts that export data to relational SQL databases, string syntax is incredibly strict. In SQL, if you write `INSERT INTO table VALUES (Approved)`, the database will look for a column or function named `Approved` and crash. You must write `INSERT INTO table VALUES ('Approved')` so the database knows it is a literal text string. 
While you could technically achieve this in Essbase using massive concatenation chains (e.g., `@CONCATENATE("'", @CONCATENATE("Approved", "'"))`), this is messy, hard to read, and highly prone to syntax errors. 
`@CalcMgrSQuote` performs this operation instantly. By passing a text variable into this function, it automatically prepends and appends the single quotes, instantly sanitizing the text for downstream SQL macro injection.

### When to Use It

- **SQL Integration**: Formatting dynamically generated text variables (like `Current_User` or `Project_Name`) so they can be safely injected into a SQL `UPDATE` or `INSERT` statement.
- **Smart View File Formatting**: Forcing text into single quotes so that downstream CSV or Excel parsers treat the data strictly as text, preventing them from automatically converting formats (like turning `"1-2"` into a date).
- **MaxL Variable Formatting**: Wrapping text strings in quotes before passing them as execution parameters to external MaxL scripts.

---

## Category

**String / Text Manipulation & Formatting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrSQuote(text)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be wrapped (e.g., `"New_York"`). |

---

## Return Value

**Return Type**: String

Returns a new text string, perfectly wrapped in single quotation marks.
- E.g., `"New_York"` becomes `"'New_York'"`.
- **Note**: It does NOT cleanse the internal string. If the original string already had single quotes inside it (e.g., `"O'Connor"`), the result will be `"'O'Connor'"`. This will crash SQL databases. You must use `@CalcMgrRemoveSQuotes` *before* using this function if the data is messy.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Concatenation**: It executes a fast string builder function equivalent to `"'" + text + "'"`.
3. **Return**: It returns the newly formatted string back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Preparing a Variable for SQL

```essbase
/* Assuming vDept = "Sales" */
VAR vSQLReadyDept = @CalcMgrSQuote(vDept);
/* Result: "'Sales'" */
```

---

## Practical Examples

### Example 1: Building a Dynamic SQL Update Statement

**Scenario**: A business rule runs inside EPM, calculates a final variance status (e.g., `"Over_Budget"`), and must dynamically construct a SQL string to push that status back to an external Oracle relational staging table. The SQL syntax requires the string to be wrapped in single quotes.

```essbase
FIX("FY25", "Working", @LEVEL0("Departments"))
    
    /* Ensure the department has an active status string */
    IF(@ISMBR(@LIST("Calculated_Status")))
        
        /* 
           1. The account "Calculated_Status" contains raw text like "Over_Budget".
           Wrap the raw text in single quotes so SQL can read it.
           Result: "'Over_Budget'"
        */
        VAR vSafeStatus = @CalcMgrSQuote("Calculated_Status");
        
        /* 
           2. Dynamically build the SQL statement using the protected string.
           (Assumes vDeptID is already populated).
        */
        VAR vSQLString = @CalcMgrMessageFormat(
            "UPDATE budget_status SET status = {0} WHERE dept = {1}",
            @LIST(vSafeStatus, vDeptID)
        );
        
        /* 3. Log the final safe string to prove the SQL syntax is perfect */
        VAR vLog = @CalcMgrLogStrings("Executing SQL: ", vSQLString);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not Cleansing First | Using it on `"O'Connor"` | This function just blindly wraps the text. If your user text already contains single quotes, wrapping it in MORE single quotes (`"'O'Connor'"`) will create a fatal SQL syntax error. You MUST run `@CalcMgrRemoveSQuotes` on the source string to strip internal quotes *before* you wrap the perimeter in quotes using this function |
| Expecting Double Quotes | Using it for CSV generation | The "S" in `SQuote` stands for Single. If you are generating a CSV file, the strict RFC 4180 standard requires text qualifiers to be **Double Quotes** (`"`). If you wrap your CSV text in single quotes, many parser engines will fail to recognize them. You must use the sibling function `@CalcMgrDoubleQuote` for CSV generation |
| Attempting to Wrap Numbers | `@CalcMgrSQuote(12345)` | This function strictly requires a text string. If you pass a numeric Essbase account into it, the Java engine will crash because it cannot perform string concatenation on a raw double. Convert numbers to strings first using `@CalcMgrDoubleToString` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDoubleQuote`](@CalcMgrDQuote.md) | The exact counterpart to this function. It wraps the text in double quotes (`"`) instead of single quotes |
| [`@CalcMgrRemoveSQuotes`](./@CalcMgrRemoveSQuotes.md) | The critical prerequisite function used to strip dangerous internal single quotes from a string before wrapping it |
| [`@CONCATENATE`](../18_Range_Set_Operations/@CONCATENATE.md) | The manual, clunky alternative to using this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_squote.html)
