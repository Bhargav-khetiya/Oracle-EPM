# @CalcMgrExcelFV

## Overview

`@CalcMgrExcelFV` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `FV` function directly inside an Essbase calculation script. 
It calculates the **Future Value** of an investment based on periodic, constant payments and a constant interest rate.

### Why Does This Function Exist—

In corporate treasury, wealth management, and capital planning models, analysts frequently need to project the future value of a sinking fund, a corporate reserve account, or a bond investment. 
For example, if a company seeds a reserve account with $10,000, adds $1,000 every single month, and the account yields 5% annually, how much cash will be in the account after 5 years—
To calculate this manually in Essbase, a developer would have to write a highly inefficient looping script to compound the interest and add the new principal month by month. `@CalcMgrExcelFV` entirely eliminates the need for looping. It uses the Java financial engine to execute the integral compound interest formula, instantly calculating the exact future balance. This guarantees parity with legacy Excel models and radically speeds up the calculation.

### When to Use It

- **Corporate Treasury**: Projecting the future balance of sinking funds designed to pay off massive debts at maturity.
- **Capital Planning**: Forecasting how much cash will be available in an interest-bearing reserve account for future CapEx projects.
- Whenever you need to migrate an Excel spreadsheet containing the `FV` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelFV(rate, nper, pmt, pv, type)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `rate` | Numeric | ✅ Yes | The interest rate per period (e.g., if Annual Rate is 6%, and payments are monthly, `rate` = `0.06 / 12` = `0.005`). |
| `nper` | Numeric | ✅ Yes | The total number of payment periods (e.g., 5 years * 12 = `60`). |
| `pmt` | Numeric | ✅ Yes | The payment made each period. **Must be a negative number** representing cash outflow (e.g., `-1000`). If omitted, `pv` must be provided. |
| `pv` | Numeric | ❌ No  | The present value (initial lump sum seed amount). **Must be a negative number** (e.g., `-10000`). Defaults to 0 if omitted. |
| `type` | Numeric | ❌ No  | The timing of the payment. `0` = End of the period (standard). `1` = Beginning of the period (Advance payments). Defaults to 0 if omitted. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Future Value of the investment.
- **Sign Convention**: Because the inputs (`pmt` and `pv`) are treated as negative cash outflows (money leaving your pocket to go into the investment), the Future Value returned will be a **positive number** (cash returning to your pocket).

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures `nper` > 0.
2. **Integral Math**: The engine executes standard financial time-value-of-money mathematics. 
   - If `rate` is 0, it simply calculates: `-(pv + (pmt * nper))`.
   - If `rate` > 0, it uses the compounding formula: `-(pv * (1 + rate)^nper + pmt * (1 + rate * type) * (((1 + rate)^nper - 1) / rate))`.
3. **Return**: Passes the resulting positive cash value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Sinking Fund with Periodic Payments

```essbase
/* 
   Rate: 6% Annual (0.005 Monthly)
   Periods: 5 Years (60 Months)
   Payment: -$1,000 per month
   PV: -$10,000 initial seed
   Type: 0 (End of Month)
   Result: Calculates the total future balance (Returns ~$83,285)
*/
"Future_Fund_Balance" = @CalcMgrExcelFV(0.005, 60, -1000, -10000, 0);
```

---

## Practical Examples

### Example 1: Corporate CapEx Reserve Fund Projection

**Scenario**: A manufacturing firm sets aside a flat amount of cash every quarter into a reserve fund to eventually buy a new piece of machinery. The CFO wants to know exactly how much cash will be in that fund at the end of Year 3 (12 quarters). The model pulls the initial seed amount and the quarterly contribution amount from the assumptions block.

```essbase
FIX("FY25", "Working", "Corporate_Treasury")
    
    /* We only run this if the fund actually exists */
    IF("Reserve_Fund_Seed" > 0 OR "Reserve_Fund_Quarterly_Contribution" > 0)
        
        /* 1. Establish the rate (e.g., 4% annual / 4 quarters) */
        VAR vQuarterlyRate = "Annual_Yield_Rate" / 4;
        
        /* 2. Format cash flows as negative numbers (outflows into the fund) */
        VAR vSeedCashFlow = "Reserve_Fund_Seed" * -1;
        VAR vQtrCashFlow = "Reserve_Fund_Quarterly_Contribution" * -1;
        
        /* 3. Calculate Future Value after 12 quarters (3 years) */
        "Projected_CapEx_Fund_Balance" = @ROUND(
            @CalcMgrExcelFV(
                vQuarterlyRate, 
                12,             /* NPER: 12 quarters */
                vQtrCashFlow,   /* PMT */
                vSeedCashFlow,  /* PV */
                0               /* Type: End of Quarter */
            )
        , 2);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Frequencies | Passing `0.06` (Annual) but `60` (Months) | The `rate` and `nper` must be in the exact same time unit. If you are calculating monthly contributions over 5 years, the `nper` is 60, and the `rate` MUST be the annual rate divided by 12. If you pass 6% (0.06) against 60 periods, the interest will be massively overstated |
| Positive Cash Flows | Passing `1000` for PMT | Excel financial functions strictly use cash flow sign conventions. If you put money *into* an investment, it is a negative outflow (`-1000`). If you pass positive numbers for PV and PMT, the `FV` function will return a massive negative number, implying you owe that money |
| Omitted Parameters | `@CalcMgrExcelFV(0.05, 60, -1000)` | While Excel allows you to omit PV and Type, the Calc Manager Java wrapper can sometimes fail or return `#MISSING` if trailing arguments are dropped depending on your exact EPM patch version. It is always safest to explicitly pass `0` for `pv` and `0` for `type` if they are not used |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPV`](./@CalcMgrExcelPV.md) | The exact inverse function: Calculates the Present Value based on a future target balance |
| [`@CalcMgrExcelFVSCHEDULE`](./@CalcMgrExcelFVSCHEDULE.md) | Calculates the Future Value, but allows for a *variable* (changing) interest rate schedule rather than a fixed rate |
| [`@CalcMgrExcelPMT`](./@CalcMgrExcelPMT.md) | Calculates the exact payment amount required to reach a specific future value |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelfv.html)
