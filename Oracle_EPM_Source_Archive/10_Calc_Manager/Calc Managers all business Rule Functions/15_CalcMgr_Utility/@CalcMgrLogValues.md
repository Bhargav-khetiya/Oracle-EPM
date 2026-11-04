# @CalcMgrLogValues

## Overview

`@CalcMgrLogValues` is a **custom Calc Manager diagnostic logging function** in Oracle EPM Cloud (PBCS/EPBCS). Unlike string-based loggers, this function is designed specifically to capture **live numerical calculations or block data values** in memory and physically print them into the official Calc Manager Job Console log during the execution of a script.

### Why Does This Function Exist—

When a complex calculation script produces an incorrect final answer (e.g., Net Income is off by `$5M`), standard Essbase gives you no visibility into the intermediate steps. If the formula is `Net Income = (Revenue - COGS) * Tax_Rate`, and the result is wrong, you do not know which variable caused the error. 
To debug this in standard Essbase, you have to create "dummy" accounts (like `"Debug_Tax_Rate"`) in the database outline, save the intermediate variables to the database, run the script, open a Smart View grid, and check the dummy accounts manually. This bloats the database outline and requires structural changes just to trace a math error.
`@CalcMgrLogValues` eliminates this process. It acts as a real-time mathematical probe. You can wrap any numeric variable, formula, or Essbase block account inside this function. As the script runs, it instantly prints the actual numerical value of that variable to the backend Job Console. This allows you to inspect intermediate math outputs without ever saving them to the database.

### When to Use It

- **Formula Troubleshooting**: Printing the exact value of the numerator and denominator to the log right before a division operation to prove why a "Divide by Zero" error occurred.
- **Variable Inspection**: Verifying that a dynamically calculated runtime variable (e.g., `vDynamicRate`) is actually resolving to `0.05` instead of `5.0`.
- **Data Load Auditing**: Printing the exact opening balance of a critical account before the calculation begins, creating a permanent audit trail of what the data looked like before it was altered.

---

## Category

**Diagnostic & Debugging / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrLogValues(message, numeric_value)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | String | ✅ Yes | A custom text prefix or header to identify the number in the log (e.g., `"The Tax Rate is: "`). |
| `numeric_value` | Numeric | ✅ Yes | The actual mathematical variable, Essbase account, or hardcoded number you want to print. |

---

## Return Value

**Return Type**: None (Void / Structural)

- This function does not return a mathematical value to the script.
- It physically writes a concatenated line to the **EPM Job Console** (e.g., `The Tax Rate is: 0.05`).
- Because it has no numeric output, it must be assigned to a dummy variable to satisfy Essbase syntax.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the header string and the live numeric value.
2. **Type Coercion**: It automatically casts the numeric value into a string behind the scenes (effectively running a hidden `@CalcMgrDoubleToString`).
3. **Concatenation**: It combines the header string and the numeric string.
4. **Log Write**: It pushes that combined string directly to the active Log4j stream attached to the Job Console.

---

## Syntax Variants & Scenarios

### Variant 1: Logging a Live Variable

```essbase
/* Assuming vTaxRate = 0.25 */
VAR vLog = @CalcMgrLogValues("Calculated Tax Rate: ", vTaxRate);
```

---

## Practical Examples

### Example 1: Isolating a Calculation Anomaly (The Needle in the Haystack)

**Scenario**: A massive allocation script runs across 5,000 cost centers. 4,999 of them calculate perfectly. One of them fails and produces `#MISSING`. The administrator suspects the "Headcount_Pct" driver is missing for that specific cost center, but they aren't sure. They add `LogValues` wrapped in a trap to print the exact driver value to the log *only* when the allocation fails.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"), @LEVEL0("Cost_Center"))
    
    /* 1. Calculate the dynamic allocation */
    "Allocated_Expense" = "Corporate_Pool" * "Headcount_Pct";
    
    /* 2. Set up the diagnostic trap */
    IF("Allocated_Expense" == #MISSING)
        
        /* 
           3. The calculation failed! 
           Log the exact current member so we know WHERE we are. 
        */
        VAR vLog1 = @CalcMgrLogCurrMembers("Entity, Cost_Center");
        
        /* 
           4. Log the actual numerical values of the drivers at this exact intersection.
           This proves EXACTLY why the math failed.
        */
        VAR vLog2 = @CalcMgrLogValues("Corporate Pool Value was: ", "Corporate_Pool");
        VAR vLog3 = @CalcMgrLogValues("Headcount Pct Value was: ", "Headcount_Pct");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Log Strings | `@CalcMgrLogValues("Value:", "FY25")` | This function explicitly expects the second parameter to be a **Number**. If you try to pass a string (like `"FY25"`), the Java engine will crash because it cannot trace a string in a numeric function. If you need to log a string, you must use `@CalcMgrLogStrings` instead |
| Loop Flooding | Placing the log outside an `IF` statement inside a massive `FIX` block | If you drop `LogValues("Revenue:", "Revenue")` inside a `FIX` statement touching 1 million members, it will print the revenue for all 1 million members to the Job Console. This will cause massive I/O throttling, drastically slow down your calculation, and likely crash the server's logging buffer. Always log values selectively using `IF` traps |
| Misunderstanding Output | Trying to save the result to the database | `VAR vResult = @CalcMgrLogValues(...)` does NOT assign the number to `vResult`. It executes the log and assigns a void/dummy value to `vResult`. You cannot use `vResult` in subsequent math |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogStrings`](./@CalcMgrLogStrings.md) | The string equivalent of this function. Used to print text variables instead of numbers |
| [`@CalcMgrLogCurrMembers`](./@CalcMgrLogCurrMembers.md) | Prints the active dimension members so you know *where* the math is currently occurring before logging the values |
| [`@CalcMgrDoubleToString`](./@CalcMgrDoubleToString.md) | Used if you want to manually convert the number to a string and handle the logging/concatenation yourself |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_logvalues.html)
