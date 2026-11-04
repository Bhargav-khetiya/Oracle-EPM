# @SLN

## Overview

`@SLN` is a **financial depreciation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that calculates the **Straight-Line Depreciation** of an asset for a single period. Straight-line depreciation distributes the cost of an asset evenly across its useful life.

### Why Does This Function Exist—

Depreciation is a core requirement of financial accounting and capital planning:
- **Expense Planning**: Translating large capital expenditures (CapEx) into monthly/annual depreciation expenses on the P&L.
- **Asset Valuation**: Reducing the book value of an asset on the balance sheet over time.
- **Simplicity**: Straight-line is the most common and simple method of depreciation used globally for book purposes.

Instead of manually writing `(Cost - Salvage) / Life`, `@SLN` provides a clean, standardized function.

### When to Use It

- In Capital Expense (CapEx) planning models to calculate depreciation for new asset purchases.
- When modeling fixed assets on the balance sheet.
- When accounting policies dictate an even spread of asset cost over time.

---

## Category

**Financial / Depreciation**

---

## Syntax

```essbase
@SLN(cost, salvage, life)
```

### Formal Syntax

```
@SLN(costValue, salvageValue, lifePeriods)
```

Where:
- `costValue` — The initial purchase price or capitalized cost of the asset.
- `salvageValue` — The estimated residual value of the asset at the end of its useful life.
- `lifePeriods` — The number of periods over which the asset will be depreciated.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cost` | Numeric | ✅ Yes | The initial cost of the asset. Can be a member reference (e.g., `"Asset_Cost"`), a variable, or a hardcoded number. |
| `salvage` | Numeric | ✅ Yes | The expected salvage value at the end of the asset's life. Often zero in planning models, but required by the syntax. |
| `life` | Numeric | ✅ Yes | The useful life of the asset, expressed in the same periods as the calculation (e.g., if calculating monthly depreciation, life must be in months). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the depreciation expense for a single period. 
*(Note: Because it's straight-line, the value returned is identical for every period of the asset's life).*

---

## How It Works (Behind the Scenes)

1. **Mathematical Formula**: 
   `SLN = (Cost - Salvage) / Life`
2. **Stateless Calculation**: `@SLN` does not track how many periods have elapsed. It simply performs the math. It is up to the developer to apply this calculation only during the active life of the asset (e.g., using `IF` statements or date logic).
3. **Period Matching**: If you are forecasting on a monthly basis, the `life` parameter must be in months (e.g., a 5-year asset = 60 months).

---

## Syntax Variants & Scenarios

### Variant 1: Basic Annual Depreciation

```essbase
/* 5-year asset, 100k cost, 10k salvage */
"Depreciation_Expense" = @SLN(100000, 10000, 5); 
/* Returns 18,000 per year */
```

### Variant 2: Using Account Members

```essbase
"Depreciation_Expense" = @SLN("Asset_Cost", "Salvage_Value", "Useful_Life");
```

### Variant 3: Monthly Calculation (Converting Life)

```essbase
/* If Useful_Life is stored in years, multiply by 12 for monthly calculation */
"Monthly_Depr" = @SLN("Asset_Cost", 0, "Useful_Life_Years" * 12);
```

---

## Practical Examples

### Example 1: Basic CapEx Depreciation

**Scenario**: Calculate monthly straight-line depreciation for a newly purchased server, ensuring it stops depreciating after its useful life.

```essbase
FIX("FY25":"FY29", "Working", "Server_Asset")
    /* Assuming Cost is recognized in Period 1, Life is 36 months, Salvage is 0 */
    VAR vCost = "Asset_Cost" -> "BegBalance";
    VAR vLifeMonths = "Useful_Life_Years" -> "BegBalance" * 12;
    VAR vPeriodsElapsed = "Periods_Since_Purchase"; /* Calculated via date math */
    
    /* Only apply depreciation if the asset is still active */
    IF(vPeriodsElapsed > 0 AND vPeriodsElapsed <= vLifeMonths)
        "Depreciation_Expense" = @SLN(vCost, 0, vLifeMonths);
        
        /* Update Accumulated Depreciation */
        "Accumulated_Depr" = "Accumulated_Depr" -> @PRIOR(@CURRMBR("Period")) 
                           + "Depreciation_Expense";
    ENDIF
ENDFIX
```

---

### Example 2: Dynamic Asset Classes

**Scenario**: Different asset classes have different default useful lives.

```essbase
FIX("FY25", "Working", @DESCENDANTS("New_Purchases"))
    VAR vLife = 0;
    
    IF(@ISMBR("IT_Equipment"))
        vLife = 36; /* 3 years */
    ELSEIF(@ISMBR("Furniture"))
        vLife = 84; /* 7 years */
    ELSE
        vLife = 60; /* 5 years default */
    ENDIF
    
    "Depreciation_Expense" = @SLN("Purchase_Amount", 0, vLife);
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched periodicity | Providing life in years (5) while calculating at the month level | Multiply life by 12 if calculating monthly |
| Depreciating past useful life | `@SLN` just does the math; it will happily return an expense in period 100 of a 60-period asset | Use `IF` logic to check if `Elapsed_Periods <= Useful_Life` |
| Negative useful life or zero | Dividing by zero or negative life causes an error or #MISSING | Ensure `life > 0` before calling `@SLN` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SYD`](./@SYD.md) | Sum-of-the-Years' Digits (Accelerated depreciation) |
| [`@DECLINE`](./@DECLINE.md) | Declining balance depreciation |
| [`@PRIOR`](./@PRIOR.md) | Used to track accumulated depreciation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @SLN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/sln.html)
