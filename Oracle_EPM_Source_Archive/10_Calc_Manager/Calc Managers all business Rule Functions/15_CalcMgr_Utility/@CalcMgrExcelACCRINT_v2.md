# @CalcMgrExcelACCRINT

## Overview

`@CalcMgrExcelACCRINT` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `ACCRINT` function directly inside an Essbase calculation script. 
It calculates the accrued interest for a security (like a bond) that pays periodic interest, calculating the interest accrued from the issue date to the first interest date, or between subsequent interest dates, up to the specific settlement date.

### Why Does This Function Exist?

When migrating complex financial models from Excel into EPM Cloud (such as corporate treasury models, bond portfolio management, or debt servicing models), developers historically had to manually recreate complex financial formulas using massive algebraic `IF` statements inside Calc Scripts. This was error-prone, difficult to maintain, and often resulted in slight fractional discrepancies compared to the legacy Excel model.
Oracle introduced a suite of "Excel-equivalent" functions to solve this. `@CalcMgrExcelACCRINT` utilizes the underlying Java math engine to execute the exact same algorithmic logic as Excel, guaranteeing that the accrued interest calculated in the Essbase cube matches the legacy Excel spreadsheet down to the penny.

### When to Use It

- In Corporate Treasury models to calculate the accrued interest expense on periodic-paying corporate debt.
- In Investment Banking or Asset Management models tracking the accrued interest on a bond portfolio.
- Whenever you need to migrate an Excel spreadsheet containing the `ACCRINT` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelACCRINT(issue, firstInterest, settlement, rate, par, frequency, basis, calcMethod)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `issue` | Integer | ✅ Yes | The issue date of the security (`YYYYMMDD`). |
| `firstInterest`| Integer | ✅ Yes | The first interest date of the security (`YYYYMMDD`). |
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`) (the date the security is traded/evaluated). |
| `rate` | Numeric | ✅ Yes | The security's annual coupon interest rate (e.g., `0.05` for 5%). |
| `par` | Numeric | ✅ Yes | The security's par value (e.g., `1000`). |
| `frequency` | Numeric | ✅ Yes | The number of coupon payments per year: Annual = `1`, Semi-annual = `2`, Quarterly = `4`. |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |
| `calcMethod` | Boolean | ✅ Yes | `1` (True) = Returns total accrued interest from issue to settlement. `0` (False) = Returns accrued interest from the first interest date to settlement. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the accrued interest amount.
- The returned value is highly precise. You typically want to wrap it in `@ROUND(..., 2)` to format it cleanly for currency reporting.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures all dates are valid integers, `rate` and `par` are > 0, `frequency` is exactly 1, 2, or 4, and `basis` is between 0 and 4. If any parameter is invalid, the function throws an error or returns `#MISSING`.
2. **Date Alignment**: The engine evaluates the relationship between the `issue`, `firstInterest`, and `settlement` dates using the specified day-count `basis`.
3. **Accrual Math**: It executes the standard bond accrual formula: `Par * Rate * (Accrued_Days / Days_in_Year)`.
4. **Method Switch**: It adjusts the calculation window based on the `calcMethod` flag (total vs. partial period).
5. **Return**: Passes the resulting accrued value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Semi-Annual Corporate Bond

```essbase
/* 
   Issue: Jan 1, 2024
   First Interest: July 1, 2024
   Settlement: March 15, 2024
   Rate: 5% (0.05)
   Par: $10,000
   Freq: 2 (Semi-Annual)
   Basis: 0 (US 30/360)
   Method: 1 (Total)
*/
"Accrued_Interest" = @CalcMgrExcelACCRINT(20240101, 20240701, 20240315, 0.05, 10000, 2, 0, 1);
```

---

## Practical Examples

### Example 1: Dynamic Treasury Debt Servicing

**Scenario**: Your Corporate Treasury department manages a portfolio of debt issuances. All parameters (Issue Date, Rate, Par Value) are stored dynamically as attributes or numeric accounts at the `@LEVEL0("Debt_Tranche")` dimension. You need to calculate the accrued interest for the current month's closing date (Settlement).

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Tranche"))
    
    /* We assume Settlement Date is stored at the global 'Assumptions' level */
    
    IF("Par_Value" > 0 AND "Coupon_Rate" > 0)
        
        /* Calculate ACCRINT dynamically using cube data */
        "Calculated_Accrued_Interest" = @ROUND(
            @CalcMgrExcelACCRINT(
                "Issue_Date", 
                "First_Interest_Date", 
                "Assumptions"->"Current_Settlement_Date", 
                "Coupon_Rate", 
                "Par_Value", 
                "Payment_Frequency", 
                0, /* Assuming standard US 30/360 Basis */
                1  /* Total Accrual */
            )
        , 2); /* Round to 2 decimal places for pennies */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrExcelACCRINT(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Invalid Frequencies | Passing `12` for monthly payments | Excel's ACCRINT only supports Annual (`1`), Semi-Annual (`2`), or Quarterly (`4`). Passing any other number will cause the function to fail. If you have monthly compounding debt, you must use a different mathematical approach |
| Whole Number Rates | Passing `5` instead of `0.05` | The `rate` parameter expects a decimal. If the bond is 5%, you must pass `0.05`. Passing `5` will calculate 500% interest |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelACCRINTM`](./@CalcMgrExcelACCRINTM.md) | The sibling function that calculates accrued interest for a security that pays interest *at maturity* rather than periodically |
| [`@CalcMgrExcelPRICE`](../12_CalcMgr_Excel_Financial/@CalcMgrExcelPRICE.md) | Calculates the price per $100 face value of a security that pays periodic interest |
| [`@CalcMgrExcelYIELD`](../12_CalcMgr_Excel_Financial/@CalcMgrExcelYIELD.md) | Calculates the yield on a security that pays periodic interest |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelaccrint.html)
