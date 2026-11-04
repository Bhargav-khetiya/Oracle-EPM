# @HspCreateCDFSession

## Overview

`@HspCreateCDFSession` is a **Hyperion Planning (HSP) custom function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It acts as an advanced connection utility that establishes a **stateful, authenticated session** between the Essbase calculation engine and the relational Planning repository (the underlying SQL database that powers the Web UI, task lists, and forms).

### Why Does This Function Exist—

Essbase and Planning are technically two separate engines. Essbase handles the multidimensional block math, while Planning handles the relational metadata, user security, and web interfaces. Usually, they communicate seamlessly in the background. However, if a calculation script needs to execute a massive batch of relational updates (for example, dynamically adding 10,000 new combinations via `@HspAddPageCombination` or modifying SQL-based workflow statuses), opening and closing a network connection for every single transaction is cripplingly slow and can crash the environment.
`@HspCreateCDFSession` solves this by explicitly opening a persistent, authenticated channel to the relational repository at the start of the calculation. Subsequent relational commands use this open session to batch process their payloads, drastically improving performance and stability.

### When to Use It

- **Batch Relational Updates**: When using other HSP functions (like `@HspAddPageCombination` or `@HspMbrAssignUID`) thousands of times in a single script, requiring a persistent connection to avoid DOS-ing the server.
- **Workflow Automation**: Modifying Planning Approval statuses dynamically from inside an Essbase allocation rule.
- **Legacy On-Premise Integrations**: Maintaining older scripts that required explicit relational handshakes before executing Java Custom Defined Functions (CDFs).

---

## Category

**Planning Extensions / Relational UI Integration / Custom HSP Functions**

---

## Syntax

```essbase
@HspCreateCDFSession("App_Name", "User_Name", "Password")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"App_Name"` | String | ✅ Yes | The explicit text string name of the target Planning Application (e.g., `"Fins_Plan"`). |
| `"User_Name"` | String | ✅ Yes | The ID of an administrator or service account with sufficient relational privileges (e.g., `"admin"`). |
| `"Password"` | String | ✅ Yes | The password for the specified user account. |

---

## Return Value

**Return Type**: Numeric (Session ID / Status Code)

Returns an internal integer representing the active Session ID, or a status code indicating failure.
- **Positive Integer (e.g., `1044`)**: Success. A secure session was created, and this ID can technically be passed to other functions (though it is usually managed implicitly by the HSP wrapper).
- **`0` or Negative Integer**: Failure. Invalid credentials, invalid application name, or the relational database is offline.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the function at the top of a calculation script.
2. **Payload Generation**: It packages the credentials and application name into an encrypted API request.
3. **Relational Handshake**: It sends the payload to the primary relational Planning repository.
4. **Authentication**: Planning verifies the user. If valid, it provisions a dedicated thread/session for the Essbase transaction.
5. **Session Persistence**: The connection remains "open" for the duration of the Essbase calculation thread, allowing subsequent CDFs to pipe data rapidly without re-authenticating.

---

## Syntax Variants & Scenarios

### Variant 1: Establishing a Global Session

```essbase
/* 
   Opens a session at the very beginning of the script. 
   We write the Session ID to a temporary variable so Essbase executes the math.
*/
VAR vSessionID = @HspCreateCDFSession("FinPlan", "svc_admin", "p@ssword123");
```

---

## Practical Examples

### Example 1: Batch Loading New Combinations Safely

**Scenario**: A workforce allocation script dynamically provisions 500 new Contractor placeholders and assigns them to Cost Centers. The HR director needs all 500 combinations to be instantly available in the UI. If the script runs `@HspAddPageCombination` 500 times without a session, the server overhead will be massive. The script explicitly creates a session first.

```essbase
/* 
   1. Outside of any FIX statement, establish the persistent relational connection. 
   This ensures we only authenticate ONCE.
*/
VAR vSession = @HspCreateCDFSession("Workforce", "admin", "admin123");

/* 
   2. Ensure the connection was successful before proceeding. 
   (Anything > 0 is usually a valid session ID).
*/
IF(vSession > 0)
    
    FIX("FY25", "Working", @LEVEL0("Cost_Centers"))
        
        IF("New_Contractor_Flag" == 1)
            
            /* 
               3. Extract the active Cost Center. 
            */
            VAR vCCStr = @NAME(@CURRMBR("Cost_Center"));
            
            /* 
               4. Run the relational combination update. 
               Because the session is open, this executes almost instantly 
               for all 500 blocks.
            */
            VAR vUIStatus = @HspAddPageCombination("Contractor_Form", vCCStr, "TBD_Contractor");
            
            /* Clear the flag */
            "New_Contractor_Flag" = 0;
            
        ENDIF
        
    ENDFIX
    
ENDIF
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Putting the Session in a FIX | Creating 1,000 sessions | If you put `VAR vSession = @HspCreateCDFSession(...)` INSIDE a `FIX` block targeting 1,000 members, Essbase will literally try to authenticate and open 1,000 simultaneous network connections to the relational database. This will crash the server. Always declare sessions at the absolute top of the script, outside of any `FIX` statements |
| Hardcoding Passwords in Cloud | Security Compliance | In On-Premise environments, this was common practice. In modern EPM Cloud, hardcoding passwords in a Calc Script is a massive security violation and often blocked by Cloud architecture. In Cloud, it is vastly preferable to use REST APIs or EPM Automate for relational updates, or to rely on implicit/tokenized connections. Use this function with extreme caution in SaaS |
| Forgetting to Verify the Session | Assuming it worked | If the password expires or the App Name is misspelled, the function returns `0`. If your script proceeds to fire 5,000 relational updates using a dead session, it will flood the Job Console with errors and fail. Always wrap your relational logic in an `IF(vSession > 0)` check |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspAddPageCombination`](./@HspAddPageCombination.md) | The primary function that benefits from having a persistent session established, allowing it to rapidly push form combination updates to the UI |
| [`@HspSystemFunctions`](@HspMessage.md) | The broader suite of internal Hyperion Planning Java functions that require relational connectivity to execute properly |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspcreatecdfsession.html)
