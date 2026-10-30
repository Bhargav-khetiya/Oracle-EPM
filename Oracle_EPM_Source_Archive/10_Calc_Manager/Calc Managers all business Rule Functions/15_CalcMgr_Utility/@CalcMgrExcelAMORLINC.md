# @CalcMgrExcelAMORLINC

## Overview

`@CalcMgrExcelAMORLINC` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `AMORLINC` function directly inside an Essbase calculation script. 
It calculates the depreciation (or amortization) for an asset for a specific accounting period using a **French Accounting System depreciation convention**. Unlike `AMORDEGRC` (which uses a declining balance), `AMORLINC` calculates depreciation using a strict **linear (straight-line)** method.

### Why Does This Function Exist?

While Essbase has native Straight-Line logic (and developers often just write `"Cost" / "Life"`), the French linear depreciation rules require highly specific, to-the-day proration for the first accounting period (Period 0). 
If an asset is purchased in August, the depreciation for that first year must be prorated exactly based on the days remaining until the end of the first period, adhering to specific European day-count bases (like Actual/Actual or European 30/360). 
When migrating a global Capex model from Excel to EPM Cloud, if the French subsidiary used `=AMORLINC()` in their local spreadsheets, trying to recreate the day-count proration manually using `IF` statements is tedious. `@CalcMgrExcelAMORLINC` utilizes the underlying Java math engine to execute the exact same algorithmic logic as Excel, guaranteeing that the calculated depreciation perfectly matches the legacy spreadsheet and complies with localized accounting rules.

### When to Use It

- In global Capex models where French subsidiaries require localized linear depreciation schedules for their assets.
- When calculating prorated straight-line depreciation for specific tax reporting books that mirror the French linear system.
- Whenever you need to migrate an Excel spreadsheet containing the `AMORLINC` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelAMORLINC(cost, datePurchased, firstPeriod, salvage, period, rate, basis)
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
| `period` | Numeric | ✅ Yes | The specific period number you are trying to calculate depreciation for (e.g., `0` for year of purchase, `1`, `2`). |
| `rate` | Numeric | ✅ Yes | The standard rate of depreciation (e.g., `0.15` for 15%). |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the exact linear depreciation amount for the requested `period`.
- The returned value is highly precise. You typically want to wrap it in `@ROUND(..., 2)` to format it cleanly for currency reporting.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `cost` > 0, `salvage` >= 0, and the `period` is a valid positive integer.
2. **Proration (Period 0)**: If `period` is `0`, it calculates the exact number of days between `datePurchased` and `firstPeriod` using the selected `basis`. It applies the `rate` against the `cost`, and then multiplies by the prorated fraction of the year.
3. **Linear Math (Subsequent Periods)**: For full periods, it simply calculates standard straight line (typically `Cost * Rate`). 
4. **End of Life**: It automatically stops depreciating when the accumulated depreciation causes the asset's net book value to hit the `salvage` threshold.
5. **Return**: Passes the resulting depreciation value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Year 0 (Prorated) Depreciation

```essbase
/* 
   Cost: 2400
   Purchased: Aug 19, 2024
   First Period End: Dec 31, 2024
   Salvage: 300
   Period: 0 (The prorated year of purchase)
   Rate: 15% (0.15)
   Basis: 1 (Actual/Actual)
*/
"Depreciation_Expense" = @CalcMgrExcelAMORLINC(2400, 20240819, 20241231, 300, 0, 0.15, 1);
```

---

## Practical Examples

### Example 1: Dynamic Capex Model for a French Entity

**Scenario**: You have a global Capex cube. Your French entities use `AMORLINC` to strictly enforce the day-count proration mandated by their localized accounting system. The script loops through the assets, determines the current period number relative to the purchase date, and calculates the expense.

```essbase
FIX("FY25", "Working", "Entity_France", @LEVEL0("Asset"))
    
    /* Ensure the asset exists and has a purchase date */
    IF("Asset_Cost" > 0 AND "Purchase_Date" != #MISSING)
        
        /* In this simplified example, we assume Period_Counter is calculated 
           elsewhere (e.g., Year of Purchase = 0, Year 2 = 1, etc.) */
           
        "Depreciation_Expense" = @ROUND(
            @CalcMgrExcelAMORLINC(
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
| Passing Java Dates | `@CalcMgrExcelAMORLINC(Cost, vJavaDate...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Wrong Period Indexing | Passing `1` for the year of purchase | Under this convention, the period of purchase is technically Period `0`. Period `1` represents the first *full* year following the purchase. If you pass `1` during the year of purchase, you will massively overstate your depreciation |
| Whole Number Rates | Passing `15` instead of `0.15` | The `rate` parameter expects a decimal. If the depreciation rate is 15%, you must pass `0.15`. Passing `15` will calculate 1500% depreciation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelAMORDEGRC`](./@CalcMgrExcelAMORDEGRC.md) | The sibling function that calculates depreciation for the French accounting system using the **declining balance** (degressive) method rather than linear |
| [`@CalcMgrExcelSLN`](./@CalcMgrExcelSLN.md) | Calculates standard Straight-Line depreciation for standard US/Global models that do not require French day-count proration |
| [`@CalcMgrExcelSYD`](./@CalcMgrExcelSYD.md) | Calculates Sum-of-Years' Digits accelerated depreciation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelamorlinc.html)
