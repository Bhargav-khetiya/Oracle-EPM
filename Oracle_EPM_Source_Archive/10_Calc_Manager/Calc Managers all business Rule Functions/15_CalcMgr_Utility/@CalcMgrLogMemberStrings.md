# @CalcMgrLogMemberStrings

## Overview

`@CalcMgrLogMemberStrings` is a **custom Calc Manager diagnostic logging function** in Oracle EPM Cloud (PBCS/EPBCS). Unlike `@CalcMgrLogCurrMembers` (which dynamically checks the active calculation state), this function allows you to manually inject a **static, concatenated string of member names or text** directly into the official Calc Manager Job Console log during the execution of a script.

### Why Does This Function Exist—

When executing complex calculation scripts, administrators often build dynamic string variables that represent target database intersections. For example, a script might slice the current year, add 1 to it, concatenate it into `"FY25"`, and then attempt to copy data. 
If the data copy fails or produces unexpected results, the administrator needs to know exactly what string was generated in memory before the failure occurred. Standard Essbase gives you no visibility into temporary string variables once the script finishes running. 
`@CalcMgrLogMemberStrings` resolves this by acting as a "Print Statement" for text variables. You can pass your dynamically generated member string into this function, and it will physically print it to the backend Job Console. This allows you to verify that your string manipulation logic (e.g., your substrings and concatenations) is actually producing the valid member names you expected.

### When to Use It

- **Macro Debugging**: Verifying that a massive string concatenation macro actually built `"Actuals_FY25_Final"` instead of accidentally building `"Actuals_FY25Final"`.
- **Milestone Tracking**: Printing static messages like `"--- FINISHED OVERHEAD ALLOCATIONS ---"` into the log to trace exactly how far a massive script progressed before it crashed.
- **User Prompt Tracing**: Printing exactly what text the user typed into a runtime prompt before the script attempts to parse it.

---

## Category

**Diagnostic & Debugging / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrLogMemberStrings(message, memberStrings)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | String | ✅ Yes | A custom text prefix or header to identify the log entry (e.g., `"Target Member Generated: "`). |
| `memberStrings` | String | ✅ Yes | The actual string variable (or hardcoded string) you want to print into the log. |

---

## Return Value

**Return Type**: None (Void / Structural)

- This function does not return a mathematical value to the script.
- It physically writes a concatenated line to the **EPM Job Console** (e.g., `Target Member Generated: FY25`).
- Because it has no numeric output, it must be assigned to a dummy variable to satisfy Essbase syntax.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the header string and the target payload string.
2. **Concatenation**: It combines them into a single, highly readable log statement.
3. **Log Write**: It pushes that combined string directly to the active Log4j stream attached to the Job Console.

---

## Syntax Variants & Scenarios

### Variant 1: Logging a Dynamically Generated String

```essbase
/* Assuming vTargetMember = "FY25" */
VAR vLog = @CalcMgrLogMemberStrings("The Script will now write to: ", vTargetMember);
```

---

## Practical Examples

### Example 1: Debugging Cross-Dimensional Target Construction

**Scenario**: A dynamic rolling forecast script builds a target cross-dimensional string based on user inputs. The script is failing with an "Invalid Member" error. The administrator cannot tell if the error is caused by the Year, the Scenario, or a missing underscore. They use `LogMemberStrings` to print the final constructed string to the log right before the data copy executes.

```essbase
FIX("Working", @LEVEL0("Accounts"))
    
    /* 1. Build the dynamic components */
    VAR vYearStr = @CalcMgrSubstring({Target_Year}, 2);
    VAR vVersionStr = "Final_V1";
    
    /* 2. Concatenate the target block (e.g. "FY24_Final_V1") */
    VAR vTargetBlock = @CONCATENATE(@CONCATENATE("FY", vYearStr), @CONCATENATE("_", vVersionStr));
    
    /* 
       3. DEBUGGING TRAP: Print the exact string to the Job Console.
       If the script crashes on the next line, the administrator can check the 
       log and see exactly what vTargetBlock looked like. 
    */
    VAR vLog = @CalcMgrLogMemberStrings("ATTEMPTING TO COPY TO BLOCK: ", vTargetBlock);
    
    /* 4. Execute the copy (This is where the crash might occur) */
    FIX(@MEMBER(vTargetBlock))
        "Forecast" = "Actuals";
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Log Numbers | `@CalcMgrLogMemberStrings("Value:", 100)` | This function explicitly expects the second parameter to be a **Text String**. If you try to pass a raw mathematical number, a float, or an Essbase account (like `"Sales"`), the Java engine will crash. If you need to log a numeric value, you must either convert it to a string first (`@CalcMgrDoubleToString`) or use `@CalcMgrLogValues` instead |
| Loop Flooding | Placing the log inside a massive `FIX` block | If you put this function inside a `FIX` statement touching 1 million members, it will print 1 million identical lines to the Job Console. This will cause massive I/O throttling and likely crash the server's logging buffer. Always try to log strings *outside* of large data loops, or wrap them in an `IF` statement |
| Thinking it Validates | Assuming it checks the outline | This function is a "dumb" printer. It literally just prints whatever string you give it. It does NOT check if the member string actually exists in the database. If you want to validate if the string is real, you must use `@CalcMgrIsValidMember` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogCurrMembers`](./@CalcMgrLogCurrMembers.md) | Automatically interrogates the engine and prints the active dimension members, rather than printing a custom string variable |
| [`@CalcMgrLogValues`](./@CalcMgrLogValues.md) | The numeric equivalent of this function. Used to physically print mathematical numbers/doubles to the Job Console |
| [`@CalcMgrLogMessageTrace`](./@CalcMgrLogMessageTrace.md) | A generic wrapper that functions almost identically to this one |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_logmemberstrings.html)
