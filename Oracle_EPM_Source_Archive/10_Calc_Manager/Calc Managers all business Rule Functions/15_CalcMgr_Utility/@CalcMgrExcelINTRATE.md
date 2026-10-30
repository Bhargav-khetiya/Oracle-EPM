# @CalcMgrExcelINTRATE

## Overview

`@CalcMgrExcelINTRATE` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `INTRATE` function directly inside an Essbase calculation script. 
It calculates the **Interest Rate** for a fully invested security, typically used for short-term discount bonds or promissory notes where a flat amount is invested upfront, and a larger flat amount is received at maturity, with no periodic coupon payments in between.

### Why Does This Function Exist?

When a company buys a zero-coupon bond or a short-term commercial paper, they don't receive an explicit "5% annual yield" quote. Instead, they are told: "If you pay us $9,500 today, we will pay you $10,000 in exactly 215 days." 
To determine if this is a good investment, the Treasury department must mathematically convert that $500 profit over 215 days into an annualized interest rate. Doing this manually in Essbase requires the algebraic formula: `((Redemption - Investment) / Investment) * (YearBase / DaysBetween)`. While technically possible, configuring the `DaysBetween` to correctly adhere to NASD 30/360 or Actual/360 calendar rules using raw Essbase `IF` statements is incredibly brittle. 
`@CalcMgrExcelINTRATE` wraps this entire mathematical and calendrical logic into a single Java call, instantly returning the exact annualized interest rate and ensuring perfect parity with legacy Treasury spreadsheets.

### When to Use It

- **Corporate Treasury**: Evaluating the true annualized yield on short-term discount paper or zero-coupon bonds.
- **Investment Portfolios**: Normalizing the return on disparate short-term investments so they can be compared against a standard benchmark (like a 3-month Treasury Bill yield).
- Whenever you need to migrate an Excel spreadsheet containing the `INTRATE` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelINTRATE(settlement, maturity, investment, redemption, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the money is invested. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the investment pays out. Must be > `settlement`. |
| `investment` | Numeric | ✅ Yes | The total amount of money invested (paid) on the settlement date. Must be > 0. |
| `redemption` | Numeric | ✅ Yes | The total amount of money received on the maturity date. Must be > 0. |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the annualized interest rate as a decimal.
- E.g., `0.0525` implies a 5.25% annualized interest rate. You typically want to wrap the output in `@ROUND(..., 4)` to keep the reports clean.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `investment` > 0, `redemption` > 0, and `basis` is between 0 and 4. `settlement` must be chronologically before `maturity`.
2. **Day-Count Math**: It calculates the exact number of days between `settlement` and `maturity` (`DSM`) using the specified calendar `basis`.
3. **Interest Equation**: It executes the standard algorithm: `((redemption - investment) / investment) * (Year_Basis / DSM)`.
4. **Return**: Passes the resulting annualized decimal rate back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Actual/360 Short-Term Paper

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Dec 31, 2024
   Investment: $9,500
   Redemption: $10,000
   Basis: 2 (Actual/360 - common for T-Bills)
*/
"Calculated_Interest_Rate" = @CalcMgrExcelINTRATE(20240101, 20241231, 9500, 10000, 2);
```

---

## Practical Examples

### Example 1: Ranking Short-Term Investments by True Yield

**Scenario**: A treasury model ingests a list of potential short-term promissory notes. Each note has a different cost (`Investment`), a different payout (`Redemption`), and a different lifespan (`Maturity`). To determine which note is actually the most profitable, the system calculates the annualized `INTRATE` for every single option, and stores it so the dashboard can rank them.

```essbase
FIX("FY25", "Working", @LEVEL0("Short_Term_Notes"))
    
    /* Ensure the note is valid and hasn't already matured */
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date" AND "Initial_Investment" > 0)
        
        /* Calculate the annualized Interest Rate using Actual/360 basis */
        "Annualized_Yield" = @ROUND(
            @CalcMgrExcelINTRATE(
                "Assumptions"->"Current_Settlement_Date", 
                "Maturity_Date", 
                "Initial_Investment", 
                "Redemption_Value", 
                2 /* Basis 2 */
            )
        , 4);
        
        /* Flag investments yielding higher than the corporate hurdle rate */
        IF("Annualized_Yield" > "Corporate_Hurdle_Rate")
            "Buy_Recommendation" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Cash Flows | Passing `-9500` for the Investment | Unlike functions such as `IRR` or `FV` which strictly rely on cash flow sign conventions (outflows are negative), `INTRATE` expects absolute positive values for both the investment and the redemption. Passing a negative number will cause the function to fail |
| Chronological Reversal | Settlement Date > Maturity Date | If the settlement date occurs *after* the maturity date, the math evaluates to a negative day count, and the function will fail |
| Using for Coupon Bonds | Using INTRATE for a 10-year Treasury | `INTRATE` is designed for fully invested, non-coupon-bearing securities (where all profit is derived from the difference between the buy price and the final payout). If the bond pays periodic interest coupons along the way, this function will massively understate the true yield. Use `@CalcMgrExcelYIELD` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelYIELD`](./@CalcMgrExcelYIELD.md) | Calculates the yield on a security that pays periodic interest coupons (the standard alternative to `INTRATE`) |
| [`@CalcMgrExcelDISC`](./@CalcMgrExcelDISC.md) | Calculates the Discount Rate (which is mathematically similar, but bases the denominator on the redemption value rather than the investment value) |
| [`@CalcMgrExcelPRICEMAT`](./@CalcMgrExcelPRICEMAT.md) | Calculates the price of a security that pays interest at maturity |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelintrate.html)
