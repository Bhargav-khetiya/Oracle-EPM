# @CalcMgrExcelMDURATION

## Overview

`@CalcMgrExcelMDURATION` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `MDURATION` function directly inside an Essbase calculation script. 
It calculates the **Modified Macaulay Duration** for a security with an assumed par value of $100. Modified Duration is a critical risk metric used to measure a bond's price sensitivity to interest rate changes.

### Why Does This Function Exist—

While standard `DURATION` (Macaulay Duration) calculates the weighted average time (in years) it takes to receive a bond's cash flows, **Modified Duration** takes that time metric and mathematically adjusts it to calculate actual price volatility. 
Specifically, Modified Duration answers the question: *"If the market interest rate goes up by 1%, by exactly what percentage will the price of my bond collapse—*
The mathematical formula for Modified Duration is `Macaulay_Duration / (1 + (Yield / Frequency))`. While you could theoretically calculate this manually in Essbase using the standard `DURATION` function and dividing it, `@CalcMgrExcelMDURATION` handles the entire iterative discounting loop and the subsequent modification in a single Java call. This guarantees perfect parity with legacy risk-management spreadsheets used by corporate treasurers.

### When to Use It

- **Risk Management (ALM)**: Evaluating exactly how much value a fixed-income portfolio will lose if the Federal Reserve raises interest rates by 50 basis points.
- **Hedging Strategies**: Calculating the elasticity of corporate bonds to determine how many interest rate swaps are required to perfectly hedge the portfolio.
- Whenever you need to migrate an Excel spreadsheet containing the `MDURATION` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelMDURATION(settlement, maturity, coupon, yld, frequency, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the security is traded or evaluated. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the security expires. Must be > `settlement`. |
| `coupon` | Numeric | ✅ Yes | The bond's annual coupon interest rate (e.g., `0.05` for 5%). |
| `yld` | Numeric | ✅ Yes | The bond's current annual yield-to-maturity (e.g., `0.06` for 6%). |
| `frequency` | Numeric | ✅ Yes | The number of coupon payments per year: Annual = `1`, Semi-annual = `2`, Quarterly = `4`. |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Modified Duration expressed as a percentage multiplier (e.g., `4.25`).
- A return value of `4.25` means that for every 1% change in the `yld`, the price of the bond will change by approximately 4.25% in the opposite direction.

---

## How It Works (Behind the Scenes)

1. **Validation & Iteration**: The Java engine ensures dates are valid and computes the standard Macaulay Duration using the exact same iterative cash-flow discounting loop as `@CalcMgrExcelDURATION`.
2. **Modification Math**: It takes that standard Macaulay Duration and applies the volatility modifier: `Macaulay / (1 + (yld / frequency))`.
3. **Return**: Passes the final volatility metric back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Volatility on a Standard Semi-Annual Bond

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Dec 31, 2028 (5 Years remaining)
   Coupon: 5% (0.05)
   Yield: 6% (0.06)
   Freq: 2 (Semi-Annual)
   Basis: 0 (US 30/360)
   Result: ~ 4.28
*/
"Modified_Duration" = @CalcMgrExcelMDURATION(20240101, 20281231, 0.05, 0.06, 2, 0);
```

---

## Practical Examples

### Example 1: Stress-Testing a Bond Portfolio (Rate Shock)

**Scenario**: A corporate treasury holds a large portfolio of bonds. The Chief Risk Officer wants a stress-test scenario in the Essbase model: "What is the exact dollar loss to our portfolio if interest rates rise by 1.5% (150 basis points)— The FP&A team uses `MDURATION` to calculate the price elasticity, and multiplies it by the shock factor.

```essbase
FIX("Scenario_Rate_Shock_Up_150bps", "Working", @LEVEL0("Debt_Investments"))
    
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date" AND "Current_Market_Value" > 0)
        
        /* 1. Calculate the price elasticity multiplier */
        VAR vModDuration = @CalcMgrExcelMDURATION(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Coupon_Rate", 
            "Yield_To_Maturity", 
            "Payment_Frequency", 
            0 /* Assuming US 30/360 Basis */
        );
        
        /* 
           2. Calculate the Percentage Price Change.
           Formula: -Modified_Duration * Change_In_Yield 
           Change in yield is +0.015 (1.5%)
        */
        VAR vPctPriceChange = -1 * vModDuration * 0.015;
        
        /* 3. Calculate the new stressed value of the bond */
        "Stressed_Market_Value" = "Current_Market_Value" * (1 + vPctPriceChange);
        
        /* 4. Store the exact dollar loss */
        "Stress_Test_Value_At_Risk" = "Current_Market_Value" - "Stressed_Market_Value";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with Macaulay Duration | Expecting "Time in Years" | `DURATION` measures *time*. `MDURATION` measures *price elasticity*. While they are mathematically linked, and the resulting numbers look similar (e.g., 4.41 vs 4.28), they mean completely different things. Ensure you know which metric your Treasury department is actually asking for |
| Whole Number Rates | Passing `5` for Coupon | The `coupon` and `yld` parameters expect decimals. If the rate is 5%, you must pass `0.05`. Passing `5` will calculate volatility based on a 500% interest rate, destroying the calculation |
| Large Rate Shocks | Assuming perfection | Modified Duration is a *linear approximation* of a bond's price curve (which is actually convex). It is highly accurate for small interest rate changes (e.g., 1%). If you are simulating a massive 5% rate shock, Modified Duration will slightly overstate the loss. Advanced models must also calculate Convexity to adjust for this |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelDURATION`](./@CalcMgrExcelDURATION.md) | Calculates standard Macaulay Duration (weighted time), which acts as the mathematical numerator for this function |
| [`@CalcMgrExcelPRICE`](../12_CalcMgr_Excel_Financial/@CalcMgrExcelPRICE.md) | Calculates the underlying price of the bond |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelmduration.html)
