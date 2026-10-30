# @HspAddPageCombination

## Overview

`@HspAddPageCombination` is a **Hyperion Planning (HSP) custom function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It is an advanced administrative function used to **dynamically register a specific intersection of members as a valid Page/Form combination** within the Planning relational database, bypassing the standard user interface setup.

### Why Does This Function Exist?

In massive Planning applications (like Workforce or Capital), web forms are often designed using "Page" dropdowns to filter data (e.g., picking a specific Employee or Asset from a dropdown list). To maintain performance, Planning only allows users to select combinations that are considered "valid."
If an administrator loads 500 new temporary employees via an Essbase calculation script (e.g., dynamically generating `Emp_9001`, `Emp_9002`), those employees exist in Essbase, but the relational Planning tier does not know they should be visible in the Data Form dropdowns for the `"Contractors"` department. 
Historically, an admin would have to run a separate relational utility to refresh the combinations. `@HspAddPageCombination` allows the Essbase calculation script to communicate *directly* with the relational Planning repository, instantly activating those new combinations in the UI in real-time as the script runs.

### When to Use It

- **Dynamic Member Generation**: Instantly activating new Employees, Assets, or Projects in Data Forms immediately after creating them via an Essbase rule.
- **Smart Push Synchronizations**: Guaranteeing that newly allocated combinations in an ASO reporting cube are immediately accessible via the relational UI without a manual refresh.
- **Automated Provisioning**: Programmatically assigning newly acquired entities to specific reporting forms based on calculation triggers.

---

## Category

**Planning Extensions / Relational UI Integration / Custom HSP Functions**

---

## Syntax

```essbase
@HspAddPageCombination("Form_Name", "Member_1", "Member_2", ...)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Form_Name"` | String | ✅ Yes | The exact text string name of the Planning Web Form (e.g., `"Workforce_Entry"`). Must be enclosed in quotes. |
| `"Member_N"` | String | ✅ Yes | A comma-separated list of member names representing the exact intersection you want to make visible. These must map to the dimensions present on the Page axis of the specified form. |

---

## Return Value

**Return Type**: Numeric (Status Code)

Returns a status integer indicating the success of the relational update.
- **`1`**: Success. The combination was successfully added to the Planning repository.
- **`0` or `< 0`**: Failure. The form name is invalid, the members do not exist, or the relational connection timed out.
- **Note**: Because Essbase blocks can only store numbers, if you need to trap errors, you must write this result to a dummy metric account.

---

## How It Works (Behind the Scenes)

1. **Trigger**: When the Essbase engine executes this function, it momentarily pauses standard block calculation.
2. **Relational Handshake**: Essbase sends a direct API payload back to the primary relational repository (the Oracle database powering the Web UI).
3. **Validation**: The Planning layer validates that `"Form_Name"` exists and that the provided members exist in the outline.
4. **Insert**: It executes an `INSERT` statement into the internal `HSP_PAGE_COMBO` relational tables.
5. **Return**: It sends a success code (`1`) back to Essbase, and the calculation engine resumes processing data.

---

## Syntax Variants & Scenarios

### Variant 1: Activating a New Asset Combination

```essbase
/* 
   Activates a new combination on the "Asset_Depreciation" form.
*/
VAR vStatus = @HspAddPageCombination("Asset_Depreciation", "New_York", "IT_Hardware", "Asset_0051");
```

---

## Practical Examples

### Example 1: Real-Time Workforce Provisioning

**Scenario**: An HR director uses a "Hire TBD Employee" business rule. The rule locates the next available dummy placeholder (e.g., `"TBD_015"`) and calculates their base salary. However, until that placeholder is added to the valid Page combinations, the HR director cannot view them in the detail form. The script uses `@HspAddPageCombination` to instantly activate the UI.

```essbase
FIX("FY25", "Working", @LEVEL0("Departments"))
    
    /* 
       1. Assuming the script already located the next available TBD 
       member and stored it in a string variable.
    */
    VAR vNewEmpStr = "TBD_015";
    
    /* 
       2. Retrieve the active Department name.
    */
    VAR vDeptStr = @NAME(@CURRMBR("Department"));
    
    /* 
       3. Register the new intersection (Department + Employee) 
       directly into the Planning Web Form repository.
       We capture the output in a variable to avoid writing it to a block.
    */
    VAR vUIUpdateStatus = @HspAddPageCombination("HR_Detailed_Entry", vDeptStr, vNewEmpStr);
    
    /* 
       4. Log the success or failure to the Job Console.
    */
    IF(vUIUpdateStatus == 1)
        VAR vLog = @CalcMgrLogMemberStrings("Success: Activated UI for ", vNewEmpStr);
    ELSE
        VAR vLog = @CalcMgrLogMemberStrings("FAILURE: Could not activate UI for ", vNewEmpStr);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Page Dimensions | Passing 3 members when the form has 2 Page drops | The `Member_N` list MUST perfectly match the dimensions mapped to the Page/POV axis of the specified `"Form_Name"`. If the form only has "Entity" and "Product" on the Page drop-downs, and you pass `("Form", "Entity", "Product", "Year")`, the relational update will crash because it doesn't know where to put "Year" |
| Passing Member Objects | `@HspAddPageCombination("Form", @CURRMBR("Entity"))` | This function strictly requires text strings, because it is sending a text-based SQL payload to a relational database. You CANNOT pass native Essbase Member Objects. You MUST wrap dynamic references in `@NAME`: `@HspAddPageCombination("Form", @NAME(@CURRMBR("Entity")))` |
| Overusing in Large Loops | Using it inside a dense `IF` block | This function initiates a network call to the relational database. If you put it inside a calculation loop that fires 100,000 times, you will execute 100,000 separate network payloads, effectively executing a Denial of Service (DoS) attack on your own EPM environment. Only use this function for targeted, single-event additions |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspCreateCDFSession`](./@HspCreateCDFSession.md) | Another relational extension function used to establish stateful connections between Essbase and the Planning repository |
| [`@CalcMgrLogMemberStrings`](./@CalcMgrLogMemberStrings.md) | Highly recommended companion function to log the success/failure code returned by the relational database |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspaddpagecombination.html)
