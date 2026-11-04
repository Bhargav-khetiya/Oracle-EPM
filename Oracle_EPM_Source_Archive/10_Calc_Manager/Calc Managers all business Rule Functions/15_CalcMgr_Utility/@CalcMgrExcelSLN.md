# @CalcMgrExcelSLN

## Overview

`@CalcMgrExcelSLN` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `SLN` function directly inside an Essbase calculation script. 
It calculates the **Straight-Line Depreciation** of an asset for one single period. 

### Why Does This Function Exist—

Depreciation is the accounting process of allocating the cost of a tangible asset over its useful life. The simplest and most widely used method globally is Straight-Line Depreciation. In this method, the asset loses the exact same amount of value every single year until it reaches its final salvage value. 
The algebraic formula is `(Cost - Salvage) / Life`. While this is an incredibly simple mathematical equation that can easily be written natively in Essbase, using `@CalcMgrExcelSLN` provides two distinct advantages: 
1. It guarantees perfect parity with legacy Excel fixed-asset schedules that utilize the `SLN` formula.
2. It standardizes the code syntax across all depreciation models, making it easier for FP&A administrators to switch between `SLN` (Straight-Line), `SYD` (Sum-of-Years' Digits), and `DDB` (Double-Declining Balance) functions seamlessly without having to rewrite custom algebraic blocks.

### When to Use It

- **CapEx Planning**: Calculating the fixed monthly or annual depreciation expense for standard corporate assets (like laptops, office furniture, or standard machinery) that degrade linearly.
- **Fixed Asset Roll-Forwards**: Automatically populating the Accumulated Depreciation balance sheet accounts.
- Whenever you need to migrate an Excel spreadsheet containing the `SLN` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelSLN(cost, salvage, life)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cost` | Numeric | ✅ Yes | The initial cost of the asset (e.g., `100000`). |
| `salvage` | Numeric | ✅ Yes | The value of the asset at the end of the depreciation (e.g., `10000`). Sometimes called scrap value. |
| `life` | Numeric | ✅ Yes | The number of periods over which the asset is depreciated (e.g., `5` years). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the depreciation expense for one single period.
- Because Straight-Line depreciation is constant, this number represents the expense for *every* period in the asset's life.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures `life` is > 0. If `life` is 0, it results in a division by zero error, and the function returns `#MISSING`.
2. **Formula Execution**: It executes the standard algebraic formula: `(cost - salvage) / life`.
3. **Return**: Passes the resulting fixed expense back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Annual Depreciation

```essbase
/* 
   Cost: $100,000
   Salvage: $10,000
   Life: 5 Years
   Result: Calculates annual expense. Returns $18,000.
*/
"Annual_Depreciation_Expense" = @CalcMgrExcelSLN(100000, 10000, 5);
```

---

## Practical Examples

### Example 1: Dynamic Monthly CapEx Depreciation

**Scenario**: A corporate capital planning model handles the purchase of new vehicles. The vehicles cost `$50,000`, have a salvage value of `$5,000`, and a useful life of `60` months. The FP&A team needs to automatically push the monthly depreciation expense to the P&L for every month the asset is active.

```essbase
FIX("FY25", "Working", @LEVEL0("Fleet_Vehicles"))
    
    /* Iterate through the forecast months */
    FIX(@IDESCENDANTS("YearTotal"))
        
        /* Ensure the asset is actually active in this period */
        IF("Asset_Status_Flag" == 1)
            
            /* 
               Calculate the straight-line depreciation for a single month.
               Note: Because the life parameter is in Months (60), the function
               automatically returns a Monthly expense.
               Returns: $750 per month.
            */
            "Monthly_Depreciation_Expense" = @ROUND(
                @CalcMgrExcelSLN(
                    "Asset_Cost", 
                    "Salvage_Value", 
                    "Useful_Life_Months"
                )
            , 2);
            
            /* Roll forward the Balance Sheet Accumulated Depreciation */
            "Accumulated_Depreciation" = "Prior_Month_Accum_Depr" + "Monthly_Depreciation_Expense";
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Time Units | Passing a 5-Year Life to calculate Monthly Expense | The time unit of the `life` parameter dictates the time unit of the output. If you pass `5` (years), the function returns the *Annual* depreciation expense. If you are calculating a monthly P&L, you must either divide the result by 12, or pass `60` (months) as the `life` parameter |
| Negative Cost | Passing `-100000` | Unlike loan functions (like `PMT` or `FV`) that rely on strict cash flow sign conventions (outflows are negative), depreciation functions generally expect the `cost` and `salvage` to be positive numbers representing absolute asset value. If you pass negative numbers, the resulting depreciation expense will be mathematically inverted |
| Over-Depreciating | Continuing past the useful life | Because `SLN` returns a flat number regardless of the period, if you accidentally run the calculation for 7 years on a 5-year asset, the function will happily return the $18,000 expense for Years 6 and 7, causing your asset's book value to drop below the salvage value. You must write an `IF` statement to ensure the calculation stops when the asset retires |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelSYD`](./@CalcMgrExcelSYD.md) | Calculates Sum-of-Years' Digits depreciation (an accelerated method where the expense is higher in early years) |
| [`@CalcMgrExcelDDB`](./@CalcMgrExcelDDB.md) | Calculates Double-Declining Balance depreciation (an aggressively accelerated method) |
| [`@CalcMgrExcelDB`](./@CalcMgrExcelDB.md) | Calculates standard Declining Balance depreciation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelsln.html)
