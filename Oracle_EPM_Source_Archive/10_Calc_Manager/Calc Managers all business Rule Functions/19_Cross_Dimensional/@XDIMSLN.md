# @XDIMSLN

## Overview

`@XDIMSLN` is a **native Essbase specialized financial function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates **Straight-Line Depreciation** (or amortization) for an asset. Crucially, the `XDIM` prefix means this function is explicitly designed to calculate and push the depreciation values across **multiple different periods and cross-dimensional intersections** simultaneously, rather than just calculating a single value for a single block.

### Why Does This Function Exist?

Standard straight-line depreciation is simple math: `(Cost - Salvage Value) / Lifespan`. 
The standard `@SLN` function performs this math, but it only returns the answer to the *current block* being calculated. You have to put it inside a massive Time loop, check if the asset is active every month, execute the math, and stop when the lifespan ends. This is tedious and slow.
`@XDIMSLN` was created to automate the entire lifecycle distribution. You feed it the asset's Cost, its Lifespan, and an `XrangeList` (a custom multi-year timeline). The C-engine takes over. It calculates the monthly depreciation, finds the asset's start date, steps through the `XrangeList`, automatically writes the depreciation into every single month, and mathematically halts exactly when the asset's lifespan is exhausted. It manages the entire asset lifecycle autonomously.

### When to Use It

- **CapEx Planning**: Distributing straight-line depreciation across a 5-year multi-dimensional time range (`FY24-Jan` to `FY28-Dec`) for newly purchased IT equipment.
- **Pre-paid Expense Amortization**: Automatically spreading a massive 12-month software license fee evenly across the fiscal year.
- **Loan Amortization**: Spreading the principal of a zero-interest intercompany loan across the remaining periods of the contract.

---

## Category

**Financial / Asset Lifecycle & Depreciation / Essbase Native Functions**

---

## Syntax

```essbase
@XDIMSLN(costMbr, salvageMbr, lifeMbr, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `costMbr` | Member/Numeric | ✅ Yes | The initial purchase price or principal amount to be depreciated (e.g., `"Capital_Cost"`). |
| `salvageMbr` | Member/Numeric | ✅ Yes | The residual value of the asset at the end of its life (e.g., `"Salvage_Value"`). Usually `0`. |
| `lifeMbr` | Member/Numeric | ✅ Yes | The useful lifespan of the asset in periods (e.g., `36` months). Must align with the granularity of the `XrangeList`. |
| `XrangeList`| Member List | ❌ No  | A custom time range over which the engine is allowed to distribute the depreciation. **Highly recommended to explicitly define using `@XRANGE`** to ensure it crosses year boundaries safely. |

---

## Return Value

**Return Type**: Numeric (Distributed Array)

Unlike standard functions, `@XDIMSLN` calculates the monthly amount and actively pushes it into the blocks defined by the `XrangeList`.
- **In-Life Periods**: Returns the periodic depreciation amount: `(Cost - Salvage) / Life`.
- **Post-Life Periods**: Once the asset hits the end of its lifespan, the function automatically returns `#MISSING` for all subsequent periods in the range.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The engine pulls the Cost, Salvage, and Life variables from the anchor block (usually the month the asset was purchased).
2. **Formula Execution**: It calculates the periodic payload (e.g., $(10,000 - 0) / 10 = 1,000$).
3. **Array Generation**: It compiles the `XrangeList` (e.g., `FY24` through `FY25`).
4. **Distribution Loop**: It starts writing `1,000` into the current calculating block. It steps to the next block in the `XrangeList`, writes `1,000`, decrements the Life counter, and continues.
5. **Termination**: When the Life counter hits `0`, it stops writing data and exits the loop.

---

## Syntax Variants & Scenarios

### Variant 1: Basic CapEx Distribution

```essbase
/* 
   Calculates depreciation for an asset and distributes it across FY24 and FY25.
*/
"Depreciation_Expense" = @XDIMSLN("Asset_Cost", 0, "Useful_Life", 
    @XRANGE("FY24"->"Jan", "FY25"->"Dec")
);
```

---

## Practical Examples

### Example 1: Multi-Year Software Amortization

**Scenario**: IT purchases a new Server for `$36,000` in `FY24->Jan`. The Useful Life is `36` months. The salvage value is `$0`. The FP&A admin wants Essbase to automatically spread `$1,000` a month starting in Jan and ending exactly 36 months later in `FY26->Dec`.

```essbase
/* 
   We FIX on the exact month the asset was purchased to serve as the anchor.
*/
FIX("Working", @LEVEL0("IT_Assets"), "FY24", "Jan")
    
    /* 
       1. Cost = $36,000. Salvage = 0. Life = 36.
       2. We provide an XRANGE spanning 4 years to give the engine plenty of runway.
       3. The engine calculates $1,000. It writes $1,000 into Jan. 
       It steps to Feb, writes $1,000... all the way to FY26-Dec.
       4. In FY27-Jan, the life is over. It stops writing.
    */
    "Depreciation_Expense" = @XDIMSLN("Purchase_Cost", "Salvage_Value", "Useful_Life", 
        @XRANGE("FY24"->"Jan", "FY27"->"Dec")
    );
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not Fixing on the Purchase Month | Massive Duplication | `@XDIMSLN` calculates and pushes data *forward*. If you `FIX` on all 12 months of the year, the engine will trigger the function in Jan (pushing 36 months of data). Then it steps to Feb, sees the cost, triggers *again*, and pushes 36 months of data starting from Feb (overwriting Jan's trajectory). You MUST FIX the script strictly on the "In-Service Date" or "Purchase Month" so the function only triggers once as an anchor point |
| Trapped by the Year Boundary | Missing `XrangeList` | If you don't provide an `@XRANGE`, the function relies on the Level-0 members of Time (`Jan:Dec`). When it hits `Dec`, it hits a wall and stops, even if the asset still has 24 months of life left. ALWAYS use an `@XRANGE` spanning multiple years |
| Using it for Declining Balance | Wrong Math | This is strictly Straight Line (SLN). The amount is identical every single month. If you need SYD (Sum of Years Digits) or Declining Balance depreciation, you must use `@XDIMSYD` or `@XDIMDECL` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SLN`](./@SLN.md) | The standard version. Calculates the straight-line math, but only returns a single value for the current block; does not automatically distribute across time |
| [`@_XDIMSLN`](./@_XDIMSLN.md) | The hidden sibling function. Identical in operation, but completely skips the *first* period, beginning the depreciation distribution in month 2 |
| [`@XRANGE`](./@XRANGE.md) | The critical utility function used to build the multi-year timeline required for the distribution |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — XDIMSLN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/xdimsln.html)
