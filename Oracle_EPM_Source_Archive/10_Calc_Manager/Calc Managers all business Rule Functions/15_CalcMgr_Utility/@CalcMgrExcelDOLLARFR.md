# @CalcMgrExcelDOLLARFR

## Overview

`@CalcMgrExcelDOLLARFR` is a **custom Calc Manager formatting/math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DOLLARFR` function directly inside an Essbase calculation script. 
It is the exact inverse of `DOLLARDE`. It takes a standard **decimal number** (e.g., `102.125`) and converts it into a fractional representation expressed as a decimal (e.g., `102.04`, representing 102 and 4/32nds).

### Why Does This Function Exist?

While calculating bond yields and treasury portfolio valuations mathematically requires standard decimals (`102.125`), the traders and external systems that consume those reports often expect to see the data formatted in legacy fractional notation (e.g., `102.04`). 
If a Treasury model calculates an optimal sell price for a bond as `$104.75`, and needs to export that to a trading desk system that strictly accepts quotes in 32nds, the system must translate `.75` into `24/32nds`, formatting the final output as `104.24`.
Writing modulus math and string concatenation to achieve this manually in Essbase is incredibly complex. `@CalcMgrExcelDOLLARFR` uses the underlying Java engine to instantly convert the decimal back to the fractional display format, ensuring seamless integration with external financial systems.

### When to Use It

- **Reporting & Exporting**: Formatting calculated bond prices back into 8ths, 16ths, or 32nds for a flat-file export to a trading platform.
- **Dashboards**: Displaying calculated bond yields in a format that traders are accustomed to seeing on their Bloomberg terminals.
- Whenever you need to migrate an Excel spreadsheet containing the `DOLLARFR` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDOLLARFR(decimal_dollar, fraction)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `decimal_dollar`| Numeric | ✅ Yes | The standard decimal number to convert (e.g., `102.125`). |
| `fraction` | Numeric | ✅ Yes | The integer to use as the denominator of the target fraction (e.g., `32` for thirty-seconds, `8` for eighths). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the fractional representation formatted as a decimal.
- e.g., Passing `102.125` with a fraction of `32` returns `102.04`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures `fraction` is an integer >= 0. If `fraction` < 0, the function fails. If `fraction` is exactly 0, it throws a `#MISSING`.
2. **Component Extraction**: The engine isolates the decimal portion of `decimal_dollar` (e.g., `0.125`).
3. **Fraction Math**: It multiplies the decimal portion by the `fraction` parameter to find the numerator (`0.125 * 32 = 4.0`). It shifts the decimal place of that numerator so it can be appended as a suffix (e.g., `4` becomes `0.04`).
4. **Reassembly**: It adds the suffix back to the integer portion of the original number (`102 + 0.04 = 102.04`).
5. **Return**: Passes the newly formatted numeric value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Converting to a Treasury Quote (32nds)

```essbase
/* Actual price is $98.25. Target is 32nds. .25 is 8/32. Returns 98.08 */
"Export_Price" = @CalcMgrExcelDOLLARFR(98.25, 32);
```

### Variant 2: Converting to a Corporate Bond Quote (8ths)

```essbase
/* Actual price is $105.125. Target is 8ths. .125 is 1/8. Returns 105.1 */
"Export_Price" = @CalcMgrExcelDOLLARFR(105.125, 8);
```

---

## Practical Examples

### Example 1: Formatting Calculated Prices for Export

**Scenario**: A corporate treasury model dynamically calculates the theoretical "Target Sell Price" for a portfolio of treasury bonds based on yield curve shifts. The calculated price (`"Target_Sell_Price_Decimal"`) is a pure mathematical decimal (e.g., `101.50`). The trading system requires a flat-file export where all prices are quoted in 32nds (`101.16`). You must convert the data before export.

```essbase
FIX("FY25", "Working", @LEVEL0("Treasury_Bonds"))
    
    /* Ensure a calculated price exists */
    IF("Target_Sell_Price_Decimal" != #MISSING)
        
        /* 
           Convert the decimal into fractional notation.
           E.g., 101.50 becomes 101.16 
        */
        "Export_Target_Price" = @CalcMgrExcelDOLLARFR("Target_Sell_Price_Decimal", 32);
        
        /* 'Export_Target_Price' is then loaded into a reporting slice 
           that gets pulled by the nightly Data Management integration job. */
           
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Calculating with the Output | Multiplying `102.04 * Quantity` | The output of `DOLLARFR` (`102.04`) is purely a visual/formatting construct. It is mathematically "fake" (it represents 102 and 4/32nds, not 102 dollars and 4 cents). If you attempt to multiply this output by a quantity of bonds to get a total dollar value, your math will be massively incorrect. Only use this function at the very end of your calculation stream, solely for reporting or exporting |
| Fractional Denominators | Passing `32.5` as the fraction | The `fraction` parameter is expected to be an integer. The Java wrapper will truncate decimals (e.g., `32.5` becomes `32`). |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelDOLLARDE`](./@CalcMgrExcelDOLLARDE.md) | The exact inverse function: Converts the "fake" fractional representation (e.g., `1.02`) back into a mathematically true decimal (`1.0625`) so you can perform valid multiplication |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldollarfr.html)
