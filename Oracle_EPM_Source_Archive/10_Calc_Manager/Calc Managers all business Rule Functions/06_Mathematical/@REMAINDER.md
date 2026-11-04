# @REMAINDER

## Overview

`@REMAINDER` is a **native Essbase mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It divides one numeric value (the dividend) by another numeric value (the divisor) and returns the **fractional or integer remainder** of that division.

*(Note: In modern EPM Cloud, `@REMAINDER` is mathematically and functionally identical to `@MOD` (Modulo). They use the exact same underlying C-engine arithmetic. `@REMAINDER` exists primarily as a legacy alias for administrators who prefer non-programmatic, plain-English syntax).*

### Why Does This Function Exist—

When executing workforce planning, logistics routing, or batch-processing models, mathematical division often leaves leftover pieces. 
If a retail location has $52$ `"Sales_Associates"`, and they must be grouped into `"Training_Classes"` that hold exactly $10$ people, dividing $52 / 10$ yields $5.2$ classes. 
The business can't host $0.2$ of a class. They need to know they have $5$ full classes, and they have exactly $2$ associates leftover who need to be rolled over to the next month.
The whole classes are calculated using `@INT(52 / 10)`. 
The leftovers are calculated using `@REMAINDER(52, 10)`. The function divides 52 by 10, strips away the whole-number quotient (5), and explicitly returns the leftover units ($2$). This enables highly precise, physical unit routing natively within the Essbase calculation engine.

### When to Use It

- **Physical Unit Leftovers**: Calculating the remaining raw materials after full manufacturing batches have been processed.
- **Cycle Identification**: Determining if a specific period is the end of a quarter or the end of a year by running remainder math on a sequential time counter (`IF(@REMAINDER(MonthCounter, 3) == 0)` means it is the end of a quarter).
- **Even/Odd Toggling**: Passing `@REMAINDER(Value, 2)` to determine if a dynamic number is Even (returns 0) or Odd (returns 1).

---

## Category

**Mathematical / Scientific & Statistical / Essbase Native Functions**

---

## Syntax

```essbase
@REMAINDER(dividend, divisor)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dividend` | Numeric | ✅ Yes | The number being divided (the total amount). Can be a hardcoded number, formula, or member reference. |
| `divisor` | Numeric | ✅ Yes | The number to divide by. <br>*Crucial: This cannot be 0, as division by zero is mathematically impossible.* |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the remainder of the division.
- **Perfect Division**: If the divisor goes into the dividend perfectly (e.g., $100 / 10$), there is no remainder. The function returns `0`.
- **Decimals**: If you pass decimal values (e.g., `@REMAINDER(10.5, 3)`), it will return the precise decimal remainder (`1.5`).
- **Divide by Zero**: If the `divisor` is `0` or `#MISSING`, the function will return `#MISSING` and likely throw a Divide-By-Zero warning in the server Job Console.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine resolves both the `dividend` and the `divisor` to double-precision floats.
2. **Boundary Check**: It verifies that `divisor != 0`.
3. **C-Math Execution**: It executes a standard C-level floating-point modulo operation (`fmod(dividend, divisor)`). Internally, this is mathematically identical to: `dividend - (@INT(dividend / divisor) * divisor)`.
4. **Return**: It returns the isolated remainder to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Finding Leftover Associates

```essbase
/* 
   Divides 52 by 10. 
   10 goes into 52 five times (50). 
   The remainder is 2. Returns 2.
*/
"Leftover_Associates" = @REMAINDER(52, 10);
```

---

## Practical Examples

### Example 1: Isolating Fractional Cents in Payroll

**Scenario**: A global payroll script calculates `"Bonus_Accrual"` by multiplying `"Base_Salary"` by `0.075`. The result is often a highly precise decimal (e.g., `$1,045.6789`). The accounting system cannot accept fractions of a cent; it only accepts whole integers. The administrator must split the number into two accounts: `"Whole_Dollars"` and `"Fractional_Cents"`.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    /* 
       1. First, we calculate the raw, precise accrual amount in memory.
       (e.g., 1045.6789)
    */
    VAR vRawAccrual = "Base_Salary" * 0.075;
    
    /* 
       2. We use @INT to slice off the decimal and keep the whole dollars.
       (Result = 1045)
    */
    "Whole_Dollars" = @INT(vRawAccrual);
    
    /* 
       3. We use @REMAINDER with a divisor of 1 to extract ONLY the decimals.
       (Result = 0.6789)
    */
    "Fractional_Cents" = @REMAINDER(vRawAccrual, 1);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Divide by Zero | `@REMAINDER(100, 0)` | The most frequent crash vector for this function is passing a dynamic metric into the divisor (`@REMAINDER("Total", "Divisor_Account")`), and failing to check if `"Divisor_Account"` is empty (`#MISSING` evaluates as `0`). You MUST wrap remainder functions in an `IF` statement: `IF("Divisor_Account" > 0)` to prevent the script from halting |
| Confusing with `@INT` | Returning the Quotient | If you divide 52 by 10, `@REMAINDER` returns `2`. It does NOT return `5` (the number of full classes). If you want the number of full, complete divisions (the quotient), you must use `@INT(52 / 10)`. If you want standard mathematical rounding, use `@ROUND` |
| Negative Numbers | Sign Shifting | Remainder math on negative numbers can be unpredictable across different internal Essbase patches. Generally, `@REMAINDER(-10, 3)` returns `-1`. If you require strictly positive remainders for your logic, wrap the dividend in `@ABS` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MOD`](./@MOD.md) | The exact same function. Modulo (`@MOD`) is the standard programmatic nomenclature, while `@REMAINDER` is the plain-English alias |
| [`@INT`](./@INT.md) | The mathematical inverse concept. It returns the whole-number quotient of a division, explicitly discarding the remainder |
| [`@TRUNCATE`](./@TRUNCATE.md) | Similar to `@INT`, slices off fractional remainders to leave clean integers, but handles negatives differently |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — REMAINDER](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/remainder.html)
