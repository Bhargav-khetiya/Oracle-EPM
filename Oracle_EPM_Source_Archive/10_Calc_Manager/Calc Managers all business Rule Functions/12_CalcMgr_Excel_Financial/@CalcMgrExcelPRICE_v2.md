# @CalcMgrExcelPRICE

## Overview

`@CalcMgrExcelPRICE` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `PRICE` function directly inside an Essbase calculation script. 
It calculates the **Clean Price** of a standard coupon-bearing bond (per $100 of face value) that pays periodic interest. 

### Why Does This Function Exist—

In corporate treasury and investment portfolios, bonds are constantly traded on the secondary market. If a company bought a 10-year bond 3 years ago that pays a 5% coupon, but current market interest rates (the Yield to Maturity) have risen to 7%, the bond is now worth less than what they paid for it. 
Calculating the exact current market price of that bond requires discounting all future coupon payments back to today's settlement date, adjusting for fractional days (accrued interest), and summing the discounted face value. This requires a massive iterative calculus loop and complex calendar math (e.g., NASD 30/360). 
`@CalcMgrExcelPRICE` completely offloads this entire discounting and calendrical algorithm to the Java engine. It instantly returns the bond's clean price per $100 face value, ensuring your EPM Mark-to-Market (MTM) calculations exactly match your bank's Excel models.

### When to Use It

- **Mark-to-Market Valuation**: Revaluing a corporate treasury portfolio at month-end based on current market yields.
- **Fixed Income Strategy**: Calculating the purchase price of a bond in the secondary market to achieve a specific target yield.
- Whenever you need to migrate an Excel spreadsheet containing the `PRICE` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelPRICE(settlement, maturity, rate, yld, redemption, frequency, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the security is traded or evaluated. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the security expires. Must be > `settlement`. |
| `rate` | Numeric | ✅ Yes | The bond's stated annual coupon interest rate (e.g., `0.05` for 5%). |
| `yld` | Numeric | ✅ Yes | The bond's current annual yield-to-maturity (e.g., `0.07` for 7%). |
| `redemption` | Numeric | ✅ Yes | The redemption value per $100 face value. (Usually `100`). |
| `frequency` | Numeric | ✅ Yes | The number of coupon payments per year: Annual = `1`, Semi-annual = `2`, Quarterly = `4`. |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the clean price of the bond per $100 of face value.
- E.g., Returns `92.50`. If you own `$1,000,000` of this bond in face value, the actual market value is `$1,000,000 * (92.50 / 100) = $925,000`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, rates are valid decimals, and the settlement date is chronologically before the maturity date.
2. **Iterative Discounting**: The engine determines exactly how many coupon periods remain between the settlement and maturity dates based on the `frequency`. It discounts each remaining coupon payment, plus the final `redemption` value, back to the settlement date using the `yld`.
3. **Accrued Interest Removal**: Because `PRICE` calculates the *clean* price, it mathematically strips out any accrued interest that belongs to the seller for the current fractional period.
4. **Return**: Passes the final calculated price metric back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Valuing a Standard Corporate Bond

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Dec 31, 2028 (5 Years)
   Coupon: 5% (0.05)
   Current Yield: 7% (0.07) -> Yield is higher than coupon, so price drops below 100.
   Redemption: 100
   Freq: 2 (Semi-Annual)
   Basis: 0 (US 30/360)
   Result: ~ 91.68
*/
"Bond_Clean_Price" = @CalcMgrExcelPRICE(20240101, 20281231, 0.05, 0.07, 100, 2, 0);
```

---

## Practical Examples

### Example 1: Month-End Portfolio Mark-to-Market

**Scenario**: At the end of every month, a corporate treasury must report the fair market value of its bond holdings. The system stores the `"Face_Value"` and `"Coupon_Rate"`. The FP&A team inputs the current market `"Yield_To_Maturity"` based on Bloomberg data. The system uses `PRICE` to calculate the current value, and books the unrealized gain/loss.

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Investments"))
    
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date" AND "Face_Value" > 0)
        
        /* 1. Calculate the Clean Price per $100 Face Value */
        VAR vCleanPrice = @CalcMgrExcelPRICE(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Coupon_Rate", 
            "Yield_To_Maturity", 
            100, /* Standard Redemption */
            "Payment_Frequency", 
            0    /* Assuming US 30/360 Basis */
        );
        
        /* 2. Calculate Total Market Value (Scale the price against the Face Value) */
        "Current_Market_Value" = "Face_Value" * (vCleanPrice / 100);
        
        /* 3. Calculate Unrealized Gain/Loss against the Book Value */
        "Unrealized_Gain_Loss" = "Current_Market_Value" - "Historical_Book_Value";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Whole Number Rates | Passing `5` for Coupon | The `rate` and `yld` parameters expect decimals. If the rate is 5%, you must pass `0.05`. Passing `5` will calculate the price of a bond paying 500% interest, resulting in an absurdly high price |
| Forgetting to Scale | Using `92.5` as the total value | `PRICE` strictly returns the price *per $100 of face value*. It does not return the total dollar value of your specific holding. You MUST divide the output by 100 and multiply it by your total Face Value |
| Clean vs Dirty Price | Expecting the invoice price | `PRICE` calculates the *clean* price (market value excluding accrued interest). When you actually buy a bond mid-period, you pay the *dirty* price (clean price + accrued interest). If you are modeling cash outflows for a purchase, you must calculate accrued interest using `@CalcMgrExcelACCRINT` and add it to the result of `PRICE` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelYIELD`](./@CalcMgrExcelYIELD.md) | The exact inverse function: Calculates the Yield to Maturity based on a known Market Price |
| [`@CalcMgrExcelACCRINT`](../15_CalcMgr_Utility/@CalcMgrExcelACCRINT.md) | Calculates the Accrued Interest, which must be added to `PRICE` to find the total invoice amount of a trade |
| [`@CalcMgrExcelPRICEDISC`](./@CalcMgrExcelPRICEDISC.md) | Calculates the price for a zero-coupon discount bond (like a T-Bill) rather than a coupon-bearing bond |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelprice.html)
