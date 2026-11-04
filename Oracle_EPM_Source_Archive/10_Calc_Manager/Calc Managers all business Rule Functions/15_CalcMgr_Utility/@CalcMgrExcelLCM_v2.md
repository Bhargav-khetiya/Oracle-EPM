# @CalcMgrExcelLCM

## Overview

`@CalcMgrExcelLCM` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `LCM` function directly inside an Essbase calculation script. 
It calculates the **Least Common Multiple** of two or more integers. The LCM is the smallest positive integer that is perfectly divisible by all of the provided numbers.

### Why Does This Function Exist—

In supply chain, procurement, and manufacturing models, aligning disparate production cycles or batch constraints requires finding a common operational denominator. 
For example, a raw material supplier only sells screws in boxes of 25. Another supplier only sells washers in boxes of 15. If a manufacturing process requires exactly 1 screw and 1 washer per widget, what is the minimum number of components you can buy to ensure you have exactly matching quantities with zero leftovers— You must find the Least Common Multiple of 25 and 15 (which is 75).
Writing a custom loop in Essbase to iteratively calculate multiples of numbers until a match is found is horribly inefficient and can easily cause infinite loops if poorly designed. `@CalcMgrExcelLCM` delegates this calculation to the Java engine, instantly returning the mathematically perfect intersection point.

### When to Use It

- **Procurement Alignment**: Synchronizing purchase orders for complementary components that are sold in different lot sizes.
- **Manufacturing Scheduling**: Determining the synchronization point of two machines running on different cycle times (e.g., Machine A finishes a batch every 8 hours, Machine B every 12 hours. They will finish simultaneously every 24 hours).
- Whenever you need to migrate an Excel spreadsheet containing the `LCM` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelLCM(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelLCM(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, variables, or Essbase accounts. You can also pass a range of members (like `@CHILDREN("Components")`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first integer. |
| `val2` | Numeric | ✅ Yes | The second integer. |
| `[valN]` | Numeric | ❌ No  | Any subsequent integers to include in the evaluation. All numbers must be >= 0. |

---

## Return Value

**Return Type**: Numeric (Integer returned as double-precision floating point)

Returns the smallest positive integer that is a multiple of all provided numbers.
- E.g., `@CalcMgrExcelLCM(25, 15)` returns `75`.
- If any of the provided numbers is exactly `0`, the LCM is mathematically undefined in this context, and the function will return `0`.

---

## How It Works (Behind the Scenes)

1. **Parameter Truncation**: If you pass decimal values (e.g., `25.8, 15.1`), the Java engine automatically truncates them to integers (`25, 15`) before running the math.
2. **Validation Check**: It ensures all numbers are >= 0. If any number is negative, the function fails and returns `#MISSING`.
3. **Algorithmic Execution**: The engine calculates the LCM using the mathematical formula: `LCM(a, b) = (|a * b|) / GCD(a, b)`. It relies heavily on the Greatest Common Divisor calculation internally.
4. **Return**: It passes the final integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Component Synchronization (List)

```essbase
/* Component A sold in 25s, B in 15s. Returns 75. */
"Optimal_Procurement_Lot" = @CalcMgrExcelLCM(25, 15);
```

### Variant 2: Passing an Array

```essbase
/* Analyzes lot sizes across an entire product group */
"Master_Lot_Size" = @CalcMgrExcelLCM("Supplier_Lot_Size"->@CHILDREN("Component_Group"));
```

---

## Practical Examples

### Example 1: Synchronizing Maintenance Cycles

**Scenario**: A manufacturing plant has three critical conveyor belts. Belt A requires maintenance every 4 weeks. Belt B requires it every 6 weeks. Belt C requires it every 8 weeks. To minimize factory downtime, the Plant Manager wants to know how many weeks until all three belts are scheduled for maintenance at the exact same time, allowing them to schedule a unified "Factory Shutdown" day.

```essbase
FIX("FY25", "Working", "Factory_Floor")
    
    /* Calculate the LCM of the maintenance schedules */
    "Weeks_Until_Unified_Shutdown" = @CalcMgrExcelLCM(
        "Maintenance_Freq_Weeks"->"Belt_A",
        "Maintenance_Freq_Weeks"->"Belt_B",
        "Maintenance_Freq_Weeks"->"Belt_C"
    );
    
    /* 
       LCM of 4, 6, and 8 is 24.
       Every 24 weeks, all three belts align perfectly.
    */
                             
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Numbers | `@CalcMgrExcelLCM(10, -5)` | LCM is typically defined for non-negative integers. Passing a negative number causes the Calc Manager function to fail. Use `@ABS` to unify your data signs |
| Passing Decimals | `@CalcMgrExcelLCM(10.5, 5.5)` | The function truncates decimals instantly (`10, 5`) and returns `10`. It will NOT calculate the LCM of the fractional components. Only use this function on integer data |
| Massive Return Values | LCM of 3, 7, 11, 13, 17, 19 | The LCM grows exponentially fast if you provide an array of prime numbers (since the LCM of prime numbers is simply all of them multiplied together). While Essbase can store massive floating-point numbers, be aware that pushing dozens of disparate prime lot sizes into this function might yield a number so large it is operationally useless (e.g., returning an optimal lot size of 5 million) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelGCD`](./@CalcMgrExcelGCD.md) | The direct counterpart: Calculates the Greatest Common Divisor (the largest number that divides evenly *into* all provided numbers, rather than the smallest number that is a *multiple* of them) |
| [`@CalcMgrExcelMOD`](../06_Mathematical/@MOD.md) | Calculates the remainder of division, often used alongside LCM logic |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excellcm.html)
