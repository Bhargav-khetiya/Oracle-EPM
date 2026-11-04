# @CalcMgrExcelPV

## Overview

`@CalcMgrExcelPV` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `PV` function directly inside an Essbase calculation script. 
It calculates the **Present Value** of a loan or an investment, based on a constant interest rate and a series of equal, periodic payments. 

### Why Does This Function Exist—

Present Value answers the fundamental corporate finance question: *"If I am promised $10,000 every month for the next 5 years, and my corporate discount rate is 6%, how much is that entire contract worth to me TODAY—* 
Alternatively, for debt modeling: *"If I can afford to pay exactly $50,000 a month to the bank for 10 years at a 5% interest rate, exactly how large of a loan can I take out today—*
The mathematical formula for the present value of an annuity is `PMT * ((1 - (1 + Rate)^-Nper) / Rate)`. Writing this complex algebraic formula manually in Essbase is completely unnecessary and prone to syntax errors. 
`@CalcMgrExcelPV` wraps this precise algebraic formula into a highly optimized Java call. It instantly returns the exact present value, ensuring your Essbase valuation models match legacy Excel spreadsheets perfectly.

### When to Use It

- **Loan Sizing**: Calculating the maximum initial loan amount a subsidiary can afford based on their fixed monthly cash flow limits.
- **Contract Valuation**: Valuing a leasing contract or subscription agreement that guarantees a fixed monthly payment over a set number of years.
- Whenever you need to migrate an Excel spreadsheet containing the `PV` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelPV(rate, nper, pmt, fv, type)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `rate` | Numeric | ✅ Yes | The discount/interest rate per period (e.g., if Annual Rate is 6%, and payments are monthly, `rate` = `0.06 / 12` = `0.005`). |
| `nper` | Numeric | ✅ Yes | The total number of payment periods (e.g., 5 years * 12 = `60`). |
| `pmt` | Numeric | ✅ Yes | The flat payment made/received each period. (If you are making payments to a bank, this is a **negative number**). |
| `fv` | Numeric | ❌ No  | The future target value remaining after the final payment. Defaults to 0 (fully paid off). |
| `type` | Numeric | ❌ No  | The timing of the payment. `0` = End of the period (standard). `1` = Beginning of the period. Defaults to 0. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the exact Present Value.
- **Sign Convention**: If you are calculating how much loan you can afford, and your `PMT` is negative (cash leaving your pocket), the `PV` returned will be a **positive number** (cash deposited into your account today). 

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures `nper` is > 0.
2. **Special Math Check**: If the `rate` is exactly `0`, the function completely bypasses the complex exponents and simply returns `-(fv + (pmt * nper))`.
3. **Annuity Math**: If the rate is > 0, it executes the standard present value of an annuity algebraic formula.
4. **Return**: Passes the resulting cash value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Maximum Loan Affordability

```essbase
/* 
   Rate: 6% Annual (0.005 Monthly)
   Periods: 5 Years (60 Months)
   Payment: Can afford -$50,000 per month
   Target: Pay down to $0
   Result: Calculates the max loan amount. Returns ~ $2,586,278.04
*/
"Max_Affordable_Loan" = @CalcMgrExcelPV(0.005, 60, -50000, 0, 0);
```

---

## Practical Examples

### Example 1: Sizing Debt for a Capital Project

**Scenario**: A manufacturing plant needs to upgrade its equipment. The plant generates exactly `$120,000` in free cash flow every month, and the CFO dictates that they can use exactly half of that (`-$60,000` outflow) to service new debt over the next 10 years (120 months). The bank's interest rate is 7%. The system must dynamically calculate exactly how much money the plant can borrow *today* to fund the upgrade.

```essbase
FIX("FY25", "Working", @LEVEL0("Plants"))
    
    /* Ensure the plant has free cash flow */
    IF("Monthly_Free_Cash_Flow" > 0)
        
        /* 1. Calculate the maximum affordable monthly payment (negative cash flow) */
        VAR vMaxPayment = ("Monthly_Free_Cash_Flow" * 0.5) * -1;
        
        /* 2. Calculate Monthly Interest Rate */
        VAR vMonthlyRate = "Bank_Interest_Rate" / 12;
        
        /* 3. Calculate exactly how large of a loan they can afford (Positive PV) */
        "Approved_CapEx_Budget" = @ROUND(
            @CalcMgrExcelPV(
                vMonthlyRate, 
                120,          /* 10 Year Loan */
                vMaxPayment, 
                0, 0
            )
        , 0);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Frequencies | Passing `0.06` (Annual) but `60` (Months) | The `rate` and `nper` must be in the exact same time unit. If the loan is 60 months, the rate MUST be the annual rate divided by 12. If you pass 6% (0.06) against 60 periods, the calculation assumes you are discounting at 6% *every single month*, and the resulting present value will be drastically understated |
| Positive Payments | Passing `50000` | If you are modeling a loan, your payments to the bank are cash *leaving* your pocket, so `PMT` MUST be negative `-50000`. The resulting `PV` (the loan cash you receive today) will be positive. If you pass a positive payment, `PV` will return a negative number |
| Omitting the Rate Division | Not dividing by 12 | The #1 reason users think this function is "broken" is because they pass their `Assumptions->Interest_Rate` directly into the function without dividing by 12. Always verify your time units |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelFV`](./@CalcMgrExcelFV.md) | The direct inverse function: Calculates the *Future Value* of an investment, rather than discounting it back to today |
| [`@CalcMgrExcelPMT`](./@CalcMgrExcelPMT.md) | Calculates the required *Payment* if the Present Value (the loan amount) is already known |
| [`@CalcMgrExcelNPV`](./@CalcMgrExcelNPV.md) | Calculates the Present Value for a series of *uneven/changing* cash flows, whereas `PV` requires the payment to be exactly the same every period |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelpv.html)
