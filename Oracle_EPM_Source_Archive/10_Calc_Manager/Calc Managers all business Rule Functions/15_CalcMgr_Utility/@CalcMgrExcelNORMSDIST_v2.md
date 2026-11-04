# @CalcMgrExcelNORMSDIST

## Overview

`@CalcMgrExcelNORMSDIST` is a **custom Calc Manager statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `NORMSDIST` (or `NORM.S.DIST`) function directly inside an Essbase calculation script. 
It calculates the **Standard Normal Cumulative Distribution Function**. In simpler terms, if you provide a standard Z-score (how many standard deviations a value is away from the mean), this function returns the exact probability that a random variable will fall below that Z-score on a standard bell curve.

### Why Does This Function Exist—

Standard normal distribution (the "bell curve") is the foundation of modern risk modeling, quality control, and inventory optimization. A standard normal curve has a Mean of `0` and a Standard Deviation of `1`. 
If a factory produces widgets with a known defect rate, and a quality engineer calculates a Z-score of `1.96` for today's batch, they need to know what percentage of historical batches were better than this. The math required to calculate the area under the curve of a normal distribution requires integrating the probability density function (`e^(-z^2/2) / sqrt(2*pi)`). 
Because Essbase cannot execute advanced calculus integrals natively, `@CalcMgrExcelNORMSDIST` utilizes highly optimized Java mathematical libraries to approximate the integral instantly, returning the exact probability percentage. This is mandatory for migrating Excel-based Six Sigma or safety-stock models into EPM Cloud.

### When to Use It

- **Inventory Optimization**: Calculating "Service Levels" for safety stock (e.g., finding the probability that you will NOT run out of stock during a lead-time period).
- **Quality Control (Six Sigma)**: Determining the probability of manufacturing defects based on standard deviations from the target spec.
- Whenever you need to migrate an Excel spreadsheet containing the `NORMSDIST` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelNORMSDIST(z)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `z` | Numeric | ✅ Yes | The Z-score (the number of standard deviations away from the mean). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the cumulative probability (the area under the curve to the *left* of the Z-score) as a decimal between `0` and `1`.
- E.g., `@CalcMgrExcelNORMSDIST(0)` returns `0.5` (a Z-score of 0 is exactly in the middle of the bell curve, so 50% of the data falls below it).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Z-score (which can be positive or negative).
2. **Integral Approximation**: The engine runs a high-precision polynomial approximation algorithm (typically based on the error function `erf`) to simulate the calculus integral of the normal distribution curve from negative infinity up to `z`.
3. **Return**: Passes the resulting probability decimal back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating 95% Confidence (1.645)

```essbase
/* A Z-score of 1.645 covers 95% of the curve. Returns ~0.9500 */
"Cumulative_Probability" = @CalcMgrExcelNORMSDIST(1.645);
```

### Variant 2: Calculating Negative Z-Scores

```essbase
/* A Z-score of -1 means it is 1 standard deviation below the mean. Returns ~0.1586 (15.8%) */
"Cumulative_Probability" = @CalcMgrExcelNORMSDIST(-1);
```

---

## Practical Examples

### Example 1: Dynamic Safety Stock Service Levels

**Scenario**: A supply chain model calculates the required `"Safety_Stock_Units"` to ensure they do not run out of product. The Z-score dictates how safe they want to be. The operations director inputs a Z-score of `2.33` into an assumption driver. The model uses `NORMSDIST` to translate that Z-score into a human-readable "Service Level Probability" for the executive dashboard (showing that a Z-score of 2.33 equates to a 99% guarantee of not stocking out).

```essbase
FIX("FY25", "Working", "Global_Assumptions")
    
    /* Ensure a Z-score driver was entered */
    IF("Target_Safety_Z_Score" != #MISSING)
        
        /* 
           Convert the Z-score into a probability decimal.
           E.g., Z = 2.33 returns ~0.9901.
        */
        VAR vProbability = @CalcMgrExcelNORMSDIST("Target_Safety_Z_Score");
        
        /* Store it as a percentage for the dashboard (99.01%) */
        "Calculated_Service_Level_Pct" = vProbability * 100;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing Left vs Right Tail | Expecting the probability of an outlier | `NORMSDIST` returns the cumulative area to the *left* of the Z-score. If you have a Z-score of `2` (which is very high), the function returns `0.9772` (meaning 97.72% of data is *below* this point). If you want to know the probability of being *above* this point (the right tail), you must manually subtract the result from 1: `1 - @CalcMgrExcelNORMSDIST(2) = 0.0228` |
| Using for Non-Standard Curves | Passing a raw raw value like $500 | `NORMSDIST` explicitly assumes a *standard* normal curve (Mean = 0, StdDev = 1). You MUST pass a Z-score. If you have a raw value (like $500 in sales), a Mean of $400, and a StdDev of $50, you must mathematically standardize it first: `Z = (500 - 400) / 50 = 2`, and then pass `2` to `NORMSDIST` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelNORMSINV`](./@CalcMgrExcelNORMSINV.md) | The exact inverse function: You provide a probability (e.g., `0.95`), and it returns the Z-score required to achieve it (`1.645`) |
| [`@CalcMgrExcelSTANDARDIZE`](@CalcMgrExcelNORMSDIST.md) | Converts a raw value into a Z-score based on a provided Mean and Standard Deviation (the necessary precursor step before using `NORMSDIST`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelnormsdist.html)
