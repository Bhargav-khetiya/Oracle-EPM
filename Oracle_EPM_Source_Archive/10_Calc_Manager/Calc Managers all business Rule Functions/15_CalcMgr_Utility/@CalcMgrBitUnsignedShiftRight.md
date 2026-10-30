# @CalcMgrBitUnsignedShiftRight

## Overview

`@CalcMgrBitUnsignedShiftRight` is a **custom Calc Manager bitwise function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a mathematical "unsigned right shift" operation on the binary representation of an integer, moving all bits to the right by a specified number of positions, and forcibly filling the newly vacated left-most bits with zeros, regardless of the original sign of the number.

### Why Does This Function Exist?

In Java (the underlying engine for Calc Manager), integers are signed 32-bit values. The far-left bit (the 32nd bit) is the "Sign Bit" (0 = positive, 1 = negative). 
When you use a standard right shift (`@CalcMgrBitShiftRight`), the system preserves the sign by copying the sign bit into the new spaces on the left. If you shift a negative number right, it stays negative.
However, if you are treating the 32-bit integer not as a standard math number, but strictly as a raw container for 32 Boolean flags (Bitmasking), the "Sign Bit" is just Flag #32. You do not want it to magically duplicate itself across the integer when you shift bits around. 
`@CalcMgrBitUnsignedShiftRight` (equivalent to the `>>>` operator in Java) ignores the concept of positive/negative numbers. It just blindly shifts bits to the right and pumps zeros into the left side.

### When to Use It

- When implementing advanced data-packing algorithms where all 32 bits of an integer are used to store data, and the sign of the number is irrelevant.
- To safely extract bit flags from the far-left side of an integer without accidentally spawning a trail of `1`s (which happens if you use a signed shift on a negative number).
- When migrating low-level unsigned hashing or encryption algorithms from Java/C++ into Calc Scripts.
- Never in standard financial FP&A models.

---

## Category

**Mathematical / Bitwise / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrBitUnsignedShiftRight(value, shiftAmount)
```

### Formal Syntax

```
@CalcMgrBitUnsignedShiftRight(integerExpression, shiftAmount)
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

Returns the new decimal integer resulting from the unsigned right shift. 
If the original number was positive, the result is identical to `@CalcMgrBitShiftRight`. If the original number was negative, the result will immediately become a large positive number (because the leading `1` sign bit is replaced by a `0`).

---

## How It Works (Behind the Scenes)

1. **Binary Conversion**: Essbase (via the Java engine) converts the decimal integer into its 32-bit binary equivalent.
   - Example (Negative Number): `value` = -2147483648 (Binary: `10000000...00000000`)
2. **Unsigned Right Shift Operation**: It takes all bits and shifts them to the right by `shiftAmount` spaces. The bits that fall off the right edge are discarded. The new spaces on the left are strictly filled with `0`s, overwriting the sign bit.
   - Shifting by 1.
   - `10000000...00000000` >>> 1
   - `01000000...00000000` 
3. **Decimal Conversion**: It converts the resulting binary sequence back to a decimal integer.
   - Result: 1073741824 (The number became positive because the sign bit was flushed with a zero).

---

## Syntax Variants & Scenarios

### Variant 1: Unsigned Shift for Unpacking

```essbase
/* Shift right by 4, guaranteeing zeros on the left edge */
"Result" = @CalcMgrBitUnsignedShiftRight("Packed_Data_Account", 4);
```

---

## Practical Examples

### Example 1: Safely Unpacking 32-Bit Status Arrays

**Scenario**: A developer heavily optimized a database by storing 32 distinct boolean Yes/No questions inside a single account called `Survey_Responses`. The far-left bit (Bit 32) represents Question 32. If Question 32 is "Yes", the bit is 1, which unfortunately makes the decimal integer evaluate as a negative number in Java.
If you need to shift the bits right to read Question 30, using a standard signed shift would drag that `1` across the number, corrupting Questions 31 and 30. You must use an Unsigned Shift.

```essbase
FIX("FY25", "Working", @LEVEL0("Customer"))
    
    IF("Survey_Responses" != #MISSING)
        
        /* Shift right by 29 positions to isolate Question 30.
           Because we use the Unsigned shift, we guarantee the left side fills with 0s,
           even if Question 32 (the sign bit) was True (1). */
           
        "Extracted_Q30_Flag" = @CalcMgrBitAnd(
            @CalcMgrBitUnsignedShiftRight("Survey_Responses", 29), 
            1
        );
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for Mathematics | Relying on this function to divide a negative number by 2 | If you use an unsigned shift on `-10`, you do not get `-5`. You get `2147483643`. If you want mathematical division, use standard division (`/ 2`) or the signed `@CalcMgrBitShiftRight` |
| Using with decimals | `@CalcMgrBitUnsignedShiftRight(10.5, 2)` | Bitwise operations require pure integers. Using floating point numbers will cause errors or return nonsensical binary conversions |
| Poor Readability | Using this function outside of explicit data-packing architectures | This is a highly specialized computer science function. It should never appear in a standard Gross Margin or Headcount calculation script |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrBitShiftRight`](./@CalcMgrBitShiftRight.md) | The signed version of the right shift (preserves positive/negative status) |
| [`@CalcMgrBitShiftLeft`](./@CalcMgrBitShiftLeft.md) | The left-shifting equivalent (multiplies by 2^N) |
| [`@CalcMgrBitAnd`](./@CalcMgrBitAnd.md) | Commonly used immediately after an unsigned shift to isolate the specific bit you just moved to the right edge |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_bitunsignedshiftright.html)
