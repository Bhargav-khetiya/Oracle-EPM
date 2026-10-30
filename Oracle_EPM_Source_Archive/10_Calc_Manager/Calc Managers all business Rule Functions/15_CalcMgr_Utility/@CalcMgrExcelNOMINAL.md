# @CalcMgrExcelNOMINAL

## Overview

`@CalcMgrExcelNOMINAL` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `NOMINAL` function directly inside an Essbase calculation script. 
It calculates the **Nominal Annual Interest Rate**, converting a true Effective Annual Rate (EAR / APY) back into the stated "base" rate, based on how many times per year the interest compounds.

### Why Does This Function Exist?

When a bank quotes an interest rate, they usually give you the "Nominal" rate (e.g., 12% APR). If it compounds monthly, the *actual* amount of interest paid by the end of the year equates to an Effective Annual Rate (EAR) of 12.68%. The function `@CalcMgrExcelEFFECT` handles that forward calculation.
However, in reverse-engineering scenarios, you might only know the final Effective yield (e.g., "This investment guarantees a 5.5% APY"). If you need to build a monthly amortization schedule for that investment inside Essbase, you cannot divide 5.5% by 12. You must mathematically strip out the compounding effect to find the underlying Nominal base rate, and *then* divide that base rate by 12. 
`@CalcMgrExcelNOMINAL` handles this reverse-algebra instantly in Java, executing `npery * ((1 + effect_rate) ^ (1 / npery) - 1)` without requiring the developer to write massive fractional exponent math in a calc script.

### When to Use It

- **Debt Structuring**: Reverse-engineering a competitor's loan product (where only the final APY is advertised) into a monthly stated rate to build comparative amortization tables.
- **Investment Modeling**: Converting a target annual yield back into a daily compounding rate for cash-sweep accounts.
- Whenever you need to migrate an Excel spreadsheet containing the `NOMINAL` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelNOMINAL(effect_rate, npery)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `effect_rate`| Numeric | ✅ Yes | The true Effective Annual Interest Rate as a decimal (e.g., `0.1268` for 12.68%). Must be > 0. |
| `npery` | Numeric | ✅ Yes | The number of compounding periods per year. E.g., `12` for monthly, `4` for quarterly, `365` for daily. Must be an integer >= 1. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Nominal Annual Interest Rate as a decimal.
- E.g., Passing `0.12682503` with `12` periods returns `0.12` (12%).

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures `effect_rate` > 0 and `npery` >= 1. If `npery` is a decimal (e.g., `12.5`), it automatically truncates it to an integer (`12`).
2. **Formula Execution**: It executes the reverse algebraic formula: `npery * ((1 + effect_rate) ^ (1 / npery) - 1)`.
3. **Return**: Passes the resulting base rate decimal back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Unwinding Monthly Compounding

```essbase
/* The True Yield is 12.68%. It compounds 12 times a year. Returns exactly 0.12 (12%) */
"Stated_Base_Rate" = @CalcMgrExcelNOMINAL(0.12682503, 12);
```

---

## Practical Examples

### Example 1: Building an Amortization Schedule from a Target APY

**Scenario**: A corporate treasury wants to offer a structured investment product to its subsidiaries that guarantees exactly a `6.00% APY` (Effective Rate). Interest will be paid into their accounts monthly (12 periods). To build the Essbase forecast that actually calculates the monthly interest expense, the system must first find the underlying Nominal rate, and then find the monthly rate.

```essbase
FIX("FY25", "Working", @LEVEL0("Subsidiaries"))
    
    /* Ensure the sub has invested money */
    IF("Initial_Investment_Deposit" > 0)
        
        /* 
           1. The target APY is 6% (0.06). 
           We must extract the base Nominal Rate to back out the compounding effect.
           Returns ~0.0584 (5.84%)
        */
        VAR vNominalRate = @CalcMgrExcelNOMINAL(0.06, 12);
        
        /* 
           2. Divide the Nominal Rate by 12 to find the exact rate to apply every month.
           Returns ~0.00486 (0.486%)
        */
        "Calculated_Monthly_Rate" = vNominalRate / 12;
        
        /* 
           3. The downstream script will now take "Calculated_Monthly_Rate" and apply it 
           to the cascading monthly balance to perfectly hit the 6.00% target at year-end.
        */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Whole Numbers | `NOMINAL(12.68, 12)` | The `effect_rate` explicitly expects a decimal. If the APY is 12.68%, you must pass `0.1268`. Passing `12.68` implies the interest rate is 1,268%, resulting in massive overflow values |
| Number of Periods < 1 | `NOMINAL(0.06, 0)` | You cannot have 0 compounding periods per year. If an investment does not compound, or compounds exactly once a year, the `npery` is `1`. Passing a value < 1 causes the function to fail and return `#MISSING` |
| Direct Division Error | `0.06 / 12` | If you have a target APY of 6%, you CANNOT simply divide 0.06 by 12 to get your monthly rate. If you do that, the compounding math will yield `6.16%` by the end of the year, overpaying the investor. You MUST run the APY through `NOMINAL` first, and *then* divide by 12 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelEFFECT`](./@CalcMgrExcelEFFECT.md) | The exact inverse function: Converts a stated Nominal Rate forward into its true Effective Annual Rate |
| [`@CalcMgrExcelFV`](./@CalcMgrExcelFV.md) | Calculates the Future Value of an investment based on periodic compounding |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelnominal.html)
