# @CalcMgrExcelFLOOR

## Overview

`@CalcMgrExcelFLOOR` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `FLOOR` function directly inside an Essbase calculation script. 
It forcefully rounds a number **DOWN** toward zero, to the nearest multiple of a specified significance. 

### Why Does This Function Exist?

Standard rounding (`@ROUND` or `@TRUNC`) typically rounds to the nearest whole integer or strips away decimals completely. However, operational models often require rounding down to highly specific, arbitrary multiples based on packaging, labor shifts, or pricing floors.
For example, if you mathematically determine that you can afford to buy `4.8` pallets of material, but you are only allowed to buy full pallets, standard rounding might push you to `5` (putting you over budget). You must forcefully round `4.8` DOWN to the nearest multiple of `1` (which is `4`). If you have a budget of $124.99 and you can only buy items in $10 increments, you must round down to the nearest multiple of `10` (which is `120`).
`@CalcMgrExcelFLOOR` offloads this complex modulus math to the Java engine, providing an instant, reliable way to enforce maximum thresholds and budget constraints.

### When to Use It

- **Procurement Planning**: Forcing calculated purchase volumes DOWN to the nearest whole pallet or box size to ensure budgets are not exceeded.
- **Labor Planning**: Forcing forecasted hours DOWN to the nearest whole 8-hour shift to prevent fractional overtime.
- **Pricing Models**: Establishing price floors (e.g., aggressively dropping a calculated discount price down to the nearest $0.50 increment).

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelFLOOR(number, significance)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The raw numeric value you want to round down. |
| `significance` | Numeric | ✅ Yes | The multiple to which you want to round (e.g., `5`, `12`, `0.50`). Must have the same mathematical sign as the `number` (both positive, or both negative). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the rounded-down value.
- If the `number` is already an exact multiple of the `significance`, no rounding occurs, and the original number is returned.

---

## How It Works (Behind the Scenes)

1. **Sign Check**: The Java engine checks if both `number` and `significance` have the same sign (positive/positive or negative/negative). If they have opposite signs, the function fails and returns `#MISSING`.
2. **Modulus Evaluation**: It divides the `number` by the `significance`. If there is a remainder, it forcefully strips the remainder and pushes the `number` DOWN (toward zero) to the nearest integer multiple of the `significance` boundary.
3. **Return**: It passes the finalized, rounded-down value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rounding down to Pallet Sizes (Integers)

```essbase
/* Budget allows for 28 units. A pallet holds 12. 
   We must round down to the nearest 12 to stay under budget. Returns 24. */
"Units_To_Order" = @CalcMgrExcelFLOOR(28, 12);
```

### Variant 2: Tiered Pricing (Decimals)

```essbase
/* Calculated discount price is $14.88. We want all sale prices to end in a multiple of $0.50. 
   Returns 14.50 */
"Sale_Price" = @CalcMgrExcelFLOOR(14.88, 0.50);
```

---

## Practical Examples

### Example 1: Enforcing Budget Constraints in Procurement

**Scenario**: A regional manager submits a Capex request for laptops. They have a budget of `$15,300`. A laptop costs `$1,200` (which implies `12.75` laptops). Standard rounding (`13`) would exceed the budget. You must round the mathematically affordable units DOWN to the nearest multiple of `1` to find exactly how many full laptops they can buy.

```essbase
FIX("FY25", "Working", @LEVEL0("CostCenter"))
    
    /* Calculate the raw, fractional number of laptops they can afford */
    "Affordable_Laptops_Raw" = "Laptop_Budget" / "Cost_Per_Laptop";
    
    IF("Affordable_Laptops_Raw" > 0)
        
        /* Force the quantity DOWN to the nearest whole number (multiple of 1) */
        "Approved_Laptop_Qty" = @CalcMgrExcelFLOOR("Affordable_Laptops_Raw", 1);
        
        /* Recalculate the true spend */
        "Final_Capex_Spend" = "Approved_Laptop_Qty" * "Cost_Per_Laptop";
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Labor Shift Optimization

**Scenario**: A factory model predicts that a specific product run will require `115` hours of labor. The factory operates strictly in `8`-hour shifts. The manager wants to know how many *full* shifts are guaranteed to be worked. Any leftover fractional hours will be handled by temporary workers. You use `FLOOR` with a significance of `8`.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    IF("Required_Labor_Hours" > 0)
        
        /* Round the hours DOWN to the nearest multiple of 8 */
        /* E.g., 115 rounded down to nearest 8 is 112 */
        "Guaranteed_Shift_Hours" = @CalcMgrExcelFLOOR("Required_Labor_Hours", 8);
        
        /* Calculate how many full shifts that equates to (112 / 8 = 14 shifts) */
        "Full_Shifts" = "Guaranteed_Shift_Hours" / 8;
        
        /* Isolate the leftover hours for temp workers (115 - 112 = 3 hours) */
        "Temp_Labor_Hours" = "Required_Labor_Hours" - "Guaranteed_Shift_Hours";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Sign Mismatches | `@CalcMgrExcelFLOOR(10.5, -2)` | Excel math dictates that the number and the significance must have the exact same sign. If you pass a positive number and a negative significance, the function will fail. Use `@ABS` to unify signs if your data is messy |
| Confusing Floor with Rounding | Using Floor to round to 2 decimals | `FLOOR(14.99, 0.10)` rounds to `14.90`. It does NOT round to the nearest value; it *always* forces the value DOWN. If you just want standard mathematical rounding to 2 decimal places, use `@ROUND("Value", 2)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelCEILING`](./@CalcMgrExcelCEILING.md) | The direct opposite (forcefully rounds a number **UP** to the nearest multiple of significance) |
| [`@CalcMgrExcelMROUND`](./@CalcMgrExcelMROUND.md) | Rounds a number to a specific multiple based on standard rounding rules (rounding up OR down depending on which boundary is closer, rather than forcefully flooring it) |
| [`@TRUNC`](./@TRUNC.md) | Native Essbase function that simply chops off all decimals, acting similarly to `FLOOR(x, 1)` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelfloor.html)
