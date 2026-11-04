# @CalcMgrCounterAddText

## Overview

`@CalcMgrCounterAddText` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It appends a specified text string into an invisible, globally tracked memory bucket (a "text counter") running in the background during the execution of a Business Rule.

### Why Does This Function Exist—

While `@CalcMgrCounterAddNumber` keeps a running mathematical tally, sometimes you need to keep a running *list*. 
Standard Essbase calculation scripts evaluate data block by block. If you encounter an anomaly (like a validation error) on Entity A, and another on Entity Z, there is no native way to aggregate those specific member names into a single readable string.
`@CalcMgrCounterAddText` allows you to build a dynamic log of events in the background Java heap memory. You can append the names of members that failed validation, log specific data thresholds that were breached, or assemble an array of strings that can later be extracted and passed into an email alert, a Groovy log, or a centralized string attribute.

### When to Use It

- To build a dynamic list of entities that failed a data validation rule.
- To assemble a custom audit trail showing exactly which products had their prices overridden during a calc run.
- When passing a comma-separated list of affected members from an Essbase block calculation back into a Groovy script interface for further processing.

---

## Category

**State Tracking / Memory / String / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterAddText("CounterName", textString)
```

### Formal Syntax

```
@CalcMgrCounterAddText("counterNameString", stringExpressionToAdd)
```

Where:
- `"counterNameString"` — The unique name you are giving to this specific memory bucket. Must be a string in double quotes.
- `stringExpressionToAdd` — The text string to append to the bucket.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the text counter. If the counter does not exist, the engine initializes it as an empty string before appending the new text. |
| `textString` | String | ✅ Yes | The text to append. Can be a hardcoded string, a dynamically extracted attribute (via `@ATTRIBUTESVAL`), or a member name converted to a string (via `@NAME`). |

---

## Return Value

**Return Type**: String

Returns the *new composite string value* of the counter immediately after the append operation is performed.
*(Note: As with most Calc Manager custom functions, you often have to assign the result of this function to a temporary String variable to force Essbase to execute it).*

---

## How It Works (Behind the Scenes)

1. **Initialization Check**: The Java engine checks if a counter named `"CounterName"` already exists in the active memory heap for this specific script execution. If it doesn't, it creates it.
2. **String Appending**: It takes the existing string inside the counter and appends `textString` to the very end of it. It does NOT automatically add commas or spaces. If you want a comma-separated list, you must manually append the comma.
3. **Persistence**: The string stays alive in memory until the entire Business Rule finishes executing, allowing you to append to it from completely different `FIX` blocks later in the script.
4. **Return**: It returns the newly expanded composite string.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Appending

```essbase
/* Appends "Error_1" to the log */
VAR vDummyStr = @CalcMgrCounterAddText("ErrorLog", "Error_1");
```

### Variant 2: Appending a Member Name with a Comma

```essbase
/* To make it readable, we concatenate the member name with a comma first */
VAR vAppendStr = @CalcMgrConcat(@NAME(@CURRMBR("Entity")), ", ");
VAR vDummyStr = @CalcMgrCounterAddText("FailedEntities", vAppendStr);
```

---

## Practical Examples

### Example 1: Building a Validation Error Log

**Scenario**: You have a massive validation script. If any entity has a negative gross margin, it is an error. You want to compile a comma-separated list of the exact entities that failed, and push that text string into a centralized "Validation_Log" text attribute or pass it to Groovy.

```essbase
/* PASS 1: Iterate through the entities and build the string log */
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Gross_Margin" < 0)
        /* Flag the local entity numerically */
        "Validation_Flag" = 1;
        
        /* Build the string to append: "EntityName, " */
        VAR vEntityStr = @NAME(@CURRMBR("Entity"));
        VAR vAppendStr = @CalcMgrConcat(vEntityStr, ", ");
        
        /* Append it to the global memory bucket */
        VAR vLog = @CalcMgrCounterAddText("Global_Error_Log", vAppendStr);
    ENDIF
    
ENDFIX

/* PASS 2: Retrieve the final string log and stamp it somewhere (if supported) 
   Or simply let Groovy retrieve it from the context memory */
/* ... */

/* Cleanup */
VAR vClear = @CalcMgrCounterClear("Global_Error_Log");
```

---

### Example 2: Capturing Manual Overrides

**Scenario**: You want to track every time a user manually overrides a system-calculated baseline. If an override occurs, you append the Product name to a specific tracking counter.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    IF("Manual_Adjustment" != #MISSING)
        
        /* Create the entry: "Product: AdjustmentValue | " */
        VAR vProdName = @NAME(@CURRMBR("Product"));
        VAR vEntry = @CalcMgrConcat(vProdName, " | ");
        
        /* Add to the tracking log */
        VAR vIgnore = @CalcMgrCounterAddText("Override_Tracker", vEntry);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Delimiters | `AddText("Log", "A")` then `AddText("Log", "B")` yields `"AB"` | The function does not automatically add spaces or commas. You must explicitly build them into the string before appending them if you want a readable list |
| Syntax execution failures | `@CalcMgrCounterAddText("Log", "Value");` | In Essbase, you cannot just drop a function on a line by iteself. It must be assigned to a String variable. Use `VAR vIgnore = @CalcMgrCounterAddText(...)` |
| Hitting string length limits | Appending 50,000 member names into a single string | While the Java heap can handle massive strings, if you try to pull that string back into an Essbase Smart List or Text Attribute, you will hit Essbase's native string length limits (often 255 or 1000 chars depending on the database config). Use with caution on large datasets |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterGetText`](./@CalcMgrCounterGetText.md) | Retrieves the composite string from the counter without adding anything to it |
| [`@CalcMgrCounterAddNumber`](./@CalcMgrCounterAddNumber.md) | The mathematical equivalent for building a running numeric total |
| [`@CalcMgrCounterClear`](./@CalcMgrCounterClear.md) | Deletes the counter from memory, resetting it (critical for avoiding memory leaks) |
| [`@CalcMgrConcat`](./@CalcMgrConcat.md) | Essential for building the string chunk (with commas/spaces) before appending it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counteraddtext.html)
