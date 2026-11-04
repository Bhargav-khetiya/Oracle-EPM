# @FACTORIAL

## Overview

`@FACTORIAL` is a **native Essbase mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the **factorial** of a given integer. In mathematics, the factorial of a non-negative integer $n$ (denoted as $n!$) is the product of all positive integers less than or equal to $n$. (e.g., $5! = 5 \times 4 \times 3 \times 2 \times 1 = 120$).

### Why Does This Function Exist—

In advanced operations research, probability modeling, and workforce optimization, administrators often need to calculate combinations or permutations (how many different ways can a schedule be arranged, or what is the probability of a specific sequence of events occurring). 
The mathematical formulas for combinations ($nCr$) and permutations ($nPr$) rely heavily on factorials: $\frac{n!}{r!(n-r)!}$.
Writing a recursive loop in an Essbase calculation script to multiply a number by $n-1$, then $n-2$, is computationally expensive and difficult to construct using standard EPM blocks. `@FACTORIAL` natively executes this recursive multiplication in the underlying C-engine instantly, returning the exact product for use in advanced statistical algorithms.

### When to Use It

- **Workforce Permutations**: Calculating how many different shift-assignment combinations are possible for a pool of 10 employees to optimize labor scheduling algorithms.
- **Probability Distributions**: Feeding factorial results into custom Poisson or Binomial distribution formulas for predictive sales forecasting.
- **Supply Chain Routing**: Calculating the number of possible routing paths for a delivery truck with multiple stops to optimize logistics costs.

---

## Category

**Mathematical / Advanced Statistics & Exponents / Essbase Native Functions**

---

## Syntax

```essbase
@FACTORIAL(integer_value)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `integer_value` | Numeric | ✅ Yes | The non-negative integer whose factorial you want to calculate ($n$). <br>If a fractional decimal is passed (e.g., `4.5`), Essbase will implicitly truncate/round it to an integer before evaluating. |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the mathematical product ($n!$).
- **Zero Input**: Mathematically, $0! = 1$. If you pass `0`, the function correctly returns `1.0`.
- **Negative Input**: Factorials do not exist for negative numbers. If you pass a negative number, the function returns `#MISSING`.
- **Missing Data**: If the input is `#MISSING`, the function treats it as `0`, resulting in a return value of `1.0`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The calculation engine resolves the input number and truncates any decimal remainders.
2. **Validation**: It checks if the number is `< 0`. If so, it aborts and returns `#MISSING`. It checks if it is `0`. If so, it returns `1.0`.
3. **Execution Loop**: It initiates a rapid C-level `for` loop, multiplying $n \times (n-1)$ down to $1$. 
4. **Return**: It casts the massive resulting integer into a double-precision floating-point number (to avoid standard 32-bit integer overflow) and returns it to the script.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Factorial Execution

```essbase
/* 
   Calculates 5! (5 * 4 * 3 * 2 * 1)
   Result is 120.
*/
"Combinations" = @FACTORIAL(5);
```

---

## Practical Examples

### Example 1: Calculating Shift Permutations

**Scenario**: A warehouse has `Pool_Size` (e.g., 8 workers) and `Shift_Slots` (e.g., 3 open shifts). The operations team needs to know exactly how many unique ways they can assign 3 workers from a pool of 8. The mathematical formula for Permutations is $P(n,r) = \frac{n!}{(n-r)!}$. The script must calculate this natively.

```essbase
FIX("FY25", "Working", @LEVEL0("Warehouses"))
    
    IF("Pool_Size" > 0 AND "Shift_Slots" > 0)
        
        /* 
           1. Calculate the numerator: n!
           (e.g., 8!)
        */
        VAR vNumerator = @FACTORIAL("Pool_Size");
        
        /* 
           2. Calculate the denominator parameter: (n - r)
           (e.g., 8 - 3 = 5)
        */
        VAR vDenominatorParam = "Pool_Size" - "Shift_Slots";
        
        /* 
           3. Calculate the denominator factorial: (n-r)!
           (e.g., 5!)
        */
        VAR vDenominator = @FACTORIAL(vDenominatorParam);
        
        /* 
           4. Execute the final division to find total permutations.
           (e.g., 40,320 / 120 = 336)
        */
        "Total_Permutations" = vNumerator / vDenominator;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Block Explosion on #MISSING | `Account = @FACTORIAL(Empty_Account)` | As with `@EXP`, because $0! = 1$, executing this on `#MISSING` data literally generates a `1.0` where no data previously existed. If run across a large dimension without an `IF` statement, it will explode your database size. Always wrap it in an `IF(Account != #MISSING)` check |
| Overflowing the Engine | `@FACTORIAL(200)` | Factorials grow at an astonishingly violent mathematical rate. `10!` is $3.6$ Million. `20!` is $2.4 \times 10^{18}$. `170!` is the absolute maximum limit of a standard 64-bit IEEE double (roughly $7.2 \times 10^{308}$). If you attempt to calculate `@FACTORIAL(200)`, the EPM server will experience an `#OVERFLOW` error and likely return `#MISSING` or crash the specific calculation thread. Never feed unbounded large numbers into this function |
| Decimal Inputs | `@FACTORIAL(4.7)` | The mathematical Gamma function allows factorials of decimals, but Essbase does not implement it. If you pass `4.7`, Essbase will silently truncate it to `4` and calculate `4!` (24). Ensure your inputs are clean integers |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@POWER`](./@POWER.md) | A less explosive scaling mathematical function used for standard exponential growth ($x^y$) rather than factorial combinations |
| [`@EXP`](./@EXP.md) | Calculates the exponential of Euler's constant ($e^x$), heavily used alongside factorials in statistical probability curves |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — FACTORIAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/factorial.html)
