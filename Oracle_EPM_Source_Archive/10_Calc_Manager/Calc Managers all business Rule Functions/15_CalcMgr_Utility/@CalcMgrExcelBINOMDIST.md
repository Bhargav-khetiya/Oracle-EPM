# @CalcMgrExcelBINOMDIST

## Overview

`@CalcMgrExcelBINOMDIST` is a **custom Calc Manager statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `BINOMDIST` function directly inside an Essbase calculation script. 
It calculates the **Binomial Distribution Probability**, which tells you the likelihood of getting exactly *X* successes in *Y* independent trials, given a specific probability of success for each individual trial.

### Why Does This Function Exist?

In advanced Risk Management, Quality Assurance, and Operational Planning models, analysts frequently need to calculate probability distributions. For example, if a factory knows that 2% of its parts are defective, what is the probability that in a batch of 100 parts, *exactly* 3 will be defective? What is the probability that *at most* 3 will be defective?
To calculate this manually in Essbase requires calculating complex factorials (Combinations) and exponents: `C(n, k) * p^k * (1-p)^(n-k)`. Trying to build this algebraic formula manually using standard Essbase math functions is extremely cumbersome, slow, and prone to precision loss.
`@CalcMgrExcelBINOMDIST` offloads this complex statistical math to the underlying Java engine, returning the exact same probability score that the legacy Excel model produced, allowing FP&A teams to run Monte Carlo simulations or probabilistic risk assessments directly inside the multidimensional cube.

### When to Use It

- **Quality Assurance Planning**: Predicting the probability of failure rates in manufacturing output.
- **Risk Assessment**: Calculating the likelihood of a specific number of defaults in a portfolio of loans, given a historical default rate.
- **Sales Forecasting**: If a salesperson has a 10% historical close rate, what is the probability they will close exactly 5 out of their next 20 leads?

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelBINOMDIST(number_s, trials, probability_s, cumulative)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number_s` | Numeric | ✅ Yes | The number of successes you want to evaluate (e.g., exactly `3` defective parts). Must be an integer >= 0. |
| `trials` | Numeric | ✅ Yes | The total number of independent trials (e.g., a batch of `100` parts). Must be an integer >= `number_s`. |
| `probability_s`| Numeric | ✅ Yes | The historical probability of success for a single trial (e.g., `0.02` for 2%). Must be between `0` and `1`. |
| `cumulative`| Boolean | ✅ Yes | `1` (True) = Calculates the **Cumulative Distribution** (probability of getting *at most* `number_s` successes). `0` (False) = Calculates the **Probability Mass** (probability of getting *exactly* `number_s` successes). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns a decimal representing the probability percentage (between `0` and `1`). 
- e.g., A return value of `0.182` means there is an 18.2% chance of the event occurring.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures `number_s` and `trials` are positive integers, and that `probability_s` is safely bounded between `0.0` and `1.0`.
2. **Formula Execution (Mass Function)**: If `cumulative` is `0`, the engine calculates `Combinations(trials, number_s) * (probability ^ number_s) * ((1 - probability) ^ (trials - number_s))`.
3. **Cumulative Loop**: If `cumulative` is `1`, the engine loops from `0` up to `number_s`, calculating the probability mass for each step, and summing them all together to find the cumulative probability.
4. **Return**: Passes the final decimal probability back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Exact Probability (Probability Mass Function)

```essbase
/* 
   Probability of getting EXACTLY 5 heads in 10 coin flips (50% chance per flip).
   Returns ~ 0.246 (24.6%)
*/
"Prob_Exact" = @CalcMgrExcelBINOMDIST(5, 10, 0.5, 0);
```

### Variant 2: Cumulative Probability

```essbase
/* 
   Probability of getting AT MOST 5 heads in 10 coin flips.
   Returns ~ 0.623 (62.3%)
*/
"Prob_At_Most" = @CalcMgrExcelBINOMDIST(5, 10, 0.5, 1);
```

---

## Practical Examples

### Example 1: Factory Defect Risk Modeling

**Scenario**: A manufacturing plant is planning its QA budget. Historically, the `"Defect_Rate"` for a specific product is 2% (`0.02`). They produce in batches of `100` (`"Batch_Size"`). If a batch has *more than 3* defects, the entire batch must be scrapped. The QA director needs to know the probability of a batch surviving (i.e., having 3 or fewer defects). 

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* Ensure the parameters exist */
    IF("Defect_Rate" > 0 AND "Batch_Size" > 0)
        
        /* 
           We want to know the probability of getting AT MOST 3 defects.
           Therefore, cumulative flag = 1.
        */
        "Probability_Batch_Survival" = @CalcMgrExcelBINOMDIST(
            3,               /* number_s: up to 3 defects */
            "Batch_Size",    /* trials: 100 parts */
            "Defect_Rate",   /* probability_s: 0.02 */
            1                /* cumulative: TRUE */
        );
        
        /* If the survival probability drops below 80%, flag it for QA Review */
        IF("Probability_Batch_Survival" < 0.80)
            "QA_Review_Required" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Whole Number Probabilities | Passing `2` instead of `0.02` | The `probability_s` parameter explicitly requires a decimal between `0` and `1`. If you pass a whole percentage like `50`, the function will fail. Always divide by 100 if your Essbase data is stored as whole numbers |
| Number of Successes > Trials | `BINOMDIST(150, 100, 0.5, 0)` | You cannot have 150 successes in only 100 trials. The `number_s` parameter must always be less than or equal to the `trials` parameter, otherwise the function returns `#MISSING` |
| Negative Numbers | Passing `-1` for successes | Binomial distributions do not support negative outcomes or negative probabilities. All inputs must be positive |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelCOMBIN`](./@CalcMgrExcelCOMBIN.md) | Calculates the number of possible combinations (a core component of the Binomial equation) |
| [`@CalcMgrExcelNORMDIST`](./@CalcMgrExcelNORMDIST.md) | Calculates the Normal Distribution probability (often used as an approximation for Binomial distributions in massive sample sizes) |
| [`@CalcMgrExcelPOISSON`](./@CalcMgrExcelPOISSON.md) | Calculates the Poisson distribution probability (often used for predicting the number of events over a fixed period of time) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelbinomdist.html)
