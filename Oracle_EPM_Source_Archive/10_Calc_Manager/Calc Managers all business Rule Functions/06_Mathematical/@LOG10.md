# @LOG10

## Overview

`@LOG10` is a **native Essbase mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the **Base-10 Logarithm** (the common logarithm) of a specified numeric value. 

### Why Does This Function Exist?

While `@LOG` calculates the Natural Logarithm (Base $e$), `@LOG10` is used for order-of-magnitude scaling. 
In corporate finance and data science, datasets often span massive scales. A company might have a `"Local_Store"` making `$1,000` a day, and a `"Global_HQ"` making `$10,000,000` a day. If you attempt to plot these on a linear chart or feed them into a linear scoring model, the `$1,000` store essentially disappears into a flat line at the bottom.
The Base-10 logarithm answers the question: *"10 raised to what power equals this number?"* 
Because $10^3 = 1,000$, the Base-10 log of $1,000$ is `3`. Because $10^7 = 10,000,000$, the Base-10 log is `7`. 
By passing the raw financial data through `@LOG10`, Essbase compresses a variance of $9,999,000$ down to a clean, highly manageable scale of $3$ to $7$. This allows administrators to build normalized performance indices, tier groupings, and statistical models natively inside the Essbase engine.

### When to Use It

- **Magnitude Scoring**: Converting raw revenue or volume data into a normalized $1-10$ "Tier Score" for stores, where each full integer represents a 10x increase in volume.
- **Data Smoothing**: Preparing financial data for export to external reporting tools that require logarithmic scales to visualize exponential growth clearly.
- **Acoustic / Scientific Modeling**: If Essbase is being used to track non-financial scientific data (like decibels or seismic activity), Base-10 logs are the foundational math for those scales.

---

## Category

**Mathematical / Scientific & Statistical / Essbase Native Functions**

---

## Syntax

```essbase
@LOG10(numeric_value)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numeric_value` | Numeric | ✅ Yes | The mathematical value, formula, or member reference you want to transform. <br>*Crucial: This value MUST be strictly greater than 0.* |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the Base-10 logarithm of the input.
- **Mathematical Bound**: The input must be positive. The logarithm of $0$ is undefined (approaching negative infinity), and the logarithm of a negative number is imaginary.
- **Invalid Inputs**: If you pass `0`, a negative number, or `#MISSING` (which evaluates as `0`) into the function, Essbase cannot calculate it. It will return `#MISSING` and may log a mathematical error warning in the Job Console.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine resolves the `numeric_value` to its double-precision floating-point state.
2. **Boundary Check**: It verifies that the number is $> 0$. If it is $\le 0$, it aborts and returns `#MISSING`.
3. **C-Math Execution**: It executes the standard C-library `log10(x)` function, calculating the precise exponential power required to reach the input value using a Base of 10.
4. **Return**: It writes the resulting transformed double back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Base-10 Log

```essbase
/* 
   Calculates the Base-10 log of 100,000.
   10^5 = 100,000.
   Returns exactly 5.
*/
"Tier_Score" = @LOG10(100000);
```

---

## Practical Examples

### Example 1: Dynamic Revenue Tiering

**Scenario**: A retail company assigns a `"Volume_Tier"` to every store. Instead of manually maintaining these tiers, the FP&A team uses `@LOG10` on the `"Annual_Revenue"`. A store making $100K gets a tier of 5. A store making $1M gets a tier of 6. A store making $10M gets a tier of 7. The script automatically calculates and rounds this tier score.

```essbase
FIX("FY25", "Working", @LEVEL0("Stores"))
    
    /* 
       1. We MUST check that revenue is greater than 0.
       Log(0) or Log(Negative) will crash the math engine or return #MISSING.
    */
    IF("Annual_Revenue" > 0)
        
        /* 
           2. Execute the Base-10 Log transformation.
           If revenue is $5,000,000, @LOG10 is ~6.69.
        */
        VAR vRawLog = @LOG10("Annual_Revenue");
        
        /* 
           3. We use @ROUND to convert 6.69 into a clean integer Tier (7).
        */
        "Volume_Tier" = @ROUND(vRawLog, 0);
        
    ELSE
        
        /* 
           4. Safely handle empty or zero-revenue stores.
        */
        "Volume_Tier" = 0;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing Base-10 with Natural Log | `@LOG10` vs `@LOG` | If you are doing standard financial regression or continuous compound modeling, you generally want the Natural Logarithm (Base $e$), which is the `@LOG` function. `@LOG10` is strictly for order-of-magnitude scaling (Base 10). Using the wrong base will fundamentally break predictive algorithms |
| Log of Zero | Crashing the block | Just like `@LOG`, the most common failure point is forgetting that `#MISSING` evaluates as `0` in math functions. If you run `@LOG10("Revenue")` on an empty block, Essbase attempts to calculate the log of `0`, which is undefined. You MUST wrap all logarithmic functions in `IF(Value > 0)` |
| Trying to Undo It with Multiplication | Reversing the Log | Once you transform a number into a Base-10 logarithm (e.g., $100,000$ becomes $5$), you cannot just multiply it to get the original number back. You must raise 10 to that power. To reverse `@LOG10(x)`, you must use `@POWER(10, x)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@LOG`](./@LOG.md) | Calculates the Natural Logarithm (Base $e$, $\ln$), rather than the Base-10 Logarithm |
| [`@POWER`](./@POWER.md) | The mathematical inverse for Base-10. You use `@POWER(10, Result)` to convert the log score back into the original raw data |
| [`@EXP`](./@EXP.md) | The mathematical inverse specifically for the Natural Logarithm (Base $e$) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — LOG10](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/log10.html)
