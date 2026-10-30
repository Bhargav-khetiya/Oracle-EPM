# @CalcMgrBitAnd

## Overview

`@CalcMgrBitAnd` is a **custom Calc Manager bitwise function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a bitwise logical `AND` operation between two integers. 

### Why Does This Function Exist?

In traditional financial planning applications, binary and bitwise operations are extremely rare. Essbase is fundamentally a multidimensional OLAP database designed for floating-point aggregations (like Revenue and Expenses), not low-level computer science operations.
However, in highly advanced models (particularly those dealing with complex system security, custom metadata tagging, or high-performance state tracking), developers sometimes use **Bitmasking**.
Bitmasking allows you to store multiple boolean states (True/False flags) inside a single integer account rather than creating a dozen separate accounts. For example, instead of having accounts for `Is_Active`, `Is_Approved`, and `Is_Locked`, you store the value `7` (Binary `111`), which represents all three states at once.
`@CalcMgrBitAnd` allows you to query these bitmasked integers to see if a specific flag is set.

### When to Use It

- When implementing a Bitmasking architecture to conserve block size and reduce the number of accounts.
- To check if a specific binary flag is toggled "ON" inside a combined status integer.
- When migrating low-level logic from Groovy or Java back into pure Calc Script syntax.
- Almost never in standard financial FP&A models (use standard boolean accounts instead for readability).

---

## Category

**Mathematical / Bitwise / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrBitAnd(value1, value2)
```

### Formal Syntax

```
@CalcMgrBitAnd(integerExpression1, integerExpression2)
```

Where:
- `integerExpression1` — The first integer (typically the stored status account).
- `integerExpression2` — The second integer (typically the bitmask you are testing against).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value1` | Integer | ✅ Yes | The primary integer holding the combined bitmask. Must be a whole number; floating-point decimals will be truncated or cause unpredictable bitwise behavior. |
| `value2` | Integer | ✅ Yes | The integer mask representing the specific bit(s) you want to test. |

---

## Return Value

**Return Type**: Integer

Returns an integer resulting from the bitwise `AND` operation.
- If you are testing a specific bit (e.g., testing if bit `4` is on), it will return the value of the mask (`4`) if the bit is ON, and `0` if the bit is OFF.

---

## How It Works (Behind the Scenes)

1. **Binary Conversion**: Essbase converts both decimal integers into their binary equivalents.
   - Example: `value1` = 14 (Binary: `1110`)
   - Example: `value2` = 4  (Binary: `0100`)
2. **Bitwise AND Comparison**: It compares the two binary sequences bit by bit. A resulting bit is set to `1` *only if both* corresponding input bits are `1`.
   - `1110` (14)
   - `0100` (4)
   - `----`
   - `0100` (Result: 4)
3. **Decimal Conversion**: It converts the resulting binary sequence back to a decimal integer and returns it to the script.

---

## Syntax Variants & Scenarios

### Variant 1: Checking a Single Status Flag

```essbase
/* Assume Status = 14, and we want to check if the 'Approved' flag (Value 4) is on */
IF(@CalcMgrBitAnd("Status_Account", 4) == 4)
    /* The Approved bit is ON */
ENDIF
```

### Variant 2: Combining Flags

```essbase
/* Check if both flag 2 and flag 4 are ON. The mask for both is 6 (2 + 4) */
IF(@CalcMgrBitAnd("Status_Account", 6) == 6)
    /* Both bits are ON */
ENDIF
```

---

## Practical Examples

### Example 1: Multi-State Project Tracking (Bitmasking)

**Scenario**: You are tracking project statuses. To save space, you use a single "Project_Status" account.
- Bit 1 (Value 1) = Active
- Bit 2 (Value 2) = Budget_Approved
- Bit 3 (Value 4) = Funded
- Bit 4 (Value 8) = Locked

A project with a status of `7` (1 + 2 + 4) is Active, Approved, and Funded, but not Locked. You want to execute a calculation only if the project is "Funded" (Value 4), regardless of its other states.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    /* We use @CalcMgrBitAnd to isolate the 'Funded' bit (4).
       If the project is Status 7 (0111), 7 AND 4 = 4. 
       If the project is Status 3 (0011), 3 AND 4 = 0. */
       
    IF(@CalcMgrBitAnd("Project_Status", 4) == 4)
        
        /* The project is officially funded, safe to calculate depreciation */
        "Capitalized_Value" = "Total_Cost" * 0.90;
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Security Access Masks

**Scenario**: A custom metadata-driven security model uses integers to define access levels to certain departments.
- Read = 1
- Write = 2
- Delete = 4
If a user has "Write" access (Mask 2), you want to allow a calculation to push data to that department.

```essbase
FIX("FY25", "Working", @LEVEL0("Department"))
    
    /* Check if the user's access mask contains the Write bit (2) */
    IF(@CalcMgrBitAnd("User_Access_Mask", 2) == 2)
        
        /* Push the data */
        "Allocated_Expense" = "Corporate_Pool" * "Share_Pct";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using with decimals | `14.5 AND 4` | Bitwise operations require pure integers. Using floating point numbers (which Essbase natively stores) can cause the Java engine to throw errors or return nonsensical binary conversions |
| Checking for Boolean True | `IF(@CalcMgrBitAnd(Status, 4))` | Unlike C or Python, Essbase `IF` statements expect explicit boolean comparisons for safety. Always compare the result against the mask: `IF(@CalcMgrBitAnd(Status, 4) == 4)` |
| Over-engineering | Using bitmasking when simple boolean accounts would suffice | Unless you have extreme block density issues (e.g., millions of members where adding 3 accounts blows up the database size), it is almost always better to use separate accounts (e.g., "Is_Active", "Is_Funded"). Bitmasking is a premature optimization in 99% of FP&A models |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrBitOR`](./@CalcMgrBitOR.md) | Turns a specific bit ON |
| [`@CalcMgrBitExOR`](./@CalcMgrBitExOR.md) | Toggles a specific bit (turns it ON if OFF, or OFF if ON) |
| [`@CalcMgrBitCompliment`](./@CalcMgrBitCompliment.md) | Inverts all bits (often used to turn a specific bit OFF when combined with AND) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_bitand.html)
