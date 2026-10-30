# @CalcMgrExcelACCRINTM

## Overview

`@CalcMgrExcelACCRINTM` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `ACCRINTM` function directly inside an Essbase calculation script. 
It calculates the accrued interest for a security (like a zero-coupon bond, short-term commercial paper, or certificate of deposit) that pays interest entirely **at maturity**, rather than in periodic coupon payments.

### Why Does This Function Exist?

When migrating treasury models from Excel into EPM Cloud, developers often need to model short-term debt instruments that do not pay semi-annual coupons. Instead, the interest accrues over the lifespan of the instrument and is paid out in a single lump sum when the instrument matures.
Recreating the precise Excel day-count logic (especially adjusting for leap years or specific European vs. US day-count bases) using raw algebraic Essbase equations is tedious and prone to fractional rounding errors. `@CalcMgrExcelACCRINTM` utilizes the underlying Java math engine to execute the exact same logic as Excel, ensuring 100% parity with legacy spreadsheets down to the penny.

### When to Use It

- In Corporate Treasury models to calculate the accrued interest on commercial paper or Certificates of Deposit (CDs).
- In Asset Management models evaluating the accrued value of bonds that strictly pay at maturity.
- Whenever you need to migrate an Excel spreadsheet containing the `ACCRINTM` function directly into an Essbase calculation without losing mathematical fidelity.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelACCRINTM(issue, settlement, rate, par, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function. Notice the absence of the 'frequency' parameter, because interest is only paid once).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `issue` | Integer | ✅ Yes | The issue date of the security (`YYYYMMDD`). |
| `settlement` | Integer | ✅ Yes | The maturity/settlement date (`YYYYMMDD`). Must be > `issue`. |
| `rate` | Numeric | ✅ Yes | The security's annual interest rate (e.g., `0.05` for 5%). |
| `par` | Numeric | ✅ Yes | The security's par value (e.g., `1000`). |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the accrued interest amount at maturity.
- The returned value is highly precise. You typically want to wrap it in `@ROUND(..., 2)` to format it cleanly for currency reporting.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `rate` and `par` are > 0, and `basis` is between 0 and 4. `settlement` must be chronologically after `issue`.
2. **Date Math**: It calculates the exact number of days between the `issue` date and the `settlement` date based strictly on the selected `basis` calendar logic (e.g., treating every month as exactly 30 days if basis `0` is selected).
3. **Accrual Equation**: It executes the standard maturity accrual formula: `Par * Rate * (Days_Between / Annual_Basis_Days)`.
4. **Return**: Passes the resulting accrued value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Commercial Paper (US 30/360 Basis)

```essbase
/* 
   Issue: Jan 1, 2024
   Settlement: Dec 31, 2024
   Rate: 4% (0.04)
   Par: $100,000
   Basis: 0 (US 30/360)
*/
"Maturity_Interest" = @CalcMgrExcelACCRINTM(20240101, 20241231, 0.04, 100000, 0);
```

---

## Practical Examples

### Example 1: Calculating CD Payouts in a Treasury Model

**Scenario**: Your company invests excess cash into short-term Certificates of Deposit (CDs). You track each CD as a unique Level 0 member. You want to calculate exactly how much interest income will be realized upon maturity of the CD. The assumptions (Rate, Par, Dates) are stored as dynamic values in the cube.

```essbase
FIX("FY25", "Working", @LEVEL0("Investments"))
    
    /* Ensure the investment is a maturity-paying instrument */
    IF("Investment_Type" == 2 AND "Par_Value" > 0 AND "Interest_Rate" > 0)
        
        /* Calculate ACCRINTM dynamically using cube data.
           We use Basis 2 (Actual/360), which is common for short-term corporate paper. */
        "Realized_Interest_Income" = @ROUND(
            @CalcMgrExcelACCRINTM(
                "Issue_Date", 
                "Maturity_Date", 
                "Interest_Rate", 
                "Par_Value", 
                2  /* Basis: Actual/360 */
            )
        , 2); /* Round to 2 decimal places */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrExcelACCRINTM(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Chronological Reversal | Settlement Date < Issue Date | If the maturity/settlement date occurs *before* the issue date, the function will fail and return `#MISSING`. Ensure your dates are sequenced correctly |
| Whole Number Rates | Passing `5` instead of `0.05` | The `rate` parameter expects a decimal. If the interest rate is 5%, you must pass `0.05`. Passing `5` will calculate 500% interest |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelACCRINT`](./@CalcMgrExcelACCRINT.md) | The sibling function that calculates accrued interest for a security that pays interest *periodically* (semi-annually, quarterly) rather than at maturity |
| [`@CalcMgrExcelPRICEMAT`](../12_CalcMgr_Excel_Financial/@CalcMgrExcelPRICEMAT.md) | Calculates the price per $100 face value of a security that pays interest at maturity |
| [`@CalcMgrExcelYIELDMAT`](../12_CalcMgr_Excel_Financial/@CalcMgrExcelYIELDMAT.md) | Calculates the annual yield of a security that pays interest at maturity |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelaccrintm.html)
