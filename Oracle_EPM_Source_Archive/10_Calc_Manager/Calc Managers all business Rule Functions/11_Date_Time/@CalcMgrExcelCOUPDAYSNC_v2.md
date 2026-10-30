# @CalcMgrExcelCOUPDAYSNC

## Overview

`@CalcMgrExcelCOUPDAYSNC` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `COUPDAYSNC` function directly inside an Essbase calculation script. 
It calculates the exact number of days from the settlement date up to the **N**ext **C**oupon date.

### Why Does This Function Exist?

In bond pricing and treasury cash flow models, it is essential to know exactly how far away the next cash outflow (interest payment) is. If a company issues a semi-annual bond (paying July 1 and Dec 31) and today's settlement date is May 15, the treasury department needs to know exactly how many days they have left to prepare the July 1 cash payment. 
Calculating this manually in Essbase requires extrapolating the theoretical coupon schedule backwards from the maturity date, determining which period today falls into, and doing day-count math. `@CalcMgrExcelCOUPDAYSNC` executes this complex calendar logic seamlessly, returning the precise number of days remaining until the next coupon payment, matching Excel's internal math exactly.

### When to Use It

- In Treasury Cash Flow forecasting models to determine the timing of impending debt servicing payments.
- When calculating the fractional discounting period for bond pricing logic.
- Whenever you need to migrate an Excel spreadsheet containing the `COUPDAYSNC` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelCOUPDAYSNC(settlement, maturity, frequency, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the security is traded or evaluated. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the security expires. |
| `frequency` | Numeric | ✅ Yes | The number of coupon payments per year: Annual = `1`, Semi-annual = `2`, Quarterly = `4`. |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the exact number of days remaining from the settlement date until the next coupon payment date.
- Essbase stores the resulting integer as a double-precision floating-point number natively.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `frequency` is exactly 1, 2, or 4, and `basis` is between 0 and 4. `settlement` must be chronologically before `maturity`.
2. **Boundary Extrapolation**: The engine takes the `maturity` date and projects backward in time using the `frequency` to determine the exact date of the next upcoming coupon payment relative to the `settlement` date.
3. **Day-Count Math**: It calculates the difference in days between the `settlement` date and the projected next coupon date, strictly adhering to the selected calendar `basis` rules.
4. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Semi-Annual Bond Analysis

```essbase
/* 
   Settlement: March 15, 2024
   Maturity: Dec 31, 2025
   Freq: 2 (Semi-Annual)
   Basis: 0 (US 30/360)
   Result: Calculates days until the next payment.
*/
"Days_Until_Next_Payment" = @CalcMgrExcelCOUPDAYSNC(20240315, 20251231, 2, 0);
```

---

## Practical Examples

### Example 1: Treasury Short-Term Liquidity Planning

**Scenario**: Your Corporate Treasury manages a portfolio of debt issuances. They maintain a "Liquidity Buffer" logic. If a debt tranche has a coupon payment due within the next 30 days, the cash required for that payment must be moved from "Long-Term Investments" into "Short-Term Restricted Cash". The script evaluates the days to the next coupon to trigger this reclassification.

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Tranche"))
    
    /* Ensure the debt instrument is active */
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date")
        
        /* Calculate how many days until the next interest payment is due */
        "Days_To_Next_Coupon" = @CalcMgrExcelCOUPDAYSNC(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Payment_Frequency", 
            0
        );
        
        /* Trigger logic if the payment is impending (within 30 days) */
        IF("Days_To_Next_Coupon" <= 30 AND "Days_To_Next_Coupon" > 0)
            
            /* Reclassify the cash required for the payment */
            "Restricted_Cash_Requirement" = "Expected_Coupon_Payment";
            "Available_Operating_Cash" = "Available_Operating_Cash" - "Expected_Coupon_Payment";
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misinterpreting the Math | `Elapsed` vs `Remaining` | This function (`COUPDAYSNC`) calculates the days *remaining* in the current period. If you need the days *already elapsed* in the period (for accrued interest), you must use `@CalcMgrExcelCOUPDAYBS` |
| Passing Java Dates | `@CalcMgrExcelCOUPDAYSNC(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Chronological Reversal | Settlement Date > Maturity Date | The settlement date must occur *before* the maturity date. If the bond has matured, there are no next coupon payments, and the function will fail |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelCOUPDAYS`](./@CalcMgrExcelCOUPDAYS.md) | Calculates the *total* number of days in the coupon period |
| [`@CalcMgrExcelCOUPDAYBS`](./@CalcMgrExcelCOUPDAYBS.md) | Calculates the *elapsed* number of days in the coupon period (from the beginning of the period to settlement) |
| [`@CalcMgrExcelCOUPNCD`](../15_CalcMgr_Utility/@CalcMgrExcelCOUPNCD.md) | Calculates the actual calendar *date* (YYYYMMDD) of the next coupon payment, rather than the number of days until it arrives |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelcoupdaysnc.html)
