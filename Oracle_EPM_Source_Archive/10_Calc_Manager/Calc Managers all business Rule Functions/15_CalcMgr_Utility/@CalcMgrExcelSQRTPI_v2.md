# @CalcMgrExcelSQRTPI

## Overview

`@CalcMgrExcelSQRTPI` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `SQRTPI` function directly inside an Essbase calculation script. 
It calculates the **Square Root of (Number * Pi)**. Mathematically, it executes `SQRT(number * 3.14159...)`.

### Why Does This Function Exist—

In physics, fluid dynamics, and advanced manufacturing models involving cylindrical or spherical constraints, you frequently need to calculate surface areas, radii, and volumetric flow rates. Many of these algebraic formulas require dividing by Pi, or finding the root of a Pi-scaled constant. 
While you can easily write this manually in Essbase using two distinct functions (`@CalcMgrExcelSQRT(Number * @CalcMgrExcelPI())`), utilizing the dedicated `SQRTPI` function reduces calculation script clutter, eliminates multiple function calls to the Java engine, and perfectly mirrors the syntax of legacy engineering spreadsheets built in Excel.

### When to Use It

- **Manufacturing & Engineering**: Reverse-engineering the radius of a circle or cylinder when the raw Area is known.
- **Physics Modeling**: Calculating standard volumetric capacities or flow rates for industrial pipes.
- Whenever you need to migrate an Excel spreadsheet containing the `SQRTPI` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelSQRTPI(number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The number that will be multiplied by Pi before the square root is taken. **Must be >= 0.** |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the exact square root of `(number * Pi)`.
- E.g., `@CalcMgrExcelSQRTPI(1)` returns `1.77245385` (which is the square root of Pi itself).
- E.g., `@CalcMgrExcelSQRTPI(4)` returns `3.54490770`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine checks if the number is `< 0`. If it is negative, the resulting product would be negative, making the square root an imaginary number. The function will fail and return `#MISSING`.
2. **Execution**: It retrieves the maximum precision float for Pi, multiplies it by the number, and executes the `Math.sqrt()` algorithm.
3. **Return**: Passes the resulting double-precision floating-point value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Square Root of Pi

```essbase
/* Multiplies 1 * Pi, then takes the square root. Returns ~1.772. */
"Constant_Root_Pi" = @CalcMgrExcelSQRTPI(1);
```

---

## Practical Examples

### Example 1: Simplifying Area-to-Radius Conversion

**Scenario**: A chemical plant models the footprint of 100 different cylindrical storage tanks. The system knows the `"Cross_Sectional_Area"` of each tank. The algebraic formula to find the radius is `r = SQRT(Area / Pi)`. However, by manipulating the algebra to remove the division, you can also write this as `r = Area / SQRT(Area * Pi)`. By using `SQRTPI`, you can write this elegantly in a single line.

```essbase
FIX("FY25", "Working", @LEVEL0("Storage_Tanks"))
    
    IF("Cross_Sectional_Area" > 0)
        
        /* 
           Calculate the radius using algebraic substitution.
           Formula: Area / SQRT(Area * Pi)
        */
        "Calculated_Radius" = "Cross_Sectional_Area" / @CalcMgrExcelSQRTPI("Cross_Sectional_Area");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Numbers | `@CalcMgrExcelSQRTPI(-4)` | The result of `-4 * Pi` is a negative number. The square root of a negative number is mathematically undefined in standard Java floating-point arithmetic. It will instantly fail and return `#MISSING` or `NaN`. Use `@ABS` if your data inputs are unvalidated |
| Misunderstanding the Order of Operations | Expecting `SQRT(4) * Pi` | The multiplication happens *inside* the square root parenthesis. It calculates `SQRT(4 * 3.14)`. It does NOT calculate `SQRT(4)` and then multiply the result by `3.14`. If you want the latter, you must write `@CalcMgrExcelSQRT(4) * @CalcMgrExcelPI()` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelSQRT`](./@CalcMgrExcelSQRT.md) | Standard square root without the embedded Pi multiplier |
| [`@CalcMgrExcelPI`](@CalcMgrExcelSQRTPI.md) | Returns the mathematical constant Pi (3.14159...) |
| [`@CalcMgrExcelPOWER`](./@CalcMgrExcelPOWER.md) | Can be used to find any root (cube root, etc.) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelsqrtpi.html)
