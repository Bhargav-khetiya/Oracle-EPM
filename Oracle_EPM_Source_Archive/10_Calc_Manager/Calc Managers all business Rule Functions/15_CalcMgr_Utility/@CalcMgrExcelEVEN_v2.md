# @CalcMgrExcelEVEN

## Overview

`@CalcMgrExcelEVEN` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `EVEN` function directly inside an Essbase calculation script. 
It analyzes a number, and if that number is not an even integer, it forces the number **away from zero** to the nearest even integer.

### Why Does This Function Exist—

Standard rounding (`@ROUND` or `@TRUNC`) typically rounds to the nearest whole integer. However, in physical logistics, packaging, and supply chain manufacturing, items are frequently bundled in pairs or produced in symmetrical batches. 
For example, if you mathematically calculate that you need `4.2` pallets of raw material, standard rounding gives you `4`. The `CEILING` function might give you `5`. But if your trucks can only be loaded with a balanced, even number of pallets (e.g., 2, 4, 6, 8), you must forcefully round `4.2` up to `6`.
Writing custom modulus logic in Essbase to check if a number is even, and if not, add an offset to force it to an even integer, is tedious and error-prone (especially when dealing with negative numbers). `@CalcMgrExcelEVEN` handles this automatically in the Java engine, ensuring your rounding logic perfectly matches the legacy Excel supply chain model.

### When to Use It

- **Supply Chain / Logistics**: Forcing calculated inventory requirements into even lots (e.g., pairs of shoes, symmetrical truck loads).
- **Manufacturing Planning**: Rounding labor shifts or machine cycles to even numbers to align with shift rotations.
- Whenever you need to migrate an Excel spreadsheet containing the `EVEN` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelEVEN(number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The raw numeric value you want to round to an even integer. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the rounded even integer.
- If the `number` is already an exact even integer (e.g., `4`), no rounding occurs, and the original number is returned.
- **Directional Note**: The function always rounds *away* from zero. Positive numbers round UP (e.g., `4.2` becomes `6`). Negative numbers round DOWN (e.g., `-4.2` becomes `-6`).

---

## How It Works (Behind the Scenes)

1. **Integer Check**: The Java engine checks if the number is already an even integer (e.g., `number % 2 == 0`). If it is, it returns it instantly.
2. **Directional Math**: If the number is positive, it uses math similar to `CEILING(number, 2)` to force it up to the next even integer. If it is negative, it forces it down to the next even negative integer.
3. **Return**: It passes the finalized, even value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Positive Number Rounding

```essbase
/* Calculation requires 5.1 units. Must round up to the next even lot. Returns 6. */
"Units_To_Order" = @CalcMgrExcelEVEN(5.1);
```

### Variant 2: Negative Number Rounding

```essbase
/* Forecasting a negative variance of -3.1. Rounds away from zero to -4. */
"Even_Negative_Variance" = @CalcMgrExcelEVEN(-3.1);
```

---

## Practical Examples

### Example 1: Balancing Truckloads in Logistics

**Scenario**: A distribution center ships goods on pallets. To maintain weight distribution inside the trailer, pallets must always be loaded in pairs (side-by-side). If a retail store orders a volume equivalent to `13.5` pallets, you must round that order up to exactly `14` pallets before issuing the warehouse picking ticket.

```essbase
FIX("FY25", "Working", @LEVEL0("Store_Locations"))
    
    /* Calculate raw pallet requirement */
    "Raw_Pallets_Required" = "Order_Volume_Units" / "Units_Per_Pallet";
    
    IF("Raw_Pallets_Required" > 0)
        
        /* Force the requirement to an Even Number for trailer balancing */
        /* E.g., 13.5 becomes 14. 14.1 becomes 16. */
        "Final_Pallets_To_Ship" = @CalcMgrExcelEVEN("Raw_Pallets_Required");
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Ordering Inventory in Pairs

**Scenario**: A retailer sells luxury footwear. The forecasting system calculates demand for left shoes and right shoes based on historical replacement rates, occasionally resulting in odd numbers (e.g., demanding `3` pairs). However, the factory *only* ships master cartons containing 2 pairs (4 shoes). Therefore, order quantities for pairs must always be an even number.

```essbase
FIX("FY25", "Working", @LEVEL0("Footwear_Products"))
    
    "Raw_Demand_Pairs" = "Forecasted_Sales" * "Safety_Stock_Factor";
    
    IF("Raw_Demand_Pairs" > 0)
        
        /* Force the pair demand to an even number to align with master cartons */
        "Procurement_Order_Pairs" = @CalcMgrExcelEVEN("Raw_Demand_Pairs");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with Standard Rounding | Expecting `4.2` to round to `4` | `EVEN` does not care which even number is mathematically *closer*. It always forcefully rounds *away* from zero to the *next* even number. `4.1` becomes `6`, even though `4` is much closer. If you want nearest-neighbor rounding, use `@ROUND("Value", 0)` and deal with odd numbers manually |
| Negative Number Behavior | Expecting `-4.2` to become `-4` | Because the function always rounds *away* from zero, `-4.2` will be forced to `-6`, not `-4`. |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelODD`](./@CalcMgrExcelODD.md) | The direct counterpart: forcefully rounds a number away from zero to the nearest *odd* integer |
| [`@CalcMgrExcelCEILING`](./@CalcMgrExcelCEILING.md) | Rounds a number UP to the nearest multiple of significance (e.g., `CEILING(x, 2)` achieves the exact same thing as `EVEN` for positive numbers, but acts differently on negative numbers) |
| [`@ROUND`](../06_Mathematical/@ROUND.md) | Native Essbase function for standard, nearest-neighbor rounding |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceleven.html)
