# @CalcMgrLowercase

## Overview

`@CalcMgrLowercase` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a text string and systematically converts every alphabetical character within it to **lowercase**. 
*(Note: This function is functionally identical to `@CalcMgrToLowerCase`. It exists as a direct alias for administrators who prefer simpler naming conventions).*

### Why Does This Function Exist?

When Essbase calculations interact with external text data—such as user commentary, runtime prompts, or data loaded from third-party HR systems—data consistency is non-existent. A user might type `"Approved"`, `"APPROVED"`, or `"aPpRoVeD"`. 
If a calculation script uses an `IF` statement to check `IF("Status" == "approved")`, it performs a strict, case-sensitive comparison. The script will reject `"Approved"` and `"APPROVED"` because the capitalization does not match perfectly.
`@CalcMgrLowercase` acts as a universal equalizer. By wrapping external text inputs in this function, you forcefully normalize all data down to lowercase *before* executing your `IF` statements. This ensures your conditional logic evaluates the actual meaning of the text, completely immunizing your scripts against user typos and case-sensitive failures.

### When to Use It

- **Input Normalization**: Forcing user-typed runtime prompts (e.g., `{User_Input}`) into lowercase so you can safely validate them against a known list of lowercase keywords.
- **Status Validations**: Comparing text-based approval statuses loaded from Workday or SAP without worrying about how the source system capitalized the words.
- **Smart List Cleansing**: Pre-processing raw text data before passing it to functions like `@CalcMgrIsValidSLMember` (if your Smart List labels are all lowercase).

---

## Category

**String / Text Manipulation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrLowercase(text)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be converted (e.g., `"Final_Version"`). |

---

## Return Value

**Return Type**: String

Returns a completely lowercase version of the input string.
- E.g., `"ApPrOvEd"` returns `"approved"`.
- Non-alphabetical characters (numbers, underscores, spaces) are completely ignored and preserved exactly as they are. (e.g., `"User_123"` becomes `"user_123"`).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Character Iteration**: It executes the native Java `String.toLowerCase()` method, which scans every character in the string's array.
3. **ASCII Shift**: If a character falls within the uppercase ASCII range (A-Z), it mathematically shifts it into the lowercase range (a-z).
4. **Return**: It returns the modified string back to Essbase for immediate use in string macros or comparisons.

---

## Syntax Variants & Scenarios

### Variant 1: Normalizing a User Prompt

```essbase
/* 
   If the user types "YES" or "Yes", it is forced to "yes". 
   The IF statement then evaluates safely.
*/
IF(@CalcMgrLowercase({Continue_Prompt}) == "yes")
    /* Execute Logic */
ENDIF
```

---

## Practical Examples

### Example 1: Case-Insensitive Smart List Mapping

**Scenario**: A company loads project data from a web form. Users type the project status into a text box. The script must read this text, normalize it, and compare it against standard keywords to route the data into the correct numerical Smart List account.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    IF(@ISMBR(@LIST("User_Text_Input")))
        
        /* 
           1. Normalize whatever the user typed into lowercase.
           "Active", "ACTIVE", and "aCtIvE" all become "active".
        */
        VAR vNormalizedText = @CalcMgrLowercase("User_Text_Input");
        
        /* 
           2. Execute safe, lowercase IF logic to map the status.
        */
        IF(vNormalizedText == "active")
            "Project_Status_SmartList" = 1;
        ELSEIF(vNormalizedText == "on hold")
            "Project_Status_SmartList" = 2;
        ELSEIF(vNormalizedText == "completed")
            "Project_Status_SmartList" = 3;
        ELSE
            /* Unrecognized Status */
            "Project_Status_SmartList" = -99;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Unnecessary Usage with Case-Insensitive Functions | Using it before `IndexOf` | Some Calc Manager functions (like `@CalcMgrIndexOf`, `@CalcMgrStartsWith`, `@CalcMgrEndsWith`) have built-in `ignoreCase` boolean parameters. You do not need to use `Lowercase` if you are passing the string into a function that already ignores case natively. Only use it when setting up direct equality checks (`==`) |
| Comparing against Uppercase | `IF(@CalcMgrLowercase(Input) == "YES")` | This is a fundamental logic failure. You just forced the input to be lowercase (e.g., `"yes"`), but you are comparing it against an uppercase string (`"YES"`). The `IF` statement will literally always fail. Always ensure the right side of your equation is completely lowercase |
| Passing Numbers | `@CalcMgrLowercase(12345)` | This function strictly requires a text string. If you pass a raw number or mathematical variable, the Java engine will crash because numbers do not have casing. Convert numbers to strings first if needed |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrToLowerCase`](./@CalcMgrToLowerCase.md) | The exact same function. Literally an alias for `Lowercase` |
| [`@CalcMgrUppercase`](./@CalcMgrUppercase.md) | The exact inverse function. Forces all characters to UPPERCASE |
| [`@CalcMgrCompare`](./@CalcMgrCompare.md) | A string comparison function that features a built-in case-insensitivity parameter, often removing the need for manual normalization |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_lowercase.html)
