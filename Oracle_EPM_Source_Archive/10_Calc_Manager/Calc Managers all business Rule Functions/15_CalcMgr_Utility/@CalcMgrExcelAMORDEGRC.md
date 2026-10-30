# @CalcMgrExcelAMORDEGRC

## Overview

`@CalcMgrExcelAMORDEGRC` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `AMORDEGRC` function directly inside an Essbase calculation script. 
It calculates the depreciation (or amortization) for an asset for a specific accounting period using a **French Accounting System depreciation convention**. Specifically, it applies a declining balance (degressive) method, where a depreciation coefficient is applied based on the useful life of the asset.

### Why Does This Function Exist?

French tax and accounting laws mandate highly specific rules for accelerated depreciation. The depreciation rate is multiplied by a legal "coefficient" (e.g., 1.25, 1.75, or 2.25) depending on whether the asset's lifespan is 3-4 years, 5-6 years, or >6 years. 
Recreating this highly localized, tiered coefficient logic manually using `IF` statements in Essbase is incredibly tedious and prone to fractional calculation errors. 
When migrating a global Capex model from Excel to EPM Cloud, if the French subsidiary used `=AMORDEGRC()` in their local spreadsheets, trying to reverse-engineer it is a nightmare. `@CalcMgrExcelAMORDEGRC` utilizes the underlying Java math engine to execute the exact same algorithmic logic as Excel, guaranteeing that the calculated depreciation perfectly matches the legacy spreadsheet and complies with French accounting rules.

### When to Use It

- In global Capex models where French subsidiaries require localized depreciation schedules for their assets.
- When calculating accelerated (degressive) depreciation for specific tax reporting books that mirror the French system.
- Whenever you need to migrate an Excel spreadsheet containing the `AMORDEGRC` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelAMORDEGRC(cost, datePurchased, firstPeriod, salvage, period, rate, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cost` | Numeric | ✅ Yes | The initial cost or value of the asset. |
| `datePurchased`| Integer | ✅ Yes | The date the asset was purchased (`YYYYMMDD`). |
| `firstPeriod` | Integer | ✅ Yes | The date of the end of the very first accounting period (`YYYYMMDD`). |
| `salvage` | Numeric | ✅ Yes | The salvage (residual) value of the asset at the end of its life. |
| `period` | Numeric | ✅ Yes | The specific period number you are trying to calculate depreciation for (e.g., `0`, `1`, `2`). |
| `rate` | Numeric | ✅ Yes | The standard rate of depreciation (e.g., `0.15` for 15%). The function will apply the legal coefficient to this automatically. |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the exact depreciation amount for the requested `period`.
- The returned value is highly precise. You typically want to wrap it in `@ROUND(..., 2)` to format it cleanly for currency reporting.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `cost` > 0, `salvage` >= 0, and the `period` is a valid positive integer.
2. **Coefficient Lookup**: The engine looks at the implied life of the asset (based on `1 / rate`). 
   - If life is 3 to 4 years, it multiplies the rate by `1.5` (Note: older French laws used 1.5, newer ones use 1.25. The Java library typically aligns with Excel's hardcoded logic).
   - If life is 5 to 6 years, it multiplies by `2.0`.
   - If life is > 6 years, it multiplies by `2.5`.
3. **Proration**: For period `0` (the year of purchase), it calculates the exact number of days between `datePurchased` and `firstPeriod` to prorate the first year's depreciation.
4. **Declining Balance Math**: It applies the modified rate against the remaining Net Book Value (Cost - Accumulated Depreciation).
5. **Return**: Passes the resulting depreciation value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Year 1 Depreciation

```essbase
/* 
   Cost: 2400
   Purchased: Aug 19, 2024
   First Period End: Dec 31, 2024
   Salvage: 300
   Period: 1 (The first full year after the purchase year)
   Rate: 15% (0.15)
   Basis: 1 (Actual/Actual)
*/
"Depreciation_Expense" = @CalcMgrExcelAMORDEGRC(2400, 20240819, 20241231, 300, 1, 0.15, 1);
```

---

## Practical Examples

### Example 1: Dynamic Capex Model for a French Entity

**Scenario**: You have a global Capex cube. Your US entities use straight-line depreciation, but your French entities must use `AMORDEGRC`. The script must dynamically loop through the assets, determine the current period number relative to the purchase date, and calculate the expense.

```essbase
FIX("FY25", "Working", "Entity_France", @LEVEL0("Asset"))
    
    /* Ensure the asset exists and hasn't been fully depreciated */
    IF("Asset_Cost" > 0 AND "Purchase_Date" != #MISSING)
        
        /* In this simplified example, we assume Period_Counter is calculated 
           elsewhere (e.g., Year of Purchase = 0, Year 2 = 1, etc.) */
           
        "Depreciation_Expense" = @ROUND(
            @CalcMgrExcelAMORDEGRC(
                "Asset_Cost", 
                "Purchase_Date", 
                "First_Period_End_Date", 
                "Salvage_Value", 
                "Period_Counter", 
                "Depreciation_Rate", 
                1  /* Basis: Actual/Actual */
            )
        , 2); /* Round to 2 decimal places for reporting */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrExcelAMORDEGRC(Cost, vJavaDate...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Wrong Period Indexing | Passing `1` for the year of purchase | Under this convention, the period of purchase is technically Period `0`. Period `1` represents the first *full* year following the purchase. Ensure your period counters start at 0 |
| Whole Number Rates | Passing `15` instead of `0.15` | The `rate` parameter expects a decimal. If the depreciation rate is 15%, you must pass `0.15`. Passing `15` will calculate 1500% depreciation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelAMORLINC`](./@CalcMgrExcelAMORLINC.md) | The sibling function that calculates depreciation for the French accounting system using the **straight-line** (linear) method rather than declining balance |
| [`@CalcMgrExcelSLN`](./@CalcMgrExcelSLN.md) | Calculates standard Straight-Line depreciation for US/Global models |
| [`@CalcMgrExcelSYD`](./@CalcMgrExcelSYD.md) | Calculates Sum-of-Years' Digits accelerated depreciation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelamordegrc.html)
