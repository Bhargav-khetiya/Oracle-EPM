# @CalcMgrExcelGCD

## Overview

`@CalcMgrExcelGCD` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `GCD` function directly inside an Essbase calculation script. 
It calculates the **Greatest Common Divisor** of two or more integers. The GCD is the largest positive integer that divides all the provided numbers without leaving a remainder.

### Why Does This Function Exist?

In advanced supply chain optimization, manufacturing, and packaging models, identifying the Greatest Common Divisor is a core component of calculating optimal batch sizes, cutting patterns, or unified shipping pallets.
For example, a factory produces 250 units of Product A and 150 units of Product B. They need to pack them into identical master shipping crates so that every crate is full and contains only one type of product. The optimal crate size is the GCD of 250 and 150 (which is 50).
Writing a custom mathematical loop in an Essbase calc script to execute the Euclidean algorithm (finding the GCD manually) is horribly complex and slow. `@CalcMgrExcelGCD` delegates this recursive mathematical algorithm to the Java engine, returning the exact optimal batch size instantly.

### When to Use It

- **Supply Chain / Logistics**: Determining unified pallet sizes, optimal shipping box volumes, or standardized container loads across disparate product demand curves.
- **Manufacturing Planning**: Calculating optimal raw material cutting lengths to minimize waste across multiple product requirements.
- Whenever you need to migrate an Excel spreadsheet containing the `GCD` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelGCD(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelGCD(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, variables, or Essbase accounts. You can also pass a range of members (like `@CHILDREN("Products")`).

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

Returns the largest positive integer that divides all the provided numbers evenly.
- E.g., `@CalcMgrExcelGCD(54, 24)` returns `6`.

---

## How It Works (Behind the Scenes)

1. **Parameter Truncation**: If you pass decimal values (e.g., `54.8, 24.1`), the Java engine automatically truncates them to integers (`54, 24`) before running the math.
2. **Validation Check**: It ensures all numbers are >= 0. If any number is negative, the function fails and returns `#MISSING`.
3. **Euclidean Algorithm**: The engine executes standard GCD recursive math to find the largest common factor.
4. **Return**: It passes the final integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding Optimal Batch Sizes (List)

```essbase
/* We need to batch 250, 150, and 100 units. Returns 50. */
"Optimal_Batch_Size" = @CalcMgrExcelGCD(250, 150, 100);
```

### Variant 2: Passing an Array

```essbase
/* Analyzes the demand across all children of 'Products' */
"Optimal_Batch_Size" = @CalcMgrExcelGCD("Demand"->@CHILDREN("Products"));
```

---

## Practical Examples

### Example 1: Standardizing Master Carton Sizes

**Scenario**: A warehouse stores three variations of a product. Tomorrow's shipping requirements dictate they must ship `240` units of Red, `360` units of Blue, and `180` units of Green. The warehouse manager wants to order standard cardboard boxes (master cartons) that can be used universally for all three colors, such that every box is perfectly full and only contains one color. The optimal box capacity is the GCD.

```essbase
FIX("FY25", "Working", "Warehouse_A")
    
    /* Calculate the Greatest Common Divisor across the three demand streams */
    "Master_Carton_Capacity" = @CalcMgrExcelGCD(
        "Units_Required"->"Red",
        "Units_Required"->"Blue",
        "Units_Required"->"Green"
    );
    
    /* 
       Result: 60.
       Red uses 4 boxes of 60.
       Blue uses 6 boxes of 60.
       Green uses 3 boxes of 60.
    */
    
    /* Calculate total physical boxes needed */
    "Total_Boxes_To_Order" = ("Units_Required"->"Red" / "Master_Carton_Capacity") +
                             ("Units_Required"->"Blue" / "Master_Carton_Capacity") +
                             ("Units_Required"->"Green" / "Master_Carton_Capacity");
                             
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Numbers | `@CalcMgrExcelGCD(50, -25)` | The GCD is only mathematically defined for non-negative integers in this context. Passing a negative number causes the function to fail. Use `@ABS` to unify your data if necessary |
| Passing Decimals | `@CalcMgrExcelGCD(10.5, 5.5)` | The function truncates decimals instantly (`10, 5`) and returns `5`. It will NOT calculate the GCD of the fractional components. Do not use this function on non-integer metrics |
| Prime Number Sets | `@CalcMgrExcelGCD(7, 13)` | If the numbers share no common factors, the function returns `1`. If you are using this to optimize packaging, an answer of `1` means you must package items individually |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelLCM`](./@CalcMgrExcelLCM.md) | The direct counterpart: Calculates the Least Common Multiple (the smallest number that is a multiple of all provided numbers) |
| [`@CalcMgrExcelMOD`](./@CalcMgrExcelMOD.md) | Calculates the remainder of division, which is the foundational mathematical step of the Euclidean GCD algorithm |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelgcd.html)
