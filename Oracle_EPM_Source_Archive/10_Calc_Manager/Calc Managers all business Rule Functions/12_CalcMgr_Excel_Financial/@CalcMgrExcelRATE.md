# @CalcMgrExcelRATE

## Overview

`@CalcMgrExcelRATE` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `RATE` function directly inside an Essbase calculation script. 
It calculates the **Interest Rate per Period** of an annuity, loan, or investment.

### Why Does This Function Exist?

In corporate finance, you often know the beginning state of a loan, the ending state, and the payment schedule, but the exact interest rate is hidden. 
For example, a vendor offers you a lease: "Give us $50,000 today, and pay us $2,000 every month for 3 years, and you own the machine." The vendor does not explicitly tell you what interest rate they are charging. To find out if this is a good deal, the Treasury department must mathematically reverse-engineer the interest rate from the cash flows.
Mathematically solving for the `RATE` of an amortizing annuity requires a recursive, guess-and-check algorithm (like the Newton-Raphson method). It is fundamentally impossible to isolate the Rate algebraically. Writing a recursive guess-and-check loop inside an Essbase calc script is impossible. `@CalcMgrExcelRATE` offloads this intensive algorithm entirely to the Java engine, returning the exact interest rate instantly.

### When to Use It

- **Lease Accounting (ASC 842 / IFRS 16)**: Calculating the implied interest rate in a lease when the lessor does not explicitly provide one.
- **Vendor Financing**: Reverse-engineering the true cost of debt for vendor payment plans to compare against standard corporate borrowing rates.
- Whenever you need to migrate an Excel spreadsheet containing the `RATE` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelRATE(nper, pmt, pv, fv, type, guess)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `nper` | Numeric | ✅ Yes | The total number of payment periods (e.g., 5 years * 12 = `60`). |
| `pmt` | Numeric | ✅ Yes | The flat payment made each period. **Must be a negative number** for cash leaving your pocket. |
| `pv` | Numeric | ✅ Yes | The present value (the initial loan amount or value of the asset). **Must be positive** if you received the asset/cash today. |
| `fv` | Numeric | ❌ No  | The future target value remaining after the final payment. Defaults to 0 (fully paid off). |
| `type` | Numeric | ❌ No  | The timing of the payment. `0` = End of the period (standard). `1` = Beginning of the period. Defaults to 0. |
| `guess` | Numeric | ❌ No  | A starting guess for the iterative algorithm (e.g., `0.1` for 10%). Defaults to `0.1`. If the function returns `#MISSING`, changing the guess can help it converge. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the exact Interest Rate per period as a decimal.
- **Critical Scaling**: If your periods (`nper`) are in months, the returned rate is the *Monthly* interest rate. You must multiply it by 12 to find the Annualized Rate (APR).

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures cash flows have opposing signs. If you received an asset (`+pv`) and you are making payments (`+pmt`), the math assumes you are getting the asset *and* getting paid every month. The algorithm will fail instantly and return `#MISSING`.
2. **Iterative Algorithm**: Starting with the `guess` (or 10%), it simulates the amortization curve. It adjusts the rate up or down iteratively based on whether the final balance overshot or undershot the `fv` target.
3. **Return**: Once the final balance perfectly hits the target, the discount rate used to achieve it is passed back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Reverse-Engineering a Monthly Lease

```essbase
/* 
   Periods: 36 Months
   Payment: -$2,000 per month
   Asset Value (PV): $60,000
   Target: Pay down to $0
   Result: Calculates the Monthly rate. Returns ~0.01026 (1.026% Monthly).
*/
"Monthly_Implied_Rate" = @CalcMgrExcelRATE(36, -2000, 60000, 0, 0, 0.1);
```

---

## Practical Examples

### Example 1: Finding the True Annual Cost of Vendor Financing

**Scenario**: A company buys a massive server rack worth `$250,000`. The vendor offers financing: pay exactly `$6,000` a month for `48` months. The CFO wants to know the true Annualized Interest Rate (APR) of this deal. If the APR is higher than the corporate borrowing rate (5%), they will reject the vendor financing and just use cash from the corporate bank account.

```essbase
FIX("FY25", "Working", @LEVEL0("Vendor_Contracts"))
    
    IF("Asset_Value" > 0 AND "Monthly_Payment_Amount" > 0)
        
        /* 1. Format payment as negative cash flow */
        VAR vNegativePMT = "Monthly_Payment_Amount" * -1;
        
        /* 
           2. Calculate the Monthly Implied Rate.
           Returns a very small decimal (e.g., 0.0059).
        */
        VAR vMonthlyRate = @CalcMgrExcelRATE(
            "Contract_Months", /* e.g., 48 */
            vNegativePMT,      /* e.g., -6000 */
            "Asset_Value",     /* e.g., 250000 */
            0, 0, 0.1
        );
        
        /* 3. Convert to an Annual Percentage Rate (APR) */
        "Calculated_Annual_Rate" = vMonthlyRate * 12;
        
        /* 4. Evaluate against corporate hurdle rate */
        IF("Calculated_Annual_Rate" > "Corporate_Borrowing_Rate")
            "Use_Vendor_Financing_Flag" = 0; /* Reject */
        ELSE
            "Use_Vendor_Financing_Flag" = 1; /* Accept */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting to Annualize | Expecting 7% but getting 0.0058 | The function returns the rate *per period*. If you passed 60 months as the `nper`, the function returns the *monthly* interest rate. You MUST mathematically multiply the result by 12 to get the Annual rate |
| Mismatched Signs | Positive PV and Positive PMT | This is the #1 reason `RATE` fails. If you receive an asset, `PV` is positive. Your payments to the vendor are money leaving your pocket, so `PMT` MUST be negative. If both are positive, the recursive algorithm spins into infinity and fails, returning `#MISSING` |
| Non-Convergence | Returning `#MISSING` on valid data | The iterative algorithm stops after ~20 attempts. If the true rate is wildly far away from the default guess of 10% (0.10) (e.g., a predatory loan charging 200%), the algorithm might give up before it finds the answer. Try explicitly passing a higher `guess` parameter (like `0.5`) to help it converge |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPMT`](./@CalcMgrExcelPMT.md) | Calculates the *Payment* if the Interest Rate is known |
| [`@CalcMgrExcelNPER`](./@CalcMgrExcelNPER.md) | Calculates the *Number of Periods* if the Rate and Payment are known |
| [`@CalcMgrExcelIRR`](./@CalcMgrExcelIRR.md) | Calculates the return rate for a series of *uneven/changing* cash flows, whereas `RATE` requires the payment to be exactly the same every period |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelrate.html)
