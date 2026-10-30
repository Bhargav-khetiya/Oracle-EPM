# @CORRELATION

## Overview

`@CORRELATION` is a **native Essbase statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the **Pearson correlation coefficient (r)** between two sets of data across a specified range. It returns a statistical value between `-1.0` and `1.0` that defines exactly how strongly the two data sets are related to one another.

### Why Does This Function Exist?

When building predictive forecasting models or analyzing driver-based planning, financial analysts must understand the relationship between variables. 
Does an increase in `"Marketing_Spend"` actually lead to an increase in `"Sales_Volume"`? If so, how strong is that relationship? 
You cannot determine this using basic addition or variance analysis. You must use statistical correlation. A correlation of `1.0` means they move in perfect unison. A correlation of `-1.0` means they move in exact opposite directions. A correlation near `0.0` means they have absolutely nothing to do with each other.
`@CORRELATION` automates this complex statistical math. By passing the two data series (e.g., Marketing and Sales) and the time horizon, Essbase dynamically calculates the covariance and standard deviations, outputting the exact `r` value. This allows FP&A teams to programmatically validate their planning drivers (e.g., automatically dropping drivers with a correlation below `0.5`).

### When to Use It

- **Driver Validation**: Evaluating historical actuals to prove that `"Headcount"` is a statistically valid driver for `"IT_Software_Expenses"` before using it in next year's forecast.
- **Predictive Analytics**: Establishing the correlation between external macroeconomic indicators (like interest rates or housing starts) and internal product revenue.
- **Risk Modeling**: Identifying negatively correlated product lines (where one goes up, the other goes down) to optimize portfolio hedging strategies.

---

## Category

**Statistical / Predictive & Trend Analysis / Essbase Native Functions**

---

## Syntax

```essbase
@CORRELATION(DataList1, DataList2, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DataList1` | Member / Array | ✅ Yes | The first dataset (the independent variable / X). e.g., `"Marketing_Spend"`. |
| `DataList2` | Member / Array | ✅ Yes | The second dataset (the dependent variable / Y). e.g., `"Sales_Volume"`. |
| `XrangeList` | Member Range | ❌ No  | The range of periods to evaluate. <br>If omitted, Essbase defaults to evaluating across the `Time` dimension members in the current `FIX`. |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the Pearson correlation coefficient ($r$), a floating-point number between `-1.0` and `1.0`.
- **`1.0`**: Perfect Positive Correlation (As X goes up, Y goes up identically).
- **`-1.0`**: Perfect Negative Correlation (As X goes up, Y goes down identically).
- **`0.0`**: No Correlation (The variables are completely independent).
- **Missing Data Handling**: If either list contains `#MISSING` for a specific period, Essbase ignores that period entirely for BOTH lists (pairwise deletion). If there is insufficient data to calculate variance (e.g., less than 2 periods), it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Array Pairing**: Essbase extracts the two data arrays over the specified `XrangeList`.
2. **Mean Calculation**: It calculates the mathematical average (mean) of DataList1 ($\bar{x}$) and DataList2 ($\bar{y}$).
3. **Covariance & Variance**: It executes the standard Pearson formula:
   $$ r = \frac{\sum (x_i - \bar{x})(y_i - \bar{y})}{\sqrt{\sum (x_i - \bar{x})^2 \sum (y_i - \bar{y})^2}} $$
4. **Return**: It returns the singular calculated scalar value. Because it evaluates a range of time to produce one number, it usually writes that same number into every period in the target block.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Correlation Across Time

```essbase
/* 
   Calculates the correlation between Marketing and Sales across 
   all Time periods in the FIX.
*/
"Marketing_ROI_Score" = @CORRELATION("Marketing_Spend", "Sales_Volume");
```

---

## Practical Examples

### Example 1: Validating Forecasting Drivers

**Scenario**: A company relies on "Website Traffic" to forecast "Online Conversions". Before finalizing the forecast model, the FP&A director wants the system to statistically prove that Website Traffic is actually a good predictor of Conversions based on the last 12 months of Actuals. If the correlation is less than `0.70`, the system should flag it as a "Weak Driver".

```essbase
FIX("Actual", "FY24", "Working", @LEVEL0("Products"))
    
    /* 
       1. We calculate the correlation across the 12 months of the year.
       Because Correlation evaluates the whole year to create one score, 
       we write the score into the "YearTotal" member.
    */
    FIX("YearTotal")
        
        "Traffic_Correlation" = @CORRELATION("Website_Traffic", "Online_Conversions", @CHILDREN("YearTotal"));
        
        /* 
           2. Evaluate the statistical strength.
           (Checking if it is >= 0.70)
        */
        IF("Traffic_Correlation" >= 0.70)
            "Driver_Strength_Flag" = 1; /* Strong Predictor */
        ELSEIF("Traffic_Correlation" != #MISSING)
            "Driver_Strength_Flag" = 0; /* Weak Predictor */
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misinterpreting `#MISSING` | Correlation returns `#MISSING` unexpectedly | Pearson correlation mathematically requires variance (movement) to calculate. If `Marketing_Spend` was exactly `$10,000` every single month (it never changed), the variance is 0. Dividing by a variance of 0 creates a divide-by-zero error, and Essbase will safely return `#MISSING` instead of crashing. Ensure your datasets actually have fluctuation |
| Not Understanding the Output Block | Writing to Monthly accounts | Correlation evaluates a set of numbers (e.g., 12 months) and produces ONE statistical result. If you do not isolate your target (like fixing on `"YearTotal"`), Essbase will write the exact same correlation score (`0.85`) into Jan, Feb, Mar, etc. It is usually best practice to store correlation scores in a specific summary time period |
| Directionality (X vs Y) | Does order matter? | Mathematically, Pearson correlation is symmetric. `@CORRELATION(X, Y)` returns the exact same number as `@CORRELATION(Y, X)`. The order of the first two parameters does not matter for this specific function |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@TREND`](./@TREND.md) | While correlation tells you *if* they are related, `@TREND` uses linear regression to actually predict the *future values* based on that relationship |
| `@COVAR` | Calculates the unstandardized Covariance between two variables. (Correlation is simply Covariance divided by the product of their standard deviations) |
| `@RSQ` | Calculates the R-Squared value (the coefficient of determination), which is literally just the Correlation (`r`) squared. It tells you what percentage of the variance in Y is explained by X |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — CORRELATION](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/correlation.html)
