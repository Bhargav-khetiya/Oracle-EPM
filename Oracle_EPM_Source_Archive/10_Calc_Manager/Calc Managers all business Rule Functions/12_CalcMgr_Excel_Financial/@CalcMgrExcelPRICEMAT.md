# @CalcMgrExcelPRICEMAT

## Overview

`@CalcMgrExcelPRICEMAT` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `PRICEMAT` function directly inside an Essbase calculation script. 
It calculates the **Price** of a security that pays interest *solely at maturity* (per $100 of face value).

### Why Does This Function Exist—

There are three primary types of fixed-income securities:
1. **Standard Bonds**: Pay interest periodically (e.g., every 6 months). (Use `PRICE`).
2. **Discount Bonds**: Pay no interest, but are sold at a deep discount. (Use `PRICEDISC`).
3. **Interest-at-Maturity Bonds**: Sold at or near face value, pay no periodic interest, but pay a massive lump sum of accumulated interest on the exact day they mature. 
To calculate the current market price of an Interest-at-Maturity bond based on today's yield requirements, you must calculate the total interest that will be owed at maturity, add it to the face value, and then discount that massive final sum back to today using complex calendar math. 
`@CalcMgrExcelPRICEMAT` offloads this specialized calculation to the Java engine, ensuring your EPM models align perfectly with legacy Treasury Excel sheets without requiring manual, brittle discounting scripts.

### When to Use It

- **Treasury Management**: Valuing specific structured notes, CDs, or municipal bonds that only pay interest upon expiration.
- **Mark-to-Market Valuation**: Reporting the fair market value of Interest-at-Maturity holdings at month-end based on current market yields.
- Whenever you need to migrate an Excel spreadsheet containing the `PRICEMAT` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelPRICEMAT(settlement, maturity, issue, rate, yld, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the security is traded or evaluated. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the security expires. Must be > `settlement`. |
| `issue` | Integer | ✅ Yes | The original issue date (`YYYYMMDD`) of the security. (Required to calculate the total interest that will accrue over the life of the bond). |
| `rate` | Numeric | ✅ Yes | The security's stated annual interest rate (e.g., `0.05` for 5%). |
| `yld` | Numeric | ✅ Yes | The bond's current annual yield-to-maturity demanded by the market (e.g., `0.07` for 7%). |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the price of the security per $100 of face value.
- E.g., Returns `98.50`. If you want to buy `$1,000,000` of this bond, you will pay exactly `$985,000`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, rates are valid decimals, and `issue` < `settlement` < `maturity`.
2. **Interest Calculation**: It calculates the exact number of days between the `issue` date and `maturity` date (`DIM`). It multiplies `100 * rate * (DIM / Year_Basis)` to find the total interest owed at the end.
3. **Discount Equation**: It calculates the days between `settlement` and `maturity` (`DSM`). It takes the total final payout (100 + Total Interest) and discounts it back to the settlement date using the `yld` and the `DSM`.
4. **Return**: Passes the finalized price metric back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Valuing a 1-Year CD (Actual/360)

```essbase
/* 
   Issue: Jan 1, 2023
   Settlement: Jan 1, 2024
   Maturity: Dec 31, 2024 (1 Year remaining)
   Stated Rate: 5% (0.05)
   Current Yield: 6% (0.06)
   Basis: 2 (Actual/360)
   Result: Calculates current market price.
*/
"Bond_Price" = @CalcMgrExcelPRICEMAT(20240101, 20241231, 20230101, 0.05, 0.06, 2);
```

---

## Practical Examples

### Example 1: Month-End Valuation of Structured Notes

**Scenario**: A corporate treasury holds municipal notes that pay interest only at maturity. At the end of every month, the FP&A team inputs the current market `"Yield_To_Maturity"`. The system uses `PRICEMAT` to calculate the current clean value of the note for the Balance Sheet.

```essbase
FIX("FY25", "Working", @LEVEL0("Municipal_Notes"))
    
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date" AND "Face_Value" > 0)
        
        /* 1. Calculate the Price per $100 Face Value */
        VAR vPricePer100 = @CalcMgrExcelPRICEMAT(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Original_Issue_Date",
            "Stated_Interest_Rate",
            "Yield_To_Maturity", 
            0 /* Assuming US 30/360 Basis */
        );
        
        /* 2. Calculate Total Market Value */
        "Current_Market_Value" = "Face_Value" * (vPricePer100 / 100);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Chronological Reversal | Issue > Settlement | The original issue date MUST occur before the settlement date, and the settlement date MUST occur before the maturity date. If the dates are out of chronological order, the day-count math evaluates to negative numbers and the function fails |
| Missing Issue Date | Passing `0` for Issue | Unlike `PRICE` and `PRICEDISC`, this function absolutely requires the original `issue` date. It needs it to calculate how much interest has been building up since the bond was created. If you pass `0`, it will calculate interest from January 1900, resulting in an astronomically high price |
| Forgetting to Scale | Using the raw result as the total value | Like all price functions, `PRICEMAT` strictly returns the price *per $100 of face value*. You MUST divide the output by 100 and multiply it by your total Face Value |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelYIELDMAT`](./@CalcMgrExcelYIELDMAT.md) | The exact inverse function: Calculates the Yield to Maturity based on a known Market Price for an interest-at-maturity bond |
| [`@CalcMgrExcelPRICE`](./@CalcMgrExcelPRICE.md) | Calculates the price of a standard bond that pays periodic interest coupons |
| [`@CalcMgrExcelPRICEDISC`](./@CalcMgrExcelPRICEDISC.md) | Calculates the price for a zero-coupon discount bond |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelpricemat.html)
