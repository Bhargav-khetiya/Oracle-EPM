# @MOD

## Overview

`@MOD` is a **native Essbase mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It performs a "modulo" operation. It divides one numeric value (the dividend) by another numeric value (the divisor) and returns the **remainder** of that division.

### Why Does This Function Exist—

In operational modeling, workforce planning, and logistics, division rarely results in a perfect integer. 
For example, if a warehouse has $105$ `"Total_Units"` and they must be packed into `"Pallets"` that hold exactly $10$ units each, doing standard division ($105 / 10$) gives $10.5$ pallets. 
But physically, you can't ship half a pallet. The business needs to know two things: How many full pallets do we ship— (10). And how many units are left over sitting on the floor— (5).
You can find the full pallets using `@INT(105 / 10)`. 
`@MOD` exists to find the leftover pieces. By calling `@MOD(105, 10)`, the math engine divides 105 by 10, completely ignores the whole number quotient (10), and explicitly returns the remainder: $5$. This allows for complex, physical unit routing and cycle processing natively in Essbase.

### When to Use It

- **Cycle Identification**: Determining if a specific period is the end of a quarter or the end of a year by running modulo math on a sequential time counter (`IF(@MOD(MonthCounter, 3) == 0)` means it is the end of a quarter).
- **Physical Unit Leftovers**: Calculating the remaining raw materials after full batches have been processed.
- **Odd/Even Splitting**: Passing `@MOD(Value, 2)` to determine if a number is Even (returns 0) or Odd (returns 1).

---

## Category

**Mathematical / Scientific & Statistical / Essbase Native Functions**

---

## Syntax

```essbase
@MOD(dividend, divisor)
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
- **Decimals**: If you pass decimal values (e.g., `@MOD(10.5, 3)`), it will return the decimal remainder (`1.5`).
- **Divide by Zero**: If the `divisor` is `0` or `#MISSING`, the function will return `#MISSING` and likely throw a Divide-By-Zero warning in the server log.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine resolves both the `dividend` and the `divisor` to double-precision floats.
2. **Boundary Check**: It verifies that `divisor != 0`.
3. **C-Math Execution**: It executes a standard C-level floating-point modulo operation (`fmod(dividend, divisor)`). Internally, this is calculated as: `dividend - (@INT(dividend / divisor) * divisor)`.
4. **Return**: It returns the isolated remainder to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Finding Leftovers

```essbase
/* 
   Divides 25 by 7. 
   7 goes into 25 three times (21). 
   The remainder is 4. Returns 4.
*/
"Leftover_Units" = @MOD(25, 7);
```

---

## Practical Examples

### Example 1: Flagging Quarterly Cycles

**Scenario**: A corporate reporting script loops through 60 months of historical data. The script uses a dynamic counter (`vMonthIndex`) that increments from 1 to 60. The business logic requires a special `"Quarter_End_Bonus"` calculation to run ONLY on the 3rd, 6th, 9th, etc. months. The administrator uses `@MOD` to check if the current counter is perfectly divisible by 3.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    VAR vMonthIndex = 1;
    
    /* Assuming we are inside a 60-period loop */
    LOOP(60)
        
        /* 
           1. We check if the current month index is perfectly divisible by 3.
           If vMonthIndex is 3, @MOD(3, 3) = 0.
           If vMonthIndex is 4, @MOD(4, 3) = 1 (Not 0).
        */
        IF(@MOD(vMonthIndex, 3) == 0)
            
            /* 
               2. We hit a Quarter-End month (3, 6, 9). Execute the bonus math.
            */
            "Quarter_End_Bonus" = "Base_Salary" * 0.05;
            
        ENDIF
        
        /* Increment the counter for the next loop pass */
        vMonthIndex = vMonthIndex + 1;
        
    ENDLOOP
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Divide by Zero | `@MOD(100, 0)` | The most frequent crash vector for this function is passing a dynamic metric into the divisor (`@MOD("Total", "Divisor_Account")`), and failing to check if `"Divisor_Account"` is empty (`#MISSING` evaluates as `0`). You MUST wrap modulo functions in an `IF` statement: `IF("Divisor_Account" > 0)` to prevent the script from halting |
| Confusing with `@INT` | Returning the Quotient | If you divide 105 by 10, `@MOD` returns `5`. It does NOT return `10`. If you want the number of full, complete divisions (the quotient), you must use `@INT(105 / 10)` |
| Sign Handling | Negative Dividends | Modulo math on negative numbers can be notoriously unpredictable across different OS C-libraries. In Essbase, `@MOD(-10, 3)` generally returns `-1`. If you require strictly positive remainders for cyclical logic, you should pass the absolute value of the dividend into the function using `@ABS` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@REMAINDER`](./@REMAINDER.md) | An older alias/equivalent for the exact same function. `@MOD` is generally preferred as it aligns with standard programming syntax |
| [`@INT`](./@INT.md) | The mathematical inverse concept. It returns the whole-number quotient of a division, explicitly discarding the remainder |
| [`@TRUNCATE`](./@TRUNCATE.md) | Similar to `@INT`, slices off fractional remainders to leave clean integers |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MOD](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mod.html)
