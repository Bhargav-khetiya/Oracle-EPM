# @CalcMgrExcelFACT

## Overview

`@CalcMgrExcelFACT` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `FACT` function directly inside an Essbase calculation script. 
It calculates the **Factorial** of a number, mathematically represented as `n!`.

### Why Does This Function Exist?

A factorial is the product of an integer and all the positive integers below it (e.g., `5!` = 5 * 4 * 3 * 2 * 1 = 120). Factorials are the foundational building block of combinatorics, probability modeling, and operations research.
If a logistics model needs to calculate how many different ways a fleet of 8 delivery trucks can be routed (`8!`), Essbase does not have a native `!` operator. Writing a custom loop in an Essbase calc script to calculate `8 * 7 * 6 * 5...` is highly inefficient and creates messy code.
Furthermore, factorials grow exponentially massive very quickly (`10!` is over 3.6 million, `20!` is roughly 2.4 quintillion). Attempting to calculate these manually using Essbase variables often results in buffer overflows or precision loss. `@CalcMgrExcelFACT` offloads the math to the Java engine, which uses highly optimized mathematical libraries to calculate the exact factorial and return it to Essbase as a 64-bit floating-point number.

### When to Use It

- **Operations Planning**: Determining the total number of possible sequences or permutations for a manufacturing line or delivery route.
- **Probability Modeling**: Used as a component step in calculating complex probabilities (like Poisson or Hypergeometric distributions) if the built-in functions don't offer enough flexibility.
- Whenever you need to migrate an Excel spreadsheet containing the `FACT` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelFACT(number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The non-negative integer you want the factorial of (e.g., `5`). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the mathematical factorial of the number.
- Even though factorials are theoretically whole integers, EPM Cloud handles them as double-precision floating-point numbers to accommodate the massive size of the results without instantly overflowing 32-bit integer limits.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures the `number` is >= 0. Factorials of negative numbers do not exist mathematically; passing a negative will cause the function to return `#MISSING` or throw an error.
2. **Truncation**: If you pass a decimal (e.g., `5.9`), the engine truncates it to the nearest integer (`5`) before executing the math, strictly mirroring Excel's behavior. (It does *not* round it to 6).
3. **Execution**: The Java engine executes an optimized iterative multiplication loop (`n * (n-1) * (n-2)...`).
4. **Return**: Passes the massive resulting number back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Factorial

```essbase
/* Calculates 5! (5 * 4 * 3 * 2 * 1). Returns 120. */
"Possible_Permutations" = @CalcMgrExcelFACT(5);
```

### Variant 2: Decimal Truncation

```essbase
/* Truncates 4.9 down to 4. Calculates 4!. Returns 24. */
"Possible_Permutations" = @CalcMgrExcelFACT(4.9);
```

---

## Practical Examples

### Example 1: Route Optimization Permutations

**Scenario**: A logistics company is running a cost-optimization model. For a specific regional hub, they have an `"Available_Truck_Fleet"`. They want to calculate the total number of unique routing sequences possible (Permutations) if every truck is deployed. This highlights the computational complexity required for their downstream AI routing engine.

```essbase
FIX("FY25", "Working", @LEVEL0("Regional_Hubs"))
    
    /* Ensure the hub has trucks */
    IF("Available_Truck_Fleet" > 0)
        
        /* 
           If a hub has 6 trucks, the number of possible routing sequences is 6!
           6 * 5 * 4 * 3 * 2 * 1 = 720
        */
        "Total_Routing_Permutations" = @CalcMgrExcelFACT("Available_Truck_Fleet");
        
        /* If permutations exceed 1,000,000, flag for cloud-computing allocation */
        IF("Total_Routing_Permutations" > 1000000)
            "Requires_AI_Cluster" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Numbers | `@CalcMgrExcelFACT(-3)` | Factorials are mathematically undefined for negative numbers. The function will fail. If your data contains mixed signs, wrap it in `@ABS("Value")` first |
| Storage Overflows | Calculating `FACT(200)` | While Java handles large numbers well, Essbase blocks have finite storage capacity for double-precision floats. `FACT(170)` is approximately `7.25 * 10^306`, which is right at the boundary of a 64-bit float limit. Passing numbers larger than 170 will likely result in an `Infinity` error or `#MISSING` |
| Using for Combinations | Manually doing `n! / (k! * (n-k)!)` | If you are calculating combinations, do not manually stack three `FACT` functions together. It is inefficient and risks overflowing the numerator before the division can occur. Use `@CalcMgrExcelCOMBIN` instead, which uses reduction algorithms to prevent overflow |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelFACTDOUBLE`](./@CalcMgrExcelFACTDOUBLE.md) | Calculates a "Double Factorial" (e.g., `10!! = 10 * 8 * 6 * 4 * 2`) |
| [`@CalcMgrExcelCOMBIN`](./@CalcMgrExcelCOMBIN.md) | Uses factorials internally to calculate Combinations safely |
| [`@CalcMgrExcelPERMUT`](@CalcMgrExcelCOMBIN.md) | Calculates the number of permutations for a given number of objects |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelfact.html)
