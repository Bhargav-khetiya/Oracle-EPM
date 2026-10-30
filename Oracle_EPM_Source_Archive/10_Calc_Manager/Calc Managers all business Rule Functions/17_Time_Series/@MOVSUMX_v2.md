# @MOVSUMX

## Overview

`@MOVSUMX` is a **native Essbase time-series array function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates a **Moving Sum** (or rolling total) across a specified time series. For every member in the time range, it looks backward a defined number of periods, sums those periods together, and writes the total into the current block. 

*Crucially, the "X" denotes that this function accepts a dynamic numeric expression/formula as its input, rather than just a static member name.*

### Why Does This Function Exist?

The standard `@MOVSUM` function (without the X) is highly efficient, but it only accepts a single, raw member name (like `"Sales"`). 
But what if the metric you want to roll up doesn't physically exist in the database? What if you need to calculate the "Rolling 12-Month Net Margin", but `"Net_Margin"` is not stored anywhere; it must be calculated on the fly as `("Revenue" - "Expenses")`?
If you only had `@MOVSUM`, you would be forced to calculate the Net Margin, store it in a dummy account, run the `@MOVSUM` on that dummy account, and then clear the dummy account. This wastes immense calculation time and database space.
`@MOVSUMX` solves this by accepting a raw mathematical expression. It calculates the `("Revenue" - "Expenses")` formula in memory for every period in the historical window, sums the results of those on-the-fly calculations, and writes the final rolling total to the target block. 

### When to Use It

- **Dynamic Trailing Twelve Months (TTM)**: Calculating the TTM sum of a complex KPI (like Gross Profit Margin or EBITDA) without having to store the baseline monthly KPI in the database.
- **Rolling Accruals**: Summing up a dynamically generated expense accrual (`"Headcount" * "Rate"`) over a trailing 6-month window to check against a contract ceiling.
- **Performance Thresholds**: Summing the total number of "Breach Days" in a quarter by passing a boolean evaluation formula into the moving sum.

---

## Category

**Mathematical / Array Aggregation & Rolling / Essbase Native Functions**

---

## Syntax

```essbase
@MOVSUMX(Expression, n, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Expression` | Formula | ✅ Yes | The mathematical formula or expression to be evaluated and summed (e.g., `"Sales" * 1.5`, or `"Revenue" - "Cost"`). |
| `n` | Integer | ✅ Yes | The size of the sliding window (how many periods to look backward, *including* the current period). Must be $\ge 1$. |
| `XrangeList`| Member List | ❌ No  | A custom time range over which the moving sum is calculated. If omitted, Essbase uses the Level-0 Time members. **Required if crossing year boundaries.** |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the calculated rolling sum of the evaluated expression and writes it to the current block.
- **Ramp-Up Periods**: If `n = 12`, but the engine is calculating `"Mar"`, it sums whatever valid evaluations it can find (Jan, Feb, Mar).
- **Missing Data**: If the mathematical `Expression` evaluates to `#MISSING` for a specific historical month, that month contributes `0` to the total sum.

---

## How It Works (Behind the Scenes)

1. **Window Initialization**: The C-engine reads the `n` parameter and creates an internal memory window.
2. **Iteration**: It steps through the `XrangeList` one period at a time.
3. **Expression Evaluation**: For the current period and the trailing `n-1` periods, it executes the `Expression` in memory.
4. **Summation**: It aggregates the results of all those in-memory evaluations.
5. **Write**: It writes the final summed total to the current block, slides the window forward one step, and repeats.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Sum of a Formula

```essbase
/* 
   Calculates the trailing 3-month total of Net Profit.
*/
"Trailing_3M_Profit" = @MOVSUMX(("Revenue" - "Expenses"), 3, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Trailing Twelve Month (TTM) Commission Accrual (Crossing Years)

**Scenario**: A company pays a year-end bonus based on the TTM (Trailing Twelve Month) `"Total_Commission_Pool"`. However, the pool is never stored in the database. It is calculated dynamically as `"Total_Sales" * "Commission_Rate"`. The FP&A team uses `@MOVSUMX` and `@XRANGE` to calculate this TTM metric on the fly, crossing the boundary from FY24 into FY25 seamlessly.

```essbase
FIX(@LEVEL0("Entity"))
    
    /* 
       1. We use @XRANGE to fuse FY24 and FY25 into a single continuous time stream.
       2. We use @MOVSUMX with a window of 12.
       3. We pass the dynamic calculation ("Total_Sales" * "Commission_Rate") 
       directly into the function.
    */
    "TTM_Commission_Pool" = @MOVSUMX(("Total_Sales" * "Commission_Rate"), 12, 
        @XRANGE("FY24"->"Jan", "FY25"->"Dec")
    );
    
    /* 
       Results for FY25 -> Jun:
       The engine looks back from FY25-Jun to FY24-Jul.
       For EVERY ONE of those 12 months, it multiplies Sales by the Rate.
       It adds all 12 results together.
       It stores the massive total in the FY25-Jun block.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Overusing the "X" Variant | Performance Degradation | If you just want the rolling sum of a static account (`"Revenue"`), DO NOT use `@MOVSUMX("Revenue", 3)`. Use the standard `@MOVSUM("Revenue", 3)`. The "X" variant forces the engine to spin up a formula-evaluation thread for every single period in the window. Using it on static members adds unnecessary computational overhead |
| Cross-Dimensional Expressions | Syntax Errors | When building the `Expression`, ensure any cross-dimensional pointers are wrapped in parentheses. Writing `"Sales"->"Actual" * 1.5` might confuse the parser. Always write `("Sales"->"Actual" * 1.5)` |
| Trapped by the Year Boundary | Not using `XrangeList` | If you omit the `XrangeList`, the calculation for January has nowhere to look backward to. A TTM calculation in January will literally just be January's data. You MUST use `@XRANGE` to create a continuous multi-year time stream |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MOVSUM`](./@MOVSUM.md) | The standard version. Calculates the rolling sum of a static member without the formula-evaluation overhead |
| [`@MOVAVGX`](./@MOVAVG.md) | Calculates the rolling *average* of a dynamic formula/expression |
| [`@XRANGE`](../18_Range_Set_Operations/@XRANGE.md) | The critical utility function used to stitch multiple years together to allow moving functions to cross year boundaries |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MOVSUMX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/movsumx.html)
