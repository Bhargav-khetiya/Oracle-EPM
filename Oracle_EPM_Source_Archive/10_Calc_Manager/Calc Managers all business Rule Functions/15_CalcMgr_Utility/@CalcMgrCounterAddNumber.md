# @CalcMgrCounterAddNumber

## Overview

`@CalcMgrCounterAddNumber` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It adds a specified numeric value to an invisible, globally tracked memory variable (a "counter") running in the background during the execution of a Business Rule.

### Why Does This Function Exist?

Standard Essbase calculation scripts evaluate data block by block, member by member. Native `VAR` variables exist, but they are often constrained to the local scope of the specific `FIX` block or member formula they are declared in. 
If you need to keep a running total of *something* across the entire execution of a complex, multi-pass business rule (e.g., keeping track of how many validation errors occurred across 15 different departments), standard variables often reset or fail to carry over between passes.
`@CalcMgrCounterAddNumber` creates a persistent, named memory bucket in the background Java engine. You can add numbers to it from anywhere in the script, and retrieve the final total at the very end of the script using `@CalcMgrCounterGetNumber`.

### When to Use It

- To track the total number of validation errors generated across an entire execution run.
- To create a running sum of a specific anomaly (e.g., "Total dollars written off due to rounding exceptions").
- To generate a unique sequence number or ID that increments every time a specific condition is met.
- In Groovy-hybrid rules where you need a bridge to pass a running total from the Essbase engine back to the Groovy script interface.

---

## Category

**State Tracking / Memory / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterAddNumber("CounterName", value)
```

### Formal Syntax

```
@CalcMgrCounterAddNumber("counterNameString", numericValueToAdd)
```

Where:
- `"counterNameString"` — The unique name you are giving to this specific memory bucket. Must be a string in double quotes.
- `numericValueToAdd` — The number to add to the current total in that bucket.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the counter. If the counter does not exist, the engine initializes it at 0 before adding the value. |
| `value` | Numeric| ✅ Yes | The number to add. Can be a hardcoded integer (e.g., `1`) or a dynamic data value (e.g., `"Exception_Amount"`). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the *new total value* of the counter immediately after the addition is performed.
*(Note: Because Calc Scripts require functions to be assigned to a data cell or evaluated in an IF statement, you often have to assign the result of this function to a temporary dummy account, or wrap it in a dummy IF statement to force it to execute).*

---

## How It Works (Behind the Scenes)

1. **Initialization Check**: The Java engine checks if a counter named `"CounterName"` already exists in the active memory heap for this specific script execution. If it doesn't, it creates it and sets it to `0`.
2. **Addition**: It adds the `value` to the counter's total.
3. **Persistence**: The counter stays alive in memory until the entire Business Rule finishes executing, allowing you to access it from completely different `FIX` blocks later in the script.
4. **Return**: It returns the new total to the current calculation context.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Increment (Counting Occurrences)

```essbase
/* Add 1 to the 'ErrorCount' memory bucket */
"Dummy_Account" = @CalcMgrCounterAddNumber("ErrorCount", 1);
```

### Variant 2: Running Sum of Data

```essbase
/* Add the actual dollar value of the exception to the memory bucket */
"Dummy_Account" = @CalcMgrCounterAddNumber("Total_Exceptions", "Write_Off_Amount");
```

---

## Practical Examples

### Example 1: Tracking Total Validation Errors Across Passes

**Scenario**: You have a massive validation script that runs across 100 entities. If any entity has a negative gross margin, it is an error. You want to count exactly how many errors occurred, and stamp that final total number into a centralized "System_Admin" entity so the administrator can see the global health of the database at a glance.

```essbase
/* PASS 1: Iterate through the entities and count errors */
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Gross_Margin" < 0)
        /* Flag the local entity */
        "Validation_Flag" = 1;
        
        /* Increment the global memory counter by 1. 
           We assign it to a local dummy variable just to satisfy Essbase syntax. */
        VAR vDummy = @CalcMgrCounterAddNumber("Global_Error_Count", 1);
    ENDIF
    
ENDFIX

/* PASS 2: Retrieve the final total and stamp it in the Admin console */
FIX("FY25", "Working", "System_Admin_Entity")
    
    /* Use GetNumber to pull the final tally from the memory bucket */
    "Total_Database_Errors" = @CalcMgrCounterGetNumber("Global_Error_Count");
    
    /* Optional: Clear the counter from memory to be safe */
    VAR vClear = @CalcMgrCounterClear("Global_Error_Count");
    
ENDFIX
```

---

### Example 2: Generating a Sequential ID

**Scenario**: You are generating a list of newly approved projects and writing them to a log. You want to assign each one a sequential ID (1, 2, 3...) based on the order they were processed during this specific script run.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    IF("Approval_Status" == 1 AND "Assigned_ID" == #MISSING)
        
        /* By adding 1 and returning the result directly into the account, 
           we generate a perfect sequential ID for each project as it calculates. */
        "Assigned_ID" = @CalcMgrCounterAddNumber("Project_ID_Sequence", 1);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Syntax execution failures | `@CalcMgrCounterAddNumber("Errors", 1);` | In Essbase, you cannot just drop a function on a line by itself. It must be assigned to an account or a `VAR`. Use `VAR vIgnore = @CalcMgrCounterAddNumber(...)` if you don't want to save the incremental steps to the database |
| Forgetting to clear counters | Running a rule back-to-back in the same session without clearing | While Calc Manager usually destroys counters at the end of a run, in complex Groovy sessions or nested rules, the memory might persist. Best practice is to use `@CalcMgrCounterClear("CounterName")` at the very end of your script |
| Performance hit on dense iterations | Putting this function inside a massive dense dimension loop | Because this function makes a callout to the Java engine memory heap, putting it inside a dense loop of 5 million cells will cause a severe performance bottleneck. Use it sparingly on sparse dimensions |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterGetNumber`](./@CalcMgrCounterGetNumber.md) | Retrieves the current total from the counter without adding anything to it |
| [`@CalcMgrCounterClear`](./@CalcMgrCounterClear.md) | Deletes the counter from memory, resetting it |
| [`@CalcMgrCounterAddText`](./@CalcMgrCounterAddText.md) | The equivalent function for appending text strings into a global memory bucket (useful for building dynamic error logs) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counteraddnumber.html)
