# @CalcMgrExcelSQRT

## Overview

`@CalcMgrExcelSQRT` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `SQRT` function directly inside an Essbase calculation script. 
It calculates the **Square Root** of a positive number.

### Why Does This Function Exist—

In statistical modeling, risk management, and physical unit conversions, the square root is a fundamental building block. For example, calculating the Standard Deviation (the square root of the Variance) is mandatory for any supply chain safety stock model. 
While you can theoretically calculate a square root using exponents (`@CalcMgrExcelPOWER(number, 0.5)`), the `@CalcMgrExcelSQRT` function is specifically optimized for this singular task. By delegating the math directly to `Math.sqrt()` in the Java engine, it executes faster and guarantees perfect parity with legacy Excel models that rely on the `=SQRT(A1)` syntax.

### When to Use It

- **Statistics (Standard Deviation)**: Converting calculated statistical variance into standard deviation for Z-score and probability models.
- **Physical Planning**: Calculating physical dimensions (like the radius of a circular tank given its cross-sectional area).
- Whenever you need to migrate an Excel spreadsheet containing the `SQRT` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelSQRT(number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The number for which you want to find the square root. **Must be a positive number.** |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the exact square root of the number.
- E.g., `@CalcMgrExcelSQRT(144)` returns `12`.
- E.g., `@CalcMgrExcelSQRT(2)` returns `1.414213562373095`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine checks if the number is `< 0`. If it is negative, the square root is an imaginary number, which is mathematically undefined in this context, and the function returns `#MISSING`.
2. **Execution**: It executes the highly optimized `Math.sqrt(number)` algorithm in Java.
3. **Return**: Passes the resulting double-precision floating-point value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Square Root

```essbase
/* Mathematically calculates the square root of 25. Returns 5. */
"Result" = @CalcMgrExcelSQRT(25);
```

---

## Practical Examples

### Example 1: Calculating Standard Deviation from Variance

**Scenario**: A supply chain model calculates the historical demand variance for a product using complex array mathematics. However, to actually use that data in a safety stock formula (which relies on Z-scores), the variance must be converted into standard deviation. Standard Deviation is simply the square root of the Variance.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* Ensure the product has historical variance */
    IF("Demand_Variance" > 0)
        
        /* 
           Calculate the Standard Deviation.
           E.g., If Variance is 400, Standard Deviation is 20.
        */
        "Demand_Standard_Deviation" = @CalcMgrExcelSQRT("Demand_Variance");
        
        /* Use standard deviation to calculate physical safety stock units */
        "Safety_Stock_Units" = @ROUND("Target_Z_Score" * "Demand_Standard_Deviation", 0);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Dynamic Area-to-Radius Conversion

**Scenario**: A chemical manufacturing plant tracks the volume of liquid in cylindrical vats. The system only stores the cross-sectional area of the vat in square meters. To calculate the physical footprint, the system must reverse-engineer the radius of the vat using the formula `Area = Pi * r^2`, which rearranges to `r = SQRT(Area / Pi)`.

```essbase
FIX("Working", "Chemical_Vats")
    
    IF("Cross_Sectional_Area" > 0)
        
        /* 1. Get the exact value of Pi (3.14159...) */
        VAR vPi = @CalcMgrExcelPI();
        
        /* 2. Divide the Area by Pi */
        VAR vAreaOverPi = "Cross_Sectional_Area" / vPi;
        
        /* 3. Take the Square Root to find the Radius in meters */
        "Calculated_Radius" = @CalcMgrExcelSQRT(vAreaOverPi);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Numbers | `@CalcMgrExcelSQRT(-25)` | The square root of a negative number is an imaginary number. The Java math engine does not support complex/imaginary numbers, so it will instantly fail and return `#MISSING` (or `NaN`). If your input variable might be negative due to system adjustments, wrap it in `@ABS` first: `@CalcMgrExcelSQRT(@ABS("Value"))` |
| Over-Complicating Code | `POWER(25, 0.5)` | While mathematically identical, using the `POWER` function to find a square root is slightly less efficient and harder to read for FP&A administrators. Always use the dedicated `SQRT` function for square roots |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelSQRTPI`](./@CalcMgrExcelSQRTPI.md) | A specialized variant that multiplies the number by Pi *before* taking the square root |
| [`@CalcMgrExcelPOWER`](./@CalcMgrExcelPOWER.md) | Can be used to find any root (e.g., cube root, 4th root) by passing a fractional exponent like `1/3` |
| [`@CalcMgrExcelPI`](@CalcMgrExcelSQRTPI.md) | Returns the mathematical constant Pi (3.14159...) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelsqrt.html)
