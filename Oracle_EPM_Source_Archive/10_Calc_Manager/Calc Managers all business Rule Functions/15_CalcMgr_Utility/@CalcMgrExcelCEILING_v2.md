# @CalcMgrExcelCEILING

## Overview

`@CalcMgrExcelCEILING` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `CEILING` function directly inside an Essbase calculation script. 
It forcefully rounds a number **UP** to the nearest multiple of a specified significance. 

### Why Does This Function Exist—

Standard rounding (`@ROUND` or `@TRUNC`) typically rounds to the nearest whole integer or decimal place. However, business logic often dictates rounding to entirely arbitrary multiples based on packaging, logistics, or pricing tiers.
For example, if you calculate that you need `4.2` gallons of paint, standard rounding gives you `4`. But paint is only sold in 5-gallon buckets. You must round `4.2` up to the nearest multiple of `5` (which is `5`). If you need `6.1` gallons, you must round up to the nearest multiple of `5` (which is `10`). 
Writing custom mathematical modulus logic in Essbase to handle arbitrary multiple rounding is complex. `@CalcMgrExcelCEILING` offloads this to the Java engine, providing an instant, clean way to enforce batch sizing, packaging constraints, and tier pricing.

### When to Use It

- **Supply Chain / Inventory**: Rounding calculated raw material requirements UP to the nearest minimum order quantity (MOQ) or pallet size.
- **HR / Capacity Planning**: Rounding required labor hours UP to the nearest whole shift (e.g., multiples of 8 hours).
- **Pricing Models**: Rounding a dynamically calculated retail price UP to the nearest `$0.99` or `$5.00` interval.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelCEILING(number, significance)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The raw numeric value you want to round up. |
| `significance` | Numeric | ✅ Yes | The multiple to which you want to round (e.g., `5`, `12`, `0.99`). Must have the same mathematical sign as the `number` (both positive, or both negative). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the rounded-up value.
- If the `number` is already an exact multiple of the `significance`, no rounding occurs, and the original number is returned.

---

## How It Works (Behind the Scenes)

1. **Sign Check**: The Java engine checks if both `number` and `significance` have the same sign (positive/positive or negative/negative). If they have opposite signs, the function fails and returns `#MISSING`.
2. **Modulus Evaluation**: It divides the `number` by the `significance`. If there is a remainder, it pushes the `number` up to the next highest integer multiple of the `significance` boundary.
3. **Return**: It passes the finalized, rounded-up value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rounding up to Pallet Sizes (Integers)

```essbase
/* We need 23 units. A pallet holds 12. We must round up to the nearest 12. Returns 24. */
"Units_To_Order" = @CalcMgrExcelCEILING(23, 12);
```

### Variant 2: Tiered Pricing (Decimals)

```essbase
/* The cost-plus price is $14.22. We want all prices to end in a multiple of $0.50. Returns 14.50 */
"Retail_Price" = @CalcMgrExcelCEILING(14.22, 0.50);
```

---

## Practical Examples

### Example 1: Minimum Order Quantities (MOQ) in Procurement

**Scenario**: A manufacturing model calculates exactly how many raw components are needed for production based on the Bill of Materials. However, the supplier only sells the component in boxes of `50`. If the factory needs `101` components, they must order `150` (3 boxes). You need to round the exact requirement up to the nearest multiple of `50`.

```essbase
FIX("FY25", "Working", @LEVEL0("Raw_Materials"))
    
    /* Calculate the exact mathematical requirement */
    "Exact_Units_Required" = "Production_Volume" * "BOM_Multiplier";
    
    /* Ensure the MOQ attribute is populated (e.g., 50) */
    IF("MOQ_Size" > 0 AND "Exact_Units_Required" > 0)
        
        /* Force the order quantity UP to the nearest multiple of the MOQ */
        "Final_Order_Quantity" = @CalcMgrExcelCEILING("Exact_Units_Required", "MOQ_Size");
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Headcount Capacity Planning (FTEs)

**Scenario**: A call center model predicts how many hours of labor are required to handle forecasted call volumes. The model states that `135` hours of labor are needed next week. Agents are hired in standard `40`-hour increments (1 FTE). You cannot hire a fraction of a person. You must round the required hours UP to the nearest multiple of `40` to ensure enough staff is hired.

```essbase
FIX("FY25", "Working", @LEVEL0("Call_Center"))
    
    IF("Required_Labor_Hours" > 0)
        
        /* Round the hours up to the nearest 40 */
        "Funded_Hours" = @CalcMgrExcelCEILING("Required_Labor_Hours", 40);
        
        /* Calculate whole FTEs */
        "Funded_FTEs" = "Funded_Hours" / 40;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Sign Mismatches | `@CalcMgrExcelCEILING(10.5, -2)` | Excel math dictates that the number and the significance must have the same sign. If you pass a positive number and a negative significance, the function will fail. If your data contains mixed signs, use `@ABS` to unify them before passing them into this function |
| Confusing Ceiling with Rounding | Using Ceiling to round to 2 decimals | `CEILING(14.01, 0.10)` rounds to `14.10`. It does NOT round to the nearest value; it *always* forces the value UP. If you just want standard mathematical rounding to 2 decimal places, use `@ROUND("Value", 2)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelFLOOR`](./@CalcMgrExcelFLOOR.md) | The direct opposite (forcefully rounds a number **DOWN** to the nearest multiple of significance) |
| [`@CalcMgrExcelMROUND`](./@CalcMgrExcelMROUND.md) | Rounds a number to a specific multiple based on standard rounding rules (rounding up OR down depending on which boundary is closer) |
| [`@ROUND`](../06_Mathematical/@ROUND.md) | Native Essbase function for standard decimal place rounding |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelceiling.html)
