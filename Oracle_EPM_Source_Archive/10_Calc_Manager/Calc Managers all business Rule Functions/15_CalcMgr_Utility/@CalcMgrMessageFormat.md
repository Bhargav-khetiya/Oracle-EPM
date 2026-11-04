# @CalcMgrMessageFormat

## Overview

`@CalcMgrMessageFormat` is a **custom Calc Manager advanced string templating function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a dynamic text constructor. You provide it a **Base String Template** containing numbered placeholders (e.g., `"Error on {0} during phase {1}"`), followed by an array of values. The function intelligently injects the array values into their corresponding placeholders, returning a perfectly constructed final text string.

### Why Does This Function Exist—

When building dynamic error messages, audit logs, or email alerts in Essbase, administrators heavily rely on `@CONCATENATE`. However, `CONCATENATE` can only join two strings at a time. If you want to build a complex sentence containing 4 variables, you have to write a deeply nested, unreadable nightmare: 
`@CONCATENATE("Error in ", @CONCATENATE(vDept, @CONCATENATE(" during ", vPhase)))`. This is prone to syntax errors and is almost impossible to maintain.
`@CalcMgrMessageFormat` brings modern programming string interpolation (templating) to Essbase. You write the sentence exactly how you want it to look, using bracketed tokens (`{0}`, `{1}`). The Java engine reads the tokens and swaps them out with your dynamic variables automatically. This makes your scripts infinitely more readable and allows you to generate highly complex user-facing alerts effortlessly.

### When to Use It

- **Dynamic Error Popups**: Generating highly specific `@RETURN` validation messages that tell the user exactly which department, product, and threshold triggered the failure.
- **Custom Logging**: Constructing detailed trace strings to pass into `@CalcMgrLogMessageTrace` during overnight batch processes.
- **Narrative Reporting Generation**: Building dynamic textual commentary (e.g., `"Revenue for Q1 was $5M, representing a 10% variance."`) and saving it into a Text Account for Smart View presentation.

---

## Category

**String / Text Manipulation & Templating / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrMessageFormat(message_template, value_array)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message_template` | String | ✅ Yes | The base string containing `{0}`, `{1}`, etc., placeholders. |
| `value_array` | Array | ✅ Yes | The Essbase list/array containing the values to be injected. The first item in the list maps to `{0}`, the second to `{1}`, etc. |

---

## Return Value

**Return Type**: String

Returns the fully constructed and interpolated final text string.
- E.g., `MessageFormat("Cost is {0}", @LIST("500"))` returns `"Cost is 500"`.
- Because the output is a string, it must be stored in a Text Account, used in a log, or passed to an `@RETURN` command. It cannot be saved into a standard numeric cell.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the string template and the array of values.
2. **Type Coercion**: It forces all items in the value array into Strings.
3. **Execution**: It executes the native `java.text.MessageFormat.format()` method. It scans the template string for `{X}` tokens and replaces them with the corresponding item in the array list.
4. **Return**: Passes the finalized composite string back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Two-Variable Injection

```essbase
/* 
   Injects "Sales" into {0} and "Jan" into {1}.
   Result: "Warning: Missing data for Sales in Jan"
*/
VAR vAlert = @CalcMgrMessageFormat("Warning: Missing data for {0} in {1}", @LIST("Sales", "Jan"));
```

---

## Practical Examples

### Example 1: Creating a Dynamic Executive Error Popup

**Scenario**: A company has a strict capital expenditure limit. If a department manager enters a CapEx request that exceeds their limit, the script must abort the save and throw an `@RETURN` error. The CFO wants the error message to explicitly state the department name, the requested amount, and the maximum allowed limit, so the manager knows exactly why they were rejected.

```essbase
FIX("FY25", "Working", @LEVEL0("Departments"))
    
    /* 1. Calculate the Variance */
    VAR vVariance = "CapEx_Request" - "CapEx_Limit";
    
    /* 2. Check if they exceeded the limit */
    IF(vVariance > 0)
        
        /* 
           3. Build the dynamic error message using MessageFormat.
           {0} = The Target Department String
           {1} = The Requested Amount (converted to string)
           {2} = The Limit (converted to string)
        */
        VAR vErrorMessage = @CalcMgrMessageFormat(
            "REJECTED: Department {0} requested ${1}, but the maximum limit is ${2}.",
            @LIST(
                {Target_Dept_Prompt}, 
                @CalcMgrDoubleToString("CapEx_Request"), 
                @CalcMgrDoubleToString("CapEx_Limit")
            )
        );
        
        /* 
           4. Throw the popup to the user and abort.
        */
        @RETURN(vErrorMessage, ERROR);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Raw Numbers | `@LIST(100)` | The Java `MessageFormat` engine is expecting string objects to inject into the text. If you pass raw numerical accounts or mathematical variables directly into the `@LIST`, Essbase may struggle with the type mapping. Always wrap numeric variables in `@CalcMgrDoubleToString` before passing them into the list array to ensure safe injection |
| Misunderstanding 0-Indexing | Using `{1}` as the first token | The tokens are zero-indexed. The very first item in your `@LIST` array maps to `{0}`. The second item maps to `{1}`. If you use `{1}` and `{2}` in your template, but only provide two items in the array, `{2}` will fail because the array only goes up to index 1 |
| Unbalanced Arrays | Providing 3 tokens but only 2 variables | If your template string has `{0}, {1}, {2}`, but your `@LIST` only contains 2 items, the Java engine will fail to resolve the third token. It will either leave `{2}` explicitly printed in the text as a literal string, or it will throw an array out-of-bounds error. Always ensure your token count perfectly matches your array length |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CONCATENATE`](./@CONCATENATE.md) | The native Essbase string joiner. Extremely fast for combining two simple strings, but horrific for complex sentences |
| [`@CalcMgrDoubleToString`](./@CalcMgrDoubleToString.md) | The mandatory prep function required to convert numeric data into strings before passing them into the `MessageFormat` list array |
| [`@RETURN`](./@RETURN.md) | The native Essbase macro that takes the beautifully formatted string you just built and throws it onto the user's screen |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_messageformat.html)
