# @CalcMgrExcelFVSCHEDULE

## Overview

`@CalcMgrExcelFVSCHEDULE` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `FVSCHEDULE` function directly inside an Essbase calculation script. 
It calculates the **Future Value** of an initial principal sum after applying a series of **variable (changing) interest rates**.

### Why Does This Function Exist?

Standard Future Value (`FV`) assumes that the interest rate stays perfectly flat for the entire life of the investment. However, in reality, many investments (like adjustable-rate CDs, staggered corporate bonds, or dynamic inflation-adjusted funds) have interest rates that change every single year.
To project the future value of a $10,000 seed that grows at 3% in Year 1, 4% in Year 2, and 5% in Year 3, you would normally have to write an iterative loop in Essbase: `((Seed * 1.03) * 1.04) * 1.05`. If the investment spans 30 years, this loop becomes cumbersome and slow.
`@CalcMgrExcelFVSCHEDULE` takes the initial principal and an entire array of varying interest rates. The Java engine automatically iterates through the array, compounding the principal sequentially against each rate, and instantly returns the final balance.

### When to Use It

- **Corporate Treasury**: Projecting the final payout of stepped-rate corporate bonds or structured notes.
- **Inflation Modeling**: Calculating the future cost of a capital project by compounding an initial estimate against a multi-year array of forecasted inflation rates.
- Whenever you need to migrate an Excel spreadsheet containing the `FVSCHEDULE` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelFVSCHEDULE(principal, schedule)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `principal` | Numeric | ✅ Yes | The initial present value or starting seed money (e.g., `10000`). Note: Unlike `FV`, this is typically passed as a **positive** number to yield a positive future value. |
| `schedule` | Array/List | ✅ Yes | An array of varying interest rates (decimals). This is usually passed as a cross-dimensional range like `"Interest_Rate"->@CHILDREN("All_Years")` or a hardcoded comma-separated list. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the compounded Future Value of the principal.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ingests the principal and the array of rates.
2. **Missing Handling**: It typically treats `#MISSING` rates in the array as `0` (meaning no growth for that specific period).
3. **Iterative Compounding**: It loops through the array in order. For the first rate, it calculates `Principal * (1 + Rate[0])`. It takes that new balance, and multiplies it by `(1 + Rate[1])`, and so on.
4. **Return**: Passes the final accumulated value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Passing a Hardcoded List of Rates

```essbase
/* 
   Principal: $10,000
   Rates: 3%, 4.5%, 5%
   Result: 10000 * 1.03 * 1.045 * 1.05 = 11,301.67
*/
"Future_Balance" = @CalcMgrExcelFVSCHEDULE(10000, 0.03, 0.045, 0.05);
```

### Variant 2: Passing an Essbase Array

```essbase
/* Pulls the forecasted rates dynamically from the Time dimension */
"Future_Balance" = @CalcMgrExcelFVSCHEDULE(10000, "Forecasted_Rate"->@CHILDREN("All_Years"));
```

---

## Practical Examples

### Example 1: Inflation-Adjusted CapEx Forecasting

**Scenario**: A mining company plans to build a new processing plant in 5 years. Based on today's prices, the plant costs `$50,000,000`. However, the cost of raw materials and labor will inflate every year. The macroeconomic team provides an array of forecasted inflation rates for the next 5 years (e.g., Year 1: 4%, Year 2: 6%, Year 3: 3%). The FP&A team uses `FVSCHEDULE` to compound the current estimated cost against the inflation curve to find the true future funding requirement.

```essbase
FIX("Working", "Total_Company", "Project_Alpha")
    
    /* Ensure we have a baseline cost */
    IF("Current_Cost_Estimate" > 0)
        
        /* 
           Compound the cost against the array of inflation rates for the next 5 years.
           The array pulls dynamically from the global macroeconomic assumptions block.
        */
        "Future_Funding_Requirement" = @ROUND(
            @CalcMgrExcelFVSCHEDULE(
                "Current_Cost_Estimate", 
                "Macro_Assumptions"->"Inflation_Rate"->@CHILDREN("Next_5_Years")
            )
        , 0); /* Round to whole dollars */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Whole Number Rates | Passing `5` instead of `0.05` | The `schedule` array explicitly expects decimals. If the rate is 5%, the data must be `0.05`. If the array contains `5`, the engine will calculate a 500% compounding interest rate for that period, destroying the result |
| Sign Convention | Passing a negative principal | Unlike the standard `FV` function (which strictly adheres to cash-flow sign conventions), `FVSCHEDULE` is essentially just a raw compounding multiplier. If you pass a positive `$10,000` principal, you get a positive future value. If you pass a negative principal, you get a negative future value. Do not artificially negate the principal unless you specifically want a negative result |
| Array Ordering | Mixing up the Time dimension order | The Java engine compounds the rates in the exact order they are passed in the array. If your `@CHILDREN` array accidentally pulls data in descending chronological order (e.g., Year 5, Year 4, Year 3), the math technically yields the same final result (due to the commutative property of multiplication), but if you ever attempt to intercept the calculation mid-stream, it will be logically backwards. Ensure your time arrays are sorted chronologically |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelFV`](./@CalcMgrExcelFV.md) | Calculates Future Value based on a *fixed* (constant) interest rate and periodic payments |
| [`@CalcMgrExcelPRODUCT`](./@CalcMgrExcelPRODUCT.md) | A basic math function that multiplies an array of numbers together (essentially the manual building block of `FVSCHEDULE` if you were to add 1 to all the rates first) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelfvschedule.html)
