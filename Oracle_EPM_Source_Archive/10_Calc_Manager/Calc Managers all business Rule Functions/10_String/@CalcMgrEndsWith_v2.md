# @CalcMgrEndsWith

## Overview

`@CalcMgrEndsWith` is a **custom Calc Manager string evaluation function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a primary text string to determine if it concludes with a specific substring, returning a boolean equivalent (`True` or `False`).

### Why Does This Function Exist—

Standard Essbase syntax is famously rigid regarding text strings. While you can use `@MATCH` or `@LIKE` to search for member names using wildcards (e.g., `"Exp_*"`), those native functions strictly require database member names. You cannot use them to evaluate raw text variables, dynamically extracted Text Attributes, or strings built in memory.
`@CalcMgrEndsWith` provides Java-level string evaluation directly inside the Calc Script. By determining whether a text string ends with a specific suffix (like `"_US"` or `"Inc."`), you can execute highly specific conditional branching logic without relying on complex string manipulation workarounds.
*Note: This specific function is strictly case-sensitive. "Inc." does not equal "inc."*

### When to Use It

- To route calculations differently based on the suffix of a Text Attribute (e.g., applying specific logic if a "Contract_ID" attribute ends in `"-REV"`).
- To execute different logic depending on the suffix of the currently calculating member, by evaluating its name dynamically as a string.
- To validate string inputs in custom Calc Manager business rules before allowing data to be saved.

---

## Category

**String / Text / Logical Comparison / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrEndsWith(textString, searchSuffix)
```

### Formal Syntax

```
@CalcMgrEndsWith(stringExpression, substringExpression)
```

Where:
- `stringExpression` — The main text string or text variable to evaluate.
- `substringExpression` — The specific suffix text you are looking for at the end of the main string.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `textString` | String | ✅ Yes | The primary string to analyze. Can be hardcoded (in quotes) or a variable. |
| `searchSuffix`| String | ✅ Yes | The exact text pattern you are checking for at the end of the primary string. |

---

## Return Value

**Return Type**: Boolean (Logical)

Returns `True` (1) if the primary string ends with the exact suffix provided (case-sensitive).
Returns `False` (0) if the suffix is not found at the absolute end of the string, or if the case does not match.
*(Because Calc Scripts natively operate on math, this true/false evaluation is almost always consumed directly inside an `IF` statement).*

---

## How It Works (Behind the Scenes)

1. **String Evaluation**: Essbase passes the two text inputs into the underlying Java engine.
2. **Java `endsWith()` Method**: The engine executes the standard Java string evaluation. It counts backward from the final character of `textString` to see if the sequence perfectly matches `searchSuffix`.
3. **Resolution**: It returns the boolean result to the Calc Script for logical branching.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Condition

```essbase
/* Will return TRUE */
IF(@CalcMgrEndsWith("Account_Receivable_US", "_US"))
    /* Executes logic */
ENDIF
```

### Variant 2: Case Sensitivity Failure

```essbase
/* Will return FALSE because 'us' does not match '_US' */
IF(@CalcMgrEndsWith("Account_Receivable_US", "_us"))
    /* Will NOT execute */
ENDIF
```

---

## Practical Examples

### Example 1: Routing Logic Based on Suffixes

**Scenario**: You have 5,000 cost centers. 500 of them are "Headquarters" cost centers, which are easily identified because their member name ends in `"_HQ"` (e.g., `"Marketing_HQ"`). You need to allocate corporate rent only to these specific cost centers. You can use `@CalcMgrEndsWith` to dynamically evaluate the current member name during the loop.

```essbase
FIX("FY25", "Working", @LEVEL0("CostCenter"))
    
    /* 1. Extract the current Cost Center name as a string */
    VAR vCostCenterStr = @NAME(@CURRMBR("CostCenter"));
    
    /* 2. Check if the string ends with exactly "_HQ" */
    IF(@CalcMgrEndsWith(vCostCenterStr, "_HQ"))
        
        /* Apply the HQ-specific allocation logic */
        "Rent_Expense" = "Corporate_Rent_Pool" * "Headcount_Pct";
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Validating a User Input Text Attribute

**Scenario**: Users flag certain projects by entering a code into a Text Attribute called `"Approval_Code"`. The system requires all final approval codes to end in the literal string `"-FINAL"`. You want to write a validation script that flags projects where the code exists, but doesn't end in `"-FINAL"`.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    /* Extract the text string from the attribute */
    VAR vCodeStr = @ATTRIBUTESVAL("Approval_Code");
    
    /* If the code is not blank, and it does NOT end with "-FINAL" */
    IF(vCodeStr != "" AND NOT @CalcMgrEndsWith(vCodeStr, "-FINAL"))
        
        /* The user entered a bad code format. Flag it as an error. */
        "Validation_Error_Flag" = 1;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Case Sensitivity | Searching for `".inc"` when the data is `".Inc"` | This function is strictly case-sensitive. If you have messy data where users might use different casing, this function will miss them. You should either force the string to lowercase first, or use a custom Groovy string evaluator if your EPM patch level lacks the `IgnoreCase` variant |
| Leading/Trailing Spaces | `"Data_US "` will not match `"_US"` | If the primary string has a trailing space (often caused by bad metadata loads or sloppy text attribute entries), the function will return `False` because the string technically ends with a space. You must clean the data or trim the string first |
| Forgetting Quotes | `@CalcMgrEndsWith(vString, _US)` | The search suffix must be explicitly defined as a string enclosed in double quotes: `"_US"` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrStartsWith`](./@CalcMgrStartsWith.md) | The direct opposite (checks if a string *begins* with specific text) |
| [`@CalcMgrCompare`](../15_CalcMgr_Utility/@CalcMgrCompare.md) | Checks if two strings are *exactly* identical, rather than just sharing a suffix |
| [`@ATTRIBUTESVAL`](../04_Member_Navigation/@ATTRIBUTESVAL.md) | Commonly used to extract the text string that is fed into the evaluation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_endswith.html)
