# @CalcMgrBitCompliment

## Overview

`@CalcMgrBitCompliment` is a **custom Calc Manager bitwise function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a bitwise logical `NOT` operation (also known as a bitwise complement or inversion) on a single integer.

### Why Does This Function Exist—

Bitwise operations are primarily used in EPM when a developer employs a **Bitmasking** strategy—storing multiple Boolean states (True/False flags) within a single integer account to save block space. 
For example, a "Status" account might hold the value `7` (Binary `0111`), representing that three different flags are currently turned "ON".
While `@CalcMgrBitOR` is used to turn a bit ON, turning a bit OFF requires a combination of operations: you must take the bit you want to turn off, invert it (using `@CalcMgrBitCompliment`), and then apply it to the main account using `@CalcMgrBitAnd`.

### When to Use It

- When implementing a Bitmasking architecture to conserve block size and reduce the number of accounts.
- To invert a binary mask before using it to clear (turn OFF) a specific status flag.
- When migrating low-level logic from Groovy or Java back into pure Calc Script syntax.
- Almost never in standard financial FP&A models (use standard boolean accounts instead for readability).

---

## Category

**Mathematical / Bitwise / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrBitCompliment(value)
```

### Formal Syntax

```
@CalcMgrBitCompliment(integerExpression)
```

Where:
- `integerExpression` — The integer you want to invert (usually a bitmask value).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Integer | ✅ Yes | The integer to invert. Must be a whole number; floating-point decimals will be truncated or cause unpredictable bitwise behavior. |

---

## Return Value

**Return Type**: Integer

Returns the integer representing the binary inversion of the input value.
*(Note: Because Java uses two's complement for signed integers, the bitwise complement of a positive number `N` is usually `-(N + 1)`).*

---

## How It Works (Behind the Scenes)

1. **Binary Conversion**: Essbase (via its underlying Java engine) converts the decimal integer into its binary equivalent.
   - Example: `value` = 4 (Binary: `...00000100`)
2. **Bit Inversion**: It flips every single bit. `0` becomes `1`, and `1` becomes `0`.
   - Result: `...11111011`
3. **Decimal Conversion**: It converts the resulting binary sequence back to a decimal integer and returns it. For the value `4`, the complement is `-5`.

---

## Syntax Variants & Scenarios

### Variant 1: Turning a Bit OFF (The Primary Use Case)

To turn a specific bit OFF in a bitmask without affecting any other bits, you use the formula: `Value = Value AND NOT(Mask)`.

```essbase
/* Assume Status_Account currently holds 7 (0111). We want to turn OFF bit 4 (0100). */
"Status_Account" = @CalcMgrBitAnd("Status_Account", @CalcMgrBitCompliment(4));
/* Result: Status_Account becomes 3 (0011). Bits 1 and 2 remain untouched. */
```

---

## Practical Examples

### Example 1: Multi-State Project Tracking (Clearing a Flag)

**Scenario**: You are tracking project statuses using a single "Project_Status" account.
- Bit 1 (Value 1) = Active
- Bit 2 (Value 2) = Budget_Approved
- Bit 3 (Value 4) = Funded
- Bit 4 (Value 8) = Locked

A project was previously "Funded", but funding was just pulled. The project is still "Active" and "Approved", so you cannot simply set the status to 0. You must selectively turn OFF the "Funded" flag (Value 4) while leaving the rest of the integer intact.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    /* Check if funding was officially revoked via a driver account */
    IF("Funding_Revoked_Flag" == 1)
        
        /* Clear the Funded bit (Value 4) from the Project_Status bitmask.
           We invert the mask (4 -> -5) and use BitAnd to apply it. */
        "Project_Status" = @CalcMgrBitAnd(
            "Project_Status", 
            @CalcMgrBitCompliment(4)
        );
        
    ENDIF
    
ENDFIX
```
*(If Project_Status was 7 (Active, Approved, Funded), applying `BitAnd(7, BitCompliment(4))` changes it to 3 (Active, Approved).)*

---

### Example 2: Resetting Security Access

**Scenario**: A custom metadata-driven security model uses integers to define access levels.
- Read = 1
- Write = 2
- Delete = 4

An employee transfers departments and loses "Write" (2) and "Delete" (4) privileges, but keeps "Read" (1). Instead of wiping their access and rebuilding it, you selectively remove the Write and Delete bits. The mask to remove both is 6 (2 + 4).

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    IF("Transfer_Status" == 1)
        
        /* Remove Write(2) and Delete(4) by complimenting their combined mask (6) */
        "User_Access_Mask" = @CalcMgrBitAnd("User_Access_Mask", @CalcMgrBitCompliment(6));
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using with decimals | `@CalcMgrBitCompliment(14.5)` | Bitwise operations require pure integers. Using floating point numbers will cause errors or return nonsensical binary conversions |
| Trying to use it as a Boolean NOT | `IF(@CalcMgrBitCompliment("Account"))` | This is a mathematical bitwise operator, not a logical `NOT` for `IF` statements. If you want to invert a true/false statement, just use the native `NOT` keyword |
| Confusing the result | Complimenting `4` returns `-5`, which looks like an error to a finance user | This is correct due to two's complement integer math in Java. Do not try to "fix" the negative number; pass it directly into `@CalcMgrBitAnd` as intended |
| Over-engineering | Using bitmasking when simple boolean accounts would suffice | It is almost always better to use separate accounts (e.g., "Is_Active", "Is_Funded"). Bitmasking is a premature optimization in 99% of FP&A models |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrBitAnd`](./@CalcMgrBitAnd.md) | Always used in conjunction with Compliment to turn a specific bit OFF |
| [`@CalcMgrBitOR`](./@CalcMgrBitOR.md) | The opposite action (turns a specific bit ON) |
| [`@CalcMgrBitExOR`](./@CalcMgrBitExOR.md) | Toggles a specific bit (turns it ON if OFF, or OFF if ON) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_bitcompliment.html)
