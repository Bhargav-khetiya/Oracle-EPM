# @CalcMgrBitShiftRight

## Overview

`@CalcMgrBitShiftRight` is a **custom Calc Manager bitwise function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a mathematical "right shift" operation on the binary representation of an integer, moving all bits to the right by a specified number of positions.

### Why Does This Function Exist—

In computer science, shifting binary bits to the right by `N` positions is the mathematical equivalent of performing integer division by `2^N` (two to the power of N) and discarding the remainder. 
While you can simply write `@TRUNC("Value" / 2)` in Essbase, `@CalcMgrBitShiftRight` is provided for developers implementing highly specific low-level algorithms, data compression, or complex custom bitmasking security models natively inside Calc Scripts. 
This is a **Signed Right Shift** (equivalent to the `>>` operator in Java), meaning it preserves the sign of the number (positive or negative) by filling the newly vacated left-most bits with whatever the original sign bit was.

### When to Use It

- When implementing advanced custom hashing or encryption algorithms inside a Calc Script.
- To rapidly divide integers by powers of 2 while automatically dropping remainders.
- When extracting specific data points that have been packed into a single 32-bit integer to save database space.
- Almost never in standard financial FP&A models (use standard division like `/ 2` or `/ 4` for readability).

---

## Category

**Mathematical / Bitwise / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrBitShiftRight(value, shiftAmount)
```

### Formal Syntax

```
@CalcMgrBitShiftRight(integerExpression, shiftAmount)
```

Where:
- `integerExpression` — The primary integer you want to shift.
- `shiftAmount` — The number of positions to shift the bits to the right.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Integer | ✅ Yes | The primary integer. Must be a whole number; floating-point decimals will be truncated or cause unpredictable bitwise behavior. |
| `shiftAmount`| Integer | ✅ Yes | The number of bit positions to shift to the right. |

---

## Return Value

**Return Type**: Integer

Returns the new decimal integer resulting from the right shift.
Mathematically, for positive numbers, the result equals: `@TRUNC(value / (2 ^ shiftAmount))`.

---

## How It Works (Behind the Scenes)

1. **Binary Conversion**: Essbase (via the Java engine) converts the decimal integer into its binary equivalent.
   - Example: `value` = 12 (Binary: `0000 1100`)
2. **Right Shift Operation**: It takes all bits and shifts them to the right by `shiftAmount` spaces. The bits that fall off the right edge are permanently discarded. The new spaces on the left are filled with the "Sign Bit" (0 for positive numbers, 1 for negative numbers).
   - Example: Shifting by 2.
   - `0000 1100` >> 2
   - `0000 0011` 
3. **Decimal Conversion**: It converts the resulting binary sequence back to a decimal integer.
   - Result: 3 (Which is `12 / (2^2)`)

---

## Syntax Variants & Scenarios

### Variant 1: Equivalent of Integer Division by 2

```essbase
/* Shifts bits right by 1 (Equivalent to dividing by 2^1) */
"Result" = @CalcMgrBitShiftRight("Input_Value", 1);
```

### Variant 2: Equivalent of Integer Division by 8

```essbase
/* Shifts bits right by 3 (Equivalent to dividing by 2^3) */
"Result" = @CalcMgrBitShiftRight("Input_Value", 3);
```

---

## Practical Examples

### Example 1: Unpacking Data (Niche Optimization)

**Scenario**: To save outline size, a developer packed two distinct pieces of information into a single integer account. The right-most 4 bits (0-15) represent a "Status Code", and the bits to the left represent a "Department ID". To extract the Department ID, you must shift the bits to the right by 4, dropping the status code completely.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    IF("Packed_Data_Account" != #MISSING)
        
        /* Shift right by 4 to drop the 4-bit status code and isolate the Department ID */
        "Extracted_Dept_ID" = @CalcMgrBitShiftRight("Packed_Data_Account", 4);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Fast Integer Halving

**Scenario**: You have an inventory model that routinely cuts a reserve assumption in half, discarding any fractional remainders.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* Equivalent to @TRUNC("Reserve_Units" / 2), but executed at the bitwise level */
    "Adjusted_Reserve" = @CalcMgrBitShiftRight("Reserve_Units", 1);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using with decimals | `@CalcMgrBitShiftRight(10.5, 2)` | Bitwise operations require pure integers. Using floating point numbers will cause errors or return nonsensical binary conversions |
| Losing Data (Remainders) | Shifting `13` right by `1` yields `6`, not `6.5` | Bit shifting drops the remainder into the abyss. If you need decimal precision, you must use standard division (`/ 2`) |
| Poor Readability | Using `@CalcMgrBitShiftRight("Value", 1)` instead of `"Value" / 2` | Always prioritize readability in FP&A models. Finance users will not understand bit shifting syntax. Only use this if explicitly executing a bitmasking unpacking algorithm |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrBitShiftLeft`](./@CalcMgrBitShiftLeft.md) | The opposite operation (shifts bits left, multiplying the number by 2^N) |
| [`@CalcMgrBitUnsignedShiftRight`](./@CalcMgrBitUnsignedShiftRight.md) | Shifts bits right but *ignores* the negative/positive sign bit, filling the left edge strictly with zeros. (Equivalent to `>>>` in Java) |
| [`@CalcMgrBitAnd`](./@CalcMgrBitAnd.md) | Commonly used alongside shift operations when unpacking bitmasks |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_bitshiftright.html)
