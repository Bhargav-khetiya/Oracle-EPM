# @NAME

## Overview

`@NAME` is a **native Essbase string conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a type-caster. It takes a structural dimension member object (or a function that returns a member object) and strictly converts it into a **literal text string**.

### Why Does This Function Exist—

In the Essbase calculation engine, there is a massive difference between a *Member Object* and a *Text String*. 
If you write `@CURRMBR("Entity")`, Essbase returns a pointer to a physical block in the database (e.g., `[Entity_101]`). 
If you try to pass that block pointer into a Custom Java Debugger (`@JDebug`), an attribute comparison (`@ISMBRWITHATTR`), or a string concatenation (`@CONCAT`), the C-engine will instantly crash with a "Type Mismatch" error. It expects text (like `"Entity_101"`), but you handed it a physical database block.
`@NAME` solves this. By wrapping the member in `@NAME(@CURRMBR("Entity"))`, you instruct the compiler to extract the physical name of that block and cast it as a flat, inert string of characters (`"Entity_101"`). This allows you to pass dynamic member names safely into string-processing functions, attribute functions, and logging consoles.

### When to Use It

- **Dynamic Concatenation**: Taking the current Entity and the current Year, converting them to strings, and mashing them together (`"Entity_101_FY25"`) to dynamically generate a target export file name.
- **Diagnostics and Debugging**: Passing the exact name of an offending entity into `@CalcMgrLogText` or `@JDebug` when an allocation script hits a divide-by-zero error.
- **Attribute & UDA Operations**: Passing dynamically generated member strings into `@ISMBRWITHATTR` or `@UDA` when the functions strictly require string parameters.

---

## Category

**String Processing / Type Conversion / Essbase Native Functions**

---

## Syntax

```essbase
@NAME(mbrName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The structural member, member selection function (e.g., `@CURRMBR`), or cross-dimensional reference that you want to convert into text. |

---

## Return Value

**Return Type**: String

Returns the literal string representation of the member name.
- **Formatting**: The returned string exactly matches the member's name as defined in the outline. It does *not* include the dimension prefix unless the member is shared and requires qualification.
- **Inertness**: The returned string is dead text. You cannot use it to point to data anymore (unless you explicitly wrap it back into a member using `@MEMBER`).

---

## How It Works (Behind the Scenes)

1. **Parameter Resolution**: The C-engine resolves the `mbrName` argument to find the specific member object in memory.
2. **Metadata Extraction**: It queries the outline index and extracts the `Name` property of that member object.
3. **Type Casting**: It casts that property as a `char` array (a string).
4. **Return**: It returns the string to the surrounding function (like `@CONCAT` or `@JDebug`).

---

## Syntax Variants & Scenarios

### Variant 1: Resolving the Current Member

```essbase
/* 
   If the engine is currently calculating "Store_500", 
   this returns the text string "Store_500".
*/
VAR vCurrentEntity = @NAME(@CURRMBR("Entity"));
```

---

## Practical Examples

### Example 1: Dynamic Logging of Errors

**Scenario**: A script calculates depreciation. It expects every asset to have a `"Useful_Life"` greater than `0`. If an asset has a `0` life, the script skips the math, but it must log a severe error to the Job Console so the administrator knows exactly *which* asset has bad master data. The script uses `@NAME` to extract the asset's name and push it to the Java Logger.

```essbase
FIX("FY25", "Working", @LEVEL0("Fixed_Assets"))
    
    IF("Useful_Life" > 0)
        
        "Depreciation" = "Net_Value" / "Useful_Life";
        
    ELSE
        
        /* 
           1. The asset has zero life. We need to log it.
           We use @NAME to convert the current asset block into a text string.
        */
        VAR vAssetString = @NAME(@CURRMBR("Fixed_Assets"));
        
        /* 
           2. We concatenate it into a readable error message.
        */
        VAR vErrorMsg = @HspConcat("CRITICAL: Zero Useful Life found on Asset: ", vAssetString);
        
        /* 
           3. We send the pure string payload to the Job Console.
        */
        VAR vLog = @CalcMgrLogText(vErrorMsg);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not using it with `@CURRMBR` | Type Mismatches | The most common error in EPM script writing is trying to write `@CONCAT("Store_", @CURRMBR("Entity"))`. The compiler crashes immediately. `@CONCAT` requires strings. `@CURRMBR` returns a block. You MUST write `@CONCAT("Store_", @NAME(@CURRMBR("Entity")))` |
| Using it to reference data | `@NAME("Sales") = 500` | As stated, `@NAME` converts a block pointer into dead text. You cannot write data into a text string. `Sales = 500` writes to the block. `@NAME("Sales") = 500` tells the compiler to write 500 into the literal word "Sales", which is a fatal syntax error |
| Confusing with `@MEMBER` | String vs Block | `@NAME` goes from Block $\rightarrow$ String. `@MEMBER` does the exact opposite; it takes a string (`"Sales"`) and converts it back into a Block pointer so you can retrieve data from it. They are the inverses of each other |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MEMBER`](../04_Member_Navigation/@MEMBER.md) | The mathematical inverse. Takes a text string and converts it back into an active database block pointer |
| [`@CURRMBR`](../04_Member_Navigation/@CURRMBR.md) | The most common input for `@NAME`. Dynamically returns the active member being calculated |
| [`@CONCAT`](../15_CalcMgr_Utility/@CalcMgrConcat.md) | The most common consumer of `@NAME`. Mashes strings together to build dynamic texts |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — NAME](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/name.html)
