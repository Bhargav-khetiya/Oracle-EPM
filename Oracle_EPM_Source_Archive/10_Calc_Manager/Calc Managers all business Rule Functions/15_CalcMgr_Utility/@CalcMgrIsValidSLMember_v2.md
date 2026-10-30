# @CalcMgrIsValidSLMember

## Overview

`@CalcMgrIsValidSLMember` is a **custom Calc Manager Smart List validation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes the name of a specific Smart List and a dynamic text string, and queries the database to verify if that exact string **exists as a valid entry/label** inside that Smart List, returning a Boolean (`true` or `false`).

### Why Does This Function Exist?

Smart Lists in EPM act as dropdown menus on web forms, mapping human-readable text labels (like `"Approved"` or `"New York"`) to underlying Essbase integers (like `1` or `2`). 
When users load data via flat files or REST API integrations, they often bypass web forms and load text strings directly into Smart List-enabled text accounts. If a user loads `"Apprved"` (a typo) into a Smart List account, the system might accept the string, but any downstream calculation logic relying on the integer mapping (e.g., `IF(Status == 1)`) will completely fail.
`@CalcMgrIsValidSLMember` acts as an automated data-cleansing gateway. Before running massive calculations, the script can check the user's text string against the defined Smart List dictionary. If the text does not perfectly match a valid dropdown label, the script can dynamically flag the cell as an error, ensuring absolute data integrity across your operational models.

### When to Use It

- **Data Integration Cleansing**: Validating flat-file text inputs loaded into Smart List accounts before executing financial allocations.
- **Status Workflow Validations**: Ensuring a project status string is mathematically valid before triggering the capitalization logic.
- **Exception Logging**: Generating automated email alerts when external source systems send unrecognized text strings into critical dropdown fields.

---

## Category

**String / Smart Lists & Metadata / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrIsValidSLMember(smart_list_name, string_to_validate)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `smart_list_name` | String | ✅ Yes | The exact name of the Smart List definition in the EPM dictionary (e.g., `"SL_Project_Status"`). |
| `string_to_validate` | String | ✅ Yes | The text string you want to check against the dropdown labels (e.g., `"Active"`). |

---

## Return Value

**Return Type**: Boolean (`true` or `false`)

Returns `true` (evaluates to `1` in Essbase IF statements) if the string matches an active label within the Smart List.
Returns `false` (`0`) if the string does not exist in that specific Smart List.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Smart List name and the target string.
2. **Dictionary Query**: It queries the centralized EPM relational metadata repository (where Smart Lists are defined).
3. **Execution**: It scans the labels associated with the requested Smart List name. It performs a case-sensitive check to see if the target string exists as an active label.
4. **Return**: Passes the resulting Boolean back to the calculation script.

---

## Syntax Variants & Scenarios

### Variant 1: Validating a String Variable

```essbase
/* Checks if the text "Approved" is a valid label in the "SL_Approval" dropdown */
VAR vIsValid = @CalcMgrIsValidSLMember("SL_Approval", "Approved");
```

---

## Practical Examples

### Example 1: Flat File Validation Gatekeeper

**Scenario**: A company loads employee termination statuses from Workday into a Text Account called `"Raw_Status"`. The calculation script relies on a Smart List called `"SL_Emp_Status"` (Valid Options: `"Active"`, `"Terminated"`, `"On Leave"`). Sometimes the HR system sends `"Term"`. The script must validate the text string. If it is valid, it copies it to the official calculation account. If invalid, it throws an error flag.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    /* Ensure the text account actually has data */
    IF(@ISMBR(@LIST("Raw_Status")))
        
        /* 
           1. Check if the text string exists in the Smart List dictionary.
        */
        VAR vIsValid = @CalcMgrIsValidSLMember("SL_Emp_Status", "Raw_Status");
        
        /* 
           2. Evaluate the result.
        */
        IF(vIsValid)
            
            /* The text is perfect. We can safely map it to the active integer account. */
            /* (Assume a macro handles the string-to-integer Smart List mapping) */
            "Official_Status" = "Raw_Status";
            "Error_Flag" = 0;
            
        ELSE
            
            /* The text is corrupted or contains a typo (e.g., "Term"). Flag it. */
            "Official_Status" = #MISSING;
            "Error_Flag" = 1;
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Checking Integers | `@CalcMgrIsValidSLMember("SL_Status", "1")` | This function checks the textual **Labels** in the Smart List dictionary (e.g., `"Active"`), NOT the underlying integer IDs (`1`). If you ask if `"1"` is a valid member of the Smart List, it will return `false` (unless you literally created a dropdown label called `"1"`) |
| Case Sensitivity | Passing `"active"` instead of `"Active"` | Smart List labels are case-sensitive. If the administrator defined the dropdown label as `"Active"`, passing `"active"` will fail the validation. If your source data is messy, you must use string manipulation functions like `@CalcMgrToLowerCase` on both the dictionary and the input string to normalize them |
| Typos in Smart List Name | Passing `"SL_Status "` | The first parameter must exactly match the internal name of the Smart List as defined in the EPM Planning interface. Extra spaces or typos will cause the Java engine to throw a "Smart List not found" error, crashing the script |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrIsValidMember`](./@CalcMgrIsValidMember.md) | Specifically checks if a string exists as a member in the actual dimension hierarchy, rather than inside a Smart List dropdown definition |
| [`@CalcMgrStartsWith`](../10_String/@CalcMgrStartsWith.md) | Can be used as a manual fallback to check if a dirty string like `"Terminated_User"` starts with the valid keyword `"Term"` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_isvalidslmember.html)
