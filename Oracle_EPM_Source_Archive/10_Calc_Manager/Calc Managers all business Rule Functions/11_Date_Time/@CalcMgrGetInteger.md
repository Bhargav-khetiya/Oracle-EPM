# @CalcMgrGetInteger

## Overview

`@CalcMgrGetInteger` is a **custom Calc Manager numeric casting function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a double-precision floating-point number (e.g., `14.95`) and violently **truncates** it into a pure integer (e.g., `14`).

### Why Does This Function Exist—

Essbase natively handles all data as 64-bit double-precision floating-point numbers. Even if you type `14` into a cell, Essbase stores it as `14.0`. Most of the time, this is fine. 
However, when building complex algorithmic models involving array indexes, dynamic date manipulation (`YYYYMMDD`), or modular arithmetic, floating-point decimals cause catastrophic failures. If you try to extract the 3rd item from a custom array, but your math dynamically calculated the index as `3.14`, Java will crash because array indexes must be absolute whole integers.
While Essbase has native functions like `@INT`, they sometimes fail to properly cast the variable type at the strict Java layer when executing Calc Manager Custom Functions. `@CalcMgrGetInteger` explicitly forces the Java engine to cast the double into a pure `int` primitive type, permanently deleting any fractional data, ensuring absolute compatibility with downstream integer-only Java logic.

### When to Use It

- **Date Math Integration**: Forcing mathematical outputs into clean integers before passing them into strict YYYYMMDD date logic.
- **Array Indexing**: Calculating a dynamic array position (e.g., `(Total_Volume / Batch_Size)`) and forcing it to an integer so it can be safely used to target an array slot.
- **Precision Stripping**: Aggressively removing micro-decimals caused by floating-point drift (e.g., `14.000000000001`) before executing exact equality checks (`== 14`).

---

## Category

**Mathematical / Type Casting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetInteger(number)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The double-precision floating-point number to be truncated (e.g., `14.95`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns a pure integer.
- E.g., `14.95` returns `14`.
- **CRITICAL**: This function does **NOT** round. It simply truncates. If you pass `14.99`, it returns `14`. If you want rounding, you must use `@ROUND` first.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the 64-bit double.
2. **Type Casting**: It executes a strict Java cast: `(int) number`. This physically strips the decimal payload from the binary memory address.
3. **Return**: Passes the resulting 32-bit integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Pure Truncation

```essbase
/* Forcefully truncates the number. Returns 14. */
"Integer_Value" = @CalcMgrGetInteger(14.95);
```

---

## Practical Examples

### Example 1: Dynamic Batch Processing (Array Indexing)

**Scenario**: A manufacturing plant processes widgets in batches of 10. The system loads `"Total_Widgets_Produced"` (e.g., `45`). The model needs to dynamically determine how many full batches were completed so it can apply a "Batch Processing Fee". It divides 45 by 10 (resulting in `4.5`), and then uses `GetInteger` to strip the decimal, ensuring only fully completed batches (`4`) trigger the fee.

```essbase
FIX("FY25", "Working", @LEVEL0("Factories"))
    
    IF("Total_Widgets_Produced" > 0)
        
        /* 
           1. Calculate the raw floating-point division.
           E.g., 45 / 10 = 4.5
        */
        VAR vRawBatches = "Total_Widgets_Produced" / 10;
        
        /* 
           2. Force the float into a strict integer to drop the partial batch.
           E.g., 4.5 becomes 4.
        */
        VAR vCompletedBatches = @CalcMgrGetInteger(vRawBatches);
        
        /* 
           3. Apply the fee ($500 per completed batch).
        */
        "Total_Processing_Fees" = vCompletedBatches * 500;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Rounding | Passing `4.9` and expecting `5` | `GetInteger` performs absolute truncation. It simply deletes the decimal point and everything after it. `4.9` becomes `4`. `4.1` becomes `4`. If you need mathematical rounding, you MUST use `@ROUND(number, 0)` instead of this function |
| Redundant Usage | Wrapping native Essbase logic | If you are just trying to drop a decimal to write it into an Essbase account cell, the native Essbase `@INT()` or `@TRUNC()` functions are faster and don't require calling the Java engine. Use `GetInteger` primarily when you are prepping variables to feed into *other* Java-backed Calc Manager functions that strictly demand `int` types |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetIntegerFromString`](./@CalcMgrGetIntegerFromString.md) | Performs the same integer casting, but takes a Text String (like `"14"`) as the input rather than a float |
| [`@INT`](./@INT.md) | Native Essbase function that truncates decimals to integers |
| [`@ROUND`](./@ROUND.md) | Mathematically rounds a number up or down to the nearest integer, rather than violently truncating it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getinteger.html)
