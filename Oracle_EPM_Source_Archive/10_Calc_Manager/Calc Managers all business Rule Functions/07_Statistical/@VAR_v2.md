# @VAR

## Overview

`@VAR` is a **native Essbase statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of members and calculates the **Sample Variance** of their numeric values. 

Variance is a foundational statistical measurement that quantifies how far a set of numbers is spread out from their average (mean). A high variance indicates that data points are widely scattered (highly volatile); a low variance indicates that data points are tightly clustered around the mean.

*(Note: `@VAR` calculates the **Sample** variance, dividing by $N-1$. If you need the **Population** variance, dividing by $N$, you must use `@VARP`).*

### Why Does This Function Exist?

In FP&A, knowing the average of a metric is rarely enough to understand the true risk profile of the business. 
For example, two stores might both have an Average Monthly Sales of `$10,000`. But Store A hits exactly `$10,000` every single month (Zero Variance). Store B hits `$20,000` one month, and `$0` the next month (Massive Variance). Store B is incredibly risky from a cash-flow perspective.
Instead of manually calculating the mean, subtracting the mean from every single month, squaring the results, summing them, and dividing by the count minus one... administrators can simply use `@VAR`. It executes the entire complex statistical formula internally, instantly providing the variance score for risk-assessment modeling.

### When to Use It

- **Risk & Volatility Modeling**: Calculating the trailing 12-month variance of raw material costs to determine if a commodity pricing hedge needs to be purchased.
- **Quality Control**: Analyzing the variance of "Manufacturing Defect Rates" across 50 factories to identify which factories are operating outside of statistically acceptable parameters.
- **Predictive Confidence Intervals**: Using Variance (and its square root, Standard Deviation) to build Monte Carlo or probabilistic forecast scenarios (Best Case vs Worst Case).

---

## Category

**Mathematical / Statistical & Array Processing / Essbase Native Functions**

---

## Syntax

```essbase
@VAR(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, MemberRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ❌ No  | Determines how empty blocks or zero values are handled in the statistical count ($N$):<br>- `SKIPNONE`: Evaluates everything (default).<br>- `SKIPMISSING`: Ignores `#MISSING` blocks.<br>- `SKIPZERO`: Ignores blocks containing exactly `0`.<br>- `SKIPBOTH`: Ignores both. |
| `MemberRange` | Member List | ✅ Yes | The array of members to evaluate (e.g., `"Jan":"Dec"`). |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the statistical Sample Variance of the array.
- **Return Value Scale**: Because Variance involves *squaring* the differences, the returned number will be massive compared to the raw data (e.g., the variance of $100$ and $200$ is $5000$). To return the value to the original scale of the data, you must calculate the Standard Deviation (`@STDEV`).
- **Insufficient Data**: Sample variance requires at least TWO valid data points (because the formula divides by $N-1$. If $N=1$, it divides by zero). If the array contains only 1 valid number, the function returns `#MISSING`.
- **Zero Variance**: If all numbers in the array are perfectly identical, the variance is exactly `0`.

---

## How It Works (Behind the Scenes)

1. **Array Processing**: The engine compiles the `MemberRange` and strips out any members that match the `Skip_Flag`. It counts the remaining valid items ($N$).
2. **Mean Calculation**: It calculates the mathematical Average (`@AVG`) of the valid array items ($\mu$).
3. **Squared Differences**: It iterates through the array again. For each item ($x$), it subtracts the average, and squares the result: $(x - \mu)^2$.
4. **Summation**: It adds all those squared differences together.
5. **Division (Sample)**: It divides that massive sum by $N-1$ (Bessel's correction for sample bias).
6. **Return**: It writes the final variance to the block.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Trailing Monthly Volatility

```essbase
/* 
   Calculates the statistical sample variance of Sales across the 12 months.
   If months are empty, they are excluded from the dataset entirely.
*/
"Sales_Volatility" = @VAR(SKIPMISSING, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Identifying Highly Volatile Exchange Rates

**Scenario**: A global corporation wants to flag any currency that is too volatile to use for stable transfer pricing. The rule is: If the sample variance of the FX Rate over the last 6 months exceeds a specific threshold, flag the currency for manual Treasury review.

```essbase
FIX("FY25", "Working", @LEVEL0("Currencies"))
    
    /* 
       1. We calculate the Sample Variance of the FX_Rate across the 
       first 6 months of the year. We use SKIPMISSING so we don't 
       corrupt the math if a currency wasn't traded in Jan.
    */
    "FX_Variance_Score" = @VAR(SKIPMISSING, "FX_Rate"->"Jan":"Jun");
    
    /* 
       2. Evaluate the risk score.
    */
    IF("FX_Variance_Score" > "Treasury_Threshold")
        "High_Risk_Flag" = 1;
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Sample vs Population | Dividing by $N-1$ vs $N$ | `@VAR` calculates the *Sample* variance (it assumes the 12 months you gave it are just a sample of a much larger infinite dataset, so it divides by $N-1$ to be conservative). If your dataset is the ENTIRE universe of data (e.g., there are only 12 months in a year, and you have all 12), you should mathematically use Population Variance (`@VARP`), which divides by exactly $N$ |
| Misinterpreting the Result | "Why is the number so huge?" | As stated, variance squares the differences. If your sales average `$10,000`, your variance might be `2,000,000`. You cannot plot Variance on the same chart as Sales. If you need a volatility metric that is scaled to the original data (e.g., "$10,000 plus or minus $1,400"), you MUST use Standard Deviation (`@STDEV`), which is literally just the square root of Variance |
| Not using `SKIPMISSING` | Zero Corruption | If a store closed for 3 months, and you use `@VAR("Jan":"Dec")`, the engine evaluates those 3 `#MISSING` months as `$0`. This creates a massive artificial gap between the `$0` months and the `$10,000` active months, skyrocketing the variance. Always use `SKIPMISSING` to evaluate only active periods |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@VARP`](../08_Financial/@VARIANCEP.md) | Calculates the Population Variance (divides by $N$ instead of $N-1$) |
| [`@STDEV`](./@STDEV.md) | Calculates the Standard Deviation (the square root of Variance), scaling the risk metric back to the original units |
| [`@AVG`](./@AVG.md) | The mathematical mean, which is the foundational anchor point from which Variance is calculated |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — VAR](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/var.html)
