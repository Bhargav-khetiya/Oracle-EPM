# @CalcMgrCounterClear

## Overview

`@CalcMgrCounterClear` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It completely deletes a specific, named memory counter (whether text or numeric) from the background Java heap memory, resetting it entirely.

### Why Does This Function Exist—

When you use `@CalcMgrCounterAddNumber` or `@CalcMgrCounterAddText`, Calc Manager spins up an invisible memory bucket in the background. Because these buckets exist in the Java heap rather than inside the Essbase multidimensional blocks, they persist *across* different `FIX` statements within the same script.
However, in highly complex architectures—especially those involving nested Business Rules, Groovy scripts iterating over data slices, or continuous user sessions—these counters can persist longer than intended. If a user runs a rule twice in a row, a counter named `"ErrorLog"` might still contain the text from the *first* run, causing the second run to append data to an already full log.
`@CalcMgrCounterClear` ensures that you are wiping the slate clean. It acts as essential garbage collection and initialization for your custom memory logic.

### When to Use It

- **At the beginning of a script**: To initialize a counter and ensure it is absolutely empty before you start adding to it.
- **At the end of a script**: As good housekeeping to free up Java memory and prevent leakage into subsequent rules.
- **Inside loops**: If you need to track a sub-total for a specific Entity, and then clear the counter before moving to the next Entity.

---

## Category

**State Tracking / Memory / Initialization / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterClear("CounterName")
```

### Formal Syntax

```
@CalcMgrCounterClear("counterNameString")
```

Where:
- `"counterNameString"` — The exact unique name of the memory bucket you wish to destroy/reset. Must be enclosed in double quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the specific text or numeric counter to clear. |

---

## Return Value

**Return Type**: Numeric (0)

Returns `0` upon successfully clearing the counter. 
*(Note: As with most Calc Manager custom functions, you must assign the result of this function to a temporary dummy account or variable to force Essbase to execute it).*

---

## How It Works (Behind the Scenes)

1. **Lookup**: The Java engine searches the active memory heap for a counter matching the `"CounterName"`.
2. **Destruction**: If it finds the counter, it nullifies the object and removes it from the hash map tracking the state.
3. **Return**: It returns `0`. If the counter never existed in the first place, it simply returns `0` harmlessly, making it completely safe to call at the start of a script even if you aren't sure if the counter exists yet.

---

## Syntax Variants & Scenarios

### Variant 1: Initializing at the start of a script

```essbase
/* Run this before any FIX statements to ensure a clean slate */
VAR vInit = @CalcMgrCounterClear("Global_Error_Count");
```

---

## Practical Examples

### Example 1: Safe Initialization and Cleanup for a Validation Run

**Scenario**: You have a validation script that counts errors. You want to ensure the counter is `0` when the script starts (just in case it was lingering in memory from a previous execution), and you want to clean it up at the very end to be a good citizen of the server's memory.

```essbase
/* 1. INITIALIZATION (Clean Slate) */
VAR vInit = @CalcMgrCounterClear("Global_Error_Count");

/* 2. THE LOGIC PASS */
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Gross_Margin" < 0)
        /* Increment the global memory counter by 1 */
        VAR vDummy = @CalcMgrCounterAddNumber("Global_Error_Count", 1);
    ENDIF
    
ENDFIX

/* 3. THE REPORTING PASS */
FIX("FY25", "Working", "System_Admin_Entity")
    
    /* Retrieve the final tally */
    "Total_Database_Errors" = @CalcMgrCounterGetNumber("Global_Error_Count");
    
ENDFIX

/* 4. CLEANUP (Garbage Collection) */
VAR vCleanup = @CalcMgrCounterClear("Global_Error_Count");
```

---

### Example 2: Sub-Totaling Inside a Cross-Dimensional Loop

**Scenario**: You are looping through Regions. For *each* Region, you want to count the number of highly profitable stores, stamp that number into a Region-level metric account, and then *reset* the counter so the next Region starts from zero.

```essbase
FIX("FY25", "Working")
    
    /* Iterate through every Level 1 Region */
    FIX(@IDESCENDANTS("Total Geography"))
        IF(@ISLEV("Geography", 1))
            
            /* Clear the counter at the start of the new Region */
            VAR vReset = @CalcMgrCounterClear("Store_Count");
            
            /* Loop through the Level 0 Stores underneath this specific Region */
            FIX(@CHILDREN(@CURRMBR("Geography")))
                
                IF("Profit_Margin" > 0.20)
                    /* Add 1 to the counter */
                    VAR vAdd = @CalcMgrCounterAddNumber("Store_Count", 1);
                ENDIF
                
            ENDFIX
            
            /* Pull the total for this specific region and stamp it */
            "Highly_Profitable_Store_Count" = @CalcMgrCounterGetNumber("Store_Count");
            
        ENDIF
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not assigning the function | `@CalcMgrCounterClear("Errors");` | You cannot call a function in a vacuum in Essbase. It must be assigned to a variable or account: `VAR vDummy = @CalcMgrCounterClear("Errors");` |
| Clearing the wrong counter | Typo in the name: `"ErrorLog"` vs `"Error_Log"` | The engine is string-literal. If you clear `"ErrorLog"` but are writing to `"Error_Log"`, the memory will not be cleared. Standardize your counter names carefully |
| Forgetting to clear in Groovy loops | Running a Groovy script that loops Business Rules | If a Groovy script executes the same business rule 50 times in a row, the counters *will* bleed across executions unless explicitly cleared on line 1 of the `.csc` script |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterClearAll`](./@CalcMgrCounterClearAll.md) | A heavier version that clears *every single counter* in memory blindly, without needing a specific name |
| [`@CalcMgrCounterAddNumber`](./@CalcMgrCounterAddNumber.md) | Creates and adds to a numeric counter |
| [`@CalcMgrCounterAddText`](./@CalcMgrCounterAddText.md) | Creates and adds to a text counter |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterclear.html)
