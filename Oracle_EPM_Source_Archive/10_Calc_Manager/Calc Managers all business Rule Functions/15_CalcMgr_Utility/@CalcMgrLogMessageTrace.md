# @CalcMgrLogMessageTrace

## Overview

`@CalcMgrLogMessageTrace` is a **custom Calc Manager diagnostic logging function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a universal, general-purpose "Print Statement," allowing an administrator to inject **custom informational alerts, trace markers, or status updates** directly into the Calc Manager Job Console log during the execution of a script.

### Why Does This Function Exist?

When executing monolithic, hour-long calculation scripts that consolidate hundreds of entities and process millions of data points, it is often impossible to know exactly which phase of the script is currently running. If the script crashes after 45 minutes, administrators have no idea if it crashed during the "Currency Translation" phase or the "Overhead Allocation" phase.
While specialized functions exist to print specific array values (`LogValues`) or current members (`LogCurrMembers`), there is a critical need for simple, human-readable breadcrumbs. 
`@CalcMgrLogMessageTrace` resolves this by allowing you to strategically place hardcoded text markers (e.g., `"--- PHASE 1 COMPLETE ---"`) throughout your script. As the script runs, these markers are printed in real-time to the backend Job Console, giving you a perfect trace history of exactly what the script was doing and when.

### When to Use It

- **Phase Tracking**: Dropping breadcrumbs between massive `FIX` blocks so you can open the Job Console and monitor the script's progress in real-time.
- **Timing Benchmarks**: Pairing this function with `@CalcMgrGetCurrentDateTime` to print exact timestamps to the log before and after a specific block, allowing you to calculate exactly how long that specific block took to run.
- **Error Trapping**: Printing a custom text alert just before a highly volatile Java custom function executes.

---

## Category

**Diagnostic & Debugging / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrLogMessageTrace(message)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | String | ✅ Yes | The custom text string you want to print into the log (e.g., `"Starting Currency Translation..."`). |

---

## Return Value

**Return Type**: None (Void / Structural)

- This function does not return a mathematical value to the script.
- It physically writes a single line to the **EPM Job Console**.
- Because it has no numeric output, it must be assigned to a dummy variable to satisfy Essbase syntax.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Log Routing**: It intercepts the string and routes it directly to the active Log4j stream attached to the Job Console.
3. **Execution**: The string is appended to the bottom of the log file, complete with an automatic system timestamp.

---

## Syntax Variants & Scenarios

### Variant 1: Dropping a Static Trace Marker

```essbase
/* Prints a simple status update to the backend log */
VAR vTrace1 = @CalcMgrLogMessageTrace("Phase 2: Executing Allocations");
```

---

## Practical Examples

### Example 1: Real-Time Performance Benchmarking

**Scenario**: A massive consolidation script takes 45 minutes to run. The administrator suspects the "Currency Translation" block is causing the bottleneck, but they cannot prove it. They use `LogMessageTrace` combined with dynamically formatted Timestamps to print exact Start and End times directly to the log.

```essbase
/* 
   ------------------------------------------------------
   PHASE 1: START TIMING
   ------------------------------------------------------
*/
/* 1. Get the current exact timestamp */
VAR vStartObj = @CalcMgrGetCurrentDateTime();

/* 2. Format it into a readable string */
VAR vStartStr = @CalcMgrGetStringFormattedDateTime(vStartObj, "HH:mm:ss");

/* 3. Concatenate and Print the Trace to the Log */
VAR vTraceStart = @CalcMgrLogMessageTrace(@CONCATENATE("Starting Currency Translation at: ", vStartStr));


/* 
   ------------------------------------------------------
   PHASE 2: EXECUTE THE MASSIVE BLOCK
   ------------------------------------------------------
*/
FIX("FY25", "Working", @IDESCENDANTS("Total_Geography"))
    /* Massive FX translation logic */
    "USD" = "Local" * "FX_Rate";
ENDFIX


/* 
   ------------------------------------------------------
   PHASE 3: END TIMING
   ------------------------------------------------------
*/
/* 1. Get the new exact timestamp */
VAR vEndObj = @CalcMgrGetCurrentDateTime();
VAR vEndStr = @CalcMgrGetStringFormattedDateTime(vEndObj, "HH:mm:ss");

/* 2. Print the final Trace to the Log */
VAR vTraceEnd = @CalcMgrLogMessageTrace(@CONCATENATE("Finished Currency Translation at: ", vEndStr));

/* 
   Result: The administrator can open the Job Console and see:
   "Starting Currency Translation at: 18:05:00"
   "Finished Currency Translation at: 18:42:00"
   Confirming the block takes exactly 37 minutes.
*/
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Log Numbers | `@CalcMgrLogMessageTrace(100)` | This function explicitly expects a **Text String**. If you try to pass a raw mathematical number or an Essbase account (like `"Sales"`), the Java engine will crash because it cannot trace a float. If you need to log a numeric value, you must convert it to a string first using `@CalcMgrDoubleToString`, or use `@CalcMgrLogValues` |
| Excessive Looping | Putting the trace inside the `FIX` | If you drop `LogMessageTrace("Calculating...")` *inside* a `FIX` statement that touches 100,000 members, the Java engine will attempt to write 100,000 lines to the log file. This will bottleneck the server's I/O and massively slow down your script. Always place trace markers *outside* of large data loops, as shown in the example |
| Expecting User Popups | Using it to warn end-users | This function writes silently to the backend Job Console. The end-user running the script from a web form will NEVER see these messages. If you need to send an alert or stop a script so a user sees it on their screen, you must use `@RETURN("Message", ERROR)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogStrings`](./@CalcMgrLogStrings.md) | An identical alias function. Functions exactly the same way |
| [`@CalcMgrLogCurrMembers`](./@CalcMgrLogCurrMembers.md) | Prints the actual dimensional intersection being calculated, rather than a custom string |
| [`@RETURN`](./@RETURN.md) | Aborts the script and prints the message to the user's screen, rather than silently writing to the backend log |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_logmessagetrace.html)
