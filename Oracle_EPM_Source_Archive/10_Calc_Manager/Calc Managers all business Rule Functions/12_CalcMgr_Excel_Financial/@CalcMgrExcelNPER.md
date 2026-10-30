# @CalcMgrExcelNPER

## Overview

`@CalcMgrExcelNPER` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `NPER` function directly inside an Essbase calculation script. 
It calculates the **Number of Periods** required to pay off a loan (or reach an investment target) based on constant, periodic payments and a constant interest rate.

### Why Does This Function Exist?

In debt modeling, a company might say: "We have a $10,000,000 loan at 6% interest. We can afford to pay exactly $250,000 every month. How long will it take to pay off this debt?" 
To answer that question manually, you would have to calculate the logarithm of the amortizing balance: `LOG(PMT / (PMT - PV * Rate)) / LOG(1 + Rate)`. Writing complex logarithmic math inside an Essbase script is highly inefficient and prone to syntax or precision errors.
`@CalcMgrExcelNPER` wraps this entire logarithmic formula into a single Java function. It instantly solves for the exact time horizon, guaranteeing parity with legacy treasury models built in Excel.

### When to Use It

- **Debt Restructuring**: Determining how many months (or years) a company can shorten a loan by increasing their monthly payments.
- **Capital Planning**: Forecasting exactly how long it will take a sinking fund (with fixed monthly contributions) to reach a target CapEx balance.
- Whenever you need to migrate an Excel spreadsheet containing the `NPER` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelNPER(rate, pmt, pv, fv, type)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `rate` | Numeric | ✅ Yes | The interest rate per period (e.g., if Annual Rate is 6%, and payments are monthly, `rate` = `0.06 / 12` = `0.005`). |
| `pmt` | Numeric | ✅ Yes | The flat payment made each period. **Must be a negative number** for cash leaving your pocket (e.g., `-250000`). |
| `pv` | Numeric | ✅ Yes | The present value. **Must be positive** for a loan you received (`10000000`), or negative for an initial seed investment you paid out. |
| `fv` | Numeric | ❌ No  | The future target value. Defaults to 0 (fully paid off). Pass a positive number if you are building an investment fund rather than paying off a loan. |
| `type` | Numeric | ❌ No  | The timing of the payment. `0` = End of the period (standard). `1` = Beginning of the period. Defaults to 0. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the total number of periods required.
- The result is often fractional (e.g., `45.6` months). This means it will take 45 full payments and one smaller final payment to perfectly hit the target. Use `@CalcMgrExcelCEILING` if you want to know the absolute total number of payments.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures cash flows have opposing signs (if you take a positive loan, you must make negative payments. If both are positive, you never pay off the loan, and the math fails).
2. **Logarithmic Math**: It executes the standard algebraic formula for periods using natural logarithms based on the `rate`, `pmt`, and `pv`.
3. **Return**: Passes the resulting period count back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Months to Pay Off a Loan

```essbase
/* 
   Rate: 6% Annual (0.005 Monthly)
   Payment: -$250,000 per month
   Loan: $10,000,000
   Result: Calculates total months to $0 balance. Returns ~44.74 months.
*/
"Months_To_Payoff" = @CalcMgrExcelNPER(0.005, -250000, 10000000, 0, 0);
```

---

## Practical Examples

### Example 1: Dynamic Amortization Lifespan for New Debt

**Scenario**: A corporate treasury team evaluates a potential new term loan. They input the `"Requested_Loan_Amount"`, the bank's `"Interest_Rate"`, and the maximum `"Affordable_Monthly_Payment"`. They want the system to dynamically tell them how many years the loan will last, so they can ensure it matures before a major corporate restructuring event.

```essbase
FIX("FY25", "Working", @LEVEL0("Proposed_Debt"))
    
    IF("Requested_Loan_Amount" > 0 AND "Affordable_Monthly_Payment" > 0)
        
        /* 1. Calculate Monthly Rate */
        VAR vMonthlyRate = "Interest_Rate" / 12;
        
        /* 2. Format payment as negative cash flow */
        VAR vNegativePMT = "Affordable_Monthly_Payment" * -1;
        
        /* 3. Calculate total months required */
        VAR vTotalMonths = @CalcMgrExcelNPER(
            vMonthlyRate, 
            vNegativePMT, 
            "Requested_Loan_Amount", 
            0, /* Pay down to 0 */
            0  /* End of month payments */
        );
        
        /* 4. Convert months to years for the dashboard, and round up */
        "Loan_Lifespan_Years" = @CalcMgrExcelCEILING(vTotalMonths / 12, 1);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Signs | Positive PV and Positive PMT | Excel financial functions strictly use cash flow sign conventions. If you receive a loan, `PV` is positive. Your payments to the bank are money leaving your pocket, so `PMT` MUST be negative. If both are positive, the math assumes you are getting a loan *and* the bank is paying you every month; the loan balance grows infinitely, the logarithms fail, and the function returns `#MISSING` |
| Payment Too Small | Payment doesn't cover interest | If your `pmt` is smaller than `pv * rate`, you are not even covering the monthly interest. The loan balance grows infinitely. The function will fail and return `#MISSING` |
| Mismatched Frequencies | Passing `0.06` (Annual) but expecting Months | The `rate` dictates the time unit of the output. If you pass an annual rate, the function returns the number of *Years*. If you pass a monthly rate, the function returns the number of *Months* |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPMT`](./@CalcMgrExcelPMT.md) | The inverse function: Calculates the required *Payment* if the Number of Periods is known |
| [`@CalcMgrExcelRATE`](./@CalcMgrExcelRATE.md) | Calculates the *Interest Rate* if the Number of Periods and the Payment are both known |
| [`@CalcMgrExcelFV`](./@CalcMgrExcelFV.md) | Calculates the *Future Value* if the Number of Periods, Payment, and Rate are known |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelnper.html)
