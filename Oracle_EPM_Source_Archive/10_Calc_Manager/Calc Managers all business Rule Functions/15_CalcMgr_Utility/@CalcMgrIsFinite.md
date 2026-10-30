# @CalcMgrIsFinite

## Overview

`@CalcMgrIsFinite` is a **custom Calc Manager mathematical validation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a strict safety check, analyzing a numeric value and returning a Boolean flag (`true` or `false`) confirming whether the number is a mathematically valid, **finite** number, as opposed to an infinite error or a `NaN` (Not a Number) exception.

### Why Does This Function Exist?

When executing massive driver-based allocation scripts, division by zero is a constant threat. In standard Essbase, if you divide `100 / 0`, the system usually returns `#MISSING`. 
However, Calc Manager custom functions rely on the underlying Java engine, which adheres to strict IEEE 754 floating-point math standards. In Java, dividing a double by zero does not return `#MISSING`; it literally returns the mathematical concept of `Infinity`. Furthermore, attempting to calculate the square root of a negative number (`@CalcMgrExcelSQRT(-5)`) returns `NaN` (Not a Number). 
If an `Infinity` or `NaN` value bleeds into your script and you attempt to save it into a standard Essbase numeric cell, it can severely corrupt the block, causing subsequent aggregations (`@SUM`) to fail across the entire hierarchy. 
`@CalcMgrIsFinite` allows you to proactively scan the results of risky custom mathematical operations *before* attempting to save them, ensuring only mathematically sane numbers are committed to the database.

### When to Use It

- **Risk Mitigation**: Scanning the output of high-risk custom financial functions (like IRR or XNPV algorithms) that might fail to converge and return `NaN`.
- **Division Safety**: Validating the output of complex, multi-layered allocation formulas where the denominator might dynamically calculate down to zero.
- **Data Cleanup**: Purging corrupted blocks by detecting `Infinity` and forcing the cell back to `#MISSING`.

---

## Category

**Mathematical / Logic & Validation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrIsFinite(number)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The double-precision floating-point number to be evaluated. |

---

## Return Value

**Return Type**: Boolean (`true` or `false`)

Returns `true` if the number is finite and mathematically valid.
Returns `false` if the number is `Infinity`, `-Infinity`, or `NaN`.
- **Essbase Note**: While it returns a Boolean internally, Essbase `IF` statements treat `true` as `1` and `false` as `0`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the 64-bit double.
2. **Type Evaluation**: It executes the native Java check: `!Double.isInfinite(number) && !Double.isNaN(number)`.
3. **Execution**: It analyzes the binary memory signature of the floating-point number to see if it triggers the IEEE 754 flags for infinity or NaN.
4. **Return**: Passes the resulting Boolean back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Output Checking

```essbase
/* 
   vOutput might be a valid number (15.5) or Infinity. 
   If it is valid, IsFinite returns true (1). 
*/
IF(@CalcMgrIsFinite(vOutput))
    "Target" = vOutput;
ENDIF
```

---

## Practical Examples

### Example 1: Protecting the Database from Infinite Allocations

**Scenario**: A multi-step driver allocation model divides total overhead by total widget production. However, because the production volume is calculated dynamically via an external Java macro, the denominator might occasionally resolve to `0.0`. If Java divides by `0.0`, it returns `Infinity`. The script must check the allocation output. If it is infinite, it must replace it with `#MISSING` to protect the database.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* 1. Calculate the dynamic allocation. (Assume vVolume happens to be 0) */
    VAR vAllocatedValue = "Total_Overhead" / vVolume;
    
    /* 
       2. Check if the result is a mathematically valid number.
       Because dividing by 0 in Java float math creates Infinity, 
       IsFinite will evaluate to FALSE.
    */
    IF(@CalcMgrIsFinite(vAllocatedValue))
        
        /* The number is safe. Save it to the database. */
        "Overhead_Allocation" = vAllocatedValue;
        
    ELSE
        
        /* 
           The number is Infinity or NaN. 
           Null it out so it doesn't corrupt the aggregation. 
        */
        "Overhead_Allocation" = #MISSING;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with IsMissing | Checking for `#MISSING` data | `IsFinite` does NOT check if data is `#MISSING`. In fact, passing `#MISSING` into this function usually resolves to `true` because Essbase implicitly treats missing data as `0` during mathematical evaluation, and `0` is a highly finite number. If you want to check if a cell is empty, you MUST use `IF("Target" == #MISSING)` |
| Over-Usage | Using it on basic addition | Addition, subtraction, and multiplication almost never result in `Infinity` (unless you are multiplying billions by billions). You do not need to wrap every formula in `IsFinite`. Only use it on high-risk operations (Division, Logarithms, Square Roots, and iterative algorithms like IRR) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrIsNaN`](./@CalcMgrIsNaN.md) | A narrower validation check that ONLY checks if the number is `NaN` (Not a Number), ignoring `Infinity` |
| [`@CalcMgrExcelSQRT`](./@CalcMgrExcelSQRT.md) | A mathematical function that will return `NaN` if you feed it a negative number, frequently requiring `IsFinite` safety checks |
| [`@ISMBR`](./@ISMBR.md) | Standard Essbase boolean logic function (used for checking dimensional location, not numerical validity) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_isfinite.html)
