# @CalcMgrExcelDISC

## Overview

`@CalcMgrExcelDISC` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DISC` function directly inside an Essbase calculation script. 
It calculates the **Discount Rate** of a security (like a bond, treasury bill, or promissory note) based on its current market price and its redemption value at maturity.

### Why Does This Function Exist?

When a company issues or buys short-term debt (like a Treasury Bill), it doesn't typically pay interest via a coupon. Instead, it is sold at a "discount" to its face value. For example, you buy a $10,000 bill today for $9,500. When it matures in a year, you get $10,000. The $500 difference is your return, derived from the "Discount Rate".
To calculate this rate manually, an FP&A analyst would have to write the algebraic discount formula: `((Redemption - Price) / Redemption) * (YearBase / DaysBetween)`. While possible in Essbase, getting the exact `DaysBetween` while adhering to localized calendar rules (like NASD 30/360 or Actual/360) requires massive blocks of `IF` statement logic.
`@CalcMgrExcelDISC` wraps all of this algebra and day-count math into a single, high-performance Java function. It ensures that the discount rate calculated in the EPM Cloud model matches legacy treasury spreadsheets perfectly.

### When to Use It

- **Corporate Treasury**: Evaluating the implicit yield/discount rate on short-term commercial paper or treasury bills.
- **Investment Banking**: Pricing zero-coupon bonds based on secondary market trading prices.
- Whenever you need to migrate an Excel spreadsheet containing the `DISC` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDISC(settlement, maturity, pr, redemption, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the security is traded or evaluated. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the security expires. Must be > `settlement`. |
| `pr` | Numeric | ✅ Yes | The security's price per $100 face value (e.g., if you bought a $100 bond for $95, pass `95`). |
| `redemption` | Numeric | ✅ Yes | The security's redemption value per $100 face value (usually `100`). |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the annualized discount rate as a decimal (e.g., `0.052` for 5.2%).
- You typically want to wrap it in `@ROUND(..., 4)` to format it cleanly for reporting.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `pr` > 0, `redemption` > 0, and `basis` is between 0 and 4. `settlement` must be chronologically before `maturity`.
2. **Day-Count Math**: It calculates the exact number of days between the `settlement` and `maturity` dates (often referred to as `DSM` - Days from Settlement to Maturity) using the specified calendar `basis`.
3. **Discount Equation**: It executes the standard discount algorithm: `((redemption - pr) / redemption) * (Year_Basis / DSM)`.
4. **Return**: Passes the resulting annualized decimal rate back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating the Discount Rate of a Treasury Bill

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Dec 31, 2024
   Price: $95.50 (per $100)
   Redemption: $100
   Basis: 2 (Actual/360 - common for T-Bills)
*/
"Calculated_Discount_Rate" = @CalcMgrExcelDISC(20240101, 20241231, 95.50, 100, 2);
```

---

## Practical Examples

### Example 1: Dynamic Yield Analysis on Commercial Paper

**Scenario**: A corporate treasury department regularly buys short-term commercial paper. The database stores the Purchase Date (Settlement), Maturity Date, and the Purchase Price (normalized to $100 face value). To compare the profitability of these investments, they need to calculate the annualized discount rate for every active holding and store it in an analysis metric.

```essbase
FIX("FY25", "Working", @LEVEL0("Short_Term_Investments"))
    
    /* Ensure the investment hasn't matured and has a valid price */
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date" AND "Purchase_Price" > 0)
        
        /* Calculate the Discount Rate dynamically. 
           We use Basis 2 (Actual/360) because this is standard for short-term corporate paper. */
           
        "Annualized_Discount_Rate" = @CalcMgrExcelDISC(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Purchase_Price", 
            100, /* Standard Redemption Face Value */
            2    /* Basis: Actual/360 */
        );
        
        /* Flag highly profitable investments for treasury review (e.g., > 6% discount rate) */
        IF("Annualized_Discount_Rate" > 0.06)
            "High_Yield_Flag" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Absolute Prices vs. Face Value | Passing `$9,500` and `$10,000` | The Excel financial functions expect prices and redemptions to be normalized *per $100 face value*. While passing absolute values might mathematically work out to the same ratio in the first half of the formula, it is best practice to pass normalized values (e.g., `95` and `100`) to guarantee consistent results |
| Chronological Reversal | Settlement Date > Maturity Date | If the settlement date occurs *after* the maturity date, the security has expired, the math evaluates to a negative day count, and the function will fail |
| Passing Java Dates | `@CalcMgrExcelDISC(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the function returns `#MISSING` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPRICEDISC`](./@CalcMgrExcelPRICEDISC.md) | The inverse function: Calculates the *Price* of a discounted security when the Discount Rate is known |
| [`@CalcMgrExcelYIELDDISC`](./@CalcMgrExcelYIELDDISC.md) | Calculates the true annualized *Yield* (which is slightly different mathematically than the *Discount*) of a discounted security |
| [`@CalcMgrExcelACCRINTM`](./@CalcMgrExcelACCRINTM.md) | Calculates the accrued interest paid at maturity |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldisc.html)
