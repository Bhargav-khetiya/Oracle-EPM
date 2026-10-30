# @CalcMgrExcelROUNDDOWN

## Overview

`@CalcMgrExcelROUNDDOWN` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `ROUNDDOWN` function directly inside an Essbase calculation script. 
It strictly rounds a number **towards zero** to a specified number of decimal digits, entirely ignoring the standard mathematical rules of nearest-neighbor rounding.

### Why Does This Function Exist?

Standard rounding (`@ROUND`) looks at the next digit to decide whether to round up or down. E.g., `10.5` rounds up to `11`. `10.2` rounds down to `10`.
However, in physical logistics, manufacturing, and financial payout models, you often cannot assume standard rounding. If you are calculating how many full cars you can build with 15 tires, the math says `15 / 4 = 3.75`. Standard rounding would round `3.75` up to `4`. But you cannot physically sell a car with only 3 tires. You must forcefully round DOWN to `3`, regardless of how close you are to the next integer.
`@CalcMgrExcelROUNDDOWN` handles this forced truncation automatically. It allows you to specify the exact decimal precision you want to retain, and then forcefully chops off all remaining decimals without evaluating them, ensuring your EPM models do not accidentally over-forecast physical capabilities or financial payouts.

### When to Use It

- **Manufacturing Planning**: Determining the maximum number of full, viable products that can be built given a constrained raw material supply (where partial units are useless).
- **Bonus Payouts**: Enforcing strict thresholds where an employee must *fully* achieve a metric to get paid (e.g., missing a quota by 0.01% rounds down and voids the bonus).
- Whenever you need to migrate an Excel spreadsheet containing the `ROUNDDOWN` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelROUNDDOWN(number, num_digits)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The raw numeric value you want to round down. |
| `num_digits` | Numeric | ✅ Yes | The number of digits to which you want to round. `0` = integers. `>0` = decimal places. `<0` = rounds to the left of the decimal point (e.g., tens, hundreds). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the forcefully truncated number.
- **Directional Note**: The function always rounds *towards zero*. 
  - `3.99` rounds down to `3`. 
  - `-3.99` rounds "down" (towards zero) to `-3`.

---

## How It Works (Behind the Scenes)

1. **Precision Shifting**: The Java engine takes the number and shifts the decimal point based on `num_digits`. (e.g., if rounding `3.756` to 2 digits, it temporarily multiplies it by 100 to become `375.6`).
2. **Truncation Math**: It forcefully truncates the decimal component (using `Math.floor` for positive numbers, or `Math.ceil` for negative numbers) to ensure the value moves strictly towards `0`.
3. **Re-Shifting**: It divides the number back by the precision multiplier (e.g., `375 / 100 = 3.75`).
4. **Return**: Passes the resulting value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rounding Down to Integers

```essbase
/* 15 / 4 = 3.75. Forcefully truncates to 3. */
"Max_Cars_Produced" = @CalcMgrExcelROUNDDOWN(3.75, 0);
```

### Variant 2: Rounding Down to Tens

```essbase
/* Passes a negative num_digits (-1). Rounds 158 down to 150. */
"Conservative_Headcount" = @CalcMgrExcelROUNDDOWN(158, -1);
```

---

## Practical Examples

### Example 1: Calculating Maximum Pallet Loads

**Scenario**: A warehouse ships products on pallets. A master pallet holds exactly 48 boxes. The system calculates that a specific customer ordered `200` boxes. The warehouse manager needs to know exactly how many *full* pallets will be shipped, ignoring any partial pallets (which will be shipped via a different carrier).

```essbase
FIX("FY25", "Working", @LEVEL0("Customers"))
    
    IF("Boxes_Ordered" > 0)
        
        /* Calculate raw pallets (200 / 48 = 4.166) */
        VAR vRawPallets = "Boxes_Ordered" / 48;
        
        /* 
           Forcefully round DOWN to 0 decimal places to find full pallets.
           Returns 4.
        */
        "Full_Pallets_To_Ship" = @CalcMgrExcelROUNDDOWN(vRawPallets, 0);
        
        /* Calculate remainder boxes (200 - (4 * 48) = 8 loose boxes) */
        "Loose_Boxes_To_Ship" = "Boxes_Ordered" - ("Full_Pallets_To_Ship" * 48);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Number Confusion | Expecting `-3.9` to round down to `-4` | Mathematical "Floor" logic rounds towards negative infinity. However, `ROUNDDOWN` strictly rounds *towards zero*. If you pass `-3.9`, it rounds to `-3`. If you actually want it to round down to `-4`, you must use `@CalcMgrExcelFLOOR` or `@TRUNC` depending on the exact algebraic intent |
| Confusing with MROUND | Expecting to round to a multiple | `ROUNDDOWN` only rounds to powers of 10 (tenths, hundredths, tens, hundreds). If you need to forcefully round a number down to the nearest multiple of `12` or `0.25`, you must use `@CalcMgrExcelFLOOR` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelROUNDUP`](./@CalcMgrExcelROUNDUP.md) | The direct counterpart: forcefully rounds a number *away* from zero |
| [`@CalcMgrExcelFLOOR`](./@CalcMgrExcelFLOOR.md) | Forcefully rounds a number down to an arbitrary *multiple* (e.g., nearest 5), rather than just a decimal precision |
| [`@ROUND`](../06_Mathematical/@ROUND.md) | Native Essbase function for standard, nearest-neighbor rounding |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelrounddown.html)
