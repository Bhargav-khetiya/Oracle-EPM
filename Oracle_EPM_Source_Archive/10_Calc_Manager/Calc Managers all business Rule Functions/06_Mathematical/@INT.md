# @INT

## Overview

`@INT` is a **native Essbase mathematical rounding function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a double-precision floating-point number (a decimal) and explicitly strips away all fractional values, returning only the **integer** (whole number) portion of the value. 

### Why Does This Function Exist—

When calculating derived metrics, Essbase frequently produces highly precise decimals. For example, if you divide a $\$1,000,000$ pool across 3 departments, the mathematical result is `333333.333333`. 
In standard financial reporting, decimals are fine. However, in driver-based models, decimals can break business logic. If a script calculates `"Required_Headcount" = "Transactions" / 50`, and the result is `3.4`, you cannot hire `3.4` people. If you pass `3.4` into a looping function (`LOOP("Headcount")`), the C-engine will likely crash or truncate the loop unpredictably because loop boundaries require absolute, whole integers.
`@INT` acts as the explicit, mathematical truncation tool. It cleanly slices off everything after the decimal point, guaranteeing that downstream functions or logic receive a perfectly clean, whole integer.

### When to Use It

- **Discrete Unit Modeling**: Calculating physical, indivisible units like Headcount, Vehicles, or Software Licenses where fractional values are physically impossible.
- **Loop Preparation**: Sanitizing derived numbers before feeding them into iterative functions (like `LOOP(x)`) or custom Java CDFs that strictly demand integer inputs.
- **Modulo/Remainder Logic**: Calculating remainders manually (e.g., isolating the decimal portion of a number by subtracting `@INT(x)` from `x`).

---

## Category

**Mathematical / Rounding & Truncation / Essbase Native Functions**

---

## Syntax

```essbase
@INT(numeric_value)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numeric_value` | Numeric | ✅ Yes | The mathematical value, formula, or member reference containing the decimal number you want to truncate. |

---

## Return Value

**Return Type**: Numeric (Double formatted as Integer)

Returns the whole number portion of the input.
- **No Rounding**: This function **DOES NOT ROUND**. It strictly truncates. If you pass `3.999`, it returns `3`. It simply deletes the decimal portion.
- **Negative Numbers**: The behavior on negative numbers is strictly truncation toward zero. If you pass `-3.9`, it returns `-3`.
- **Missing Data**: If the input is `#MISSING`, the function treats it as `0`, resulting in a return value of `0`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The calculation engine resolves the `numeric_value` parameter to its raw double-precision floating-point state.
2. **Bitwise Truncation**: The underlying C-math library explicitly drops the mantissa (the fractional bits) of the floating-point number in memory.
3. **Return**: It returns the remaining integer bits (still cast as a double-precision float to satisfy standard block storage requirements) back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Decimal Truncation

```essbase
/* 
   Removes the .75 fraction. 
   Result is exactly 5.
*/
"Required_Vehicles" = @INT(5.75);
```

---

## Practical Examples

### Example 1: Calculating Indivisible Headcount Needs

**Scenario**: A retail store model calculates `"Required_FTE"` (Full-Time Equivalents) based on `"Weekly_Foot_Traffic"`. Every 500 visitors requires 1 FTE. However, the store cannot hire a fractional person. Management policy dictates that you only get a new hire if you fully hit the next 500 increment (truncation, not rounding). The script must calculate the clean integer requirement.

```essbase
FIX("FY25", "Working", @LEVEL0("Stores"))
    
    IF("Weekly_Foot_Traffic" > 0)
        
        /* 
           1. Calculate the raw ratio. 
           (e.g., 1750 / 500 = 3.5)
        */
        VAR vRawFTE = "Weekly_Foot_Traffic" / 500;
        
        /* 
           2. Use @INT to strip the decimal. 
           (e.g., 3.5 becomes 3. The store gets 3 FTEs).
        */
        "Required_FTE" = @INT(vRawFTE);
        
    ENDIF
    
ENDFIX
```

### Example 2: Isolating the Remainder (Modulo)

**Scenario**: An administrator needs to isolate ONLY the fractional portion of a number (e.g., pulling the `.33` off of `10.33`) to push it into a `"Rounding_Plug"` account so the balance sheet remains perfectly balanced.

```essbase
FIX("FY25", "Working", "Allocated_Value")
    
    /* 
       1. The Total Value is 10.33.
       @INT("Total_Value") equals 10.
       10.33 - 10 = 0.33.
       We write 0.33 to the plug account.
    */
    "Rounding_Plug" = "Total_Value" - @INT("Total_Value");
    
    /* 2. Overwrite the main value with the clean integer */
    "Total_Value" = @INT("Total_Value");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it for Rounding | `@INT(4.9)` | **@INT DOES NOT ROUND UP**. `4.9` becomes `4`. If you are trying to do standard mathematical rounding (where `.5` and above rounds up to the next integer), you MUST use the `@ROUND` function (e.g., `@ROUND(4.9, 0)`). Using `@INT` for rounding will severely under-calculate financial models |
| Confusing with `#MISSING` | `#MISSING` becomes `0` | If you run `@INT("Empty_Account")`, the math engine evaluates `#MISSING` as `0`, and the function returns `0`. This can cause block explosions if used without an `IF` statement. Always wrap truncation math in `IF("Account" != #MISSING)` to prevent writing `0` to empty intersections |
| Double Precision Limits | Extremely large numbers | Essbase uses 64-bit double-precision floats. If you pass an astronomically massive number (e.g., $10^{20}$) into `@INT`, precision loss at the C-level might result in slightly inaccurate integer bounds. For standard EPM financial metrics, this is never an issue, but be aware when modeling abstract statistics |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ROUND`](./@ROUND.md) | The correct function to use when you want `.5` to push the integer UP. (Mathematical rounding rather than strict truncation) |
| [`@TRUNCATE`](./@TRUNCATE.md) | An older function that performs identically to `@INT`, often used interchangeably in legacy calculation scripts |
| [`@REMAINDER`](./@REMAINDER.md) | A mathematical function that explicitly calculates the modulus (the remainder) of division, circumventing the need to build the manual modulo logic shown in Example 2 |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — INT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/int.html)
