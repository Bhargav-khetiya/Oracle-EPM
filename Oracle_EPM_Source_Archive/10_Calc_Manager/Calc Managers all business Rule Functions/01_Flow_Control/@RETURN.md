# @RETURN

## Overview

`@RETURN` is a **control flow and debugging command** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **aborts the calculation script** immediately and returns a custom error message to the user. It functions as a hard stop or "fail-fast" mechanism.

### Why Does This Command Exist?

Business rules often have prerequisites. If those conditions aren't met, continuing the calculation might corrupt data, waste server resources, or produce invalid results:
- Running a forecast calculation when the forecast is already locked.
- Missing exchange rates required for currency translation.
- Allocations where the driver (denominator) is zero.
- User running a rule on an invalid combination of members (e.g., trying to clear Actuals).

`@RETURN` allows the developer to trap these errors gracefully, stop the rule, and tell the user exactly what went wrong.

### When to Use It

- For data validation checks at the very beginning of a business rule
- To prevent execution on locked periods, scenarios, or versions
- To halt calculations when a critical error condition is detected (e.g., divide by zero on a macro scale)
- To provide user-friendly error messages in the job console
- During script debugging to stop execution at a specific point and check variable values

---

## Category

**Flow Control / Error Handling / Debugging**

---

## Syntax

```essbase
@RETURN("ErrorMessage", severityLevel)
```

### Formal Syntax

```
@RETURN("messageString", level)
```

Where:
- `messageString` — The custom error message to display in the Job Console or UI.
- `level` — (Optional) The severity level: `ERROR`, `WARNING`, or `INFO`. Defaults to `ERROR`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `messageString` | String | ✅ Yes | The message to return to the user. Enclosed in double quotes. Can be a concatenated string containing variable values for detailed debugging. |
| `level` | Keyword | ❌ No | Severity level. Valid values are `ERROR` (default, stops script), `WARNING` (logs warning, script continues), or `INFO` (logs info, script continues). *Note: In many EPM Cloud contexts, `@RETURN` with any level acts as an abort. Always test local behavior.* |

---

## Return Value

`@RETURN` does not return a value to the script. If the level is `ERROR` (or omitted), it **terminates the script immediately**.

---

## How It Works (Behind the Scenes)

1. **Immediate Termination**: The moment Essbase encounters `@RETURN` (assuming `ERROR` level), all further processing stops. Any data blocks already written to disk remain, but no further blocks are processed.
2. **Job Console**: The error message specified is passed back up to the EPM Cloud Job Console. If a user launched the rule from a web form, the message typically pops up on their screen.
3. **Rollback (Caveat)**: Essbase BSO does **not** automatically roll back changes made prior to the `@RETURN` statement if they were already committed. Therefore, validation checks using `@RETURN` should ideally be placed at the very top of the script before any data is modified.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Hard Stop

```essbase
@RETURN("Calculation aborted: Target scenario is read-only.", ERROR);
```

### Variant 2: Conditional Stop

```essbase
IF(@ISMBR("Actual"))
    @RETURN("You cannot run this rule against Actuals.", ERROR);
ENDIF
```

### Variant 3: Concatenated Dynamic Message

```essbase
VAR vTotalDriver = @SUM("Headcount", @DESCENDANTS("Total Entity"));
IF(vTotalDriver == 0)
    @RETURN(@CONCATENATE("Allocation failed. Total headcount is zero for ", @NAME(@CURRMBR("Year"))), ERROR);
ENDIF
```

---

## Practical Examples

### Example 1: Preventing Execution on Locked Scenarios

**Scenario**: A user runs a rule, but you want to ensure they don't accidentally recalculate Actuals or a locked Version.

```essbase
FIX("Actual", "Final")
    /* If the script somehow gets here, stop immediately */
    IF(@ISMBR("Actual") OR @ISMBR("Final"))
        @RETURN("Error: You cannot execute this rule on Actual or Final data.", ERROR);
    ENDIF
ENDFIX

/* Main logic for working/forecast... */
FIX("Forecast", "Working")
    /* ... safe to calculate ... */
ENDFIX
```

---

### Example 2: Checking for Missing Exchange Rates

**Scenario**: Before running a heavy currency translation, ensure that a default rate exists.

```essbase
FIX("FY25", "Jan")
    VAR vDefaultRate = "Avg_Rate" -> "Global_Assumptions";
    
    IF(vDefaultRate == #MISSING OR vDefaultRate == 0)
        @RETURN("Translation aborted: Missing exchange rates in Global Assumptions.", ERROR);
    ENDIF
ENDFIX

/* Proceed with translation... */
```

---

### Example 3: Debugging a Variable Value

**Scenario**: You are writing a complex rule and want to see the value of a dynamically built string or number at runtime.

```essbase
VAR vSystemYearNum = @INT(@TODAY() / 10000);
VAR vCurrentFYStr = @CONCATENATE("FY", @SUBSTRING(@CalcMgrIntegerToString(vSystemYearNum), 2));

/* Stop the script and output the variable to verify it built "FY24" correctly */
@RETURN(@CONCATENATE("Debug - Built Year String is: ", vCurrentFYStr), ERROR);
```
*(Note: Once verified, you delete or comment out the `@RETURN` line).*

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Placing validation at the end | If `@RETURN` triggers after data has been modified and committed, you are left with partially calculated data | Always place `@RETURN` validation checks at the very top of the rule |
| Using `@RETURN` inside a loop | If used inside a `FIX` on a dense dimension, it might trigger multiple times or halt prematurely | Ensure the condition wrapping `@RETURN` is evaluated at the right block level |
| Forgetting quotes | `@RETURN(Error occurred, ERROR)` fails syntax | String must be quoted: `@RETURN("Error occurred", ERROR)` |
| Expecting automatic rollback | Essbase does not transactionally roll back a script upon `@RETURN` | Never assume a clean state if the script halts halfway through |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogStrings`](./@CalcMgrLogStrings.md) | Better for debugging (writes to a log file without stopping the script) |
| [`@CONCATENATE`](./@CONCATENATE.md) | Frequently used to build dynamic error messages for `@RETURN` |
| [`IF`](./IF.md) | Always wraps `@RETURN` so it only triggers on specific conditions |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @RETURN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/return.html)
