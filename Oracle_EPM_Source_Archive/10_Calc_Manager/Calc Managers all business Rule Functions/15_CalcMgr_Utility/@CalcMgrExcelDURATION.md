# @CalcMgrExcelDURATION

## Overview

`@CalcMgrExcelDURATION` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DURATION` function directly inside an Essbase calculation script. 
It calculates the **Macaulay Duration** of a security that pays periodic interest (like a bond). Duration measures the weighted average time (in years) it takes for an investor to receive the bond's cash flows (both interest and principal), serving as a critical metric for assessing a bond's price sensitivity to interest rate changes.

### Why Does This Function Exist—

In advanced Treasury, Banking, and Asset Management models, calculating a bond's Duration is vital for hedging interest rate risk. The math required to calculate Macaulay Duration is intensely complex. It involves calculating the Present Value of *every single future coupon payment*, weighting each one by the time until it is received, summing those weighted values, and dividing by the bond's total current market price. 
Attempting to build this iterative, discounting loop manually using standard Essbase equations is incredibly difficult, slow, and almost impossible to dynamically scale based on changing maturity dates. `@CalcMgrExcelDURATION` resolves this by offloading the entire iterative discounting loop to the Java engine, returning the exact Macaulay Duration in milliseconds.

### When to Use It

- **Asset/Liability Management (ALM)**: Matching the duration of a bank's assets (loans) to the duration of its liabilities (deposits) to neutralize interest rate risk.
- **Fixed Income Modeling**: Evaluating the volatility of a corporate bond portfolio (longer duration = higher price volatility when rates change).
- Whenever you need to migrate an Excel spreadsheet containing the `DURATION` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDURATION(settlement, maturity, coupon, yld, frequency, basis)
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

Returns the Macaulay Duration expressed in **Years**.
- e.g., A return value of `4.25` means the weighted average time to receive the bond's cash flows is 4.25 years.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `frequency` is exactly 1, 2, or 4, and `basis` is between 0 and 4. `settlement` must be chronologically before `maturity`.
2. **Schedule Generation**: The engine internally extrapolates the entire future coupon payment schedule based on the maturity and frequency.
3. **Iterative Discounting**: It loops through every future cash flow, discounts it back to the settlement date using the `yld` parameter, and multiplies it by the time (in years) until it occurs.
4. **Aggregation**: It sums all those weighted values together, and divides them by the unweighted total Present Value (which represents the bond's current clean price).
5. **Return**: Passes the final duration metric (in years) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Duration on a Standard Semi-Annual Bond

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Dec 31, 2028 (5 Years remaining)
   Coupon: 5% (0.05)
   Yield: 6% (0.06)
   Freq: 2 (Semi-Annual)
   Basis: 0 (US 30/360)
   Result: ~ 4.41 Years
*/
"Macaulay_Duration" = @CalcMgrExcelDURATION(20240101, 20281231, 0.05, 0.06, 2, 0);
```

---

## Practical Examples

### Example 1: Identifying High-Risk Bonds in a Portfolio

**Scenario**: A corporate treasury holds dozens of different bonds. If interest rates rise by 1%, the price of long-duration bonds will collapse much harder than short-duration bonds. The treasurer needs a report that flags any bond with a duration greater than 7 years, allowing them to hedge or sell the asset.

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Investments"))
    
    /* Ensure the investment hasn't matured and has valid parameters */
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date" AND "Coupon_Rate" > 0)
        
        /* Calculate Macaulay Duration */
        "Bond_Duration_Years" = @CalcMgrExcelDURATION(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Coupon_Rate", 
            "Yield_To_Maturity", 
            "Payment_Frequency", 
            0 /* Assuming US 30/360 Basis */
        );
        
        /* Evaluate Risk Profile */
        IF("Bond_Duration_Years" > 7.0)
            "Interest_Rate_Risk_Flag" = 3; /* High Risk */
        ELSEIF("Bond_Duration_Years" > 3.0)
            "Interest_Rate_Risk_Flag" = 2; /* Medium Risk */
        ELSE
            "Interest_Rate_Risk_Flag" = 1; /* Low Risk */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Whole Number Rates | Passing `5` for Coupon | The `coupon` and `yld` parameters expect decimals. If the rate is 5%, you must pass `0.05`. Passing `5` will calculate the duration based on a 500% interest rate, which will artificially crash the duration near 0. |
| Passing Java Dates | `@CalcMgrExcelDURATION(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Confusing Macaulay with Modified Duration | Expecting price volatility | `DURATION` calculates *Macaulay* duration (weighted time). If you want *Modified* duration (which directly measures the % price drop for a 1% change in yield), you must use `@CalcMgrExcelMDURATION`. |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelMDURATION`](./@CalcMgrExcelMDURATION.md) | Calculates the *Modified* Duration, which is mathematically derived from Macaulay Duration, used specifically for measuring price elasticity |
| [`@CalcMgrExcelPRICE`](./@CalcMgrExcelPRICE.md) | Calculates the underlying price of the bond using the exact same discounting engine |
| [`@CalcMgrExcelYIELD`](./@CalcMgrExcelYIELD.md) | Calculates the true Yield (often used as the `yld` input parameter if it wasn't externally provided) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelduration.html)
