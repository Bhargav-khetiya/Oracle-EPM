# @CalcMgrExcelIRR

## Overview

`@CalcMgrExcelIRR` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `IRR` function directly inside an Essbase calculation script. 
It calculates the **Internal Rate of Return** for a series of cash flows that occur at regular intervals (like months or years).

### Why Does This Function Exist—

The Internal Rate of Return (IRR) is the ultimate metric used in corporate finance to evaluate the profitability of a project or investment. It answers the question: "If I spend $1,000,000 today, and receive varying amounts of cash back over the next 5 years, what is my annualized percentage return— 
Mathematically, IRR is the discount rate that makes the Net Present Value (NPV) of all cash flows equal exactly zero. There is no clean algebraic formula for IRR; it requires an iterative, "guess and check" computational algorithm (like the Newton-Raphson method) that attempts hundreds of discount rates until it hones in on the perfect percentage.
Writing a recursive guess-and-check loop inside an Essbase calculation script is essentially impossible and highly destructive to system performance. `@CalcMgrExcelIRR` completely offloads this intensive algorithm to the Java engine. It takes an array of cash flows, runs the iterations in memory instantly, and returns the final IRR decimal.

### When to Use It

- **CapEx Planning**: Evaluating the ROI on a proposed manufacturing plant or software implementation to decide if the project clears the corporate hurdle rate.
- **Real Estate / Private Equity**: Calculating the annualized yield on a property acquisition over a 10-year hold period.
- Whenever you need to migrate an Excel spreadsheet containing the `IRR` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelIRR(cashflows, guess)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cashflows` | Array/List | ✅ Yes | An array of cash flows (both positive and negative). Usually passed as a cross-dimensional range like `"Net_Cash_Flow"->@CHILDREN("All_Years")`. The first value is almost always negative (the initial investment). |
| `guess` | Numeric | ❌ No  | A starting guess for the iterative algorithm (e.g., `0.1` for 10%). Defaults to `0.1` if omitted. If the function returns `#MISSING`, providing a different guess can sometimes help the algorithm converge. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Internal Rate of Return as a decimal.
- E.g., `0.145` implies a 14.5% rate of return.
- If the algorithm cannot find a result after 20 iterations that is accurate within 0.00001%, it will fail and return `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ingests the array of cash flows. It checks to ensure there is at least one negative cash flow (investment) and at least one positive cash flow (return). If all numbers have the same sign, IRR is mathematically impossible, and it returns `#MISSING`.
2. **Missing Handling**: It typically treats `#MISSING` data points within the array as `0` (a period with no cash movement).
3. **Iterative Algorithm**: Starting with the `guess` (or 10%), it discounts the array of cash flows and sums them (NPV). It adjusts the rate up or down iteratively based on whether the NPV was positive or negative, honing in on zero.
4. **Return**: Once the NPV hits zero, the discount rate used to achieve it is passed back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Dynamic Array Evaluation

```essbase
/* 
   Evaluates the cash flow across Year 0 through Year 5.
   Assumes a 10% guess.
*/
"Project_IRR" = @CalcMgrExcelIRR("Project_Cash_Flow"->@CHILDREN("Project_Lifespan"));
```

---

## Practical Examples

### Example 1: Project Approval Threshold

**Scenario**: A company is planning multiple capital projects. They load the `"Initial_Investment"` (negative) in Year 0, and the expected `"Operating_Cash_Inflows"` (positive) in Years 1 through 5 into an account called `"Net_Project_Cash_Flow"`. The CFO dictates that any project with an IRR below 12% is automatically rejected.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    /* Calculate the IRR across the 6-year lifespan (Yr0 to Yr5) */
    "Calculated_IRR" = @CalcMgrExcelIRR(
        "Net_Project_Cash_Flow"->@CHILDREN("Total_Project_Lifespan"), 
        0.1 /* 10% starting guess */
    );
    
    /* Evaluate against the hurdle rate (12%) */
    IF("Calculated_IRR" != #MISSING)
        
        IF("Calculated_IRR" >= 0.12)
            "Project_Status_Flag" = 1; /* Approved */
        ELSE
            "Project_Status_Flag" = 0; /* Rejected */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Negative Cash Flows | Array only contains positive profits | IRR fundamentally requires an initial investment (cash *leaving* your pocket) followed by returns. If the array only contains positive numbers, the math is undefined, and the Java engine will fail. The first value in your array is almost always negative |
| Array Ordering | Mixing up the Time dimension order | The `IRR` algorithm assumes the cash flows occur at equal intervals, *in the exact order they are passed*. If your `@CHILDREN` array pulls data in reverse chronological order, or skips periods unpredictably, the timing of the discounting will be completely wrong, resulting in a wildly inaccurate IRR. Ensure chronological sorting |
| Non-Periodic Data | Using IRR for random dates | `IRR` assumes exactly equal time periods between cash flows (e.g., exactly 1 year, exactly 1 month). If your cash flows occur on highly irregular dates (e.g., Jan 1, Feb 14, Aug 2), standard `IRR` is mathematically invalid. You must use `@CalcMgrExcelXIRR`, which allows you to pass an array of specific dates |
| Multiple IRRs | Cash flow changes sign multiple times | If the cash flow alternates signs (e.g., Invest, Return, Invest, Return), mathematical polynomials dictate that there might be *multiple* valid IRRs. The function will just return the first one it finds based on your `guess`. Adjust the `guess` if the result looks highly suspicious |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelXIRR`](./@CalcMgrExcelXIRR.md) | Calculates the IRR for cash flows that occur on irregular, specific dates (requires passing a second array of date integers) |
| [`@CalcMgrExcelNPV`](./@CalcMgrExcelNPV.md) | Calculates the Net Present Value (the dollar value of the project based on a hardcoded discount rate, rather than solving for the rate itself) |
| [`@CalcMgrExcelMIRR`](./@CalcMgrExcelMIRR.md) | Calculates the Modified IRR, which accounts for differing borrowing rates and reinvestment rates |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelirr.html)
