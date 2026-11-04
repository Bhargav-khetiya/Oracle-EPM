# @CalcMgrCompare

## Overview

`@CalcMgrCompare` is a **custom Calc Manager string comparison function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates two text strings and determines whether they are exactly identical (case-sensitive) or different. It returns a boolean equivalent (`True` or `False`).

### Why Does This Function Exist—

In classic Essbase Calc Scripts (prior to Calc Manager custom functions), comparing text strings dynamically was extremely difficult. You could compare member names (using `@ISMBR`), but comparing raw text strings (e.g., evaluating if a Smart List text value equaled a specific hardcoded string) often required convoluted workarounds using numeric mappings or external macros.
`@CalcMgrCompare` brings native, standard Java-style string comparison into Calc Scripts. It allows you to directly evaluate if String A matches String B, which is critical when processing text attributes, User-Defined Attributes (UDAs), or string-based Smart Lists.

### When to Use It

- To compare a dynamically retrieved text attribute (via `@ATTRIBUTESVAL`) against a hardcoded string.
- To validate string inputs in custom Calc Manager business rules.
- When executing conditional branching logic based on text parameters passed into a Business Rule by a user.
- To compare two different text attributes against each other to see if they align (e.g., comparing "Billing_Region" to "Shipping_Region").

---

## Category

**String / Text / Logical Comparison**

---

## Syntax

```essbase
@CalcMgrCompare(text1, text2, [ignoreCase])
```

### Formal Syntax

```
@CalcMgrCompare(stringExpression1, stringExpression2, [ignoreCaseFlag])
```

Where:
- `stringExpression1` — The first text string or text variable to evaluate.
- `stringExpression2` — The second text string or text variable to evaluate against.
- `[ignoreCaseFlag]` — (Optional in some environments, but best practice to explicitly state) A boolean flag indicating whether the comparison should ignore capitalization. Usually passed as `true` or `false` (without quotes).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text1` | String | ✅ Yes | The first string. Must be enclosed in quotes if hardcoded (e.g., `"New York"`), or passed as a string variable. |
| `text2` | String | ✅ Yes | The second string to compare. |
| `ignoreCase`| Boolean| ❌ No | `true` (ignore case, e.g., "apple" == "APPLE") or `false` (strict case matching, "apple" != "APPLE"). If omitted, it generally defaults to `false` (case-sensitive). |

---

## Return Value

**Return Type**: Boolean (Logical)

Returns `True` if the strings match according to the case sensitivity rule. Returns `False` if the strings do not match.
*(Note: Because Calc Scripts natively operate on numbers, this true/false evaluation is usually consumed directly inside an `IF` statement).*

---

## How It Works (Behind the Scenes)

1. **String Evaluation**: Essbase passes the two text inputs into the underlying Java engine.
2. **Case Logic**: If `ignoreCase` is set to `true`, the Java engine temporarily converts both strings to lowercase (`.toLowerCase()`) before evaluating them.
3. **Character Match**: The engine compares the strings character by character.
4. **Resolution**: It returns the boolean result to the Calc Script for logical branching.

---

## Syntax Variants & Scenarios

### Variant 1: Strict Case-Sensitive Comparison

```essbase
/* Will return FALSE because 'Active' != 'active' */
IF(@CalcMgrCompare("Active", "active", false))
    /* Code does not execute */
ENDIF
```

### Variant 2: Case-Insensitive Comparison

```essbase
/* Will return TRUE because we are ignoring case */
IF(@CalcMgrCompare("Active", "active", true))
    /* Code executes */
ENDIF
```

---

## Practical Examples

### Example 1: Routing Logic Based on Text Attributes

**Scenario**: You have a Text Attribute dimension called "State_Code". You want to apply a specific state tax rate only if the entity is located in Texas ("TX"). Because users might have entered "tx", "Tx", or "TX" into the system, you need a case-insensitive check.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 1. Extract the text string from the attribute */
    VAR vStateStr = @ATTRIBUTESVAL("State_Code");
    
    /* 2. Compare the extracted string to our target string, ignoring case */
    IF(@CalcMgrCompare(vStateStr, "TX", true))
        
        "State_Tax_Provision" = "PreTax_Income" * 0.05;
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Comparing Two Dynamic Attributes

**Scenario**: A product has two attributes: "Designed_In" (e.g., "USA") and "Manufactured_In" (e.g., "China"). You want to apply an import tariff only if the product is designed and manufactured in different countries. You must compare the two strings dynamically.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    VAR vDesignStr = @ATTRIBUTESVAL("Designed_In");
    VAR vMfgStr = @ATTRIBUTESVAL("Manufactured_In");
    
    /* We use NOT to check if they are DIFFERENT */
    IF(NOT @CalcMgrCompare(vDesignStr, vMfgStr, true))
        
        /* The strings don't match, meaning it was offshored. Apply tariff. */
        "Import_Tariff" = "Manufacturing_Cost" * 0.15;
        
    ENDIF
    
ENDFIX
```

---

### Example 3: Validating Runtime Prompts (RTPs)

**Scenario**: A user launches a business rule and selects a Scenario from a drop-down prompt (`{RTP_Scenario}`). You want to execute a specific block of code only if they selected "Forecast".

```essbase
/* Assuming the RTP returns the member name as a string */
IF(@CalcMgrCompare({RTP_Scenario}, "Forecast", true))
    
    FIX("Forecast", "Working", @LEVEL0("Entity"))
        /* Execute forecast seeding */
        "Data" = "Actual" -> "Prior_Year" * 1.05;
    ENDFIX
    
ENDIF
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `==` for strings | `IF(vStateStr == "TX")` | In older Essbase versions, standard `==` does not work reliably for raw string variables. Always use `@CalcMgrCompare` for safe text evaluation |
| Forgetting Quotes | `@CalcMgrCompare(TX, "TX", true)` | The first parameter `TX` will be evaluated as an empty variable or an error. Hardcoded strings must be enclosed in double quotes |
| Leading/Trailing Spaces | `" Texas"` will not match `"Texas"` even if case is ignored | `@CalcMgrCompare` does not trim whitespace. If your data has messy spaces, you must clean it up in the metadata or use a substring/trim function before comparing |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ATTRIBUTESVAL`](./@ATTRIBUTESVAL.md) | Commonly used to generate the strings fed into `@CalcMgrCompare` |
| [`@CalcMgrStartsWith`](./@CalcMgrStartsWith.md) | Checks if a string begins with specific text (e.g., "TX_Austin" starts with "TX") |
| [`@CalcMgrEndsWith`](./@CalcMgrEndsWith.md) | Checks if a string ends with specific text |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_compare.html)
