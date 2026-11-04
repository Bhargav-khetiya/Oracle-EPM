# @CalcMgrExcelTBILLPRICE

## Overview

`@CalcMgrExcelTBILLPRICE` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `TBILLPRICE` function directly inside an Essbase calculation script. 
It calculates the **Price** of a Treasury Bill (T-Bill) per $100 of face value.

### Why Does This Function Exist—

Treasury Bills do not pay periodic interest. Instead, they are sold at a discount and mature at face value. If you want to buy a $1,000,000 T-Bill that matures in 90 days and offers a 4% bank discount rate, you don't pay $1,000,000 today. You pay the "discounted" price. 
To calculate exactly how much physical cash you must transfer to the broker today to secure that T-Bill, you must calculate the price per $100 of face value using the exact number of days remaining until maturity, assuming a 360-day banking year.
`@CalcMgrExcelTBILLPRICE` completely offloads this calendar math and discounting formula to the Java engine. It returns the exact price instantly, ensuring your EPM cash-flow models perfectly match your Treasury department's legacy Excel sheets.

### When to Use It

- **Cash Flow Forecasting**: Calculating exactly how much cash is required *today* to purchase a specific volume of T-Bills based on current market discount rates.
- **Mark-to-Market Valuation**: Revaluing a corporate treasury's short-term T-Bill portfolio at month-end based on changing market yields.
- Whenever you need to migrate an Excel spreadsheet containing the `TBILLPRICE` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelTBILLPRICE(settlement, maturity, discount)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the T-Bill is purchased or evaluated. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the T-Bill expires. Must be > `settlement`. Must be within 1 year of settlement. |
| `discount` | Numeric | ✅ Yes | The quoted bank discount rate of the T-Bill (e.g., `0.05` for 5%). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the purchase price of the T-Bill per $100 of face value.
- E.g., Returns `97.50`. If you want to buy `$1,000,000` of this T-Bill, you will pay exactly `$975,000`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `discount` > 0, and the maturity is less than 365 days after the settlement.
2. **Day-Count Math**: It calculates the exact number of days remaining (`DSM`) between the settlement and maturity dates, assuming a standard Actual/360 T-Bill calendar basis.
3. **Discount Equation**: It executes the standard Treasury discount algorithm: `100 * (1 - (discount * (DSM / 360)))`.
4. **Return**: Passes the finalized price metric back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Forecasting Cash Outflow for a 6-Month T-Bill

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Jun 30, 2024 (181 days remaining)
   Discount Rate: 5% (0.05)
   Result: Calculates the price per $100. Returns ~ 97.486
*/
"TBill_Price_Per_100" = @CalcMgrExcelTBILLPRICE(20240101, 20240630, 0.05);
```

---

## Practical Examples

### Example 1: Cash Sweep Investment Planning

**Scenario**: A corporate treasury sweeps excess cash into 90-day Treasury Bills. The CFO wants to know exactly how much cash it will cost *today* to secure `$50,000,000` (Face Value) of T-Bills yielding a `4.5%` discount rate, maturing on March 31st.

```essbase
FIX("FY25", "Working", @LEVEL0("Cash_Equivalents"))
    
    IF("Target_Face_Value" > 0 AND "Market_Discount_Rate" > 0)
        
        /* 1. Calculate the Price per $100 Face Value */
        VAR vPricePer100 = @CalcMgrExcelTBILLPRICE(
            "Assumptions"->"Current_Settlement_Date", 
            "Target_Maturity_Date", 
            "Market_Discount_Rate"
        );
        
        /* 
           2. Calculate Total Cash Required for the trade.
           Divide by 100 to scale the price, then multiply by the Target Face Value.
        */
        "Required_Cash_Outflow" = "Target_Face_Value" * (vPricePer100 / 100);
        
        /* Note: For a $50M target at 4.5% over 90 days, the outflow will be ~$49.43M */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Over 1 Year Maturity | Passing dates 3 years apart | By US Treasury definition, T-Bills have a maturity of 1 year or less (52 weeks). The `TBILLPRICE` formula relies on this assumption. If the maturity date is more than 1 year past the settlement date, the function will fail and return `#MISSING`. If you need to value a longer-term zero-coupon bond, use `@CalcMgrExcelPRICEDISC` |
| Whole Number Rates | Passing `5` for Discount Rate | The `discount` parameter expects a decimal. If the rate is 5%, you must pass `0.05`. Passing `5` will calculate a massive negative price, destroying the calculation |
| Forgetting to Scale | Using `97.5` as the total value | Like all price functions, `TBILLPRICE` strictly returns the price *per $100 of face value*. You MUST divide the output by 100 and multiply it by your total actual Face Value to find the true dollar amount of the trade |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelTBILLYIELD`](./@CalcMgrExcelTBILLYIELD.md) | The exact inverse function: Calculates the Yield based on a known Market Price |
| [`@CalcMgrExcelTBILLEQ`](./@CalcMgrExcelTBILLEQ.md) | Calculates the Bond-Equivalent Yield based on the quoted discount rate |
| [`@CalcMgrExcelPRICEDISC`](./@CalcMgrExcelPRICEDISC.md) | Calculates the price of a generic discounted security, allowing for maturities greater than 1 year and custom calendar bases |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceltbillprice.html)
