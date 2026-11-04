# @HspGetFileName

## Overview

`@HspGetFileName` is a **Hyperion Planning (HSP) custom administrative function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It dynamically retrieves the **exact physical filename (text string)** of the Essbase calculation script (.csc file) that is currently executing on the server.

### Why Does This Function Exist—

In massive EPM implementations, it is common to have dozens of complex allocation scripts, aggregation routines, and data pushes running overnight in a tightly scheduled batch. If one of those calculations encounters dirty data (e.g., `"Net_Income" < 0`), it needs to log an error.
If the error simply says "Validation Failed on Cost Center 100", the administrator might have to comb through 50 different calculation scripts to figure out *which rule* actually threw the error. 
`@HspGetFileName` solves this traceability issue. By dynamically extracting the name of the currently running script, developers can prepend it to their error messages (e.g., `"Alloc_Rule_05.csc: Validation Failed on Cost Center 100"`). This creates a self-documenting audit trail, making debugging and maintenance exponentially faster in Enterprise environments.

### When to Use It

- **Dynamic Job Console Logging**: Automatically stamping every custom warning or error logged to the Job Console with the name of the script that generated it.
- **Smart Audit Trails**: Writing rows to a custom SQL audit table (via other CDFs) that log exactly which business rules executed at what times.
- **Reusable Macros**: Embedding this function inside a globally shared EPM Macro. Regardless of which specific calculation script calls the macro, the macro can dynamically identify its caller.

---

## Category

**Planning Extensions / Diagnostics & Auditing / Custom HSP Functions**

---

## Syntax

```essbase
@HspGetFileName()
```

---

## Parameters

This function accepts **no parameters**. It evaluates the internal execution context of the Essbase server thread.

---

## Return Value

**Return Type**: String

Returns a text string containing the exact filename of the calculation script currently being processed.
- **Format**: It typically returns the filename with the extension (e.g., `"Calc_OpEx_Alloc.csc"`). In some specific EPBCS implementations triggered from Web Forms, it may return the internal Rule ID.
- **Storage**: Because it returns text, you CANNOT save the output directly into a standard numeric Essbase account. It must be assigned to a `VAR` string variable and passed into a string-consuming function (like a logger).

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the function inside the script.
2. **Context Query**: The function queries the underlying C-engine's active thread properties.
3. **Extraction**: It pulls the "Script Name" property attached to the active calculation job.
4. **Return**: It returns that property as a readable string to the script.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Filename Retrieval

```essbase
/* 
   If this code is running inside a script named "Agg_Actuals.csc",
   vScriptName will contain the string "Agg_Actuals.csc".
*/
VAR vScriptName = @HspGetFileName();
```

---

## Practical Examples

### Example 1: Self-Documenting Validation Logs

**Scenario**: A company has a global `"Validate_Data"` macro that is inserted into the bottom of every single calculation script. The macro checks if total Assets equal total Liabilities (`"Balance_Check" != 0`). If the balance sheet is out of balance, it must log an error. By using `@HspGetFileName`, the macro dynamically tells the administrator exactly which script broke the balance sheet, without the administrator having to hardcode the script name in 50 different places.

```essbase
FIX("FY25", "Working", @LEVEL0("Entities"))
    
    /* Check if the Balance Sheet is out of balance */
    IF("Balance_Check" != 0)
        
        /* 
           1. Extract the name of the script that is currently running.
           (e.g., "Run_Allocations.csc")
        */
        VAR vCallerScript = @HspGetFileName();
        
        /* 
           2. Extract the name of the entity that failed.
        */
        VAR vEntityStr = @NAME(@CURRMBR("Entity"));
        
        /* 
           3. Build the composite string message.
           We use @CalcMgrStringsToString to join them together.
           Format: "[Run_Allocations.csc] Out of Balance on Entity: New_York"
        */
        VAR vPrefix = @CalcMgrStringsToString("[", vCallerScript, "] Out of Balance on Entity: ");
        VAR vFullMsg = @CalcMgrStringsToString(vPrefix, vEntityStr);
        
        /* 
           4. Write the highly detailed message directly to the Job Console.
        */
        VAR vLogStatus = @CalcMgrLogText(vFullMsg);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Save to an Account | `"Script_Name" = @HspGetFileName();` | **Essbase Data Cells CANNOT store text strings.** They only store numbers. If you try to assign the string `"Alloc_01.csc"` to a standard member, the block will reject it, writing `#MISSING` or throwing a compilation error. The string must be kept in a `VAR` memory variable and passed to a logging function |
| Misunderstanding Cloud Business Rules | Expecting human-readable names | In modern EPM Cloud, Business Rules built in Calc Manager are translated into `.csc` files on the backend before execution. Depending on how the rule was deployed or triggered (e.g., via Groovy or a Job), the underlying `.csc` file might have an internal, cryptic alphanumeric name (e.g., `HSP_R12345.csc`) rather than the readable name you assigned in the UI. Test this in your specific environment to ensure the output is useful for your auditing needs |
| Using it Outside of Logging | Using it in `IF` statements | While technically possible, using `@HspGetFileName()` to conditionally branch calculation logic (e.g., `IF(Name == "Rule1.csc")`) is extremely bad practice. It creates brittle code that breaks instantly if a developer renames the rule. Logic branching should be controlled by variables or explicitly passed runtime prompts, not by evaluating the filename |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogText`](../15_CalcMgr_Utility/@CalcMgrLogStrings.md) | The primary consumer function. `HspGetFileName` extracts the string, and `CalcMgrLogText` actually writes that string into the Job Console for the administrator to read |
| [`@CalcMgrStringsToString`](../10_String/@CalcMgrStringsToString.md) | Used to concatenate the filename string with dynamic member names (like `@NAME(@CURRMBR("Entity"))`) to build the final, comprehensive error message |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspgetfilename.html)
