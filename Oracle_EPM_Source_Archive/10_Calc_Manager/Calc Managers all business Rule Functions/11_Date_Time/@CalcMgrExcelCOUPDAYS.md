# @CalcMgrExcelCOUPDAYS

## Overview

`@CalcMgrExcelCOUPDAYS` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `COUPDAYS` function directly inside an Essbase calculation script. 
It calculates the **total number of days** in the coupon period that contains the settlement date. 

### Why Does This Function Exist—

When migrating Corporate Treasury or Investment Banking models from Excel into EPM Cloud, accurate accrued interest calculations require calculating pro-rata fractions. To calculate a fraction (e.g., how much of the interest period has elapsed), you need two numbers: the numerator (days elapsed so far) and the denominator (total days in the period).
`@CalcMgrExcelCOUPDAYS` provides the denominator. If a bond pays interest semi-annually (e.g., Jan 1 and July 1), the total number of days in that period depends entirely on whether it's a leap year, and what specific day-count basis the bond uses (e.g., US 30/360 treats every month as 30 days, meaning a semi-annual period is exactly 180 days, whereas Actual/Actual would be 181 or 182 days).
Recreating complex leap-year and European day-count basis logic manually in Essbase is extremely tedious. `@CalcMgrExcelCOUPDAYS` leverages the underlying Java financial engine to return the exact total day count, ensuring your denominator matches the legacy Excel spreadsheet perfectly.

### When to Use It

- As the denominator when calculating fractional accrued interest on a corporate bond.
- In Treasury cash flow models to determine the exact length of a debt servicing period.
- Whenever you need to migrate an Excel spreadsheet containing the `COUPDAYS` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelCOUPDAYS(settlement, maturity, frequency, basis)
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

Returns the exact total number of days in the coupon period containing the settlement date.
- Even though it returns a whole number of days, Essbase natively stores it as a double-precision floating-point number.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `frequency` is exactly 1, 2, or 4, and `basis` is between 0 and 4. `settlement` must be chronologically before `maturity`.
2. **Boundary Extrapolation**: The engine takes the `maturity` date and projects backward in time using the `frequency` to determine the exact theoretical start and end dates of the specific coupon period that encompasses the `settlement` date.
3. **Day-Count Math**: It calculates the total difference in days between the start date and the end date of that period, strictly adhering to the selected calendar `basis` rules.
4. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Semi-Annual Bond Analysis (US 30/360)

```essbase
/* 
   Settlement: March 15, 2024
   Maturity: Dec 31, 2025
   Freq: 2 (Semi-Annual)
   Basis: 0 (US 30/360)
   Result: Calculates total days in the period (Will return exactly 180).
*/
"Total_Coupon_Days" = @CalcMgrExcelCOUPDAYS(20240315, 20251231, 2, 0);
```

### Variant 2: Semi-Annual Bond Analysis (Actual/Actual)

```essbase
/* 
   Same bond, but using Actual/Actual basis. 
   Result: Will return 181 or 182 depending on leap year math for that specific half of the year.
*/
"Total_Coupon_Days" = @CalcMgrExcelCOUPDAYS(20240315, 20251231, 2, 1);
```

---

## Practical Examples

### Example 1: Calculating Pro-Rata Accrued Interest

**Scenario**: Your Corporate Treasury manages a portfolio of debt issuances. You need to calculate the accrued interest for the current month. You use `COUPDAYS` (total days in period) as the denominator, and `COUPDAYBS` (days elapsed) as the numerator to calculate a proration percentage, applying it to the total expected coupon payment.

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Tranche"))
    
    /* Ensure the debt instrument is active */
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date")
        
        /* 1. Calculate the TOTAL days in the coupon period (The Denominator) */
        "Total_Period_Days" = @CalcMgrExcelCOUPDAYS(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Payment_Frequency", 
            0
        );
        
        /* 2. Calculate the days ELAPSED so far (The Numerator) */
        "Elapsed_Period_Days" = @CalcMgrExcelCOUPDAYBS(
            "Assumptions"->"Current_Settlement_Date", 
            "Maturity_Date", 
            "Payment_Frequency", 
            0
        );
        
        /* 3. Prorate the total coupon payment */
        IF("Total_Period_Days" > 0)
            
            "Accrued_Interest_Expense" = "Expected_Coupon_Payment" * ("Elapsed_Period_Days" / "Total_Period_Days");
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrExcelCOUPDAYS(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Using the Wrong Basis | Returning 182 when you expected 180 | The denominator changes drastically based on the day-count basis. US Corporate bonds almost universally use `0` (30/360), which always yields a perfectly round number (e.g., 180 for semi-annual). US Government bonds use `1` (Actual/Actual). Ensure your basis parameter matches the legal definition of the debt instrument |
| Chronological Reversal | Settlement Date > Maturity Date | The settlement date must occur *before* the maturity date. If the bond has matured, the function will fail |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelCOUPDAYBS`](./@CalcMgrExcelCOUPDAYBS.md) | Calculates the *elapsed* number of days in the coupon period (used as the numerator) |
| [`@CalcMgrExcelCOUPDAYSNC`](./@CalcMgrExcelCOUPDAYSNC.md) | Calculates the number of days from the settlement date to the *next* coupon payment |
| [`@CalcMgrExcelCOUPNUM`](./@CalcMgrExcelCOUPNUM.md) | Calculates the total number of coupon payments remaining until the bond matures |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelcoupdays.html)
