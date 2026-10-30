# @CalcMgrExcelMROUND

## Overview

`@CalcMgrExcelMROUND` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `MROUND` function directly inside an Essbase calculation script. 
It rounds a number to the **nearest specified multiple** (e.g., rounding to the nearest 5, nearest 10, or nearest 0.25). 

### Why Does This Function Exist?

Standard rounding (`@ROUND`) in Essbase allows you to round to a specific decimal place (e.g., rounding `10.512` to `10.51`). However, it does not easily allow you to round to a specific *multiple*. 
In retail pricing models, companies often enforce a rule that all prices must end in a multiple of `$0.05` (nickels). In manufacturing, raw materials must be ordered in multiples of `12` (dozens). 
To calculate this manually in Essbase, you would have to write complex modulus math: divide by the multiple, round the result, and multiply it back. `@CalcMgrExcelMROUND` eliminates this entirely, offloading the multiple-rounding algorithm to the Java engine and ensuring perfect parity with legacy Excel models.

### When to Use It

- **Pricing Models**: Rounding a calculated wholesale price to the nearest $0.50 or $0.25 to create a clean customer-facing retail price.
- **Logistics**: Rounding required inventory up or down to the nearest master carton size.
- Whenever you need to migrate an Excel spreadsheet containing the `MROUND` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelMROUND(number, multiple)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The raw numeric value you want to round. |
| `multiple` | Numeric | ✅ Yes | The multiple to which you want to round the number (e.g., `5`, `12`, `0.50`). Must have the same mathematical sign as the `number` (both positive, or both negative). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the rounded value.
- If the `number` is exactly halfway between two multiples, it rounds **away from zero**. (e.g., rounding `12.5` to the nearest multiple of `5` returns `15`, not `10`).

---

## How It Works (Behind the Scenes)

1. **Sign Check**: The Java engine checks if both `number` and `multiple` have the same sign (positive/positive or negative/negative). If they have opposite signs, the function fails and returns `#MISSING`.
2. **Division & Assessment**: It divides the `number` by the `multiple`. It looks at the remainder. If the remainder is strictly greater than or equal to half of the `multiple`, it rounds *up* to the next boundary. Otherwise, it rounds *down* to the previous boundary.
3. **Return**: It passes the finalized, rounded value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rounding to Nearest Dozen (Integers)

```essbase
/* We need 28 units. We must round to the nearest dozen (12). 
   28 is closer to 24 than 36. Returns 24. */
"Units_To_Order" = @CalcMgrExcelMROUND(28, 12);
```

### Variant 2: Clean Pricing (Decimals)

```essbase
/* Calculated price is $14.65. We want all prices to be multiples of $0.25. 
   14.65 is closer to 14.75 than 14.50. Returns 14.75 */
"Retail_Price" = @CalcMgrExcelMROUND(14.65, 0.25);
```

---

## Practical Examples

### Example 1: Enforcing Retail Price Tiers

**Scenario**: A retailer determines next year's prices by taking last year's cost and adding a 30% markup. However, the resulting mathematical price (`$13.41`) looks terrible to consumers. The marketing team mandates that all retail prices must be rounded to the nearest nickel (`$0.05`).

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* Calculate the raw, unrounded target price */
    "Raw_Target_Price" = "Cost_Of_Goods_Sold" * 1.30;
    
    IF("Raw_Target_Price" > 0)
        
        /* Round the price to the nearest $0.05 */
        "Final_Retail_Price" = @CalcMgrExcelMROUND("Raw_Target_Price", 0.05);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Optimizing Labor Shifts

**Scenario**: A factory model predicts that a specific product run will require `115` hours of labor based on standard throughput rates. The factory operates strictly in `8`-hour shifts. The manager wants to know how many full shifts they should schedule, rounding to the nearest shift. 

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    IF("Required_Labor_Hours" > 0)
        
        /* 
           Round the hours to the nearest multiple of 8 
           E.g., 115 is closer to 112 than 120. Returns 112.
        */
        "Optimized_Shift_Hours" = @CalcMgrExcelMROUND("Required_Labor_Hours", 8);
        
        /* Calculate how many full shifts that equates to (112 / 8 = 14 shifts) */
        "Full_Shifts_Scheduled" = "Optimized_Shift_Hours" / 8;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Sign Mismatches | `@CalcMgrExcelMROUND(10.5, -2)` | Excel math dictates that the number and the multiple must have the exact same sign. If you pass a positive number and a negative multiple, the function will fail. Use `@ABS` to unify signs if your data is messy |
| Confusing with CEILING/FLOOR | Expecting `28` to round to `36` with a multiple of 12 | `MROUND` rounds to whichever boundary is mathematically *closer*. 28 is closer to 24. If you specifically want to force a number UP to the next boundary (always rounding to 36), you must use `@CalcMgrExcelCEILING`. If you want to force it DOWN (always rounding to 24), use `@CalcMgrExcelFLOOR` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelCEILING`](./@CalcMgrExcelCEILING.md) | Forcefully rounds a number **UP** to the nearest multiple |
| [`@CalcMgrExcelFLOOR`](./@CalcMgrExcelFLOOR.md) | Forcefully rounds a number **DOWN** to the nearest multiple |
| [`@ROUND`](../06_Mathematical/@ROUND.md) | Native Essbase function that rounds to a specific decimal precision, rather than an arbitrary multiple |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelmround.html)
