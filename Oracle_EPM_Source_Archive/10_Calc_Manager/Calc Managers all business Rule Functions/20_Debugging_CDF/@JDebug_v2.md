# @JDebug

## Overview

`@JDebug` is a **Hyperion Planning (HSP) custom Java-based diagnostic function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It acts as an advanced, programmatic breakpoint and diagnostic tracer inside an Essbase calculation script. It writes real-time evaluation states, variable contents, and calculation context directly into the server logs during execution.

### Why Does This Function Exist?

Debugging Essbase calculation scripts is notoriously difficult. Because Essbase compiles the script and executes it deep inside the C-engine memory block-by-block, administrators cannot natively "pause" the script or see what a variable equals at Line 45 vs Line 80.
If an allocation is producing the wrong result for `"Store_101"`, the administrator historically had to write temporary data to dummy accounts and run reports to guess what the math engine was doing.
`@JDebug` leverages the modern Java Custom Defined Function (CDF) framework to open a diagnostic channel. You place `@JDebug` directly inside a complex `IF` statement or loop. When the engine hits that line, it captures the text payload you provided (which can include dynamic variables or member names) and streams it directly to the Job Console or application log. This allows true, real-time code tracing without polluting the database with dummy data.

*Note: In modern Oracle EPM Cloud, this function is often aliased or superseded by `@CalcMgrLogText` or the built-in Rule Debugger UI. However, `@JDebug` remains a core foundational tool in legacy and highly customized on-premise migrations.*

### When to Use It

- **Loop Tracing**: Printing the current index iteration of a massive `LOOP` to ensure the math is advancing correctly.
- **Variable Auditing**: Printing the exact numeric contents of a `VAR` variable right before it is injected into a formula, proving that the variable was initialized properly.
- **Error Trapping**: Placing a `@JDebug("Math Failed Here")` statement inside an `ELSE` condition that should never mathematically trigger, allowing admins to pinpoint exactly which entity caused a failure.

---

## Category

**Planning Extensions / Java Diagnostics & Logging / Custom Java Functions**

---

## Syntax

```essbase
@JDebug("Diagnostic_String_Payload")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Diagnostic_String_Payload"` | String | ✅ Yes | The explicit text string (or concatenated string variable) that you want written into the server log. Must evaluate to valid text. |

---

## Return Value

**Return Type**: Numeric (Status Code)

Returns an integer status code indicating whether the log write was successful.
- **`0`**: Success. The diagnostic payload was successfully written to the log.
- **`< 0`**: Failure. The Java Virtual Machine (JVM) failed to write the log, usually due to string concatenation errors or log file lockouts.
- **Storage**: Because it returns a number, you must assign it to a temporary variable (e.g., `VAR vStatus = @JDebug("Hello");`) to satisfy the Essbase compiler syntax.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The calculation engine hits the `@JDebug` line.
2. **Payload Resolution**: It resolves the text string inside the parameter, converting any concatenated numeric variables into text.
3. **Java Call**: It pauses the C-engine calculation thread and hands the text payload off to the JVM via the Java Native Interface (JNI).
4. **Log Write**: The JVM opens the server diagnostic log (or Job Console stream) and writes the text payload, usually appending a timestamp and thread ID.
5. **Return**: The JVM returns a `0` back to Essbase, and the calculation engine resumes processing the very next line of the script.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Breakpoint Logging

```essbase
/* 
   Writes a simple text flag into the log when executed.
*/
VAR vLog = @JDebug("Entered the Overhead Allocation Block");
```

---

## Practical Examples

### Example 1: Tracing Dynamic Variables in a Loop

**Scenario**: A complex depreciation script loops over an asset's useful life. The administrator suspects the `vRemainingLife` variable is getting stuck at zero, causing a divide-by-zero error. They use `@JDebug` to print the exact value of the variable during every single pass of the loop for a specific test asset.

```essbase
FIX("FY25", "Working", "Asset_Test_001")
    
    VAR vRemainingLife = 60;
    
    LOOP(60)
        
        /* 
           1. We want to log the current value. 
           Because @JDebug requires a string, we must cast the number 
           to a string and concatenate it first.
        */
        VAR vLifeStr = @CalcMgrIntegerToString(vRemainingLife);
        VAR vLogStr = @HspConcat("Current Loop Remaining Life: ", vLifeStr);
        
        /* 
           2. Execute the debug logger.
           This will print: "Current Loop Remaining Life: 60", then 59, etc.
        */
        VAR vLog = @JDebug(vLogStr);
        
        /* 
           3. Execute the actual math.
        */
        "Depreciation" = "Net_Value" / vRemainingLife;
        
        /* Decrement the counter */
        vRemainingLife = vRemainingLife - 1;
        
    ENDLOOP
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Raw Numbers | `@JDebug(500)` | The Java logger strictly requires a Text String. If you pass a raw number or an Essbase member object (`@CURRMBR("Entity")`), the compiler will crash with a Type Mismatch. You MUST cast numbers to strings (using `@CalcMgrDoubleToString`) and members to strings (using `@NAME`) before passing them to the debugger |
| Leaving it in Production | Massive Log Bloat | Debug functions require calling the JVM. If you leave `@JDebug` inside a `FIX` statement that calculates 500,000 blocks, you will execute 500,000 Java network calls, massively slowing down the calculation and completely filling up the server hard drive with log files. **ALWAYS comment out or delete debug lines before migrating scripts to Production.** |
| Ignoring the Return Variable | `@JDebug("Error");` | In Essbase, functions that return values must be assigned to something, or wrapped in an `IF` statement. A bare function call hanging on a line will cause a syntax error. Always write `VAR vDummy = @JDebug("Error");` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogText`](../15_CalcMgr_Utility/@CalcMgrLogStrings.md) | The modern, universally standardized equivalent for EPM Cloud. It performs the exact same function but is natively tied to the modern Job Console UI |
| [`@JSendDebug`](./@JSendDebug.md) | A legacy variant of the debug function, occasionally used to route logs to specific target files rather than the general server output |
| [`@HspConcat`](../16_HSP_Functions/@HspConcat.md) | The primary utility used to mash text and variables together into a single payload before sending it to `@JDebug` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Java Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_jdebug.html) *(Note: Specific legacy J-functions may be undocumented or deprecated in the latest SaaS patches).*
