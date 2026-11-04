# @CalcMgrIsValidMember

## Overview

`@CalcMgrIsValidMember` is a **custom Calc Manager database validation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a dynamic text string (e.g., `"FY24"` or `"Dept_100"`) and securely queries the underlying Essbase outline to verify if that exact string **exists as a valid, physical member** in the dimension hierarchy, returning a Boolean (`true` or `false`).

### Why Does This Function Exist—

When building highly dynamic calculation scripts, administrators frequently construct target member names using string concatenation macros. For example, a script might take the current year (`"FY24"`), extract the `"24"`, add `1`, and concatenate `"FY25"`. The script then attempts to copy data into `@MEMBER("FY25")`.
However, if the database outline has not been updated yet, and `"FY25"` doesn't actually exist in the Year dimension, the `@MEMBER` macro will instantly trigger an "Invalid Member Name" exception, immediately aborting the entire calculation script and failing the job.
`@CalcMgrIsValidMember` prevents this catastrophic failure. It acts as a shield, pinging the outline metadata registry with the constructed string *before* you ever attempt to write data to it. If it returns `false`, your script can gracefully skip the block or log a controlled error message, ensuring the job finishes safely.

### When to Use It

- **Dynamic Cross-Dimensional Macros**: Validating concatenated string outputs (e.g., `Employee_` + `12345`) before passing them to `@MEMBER()`.
- **User Prompt Validation**: Checking if the text a user typed into a runtime prompt or a Smart View Text Cell actually maps to a real department or product in the system.
- **Exception Logging**: Gracefully catching invalid data mappings and logging them to an error cube instead of crashing the process.

---

## Category

**String / Metadata Validation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrIsValidMember(member_name_string)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member_name_string` | String | ✅ Yes | The exact text string representing the potential member name (e.g., `"New_York"` or `"FY24"`). |

---

## Return Value

**Return Type**: Boolean (`true` or `false`)

Returns `true` (evaluates to `1` in Essbase IF statements) if the string matches an active member in the outline.
Returns `false` (`0`) if the member does not exist.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Metadata Query**: It queries the active Essbase Outline Registry (the central memory map of all dimension members).
3. **Execution**: It executes a fast lookup check. It does not load any data blocks; it only checks the structural metadata.
4. **Return**: Passes the resulting Boolean back to the calculation script.

---

## Syntax Variants & Scenarios

### Variant 1: Validating a User Prompt

```essbase
/* Checks if the string provided in the prompt actually exists in the database */
IF(@CalcMgrIsValidMember({Target_Department}))
    /* Proceed with calculation */
ENDIF
```

---

## Practical Examples

### Example 1: Safe Dynamic Forecasting (Avoiding Crashes)

**Scenario**: A forecasting script copies data from the current year to the "Next Year". The script calculates the Next Year string dynamically (e.g., `"FY28"`). The administrator is worried that the script will crash on December 31st if IT hasn't added `"FY28"` to the outline yet. They use `IsValidMember` to wrap the copy command in a safety shield.

```essbase
FIX("Working", @LEVEL0("Accounts"))
    
    /* 1. Dynamically calculate the Target Year String (e.g., "FY28") */
    VAR vCurrentYearInt = @CalcMgrGetIntegerFromString(@CalcMgrSubstring({Target_Year}, 2));
    VAR vNextYearInt = vCurrentYearInt + 1;
    VAR vTargetYearStr = @CONCATENATE("FY", @CalcMgrIntegerToString(vNextYearInt));
    
    /* 
       2. Validate the String. 
       Does "FY28" actually exist in the Essbase Outline—
    */
    VAR vIsValid = @CalcMgrIsValidMember(vTargetYearStr);
    
    /* 
       3. Evaluate the result.
    */
    IF(vIsValid)
        
        /* The member exists! It is safe to use @MEMBER() */
        FIX(@MEMBER(vTargetYearStr))
            "Forecast" = 1000;
        ENDFIX
        
    ELSE
        
        /* 
           The member is missing. We gracefully abort the script and alert the user 
           instead of throwing an ugly database exception.
        */
        @RETURN(@CONCATENATE("Error: Target Year is missing from outline: ", vTargetYearStr), ERROR);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not Passing a String | `@CalcMgrIsValidMember(FY24)` | This function strictly requires a **Text String**. If you pass a bare member name without quotes, Essbase will try to evaluate the data inside `FY24` (which resolves to a number, or `#MISSING`) before passing it to the function. The Java engine will crash because it expects a string. You must use quotes: `"FY24"` |
| Alias Evaluation | Passing `"New York"` instead of `"NY_01"` | This function primarily checks the physical **Member Name**, not necessarily all Alias tables. If your outline is built on cryptic IDs (`NY_01`), passing the alias `"New York"` may return `false` depending on exact application configuration. Always validate against the true member name where possible |
| Using as a Data Filter | Checking if data exists | This function checks METADATA (does the member exist in the outline structure—). It does NOT check if data exists in a specific intersection. If you want to know if a member has data, use `@ISMBR` and check if the value `!= #MISSING` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrIsValidSLMember`](./@CalcMgrIsValidSLMember.md) | Specifically checks if a string exists as a valid entry inside a Smart List definition, rather than the dimension outline |
| [`@MEMBER`](../04_Member_Navigation/@MEMBER.md) | The native Essbase macro used to convert the validated string back into an active dimensional pointer |
| [`@ISMBR`](../09_Boolean_Conditional/@ISMBR.md) | Native Essbase function used to check if the current calculation block is actively sitting on a specific member |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_isvalidmember.html)
