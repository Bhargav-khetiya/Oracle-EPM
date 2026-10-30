# @CalcMgrDQuote

## Overview

`@CalcMgrDQuote` is a **custom Calc Manager string formatting function** in Oracle EPM Cloud (PBCS/EPBCS). It takes an existing text string and strictly wraps it in double quotation marks (`""`), returning the newly wrapped string.

### Why Does This Function Exist?

When building complex strings dynamically inside a Calc Script (especially when generating SQL queries, exporting JSON payloads, or passing parameters to Groovy and external APIs), you frequently need to wrap specific values in double quotes. 
However, double quotes are a reserved syntax character in Essbase calc scripts. If you try to concatenate a literal double quote into a string like this: `@CalcMgrConcat(""", "Text")`, the Essbase parser will crash, thinking you prematurely ended the string.
While you can sometimes escape quotes (e.g., using `""""`), this often leads to unreadable, brittle code that breaks during Calc Manager deployment. `@CalcMgrDQuote` provides a clean, programmatic way to force double quotes around a string without confusing the Essbase parser.

### When to Use It

- When dynamically generating `SQL` statements inside Essbase where table names or string values must be explicitly quoted.
- When assembling `JSON` strings to be passed as a payload to a REST API via a Groovy bridge.
- When generating a CSV export file manually, and you need to ensure text fields containing commas are safely wrapped in double quotes.
- When dynamically building a cross-dimensional target pointer that contains spaces, requiring quotes around the member name.

---

## Category

**String / Formatting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDQuote(textString)
```

### Formal Syntax

```
@CalcMgrDQuote(stringExpression)
```

Where:
- `stringExpression` — The text string that needs to be wrapped in double quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `textString`| String | ✅ Yes | The string to wrap. Can be a hardcoded string, a variable, or a dynamically extracted string (e.g., from `@ATTRIBUTESVAL`). |

---

## Return Value

**Return Type**: String

Returns a new literal text string with `"` appended to the beginning and `"` appended to the end.
For example, passing the string `"Texas"` returns `"\"Texas\""`.

---

## How It Works (Behind the Scenes)

1. **Extraction**: The function receives the target text string.
2. **Java String Builder**: It utilizes the internal Java engine to prepend the `"` character and append the `"` character. Because this happens in the Java layer, the Essbase syntax parser is completely bypassed, preventing compilation errors.
3. **Return Generation**: It returns the newly formatted string back to the Essbase calculation engine for further concatenation or storage.

---

## Syntax Variants & Scenarios

### Variant 1: Wrapping a Raw Extracted String

```essbase
/* Assume vState is "New York". This returns '"New York"' */
VAR vQuotedState = @CalcMgrDQuote(vState);
```

### Variant 2: Immediate Concatenation for JSON

```essbase
/* Yields: {"Region": "New York"} */
VAR vJson = @CalcMgrConcat(
    '{"Region": ', 
    @CalcMgrConcat(@CalcMgrDQuote("New York"), "}")
);
```

---

## Practical Examples

### Example 1: Creating Safe CSV Export Strings

**Scenario**: You are using a business rule to dump data into a text log that will be parsed as a CSV. Some entity names have commas in them (e.g., `"Acme, Inc."`). If you just concatenate them with commas, the CSV will break. You must wrap the entity name in double quotes before adding it to the CSV row.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Net_Income" != #MISSING)
        
        /* 1. Extract the entity name */
        VAR vEntityName = @NAME(@CURRMBR("Entity"));
        
        /* 2. Wrap the entity name safely in double quotes: '"Acme, Inc."' */
        VAR vSafeEntity = @CalcMgrDQuote(vEntityName);
        
        /* 3. Convert the numeric data to a string */
        VAR vDataStr = @CalcMgrDoubleToString("Net_Income");
        
        /* 4. Build the CSV row: '"Acme, Inc.", 5000.0' */
        VAR vRowPart1 = @CalcMgrConcat(vSafeEntity, ", ");
        VAR vFinalRow = @CalcMgrConcat(vRowPart1, vDataStr);
        
        /* 5. Append the row to a global memory log for export */
        VAR vLog = @CalcMgrCounterAddText("CSV_Dump", @CalcMgrConcat(vFinalRow, "\n"));
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Generating a Dynamic Cross-Dimensional Pointer with Spaces

**Scenario**: You are dynamically building a target account name based on a text attribute. The text attribute contains spaces (e.g., `"Audit Fees"`). When you use `@MEMBER()` to point to a target, any member with a space *must* be wrapped in quotes.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    /* Extract the category: "Audit Fees" */
    VAR vCategoryStr = @ATTRIBUTESVAL("Project_Category");
    
    IF(vCategoryStr != "")
        
        /* Wrap it in quotes so Essbase doesn't crash on the space: '"Audit Fees"' */
        VAR vSafeTarget = @CalcMgrDQuote(vCategoryStr);
        
        /* Push the data to the target member */
        @MEMBER(vSafeTarget) = "Project_Expense";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Double-Quoting | Passing `"\"Texas\""` into the function | The function is literal. If you pass a string that already has quotes, it will wrap it *again*, yielding `"\"\"Texas\"\""`. Ensure you are passing clean strings into the function |
| Passing Numbers | `@CalcMgrDQuote(500)` | This function strictly expects a String. If you want to put quotes around a number, you must first convert the number to a string using `@CalcMgrDoubleToString`, and then pass it to `DQuote` |
| Syntax execution failures | `@CalcMgrDQuote("Value");` | In Essbase, you cannot call a function in a vacuum. It must be assigned to a variable: `VAR vQuoted = @CalcMgrDQuote("Value");` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrConcat`](./@CalcMgrConcat.md) | Essential for appending your safely quoted string into a larger payload (like a JSON or CSV row) |
| [`@CalcMgrDoubleToString`](./@CalcMgrDoubleToString.md) | The required predecessor function if you need to wrap a number in quotes |
| [`@NAME`](../10_String/@NAME.md) | Used to convert the current Essbase member pointer into a string before quoting it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_dquote.html)
