# @HspWritePageCombinations

## Overview

`@HspWritePageCombinations` is a **Hyperion Planning (HSP) custom administrative function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It is an advanced relational utility designed to **dynamically register or modify a massive block of valid Page/Form combinations** in the underlying Planning repository via a direct database injection, bypassing the manual UI setup.

### Why Does This Function Exist?

In massive Planning implementations (like detailed CapEx or Workforce), Data Forms utilize "Page" drop-downs (e.g., selecting `"Employee_105"` from a list). The UI prevents users from selecting invalid combinations to protect performance. 
If a calculation script provisions 10,000 new Employees or Assets simultaneously, using `@HspAddPageCombination` 10,000 times inside a loop is wildly inefficient, even with a persistent session. It requires 10,000 separate API payloads.
`@HspWritePageCombinations` is the batch equivalent. It allows the script to aggregate all 10,000 combinations into a single massive buffer, and write them directly to the relational tables in one massive transaction block. This significantly improves performance when modifying the relational UI during heavy, data-driven automation tasks.

*Note: In modern EPM Cloud, direct relational modifications via calculation scripts are heavily restricted for SaaS stability. This function is largely considered a legacy On-Premise tool. If you are building a new application in Cloud, it is vastly preferable to use REST APIs, Groovy rules, or EPM Automate for batch metadata/combination updates.*

### When to Use It

- **Bulk Provisioning**: Activating thousands of newly generated dimension members (like temporary contractors or generic assets) in Web Forms simultaneously.
- **Smart Push Prep**: Ensuring that combinations created by an Essbase calculation are valid in the relational UI *before* triggering a Data Map or Smart Push to a reporting cube.
- **Legacy Migrations**: Maintaining older scripts that explicitly required batch updates to the `HSP_PAGE_COMBO` relational tables.

---

## Category

**Planning Extensions / Relational UI Integration / Custom HSP Functions**

---

## Syntax

```essbase
@HspWritePageCombinations("Form_Name", [arguments])
```
*(Note: Because this is a batch function, it usually works in tandem with an open session (`@HspCreateCDFSession`) and is often abstracted inside internal macros or requires specific dimensional arrays depending on the environment patch).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Form_Name"` | String | ✅ Yes | The explicit text string name of the Planning Web Form (e.g., `"Asset_Entry_Form"`). Must be in quotes. |
| `arguments` | Arrays | ❌ No  | A comma-separated list of member arrays representing the intersections to write, though this is heavily dependent on the specific relational patch structure. |

---

## Return Value

**Return Type**: Numeric (Status Code)

Returns a status integer indicating the success of the massive relational update.
- **`1`**: Success. The batch transaction was committed to the Planning repository.
- **`0` or `< 0`**: Failure. The form name is invalid, the array contains members that do not exist, or the relational timeout limit was reached.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the function.
2. **Buffer Generation**: It compiles the massive list of requested dimension intersections.
3. **Relational API Call**: It sends a single, massive XML/JSON payload back to the primary relational Planning repository.
4. **Validation & Insert**: The Planning layer validates that the Form exists and that the dimensional mappings match the Page axes. It then executes a bulk `INSERT` (or merge) statement into the internal relational tables.
5. **Commit & Return**: It commits the database transaction and sends a success code back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Batch Updating a Specific Form

```essbase
/* 
   Initiates a batch update for the specified form.
*/
VAR vStatus = @HspWritePageCombinations("Workforce_Form", "Dept_A", "TBD_Emps");
```

---

## Practical Examples

### Example 1: Integrating with a Session for Safely

**Scenario**: A macro runs every night to detect any newly added Cost Centers. If new Cost Centers exist, they must be made available on the "OpEx_Input" form. Rather than running single-line updates, the administrator relies on a batch update wrapped inside a secure, authenticated relational session.

```essbase
/* 
   1. Outside of any FIX statement, establish the persistent relational connection. 
*/
VAR vSession = @HspCreateCDFSession("FinPlan", "admin", "admin123");

IF(vSession > 0)
    
    FIX("FY25", "Working", @LEVEL0("Cost_Centers"))
        
        /* 
           2. Execute the batch write.
           This tells the relational database to ensure all calculating 
           Cost Centers are flagged as valid on the UI form.
        */
        IF("New_Entity_Flag" == 1)
            
            VAR vStatus = @HspWritePageCombinations("OpEx_Input", @NAME(@CURRMBR("Cost_Centers")));
            
            "New_Entity_Flag" = 0;
            
        ENDIF
        
    ENDFIX
    
    /* 
       3. CRITICAL: Destroy the session to free up server resources.
    */
    VAR vCloseStatus = @HspRemoveCDFSession(vSession);
    
ENDIF
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Page Dimensions | Passing 3 dimensions to a 2-drop form | Just like the singular function, the dimensions you pass MUST perfectly match the dimensions mapped to the Page/POV axis of the specified `"Form_Name"`. If the form only drops down "Entity" and you pass "Entity" and "Product", the relational batch update will fail |
| Ignoring Relational Timeouts | Writing 1,000,000 combinations | While this is a batch function, relational databases (like Oracle DB) still have transaction size limits and query timeouts. If you attempt to update 1 million combinations in a single pass, the network socket might timeout before the database finishes the `INSERT`, crashing the script. Always batch logically |
| Deprecation in the Cloud | Blocked APIs | EPM Cloud strongly discourages direct relational edits from calculation scripts. Depending on your specific Cloud tier (Enterprise vs Standard) and patch level, this function may be entirely disabled for security reasons. Always test relational CDFs in DEV before assuming they will execute in Production |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspAddPageCombination`](./@HspAddPageCombination.md) | The singular, non-batch version of this function, used for updating one specific combination at a time (often safer for small, targeted logic) |
| [`@HspCreateCDFSession`](./@HspCreateCDFSession.md) | The mandatory session-generation function that provides the authenticated channel required to execute massive relational database edits |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspwritepagecombinations.html)
