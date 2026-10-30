# @IRREX

## Overview

`@IRREX` is a **native Essbase financial function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the **Extended Internal Rate of Return (IRR)** for a series of cash flows that occur across a specified time horizon.

### Why Does This Function Exist?

The Internal Rate of Return is a critical corporate finance metric used to evaluate the profitability of an investment. It answers the question: "What discount rate forces the Net Present Value (NPV) of all my cash flows to exactly zero?"
The native `@IRR` function calculates this, but it requires an initial "guess" parameter to seed the mathematical algorithm. In massive EPM models (like a 500-project capital portfolio), guessing the IRR for every single project dynamically is nearly impossible. If the guess is too far off, the standard IRR algorithm fails to converge and returns an error.
`@IRREX` (IRR Extended) is the modernized version. It does NOT require a guess parameter. It utilizes a more advanced, exhaustive internal iteration engine that automatically searches for the convergence point across a much wider mathematical spectrum. It is highly robust and significantly easier to implement in automated calculation scripts than the legacy `@IRR`.

### When to Use It

- **Project ROI Valuations**: Evaluating the rate of return on a new product launch, balancing the massive Year 1 capital expenditures against the projected Year 2-5 revenue streams.
- **M&A Modeling**: Determining the IRR of acquiring a target company based on their projected 10-year free cash flow.
- **Capital Budgeting**: Ranking 50 different CapEx requests globally based on their respective IRRs, automatically funding the projects with the highest returns.

---

## Category

**Financial / Investment Valuation / Essbase Native Functions**

---

## Syntax

```essbase
@IRREX(cashflowMbr, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cashflowMbr` | Member | ✅ Yes | The specific account or metric containing the cash flows (e.g., `"Net_Cash_Flow"`). <br>*Crucial: This account MUST contain at least one negative value (outflow/investment) and one positive value (inflow/return).* |
| `XrangeList` | Member Range | ❌ No  | The specific time periods over which the cash flows occur. If omitted, defaults to the `Time` dimension members in the current `FIX`. |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the calculated Internal Rate of Return as a decimal.
- **Percentage Format**: The result is a true decimal (e.g., `0.15` represents `15%`).
- **Algorithm Failure**: If the cash flows are wildly erratic (e.g., alternating between massive positives and massive negatives every month), it is mathematically possible for multiple IRRs to exist, or for the algorithm to fail to converge. In these cases, it returns `#MISSING`.
- **Missing Data**: If the entire cash flow range is `#MISSING` or `0`, the function returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: Essbase locks onto the `cashflowMbr`.
2. **Time Series Traversal**: It identifies the `XrangeList` (e.g., `FY25:FY29`).
3. **Data Assembly**: It pulls the values for those periods into an internal memory array (e.g., `[-100, 20, 50, 70, 90]`).
4. **Newton-Raphson Iteration**: It initiates an iterative mathematical algorithm, testing different discount rates. It aims to solve the equation: $\sum \frac{C_t}{(1+r)^t} = 0$.
5. **Convergence & Return**: Once it finds the rate ($r$) that brings the equation to exactly zero (within an internal tolerance threshold), it returns that rate to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Basic IRR Calculation

```essbase
/* 
   Calculates the IRR across all Time periods currently in the FIX.
*/
"Project_IRR" = @IRREX("Net_Cash_Flow");
```

---

## Practical Examples

### Example 1: 5-Year Capital Project Valuation

**Scenario**: A company is building a new factory. `"Net_Cash_Flow"` holds the data. In Year 0 (`FY24`), they spend `$1,000,000` (stored as `-1,000,000`). In Years 1-4 (`FY25` to `FY28`), the factory generates positive cash flow. The script must calculate the IRR across this 5-year horizon and store it in a metrics account.

```essbase
FIX("Working", "Factory_Project", "No_Entity")
    
    /* 
       1. We calculate the IRR.
       We specifically target the Net Cash Flow account, and provide the 
       exact 5-year horizon as the XrangeList.
    */
    "Project_IRR" = @IRREX("Net_Cash_Flow", "FY24":"FY28");
    
    /*
       Results:
       FY24: -1,000,000 (Investment)
       FY25: 200,000    (Return)
       FY26: 350,000
       FY27: 400,000
       FY28: 500,000
       IRR converges to approximately 14.3% (0.143).
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Negative Cash Flows | All numbers are positive | IRR mathematically requires an initial investment (a cash outflow) to compare against future returns (inflows). If your `"Net_Cash_Flow"` account is `[100, 200, 300]`, the IRR is theoretically infinite, and the algorithm will fail or return `#MISSING`. You MUST ensure your data set contains at least one negative number |
| Not Anchoring the Output | IRR overwrites cash flows | If you write `"Net_Cash_Flow" = @IRREX("Net_Cash_Flow");`, Essbase will calculate the IRR and write the percentage back *on top* of your cash flows, destroying the data. You must always write the result to a completely separate metric account (like `"Project_IRR"`) |
| Block Explosion | Running on empty projects | If you run this across a "Projects" dimension with 10,000 empty placeholders, the engine will attempt the iteration algorithm 10,000 times, generating massive server overhead. Always wrap complex financial functions in `IF("Cash_Flow" != #MISSING)` to restrict execution to active projects |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@IRR`](./@IRR.md) | The legacy version of this function. It requires an initial "Guess" parameter. `@IRREX` is almost universally preferred because it auto-generates the guess |
| [`@NPV`](./@NPV.md) | Calculates the Net Present Value of the cash flows using a *fixed* discount rate, rather than solving for the rate itself |
| [`@DISCOUNT`](./@DISCOUNT.md) | A simplified present value calculation used when cash flows are constant, rather than varying year by year |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — IRREX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/irrex.html)
