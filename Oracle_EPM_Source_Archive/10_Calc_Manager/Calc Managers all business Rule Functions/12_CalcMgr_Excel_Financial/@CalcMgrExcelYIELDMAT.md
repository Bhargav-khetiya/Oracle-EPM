# @CalcMgrExcelYIELDMAT

## Overview

`@CalcMgrExcelYIELDMAT` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `YIELDMAT` function directly inside an Essbase calculation script. 
It calculates the **Annual Yield** of a security that pays interest *solely at maturity* (such as certain types of CDs, savings bonds, or custom fixed-income instruments).

### Why Does This Function Exist—

Unlike standard corporate bonds (`YIELD`) which pay out periodic coupons (e.g., every 6 months), and unlike zero-coupon bonds (`YIELDDISC`) which pay no interest but are sold at a deep discount, "Yield-at-Maturity" securities are unique. They are often issued at $100, accrue interest silently over their lifespan, and then pay out a single massive lump sum of the Principal + All Accrued Interest on the exact maturity date. 
If a corporate treasury buys one of these securities on the secondary market mid-way through its lifespan, they need to know their true annualized yield. 
Because there are no periodic cash flows to discount, standard `IRR` or `YIELD` functions fail completely. The math requires calculating the exact days between issuance, settlement, and maturity, and running a specialized fractional year compounding formula: `(Total Payout / Current Price) - 1`, scaled by the remaining days. `@CalcMgrExcelYIELDMAT` instantly processes this calendar math and yields the exact annualized return, ensuring parity with Treasury models.

### When to Use It

- **Specialized Portfolios**: Valuing municipal bonds or certificates of deposit that compound interest but defer all cash payments until the final expiration date.
- **Yield Validation**: Verifying the broker's quoted return on a secondary-market purchase of a maturity-interest security.
- Whenever you need to migrate an Excel spreadsheet containing the `YIELDMAT` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelYIELDMAT(issue, settlement, maturity, rate, pr, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `issue` | Integer | ✅ Yes | The issue date (`YYYYMMDD`). The date the security was originally created by the issuer. |
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date you actually purchased the security on the secondary market. Must be >= `issue`. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date it expires and pays out. Must be > `settlement`. |
| `rate` | Numeric | ✅ Yes | The stated annual interest rate on the security (e.g., `0.05` for 5%). |
| `pr` | Numeric | ✅ Yes | The price you paid per $100 of face value (e.g., `102.50`). Must be > 0. |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Annualized Yield as a decimal.
- E.g., Returns `0.043` (representing a 4.3% true yield).

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `pr` > 0, and checks the strict chronological order: `issue` <= `settlement` < `maturity`.
2. **Day-Count Math**: It calculates three specific time durations using the specified calendar `basis`:
   - `DIM`: Days from Issue to Maturity (used to calculate the final total payout).
   - `DSM`: Days from Settlement to Maturity (used to scale the yield).
   - `DIS`: Days from Issue to Settlement (used to calculate accrued interest already baked into the price).
3. **Yield Equation**: It calculates the total cash that will be received at maturity (100 + interest). It divides that by the cash paid (`pr` + accrued interest). It subtracts 1, and scales the result by `(Year_Basis / DSM)`.
4. **Return**: Passes the finalized yield decimal back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Valuing a Multi-Year CD

```essbase
/* 
   Issue: Jan 1, 2020
   Settlement: Jan 1, 2024 (Bought it 4 years late)
   Maturity: Dec 31, 2024 (Expires in 1 year)
   Rate: 5% (0.05)
   Price: 115.00 (Paying a premium because of the massive accrued interest)
   Basis: 0 (US 30/360)
   Result: Calculates the true Yield of this 1-year holding period.
*/
"CD_Yield" = @CalcMgrExcelYIELDMAT(20200101, 20240101, 20241231, 0.05, 115.00, 0);
```

---

## Practical Examples

### Example 1: Standardizing Portfolio Yields

**Scenario**: A corporate treasury holds a mix of standard bonds (`YIELD`), discount notes (`YIELDDISC`), and deferred-interest CDs (`YIELDMAT`). The CFO wants a single `"True_Yield"` metric on the dashboard. The script must detect the `"Asset_Class"` and apply the correct Excel math function dynamically.

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Investments"))
    
    IF("Purchase_Price_Per_100" > 0 AND "Purchase_Date" != #MISSING)
        
        IF(@ISMBR("Standard_Bonds"))
            
            "True_Yield" = @CalcMgrExcelYIELD( /* parameters */ );
            
        ELSEIF(@ISMBR("Discount_Notes"))
            
            "True_Yield" = @CalcMgrExcelYIELDDISC( /* parameters */ );
            
        ELSEIF(@ISMBR("Deferred_Interest_CDs"))
            
            /* Use YIELDMAT because interest is only paid at the very end */
            "True_Yield" = @CalcMgrExcelYIELDMAT(
                "Original_Issue_Date",
                "Purchase_Date", 
                "Maturity_Date", 
                "Stated_Interest_Rate",
                "Purchase_Price_Per_100",
                0 /* Assume 30/360 basis */
            );
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Issue Date | Passing `#MISSING` or `0` for the issue date | Unlike standard `YIELD` (which only cares about the current purchase date and maturity), `YIELDMAT` absolutely requires the original `issue` date. The algorithm needs it to calculate exactly how much total interest has accrued on the security since its inception. If you omit it, the function fails |
| Using for Coupon Bonds | Valuing a 10-year Corporate Bond | `YIELDMAT` is exclusively for securities that pay interest exactly *once* at the very end of their life. If the security pays periodic interest coupons (e.g., semi-annually), this function will completely ignore them and massively understate the yield. You must use `@CalcMgrExcelYIELD` instead |
| Total Value Instead of Price | Passing `$10,000,000` | The `pr` parameter strictly expects the clean price *per $100 of face value* (e.g., `115.00`). If you pass the total cash value of your trade, the algebra fails entirely |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPRICEMAT`](./@CalcMgrExcelPRICEMAT.md) | The exact inverse function: Calculates the Price based on a known Market Yield |
| [`@CalcMgrExcelYIELD`](./@CalcMgrExcelYIELD.md) | Calculates the yield of a standard bond that pays periodic coupons |
| [`@CalcMgrExcelYIELDDISC`](./@CalcMgrExcelYIELDDISC.md) | Calculates the yield of a zero-coupon discounted security (which has no stated interest rate) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelyieldmat.html)
