# @CalcMgrExcelPRODUCT

## Overview

`@CalcMgrExcelPRODUCT` is a **custom Calc Manager mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `PRODUCT` function directly inside an Essbase calculation script. 
It analyzes a list or array of data points and multiplies them all together, returning the massive **cumulative product**.

### Why Does This Function Exist?

While Essbase has native functions to calculate the sum (`@SUM`) or average (`@AVG`) of an array of members, it lacks a native function to dynamically calculate the cumulative product of an array.
In advanced financial models, calculating the compound return of a portfolio over multiple years requires taking the individual yearly growth multipliers (e.g., `1.05`, `1.03`, `1.08`) and multiplying them all together: `1.05 * 1.03 * 1.08`. Doing this manually for 3 years is easy. Doing it dynamically for a rolling 10-year array requires complex looping logic or massive hardcoded equations. 
`@CalcMgrExcelPRODUCT` handles this instantly. It takes a dynamic cross-dimensional array of values, streams them into the Java engine, and multiplies them sequentially, returning the final accumulated product.

### When to Use It

- **Compound Growth Rates**: Calculating the total cumulative growth of an investment over a dynamic period (multiplying `1 + Rate` for every year).
- **Probability Chains**: Calculating the final joint probability of multiple independent events occurring simultaneously.
- Whenever you need to migrate an Excel spreadsheet containing the `PRODUCT` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelPRODUCT(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelPRODUCT(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, variables, or Essbase accounts. You can also pass a range of members (like `@CHILDREN("Forecast_Years")`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first number or array to multiply. |
| `val2` | Numeric | ✅ Yes | The second number. |
| `[valN]` | Array/List| ❌ No  | Any subsequent numbers or ranges forming the dataset. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the final cumulative product of all valid numbers in the dataset.
- E.g., `@CalcMgrExcelPRODUCT(2, 3, 4)` returns `24`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine ingests the array of data points.
2. **Missing Handling**: It rigorously strips out `#MISSING` values. (If it treated `#MISSING` as `0`, the entire cumulative product would instantly become `0`. Instead, it safely ignores them, acting like a multiplier of `1`).
3. **Sequential Multiplication**: It initializes a variable at the first valid number, then iterates through the array, multiplying the running total by each subsequent number.
4. **Return**: Passes the resulting massive number back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Multiplication

```essbase
/* Mathematically identically to writing: 5 * 10 * 2 = 100 */
"Total_Volume" = @CalcMgrExcelPRODUCT(5, 10, 2);
```

### Variant 2: Array Multiplication

```essbase
/* Multiplies the multipliers for all 12 months together */
"Annual_Compound_Multiplier" = @CalcMgrExcelPRODUCT("Monthly_Growth_Factor"->@CHILDREN("YearTotal"));
```

---

## Practical Examples

### Example 1: Dynamic Compound Portfolio Returns

**Scenario**: A corporate treasury tracks a massive investment portfolio. The portfolio gains or loses a different percentage every single year. The FP&A team has already calculated a `"Growth_Factor"` for every year (e.g., a 5% gain is stored as `1.05`, a 2% loss is stored as `0.98`). They need to know the total cumulative growth factor over the entire 5-year forecast to project the final exit valuation.

```essbase
FIX("Working", "Treasury_Portfolio")
    
    /* 
       Calculate the cumulative product of the growth factors across all 5 years.
       E.g., 1.05 * 1.08 * 0.98 * 1.10 * 1.03 = 1.258
    */
    "Cumulative_5_Year_Growth" = @CalcMgrExcelPRODUCT(
        "Growth_Factor"->"FY21",
        "Growth_Factor"->"FY22",
        "Growth_Factor"->"FY23",
        "Growth_Factor"->"FY24",
        "Growth_Factor"->"FY25"
    );
    
    /* Calculate final exit valuation */
    "Projected_Exit_Value" = "Initial_Seed_Investment" * "Cumulative_5_Year_Growth";
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Zero vs Missing | The database contains actual `0`s | `PRODUCT` safely ignores `#MISSING` values. However, if your data load process populated empty years with hardcoded `0`s, the function will multiply the running total by `0`, resulting in a final answer of exactly `0`. Ensure empty data is truly `#MISSING`, or use an `IF` statement to force `0`s to `1` before passing them into this array |
| Block Calculation Mode | Iterating inside a Dense block | Like `@SUM`, `PRODUCT` should typically be targeted at a specific summary variable or cross-dimensional member. If you try to calculate it "in-line" across an expanding block without proper FIX statements, you might overwrite data or trigger dense-block explosion |
| Exceeding Float Limits | Multiplying massive numbers | If you multiply fifty different `$1,000,000` values together, you will instantly exceed the 64-bit floating point storage limit (approx `10^308`), and the system will return `Infinity` or `#MISSING`. `PRODUCT` is best used for growth factors/multipliers, not raw massive currency blocks |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SUM`](../06_Mathematical/@SUM.md) | Native Essbase function that adds an array of numbers together, rather than multiplying them |
| [`@CalcMgrExcelPOWER`](./@CalcMgrExcelPOWER.md) | Can be used to multiply the *same* number by itself repeatedly (e.g., `1.05^5`), whereas `PRODUCT` allows you to multiply *different* numbers together (e.g., `1.05 * 1.08 * 0.98`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelproduct.html)
