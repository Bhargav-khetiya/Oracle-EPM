# @CalcMgrBitExBoolOR

## Overview

`@CalcMgrBitExBoolOR` is a **custom Calc Manager bitwise logical function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a Boolean Exclusive OR (XOR) operation. It evaluates two boolean conditions and returns `True` (1) if *exactly one* of the conditions is true, but returns `False` (0) if both are true or if both are false.

### Why Does This Function Exist?

In standard Essbase logical statements, the `OR` operator is *inclusive*. 
If you write `IF(Condition_A OR Condition_B)`, the block executes if A is true, if B is true, AND if both A and B are true.
Sometimes business logic dictates an *exclusive* choice: a condition where a member can be one thing, or the other thing, but it is illegal for it to be both. This is known as an XOR (Exclusive OR) gate.
While you can write this out manually `IF((A AND NOT B) OR (B AND NOT A))`, the `@CalcMgrBitExBoolOR` function provides a dedicated, native method for this exact evaluation.

### When to Use It

- When enforcing strict mutually exclusive business rules (e.g., An employee can be Contractor OR Full-Time, but absolutely not both).
- In data validation scripts that flag contradictory data inputs submitted by users.
- When building complex conditional logic that requires XOR gating without writing verbose nested IF/AND/NOT statements.

---

## Category

**Logical / Boolean / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrBitExBoolOR(condition1, condition2)
```

### Formal Syntax

```
@CalcMgrBitExBoolOR(booleanExpression1, booleanExpression2)
```

Where:
- `booleanExpression1` — The first condition to evaluate (must resolve to 1/True or 0/False).
- `booleanExpression2` — The second condition to evaluate (must resolve to 1/True or 0/False).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `condition1` | Boolean | ✅ Yes | The first logical test (e.g., `"Account_A" > 0`). |
| `condition2` | Boolean | ✅ Yes | The second logical test (e.g., `"Account_B" > 0`). |

---

## Return Value

**Return Type**: Boolean / Numeric (1 or 0)

| Condition 1 | Condition 2 | Result (Return Value) |
|-------------|-------------|-----------------------|
| True (1) | False (0) | **True (1)** |
| False (0) | True (1) | **True (1)** |
| True (1) | True (1) | False (0) *(Exclusive behavior)* |
| False (0) | False (0) | False (0) |

---

## How It Works (Behind the Scenes)

1. **Evaluation**: Essbase evaluates `condition1` and resolves it to a boolean `1` or `0`. It does the same for `condition2`.
2. **XOR Gate**: It passes these two boolean values through a logical Exclusive-OR gate. 
3. **Return**: If the inputs are different (one is 1, one is 0), it returns `1`. If they are the same (both 1 or both 0), it returns `0`.

---

## Syntax Variants & Scenarios

### Variant 1: Basic IF Statement Evaluation

```essbase
/* Executes only if Account_A has data OR Account_B has data, but NOT both */
IF(@CalcMgrBitExBoolOR("Account_A" > 0, "Account_B" > 0))
    /* Proceed with exclusive logic */
ENDIF
```

---

## Practical Examples

### Example 1: Data Validation - Mutually Exclusive Inputs

**Scenario**: You have a CapEx planning form. A user can choose to lease an asset OR buy an asset, but they cannot do both for the same line item. You need a validation rule that flags an error if they enter data into both the Lease and Buy accounts, or if they enter data into neither. They must pick exactly one.

```essbase
FIX("FY25", "Plan", @LEVEL0("Asset_Line_Item"))
    
    /* We want to ensure that exactly ONE of the two options has a value.
       If both have a value, or neither have a value, the XOR returns false (0). */
       
    IF(@CalcMgrBitExBoolOR("Lease_Assumption" > 0, "Buy_Assumption" > 0))
        /* Valid entry: They picked exactly one */
        "Validation_Error_Flag" = 0;
    ELSE
        /* Invalid entry: They picked both, or neither */
        "Validation_Error_Flag" = 1;
    ENDIF
    
ENDFIX
```

---

### Example 2: Checking Mutually Exclusive Attributes

**Scenario**: Products are tagged with attributes. A product can be "Domestic" or "International". Due to legacy outline issues, these are two separate Boolean attributes instead of a single drop-down. You want to execute a calc only for products that are properly set up (they have exactly one of those flags set to True).

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* Check if exactly one flag is true */
    IF(@CalcMgrBitExBoolOR(@ATTRIBUTEBVAL("Is_Domestic") == 1, @ATTRIBUTEBVAL("Is_International") == 1))
        
        /* Valid setup. Proceed with revenue calc */
        "Projected_Rev" = "Units" * "Price";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using non-boolean inputs | `@CalcMgrBitExBoolOR(50, 100)` | This is a *logical* function, not a mathematical bitwise XOR. The inputs must be conditions that resolve to True/False or 1/0. For mathematical bitwise XOR on integers, use `@CalcMgrBitExOR` |
| Misunderstanding "Exclusive" | Assuming it works like a normal `OR` statement | If both conditions are true, the function returns FALSE. If you want it to return TRUE when both are true, use the standard `OR` operator natively: `IF(A OR B)` |
| Complex nesting | Nesting multiple XORs (`@CalcMgrBitExBoolOR(A, @CalcMgrBitExBoolOR(B, C))`) | This becomes logically unreadable for most FP&A professionals. If you have more than two mutually exclusive conditions, it is often better to use mathematical addition: `IF((A + B + C) == 1)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| Native `OR` | The inclusive version of this logic (True if A, B, or both are True) |
| [`@CalcMgrBitExOR`](./@CalcMgrBitExOR.md) | The mathematical bitwise version used for flipping bits on integers (e.g., `5 XOR 3`) |
| [`@CalcMgrBitAnd`](./@CalcMgrBitAnd.md) | Performs a logical bitwise AND on integers |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_bitexboolor.html)
