# @CalcMgrBitExOR

## Overview

`@CalcMgrBitExOR` is a **custom Calc Manager bitwise function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a bitwise Exclusive OR (XOR) operation between two integers. 

### Why Does This Function Exist?

Bitwise operations are generally used in Essbase when developers implement a **Bitmasking** strategy—condensing multiple Boolean states (True/False flags) into a single integer account to conserve block size. 
In bitmasking, `@CalcMgrBitOR` turns a specific bit ON, and `@CalcMgrBitAnd` checks if a bit is ON.
`@CalcMgrBitExOR` (Exclusive OR) serves a very specific purpose: **Toggling a bit**. If the bit is currently OFF, XOR turns it ON. If the bit is currently ON, XOR turns it OFF. It flips the state of a specific flag without needing an `IF` statement to check its current status first.

### When to Use It

- When implementing a Bitmasking architecture to conserve block size and reduce the number of accounts.
- To safely toggle a specific binary flag (like "Is_Under_Review") back and forth between ON and OFF states without knowing its current state.
- When migrating low-level logic from Groovy or Java back into pure Calc Script syntax.
- Almost never in standard financial FP&A models (use standard boolean accounts instead for readability).

---

## Category

**Mathematical / Bitwise / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrBitExOR(value1, value2)
```

### Formal Syntax

```
@CalcMgrBitExOR(integerExpression1, integerExpression2)
```

Where:
- `integerExpression1` — The primary integer (typically the stored status account).
- `integerExpression2` — The integer mask representing the specific bit(s) you want to toggle.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value1` | Integer | ✅ Yes | The primary integer holding the combined bitmask. Must be a whole number; floating-point decimals will be truncated or cause unpredictable bitwise behavior. |
| `value2` | Integer | ✅ Yes | The integer mask representing the specific bit(s) you want to toggle. |

---

## Return Value

**Return Type**: Integer

Returns an integer resulting from the bitwise `XOR` operation.
- The resulting integer will have the targeted bits flipped (1 becomes 0, 0 becomes 1), while all non-targeted bits remain exactly as they were.

---

## How It Works (Behind the Scenes)

1. **Binary Conversion**: Essbase (via the Java engine) converts both decimal integers into their binary equivalents.
   - Example: `value1` = 11 (Binary: `1011`)
   - Example: `value2` = 2  (Binary: `0010`)
2. **Bitwise XOR Operation**: It compares the two binary sequences bit by bit. A resulting bit is set to `1` *only if exactly one* of the corresponding input bits is `1`. If both are `0` or both are `1`, the result is `0`.
   - `1011` (11)
   - `0010` (2)
   - `----`
   - `1001` (Result: 9)
3. **Decimal Conversion**: It converts the resulting binary sequence back to a decimal integer (9) and returns it.
*(Notice how the 2nd bit flipped from 1 to 0, while all other bits remained exactly the same).*

---

## Syntax Variants & Scenarios

### Variant 1: Toggling a Flag (Switching ON to OFF, or OFF to ON)

```essbase
/* Assume mask for 'Is_Locked' is 8. This toggles the lock state. */
"Project_Status" = @CalcMgrBitExOR("Project_Status", 8);
```

---

## Practical Examples

### Example 1: Multi-State Project Tracking (Toggling a Status)

**Scenario**: You are tracking project statuses using a single "Project_Status" account.
- Bit 1 (Value 1) = Active
- Bit 2 (Value 2) = Needs_Review
- Bit 3 (Value 4) = Funded

Every time a specific nightly calculation runs, any project that had changes made to its budget must toggle its "Needs_Review" flag. If it didn't need review before, it does now. If it already needed review, perhaps the new calculation resolved the variance, so we toggle it off. (In reality, you'd likely use strict `IF` logic, but XOR allows a blind toggle).

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    /* If the budget changed today */
    IF("Budget_Delta" != 0)
        
        /* Toggle the Needs_Review bit (Value 2) on the Project_Status bitmask. */
        "Project_Status" = @CalcMgrBitExOR("Project_Status", 2);
        
    ENDIF
    
ENDFIX
```
*(If Project_Status was 5 (Active, Funded), applying XOR 2 changes it to 7 (Active, Review, Funded). If it was 7, it changes back to 5).*

---

### Example 2: Reverting a Batch Status Change

**Scenario**: A custom metadata-driven system uses integers to define validation states. A batch script accidentally turned on the "Flagged_for_Deletion" bit (Value 16) for a group of entities. You need to write a quick script to revert that specific bit back to 0 for those entities, without disrupting the other validation bits.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* We assume we know the bit was turned ON incorrectly. 
       XORing it again will flip it back OFF. */
       
    IF(@ISUDA("Entity", "Accidentally_Flagged"))
        "Validation_State" = @CalcMgrBitExOR("Validation_State", 16);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using with decimals | `11.5 XOR 2` | Bitwise operations require pure integers. Using floating point numbers (which Essbase natively stores) can cause the Java engine to throw errors or return nonsensical binary conversions |
| Using it as a Logical XOR | `IF(@CalcMgrBitExOR("A" > 0, "B" > 0))` | This is a *mathematical* bitwise XOR designed for integers. If you want to evaluate mutually exclusive boolean conditions in an `IF` statement, you must use `@CalcMgrBitExBoolOR` |
| Toggling blindly | XOR assumes you just want the opposite of whatever state is currently there | If you explicitly want to ensure a bit is ON (regardless of current state), use `@CalcMgrBitOR`. If you want to ensure it is OFF, use `@CalcMgrBitCompliment` combined with `@CalcMgrBitAnd`. Only use XOR for a true toggle |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrBitOR`](./@CalcMgrBitOR.md) | Turns a specific bit ON (Explicitly sets to 1) |
| [`@CalcMgrBitAnd`](./@CalcMgrBitAnd.md) | Checks if a specific bit is currently ON |
| [`@CalcMgrBitCompliment`](./@CalcMgrBitCompliment.md) | Inverts all bits (used in conjunction with AND to explicitly turn a bit OFF) |
| [`@CalcMgrBitExBoolOR`](./@CalcMgrBitExBoolOR.md) | The logical/boolean version of XOR for IF statement evaluation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_bitexor.html)
