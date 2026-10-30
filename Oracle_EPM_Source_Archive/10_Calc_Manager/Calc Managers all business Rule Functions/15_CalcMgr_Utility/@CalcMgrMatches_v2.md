# @CalcMgrMatches

## Overview

`@CalcMgrMatches` is a **custom Calc Manager string validation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an advanced pattern-matching engine. Instead of searching for an exact word, it evaluates a text string against a **Regular Expression (Regex)** pattern, returning a Boolean (`true` or `false`) confirming whether the entire string conforms to that specific structural pattern.

### Why Does This Function Exist?

Standard Essbase string functions can tell you if a string *contains* a word (`@CalcMgrIndexOf`), or if it starts with a word (`@CalcMgrStartsWith`). But they cannot validate structural formats. 
How do you verify that a user-entered text string is a valid Social Security Number (3 digits, a dash, 2 digits, a dash, 4 digits)? How do you verify that a string is a valid email address containing an `@` symbol and a `.com` suffix? 
`@CalcMgrMatches` unleashes the full power of the Java Regular Expression engine inside Essbase. By passing a Regex pattern string, you can execute infinitely complex structural validations in a single line of code, guaranteeing that external data conforms to corporate data-governance standards before it is allowed into your allocation scripts.

### When to Use It

- **Format Validation**: Ensuring a text account containing a Phone Number strictly matches the `(XXX) XXX-XXXX` format.
- **Alphanumeric Checking**: Verifying that a product ID string contains exactly two letters followed by exactly four numbers (e.g., `AB1234`).
- **Data Cleansing**: Scanning imported text data for special characters, rejecting any strings that do not conform to a strict `[A-Za-z0-9]` whitelist.

---

## Category

**String / Text Manipulation & Regex / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrMatches(text, regex_pattern)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be evaluated (e.g., `"test@oracle.com"`). |
| `regex_pattern` | String | ✅ Yes | The strict Java Regular Expression pattern you want to enforce (e.g., `".*@.*\\..*"`). |

### Common Regex Pattern Symbols
| Symbol | Meaning | Example Pattern | Result |
|--------|---------|-----------------|--------|
| `\d` (in EPM `\\d`) | Any digit (0-9) | `"\\d\\d\\d"` | Matches `"123"` |
| `\D` (in EPM `\\D`) | Any non-digit character | `"\\D\\D"` | Matches `"AB"` |
| `[a-z]` | Any lowercase letter | `"[a-z]+"` | Matches `"hello"` |
| `^` and `$` | Start and End of string | `"^A.*"` | Matches strings starting with A |
| `.` | Any single character | `".*"` | Matches literally anything |

---

## Return Value

**Return Type**: Boolean (`true` or `false`)

Returns `true` (evaluates to `1` in Essbase IF statements) if the ENTIRE string perfectly satisfies the Regex pattern.
Returns `false` (`0`) if it violates the pattern.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string and the Regex pattern string.
2. **Regex Compilation**: It compiles the pattern using `java.util.regex.Pattern`.
3. **Execution**: It executes the `Matcher.matches()` method. 
   - **CRITICAL**: Unlike standard regex searches, `Matcher.matches()` requires the pattern to match the *entire* string from start to finish, not just a substring within it.
4. **Return**: Passes the Boolean result back to the Essbase calculation script.

---

## Syntax Variants & Scenarios

### Variant 1: Validating a Zip Code (5 Digits)

```essbase
/* 
   The pattern "\\d{5}" means exactly 5 digits in a row. 
   "12345" will return true. "1234A" will return false.
*/
VAR vIsValidZip = @CalcMgrMatches("User_Zip_Code", "\\d{5}");
```

---

## Practical Examples

### Example 1: Validating Corporate Email Formats

**Scenario**: A planning application captures new employee requests. The HR manager enters the requested email address into a text cell. Before the script processes the request, it must validate that the text string looks like a real email address (contains characters, an `@` symbol, a domain, a dot, and an extension).

```essbase
FIX("FY25", "Working", "No_Entity")
    
    IF(@ISMBR(@LIST("Requested_Email")))
        
        /* 
           1. Define the Regex Pattern for a standard Email.
           ^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$
           (Note: In Calc Manager, backslashes must be escaped with another backslash).
        */
        VAR vEmailRegex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";
        
        /* 
           2. Evaluate the text against the pattern.
        */
        VAR vIsValidEmail = @CalcMgrMatches("Requested_Email", vEmailRegex);
        
        /* 
           3. Validate and route.
        */
        IF(vIsValidEmail)
            "Request_Status" = 1; /* Approved for Processing */
        ELSE
            "Request_Status" = -99; /* Rejected: Invalid Format */
            @RETURN("Error: The requested email address has an invalid format.", ERROR);
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Substring Matching vs Full Matching | Expecting `"abc"` to match `"b"` | `Matches` requires the pattern to validate the **entire string** from end to end. If your text is `"Data_123_Error"`, and your regex is `"\\d{3}"` (looking for 3 numbers), it will return `false`. Why? Because the pattern doesn't account for the letters at the beginning and end. To find a substring via regex, you must wrap it in wildcards: `".*\\d{3}.*"` |
| Forgetting to Double Escape | Using `\d` instead of `\\d` | When writing Regex inside an Essbase string (inside double quotes), a single backslash is interpreted by Essbase as an escape character. To pass a literal backslash to the Java regex engine, you MUST use two backslashes (`"\\d"`). Failing to double-escape will crash the script during compilation |
| Unnecessary Complexity | Using Regex for exact word matches | Regex is computationally heavy. If you just want to know if a string equals exactly `"Approved"`, do not use `Matches("Text", "^Approved$")`. Just use a standard `IF("Text" == "Approved")`. Save `Matches` for complex structural validations (like emails, phone numbers, or dynamic IDs) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCompare`](./@CalcMgrCompare.md) | Standard string comparison. Faster than Regex if you just need to check if two strings are identical |
| [`@CalcMgrIndexOf`](../10_String/@CalcMgrIndexOf.md) | Scans a string for an exact substring. Faster than Regex if you just need to know if a specific word exists within a larger block of text |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_matches.html)
