# @CalcMgrExcelPOWER

## Overview

`@CalcMgrExcelPOWER` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `POWER` function directly inside an Essbase calculation script. 
It returns the result of a **base number raised to a specific exponential power**. Mathematically, it executes `number ^ power`.

### Why Does This Function Exist—

In legacy on-premise Essbase, calculating exponents typically required using the native `@POWER` function. However, the Calc Manager `@CalcMgrExcelPOWER` function was introduced to guarantee perfect 1-to-1 floating-point parity with the Microsoft Excel mathematical engine. 
In advanced financial physics, depreciation curves, and compound interest models, a slight difference in floating-point precision deep within a massive exponent calculation (e.g., `(1 + 0.05) ^ 120`) can compound into a multi-thousand dollar variance by the end of a 10-year forecast.
By utilizing `@CalcMgrExcelPOWER`, administrators guarantee that their EPM Cloud models calculate exponents exactly the way legacy Excel spreadsheets do, eliminating precision reconciliation headaches.

### When to Use It

- **Compound Interest**: Manually calculating future values or compound growth rates using algebraic formulas (e.g., `CAGR = (Ending / Beginning) ^ (1/N) - 1`).
- **Depreciation**: Calculating geometric or double-declining balance depreciation curves.
- Whenever you need to migrate an Excel spreadsheet containing the `POWER` function directly into an Essbase calculation and require absolute mathematical parity.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelPOWER(number, power)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The base number. |
| `power` | Numeric | ✅ Yes | The exponent to which the base number is raised. Can be an integer or a decimal. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the calculated exponential result.
- E.g., `@CalcMgrExcelPOWER(5, 2)` mathematically equates to `5 * 5` and returns `25`.
- E.g., `@CalcMgrExcelPOWER(27, 1/3)` mathematically equates to the cube root of 27 and returns `3`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the base number and the exponent.
2. **Execution**: It executes `Math.pow(number, power)` in Java, returning the exact double-precision floating-point result.
3. **Return**: Passes the finalized result back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Squaring

```essbase
/* Squares the number 10. Returns 100. */
"Result" = @CalcMgrExcelPOWER(10, 2);
```

### Variant 2: Fractional Exponents (Roots)

```essbase
/* Passing a fractional exponent (1/3) acts as a cube root. Returns 4. */
"Result" = @CalcMgrExcelPOWER(64, (1/3));
```

---

## Practical Examples

### Example 1: Manual Compound Annual Growth Rate (CAGR)

**Scenario**: A company wants to calculate the exact Compound Annual Growth Rate (CAGR) of its revenue over a 5-year period (from FY20 to FY25). The algebraic formula for CAGR is `(Ending_Value / Beginning_Value) ^ (1 / Number_Of_Years) - 1`. 

```essbase
FIX("Working", "Total_Revenue")
    
    /* Ensure we have a valid beginning value to prevent division by zero */
    IF("FY20" != #MISSING AND "FY20" > 0)
        
        /* Calculate the raw ratio */
        VAR vRatio = "FY25" / "FY20";
        
        /* 
           Apply the fractional exponent (1/5) using the POWER function.
           Subtract 1 to convert it to a pure growth percentage.
        */
        "5_Year_CAGR" = @CalcMgrExcelPOWER(vRatio, (1/5)) - 1;
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Manual Future Value Compounding

**Scenario**: While `@CalcMgrExcelFV` is ideal for periodic payments, sometimes you just need to compound a single flat investment dynamically. A $10,000 investment grows at 5% annually for 10 years. The formula is `PV * (1 + Rate) ^ Years`.

```essbase
FIX("FY25", "Working", "Treasury_Investments")
    
    IF("Initial_Seed_Cash" > 0)
        
        /* Calculate the compounding multiplier using POWER */
        VAR vMultiplier = @CalcMgrExcelPOWER((1 + "Annual_Interest_Rate"), "Total_Years");
        
        /* Multiply by the initial investment */
        "Calculated_Future_Value" = "Initial_Seed_Cash" * vMultiplier;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Base, Fractional Exponent | `@CalcMgrExcelPOWER(-27, 1/3)` | Mathematically, taking the fractional exponent of a negative number often pushes into imaginary/complex numbers (which Excel and Essbase do not support in standard math functions). This will return an error or `NaN`. If you need to find the cube root of a negative number, use `@ABS` to make it positive, run the `POWER` calculation, and then multiply the result by `-1` |
| 0 to the Power of 0 | `@CalcMgrExcelPOWER(0, 0)` | Mathematically undefined. Will result in an error or `#MISSING` |
| Over-Complicating Code | Using `POWER` for basic squaring | If you just need to square a number, typing `"Value" * "Value"` is slightly faster for the Essbase engine to process than delegating the math out to a custom Java `POWER` function. Reserve `POWER` for larger, variable, or fractional exponents |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@POWER`](../06_Mathematical/@POWER.md) | The native Essbase exponent function (essentially identical, but `CalcMgrExcelPOWER` guarantees perfect Excel floating-point parity) |
| [`@CalcMgrExcelEXP`](../06_Mathematical/@EXP.md) | Specifically calculates `e` (Euler's number, ~2.718) raised to a power, used in continuous compounding formulas |
| [`@CalcMgrExcelSQRT`](./@CalcMgrExcelSQRT.md) | A dedicated function for finding the square root of a number |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelpower.html)
