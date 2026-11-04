# @CalcMgrBitShiftLeft

## Overview

`@CalcMgrBitShiftLeft` is a **custom Calc Manager bitwise function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a mathematical "left shift" operation on the binary representation of an integer, moving all bits to the left by a specified number of positions and filling the vacated right-side positions with zeros.

### Why Does This Function Exist—

In computer science, shifting binary bits to the left by `N` positions is the mathematical equivalent of multiplying the decimal number by `2^N` (two to the power of N). 
While you can simply write `"Value" * 2` in Essbase, `@CalcMgrBitShiftLeft` is provided for developers migrating highly specific low-level algorithms, hashing functions, or complex custom security models from Java or Groovy directly into Calc Scripts. It executes at the processor level via Java, making it technically faster than standard floating-point multiplication, though this speed difference is completely negligible in standard FP&A OLAP operations.

### When to Use It

- When implementing advanced custom hashing or encryption algorithms inside a Calc Script.
- When generating complex sequential bitmasks dynamically.
- When porting low-level C++ or Java routines into Calc Manager.
- Almost never in standard financial FP&A models (use standard multiplication like `* 2` or `* 4` for readability).

---

## Category

**Mathematical / Bitwise / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrBitShiftLeft(value, shiftAmount)
```

### Formal Syntax

```
@CalcMgrBitShiftLeft(integerExpression, shiftAmount)
```

Where:
- `integerExpression` — The primary integer you want to shift.
- `shiftAmount` — The number of positions to shift the bits to the left.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Integer | ✅ Yes | The primary integer. Must be a whole number; floating-point decimals will be truncated or cause unpredictable bitwise behavior. |
| `shiftAmount`| Integer | ✅ Yes | The number of bit positions to shift to the left. |

---

## Return Value

**Return Type**: Integer

Returns the new decimal integer resulting from the left shift.
Mathematically, the result equals: `value * (2 ^ shiftAmount)`.

---

## How It Works (Behind the Scenes)

1. **Binary Conversion**: Essbase (via the Java engine) converts the decimal integer into its binary equivalent.
   - Example: `value` = 3 (Binary: `0000 0011`)
2. **Left Shift Operation**: It takes all bits and shifts them to the left by `shiftAmount` spaces. The new spaces on the right are filled with `0`s. Any bits pushed past the maximum size of the integer (typically 32-bit in Java) are discarded (this can cause sign flips to negative numbers in edge cases).
   - Example: Shifting by 2.
   - `0000 0011` << 2
   - `0000 1100` 
3. **Decimal Conversion**: It converts the resulting binary sequence back to a decimal integer.
   - Result: 12 (Which is `3 * (2^2)`)

---

## Syntax Variants & Scenarios

### Variant 1: Equivalent of Multiplying by 2

```essbase
/* Shifts bits left by 1 (Equivalent to multiplying by 2^1) */
"Result" = @CalcMgrBitShiftLeft("Input_Value", 1);
```

### Variant 2: Equivalent of Multiplying by 8

```essbase
/* Shifts bits left by 3 (Equivalent to multiplying by 2^3) */
"Result" = @CalcMgrBitShiftLeft("Input_Value", 3);
```

---

## Practical Examples

### Example 1: Dynamic Mask Generation

**Scenario**: You are using a Bitmasking architecture to track statuses. You want to dynamically generate the mask for "Status Level 5". Status levels are sequential powers of 2 (Level 1 = 2, Level 2 = 4, Level 3 = 8). You can generate the mask dynamically using a bit shift.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    /* We want to find the mask for Level 5.
       We take the number 1 (Binary 0001) and shift it left by 5 positions.
       0001 << 5 = 0010 0000 (Decimal 32) */
       
    IF("Project_Level" != #MISSING)
        
        "Dynamic_Status_Mask" = @CalcMgrBitShiftLeft(1, "Project_Level");
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Ultra-Fast Integer Multiplication (Niche Optimization)

**Scenario**: A client has a massive dataset where an integer account needs to be multiplied by 4 across 50 million intersections. While standard `* 4` is fast, bit shifting is technically processed faster at the CPU level. (Again, in Essbase, block I/O time dwarfs CPU time, so this is rarely noticeable, but technically valid).

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Multiply the integer by 4 (2^2) by shifting left 2 spaces */
    "Adjusted_Units" = @CalcMgrBitShiftLeft("Raw_Units", 2);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using with decimals | `@CalcMgrBitShiftLeft(10.5, 2)` | Bitwise operations require pure integers. Using floating point numbers will cause errors or return nonsensical binary conversions |
| Overflowing the Integer | Shifting left too many times on a large number | Java uses signed 32-bit integers. If you shift a `1` bit into the far-left position (the sign bit), the resulting decimal number will suddenly become negative. Ensure your shifts stay within safe integer bounds |
| Poor Readability | Using `@CalcMgrBitShiftLeft("Value", 1)` instead of `"Value" * 2` | Always prioritize readability in FP&A models. Only use bitwise shifts if explicitly executing a bitmasking algorithm or porting a hash function |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrBitShiftRight`](./@CalcMgrBitShiftRight.md) | The opposite operation (shifts bits right, dividing the number by 2^N) |
| [`@CalcMgrBitUnsignedShiftRight`](./@CalcMgrBitUnsignedShiftRight.md) | Shifts bits right but ignores the negative/positive sign bit, filling with zeros |
| [`@CalcMgrBitOR`](./@CalcMgrBitOR.md) | Commonly used alongside shift operations when building bitmasks |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_bitshiftleft.html)
