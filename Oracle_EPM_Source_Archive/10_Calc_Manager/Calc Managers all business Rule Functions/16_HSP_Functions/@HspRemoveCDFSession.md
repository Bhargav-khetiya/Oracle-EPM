# @HspRemoveCDFSession

## Overview

`@HspRemoveCDFSession` is a **Hyperion Planning (HSP) custom administrative function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It acts as the closing handshake for a persistent relational connection. It takes an active **Session ID** (generated previously by `@HspCreateCDFSession`), explicitly terminates the connection to the relational Planning repository, and frees up server memory and networking threads.

### Why Does This Function Exist—

When an Essbase calculation script uses `@HspCreateCDFSession` to open a dedicated, authenticated channel to the relational database (usually to push thousands of Web Form UI combinations or update workflow statuses), that connection reserves dedicated CPU and RAM on the Planning tier. 
If an administrator runs a script that opens a session, does the work, but never explicitly closes the session, that connection becomes a "zombie" or "orphan." The server holds it open, waiting for more data. If this happens repeatedly across multiple calculations, the relational connection pool will max out, completely crashing the Planning UI for all end users.
`@HspRemoveCDFSession` is the mandatory garbage-collection mechanism. It tells the server: "I am done transmitting data. You can securely close this thread and return the resources to the pool."

### When to Use It

- **Cleanup (Mandatory)**: It MUST be used at the absolute end of any script (or macro) that utilizes `@HspCreateCDFSession`.
- **Error Trapping**: Placing this function inside an error-handling routine to ensure the session is destroyed even if the main calculation logic fails halfway through.

---

## Category

**Planning Extensions / Relational UI Integration / Custom HSP Functions**

---

## Syntax

```essbase
@HspRemoveCDFSession(Session_ID)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Session_ID` | Numeric | ✅ Yes | The integer ID of the active session. This must exactly match the integer returned by the `@HspCreateCDFSession` function at the start of the script. |

---

## Return Value

**Return Type**: Numeric (Status Code)

Returns a status integer indicating the success of the termination request.
- **`1`**: Success. The session was located and securely destroyed.
- **`0` or `< 0`**: Failure. The session ID was invalid, already closed, or the relational database could not be reached.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine hits the termination command.
2. **Payload Generation**: It packages the specific `Session_ID` integer into an API request.
3. **Relational Handshake**: It sends the termination request to the Planning UI repository.
4. **Destruction**: The Planning repository identifies the thread associated with that ID, flushes any pending relational buffers, commits the transactions, and drops the connection.
5. **Return**: It sends a success code (`1`) back to Essbase, and the calculation engine finishes the script.

---

## Syntax Variants & Scenarios

### Variant 1: Closing a Standard Session

```essbase
/* 
   Assuming vSession contains a valid Session ID (e.g., 1044).
   Destroys the session and releases the memory.
*/
VAR vStatus = @HspRemoveCDFSession(vSession);
```

---

## Practical Examples

### Example 1: Full Lifecycle Relational Update

**Scenario**: A workforce allocation script dynamically provisions 500 new Contractor placeholders and assigns them to Cost Centers. The script must open a session, execute the 500 relational updates inside a `FIX` block, and then securely close the session at the end of the script to prevent memory leaks.

```essbase
/* 
   1. Establish the persistent relational connection. 
   (e.g., vSession becomes 1055).
*/
VAR vSession = @HspCreateCDFSession("Workforce", "admin", "admin123");

/* 
   2. Validate the session is open before proceeding.
*/
IF(vSession > 0)
    
    FIX("FY25", "Working", @LEVEL0("Cost_Centers"))
        
        IF("New_Contractor_Flag" == 1)
            
            /* 
               3. Execute the relational update. 
               (This uses the open session implicitly on the backend).
            */
            VAR vCCStr = @NAME(@CURRMBR("Cost_Center"));
            VAR vUIStatus = @HspAddPageCombination("Contractor_Form", vCCStr, "TBD_Contractor");
            
            "New_Contractor_Flag" = 0;
            
        ENDIF
        
    ENDFIX
    
    /* 
       4. CRITICAL: The data push is complete. 
       We must destroy the session to free up server resources.
    */
    VAR vCloseStatus = @HspRemoveCDFSession(vSession);
    
    /* 
       5. Log if the closure failed (to alert admins of a potential leak).
    */
    IF(vCloseStatus <= 0)
        VAR vLog = @CalcMgrLogText("WARNING: Could not cleanly terminate Relational Session.");
    ENDIF
    
ENDIF
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Putting the Closure in a FIX | Closing the session prematurely | If you put `@HspRemoveCDFSession(vSession)` *inside* the `FIX` block that is looping through members, Essbase will hit it on the very first member, close the session, and the next 4,999 members will fail their relational updates because the connection is dead. **ALWAYS** place the closure at the absolute bottom of the script, entirely outside of any `FIX` block |
| Forgetting to Close It | Memory leaks | As detailed above, failing to include this function in a script that opens a session is the fastest way to crash a Hyperion Planning server. The connections will pile up until the Java Virtual Machine runs out of memory (OutOfMemoryError) |
| Hardcoded Session IDs | `@HspRemoveCDFSession(1044)` | You must pass the dynamic variable (e.g., `vSession`) that captured the ID when it was created. Session IDs are dynamically generated by the OS at runtime. You cannot hardcode them |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspCreateCDFSession`](./@HspCreateCDFSession.md) | The mandatory precursor function. You cannot remove a session unless you have already created one |
| [`@HspAddPageCombination`](./@HspAddPageCombination.md) | The most common transactional function executed *between* the Create and Remove session commands |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspremovecdfsession.html)
