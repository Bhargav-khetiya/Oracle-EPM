# @JSendDebug

## Overview

`@JSendDebug` is a **Hyperion Planning (HSP) custom Java-based diagnostic function** embedded within Oracle EPM Cloud (PBCS/EPBCS). Similar to `@JDebug`, it acts as a programmatic breakpoint tracer. However, while standard debuggers write directly to the primary server log, `@JSendDebug` was historically designed to push diagnostic text payloads over a specific network socket or to a designated remote debugging listener.

### Why Does This Function Exist—

In massive On-Premise Hyperion deployments (where calculating nodes and UI nodes are separated across different physical servers), checking a local server text log for a specific calculation error is tedious. 
Furthermore, if 100 users are running calculations simultaneously, the primary server log becomes an unreadable mess of intertwined messages.
`@JSendDebug` was built to allow the calculation engine to bypass the local file system entirely. It takes the text payload and broadcasts it out to an active Java debugger listener (often tied to the developer's local IDE or a specialized monitoring port). This allows a developer to watch the calculation script execute and read the variables in real-time on a completely separate machine.

*Note: In modern Oracle EPM Cloud SaaS environments, network sockets and remote JVM debugging are strictly locked down by Oracle for security. Consequently, `@JSendDebug` is effectively deprecated in Cloud. It is typically aliased internally to act identically to `@CalcMgrLogText` or simply ignored. It remains here strictly for backwards compatibility with legacy on-premise scripts.*

### When to Use It

- **Remote JVM Monitoring**: (Legacy On-Premise) Sending real-time calculation status updates to a remote listener port to monitor the progress of a 10-hour aggregation script without locking the primary log file.
- **Advanced State Tracing**: Emitting dynamic variable values out of deep recursive loops for real-time analysis.
- **Legacy Migrations**: Maintaining older calculation scripts that have not yet been modernized to use `@CalcMgrLogText`.

---

## Category

**Planning Extensions / Java Diagnostics & Logging / Custom Java Functions**

---

## Syntax

```essbase
@JSendDebug("Diagnostic_String_Payload")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Diagnostic_String_Payload"` | String | ✅ Yes | The explicit text string (or dynamically concatenated string variable) that you want broadcast to the debug listener. Must evaluate to valid text. |

---

## Return Value

**Return Type**: Numeric (Status Code)

Returns an integer status code indicating the success of the broadcast.
- **`0`**: Success. The diagnostic payload was successfully handed off to the JVM and broadcast.
- **`< 0`**: Failure. The JVM could not reach the listener port, the network was blocked, or the string was invalid.
- **Storage**: Must be assigned to a variable (e.g., `VAR vSendStatus = @JSendDebug("Payload");`).

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the function during calculation.
2. **Payload Resolution**: It evaluates the parameter, resolving any nested string functions (like `@NAME` or `@CalcMgrIntegerToString`) into a single, flat text string.
3. **Java Handoff**: It suspends the C-thread and passes the string to the JVM via the Java Native Interface (JNI).
4. **Broadcast**: The JVM opens the pre-configured diagnostic socket and pushes the text packet over the network.
5. **Return**: It returns the status code back to Essbase and resumes the calculation.

---

## Syntax Variants & Scenarios

### Variant 1: Broadcasting an Error State

```essbase
/* 
   Sends a critical failure notification if data is missing.
*/
VAR vStatus = @JSendDebug("ERROR: Mandatory assumptions are missing.");
```

---

## Practical Examples

### Example 1: Emitting Entity Names During Failures

**Scenario**: A complex depreciation script relies on an asset having a `"Useful_Life"` greater than zero. If the useful life is zero, the script skips the math. However, the FP&A team needs to know exactly *which* assets were skipped so they can fix the master data. The script uses `@JSendDebug` to broadcast the exact name of the offending asset.

```essbase
FIX("FY25", "Working", @LEVEL0("Fixed_Assets"))
    
    IF("Useful_Life" > 0)
        
        "Depreciation" = "Net_Value" / "Useful_Life";
        
    ELSE
        
        /* 
           1. We hit a zero-life asset. We need to tell the admins.
           We extract the name of the active asset and cast it to a string.
        */
        VAR vAssetName = @NAME(@CURRMBR("Fixed_Assets"));
        
        /* 
           2. We concatenate it into a readable error message.
        */
        VAR vErrorMsg = @HspConcat("SKIPPED (Zero Life): ", vAssetName);
        
        /* 
           3. Broadcast the message to the debug listener.
           (In modern Cloud, this writes to the Job Console).
        */
        VAR vDummy = @JSendDebug(vErrorMsg);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using in SaaS Environments | Expecting Remote Delivery | As stated above, Oracle EPM Cloud blocks custom Java socket broadcasting. If you use this function in the Cloud, it will either silently fail, or Oracle's internal interceptors will simply route it to the standard Job Console log. If you are developing natively in the Cloud, immediately switch to `@CalcMgrLogText` |
| Performance Penalties | Looping the Broadcaster | Network operations are exponentially slower than memory operations. If you put `@JSendDebug` inside a dense block evaluation that calculates 1,000,000 times, you are attempting 1,000,000 network broadcasts. Your script will take hours to run instead of seconds. Only place diagnostic functions inside targeted `IF` statements that capture rare error states |
| Failing to use Variables | `@JSendDebug(Error_Message_Member)` | The parameter must evaluate to an actual string (text in quotes). If you pass an Essbase member name without quotes, or try to pass a numeric account without casting it, the compiler will throw a severe Type Mismatch error |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@JDebug`](./@JDebug.md) | The standard file-based logger. Similar behavior, but historically targeted the local server file system rather than a network listener |
| [`@CalcMgrLogText`](./@CalcMgrLogText.md) | The modern, sanctioned EPM Cloud alternative for all custom script logging and debugging |
| [`@NAME`](./@NAME.md) | The crucial function required to convert structural Member Objects into the text strings demanded by the debugger |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Java Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_jsenddebug.html) *(Note: Specific legacy J-functions may be undocumented or deprecated in the latest SaaS patches).*
