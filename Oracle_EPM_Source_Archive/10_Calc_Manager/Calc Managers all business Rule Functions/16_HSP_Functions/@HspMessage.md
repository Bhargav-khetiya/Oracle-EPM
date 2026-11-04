# @HspMessage

## Overview

`@HspMessage` is a **Hyperion Planning (HSP) custom messaging function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It provides a mechanism for an Essbase calculation script to trigger a custom, localized alert or error message directly back to the Planning user interface (or log it to the Job Console) if specific validation logic fails during the execution of a business rule.

### Why Does This Function Exist—

When users launch Business Rules from a Web Form, Essbase typically runs the calculation silently in the background. If a user enters an impossible scenario (e.g., forecasting a Gross Margin of 150%) and hits "Save", a standard calculation script will mathematically process that 150%, saving bad data to the database.
If an administrator writes validation logic (e.g., `IF("Margin" > 1.0)`), they can prevent the data from saving. But how does the user know *why* their data was rejected— Standard Essbase functions cannot easily send pop-up messages to the Web UI.
`@HspMessage` bridges this gap. It allows the script to intercept the bad data, halt the calculation, and trigger a relational payload that surfaces a predefined, localized error message (stored in the Planning repository) directly back to the end user, explaining exactly what they did wrong.

*Note: In modern EPM Cloud, this function is frequently superseded by Calc Manager's graphical "Return" components and Groovy rules, which offer far richer UI messaging capabilities. However, `@HspMessage` remains a critical legacy tool for purely `.csc` driven architectures.*

### When to Use It

- **Data Validation Guardrails**: Preventing users from saving invalid data (like negative expenses or out-of-bounds percentages) and immediately alerting them why the rule failed.
- **Workflow Halts**: Stopping an approval cycle if a required metric (like "Justification_Code") is missing, and sending a warning to the user.
- **Audit Logging**: Sending custom trace messages to the Job Console for administrators to review during complex overnight batches.

---

## Category

**Planning Extensions / Diagnostics & Auditing / Custom HSP Functions**

---

## Syntax

```essbase
@HspMessage("Message_Key", "Argument_1", "Argument_2", ...)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Message_Key"` | String | ✅ Yes | The explicit text ID of the message string stored in the relational Planning repository (e.g., `"ERR_MARGIN_HIGH"`). Must be in quotes. |
| `"Argument_N"` | String | ❌ No  | Optional variables to inject into the message. If the message in the repository is `"Error on Entity {0}"`, the first Argument you pass replaces `{0}`. |

---

## Return Value

**Return Type**: Numeric (Status Code)

Returns an internal status integer indicating the success of the messaging trigger.
- **Execution Stop**: Depending on how the message is configured in the Planning repository (Warning vs Error), triggering this function may intentionally halt the entire Essbase calculation block.
- **Storage**: The return value is usually caught in a `VAR` variable to satisfy Essbase compilation rules, but the true output is the UI pop-up or log entry, not the number.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the function inside an `IF` block.
2. **Payload Compilation**: It packages the `"Message_Key"` and any arguments into an API request.
3. **Relational Handshake**: It sends the request to the Planning UI tier.
4. **Localization**: Planning looks up `"Message_Key"` in its localization repository. It formats the string (e.g., translating it into French if the user's browser is set to French).
5. **UI Surface**: Planning surfaces the error in the Web Form pop-up dialog box and/or writes it to the Job Console.
6. **Return**: It passes a status code back to Essbase (and potentially halts the thread if the message was flagged as a severe error).

---

## Syntax Variants & Scenarios

### Variant 1: Basic Warning Trigger

```essbase
/* 
   Triggers a predefined warning message indicating a budget deficit.
*/
VAR vMsgStatus = @HspMessage("WARN_BUDGET_DEFICIT");
```

---

## Practical Examples

### Example 1: Web Form Margin Validation

**Scenario**: A user enters `"Total_Revenue"` and `"COGS"` on a Web Form, and clicks a "Calculate Plan" business rule. The rule calculates the Gross Margin percentage. Corporate policy dictates that no product can be forecasted with a margin greater than 80%. If the user violates this, the script must calculate the margin, realize it is invalid, blank it out, and pop up an error message using the active product name as an argument.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* 1. Calculate the initial margin */
    IF("Total_Revenue" > 0)
        "Gross_Margin_Pct" = ("Total_Revenue" - "COGS") / "Total_Revenue";
    ENDIF
    
    /* 2. Execute the Validation Check */
    IF("Gross_Margin_Pct" > 0.80)
        
        /* 
           3. Extract the active Product Name to inject into the error.
        */
        VAR vFailedProduct = @NAME(@CURRMBR("Products"));
        
        /* 
           4. Trigger the UI error message.
           We assume the repository has a message mapped to "ERR_001" 
           that says: "Margin exceeds 80% on Product: {0}".
           We pass the product name as the first argument.
        */
        VAR vUIAlert = @HspMessage("ERR_001", vFailedProduct);
        
        /* 
           5. Blank out the invalid data so it doesn't corrupt the database.
        */
        "Gross_Margin_Pct" = #MISSING;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Raw Text | `@HspMessage("Your margin is too high!")` | The first parameter is a **Message Key**, NOT the actual text of the message. The text must be defined in the Planning relational repository via properties files or UI configurations. If you pass raw text, Planning will not find the key, and it will likely return a blank error box or fail silently. If you want to log raw text dynamically, you MUST use `@CalcMgrLogText` instead |
| Passing Member Objects | `@HspMessage("ERR_001", @CURRMBR("Entity"))` | If you are passing arguments to inject into the message (like `{0}`), those arguments must be text strings. You CANNOT pass a native Essbase Member Object. You must wrap dynamic references in `@NAME` (e.g., `@NAME(@CURRMBR("Entity"))`) to cast them to text before sending them |
| Overusing in Large Loops | Popping up 5,000 errors | If your validation logic is nested inside a `FIX` on 5,000 Level-0 Cost Centers, and all 5,000 of them fail the validation, Essbase will attempt to send 5,000 discrete API calls to the Web UI. This will crash the browser or the server. Ensure validation rules triggered by Web Forms are tightly constrained to the specific data grid the user is currently editing (e.g., using `[Descendants(Current_Entity)]`) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogText`](./@CalcMgrLogText.md) | The modern Java equivalent for generating dynamic error messages. Unlike `@HspMessage`, it allows you to construct raw text strings in the script without relying on predefined relational keys, though it logs to the Job Console rather than popping up in the UI |
| [`@HspGetFileName`](./@HspGetFileName.md) | Often used to extract the script name to pass as an argument into an `HspMessage` |
| [`@NAME`](./@NAME.md) | The mandatory function used to convert Essbase Member Objects into the text strings required for message arguments |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspmessage.html)
