# @GROWTH

## Overview

`@GROWTH` is a **native Essbase mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the mathematical **percentage growth** of a data set over a specified time range based on a fixed or dynamic percentage rate. It essentially calculates $Value_{new} = Value_{old} \times (1 + Rate)$.

### Why Does This Function Exist—

When building strategic long-range plans (LRP) or standard forecasting models, you rarely input flat dollar amounts for future years. You establish a baseline (e.g., Year 0 Revenue) and assign a "Growth Rate" assumption (e.g., $5\%$).
To project Year 1 through Year 5, an administrator could write a manual cell-by-cell loop (`@CALCMODE(CELL)`), where Year 2 reads the result of Year 1 and multiplies it by $1.05$. However, writing recursive loops is prone to circular reference errors and is slow to execute. 
`@GROWTH` automates this logic entirely. By passing it the base value and the growth rate, Essbase handles the recursive array math natively. It iterates across the time range, applying the growth curve period by period, and outputs the total projected dollar value into each respective block.

### When to Use It

- **Revenue Projections**: Projecting monthly sales for a new product based on a $2\%$ month-over-month target growth rate.
- **Expense Inflation**: Inflating a static `"Base_Cost"` by an assumed `"Annual_Inflation_Rate"` to accurately model future operating expenses.
- **Headcount Modeling**: Projecting organic workforce expansion across multiple regions based on historical percentage trends.

---

## Category

**Mathematical / Financial Projections / Essbase Native Functions**

---

## Syntax

```essbase
@GROWTH(Base_Value, Rate, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Base_Value` | Numeric / Member | ✅ Yes | The starting dollar value or metric (e.g., `1000000` or `"Prior_Year_Revenue"`). |
| `Rate` | Numeric / Member | ✅ Yes | The growth rate, expressed as a decimal (e.g., `0.05` for 5%). <br>*Note: This rate can be a hardcoded number, or a member that contains different rates in different months.* |
| `XrangeList` | Member Range | ❌ No  | The specific time periods over which to apply the growth. <br>If omitted, defaults to the `Time` dimension members in the current `FIX`. |

---

## Return Value

**Return Type**: Numeric (Block Vector)

Returns the final calculated dollar amount (Base + Growth) for each period in the range.
- **Recursive Execution**: In Period 1, it calculates $Base \times (1 + Rate)$. In Period 2, it calculates $Period1 \times (1 + Rate)$. 
- **Dynamic Rates**: If `Rate` points to a member that has `0.05` in Jan, and `-0.02` in Feb, the function will correctly calculate $5\%$ growth in Jan, and a $2\%$ contraction in Feb.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: Essbase locks onto the `Base_Value` and the `Rate`.
2. **Time Series Traversal**: It identifies the `XrangeList` (e.g., `Jan:Dec`).
3. **Period 1 Calculation**: It calculates the value for the first period.
4. **Recursive Iteration**: It carries the result of Period 1 into memory, uses it as the new baseline for Period 2, applies the rate for Period 2, and continues this chain across the entire list.
5. **Data Write**: It returns the array of fully inflated dollar amounts into the target block.

---

## Syntax Variants & Scenarios

### Variant 1: Fixed Rate Baseline Growth

```essbase
/* 
   Grows the starting base value by exactly 3% every period.
*/
"Projected_Revenue" = @GROWTH("Prior_Year_Actuals", 0.03);
```

---

## Practical Examples

### Example 1: Projecting Dynamic SaaS Revenue

**Scenario**: A software company is building its 5-year Long Range Plan. The `"Ending_ARR"` from Year 0 is stored in an assumption account. The FP&A team has entered varying `"Target_Growth_Rates"` into each future year (e.g., $15\%$ in FY25, $12\%$ in FY26, $8\%$ in FY27). The script must calculate the final projected ARR dollars for every year based on those dynamic rates.

```essbase
FIX("Working", "Total_Products", "No_Entity")
    
    /* 
       1. We use @GROWTH to calculate the compounding ARR curve.
       - Base Value: "FY24"->"Ending_ARR"
       - Rate: "Target_Growth_Rate" (which fluctuates year by year)
       - Range: FY25 through FY29
    */
    "Projected_ARR" = @GROWTH(
        "Ending_ARR"->"FY24", 
        "Target_Growth_Rate", 
        "FY25":"FY29"
    );
    
    /*
       Results:
       If FY24 ended at $10M.
       FY25 (15%) = $11.5M
       FY26 (12%) = $12.88M
       FY27 (8%)  = $13.91M
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Rate vs Percentage | Passing `5` instead of `0.05` | Essbase mathematical functions expect rates to be expressed as pure decimals. If you pass `5` for 5%, Essbase treats it as `500%`, and your projections will explode into billions of dollars instantly. Always divide whole percentages by 100 before passing them |
| Confusing `@GROWTH` with `@COMPOUND` | Which to use— | Mathematically, if you use a fixed rate, `@GROWTH` and `@COMPOUND` return the exact same numbers. However, `@GROWTH` allows the *Rate* to be dynamic across the time periods, whereas `@COMPOUND` is generally designed for fixed financial interest calculations |
| Using the Wrong Base Period | Pointing to a moving base | If you want to project a curve, your `Base_Value` should generally be a static, isolated anchor (like `"FY24"->"Actuals"`). If you just point `Base_Value` to the current calculating member, Essbase will try to grow the current period off of itself, creating `#MISSING` loops or circular logic. Always anchor the base |
| Expecting the Delta | `"Variance" = @GROWTH(...)` | This function returns the TOTAL projected value (the baseline PLUS the growth amount). It does NOT isolate the variance. If you start with $\$100$ and grow by $5\%$, the output is $\$105$. If you ONLY wanted the $\$5$ delta to put on a P&L variance line, you must use `@COMPOUNDGROWTH` or manually subtract the base |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@COMPOUND`](../08_Financial/@COMPOUND.md) | A specialized financial version of growth, typically used for fixed-rate interest and treasury calculations rather than dynamic P&L projections |
| [`@COMPOUNDGROWTH`](./@COMPOUNDGROWTH.md) | Isolates the mathematical delta (the growth amount ONLY) rather than returning the total accumulated value |
| [`@TREND`](../07_Statistical/@TREND.md) | Projects future values based on statistical linear regression of past actuals, rather than relying on a user-input percentage rate |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — GROWTH](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/growth.html)
