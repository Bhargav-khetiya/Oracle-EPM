# @CalcMgrCounterUpdateText

## Overview

`@CalcMgrCounterUpdateText` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It directly forces a new text string into a specific memory counter stored in the background Java heap, completely overwriting whatever string was previously stored there.

### Why Does This Function Exist?

Standard text counters (`@CalcMgrCounterAddText`) are designed for appending. If the memory bucket contains `"Error_1, "`, and you add `"Error_2"`, the bucket grows to `"Error_1, Error_2"`.
However, sometimes you need a global variable to hold a single, definitive status string rather than a growing log. For instance, you might want a global string variable called `"System_Status"` that starts as `"Running"`, and if a critical error is encountered, you want to completely overwrite it to say `"Failed"`.
`@CalcMgrCounterUpdateText` is a pure String Setter. It wipes out the existing contents of the memory bucket and replaces it with the exact string you provide.

### When to Use It

- To manage a global state machine flag during a complex calculation (e.g., tracking the current phase of the calculation: `"Allocations_Phase"`, `"Consolidation_Phase"`).
- To overwrite a default audit status from `"Pending"` to `"Completed"` upon successful execution of a block of code.
- As a bridge to pass a definitive, single-value string (like a dynamically constructed target member name) out of an Essbase loop and into a Groovy script.

---

## Category

**State Tracking / Memory / String / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterUpdateText("CounterName", "newString")
```

### Formal Syntax

```
@CalcMgrCounterUpdateText("counterNameString", "stringValue")
```

Where:
- `"counterNameString"` — The exact name of the memory bucket you wish to update. Must be enclosed in double quotes.
- `"stringValue"` — The exact new text string to force into the bucket, overwriting what was there.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the specific text counter you want to overwrite. If it does not exist, it will be instantly created. |
| `"newString"` | String | ✅ Yes | The text to place into the memory bucket. Can be a hardcoded string in quotes, a dynamically extracted attribute (`@ATTRIBUTESVAL`), or a member converted to string (`@NAME`). |

---

## Return Value

**Return Type**: String

Returns the *new string value* of the counter (which is simply the `"stringValue"` you just passed to it). 
*(Note: As with most Calc Manager custom functions, you must assign the result of this function to a temporary String variable to force Essbase to evaluate and execute it).*

---

## How It Works (Behind the Scenes)

1. **Lookup/Initialization**: The Java engine checks the active memory heap for a string counter named `"CounterName"`. If it does not exist, it initializes it.
2. **Replacement**: It completely flushes whatever text was previously stored in that bucket (performing automatic garbage collection on the old string).
3. **Assignment**: It inserts the `"newString"` directly into the bucket.
4. **Return**: It returns the string back to the Essbase engine to confirm success.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Status Overwrite

```essbase
/* Forces the global status bucket to read "Failed", destroying any previous log */
VAR vIgnoreStr = @CalcMgrCounterUpdateText("Global_Status", "Failed");
```

### Variant 2: Storing a Dynamic Target Name

```essbase
/* Overwrites the bucket with the dynamically constructed name of a target account */
VAR vTargetStr = @CalcMgrConcat("Exp_", @NAME(@CURRMBR("Department")));
VAR vIgnoreStr = @CalcMgrCounterUpdateText("Target_Account_Name", vTargetStr);
```

---

## Practical Examples

### Example 1: Global State Machine (Halt on Error)

**Scenario**: You have a 3-part script: Initialization, Calculation, and Export. If any step fails, a global string flag must be flipped to `"ABORT"`. Every subsequent block of code checks this global string before executing. This prevents the Export block from running if the Calculation block encountered bad data.

```essbase
/* 1. INITIALIZATION */
VAR vSetup = @CalcMgrCounterUpdateText("Job_Status", "Running");

/* 2. CALCULATION PASS */
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Gross_Margin" < -1000000)
        /* Catastrophic error found. Flip the global switch. 
           We use UpdateText to completely overwrite the 'Running' status. */
        VAR vFail = @CalcMgrCounterUpdateText("Job_Status", "ABORT");
    ENDIF
    
ENDFIX

/* 3. EXPORT PASS */
/* We check the global status before doing the heavy export */
IF(@CalcMgrCompare(@CalcMgrCounterGetText("Job_Status"), "ABORT", true))
    
    /* Do nothing, bypass export */
    
ELSE
    
    /* Safe to export */
    FIX("FY25", "Working")
        "Data_Export" = "Data";
    ENDFIX
    
ENDIF
```

---

### Example 2: Caching a String Attribute to Avoid Repeated Lookups

**Scenario**: You are running a calculation across thousands of products. The "Default_Currency" for the entire region is stored as a text attribute on the Region member. Rather than executing a string extraction (`@ATTRIBUTESVAL`) inside the dense product loop thousands of times, you extract it once, overwrite a memory variable with it, and reference the memory variable.

```essbase
FIX("FY25", "Working", "North_America")
    
    /* 1. Extract the string and cache it to memory using UpdateText */
    VAR vCurrStr = @ATTRIBUTESVAL("Default_Currency_Text");
    VAR vCache = @CalcMgrCounterUpdateText("Cached_Currency", vCurrStr);
    
    /* 2. Execute the dense loop */
    FIX(@LEVEL0("Product"))
        
        /* Retrieve the string from memory for evaluation */
        IF(@CalcMgrCompare(@CalcMgrCounterGetText("Cached_Currency"), "USD", true))
            "Local_Sales" = "Units" * 50;
        ELSE
            "Local_Sales" = "Units" * 45;
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting additive logic | Using `UpdateText` when you meant `AddText` | If the log is `"Error_1"`, and you use `UpdateText("Log", "Error_2")`, the final log is just `"Error_2"`. The first error is permanently deleted. If you want to build a comma-separated list, you MUST use `@CalcMgrCounterAddText` |
| Using on Numeric Counters | `UpdateText("ErrorCount", "Failed")` | If the bucket was previously created to hold numbers, attempting to overwrite it with a text string will cause validation errors or unpredictable engine behavior. Text goes with Text |
| Syntax execution failures | `@CalcMgrCounterUpdateText("Log", "Ready");` | In Essbase, you cannot call a function in a vacuum. It must be assigned to a String variable: `VAR vDummyStr = @CalcMgrCounterUpdateText(...)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterAddText`](./@CalcMgrCounterAddText.md) | Used when you want to *append* to the existing string (building a log) rather than replace it entirely |
| [`@CalcMgrCounterUpdateNumber`](./@CalcMgrCounterUpdateNumber.md) | The mathematical equivalent for completely overwriting a numeric total |
| [`@CalcMgrCounterGetText`](./@CalcMgrCounterGetText.md) | The required function to read the data back out of the memory bucket after you update it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterupdatetext.html)
