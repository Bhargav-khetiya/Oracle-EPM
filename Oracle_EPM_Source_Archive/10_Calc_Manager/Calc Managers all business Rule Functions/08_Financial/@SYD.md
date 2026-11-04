# @SYD

## Overview

`@SYD` is a **financial depreciation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that calculates the **Sum-of-the-Years' Digits** depreciation for an asset for a specific period. This is an **accelerated depreciation method**, meaning more expense is recognized in the early years of the asset's life and less in the later years.

### Why Does This Function Exist—

While straight-line depreciation (@SLN) spreads cost evenly, some assets (like computers or vehicles) lose most of their value or utility rapidly in the first few years.
- **Tax Planning**: Accelerated depreciation often provides near-term tax benefits by increasing deductible expenses early in an asset's life.
- **Matching Principle**: If an asset is highly productive early on and requires more maintenance later, SYD matches the higher expense with the higher early productivity.

### When to Use It

- In Capital Expense (CapEx) planning models for specific asset classes that require accelerated depreciation (e.g., technology, vehicles).
- For tax provision forecasting where tax authorities allow SYD depreciation.
- When accounting policies dictate accelerated expense recognition.

---

## Category

**Financial / Depreciation**

---

## Syntax

```essbase
@SYD(cost, salvage, life, period)
```

### Formal Syntax

```
@SYD(costValue, salvageValue, lifePeriods, currentPeriodNum)
```

Where:
- `costValue` — The initial purchase price or capitalized cost.
- `salvageValue` — The estimated residual value.
- `lifePeriods` — The total number of periods of useful life.
- `currentPeriodNum` — The specific period you are calculating depreciation for (e.g., period 1, period 2).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cost` | Numeric | ✅ Yes | The initial cost of the asset. |
| `salvage` | Numeric | ✅ Yes | The expected salvage value at the end of the asset's life. |
| `life` | Numeric | ✅ Yes | The total useful life of the asset. Must be in the same frequency as the periods being calculated (e.g., months or years). |
| `period` | Numeric | ✅ Yes | The current period number for which you want to calculate the expense (from `1` up to `life`). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the depreciation expense for that specific period. 
*(Note: Because it's accelerated, the value returned will be highest when `period = 1` and lowest when `period = life`).*

---

## How It Works (Behind the Scenes)

1. **Mathematical Formula**: 
   The "Sum of Years' Digits" is calculated as: `(Life * (Life + 1)) / 2`.
   The depreciation for a specific period is: 
   `Expense = (Cost - Salvage) * (Remaining Life / Sum of Digits)`
2. **Example**: A 5-year asset. Sum of digits = 5+4+3+2+1 = 15.
   - Year 1 expense = (Cost - Salvage) * (5/15)
   - Year 2 expense = (Cost - Salvage) * (4/15)
   - Year 5 expense = (Cost - Salvage) * (1/15)
3. **Stateless Calculation**: Like `@SLN`, `@SYD` does not track state. You must explicitly pass it the current period number (e.g., Month 14 of 60).

---

## Syntax Variants & Scenarios

### Variant 1: Basic Annual Depreciation (Year 1)

```essbase
/* 5-year asset, 100k cost, 10k salvage, calculating Year 1 */
"Depr_Yr1" = @SYD(100000, 10000, 5, 1); 
/* Returns 30,000 */
```

### Variant 2: Basic Annual Depreciation (Year 2)

```essbase
"Depr_Yr2" = @SYD(100000, 10000, 5, 2); 
/* Returns 24,000 */
```

### Variant 3: Using Dynamic Variables

```essbase
"Depreciation_Expense" = @SYD("Asset_Cost", "Salvage_Value", "Useful_Life", "Asset_Age_Periods");
```

---

## Practical Examples

### Example 1: Accelerated CapEx Depreciation

**Scenario**: Calculate monthly SYD depreciation for a fleet of vehicles. The "Asset_Age" metric tracks how many months old the asset is.

```essbase
FIX("FY25":"FY29", "Working", "Vehicle_Fleet")
    VAR vCost = "Asset_Cost" -> "BegBalance";
    VAR vLifeMonths = "Useful_Life_Years" -> "BegBalance" * 12;
    VAR vCurrentAge = "Asset_Age_Months"; /* E.g., 1, 2, 3... */
    
    /* Only apply depreciation if the asset is active and within its life */
    IF(vCurrentAge > 0 AND vCurrentAge <= vLifeMonths)
        "Depreciation_Expense" = @SYD(vCost, 0, vLifeMonths, vCurrentAge);
        
        "Accumulated_Depr" = "Accumulated_Depr" -> @PRIOR(@CURRMBR("Period")) 
                           + "Depreciation_Expense";
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing the period parameter | `@SYD` requires 4 parameters; `@SLN` only requires 3 | Ensure you provide the current period number as the 4th parameter |
| Period > Life | If you pass a period number greater than the life, the formula will generate negative or nonsensical depreciation | Wrap the calculation in an `IF` statement: `IF(Period <= Life)` |
| Mismatched periodicity | Providing life in years (5) but period in months (14) | Both must match. E.g., Life = 60 months, Period = 14 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SLN`](./@SLN.md) | Straight-Line Depreciation (even distribution) |
| [`@DECLINE`](./@DECLINE.md) | Declining balance depreciation (another accelerated method) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @SYD](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/syd.html)
