# @DISCOUNT

## Overview

`@DISCOUNT` is a **native Essbase financial function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the **Present Value (PV)** of a future stream of cash flows based on a specific discount rate. It takes future dollar amounts and mathematically discounts them back to "today's dollars" to account for the time value of money.

### Why Does This Function Exist—

A dollar today is worth more than a dollar five years from now due to inflation and lost investment opportunity (the time value of money). When evaluating long-term capital projects, acquisitions, or real estate leases, a company might expect to receive `$1,000,000` in Year 5. But to compare that project against other investments *today*, FP&A teams must discount that future `$1,000,000` back to its present value using the company's Weighted Average Cost of Capital (WACC) or a hurdle rate.
Writing the exponential present value formula ($PV = \frac{FV}{(1 + r)^n}$) manually across an entire 10-year array using `@POWER` is extremely tedious. 
`@DISCOUNT` automates this. You pass it the array of future cash flows and the discount rate. Essbase automatically calculates the time-period offset ($n$) for every single period in the range, executes the discounting math, and returns the Present Value for each respective period.

### When to Use It

- **Net Present Value (NPV) Analysis**: Discounting future project cash inflows back to Year 0 to determine if a capital expenditure will generate a positive return.
- **Lease Liability Valuation**: Calculating the present value of future lease payments to capitalize the lease on the Balance Sheet (IFRS 16 / ASC 842 compliance).
- **M&A Valuations**: Discounting 10 years of projected cash flows from a target acquisition to determine a fair purchase price today.

---

## Category

**Financial & Mathematical / Valuation & Present Value / Essbase Native Functions**

---

## Syntax

```essbase
@DISCOUNT(CashFlows, Rate, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `CashFlows` | Numeric / Member | ✅ Yes | The future dollar amounts to be discounted (e.g., `"Projected_Cash_Flow"`). |
| `Rate` | Numeric / Member | ✅ Yes | The discount rate (or hurdle rate) per period, expressed as a decimal (e.g., `0.08` for 8%). |
| `XrangeList` | Member Range | ❌ No  | The range of periods representing time ($n$). <br>If omitted, defaults to the `Time` dimension members in the current `FIX`. |

---

## Return Value

**Return Type**: Numeric (Block Vector)

Returns the calculated Present Value for *each individual period* in the range.
- **Output Definition**: It does NOT return a single summed total (like NPV). It returns an array. If Year 1 Cash Flow is `$100` and Year 2 is `$100`, it returns `$92` in Year 1 and `$85` in Year 2. To get the Total NPV, you must `@SUM` the resulting account.
- **Time Offset ($n$)**: Essbase natively increments the exponent ($n$) based on the position of the member in the `XrangeList`. The first member is $n=1$, the second is $n=2$.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: Essbase locks onto the `CashFlows` account and the `Rate`.
2. **Range Indexing**: It evaluates the `XrangeList`. It assigns an internal integer ($n$) to each member. (e.g., `FY24` = 1, `FY25` = 2, `FY26` = 3).
3. **Execution Loop**: For each period, it executes the formula: 
   $$ PV = \frac{CashFlow}{(1 + Rate)^n} $$
4. **Data Write**: It returns the array of discounted values into the target block.

---

## Syntax Variants & Scenarios

### Variant 1: Fixed Rate Discounting (Default Time Range)

```essbase
/* 
   Discounts the future Cash Flows at a strict 8% corporate hurdle rate. 
*/
"Present_Value" = @DISCOUNT("Future_Cash_Flow", 0.08);
```

---

## Practical Examples

### Example 1: Capital Project NPV Calculation

**Scenario**: A company is evaluating a new factory. The `"Net_Cash_Flow"` for the next 5 years is projected. The company uses a `10%` discount rate (`0.10`). The script must calculate the Present Value of every future year, and then sum them up into `"Total_NPV"` to see if the project is viable.

```essbase
FIX("Working", "Project_Alpha", "No_Entity")
    
    /* 
       1. Calculate the Present Value for each individual year.
       Rate is 10% (0.10).
       Range is FY24 to FY28.
    */
    "Present_Value" = @DISCOUNT("Net_Cash_Flow", 0.10, "FY24":"FY28");
    
    /* 
       2. Sum up all the discounted periods to get the final Net Present Value.
       (If the NPV is > 0, the project is a "Go").
    */
    "Total_NPV" = @SUM(@RANGE("Present_Value", "FY24":"FY28"));
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Rate vs Percentage | Passing `8` instead of `0.08` | Essbase mathematical functions expect rates to be expressed as pure decimals. If you pass `8` for 8%, Essbase interprets that as `800%`. Your denominator will become massive, and your Present Value will instantly drop to `$0.00`. Always divide whole percentages by 100 before passing them |
| Mismatched Time Horizons | Applying an 8% Annual rate across Monthly periods | The `Rate` must match the frequency of the `XrangeList`. If your range is `Jan:Dec` (monthly), and you pass `0.08` (8% annual), Essbase will discount it by 8% *every single month*. If the range is months, you must divide the annual rate by 12: `@DISCOUNT(Flow, (Rate/12), "Jan":"Dec")` |
| Expecting a Single NPV Output | `"NPV" = @DISCOUNT(...)` | `DISCOUNT` is a vector function. It returns an array of numbers (one for each year). It does NOT automatically sum them together. If you want the total Net Present Value of the project, you must calculate the discount first, and then wrap it or follow it with an `@SUM` function (see Example 1) |
| Period 0 Errors | Year 0 Cash Flows | The function inherently starts discounting at $n=1$ for the first member in the list. If your capital model has a "Year 0" (an immediate upfront cash outflow that should NOT be discounted), do not include Year 0 in the `XrangeList`. Run the discount on Years 1-5, and then manually add the Year 0 outflow to the final sum |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@NPV`](./@NPV.md) | A combined function that natively executes the discount AND sums all the periods together in a single step, often preferred if you don't need to see the individual periodic PVs |
| [`@IRR`](./@IRR.md) | Calculates the Internal Rate of Return (the exact discount rate required to make the NPV equal to exactly zero) |
| [`@COMPOUND`](./@COMPOUND.md) | The mathematical opposite. It calculates the Future Value (FV) of a present amount, rather than the Present Value (PV) of a future amount |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — DISCOUNT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/discount.html)
