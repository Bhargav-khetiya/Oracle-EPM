# @CalcMgrConcat

## Overview

`@CalcMgrConcat` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It concatenates (joins together) two or more text strings into a single continuous text string.

### Why Does This Function Exist?

While Essbase has a native `@CONCATENATE` function, the native version historically had limitations regarding the number of strings it could join at once, and how it handled variables versus hardcoded text within complex Calc Manager GUI loops.
`@CalcMgrConcat` utilizes the underlying Java engine's robust string builder capabilities. It is the backbone of dynamic string generation in modern EPM applications—allowing developers to stitch together prefixes, dynamic attributes, and suffixes to create highly dynamic cross-dimensional target pointers.

### When to Use It

- To dynamically construct target Account or Entity member names based on the current context (e.g., combining `"Rev_"` with the current Product name).
- To build dynamic file paths or URLs for data export routines.
- To combine multiple Text Attributes into a single composite key.
- To assemble logging messages or validation error outputs inside a Business Rule.

---

## Category

**String / Text / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrConcat(text1, text2, [text3...])
```

### Formal Syntax

```
@CalcMgrConcat(stringExpression1, stringExpression2, [stringExpressionN])
```

Where:
- `stringExpression1` — The first text string (the prefix).
- `stringExpression2` — The second text string to append.
- `[stringExpressionN]` — (Optional) Additional strings to append in sequence.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text1` | String | ✅ Yes | The starting string. Must be enclosed in quotes if hardcoded (e.g., `"Opex_"`). |
| `text2` | String | ✅ Yes | The second string. Can be hardcoded or a variable/function output. |
| `textN` | String | ❌ No | Additional strings to append. (Note: Depending on the specific EPM patch level, CalcMgrConcat may be limited to a specific number of arguments, often 2 or 3. If you need 5 strings, you can nest the function). |

---

## Return Value

**Return Type**: String

Returns a single unified text string containing all the input strings joined end-to-end without any added spaces.

---

## How It Works (Behind the Scenes)

1. **String Evaluation**: Essbase evaluates all input arguments to ensure they resolve to text strings. (If you pass a member name pointer, it must be converted to a string using `@NAME` first).
2. **Java StringBuilder**: The underlying engine appends `text2` directly to the end of `text1`, and so forth.
3. **Resolution**: It returns the concatenated string, which can then be wrapped in `@MEMBER` to convert it back into an active outline pointer, or stored in a string variable.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Hardcoded Prefix

```essbase
/* Combines "Exp_" and "Travel" to yield "Exp_Travel" */
VAR vTargetString = @CalcMgrConcat("Exp_", "Travel");
```

### Variant 2: Nesting Functions to Overcome Argument Limits

```essbase
/* If the system limits the function to 2 arguments, nest them to join 3 strings */
/* Yields "Exp_Travel_Actual" */
VAR vTargetString = @CalcMgrConcat(@CalcMgrConcat("Exp_", "Travel"), "_Actual");
```

---

## Practical Examples

### Example 1: Dynamic Account Targeting (Prefixing)

**Scenario**: You are calculating Revenue. Your cube structure has a base account for Volume, and a base account for Price. The Revenue account is always named `Rev_` followed by the Product line (e.g., `Rev_Smartphones`). You need to write a single generic script that dynamically finds the right Revenue account based on the product currently being calculated.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* 1. Extract the current Product name as a string */
    VAR vProdNameStr = @NAME(@CURRMBR("Product"));
    
    /* 2. Concatenate the "Rev_" prefix with the Product string */
    VAR vTargetAccountStr = @CalcMgrConcat("Rev_", vProdNameStr);
    
    /* 3. Wrap the string in @MEMBER to point data into the target intersection */
    @MEMBER(vTargetAccountStr) = "Volume" * "Price";
    
ENDFIX
```

---

### Example 2: Combining Text Attributes for Mapping

**Scenario**: You need to allocate corporate overhead to specific departments. The mapping is determined by combining two Text Attributes assigned to the Entity: "Region_Code" and "CostCenter_Code". The target account is named `Alloc_[Region]_[CostCenter]`.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Extract the two attributes */
    VAR vRegionStr = @ATTRIBUTESVAL("Region_Code");
    VAR vCostCenterStr = @ATTRIBUTESVAL("CostCenter_Code");
    
    /* Build the target string: "Alloc_" + Region + "_" + CostCenter */
    VAR vStep1 = @CalcMgrConcat("Alloc_", vRegionStr);
    VAR vStep2 = @CalcMgrConcat(vStep1, "_");
    VAR vFinalTarget = @CalcMgrConcat(vStep2, vCostCenterStr);
    
    /* Push the allocation to the dynamically built target */
    @MEMBER(vFinalTarget) = "Corporate_Pool" * "Driver_Pct";
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting `@NAME` | `@CalcMgrConcat("Rev_", @CURRMBR("Product"))` | `@CURRMBR` returns a *member pointer*, not a text string. The concatenation engine will fail. You must use `@NAME(@CURRMBR("Dim"))` to convert the pointer into text first |
| Added Spaces | Assuming the function adds a space between words | `Concat("Hello", "World")` yields `"HelloWorld"`. If you need a space or underscore, you must explicitly provide it: `Concat("Hello", " World")` or use multiple concatenations |
| Using on Numeric Data | `Concat("Year_", 2024)` | The engine expects text strings. Trying to concatenate an integer directly into a string without converting it (using `@CalcMgrDoubleToString`) will cause a validation error |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CONCATENATE`](./@CONCATENATE.md) | The native Essbase equivalent function, often used interchangeably depending on developer preference |
| [`@NAME`](./@NAME.md) | Absolutely essential for converting members into strings so they can be concatenated |
| [`@MEMBER`](./@MEMBER.md) | The function used to convert the finished string back into a usable database pointer |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_concat.html)
