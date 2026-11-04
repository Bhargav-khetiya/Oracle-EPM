# @CalcMgrExcelCOUPNUM

## Overview

`@CalcMgrExcelCOUPNUM` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `COUPNUM` function directly inside an Essbase calculation script. 
It calculates the exact **number of coupon payments remaining** to be paid out between the settlement date and the maturity date of a bond or debt security.

### Why Does This Function Exist—

In corporate finance, debt amortization and valuation models require knowing exactly how many cash flow periods remain in the lifespan of an instrument. For example, if a 10-year bond pays semi-annually, it has 20 total payments. If you evaluate it in year 8, how many payments are left—
While you could try to write custom math in Essbase (e.g., `(Maturity_Year - Settlement_Year) * Frequency`), leap years, varying month lengths, and specific European vs. US day-count basis rules make manual proration highly inaccurate. `@CalcMgrExcelCOUPNUM` handles all of this internally, executing the exact same algorithm as Excel to return the precise number of remaining payments, ensuring the resulting financial valuation matches the legacy spreadsheet exactly.

### When to Use It

- In bond pricing and yield models to determine the number of discounting periods remaining in the cash flow.
- In Corporate Treasury models to project future cash outflows and debt servicing requirements.
- Whenever you need to migrate an Excel spreadsheet containing the `COUPNUM` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelCOUPNUM(settlement, maturity, frequency, basis)
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

Returns the exact number of coupon payments remaining.
- Essbase stores the resulting integer as a double-precision floating-point number natively. Note that if the settlement date falls exactly on a coupon date, that payment is typically not included in the "remaining" count depending on standard bond logic rules handled by the Java engine.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `frequency` is exactly 1, 2, or 4, and `basis` is between 0 and 4. `settlement` must be chronologically before `maturity`.
2. **Boundary Extrapolation**: The engine takes the `maturity` date and projects backward in time using the `frequency` to build the theoretical payment schedule.
3. **Count Math**: It counts every theoretical coupon date that occurs strictly after the `settlement` date, up to and including the `maturity` date.
4. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Semi-Annual Bond

```essbase
/* 
   Settlement: March 15, 2024
   Maturity: Dec 31, 2025
   Freq: 2 (Semi-Annual)
   Basis: 0 (US 30/360)
   Result: Calculates payments remaining (Likely 4: Jul 24, Dec 24, Jul 25, Dec 25).
*/
"Remaining_Payments" = @CalcMgrExcelCOUPNUM(20240315, 20251231, 2, 0);
```

---

## Practical Examples

### Example 1: Calculating Total Remaining Liability

**Scenario**: Your Corporate Treasury needs a summary report showing the "Total Undiscounted Cash Liability" for every active debt tranche. This represents the total amount of cash the company will spend on interest over the remaining life of the bond before it matures.

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Tranche"))
    
    /* Ensure the debt instrument is active */
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date")
        
        /* 1. Calculate how many payments remain */
        "Remaining_Payments" = @CalcMgrExcelCOUPNUM(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Payment_Frequency", 
            0
        );
        
        /* 2. Multiply the remaining payments by the expected coupon amount */
        IF("Remaining_Payments" > 0)
            
            "Total_Future_Interest_Liability" = "Remaining_Payments" * "Expected_Coupon_Payment";
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrExcelCOUPNUM(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Invalid Frequencies | Passing `12` for monthly payments | The Excel Coupon functions only support Annual (`1`), Semi-Annual (`2`), or Quarterly (`4`). Passing `12` will cause the function to fail. If you have monthly debt, you must calculate periods manually using `@CalcMgrDateDiff` |
| Settlement = Maturity | Evaluating a matured bond | If the settlement date is equal to or greater than the maturity date, the function will fail. Ensure your script only evaluates active debt tranches |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelCOUPDAYS`](./@CalcMgrExcelCOUPDAYS.md) | Calculates the total number of days in a single coupon period |
| [`@CalcMgrExcelCOUPNCD`](./@CalcMgrExcelCOUPNCD.md) | Calculates the specific calendar *date* of the next upcoming payment |
| [`@CalcMgrExcelPRICE`](./@CalcMgrExcelPRICE.md) | Often utilizes the output of COUPNUM internally to discount cash flows and determine bond valuation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelcoupnum.html)
