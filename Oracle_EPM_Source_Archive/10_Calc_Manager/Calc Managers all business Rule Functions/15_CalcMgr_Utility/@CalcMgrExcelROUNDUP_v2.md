# @CalcMgrExcelROUNDUP

## Overview

`@CalcMgrExcelROUNDUP` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `ROUNDUP` function directly inside an Essbase calculation script. 
It strictly rounds a number **away from zero** to a specified number of decimal digits, entirely ignoring the standard mathematical rules of nearest-neighbor rounding.

### Why Does This Function Exist?

Standard rounding (`@ROUND`) evaluates the next digit to decide whether to round up or down. E.g., `10.2` rounds down to `10`.
However, in procurement, capacity planning, and logistics models, you often must strictly round *up* to ensure you have enough resources. If a project requires `10.2` hours of specialized labor, and contractors can only be hired in full 1-hour increments, standard rounding says you only need 10 hours. If you only hire 10 hours, the project fails because it is 0.2 hours short. You must forcefully round UP to `11`.
`@CalcMgrExcelROUNDUP` handles this forced escalation automatically. It allows you to specify the exact decimal precision you want to retain, and then forcefully bumps the final digit up (away from zero) if any trailing decimals exist, ensuring your EPM models never under-forecast critical operational requirements.

### When to Use It

- **Procurement Planning**: Ensuring you order enough raw materials when fractional boxes or gallons cannot be purchased.
- **Labor Forecasting**: Rounding required labor hours up to the next full shift to guarantee full operational coverage.
- Whenever you need to migrate an Excel spreadsheet containing the `ROUNDUP` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelROUNDUP(number, num_digits)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The raw numeric value you want to round up. |
| `num_digits` | Numeric | ✅ Yes | The number of digits to which you want to round. `0` = integers. `>0` = decimal places. `<0` = rounds to the left of the decimal point (e.g., tens, hundreds). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the forcefully escalated number.
- **Directional Note**: The function always rounds *away from zero*. 
  - `3.1` rounds up to `4`. 
  - `-3.1` rounds "up" (away from zero) to `-4`.

---

## How It Works (Behind the Scenes)

1. **Precision Shifting**: The Java engine takes the number and shifts the decimal point based on `num_digits`. (e.g., if rounding `3.141` to 2 digits, it temporarily multiplies it by 100 to become `314.1`).
2. **Escalation Math**: It checks if there is any fractional remainder. If there is, it forcefully escalates the integer component (using `Math.ceil` for positive numbers, or `Math.floor` for negative numbers) to ensure the value moves strictly away from `0`. (e.g., `314.1` becomes `315`).
3. **Re-Shifting**: It divides the number back by the precision multiplier (e.g., `315 / 100 = 3.15`).
4. **Return**: Passes the resulting value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rounding Up to Integers

```essbase
/* 10.2 hours required. Forcefully rounds up to 11. */
"Labor_Hours_To_Hire" = @CalcMgrExcelROUNDUP(10.2, 0);
```

### Variant 2: Rounding Up to Hundreds

```essbase
/* Passes a negative num_digits (-2). Rounds 1,215 up to 1,300. */
"Safe_Cash_Reserve" = @CalcMgrExcelROUNDUP(1215, -2);
```

---

## Practical Examples

### Example 1: Minimum Master Carton Orders

**Scenario**: A corporate procurement system calculates exactly how many individual units of a product are needed next month (e.g., `215`). However, the supplier only sells the product in master cartons of `50`. The system must divide the required units by 50 (`4.3`), and forcefully round UP to ensure they don't run out of stock. 

```essbase
FIX("FY25", "Working", @LEVEL0("Raw_Materials"))
    
    IF("Required_Units" > 0)
        
        /* Calculate raw cartons (215 / 50 = 4.3) */
        VAR vRawCartons = "Required_Units" / 50;
        
        /* 
           Forcefully round UP to 0 decimal places to find full cartons to order.
           Returns 5.
        */
        "Cartons_To_Order" = @CalcMgrExcelROUNDUP(vRawCartons, 0);
        
        /* Calculate the physical units that will arrive (5 * 50 = 250) */
        "Units_Arriving" = "Cartons_To_Order" * 50;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Number Confusion | Expecting `-3.1` to round up to `-3` | Mathematical "Ceiling" logic rounds towards positive infinity. However, `ROUNDUP` strictly rounds *away from zero*. If you pass `-3.1`, it rounds to `-4`. If you actually want it to round up to `-3`, you must use standard `CEILING` logic |
| Confusing with CEILING | Expecting to round to a multiple | `ROUNDUP` only rounds to powers of 10 (tenths, hundredths, tens, hundreds). If you need to forcefully round a number up to the nearest multiple of `12` (dozens) or `0.25` (quarters), you must use `@CalcMgrExcelCEILING` |
| Zero Remainder | Expecting `4.0` to become `5` | If a number is already an exact integer (or an exact match to the requested decimal precision), no rounding occurs. `4.0` returns `4`. It only rounds up if there is a fractional remainder |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelROUNDDOWN`](./@CalcMgrExcelROUNDDOWN.md) | The direct counterpart: forcefully rounds a number *towards* zero |
| [`@CalcMgrExcelCEILING`](./@CalcMgrExcelCEILING.md) | Forcefully rounds a number up to an arbitrary *multiple* (e.g., nearest 5), rather than just a decimal precision |
| [`@ROUND`](../06_Mathematical/@ROUND.md) | Native Essbase function for standard, nearest-neighbor rounding |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelroundup.html)
