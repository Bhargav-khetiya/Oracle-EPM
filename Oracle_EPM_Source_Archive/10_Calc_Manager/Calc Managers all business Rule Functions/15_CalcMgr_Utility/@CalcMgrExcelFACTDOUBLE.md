# @CalcMgrExcelFACTDOUBLE

## Overview

`@CalcMgrExcelFACTDOUBLE` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `FACTDOUBLE` function directly inside an Essbase calculation script. 
It calculates the **Double Factorial** of a number, mathematically represented as `n!!`.

### Why Does This Function Exist—

A standard factorial (`n!`) multiplies every integer downwards (e.g., 6 * 5 * 4 * 3 * 2 * 1). 
A *double* factorial (`n!!`) steps down by **two** integers at a time, strictly preserving the parity (even/odd nature) of the starting number. 
- If the number is Even (e.g., `6`), it calculates `6 * 4 * 2 = 48`.
- If the number is Odd (e.g., `7`), it calculates `7 * 5 * 3 * 1 = 105`.

Double factorials are used in highly specialized probabilistic mathematics, quantum physics, and certain advanced statistical integrals (like calculating the volume of n-dimensional spheres). While incredibly rare in standard corporate finance, if an actuary or data scientist built a complex Monte Carlo risk simulation in Excel that utilized `=FACTDOUBLE()`, rebuilding that "skip-step" multiplication loop in an Essbase calc script is tedious and slow. `@CalcMgrExcelFACTDOUBLE` bridges the gap, allowing for a 1-to-1 migration of the formula into EPM Cloud.

### When to Use It

- **Actuarial Modeling**: Advanced probabilistic models evaluating life expectancies or insurance risk using hypergeometric distributions.
- **Statistical Analytics**: Calculating specialized Taylor series expansions inside custom Essbase variance models.
- Whenever you need to migrate an Excel spreadsheet containing the `FACTDOUBLE` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelFACTDOUBLE(number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The non-negative integer you want the double factorial of (e.g., `6`). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the mathematical double factorial of the number.
- EPM Cloud handles the result as a double-precision floating-point number to accommodate massive outcomes without integer overflow.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures the `number` is >= 0. Passing a negative number will cause the function to return `#MISSING`.
2. **Truncation**: If you pass a decimal (e.g., `6.9`), the engine truncates it to the nearest integer (`6`) before executing the math, mirroring Excel's behavior. 
3. **Parity Check & Execution**: The Java engine checks if the number is odd or even, and executes an optimized iterative multiplication loop, subtracting 2 at each step until it hits `1` (for odd numbers) or `2` (for even numbers). Special case: `FACTDOUBLE(0)` and `FACTDOUBLE(-1)` evaluate to `1` by mathematical definition, though passing `-1` often throws an error depending on the exact Java implementation version.
4. **Return**: Passes the resulting number back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Even Double Factorial

```essbase
/* Calculates 6!! (6 * 4 * 2). Returns 48. */
"Special_Permutations" = @CalcMgrExcelFACTDOUBLE(6);
```

### Variant 2: Odd Double Factorial

```essbase
/* Calculates 7!! (7 * 5 * 3 * 1). Returns 105. */
"Special_Permutations" = @CalcMgrExcelFACTDOUBLE(7);
```

---

## Practical Examples

### Example 1: Advanced Actuarial Math (Simplified)

**Scenario**: An insurance company uses Essbase to run risk assessments on localized population pockets. They use a proprietary statistical formula to determine a "Risk Volatility Index" that explicitly relies on the Double Factorial of a given demographic's `"Risk_Category"` (an integer between 1 and 20).

```essbase
FIX("FY25", "Working", @LEVEL0("Demographics"))
    
    IF("Risk_Category" != #MISSING)
        
        /* 1. Calculate the Double Factorial base */
        VAR vBase = @CalcMgrExcelFACTDOUBLE("Risk_Category");
        
        /* 2. Apply proprietary weighting (e.g., dividing by Population Variance) */
        "Volatility_Index" = vBase / "Historical_Variance";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misinterpreting the Function | Thinking `FACTDOUBLE` means `(n!) * 2` | A double factorial is a completely different mathematical operation than multiplying a factorial by two, or taking a factorial of a factorial (e.g., `(3!)!`). `FACTDOUBLE(6)` is `48`. `FACT(6) * 2` is `1,440`. |
| Negative Numbers | `@CalcMgrExcelFACTDOUBLE(-4)` | Double factorials are generally undefined for negative integers (except for specific cases involving odd negative integers in complex math, which this function does not support). The function will fail. |
| Storage Overflows | Calculating `FACTDOUBLE(300)` | While `FACTDOUBLE` grows slower than `FACT`, passing extremely large numbers will eventually exceed the 64-bit float limit of `10^308`, resulting in an `Infinity` error or `#MISSING`. |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelFACT`](./@CalcMgrExcelFACT.md) | Calculates a standard Factorial (multiplying down by 1 integer at a time) |
| [`@CalcMgrExcelCOMBIN`](./@CalcMgrExcelCOMBIN.md) | Calculates combinations (which natively relies on standard factorials) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelfactdouble.html)
