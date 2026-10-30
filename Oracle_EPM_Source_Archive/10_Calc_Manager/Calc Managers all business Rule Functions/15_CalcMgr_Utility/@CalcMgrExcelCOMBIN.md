# @CalcMgrExcelCOMBIN

## Overview

`@CalcMgrExcelCOMBIN` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `COMBIN` function directly inside an Essbase calculation script. 
It calculates the number of possible **Combinations** for a given number of items, where order does not matter. Mathematically, it evaluates the classic binomial coefficient formula: `n! / (k! * (n - k)!)`.

### Why Does This Function Exist?

Combinatorics are heavily used in probability, risk analysis, and operations research. For example, if you have a team of 10 people, and you need to select a committee of 3, how many unique 3-person committees can you form? (The answer is 120).
In standard Essbase math, there is no native factorial function (`!`). To calculate combinations manually, a developer would have to write a custom looping script that multiplies variables incrementally (`10 * 9 * 8 ...`) just to evaluate the numerator, which is horribly inefficient and prone to integer overflow.
`@CalcMgrExcelCOMBIN` handles the complex factorial math entirely in the background Java layer, instantly returning the precise number of combinations, ensuring perfect parity with legacy Excel models that rely on the `=COMBIN()` function.

### When to Use It

- **Risk Management**: Calculating the total possible number of multi-point failure scenarios in a network or manufacturing line.
- **Operations**: Determining how many unique shift pairings can be created from a pool of available workers.
- **Probability Modeling**: Often used as a building block for calculating hyper-geometric or binomial probabilities inside custom financial models.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelCOMBIN(number, number_chosen)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The total size of the pool (`n`). The total number of items available to choose from. Must be >= 0. |
| `number_chosen` | Numeric | ✅ Yes | The size of the subset (`k`). The number of items you are selecting in each combination. Must be >= 0, and <= `number`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the total number of possible combinations.
- The returned value is mathematically an integer, but is returned as a floating-point number compatible with Essbase storage.

---

## How It Works (Behind the Scenes)

1. **Parameter Truncation**: If you pass decimal values (e.g., `COMBIN(10.5, 3.2)`), the Java engine automatically truncates them to integers (`10, 3`).
2. **Validation Check**: It ensures `number` >= 0, `number_chosen` >= 0, and `number` >= `number_chosen`. If any of these rules are violated, it returns `#MISSING`.
3. **Factorial Math**: It executes the binomial coefficient algorithm `n! / (k! * (n-k)!)`. Because factorials get massive very quickly, the Java engine uses optimized reduction algorithms to prevent memory overflow before executing the division.
4. **Return**: It passes the final combination count back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Combination

```essbase
/* 
   We have 10 products. We want to bundle them in groups of 3. 
   How many unique bundles can we make? (Returns 120)
*/
"Total_Possible_Bundles" = @CalcMgrExcelCOMBIN(10, 3);
```

---

## Practical Examples

### Example 1: Workforce Shift Pairing

**Scenario**: You are forecasting labor costs for a specialized task force. You have an "Available_Headcount" pool for each region. The task force requires teams of exactly 4 people. You want to calculate the total number of unique task forces that can be generated from the regional pool to assess staffing flexibility and risk.

```essbase
FIX("FY25", "Working", @LEVEL0("Region"))
    
    /* Ensure we have enough headcount to form at least one team */
    IF("Available_Headcount" >= 4)
        
        /* Calculate the Combinations: COMBIN(Total_Headcount, 4) */
        "Unique_Team_Combinations" = @CalcMgrExcelCOMBIN("Available_Headcount", 4);
        
        /* If flexibility is too low (e.g., fewer than 5 possible combinations),
           flag the region for additional hiring */
        IF("Unique_Team_Combinations" < 5)
            "Hiring_Risk_Flag" = 1;
        ENDIF
        
    ELSE
        
        "Unique_Team_Combinations" = 0;
        "Hiring_Risk_Flag" = 1;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Order Matters vs. Doesn't Matter | Using `COMBIN` when order matters | Combinations assume that selecting [A, B, C] is the exact same outcome as selecting [C, B, A]. If the order of selection *does* matter (e.g., assigning specific roles like President, VP, Treasurer), you must use Permutations, not Combinations |
| Floating Point Capacity | Calculating `COMBIN(1000, 500)` | Factorial math generates numbers that exceed the physical storage limits of a 64-bit floating-point variable very quickly. While Java handles this better than raw Essbase scripts, attempting to calculate massive combinations may result in `#MISSING` or `Infinity` errors. |
| Subset > Total | Passing `COMBIN(5, 10)` | You cannot choose 10 items from a pool of 5. The `number_chosen` must always be less than or equal to `number`. |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelBINOMDIST`](./@CalcMgrExcelBINOMDIST.md) | Uses combinatorics internally to calculate the probability of exact success rates in a given number of trials |
| [`@CalcMgrExcelFACT`](./@CalcMgrExcelFACT.md) | Calculates the raw factorial of a number (`n!`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelcombin.html)
