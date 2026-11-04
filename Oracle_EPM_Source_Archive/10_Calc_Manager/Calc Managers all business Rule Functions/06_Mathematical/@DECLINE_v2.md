# @DECLINE

## Overview

`@DECLINE` is a **native Essbase financial function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the **Declining Balance Depreciation** for a capital asset across a specified range of time. It computes exactly how much value an asset loses in each specific period, allowing the expense to be mapped directly to the Income Statement.

### Why Does This Function Exist—

In corporate accounting, straight-line depreciation (where an asset loses the exact same amount of value every year) is easy to calculate (`Cost / Useful_Life`). However, for tax optimization and rapid-obsolescence assets (like computers or fleet vehicles), companies use Declining Balance Depreciation. This method heavily front-loads the depreciation expense, charging massive amounts in Year 1 and Year 2, and very little in Year 4 and Year 5.
Calculating this manually across an array requires complex recursive loops, because the depreciation in Year 2 is based on the *remaining book value* after Year 1 (`(Cost - Y1_Depreciation) * Rate`).
`@DECLINE` automates this entire recursive math chain. By passing the Cost, Salvage Value, Life, and the Depreciation Factor (Rate), Essbase iterates across the defined time range, calculates the declining book value in memory, and writes the exact depreciation expense into every period of the target block.

### When to Use It

- **Tax Planning**: Calculating MACRS or Double-Declining Balance depreciation on capital equipment to maximize near-term corporate tax deductions.
- **IT Hardware Lifecycles**: Accelerating the depreciation of servers and laptops that lose the majority of their technological value within the first 18 months of purchase.
- **Fleet Management**: Depreciating delivery vehicles based on heavy initial usage and rapid early-life value degradation.

---

## Category

**Financial & Mathematical / Depreciation & Amortization / Essbase Native Functions**

---

## Syntax

```essbase
@DECLINE(Cost, Salvage, Life, Factor, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Cost` | Numeric / Member | ✅ Yes | The initial purchase price or capitalized cost of the asset. |
| `Salvage` | Numeric / Member | ✅ Yes | The estimated residual value of the asset at the end of its useful life. The asset will NOT depreciate below this amount. |
| `Life` | Numeric / Member | ✅ Yes | The total useful life of the asset (in periods). Must match the granularity of the `XrangeList`. |
| `Factor` | Numeric / Member | ✅ Yes | The multiplier applied to the straight-line rate to accelerate the depreciation. <br>E.g., `2.0` = Double-Declining Balance. <br>`1.5` = 150% Declining Balance. |
| `XrangeList` | Member Range | ❌ No  | The range of periods to calculate across. <br>If omitted, defaults to the `Time` dimension members in the current `FIX`. |

---

## Return Value

**Return Type**: Numeric (Block Vector)

Returns the specific depreciation *expense* for each period in the range.
- **Output Definition**: It outputs the periodic expense (the Income Statement hit), NOT the accumulated depreciation or the remaining book value.
- **Salvage Protection**: The internal loop will mathematically stop depreciating the asset once the remaining book value hits the `Salvage` amount. It will output `0` for any remaining periods.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: Essbase locks onto the Cost, Salvage, Life, and Factor.
2. **Rate Calculation**: It calculates the standard straight-line rate (`1 / Life`) and multiplies it by the `Factor`. (e.g., Life 5, Factor 2 = `(1/5) * 2 = 40%`).
3. **Period 1 Execution**: It calculates Period 1 Depreciation: `Cost * Rate`.
4. **Recursive Loop**: For Period 2, it calculates the remaining Book Value (`Cost - P1_Depreciation`). It then multiplies that new Book Value by the Rate. 
5. **Salvage Check**: Before writing a result, it ensures `Book Value - New_Depreciation >= Salvage`. If it drops below, it truncates the depreciation to perfectly hit the Salvage line.
6. **Data Write**: It returns the array of expenses into the target block.

---

## Syntax Variants & Scenarios

### Variant 1: Double-Declining Balance (DDB)

```essbase
/* 
   Calculates DDB Depreciation for a $100k asset with $10k salvage over 5 years.
   The factor is 2.0 (Double).
*/
"Depreciation_Expense" = @DECLINE(100000, 10000, 5, 2.0, "FY24":"FY28");
```

---

## Practical Examples

### Example 1: Calculating Monthly Fleet Depreciation

**Scenario**: A logistics company buys delivery trucks for `$50,000`. They have a `$5,000` salvage value and a 4-year (48-month) useful life. The CFO wants to use a 150% Declining Balance (`1.5` Factor) to accelerate the expense early in the lifecycle. The script must calculate the monthly depreciation expense and push it to the P&L.

```essbase
FIX("FY25", "Working", @LEVEL0("Fleet_Vehicles"))
    
    /* 
       1. We FIX on all months of the year.
       2. We point the function at our assumption drivers.
       - Cost = 50000
       - Salvage = 5000
       - Life = 48 (Because we are calculating Months, the Life MUST be in months).
       - Factor = 1.5
    */
    FIX(@CHILDREN("YearTotal"))
        
        "Depreciation_Expense" = @DECLINE(
            "Purchase_Price", 
            "Salvage_Value", 
            "Useful_Life_Months", 
            1.5
        );
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Life and Time Horizons | Life = 5 (Years), Range = Jan:Dec | This is a catastrophic error. The `Life` parameter must match the granularity of your `XrangeList`. If your range is `Jan:Dec` (12 items), but you pass `Life = 5` (meaning 5 years), Essbase thinks the asset dies in 5 *months*. It will depreciate the entire truck between January and May. If your range is monthly, your Life must be multiplied by 12 (e.g., `60`) |
| Expecting Book Value | `"Remaining_Value" = @DECLINE(...)` | This function strictly returns the Expense (the delta). It does NOT return the remaining Net Book Value (NBV). If you need the NBV for the Balance Sheet, you must calculate it separately by subtracting the accumulated `@DECLINE` expenses from the `Cost` |
| Over-depreciating past Salvage | Using `@COMPOUNDGROWTH` to hack it | If you try to calculate declining balance manually using simple compounding functions, you will likely depreciate the asset all the way to `$0`. The power of `@DECLINE` is that it has native collision-detection with the `Salvage` parameter and will stop depreciating automatically |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SLN`](../08_Financial/@SLN.md) | Calculates Straight-Line Depreciation (the exact same expense amount every single period), rather than an accelerated curve |
| [`@SYD`](../08_Financial/@SYD.md) | Calculates Sum-of-the-Years'-Digits Depreciation, which is a different, slightly smoother method of accelerated depreciation |
| `@AMORTIZE` | Calculates the amortization of a loan or intangible asset, spreading the principal and interest over a fixed term |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — DECLINE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/decline.html)
