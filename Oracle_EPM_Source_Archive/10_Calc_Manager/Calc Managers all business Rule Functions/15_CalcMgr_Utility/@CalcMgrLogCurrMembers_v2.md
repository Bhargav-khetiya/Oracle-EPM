# @CalcMgrLogCurrMembers

## Overview

`@CalcMgrLogCurrMembers` is a **custom Calc Manager diagnostic logging function** in Oracle EPM Cloud (PBCS/EPBCS). It serves as a powerful debugging tool that captures the **exact dimensional intersection** (the specific combination of members) currently being evaluated by the Essbase engine, and physically writes that intersection into the official Calc Manager Job Console log.

### Why Does This Function Exist?

Essbase calculation scripts operate using multi-dimensional loop blocks (`FIX` statements). If you write a `FIX` on 1,000 Products and 100 Entities, Essbase will dynamically evaluate 100,000 unique intersections in memory. 
When a calculation fails, returns unexpected numbers, or triggers a "Divide by Zero" exception deep inside one of those blocks, finding the exact intersection where the math failed is like finding a needle in a haystack. Standard Essbase debugging involves manually isolating variables and writing dummy data to dummy accounts.
`@CalcMgrLogCurrMembers` completely revolutionizes debugging. You can drop this function directly inside an `IF` statement. When the script detects a specific mathematical anomaly (like an allocation failure), this function reaches into the engine's current state, extracts the exact member names it is currently sitting on (e.g., `"P_100, E_500, Jan"`), and stamps them permanently into the Job Log, telling the administrator exactly where to investigate.

### When to Use It

- **Targeted Debugging**: Printing the current intersection to the log only when an unexpected mathematical event occurs (e.g., an allocation output is `< 0`).
- **Loop Tracing**: Printing the current member inside a custom Java `FOR` loop to verify that the loop is iterating through the children in the correct order.
- **Audit Trails**: Providing a permanent log file proving that a specific entity was indeed touched and calculated during the overnight batch process.

---

## Category

**Diagnostic & Debugging / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrLogCurrMembers(dimensions)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimensions` | String | ✅ Yes | A comma-separated string listing the exact Dimension names whose current active member you want to log (e.g., `"Entity, Product, Period"`). |

---

## Return Value

**Return Type**: None (Void / Structural)

- This function does not return a mathematical value to the script.
- It physically writes a line to the **EPM Job Console** (accessible via the EPM web interface under Jobs > Job Details) containing the exact member names.
- Because it has no numeric output, it must be used as a standalone operational command, often wrapped inside a dummy variable or executed in a void state.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the string of dimension names.
2. **State Interrogation**: It halts the calculation momentarily and queries the active Essbase `CalcState` object to determine exactly which member block is currently loaded in the CPU register for the requested dimensions.
3. **String Construction**: It concatenates the active member names into a readable string (e.g., `"Current Members: [Product: P_105] [Entity: E_12]"`).
4. **Log Write**: It pushes that string directly to the active Log4j stream attached to the Job Console.

---

## Syntax Variants & Scenarios

### Variant 1: Logging Specific Dimensions

```essbase
/* Logs the current Entity and Product being calculated */
VAR vDummy = @CalcMgrLogCurrMembers("Entity, Product");
```

---

## Practical Examples

### Example 1: Hunting Down Negative Allocations

**Scenario**: A massive corporate allocation script runs across 5,000 cost centers. After the script runs, the CFO notices that some cost centers have negative allocated expenses (which is mathematically impossible based on the drivers). Instead of manually checking 5,000 intersections, the administrator adds `LogCurrMembers` to the script. If the calculation ever drops below 0, it will instantly print the exact guilty Entity and Cost Center to the Job Console.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"), @LEVEL0("Cost_Center"))
    
    /* 1. Calculate the dynamic allocation */
    "Allocated_Expense" = "Corporate_Pool" * "Headcount_Pct";
    
    /* 2. Set up the diagnostic trap */
    IF("Allocated_Expense" < 0)
        
        /* 
           3. The trap was triggered! 
           Log the exact intersection so we can fix the driver data tomorrow.
           (We assign it to a dummy variable to satisfy Essbase syntax).
        */
        VAR vLog = @CalcMgrLogCurrMembers("Entity, Cost_Center, Period");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Unconditional Logging | Putting it outside an `IF` statement | If you place this function inside a `FIX` statement of 100,000 members, and do not wrap it in an `IF` statement, it will write 100,000 lines to the Job Console. This will cause massive I/O bottlenecks, slowing your script from 5 seconds to 5 hours, and likely crashing the log viewer. Always use it surgically inside a conditional trap |
| Spelling the Dimension Wrong | Passing `"Entty"` instead of `"Entity"` | The parameter string must perfectly match the internal dimension names of your Essbase outline. If you misspell it, the Java engine cannot query the state and the script will fail |
| Expecting an On-Screen Pop-up | Looking for `@RETURN` behavior | This function does NOT abort the script, and it does NOT throw a red error box on the user's screen. It silently writes to the backend Job Console. The script will continue running seamlessly. If you want to stop the script and alert the user immediately, you must use `@RETURN(..., ERROR)` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogMemberStrings`](./@CalcMgrLogMemberStrings.md) | Logs a custom string of static member names rather than pinging the dynamic engine state |
| [`@CalcMgrLogMessageTrace`](./@CalcMgrLogMessageTrace.md) | A general-purpose logging function that allows you to write completely custom text strings and mathematical values to the Job Console |
| [`@RETURN`](../01_Flow_Control/@RETURN.md) | The native Essbase macro used to instantly abort a calculation script and throw a visible error message to the end-user |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_logcurrmembers.html)
