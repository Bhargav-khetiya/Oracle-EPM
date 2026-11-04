# @CalcMgrExcelXIRR

## Overview

`@CalcMgrExcelXIRR` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `XIRR` function directly inside an Essbase calculation script. 
It calculates the **Internal Rate of Return (IRR)** for a schedule of cash flows that occur on **irregular, specific dates**.

### Why Does This Function Exist—

The standard `@CalcMgrExcelIRR` function assumes that all cash flows happen exactly one period apart (e.g., exactly 1 month, or exactly 1 year). In real-world Private Equity, Venture Capital, and complex CapEx modeling, this is never true. A company might invest $5M on January 1st, inject another $2M on March 15th, and receive a payout on November 2nd. 
Standard `IRR` cannot handle these random dates. To calculate the true Internal Rate of Return (the discount rate that makes the NPV of these chaotic cash flows equal zero), you must use `XIRR`. 
Solving `XIRR` requires aligning every cash flow with its exact calendar day, running a massive `NPV` calculation, and utilizing a complex recursive guess-and-check algorithm (Newton-Raphson) to find the rate. Writing this inside an Essbase script is impossible. `@CalcMgrExcelXIRR` offloads the entire recursive calendar algorithm to the Java engine, ensuring your Private Equity dashboards match your legacy Excel models perfectly.

### When to Use It

- **Private Equity & Venture Capital**: Calculating the true return of an investment portfolio where capital calls and distributions happen on highly erratic dates.
- **Complex Project Finance**: Evaluating the IRR of a massive construction project where contractor payments are tied to random milestone completion dates, rather than a monthly schedule.
- Whenever you need to migrate an Excel spreadsheet containing the `XIRR` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelXIRR(cashflows, dates, guess)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cashflows` | Array/List | ✅ Yes | An array of cash flows (both positive and negative). Usually passed as a cross-dimensional range like `"Net_Cash_Flow"->@CHILDREN("Transactions")`. |
| `dates` | Array/List | ✅ Yes | An array of `YYYYMMDD` integer dates corresponding *exactly* to the cash flows. |
| `guess` | Numeric | ❌ No  | A starting guess for the iterative algorithm (e.g., `0.1` for 10%). Defaults to `0.1`. If the function returns `#MISSING`, changing the guess can help it converge. |

**CRITICAL REQUIREMENT**: The `cashflows` array and the `dates` array must have the exact same number of elements. The first cash flow must correspond to the first date.

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Internal Rate of Return as an Annualized Decimal.
- E.g., Returns `0.152` (representing a 15.2% annualized return).
- **Important Note**: Unlike standard `IRR` which returns the rate *per period*, `XIRR` always returns a strictly **Annualized** rate, regardless of how close together the dates are.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ingests both arrays. It verifies they are the same length. It verifies there is at least one negative cash flow (investment) and at least one positive cash flow (return).
2. **Chronological Sorting**: Unlike standard `IRR`, the dates in `XIRR` do not technically have to be in chronological order. The Java engine will dynamically map the dates to the cash flows and sort them chronologically in memory. 
3. **Iterative Algorithm**: Starting with the `guess` (or 10%), it executes a recursive `XNPV` algorithm, testing discount rates. It adjusts the rate up or down iteratively based on whether the final Net Present Value overshot or undershot 0.
4. **Return**: Once the NPV perfectly hits 0, the discount rate used to achieve it is passed back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Dynamic Array Evaluation

```essbase
/* 
   Evaluates an array of cash flows against a matching array of transaction dates.
   Returns the true annualized IRR.
*/
"Calculated_XIRR" = @CalcMgrExcelXIRR(
    "Net_Cash_Flow"->@CHILDREN("Milestone_Events"),
    "Event_Date_Integer"->@CHILDREN("Milestone_Events"),
    0.1
);
```

---

## Practical Examples

### Example 1: Private Equity Capital Call Returns

**Scenario**: A Private Equity firm tracks an investment fund. The fund has 10 possible `"Transaction"` events over a 5-year lifespan. Some are negative Capital Calls, some are positive Distributions. Because they happen randomly based on market conditions, the FP&A team stores the exact `YYYYMMDD` date in an account called `"Transaction_Date"`. They use `XIRR` to evaluate the fund's overall performance.

```essbase
FIX("FY25", "Working", @LEVEL0("PE_Funds"))
    
    /* Ensure the fund actually had transactions (prevent empty array errors) */
    IF(@SUM("Transaction_Cash_Flow"->@CHILDREN("Transactions")) != 0)
        
        /* 
           1. Calculate the XIRR.
           Pass the array of cash flows, and the matching array of dates.
        */
        "Fund_Level_XIRR" = @CalcMgrExcelXIRR(
            "Transaction_Cash_Flow"->@CHILDREN("Transactions"),
            "Transaction_Date"->@CHILDREN("Transactions"),
            0.1 /* Standard 10% starting guess */
        );
        
        /* 
           2. Flag if the fund failed to beat the corporate hurdle rate (e.g., 8%)
        */
        IF("Fund_Level_XIRR" < 0.08)
            "Under_Performance_Flag" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Array Sizes | `XIRR(CashFlows, Dates)` | This is the #1 reason this function fails. The function aligns the arrays by index. If the `cashflows` array has 10 items, and the `dates` array has 12 items, the Java engine cannot align them and will throw an error. The arrays must be perfectly identical in length |
| Passing `#MISSING` Dates | Empty transaction slots | If your array covers 10 potential transactions, but the fund only had 3, the remaining 7 slots will have `#MISSING` dates. While the function can handle `#MISSING` cash flows as `0`, a `#MISSING` date passed to the calendar math will cause the function to fail. You must dynamically build your arrays or isolate the valid data blocks |
| Missing Opposing Signs | All positive cash flows | IRR fundamentally requires an initial investment (negative) and a return (positive). If a project only has positive cash flows (you never invested any money), the rate of return is mathematically infinite. The algorithm will fail and return `#MISSING` |
| Non-Convergence | Returning `#MISSING` on valid data | The iterative Newton-Raphson algorithm stops after ~20 to 100 attempts. If the true IRR is wildly erratic (e.g., -90% or +400%), the algorithm might give up before it finds the answer. Try explicitly passing a higher or negative `guess` parameter to help it converge |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelIRR`](../12_CalcMgr_Excel_Financial/@CalcMgrExcelIRR.md) | Calculates the Internal Rate of Return for cash flows that occur at perfectly regular, identical intervals (e.g., exactly 1 year apart) |
| [`@CalcMgrExcelXNPV`](./@CalcMgrExcelXNPV.md) | Calculates the Net Present Value for irregular dates based on a *fixed* discount rate |
| [`@CalcMgrExcelMIRR`](../12_CalcMgr_Excel_Financial/@CalcMgrExcelMIRR.md) | Calculates the Modified IRR, which accounts for the cost of borrowing and the reinvestment rate of the returns |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelxirr.html)
