# @CalcMgrLogStrings

## Overview

`@CalcMgrLogStrings` is a **custom Calc Manager diagnostic logging function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a universal, general-purpose "Print Statement," allowing an administrator to inject **custom text variables or static messages** directly into the Calc Manager Job Console log during script execution. 
*(Note: This function is functionally identical to `@CalcMgrLogMessageTrace`. It exists as an alternative alias to align with the naming conventions of the `@CalcMgrLogValues` numeric logger).*

### Why Does This Function Exist?

When building dynamic calculation scripts, administrators constantly manipulate strings (e.g., dynamically generating a filename for an export, or constructing a cross-dimensional member name like `"FY25_Final"`). 
If the script fails, standard Essbase provides no visibility into what those temporary string variables actually looked like in memory at the exact moment of failure. Did the concatenation macro accidentally create `"FY25Final"` (missing the underscore)? 
`@CalcMgrLogStrings` resolves this by allowing you to manually print those temporary string variables directly to the backend Job Console. By placing these print statements right before a risky operation, you leave a permanent trace that proves exactly what the script was trying to do, drastically reducing debugging time.

### When to Use It

- **Variable Inspection**: Printing the final result of a complex `@CONCATENATE` and `@CalcMgrSubstring` chain to verify the syntax is correct.
- **Phase Tracking**: Dropping hardcoded breadcrumbs (e.g., `"--- STARTING ALLOCATIONS ---"`) between massive `FIX` blocks so you can monitor progress.
- **Dynamic File Exports**: Printing the dynamically generated filename of a data export to the log, creating an audit trail of exactly what files were generated during the overnight batch.

---

## Category

**Diagnostic & Debugging / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrLogStrings(message, string_variable)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | String | ✅ Yes | A custom text prefix or header to identify the log entry (e.g., `"Generated Target: "`). |
| `string_variable` | String | ✅ Yes | The actual string variable (or hardcoded string) you want to print into the log. |

---

## Return Value

**Return Type**: None (Void / Structural)

- This function does not return a mathematical value.
- It physically writes a concatenated line to the **EPM Job Console** (e.g., `Generated Target: FY25_Final`).
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
/* Assuming vTargetMember = "FY25_Final" */
VAR vLog = @CalcMgrLogStrings("The calculated target is: ", vTargetMember);
```

---

## Practical Examples

### Example 1: Creating an Audit Trail for Dynamic File Exports

**Scenario**: A script dynamically exports daily sales data. The export filename must include the current `YYYYMMDD` integer (e.g., `"Sales_Export_20241231.txt"`). The administrator wants the script to physically print the final filename into the Job Console so that the IT department has a permanent audit trail of exactly what file was created on what day.

```essbase
FIX("FY25", "Working", "No_Entity")
    
    /* 1. Capture the exact current date */
    VAR vTodayObj = @CalcMgrGetCurrentDate();
    
    /* 2. Format the date into a YYYYMMDD string */
    VAR vDateStr = @CalcMgrFormatDate(vTodayObj, "yyyyMMdd");
    
    /* 3. Build the final filename using Concatenation */
    VAR vFilenameStr = @CONCATENATE("Sales_Export_", @CONCATENATE(vDateStr, ".txt"));
    
    /* 
       4. Print the filename to the Job Console for Audit purposes. 
    */
    VAR vAuditLog = @CalcMgrLogStrings("File Successfully Generated: ", vFilenameStr);
    
    /* 5. (Conceptual) Execute the actual DataExport command using the variable */
    /* DATAEXPORT "File" "," vFilenameStr "Data"; */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Log Numbers | `@CalcMgrLogStrings("Value:", 100)` | This function explicitly expects the second parameter to be a **Text String**. If you try to pass a raw mathematical number, a float, or an Essbase account (like `"Sales"`), the Java engine will crash. If you need to log a numeric value, you must use `@CalcMgrLogValues` instead |
| Loop Flooding | Placing the log inside a massive `FIX` block | If you put this function inside a `FIX` statement touching 100,000 members, it will print 100,000 identical lines to the Job Console. This will cause massive I/O throttling and likely crash the server's logging buffer. Always log strings *outside* of large data loops, or wrap them in an `IF` statement |
| Thinking it Validates | Assuming it checks the outline | This function is a "dumb" printer. It literally just prints whatever string you give it. It does NOT check if the string actually exists in the database. If you want to validate if the string is a real member, you must use `@CalcMgrIsValidMember` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogMemberStrings`](./@CalcMgrLogMemberStrings.md) | An identical alias function. Functions exactly the same way |
| [`@CalcMgrLogValues`](./@CalcMgrLogValues.md) | The numeric equivalent of this function. Used to physically print mathematical numbers/doubles to the Job Console |
| [`@CalcMgrLogCurrMembers`](./@CalcMgrLogCurrMembers.md) | Automatically interrogates the engine and prints the active dimension members, rather than printing a custom string variable |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_logstrings.html)
