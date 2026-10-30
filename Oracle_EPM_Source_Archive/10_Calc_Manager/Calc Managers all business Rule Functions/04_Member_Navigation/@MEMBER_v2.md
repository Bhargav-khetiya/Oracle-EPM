# @MEMBER

## Overview

`@MEMBER` is a **string-to-member conversion function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It takes a text string and attempts to resolve it into a valid member reference within the outline.

### Why Does This Function Exist?

Calc scripts often require dynamic cross-referencing. For example, if you are looking at `Entity_101`, and you need to push data to `Project_101`, you have to dynamically construct the string `"Project_101"`. 
However, Essbase cannot mathematically assign a value to a string. `("Project_" + "101") = 500` is invalid syntax.
`@MEMBER` acts as the bridge: it takes the dynamically built string `"Project_101"` and tells Essbase to treat it as a real member in the database.

### When to Use It

- When dynamically constructing target or source members using string manipulation (`@CONCATENATE`, `@SUBSTRING`).
- When converting User-Defined Attributes (UDAs) or Text Attributes into actual member references.
- In cross-dimensional allocations where the target member name is derived from the current context.

---

## Category

**String / Conversion / Member Selection**

---

## Syntax

```essbase
@MEMBER(string)
```

### Formal Syntax

```
@MEMBER("stringExpression")
```

Where:
- `"stringExpression"` — A literal string, a string variable, or a string function that evaluates to a valid member name in the outline.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `string` | String | ✅ Yes | The text string that represents the member name. E.g., `"Actual"`, `@CONCATENATE("FY", "25")`, or a string variable. |

---

## Return Value

**Return Type**: Member Reference

Returns the actual outline member that matches the string. If the string does not match any valid member name or alias in the database, the function fails, which typically causes the calc script to fail during validation or runtime.

---

## How It Works (Behind the Scenes)

1. **String Evaluation**: Essbase first evaluates whatever functions are inside the `@MEMBER` call to produce a final text string (e.g., `"FY25"`).
2. **Outline Lookup**: It searches the database outline for a member or alias matching that exact string.
3. **Reference Conversion**: It swaps the text string for the physical member reference, allowing formulas like `X = Y` to execute properly.
4. **Validation Phase vs Runtime**: If the string is hardcoded or relies on variables resolved at compile-time, it validates instantly. If the string is highly dynamic (e.g., pulling text data from cells at runtime), validation can be tricky, and runtime errors are possible if the generated string doesn't exist.

---

## Syntax Variants & Scenarios

### Variant 1: Resolving a Concatenated String

```essbase
"Allocated_Value" -> @MEMBER(@CONCATENATE("Proj_", "101")) = "Expense";
```

### Variant 2: Using a Variable

```essbase
VAR vYearStr = "FY25";
"Value" -> @MEMBER(vYearStr) = 100;
```

### Variant 3: Double Conversion (Name to String to Member)

```essbase
/* Rarely needed directly, but shows the mechanics */
@MEMBER(@NAME(@CURRMBR("Entity")))
```

---

## Practical Examples

### Example 1: Dynamic Entity-to-Project Cross-Reference

**Scenario**: Entities (e.g., `E_101`) have a 1-to-1 relationship with Projects (e.g., `P_101`). You want to push data from the entity to its corresponding project dynamically without writing a hundred `IF` statements.

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    /* Extract "101" from "E_101" */
    VAR vID = @SUBSTRING(@NAME(@CURRMBR("Entity")), 3);
    
    /* Build "P_101" */
    VAR vProjectStr = @CONCATENATE("P_", vID);
    
    /* Use @MEMBER to turn "P_101" into a target destination */
    "Transfer_Out" -> @MEMBER(vProjectStr) = "Total_Expenses";
ENDFIX
```

---

### Example 2: Using Text Attributes as Targets

**Scenario**: A text attribute "Target_Cost_Center" is stored against products. You want to push product revenue to the specific cost center named in that attribute.

```essbase
/* Warning: Reading text values from cells requires specific CalcMgr functions, 
   but conceptually: */
FIX("FY25", "Working", @CHILDREN("Products"))
    /* Assume vTargetCC string is retrieved successfully, e.g., "CC_Marketing" */
    VAR vTargetCC = @CalcMgrGetString(...); 
    
    /* Push revenue */
    "Revenue" -> @MEMBER(vTargetCC) = "Product_Revenue";
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `@MEMBER` instead of `@NAME` | `@MEMBER` turns a String into a Member. `@NAME` turns a Member into a String | Example: `"FY25"` (String) -> `@MEMBER` -> `FY25` (Member). |
| Invalid Member Name | If the string evaluates to `"Proj_999"` but that project doesn't exist in the outline | The script will fail. Always ensure dynamic strings map to valid members |
| Hardcoding when unnecessary | `@MEMBER("Actual")` | Just use `"Actual"` directly. Essbase natively resolves quoted literals in cross-dimensional operators |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@NAME`](../10_String/@NAME.md) | The exact opposite — converts a member to a string |
| [`@CONCATENATE`](../18_Range_Set_Operations/@CONCATENATE.md) | Used to build the strings that @MEMBER resolves |
| [`@SUBSTRING`](../10_String/@SUBSTRING.md) | Used to parse strings before feeding to @MEMBER |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MEMBER](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/member.html)
