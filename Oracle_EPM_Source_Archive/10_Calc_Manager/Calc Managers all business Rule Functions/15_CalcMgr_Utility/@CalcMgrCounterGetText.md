# @CalcMgrCounterGetText

## Overview

`@CalcMgrCounterGetText` is a **custom Calc Manager memory retrieval function** in Oracle EPM Cloud (PBCS/EPBCS). It retrieves the composite text string currently stored inside a specific global string counter in the background Java heap memory.

### Why Does This Function Exist?

When developers build complex validation or auditing scripts, they often use `@CalcMgrCounterAddText` to append strings (like the names of failing entities) into an invisible Java memory bucket. This creates a running log (e.g., `"New_York, Texas, California, "`).
Eventually, you must take that massive text string *out* of memory so that you can process it. You might want to write it to a centralized Text Attribute, evaluate it in an `IF` statement to see if it contains a specific keyword, or most commonly, pass it back out to a Groovy script that will email the log to an administrator.
`@CalcMgrCounterGetText` is the dedicated "Read" operation. It accesses the memory heap, finds the named string counter, and returns the complete text payload.

### When to Use It

- At the end of a multi-pass calculation script, to retrieve dynamic string logs stored in memory.
- To execute conditional branching logic based on a string status stored in a global counter (e.g., checking if the global log contains the word `"Error"`).
- When passing a comma-separated list of affected members from an Essbase block calculation back into a Groovy script interface for further processing.

---

## Category

**State Tracking / Memory / String / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterGetText("CounterName")
```

### Formal Syntax

```
@CalcMgrCounterGetText("counterNameString")
```

Where:
- `"counterNameString"` — The exact unique name of the memory bucket whose string you wish to retrieve. Must be enclosed in double quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the specific text counter you want to read. |

---

## Return Value

**Return Type**: String

Returns the literal text string currently stored in the specified counter.
- If the counter does not exist (perhaps because no text was ever added to it, or it was misspelled), it safely returns an empty string (`""`).

---

## How It Works (Behind the Scenes)

1. **Lookup**: The Java engine searches the active memory heap for a counter object matching the exact `"CounterName"`.
2. **Data Extraction**: If found, it copies the text string stored at that location.
3. **Return**: It passes the string back to the Essbase calculation engine. *Crucially, this is a read-only, non-destructive operation. The text remains inside the memory bucket; reading the log does not erase it. You must use `@CalcMgrCounterClear` to explicitly destroy the log.*

---

## Syntax Variants & Scenarios

### Variant 1: Storing to a String Variable

```essbase
/* Reaches into memory and pulls the total error log string into a local variable */
VAR vGlobalLog = @CalcMgrCounterGetText("Global_Error_Log");
```

### Variant 2: Conditional Evaluation (Does the log exist?)

```essbase
/* If the log string is not empty, it means errors occurred */
IF(@CalcMgrCounterGetText("Global_Error_Log") != "")
    /* Trigger a massive abort sequence or alert */
    "System_Halt_Flag" = 1;
ENDIF
```

---

## Practical Examples

### Example 1: Building and Reading a Validation Error Log

**Scenario**: You have a validation script. If any entity has a negative gross margin, it is an error. You want to compile a comma-separated list of the exact entities that failed, and push that text string into a centralized "Validation_Log" text attribute.

```essbase
/* PASS 1: Iterate through the entities and build the string log */
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Gross_Margin" < 0)
        
        /* Build the string to append: "EntityName, " */
        VAR vEntityStr = @NAME(@CURRMBR("Entity"));
        VAR vAppendStr = @CalcMgrConcat(vEntityStr, ", ");
        
        /* Append it to the global memory bucket */
        VAR vLog = @CalcMgrCounterAddText("Global_Error_Log", vAppendStr);
    ENDIF
    
ENDFIX

/* PASS 2: Retrieve the final string log and stamp it (if supported) */
FIX("FY25", "Working", "Admin_Entity")
    
    /* READ OPERATION: Pull the final text string from the memory bucket */
    VAR vFinalLog = @CalcMgrCounterGetText("Global_Error_Log");
    
    /* If the log has text in it, we write it to the attribute */
    IF(vFinalLog != "")
        
        /* Note: Writing strings directly to Essbase cells is tricky; 
           this is often handled by a Groovy bridge or Text Attributes, 
           but conceptually, you'd assign it here. */
           
        /* "Exception_Notes_Str" = vFinalLog; */
        
    ENDIF
    
ENDFIX

/* GOOD HOUSEKEEPING: Clear the massive string from Java memory */
VAR vClear = @CalcMgrCounterClear("Global_Error_Log");
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on Numeric Counters | Trying to pull text from a counter that holds a math total | If the counter was populated using `@CalcMgrCounterAddNumber`, trying to extract it as text will likely return an empty string or cause an engine error. Ensure you match your getters and setters (Text goes with Text, Numbers go with Numbers) |
| Expecting it to clear memory | Assuming `GetText` acts like a "Cut" operation | `GetText` is a "Copy" operation. It leaves the string intact in memory. Because strings can grow extremely large (megabytes), it is absolutely critical that you run `@CalcMgrCounterClear` on text counters when you are finished with them to avoid blowing out the Java heap memory |
| Hitting string length limits | Trying to push a massive log back into a standard Essbase Text Attribute | While the Java heap can handle massive strings, if you try to push a string containing 50,000 member names into an Essbase Text Attribute, you will hit Essbase's native string length limit (often 255 chars). Use Groovy for heavy lifting if logs get this large |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterAddText`](./@CalcMgrCounterAddText.md) | The required predecessor function that actually builds the string |
| [`@CalcMgrCounterClear`](./@CalcMgrCounterClear.md) | Must be used after `GetText` if you want to ensure the memory is wiped clean |
| [`@CalcMgrCounterGetNumber`](./@CalcMgrCounterGetNumber.md) | The equivalent function for pulling mathematical totals out of memory |
| [`@CalcMgrCounterGetKeyText`](./@CalcMgrCounterGetKeyText.md) | Used to retrieve strings from specific keys inside complex maps, rather than simple global counters |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_countergettext.html)
