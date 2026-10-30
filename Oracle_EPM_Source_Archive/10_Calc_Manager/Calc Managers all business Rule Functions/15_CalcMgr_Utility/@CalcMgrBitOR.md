# @CalcMgrBitOR

## Overview

`@CalcMgrBitOR` is a **custom Calc Manager bitwise function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a bitwise logical `OR` (Inclusive OR) operation between two integers. 

### Why Does This Function Exist?

Bitwise operations are primarily utilized in EPM when a developer implements a **Bitmasking** strategy—compressing multiple Boolean states (True/False flags) into a single integer account to conserve database block size and reduce outline sparsity. 
In bitmasking architecture:
- `@CalcMgrBitAnd` is used to *Read* a status (check if a bit is ON).
- `@CalcMgrBitOR` is used to *Write* a status. It explicitly turns a specific bit **ON** (sets it to 1) without altering or destroying the state of any other bits stored in that integer.

### When to Use It

- When implementing a Bitmasking architecture to conserve block size and reduce the number of discrete accounts.
- To safely toggle a specific binary flag (like "Is_Approved") to an ON state, ensuring that previously set flags (like "Is_Active") remain intact.
- When migrating low-level logic from Groovy or Java back into pure Calc Script syntax.
- Almost never in standard financial FP&A models (use standard boolean accounts instead for readability).

---

## Category

**Mathematical / Bitwise / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrBitOR(value1, value2)
```

### Formal Syntax

```
@CalcMgrBitOR(integerExpression1, integerExpression2)
```

Where:
- `integerExpression1` — The primary integer (typically the stored status account).
- `integerExpression2` — The integer mask representing the specific bit(s) you want to turn ON.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value1` | Integer | ✅ Yes | The primary integer holding the combined bitmask. Must be a whole number; floating-point decimals will be truncated or cause unpredictable bitwise behavior. |
| `value2` | Integer | ✅ Yes | The integer mask representing the specific bit(s) you want to turn ON. |

---

## Return Value

**Return Type**: Integer

Returns an integer resulting from the bitwise `OR` operation.
- The resulting integer will have the targeted bits explicitly set to `1`, while all non-targeted bits remain exactly as they were prior to the operation.

---

## How It Works (Behind the Scenes)

1. **Binary Conversion**: Essbase (via the Java engine) converts both decimal integers into their binary equivalents.
   - Example: `value1` = 10 (Binary: `1010`) -> Let's say this means "Active" and "Funded"
   - Example: `value2` = 4  (Binary: `0100`) -> Let's say this means "Approved"
2. **Bitwise OR Operation**: It compares the two binary sequences bit by bit. A resulting bit is set to `1` if *either* of the corresponding input bits is `1`.
   - `1010` (10)
   - `0100` (4)
   - `----`
   - `1110` (Result: 14)
3. **Decimal Conversion**: It converts the resulting binary sequence back to a decimal integer (14) and returns it.
*(Notice how the "Approved" bit was successfully added, and the previous "Active" and "Funded" bits were preserved).*

---

## Syntax Variants & Scenarios

### Variant 1: Turning a Flag ON (Setting a bit)

```essbase
/* Assume mask for 'Is_Locked' is 8. This ensures the lock bit is ON. */
"Project_Status" = @CalcMgrBitOR("Project_Status", 8);
```

### Variant 2: Turning Multiple Flags ON at Once

```essbase
/* Mask 12 (4 + 8) turns on BOTH the 4-bit and the 8-bit simultaneously */
"Project_Status" = @CalcMgrBitOR("Project_Status", 12);
```

---

## Practical Examples

### Example 1: Multi-State Project Tracking (Setting a Status)

**Scenario**: You are tracking project statuses using a single "Project_Status" account.
- Bit 1 (Value 1) = Active
- Bit 2 (Value 2) = Needs_Review
- Bit 3 (Value 4) = Budget_Approved
- Bit 4 (Value 8) = Funded

A nightly calculation runs to check if a project has received full funding from corporate. If it has, the system must set the "Funded" bit (Value 8) to ON. However, the system must NOT overwrite the fact that the project might also be "Active" (1) and "Approved" (4). If you just wrote `"Project_Status" = 8;`, you would wipe out the other statuses. You must use `@CalcMgrBitOR` to merge the new status safely.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    /* If corporate allocated funding today */
    IF("Corporate_Funding_Received" > 0)
        
        /* Safely merge the Funded bit (Value 8) into the existing status */
        "Project_Status" = @CalcMgrBitOR("Project_Status", 8);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Security Access Masks (Granting Permissions)

**Scenario**: A custom metadata-driven system uses integers to define security access levels.
- Read = 1
- Write = 2
- Delete = 4

An employee receives a promotion and is granted "Delete" access. They already have "Read" and "Write". You use Bitwise OR to append the new permission to their existing mask.

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    IF("Promotion_Flag" == 1)
        /* Add Delete (4) to their existing mask */
        "User_Access_Mask" = @CalcMgrBitOR("User_Access_Mask", 4);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using with decimals | `10.5 OR 4` | Bitwise operations require pure integers. Using floating point numbers (which Essbase natively stores) can cause errors or return nonsensical binary conversions |
| Using it as a Logical OR | `IF(@CalcMgrBitOR("A" > 0, "B" > 0))` | This is a *mathematical* bitwise OR designed for integers. If you want to evaluate standard inclusive boolean conditions in an `IF` statement, you must use the native `OR` operator natively: `IF(A OR B)` |
| Trying to turn a bit OFF | Trying to use `@CalcMgrBitOR(Status, 0)` | This will do nothing. `10 OR 0` is still `10`. To turn a bit OFF, you must use `@CalcMgrBitCompliment` combined with `@CalcMgrBitAnd` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrBitAnd`](./@CalcMgrBitAnd.md) | Checks if a specific bit is currently ON (Reads the state) |
| [`@CalcMgrBitExOR`](./@CalcMgrBitExOR.md) | Toggles a specific bit (Flips it from ON to OFF or OFF to ON) |
| [`@CalcMgrBitCompliment`](./@CalcMgrBitCompliment.md) | Inverts all bits (used in conjunction with AND to explicitly turn a bit OFF) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_bitor.html)
