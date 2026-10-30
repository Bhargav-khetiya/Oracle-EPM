# @LOG

## Overview

`@LOG` is a **native Essbase mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the **Natural Logarithm** (base *e*) of a given numeric value.

### Why Does This Function Exist?

In advanced financial modeling, statistics, and data science, logarithmic transformations are essential for normalizing highly skewed data or modeling exponential compound growth.
If a data scientist is pushing a massive dataset of "Store Revenue" into a predictive Machine Learning model, raw revenue numbers (ranging from $10,000 to $50,000,000) will break the algorithm due to extreme variance. The standard mathematical solution is to take the Natural Logarithm ($\ln$) of every revenue number, compressing that massive range into a tight, manageable scale (e.g., $9.21$ to $17.72$).
Essbase calculation engines are natively built on C-math libraries. `@LOG` exposes the standard C `log()` function directly to the Essbase calculation script, allowing administrators to execute these deep statistical transformations natively inside the database without having to export the data to Python or R.

### When to Use It

- **Data Normalization**: Smoothing out extreme statistical outliers in historical data before running a linear regression or statistical forecasting algorithm on it.
- **Compound Growth Isolation**: Reversing the mathematical effects of continuous exponential growth to determine the underlying, steady-state rate of return (calculating the continuous compound rate).
- **Custom Decay Curves**: Building complex asset decay or user-retention curves where the drop-off rate is logarithmic rather than linear.

---

## Category

**Mathematical / Scientific & Statistical / Essbase Native Functions**

---

## Syntax

```essbase
@LOG(numeric_value)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numeric_value` | Numeric | ✅ Yes | The mathematical value, formula, or member reference you want to transform. <br>*Crucial: This value MUST be strictly greater than 0.* |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the natural logarithm (base *e*, where $e \approx 2.71828$) of the input.
- **Mathematical Bound**: The input must be positive. The natural logarithm of $0$ is undefined (approaching negative infinity), and the logarithm of a negative number is imaginary.
- **Invalid Inputs**: If you pass `0`, a negative number, or `#MISSING` (which evaluates as `0`) into the function, Essbase cannot calculate it. It will return `#MISSING` and may log a mathematical error warning in the Job Console.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine resolves the `numeric_value` to its double-precision floating-point state.
2. **Boundary Check**: It verifies that the number is $> 0$. If it is $\le 0$, it aborts and returns `#MISSING`.
3. **C-Math Execution**: It executes the standard C-library `log(x)` function, which utilizes a highly optimized Taylor series or hardware-level floating-point algorithm to calculate the natural logarithm.
4. **Return**: It writes the resulting transformed double back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Natural Log

```essbase
/* 
   Calculates the natural log of 10.
   e^2.302585 = 10.
   Returns ~2.302585.
*/
"Normalized_Value" = @LOG(10);
```

---

## Practical Examples

### Example 1: Normalizing Sales Data for Regression

**Scenario**: The FP&A team is running a predictive forecasting model that relies on historical `"Gross_Sales"`. However, three flagship stores have sales in the millions, while fifty standard stores have sales in the thousands. This massive variance breaks the trendline. The script must take the natural logarithm of all sales data and store it in a staging account (`"Normalized_Sales"`) before the external model reads it.

```essbase
FIX("FY25", "Working", @LEVEL0("Stores"))
    
    /* 
       1. We MUST check that sales are greater than 0.
       Log(0) or Log(Negative) will crash the math engine or return #MISSING.
    */
    IF("Gross_Sales" > 0)
        
        /* 
           2. Execute the Natural Log transformation.
           If sales were 50,000, Normalized_Sales becomes ~10.82.
           If sales were 5,000,000, Normalized_Sales becomes ~15.42.
           The variance is now compressed and safe for linear regression.
        */
        "Normalized_Sales" = @LOG("Gross_Sales");
        
    ELSE
        
        /* 
           3. Safely handle empty or negative stores.
        */
        "Normalized_Sales" = #MISSING;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing Natural Log with Base-10 | `@LOG(100)` | In many calculators, the `LOG` button means "Logarithm Base 10". In C-programming and Essbase, `@LOG` specifically means "Natural Logarithm" (Base *e*, often written as $\ln$). If you want the Base-10 logarithm (where the log of $100$ is $2$), you MUST use the explicitly named `@LOG10` function |
| Log of Zero | Crashing the block | The most common failure point for statistical functions in EPM is forgetting that `#MISSING` evaluates as `0`. If you run `@LOG("Revenue")` on an empty block, Essbase attempts to calculate $\ln(0)$, which is mathematically undefined. You MUST wrap all logarithmic functions in `IF(Value > 0)` |
| Trying to Undo It with Multiplication | Reversing the Log | Once you transform a number into a natural logarithm, you cannot just multiply it to get the original number back. You must use the exponential function to reverse it (e.g., $e^x$). Essbase provides the `@EXP` function specifically to reverse the effects of `@LOG` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@LOG10`](./@LOG10.md) | Calculates the Base-10 logarithm (where $100 = 2$), rather than the Natural Logarithm |
| [`@EXP`](./@EXP.md) | The mathematical inverse. Raises $e$ to the power of the input, effectively reversing the `@LOG` transformation |
| [`@POWER`](./@POWER.md) | A generalized exponent function that allows you to raise any base to any power, rather than strictly using Euler's number ($e$) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — LOG](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/log.html)
