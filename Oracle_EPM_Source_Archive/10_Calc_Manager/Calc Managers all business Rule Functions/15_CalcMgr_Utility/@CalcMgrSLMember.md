# @CalcMgrSLMember

## Overview

`@CalcMgrSLMember` is a **custom Calc Manager Smart List resolution function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a two-way translator between human-readable text labels and Essbase backend integers. It takes the name of a Smart List and a specific value, queries the relational EPM dictionary, and returns the corresponding translated value (either converting text to an integer, or an integer to text).

### Why Does This Function Exist?

Smart Lists in EPM operate in two distinct domains. To an end-user on a web form, a Smart List looks like a text dropdown menu containing words like `"Active"`, `"Hold"`, or `"Closed"`. To the Essbase calculation engine, these words do not exist; they are stored natively in the database as numerical integers (`1`, `2`, `3`). 
When writing calculation scripts, administrators often need to dynamically evaluate Smart List values. If a runtime prompt passes the text string `"Active"` into the script, you cannot write `IF("Status" == "Active")` because `"Status"` is storing the number `1`. 
`@CalcMgrSLMember` bridges this gap. It queries the metadata dictionary and performs the translation on the fly. You can hand it the word `"Active"`, and it will return `1`, allowing your Essbase script to perform strict numerical comparisons effortlessly. Conversely, it can also translate integers back into text for generating dynamic log messages.

### When to Use It

- **Runtime Prompt Translation**: Translating a text-based Smart List prompt selected by a user into the underlying integer so it can be evaluated in an `IF` statement.
- **Dynamic Cross-Dimensional Lookups**: Using the text label of a Smart List (e.g., `"Dept_101"`) to dynamically generate an `@MEMBER("Dept_101")` reference.
- **Audit Logging**: Translating raw database integers (like `2`) back into human-readable text (`"On Hold"`) before printing them to the Job Console or writing them to a Text Account.

---

## Category

**String / Smart Lists & Metadata / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrSLMember(smart_list_name, string_or_integer)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `smart_list_name` | String | ✅ Yes | The exact name of the Smart List definition in the EPM dictionary (e.g., `"SL_Project_Status"`). |
| `string_or_integer` | Variant | ✅ Yes | The value you want to translate. <br>- **Text String**: (e.g., `"Active"`) Returns the underlying integer. <br>- **Integer**: (e.g., `1`) Returns the human-readable text label. |

---

## Return Value

**Return Type**: Variant (Numeric or String)

The return type completely depends on what you passed in:
- **String to Integer**: If you pass `"Active"`, it returns the Number `1`. (Can be used in math or `IF` statements).
- **Integer to String**: If you pass the Number `1`, it returns the String `"Active"`. (Must be assigned to a Text Account or string macro).
- **Failure**: If the value does not exist in the Smart List, it returns `#MISSING` (or a null string), which can crash downstream concatenation macros. Always validate first.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Smart List name and the target payload.
2. **Type Detection**: It analyzes the payload. Is it a string or a number?
3. **Dictionary Query**: It queries the centralized EPM relational metadata repository (where Smart Lists are defined).
4. **Translation**: 
   - If payload is a string, it searches the Labels column and extracts the corresponding ID.
   - If payload is a number, it searches the ID column and extracts the corresponding Label.
5. **Return**: Passes the translated value back to the calculation script.

---

## Syntax Variants & Scenarios

### Variant 1: Translating Text to Integer

```essbase
/* 
   Translates the word "Closed" into its numerical ID (e.g., 3).
*/
VAR vStatusInt = @CalcMgrSLMember("SL_Status", "Closed");
```

---

## Practical Examples

### Example 1: Resolving a Runtime Prompt for Execution

**Scenario**: A web form contains a Smart List runtime prompt (`{Target_Status}`). The user selects `"Active"` from the dropdown. However, EPM passes the literal string `"Active"` into the script. The script needs to clear all projects that match this status. The administrator must translate `"Active"` into its numerical ID before looping through the database.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    /* 
       1. Translate the user's Text Prompt into the backend Integer ID.
       If the prompt is "Active", vTargetStatusID becomes 1.
    */
    VAR vTargetStatusID = @CalcMgrSLMember("SL_Proj_Status", {Target_Status});
    
    /* 
       2. Compare the database integer against the translated integer.
    */
    IF("Project_Status" == vTargetStatusID)
        
        /* 3. If they match, clear the financial data */
        "Total_Expenses" = #MISSING;
        
    ENDIF
    
ENDFIX
```

### Example 2: Generating Readable Audit Logs

**Scenario**: An allocation script encounters an error on a specific project. The script logs the error, but logging `Project Status was: 2` is not helpful to the CFO. The script uses this function to reverse-translate the `2` into `"On Hold"` before logging it.

```essbase
FIX("Working", "Project_X")
    
    IF("Expenses" < 0)
        
        /* 1. Extract the raw integer from the database (e.g., 2) */
        VAR vRawInt = "Project_Status";
        
        /* 2. Reverse-Translate the integer back into a Text Label */
        VAR vLabelText = @CalcMgrSLMember("SL_Proj_Status", vRawInt);
        
        /* 3. Log the readable error message */
        VAR vLog = @CalcMgrLogMemberStrings("Error on Project X. Status is currently: ", vLabelText);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not Validating Text Strings | `@CalcMgrSLMember("SL", "Acive")` | If a user types a typo (e.g., `"Acive"` instead of `"Active"`), this function will fail to find a translation and will return a null object, which usually crashes subsequent IF statements. If you are accepting raw text inputs, you should ALWAYS wrap them in `@CalcMgrIsValidSLMember` first before attempting to translate them |
| Case Sensitivity | Passing `"active"` instead of `"Active"` | Smart List labels are strictly case-sensitive. If you pass lowercase `"active"`, the dictionary query will fail. Use `@CalcMgrLowercase` on both ends if you are dealing with messy data |
| Saving Labels to Numeric Accounts | `"Status" = @CalcMgrSLMember("SL", 1)` | If you pass an integer, the function returns a **Text String** (e.g., `"Active"`). You cannot save the word `"Active"` directly into standard Essbase numeric accounts. You must save it to a Text Account |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrIsValidSLMember`](./@CalcMgrIsValidSLMember.md) | Specifically checks if a text string exists in the Smart List dictionary BEFORE you attempt to translate it |
| [`@CalcMgrIsValidMember`](./@CalcMgrIsValidMember.md) | Used if your translated label is meant to be used as a physical outline member (e.g., a Department name) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_slmember.html)
