# @CalcMgrExcelRECEIVED

## Overview

`@CalcMgrExcelRECEIVED` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `RECEIVED` function directly inside an Essbase calculation script. 
It calculates the **Total Amount Received at Maturity** for a fully invested security, typically a discount bond or short-term promissory note.

### Why Does This Function Exist?

When a corporate treasury department buys a short-term discount note, they pay a flat initial investment amount today. They are guaranteed a specific discount yield (interest rate). However, they need to calculate exactly how much physical cash will be deposited back into their bank account on the maturity date. 
To calculate this manually in Essbase, a developer must calculate the exact number of days between the settlement date and the maturity date based on specific banking calendars (e.g., Actual/360), and then apply the inverse discount formula: `Investment / (1 - (Discount * Days / YearBase))`. 
`@CalcMgrExcelRECEIVED` wraps this entire calendrical and algebraic equation into a single Java call. It takes the investment amount and the discount rate, handles the day-count math internally, and returns the final payout amount, perfectly matching legacy Treasury models.

### When to Use It

- **Cash Flow Forecasting**: Projecting exactly how much cash will flow back into the corporate treasury accounts when short-term commercial paper matures.
- **Yield Validation**: Verifying that a broker's promised payout matches the mathematical reality of the stated discount rate and the calendar.
- Whenever you need to migrate an Excel spreadsheet containing the `RECEIVED` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelRECEIVED(settlement, maturity, investment, discount, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the security is purchased. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the security pays out. Must be > `settlement`. |
| `investment` | Numeric | ✅ Yes | The amount of money paid on the settlement date (e.g., `1000000`). Must be > 0. |
| `discount` | Numeric | ✅ Yes | The security's annual discount rate (e.g., `0.05` for 5%). |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the total cash amount received at maturity.
- This includes both the return of the original principal *and* the earned interest. 

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `investment` > 0, and `discount` > 0. The settlement date must be chronologically before the maturity date.
2. **Day-Count Math**: It calculates the exact number of days remaining (`DSM`) between the settlement and maturity dates using the specified calendar `basis`.
3. **Discount Equation**: It executes the standard Treasury payout algorithm: `investment / (1 - (discount * (DSM / Year_Basis)))`.
4. **Return**: Passes the resulting final dollar payout back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Forecasting T-Bill Payout (Actual/360)

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Jun 30, 2024 (181 days remaining)
   Investment: $1,000,000
   Discount Rate: 5% (0.05)
   Basis: 2 (Actual/360 - The standard for US T-Bills)
   Result: ~ $1,025,788.08
*/
"Cash_Received_At_Maturity" = @CalcMgrExcelRECEIVED(20240101, 20240630, 1000000, 0.05, 2);
```

---

## Practical Examples

### Example 1: Rolling Treasury Cash Flow Forecast

**Scenario**: A corporate treasury sweeps excess cash into various short-term commercial paper instruments. They record the `"Initial_Investment_Amount"` on the `"Settlement_Date"`. The CFO needs a rolling cash flow forecast to see exactly when and how much cash will re-enter the company's operating accounts to fund payroll. The FP&A team uses `RECEIVED` to calculate the final payout, and dynamically pushes that value into the month matching the `"Maturity_Date"`.

```essbase
FIX("FY25", "Working", @LEVEL0("Short_Term_Notes"))
    
    IF("Maturity_Date" != #MISSING AND "Initial_Investment_Amount" > 0)
        
        /* 1. Calculate the exact cash payout at maturity */
        VAR vTotalPayout = @CalcMgrExcelRECEIVED(
            "Settlement_Date", 
            "Maturity_Date", 
            "Initial_Investment_Amount", 
            "Market_Discount_Rate", 
            2 /* Actual/360 Basis */
        );
        
        /* 
           2. Extract the month integer from the maturity date 
           e.g., 20240630 -> 6 
        */
        VAR vMaturityMonth = @CalcMgrExcelMONTH("Maturity_Date");
        
        /* 3. Push the payout to the correct forecast month */
        IF(vMaturityMonth == 1)
            "Cash_Inflows"->"Jan" = vTotalPayout;
        ELSEIF(vMaturityMonth == 2)
            "Cash_Inflows"->"Feb" = vTotalPayout;
        /* ... continued for all months ... */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for Coupon Bonds | Valuing a 10-year Treasury Note | `RECEIVED` is exclusively designed for fully-invested, zero-coupon discounted securities. If the security pays periodic interest coupons along the way, this function will completely ignore them and massively understate your cash flow. It is strictly for investments where all profit is paid in a single lump sum at the end |
| Whole Number Rates | Passing `5` for Discount Rate | The `discount` parameter expects a decimal. If the rate is 5%, you must pass `0.05`. Passing `5` will cause the formula's denominator to become negative, resulting in a massive negative payout, completely destroying the calculation |
| Negative Investment | Passing `-1000000` | Unlike functions like `IRR` or `FV` which rely on strict cash-flow sign conventions, `RECEIVED` expects an absolute positive value for the investment. If you pass a negative number, the payout will return negative |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelINTRATE`](./@CalcMgrExcelINTRATE.md) | The inverse logic: If you already know the Investment amount and the Final Received amount, this calculates the Interest Rate |
| [`@CalcMgrExcelPRICEDISC`](./@CalcMgrExcelPRICEDISC.md) | Calculates the *Price* (the initial investment required) of a discount bond per $100 face value |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelreceived.html)
