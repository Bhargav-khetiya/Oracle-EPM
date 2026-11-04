# @CalcMgrExcelNPV

## Overview

`@CalcMgrExcelNPV` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `NPV` function directly inside an Essbase calculation script. 
It calculates the **Net Present Value** of an investment based on a specified discount rate and a series of future periodic cash flows.

### Why Does This Function Exist—

A dollar today is worth more than a dollar tomorrow. In corporate finance, if a project costs $1,000,000 today and returns $300,000 a year for 4 years, the total cash returned is $1,200,000. However, because you could have invested that initial $1M in a safe bond yielding 5%, those future returns must be discounted by 5% to see if the project actually destroys or creates "true" value in today's dollars.
To calculate NPV manually in Essbase, a developer must loop through every single year, grab the cash flow, divide it by `(1 + Rate) ^ Year_Index`, and sum all those discounted values into a master variable.
`@CalcMgrExcelNPV` bypasses the manual time-dimension looping. It takes a cross-dimensional array of cash flows, automatically applies the exponent-based discounting iteratively in the Java engine, and instantly returns the final summed value.

### When to Use It

- **CapEx Planning**: Calculating the true value created (or destroyed) by a proposed capital project or software implementation.
- **Valuation Modeling**: Running Discounted Cash Flow (DCF) models to estimate the enterprise value of a subsidiary based on its projected 5-year free cash flow.
- Whenever you need to migrate an Excel spreadsheet containing the `NPV` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelNPV(rate, cashflows)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `rate` | Numeric | ✅ Yes | The discount rate over one period (e.g., `0.08` for an 8% corporate hurdle rate). |
| `cashflows` | Array/List | ✅ Yes | An array of cash flows (both positive and negative). Usually passed as a cross-dimensional range like `"Net_Cash_Flow"->@CHILDREN("Forecast_Years")`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Net Present Value of the cash flows in today's dollars.
- A positive NPV means the project is profitable above the discount rate. A negative NPV means the project destroys value.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ingests the discount rate and the array of cash flows.
2. **Missing Handling**: It typically treats `#MISSING` data points within the array as `0` (a period with no cash movement).
3. **Iterative Discounting**: It loops through the array. 
   - Note: Unlike strict financial theory which treats the initial investment at Time 0, **Excel's NPV function assumes the first cash flow in the array occurs at the end of Period 1**. It discounts the first value by `(1 + rate)^1`, the second by `(1 + rate)^2`, etc.
4. **Aggregation**: It sums all the discounted values together.
5. **Return**: Passes the final summed dollar value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Dynamic Array Evaluation

```essbase
/* 
   Evaluates cash flows across Years 1 through 5.
   Applies an 8% discount rate.
*/
"Calculated_NPV" = @CalcMgrExcelNPV(0.08, "Project_Cash_Flow"->@CHILDREN("Future_Years"));
```

---

## Practical Examples

### Example 1: Standard Project NPV (Correcting Excel's Time 0 Flaw)

**Scenario**: A company evaluates a 5-year project. The initial investment (`$1,000,000` outflow) happens *today* (Time 0). The returns happen in Years 1 through 5. Because Excel's `NPV` function incorrectly assumes the very first number in an array happens at the end of Year 1, you must NOT include the initial investment in the `NPV` array. You must calculate the `NPV` of the returns (Years 1-5), and then manually add the initial Time 0 investment outside the function. This is standard FP&A practice.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    /* Ensure the project has an initial investment */
    IF("Initial_Investment" < 0)
        
        /* 
           1. Calculate the Present Value of the FUTURE cash flows (Years 1-5).
           Assuming a 10% discount rate (0.10).
        */
        VAR vDiscountedReturns = @CalcMgrExcelNPV(
            0.10, 
            "Net_Cash_Flow"->@CHILDREN("Future_5_Years")
        );
        
        /* 
           2. Add the initial investment (which is already in today's dollars, 
           and is a negative number) to the discounted returns.
        */
        "Project_NPV" = "Initial_Investment" + vDiscountedReturns;
        
        /* Flag for approval if NPV is positive */
        IF("Project_NPV" > 0)
            "Approval_Flag" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| The "Time 0" Flaw | Including Year 0 in the array | This is the #1 mistake made in both Excel and Essbase. `NPV` assumes the very first item in the array occurs 1 year from now. If you put your initial investment inside the `cashflows` array, it will be incorrectly discounted by 1 year, throwing off the entire valuation. Always calculate the `NPV` of future cash flows, and add the Year 0 investment manually outside the function |
| Array Ordering | Mixing up the Time dimension order | The Java engine assumes cash flows occur at equal intervals, in the exact order they are passed. If your `@CHILDREN` array pulls data in reverse chronological order, the heaviest discounts will be applied to the earliest years, ruining the math. Ensure chronological sorting |
| Non-Periodic Data | Using NPV for random dates | `NPV` assumes exactly equal time periods between cash flows (e.g., exactly 1 year). If cash flows occur on highly irregular dates, you must use `@CalcMgrExcelXNPV`, which allows you to pass an array of specific dates |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelXNPV`](./@CalcMgrExcelXNPV.md) | Calculates NPV for cash flows that occur on irregular, specific dates (requires passing a second array of date integers) |
| [`@CalcMgrExcelIRR`](./@CalcMgrExcelIRR.md) | Calculates the Internal Rate of Return (finds the exact discount rate that makes the NPV perfectly equal to 0) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelnpv.html)
