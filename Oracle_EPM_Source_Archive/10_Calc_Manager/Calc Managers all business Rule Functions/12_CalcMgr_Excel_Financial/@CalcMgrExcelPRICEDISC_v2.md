# @CalcMgrExcelPRICEDISC

## Overview

`@CalcMgrExcelPRICEDISC` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `PRICEDISC` function directly inside an Essbase calculation script. 
It calculates the **Price** of a discounted security (like a zero-coupon bond or a short-term Treasury Bill) per $100 of face value. 

### Why Does This Function Exist—

Unlike standard corporate bonds that pay periodic interest coupons (`@CalcMgrExcelPRICE`), short-term discounted securities pay absolutely no interest during their lifespan. Instead, they are sold at a deep discount (e.g., $95) and mature at their full face value (e.g., $100). The profit is entirely derived from that $5 difference.
To calculate the current market price of a T-Bill based on today's interest rates, you must calculate the exact number of days remaining until maturity, apply the specific calendar basis (e.g., Actual/360), and discount the $100 redemption value back to today. Doing this manually in Essbase is highly tedious and brittle.
`@CalcMgrExcelPRICEDISC` offloads this exact calculation to the Java engine, handling the calendar math and returning the exact market price instantly, ensuring your EPM models align perfectly with legacy Treasury Excel sheets.

### When to Use It

- **Treasury Management**: Valuing short-term commercial paper, zero-coupon bonds, or Treasury Bills for month-end mark-to-market reporting.
- **Cash Flow Modeling**: Calculating exactly how much cash is required *today* to purchase a T-Bill that will yield a specific discount rate upon maturity.
- Whenever you need to migrate an Excel spreadsheet containing the `PRICEDISC` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelPRICEDISC(settlement, maturity, discount, redemption, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the security is traded or evaluated. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the security expires. Must be > `settlement`. |
| `discount` | Numeric | ✅ Yes | The security's annual discount rate (e.g., `0.05` for 5%). |
| `redemption` | Numeric | ✅ Yes | The redemption value per $100 face value. (Almost always `100`). |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the price of the discounted security per $100 of face value.
- E.g., Returns `97.50`. If you want to buy `$1,000,000` of this T-Bill, you will pay exactly `$975,000`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, the discount is a valid decimal, and the settlement date is chronologically before the maturity date.
2. **Day-Count Math**: It calculates the exact number of days remaining (`DSM`) between the settlement and maturity dates using the specified calendar `basis`.
3. **Discount Equation**: It executes the standard Treasury discount algorithm: `redemption - (discount * redemption * (DSM / Year_Basis))`.
4. **Return**: Passes the finalized price metric back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Valuing a Treasury Bill (Actual/360)

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Jun 30, 2024 (181 days remaining)
   Discount Rate: 5% (0.05)
   Redemption: 100
   Basis: 2 (Actual/360 - The standard for US T-Bills)
   Result: ~ 97.486
*/
"TBill_Price" = @CalcMgrExcelPRICEDISC(20240101, 20240630, 0.05, 100, 2);
```

---

## Practical Examples

### Example 1: Cash Sweep Investment Planning

**Scenario**: A corporate treasury has a mandate to sweep excess cash into 90-day commercial paper. The CFO wants to know exactly how much cash it will cost *today* to purchase `$50,000,000` (Face Value) of commercial paper yielding a `4.5%` discount rate, maturing on March 31st.

```essbase
FIX("FY25", "Working", @LEVEL0("Cash_Equivalents"))
    
    IF("Target_Face_Value" > 0)
        
        /* 1. Calculate the Price per $100 Face Value */
        VAR vPricePer100 = @CalcMgrExcelPRICEDISC(
            "Assumptions"->"Current_Settlement_Date", 
            "Target_Maturity_Date", 
            "Market_Discount_Rate", 
            100, /* Standard Redemption */
            2    /* Actual/360 Basis */
        );
        
        /* 2. Calculate Total Cash Required for the trade */
        "Required_Cash_Outflow" = "Target_Face_Value" * (vPricePer100 / 100);
        
        /* Note: For a $50M target at 4.5% over 90 days, the outflow will be ~$49.43M */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for Coupon Bonds | Valuing a 10-year Treasury Note | `PRICEDISC` is exclusively for zero-coupon, discounted securities. If the security pays periodic interest coupons along the way, this function will massively understate the value. You must use `@CalcMgrExcelPRICE` instead |
| Whole Number Rates | Passing `5` for Discount Rate | The `discount` parameter expects a decimal. If the rate is 5%, you must pass `0.05`. Passing `5` will calculate a massive negative price, destroying the calculation |
| Forgetting to Scale | Using `97.5` as the total value | Like all price functions, `PRICEDISC` strictly returns the price *per $100 of face value*. You MUST divide the output by 100 and multiply it by your total actual Face Value to find the true dollar amount |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelDISC`](../15_CalcMgr_Utility/@CalcMgrExcelDISC.md) | The exact inverse function: Calculates the Discount Rate based on a known Market Price |
| [`@CalcMgrExcelPRICE`](./@CalcMgrExcelPRICE.md) | Calculates the price of a standard bond that pays periodic interest coupons |
| [`@CalcMgrExcelPRICEMAT`](./@CalcMgrExcelPRICEMAT.md) | Calculates the price of a security that pays interest solely at maturity |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelpricedisc.html)
