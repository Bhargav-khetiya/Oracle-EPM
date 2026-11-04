# @CalcMgrUppercase

## Overview

`@CalcMgrUppercase` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a universal capitalization tool. It takes a source text string and **converts every single alphabetical character to uppercase**, returning a fully capitalized string.

*(Note: In some EPM documentation, this function may be referred to interchangeably as `@CalcMgrToUpperCase`, but `@CalcMgrUppercase` is the standard syntax implementation).*

### Why Does This Function Exist—

When executing string evaluations in Essbase, comparisons are usually strictly case-sensitive. If an administrator writes a script that says `IF("Description" == "APPROVED")`, but a user typed `"Approved"`, the `IF` statement evaluates to `false` and the script silently skips the logic. 
While you can theoretically use `ignore_case` flags in certain advanced search functions, basic logical operators (`==`) do not support case-insensitivity. 
`@CalcMgrUppercase` serves as a critical data normalization tool. By forcing both the database text and the hardcoded target text into UPPERCASE before running the comparison, you completely eliminate case-sensitivity errors. This ensures that `"APPROVED"`, `"Approved"`, and `"approved"` are all treated identically by the calculation engine.

### When to Use It

- **Data Normalization**: Converting messy, user-entered text (like `"aCtiVe"`) into a pristine, standardized format (`"ACTIVE"`) before saving it to a relational staging table.
- **Robust Logical Comparisons**: Forcing variables into uppercase before checking equality (`IF(Var1 == Var2)`), ensuring user typos don't break the rules.
- **Standardized Export Formatting**: Forcing all employee names into ALL-CAPS before exporting them to an external HR payroll system that demands strict capitalization.

---

## Category

**String / Text Manipulation & Formatting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrUppercase(text)
```
*(Also frequently implemented as `@CalcMgrToUpperCase(text)` depending on the specific EPM patch version. Both route to the same Java method).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string you want to capitalize (e.g., `"Mixed Case"`). |

---

## Return Value

**Return Type**: String

Returns a new string where all alphabetical characters have been converted to uppercase.
- **Numbers and Symbols**: It completely ignores numbers, punctuation, and symbols. They remain perfectly intact. 
- E.g., `"v2.5_Final"` becomes `"V2.5_FINAL"`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Execution**: It executes the native Java `String.toUpperCase()` method.
3. **Locale Evaluation**: It scans the character array, leveraging the default locale dictionary to map lowercase letters (ASCII 97-122) to their uppercase equivalents (ASCII 65-90).
4. **Return**: It returns the fully capitalized string back to Essbase memory.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Normalization

```essbase
/* 
   Assumes user typed "ny_sales" 
   Result: "NY_SALES"
*/
VAR vCleanString = @CalcMgrUppercase("ny_sales");
```

---

## Practical Examples

### Example 1: Case-Insensitive Equality Comparisons

**Scenario**: A business rule relies on a text account called `"Approval_Status"`. Users type into this field manually via a Smart View grid. The script needs to lock the data if the status is approved. Because users type `"Approved"`, `"APPROVED"`, or `"approved"`, the script forces the variable to uppercase before doing the equality check.

```essbase
FIX("FY25", "Working", @LEVEL0("Departments"))
    
    IF(@ISMBR(@LIST("Approval_Status")))
        
        /* 
           1. Extract the text and force it into uppercase.
           No matter how the user typed it, vStatus is now "APPROVED".
        */
        VAR vStatus = @CalcMgrUppercase("Approval_Status");
        
        /* 
           2. Execute the equality check safely.
        */
        IF(vStatus == "APPROVED")
            
            /* Lock the financial data */
            "Lock_Flag" = 1;
            
        ELSEIF(vStatus == "DENIED")
            
            /* Reject */
            "Lock_Flag" = 0;
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Unnecessary Double Usage | Using it on `IF` targets | You only need to uppercase the *variable*. You do not need to write `IF(Uppercase(var) == Uppercase("TARGET"))`. You can just hardcode `"TARGET"` in all caps in your script. That saves CPU cycles during massive data loops |
| Attempting to Evaluate Numbers | `@CalcMgrUppercase(10050)` | This function strictly requires a text string. If you pass a numeric Essbase account value into it, the Java engine will crash because numbers do not have casing. Convert numbers to strings first if you are dealing with mixed alphanumeric data streams |
| Assuming Case-Insensitive Essbase Outlines | `@MEMBER(@CalcMgrUppercase("dept1"))` | While standard Essbase *member names* are natively case-insensitive (asking for `"dept1"` or `"DEPT1"` both work), textual equality operators (`==`) and Java string comparison functions (`IndexOf`, `StartsWith`) are strictly case-sensitive. Use this function specifically when executing string mathematics, not member references |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLowercase`](./@CalcMgrLowercase.md) | The exact counterpart. Converts all alphabetical characters to lowercase |
| [`@CalcMgrEqualsIgnoreCase`](../15_CalcMgr_Utility/@CalcMgrCompare.md) | A theoretical alternative function (if supported in your patch) that evaluates equality without needing to manually run Uppercase on both sides |
| [`@CalcMgrReplaceAll`](./@CalcMgrReplaceAll.md) | Has a built-in `ignore_case` boolean flag, allowing you to bypass manual casing entirely when executing string replacements |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_uppercase.html)
