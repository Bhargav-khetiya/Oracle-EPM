# @CalcMgrExcelDOLLARDE

## Overview

`@CalcMgrExcelDOLLARDE` is a **custom Calc Manager formatting/math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DOLLARDE` function directly inside an Essbase calculation script. 
It converts a dollar price expressed as an integer and a fraction (e.g., `1.02`, representing 1 and 2/32nds) into a standard **decimal number** (e.g., `1.0625`).

### Why Does This Function Exist?

Historically, US Treasury Bonds and certain financial securities were quoted and traded using fractions (specifically 1/32nds or 1/8ths) rather than standard decimals. For example, a bond quote of `102.04` did not mean $102 and 4 cents. It meant $102 and `4/32nds` of a dollar (which is actually $102.125). 
When pulling market pricing data into an EPM Cloud database from legacy feeds or Bloomberg terminals, these fractional representations must be mathematically converted into standard decimals before you can calculate yields, multiply by quantities, or sum total portfolio value.
`@CalcMgrExcelDOLLARDE` takes that legacy fractional representation (`102.04`) and the base fraction (`32`) and instantly converts it to a usable decimal (`102.125`), ensuring accurate downstream financial math.

### When to Use It

- **Investment Banking / Treasury**: Normalizing fractional bond market quotes into standard decimals for portfolio valuation.
- **Data Integration**: Cleaning up legacy pricing feeds where prices are quoted in 8ths, 16ths, or 32nds.
- Whenever you need to migrate an Excel spreadsheet containing the `DOLLARDE` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDOLLARDE(fractional_dollar, fraction)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `fractional_dollar`| Numeric | ✅ Yes | The number expressed as an integer and a fraction (e.g., `102.04` for 102 and 4/32). |
| `fraction` | Numeric | ✅ Yes | The integer to use as the denominator of the fraction (e.g., `32` for thirty-seconds, `8` for eighths). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the normalized decimal value.
- e.g., Passing `102.04` with a fraction of `32` returns `102.125`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures `fraction` is an integer >= 0. If `fraction` < 0, the function fails. If `fraction` is exactly 0, it throws a `#MISSING` (divide-by-zero prevention).
2. **Component Extraction**: The engine splits the `fractional_dollar` into its integer part (`102`) and its decimal part (`0.04`).
3. **Fraction Math**: It multiplies the decimal part by an appropriate power of 10 to turn it into an integer (e.g., `0.04` becomes `4`), and then divides it by the provided `fraction` parameter (`4 / 32 = 0.125`).
4. **Reassembly**: It adds the new true decimal back to the integer part (`102 + 0.125 = 102.125`).
5. **Return**: Passes the finalized decimal value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Treasury Quote (32nds)

```essbase
/* Quote is 98.08 (98 and 8/32). Returns 98.25 */
"Decimal_Price" = @CalcMgrExcelDOLLARDE(98.08, 32);
```

### Variant 2: Corporate Bond Quote (8ths)

```essbase
/* Quote is 105.1 (105 and 1/8). Returns 105.125 */
"Decimal_Price" = @CalcMgrExcelDOLLARDE(105.1, 8);
```

---

## Practical Examples

### Example 1: Normalizing Market Data Feeds

**Scenario**: A corporate treasury model pulls in the current market price of Treasury Bonds every night from an external source. The source feeds the prices in 32nds format (e.g., `101.16`). Before calculating the total value of the portfolio, the model must normalize all bond prices into standard decimals.

```essbase
FIX("FY25", "Working", @LEVEL0("Treasury_Bonds"))
    
    /* Ensure a market quote exists */
    IF("Raw_Market_Quote" != #MISSING)
        
        /* 
           Convert the quote. Treasury bonds trade in 32nds. 
           E.g., 101.16 becomes 101.50 
        */
        "Normalized_Market_Price" = @CalcMgrExcelDOLLARDE("Raw_Market_Quote", 32);
        
        /* Calculate the total value of the holdings */
        /* Assuming 'Normalized_Market_Price' is per $100 face value */
        "Total_Holdings_Value" = ("Normalized_Market_Price" / 100) * "Par_Value_Held";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding the Input | Passing standard decimals | If a bond is actually priced at `$102.50`, and you pass `102.50` into `DOLLARDE(102.50, 32)`, the function assumes you mean 102 and 50/32. It will mathematically roll the fraction over, resulting in `103.5625`. Only use this function on data explicitly known to be in fractional-quote format |
| Fractional Denominators | Passing `32.5` as the fraction | The `fraction` parameter is expected to be an integer (e.g., `8`, `16`, `32`). If you pass a decimal, the Java wrapper truncates it to an integer (e.g., `32.5` becomes `32`). This can cause unexpected rounding behavior |
| Negative Fractions | Passing `-32` | Excel and Calc Manager strictly forbid negative denominators for this calculation. It will return an error or `#MISSING` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelDOLLARFR`](./@CalcMgrExcelDOLLARFR.md) | The exact inverse function: Converts a standard decimal (e.g., `1.0625`) back into a fractional representation (e.g., `1.02`) for external reporting |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldollarde.html)
