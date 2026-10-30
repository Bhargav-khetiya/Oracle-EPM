# @CalcMgrExcelNORMSINV

## Overview

`@CalcMgrExcelNORMSINV` is a **custom Calc Manager statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `NORMSINV` (or `NORM.S.INV`) function directly inside an Essbase calculation script. 
It calculates the **Inverse of the Standard Normal Cumulative Distribution**. In simpler terms, if you provide a target probability percentage (e.g., "I want to be 95% confident"), it returns the exact Z-score (the number of standard deviations) required to hit that target on a standard bell curve.

### Why Does This Function Exist?

When building predictive models for manufacturing safety stock or financial risk reserves, executives don't pick Z-scores; they pick probabilities. A CEO says, "I want a 99% guarantee that we won't run out of inventory." 
To calculate exactly how many units of safety stock you need, you must first translate that `99%` probability into a Z-score (which is roughly `2.326`). You then multiply that Z-score by the standard deviation of your historical demand. 
Finding the exact Z-score mathematically from a probability requires calculating the inverse of the error function integral, which is completely impossible to do using standard Essbase equations. `@CalcMgrExcelNORMSINV` offloads this reverse-calculus to the Java engine, running an optimized approximation algorithm to return the exact Z-score instantly.

### When to Use It

- **Inventory Optimization**: Translating executive "Service Level" targets (e.g., 98%) into the mathematical Z-scores required to calculate physical safety stock units.
- **Value at Risk (VaR)**: Determining the exact capital reserve threshold required to ensure a bank remains solvent with 99.9% statistical confidence.
- Whenever you need to migrate an Excel spreadsheet containing the `NORMSINV` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelNORMSINV(probability)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `probability` | Numeric | ✅ Yes | The target cumulative probability expressed as a decimal. Must be strictly greater than `0` and less than `1` (e.g., `0.95` for 95%). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Z-score (number of standard deviations).
- E.g., `@CalcMgrExcelNORMSINV(0.95)` returns approximately `1.64485`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures the `probability` is `> 0` and `< 1`. If you pass `0`, `1`, or any number outside those bounds, the function fails and returns `#MISSING`.
2. **Inverse Approximation**: The engine utilizes a rational polynomial approximation (often the Beasley-Springer-Moro algorithm) to reverse-engineer the normal distribution integral.
3. **Return**: Passes the resulting Z-score back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Z-Score for 99% Confidence

```essbase
/* A target of 99% confidence. Returns ~2.3263 */
"Target_Z_Score" = @CalcMgrExcelNORMSINV(0.99);
```

### Variant 2: Finding the Z-Score for the Bottom 10%

```essbase
/* Looking at the left tail (bottom 10%). Returns a negative Z-score: ~ -1.2815 */
"Bottom_Decile_Z_Score" = @CalcMgrExcelNORMSINV(0.10);
```

---

## Practical Examples

### Example 1: Calculating Required Safety Stock Units

**Scenario**: A supply chain model calculates raw demand for retail products. The VP of Supply Chain dictates that all flagship products must have a Service Level of `98%` (they will not stock out 98% of the time). To calculate the physical safety stock units, the FP&A team uses `NORMSINV` to translate that 98% target into a Z-score, and then multiplies it by the calculated standard deviation of lead-time demand.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* Ensure there is historical volatility to measure against */
    IF("Demand_Standard_Deviation" > 0 AND "Target_Service_Level_Pct" != #MISSING)
        
        /* 
           1. Target_Service_Level_Pct is loaded as 0.98.
           Convert it to a Z-score (returns ~2.0537).
        */
        VAR vZScore = @CalcMgrExcelNORMSINV("Target_Service_Level_Pct");
        
        /* 
           2. Calculate the physical safety stock required.
           Formula: Z-Score * Standard Deviation of Demand 
        */
        "Safety_Stock_Units" = @ROUND(vZScore * "Demand_Standard_Deviation", 0);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Percentages as Integers | `@CalcMgrExcelNORMSINV(95)` | The function expects a decimal between `0` and `1`. If you pass `95` (meaning 95%), the function recognizes it as being `> 1` and instantly fails, returning `#MISSING`. Ensure your percentages are stored as true decimals (`0.95`) |
| Passing 0 or 1 | `@CalcMgrExcelNORMSINV(1)` | A normal distribution curve is asymptotic (it extends infinitely in both directions without ever perfectly hitting 0% or 100%). Therefore, there is no mathematical Z-score for exactly 100%. If you pass `1`, the function fails. If your dashboard allows users to select 100%, you must write an `IF` statement to force it to `0.9999` before calculating |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelNORMSDIST`](./@CalcMgrExcelNORMSDIST.md) | The exact inverse function: You provide a Z-score (`1.645`), and it returns the cumulative probability percentage (`0.95`) |
| [`@CalcMgrExcelSTANDARDIZE`](@CalcMgrExcelNORMSDIST.md) | Converts a raw numerical value into a Z-score |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelnormsinv.html)
