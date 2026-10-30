# @CONCATENATE

## Overview

`@CONCATENATE` is a **string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that combines two text strings into a single, continuous string. 

### Why Does This Function Exist?

Essbase Calc Manager requires a way to dynamically construct strings when referencing members, creating custom messages, or parsing naming conventions. Because Essbase uses the `+` operator strictly for mathematical addition (not string appending as in JavaScript or Python), you must use `@CONCATENATE` to join text together.

### When to Use It

- When building dynamic member names to use with `@MEMBER`.
- When appending prefixes (e.g., `"FTE_"`) or suffixes (e.g., `"_Elim"`) to existing member names.
- When generating custom textual output or log messages.

---

## Category

**String / Text Manipulation**

---

## Syntax

```essbase
@CONCATENATE(string1, string2)
```

### Formal Syntax

```
@CONCATENATE("stringExpression1", "stringExpression2")
```

Where:
- `stringExpression1` — The first part of the text.
- `stringExpression2` — The second part of the text appended immediately to the end of the first.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `string1` | String | ✅ Yes | The first text string. Can be a literal (`"FY"`), a variable, or a function returning a string (`@NAME("Entity")`). |
| `string2` | String | ✅ Yes | The second text string to append. |

---

## Return Value

**Return Type**: String

Returns a single string combining both inputs without any spaces (unless spaces are explicitly included in the input strings).

---

## How It Works (Behind the Scenes)

1. **Evaluation**: Essbase evaluates `string1` and `string2` to their final text representations.
2. **Joining**: It appends `string2` directly onto the tail of `string1`.
3. **Chaining**: Because `@CONCATENATE` only accepts exactly two arguments, if you need to join three or more strings, you must nest the functions: `@CONCATENATE(string1, @CONCATENATE(string2, string3))`.

---

## Syntax Variants & Scenarios

### Variant 1: Joining Two Literals

```essbase
@CONCATENATE("FY", "25")
/* Returns "FY25" */
```

### Variant 2: Nesting for Three Strings

```essbase
@CONCATENATE("Proj_", @CONCATENATE("101", "_Active"))
/* Returns "Proj_101_Active" */
```

### Variant 3: Combining with @NAME

```essbase
@CONCATENATE("Cost_", @NAME(@CURRMBR("Entity")))
/* If Entity is "NY", returns "Cost_NY" */
```

---

## Practical Examples

### Example 1: Dynamic Allocation Mapping (Prefixing)

**Scenario**: You have Revenue accounts (e.g., `Rev_Software`). You need to allocate marketing expenses dynamically to an equivalent expense account, which is always prefixed with `Exp_` instead of `Rev_`.

```essbase
FIX("FY25", "Working", @CHILDREN("Products"))
    /* Assuming we are iterating over Revenue accounts */
    FIX(@MATCH("Account", "Rev_*"))
    
        /* 1. Extract the product name by stripping the first 4 chars ("Rev_") */
        VAR vProdName = @SUBSTRING(@NAME(@CURRMBR("Account")), 5);
        
        /* 2. Concatenate the new prefix "Exp_" */
        VAR vTargetAccount = @CONCATENATE("Exp_", vProdName);
        
        /* 3. Push data to the dynamically generated account using @MEMBER */
        @MEMBER(vTargetAccount) = @CURRMBR("Account") * 0.10; /* Allocate 10% */
        
    ENDFIX
ENDFIX
```

---

### Example 2: Dynamic Year-Over-Year Referencing

**Scenario**: You want to calculate growth, but instead of using `@PRIOR`, you want to dynamically build the prior year string based on the current year variable. (Assuming you have logic to convert '25' to '24').

```essbase
/* Assuming vPrevYear holds the string "24" */
VAR vPrevYear = "24";
VAR vPriorYearStr = @CONCATENATE("FY", vPrevYear);

"Growth" = "Actual" - "Actual" -> @MEMBER(vPriorYearStr);
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `+` | `"FY" + "25"` is invalid. The `+` operator is for math only | Always use `@CONCATENATE("FY", "25")` |
| Providing more than 2 arguments | `@CONCATENATE("A", "B", "C")` fails validation | You must nest the function: `@CONCATENATE("A", @CONCATENATE("B", "C"))` |
| Forgetting to convert members | `@CONCATENATE("A_", @CURRMBR("Entity"))` fails because `@CURRMBR` returns a member reference, not a string | Wrap the member reference in `@NAME`: `@CONCATENATE("A_", @NAME(@CURRMBR("Entity")))` |
| Trying to assign a string to a cell | `"Account" = @CONCATENATE(...)` fails because cells hold numbers, not text | You can only use the string inside `@MEMBER` or string functions |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SUBSTRING`](./@SUBSTRING.md) | Extracts pieces of a string before or after concatenating |
| [`@NAME`](./@NAME.md) | Converts a member to a string to be used inside concatenate |
| [`@MEMBER`](./@MEMBER.md) | Converts the final concatenated string back into a usable member reference |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @CONCATENATE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/concatenate.html)
