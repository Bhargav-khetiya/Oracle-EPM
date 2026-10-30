# @CalcMgrExcelMULTINOMIAL

## Overview

`@CalcMgrExcelMULTINOMIAL` is a **custom Calc Manager statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `MULTINOMIAL` function directly inside an Essbase calculation script. 
It calculates the ratio of the factorial of a sum of values to the product of factorials. Mathematically, it calculates: `(a + b + c)! / (a! * b! * c!)`.

### Why Does This Function Exist?

The multinomial theorem is a core concept in combinatorics and probability distribution. It answers questions like: "If I have 10 total slots, how many different ways can I arrange 3 red balls, 2 blue balls, and 5 green balls?" 
The math required is `(3+2+5)! / (3! * 2! * 5!)`. 
To calculate this manually in Essbase, you would need to use the `@CalcMgrExcelFACT` function 4 separate times and manually write the division block. More importantly, factorials grow exponentially. `10!` is 3.6 million. If you try to do this manually with larger numbers (e.g., `(20+30+50)!`), the numerator will instantly exceed the 64-bit storage limit and crash the calculation with an `Infinity` error, even though the final *ratio* is a completely manageable number. 
`@CalcMgrExcelMULTINOMIAL` offloads this entirely to the Java engine. The underlying algorithm reduces the fractions mathematically *before* multiplying them out, entirely bypassing the risk of integer overflow and returning the exact permutation count safely.

### When to Use It

- **Operations Research**: Determining the total number of unique permutations available when assigning a finite pool of workers to different distinct shifts or roles.
- **Probability Modeling**: Calculating the denominator for a Multinomial Distribution probability model (the extension of the Binomial distribution).
- Whenever you need to migrate an Excel spreadsheet containing the `MULTINOMIAL` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelMULTINOMIAL(val1, val2, [val3...])
```

### Formal Syntax

```
@CalcMgrExcelMULTINOMIAL(numericList)
```

Where:
- `numericList` — A comma-separated list of numbers, variables, or Essbase accounts. You can also pass a range of members (like `@CHILDREN("Groups")`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `val1` | Numeric | ✅ Yes | The first integer count (e.g., the number of Group A items). |
| `val2` | Numeric | ✅ Yes | The second integer count (e.g., the number of Group B items). |
| `[valN]` | Numeric | ❌ No  | Any subsequent integer counts. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the mathematical multinomial coefficient.
- E.g., `@CalcMgrExcelMULTINOMIAL(2, 3, 4)` mathematically evaluates to `9! / (2! * 3! * 4!)`, returning `1260`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ingests the array of numbers. It checks that all numbers are `>= 0`. If any number is negative, the function fails.
2. **Missing Handling**: It drops `#MISSING` values. (Note: A `#MISSING` is ignored, but a `0` evaluates to `0! = 1`, which does not change the ratio).
3. **Summation**: It calculates the sum of all the valid numbers (the Numerator baseline).
4. **Reduction Algorithm**: Instead of blindly calculating massive factorials, it uses mathematical reduction (canceling out the largest denominator factorial against the numerator) to safely arrive at the final ratio without risking a floating-point overflow.
5. **Return**: Passes the resulting permutation count back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Groups

```essbase
/* Group 1: 3 items. Group 2: 2 items. Returns 10. */
"Possible_Arrangements" = @CalcMgrExcelMULTINOMIAL(3, 2);
```

### Variant 2: Array Evaluation

```essbase
/* Dynamically calculates arrangements across all departments */
"Possible_Arrangements" = @CalcMgrExcelMULTINOMIAL("Headcount"->@CHILDREN("Departments"));
```

---

## Practical Examples

### Example 1: Calculating Workforce Shift Permutations

**Scenario**: A warehouse has 15 identical employees. For the upcoming week, the manager must assign exactly 5 employees to the Morning shift, 7 to the Afternoon shift, and 3 to the Night shift. The HR modeling system wants to know exactly how many unique workforce combinations are possible. (The math is `15! / (5! * 7! * 3!)`).

```essbase
FIX("FY25", "Working", "Warehouse_A")
    
    /* 
       Calculate the Multinomial Coefficient.
       We pass the exact headcount requirements for each shift.
    */
    "Total_Shift_Combinations" = @CalcMgrExcelMULTINOMIAL(
        "Required_Headcount"->"Morning_Shift",
        "Required_Headcount"->"Afternoon_Shift",
        "Required_Headcount"->"Night_Shift"
    );
    
    /* Result: 360,360 unique shift arrangements */
                             
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Numbers | `@CalcMgrExcelMULTINOMIAL(3, -2)` | Factorials (and by extension, Multinomials) are strictly undefined for negative integers. Passing a negative number causes the function to fail and return `#MISSING`. Use `@ABS` if your source data contains negative adjustments |
| Passing Decimals | `@CalcMgrExcelMULTINOMIAL(3.5, 2.1)` | The Excel algorithm natively truncates decimals before calculating factorials. `3.5` becomes `3`. `2.1` becomes `2`. If you are passing fractional Full-Time Equivalents (FTEs), the function will truncate them, drastically altering your expected math. Only use integers |
| Assuming Limits | Worrying about `170!` | A standard `@CalcMgrExcelFACT` call will crash if you pass `171`, because `171!` exceeds the maximum size of a 64-bit float. However, `MULTINOMIAL` uses internal reduction. You can safely pass `MULTINOMIAL(100, 100)` (which internally involves `200!`) and it will successfully return the exact answer (`9.05 * 10^59`) because the denominators cancel out the massive numerator before the final float is calculated |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelFACT`](./@CalcMgrExcelFACT.md) | Calculates the standard factorial of a single number |
| [`@CalcMgrExcelCOMBIN`](./@CalcMgrExcelCOMBIN.md) | Calculates standard Combinations (which is mathematically identical to a Multinomial with exactly two parameters) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelmultinomial.html)
