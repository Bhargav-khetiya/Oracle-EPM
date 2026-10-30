# @STDEVRANGE

## Overview

`@STDEVRANGE` is a **statistical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that calculates the **sample standard deviation** of a specific member across a defined range of members from another dimension. 

### Why Does This Function Exist?

While `@STDEV` is flexible, `@STDEVRANGE` enforces a strict two-parameter signature: the measure you want to evaluate, and the range over which you want to evaluate it. It explicitly ties the standard deviation calculation to a cross-dimensional range, such as tracking the volatility of an account over a specific window of time.

### When to Use It

- To analyze the historical volatility of a financial metric over a moving window.
- When calculating standard deviations across specific peer groups (e.g., variation in sales across all stores in a region).
- In statistical driver-based models that need to quantify risk or dispersion.

---

## Category

**Statistical / Dispersion**

---

## Syntax

```essbase
@STDEVRANGE(mbrName, rangeList)
```

### Formal Syntax

```
@STDEVRANGE(valueExpression, memberRange)
```

Where:
- `valueExpression` — The specific value/measure to evaluate (e.g., `"Revenue"`).
- `memberRange` — The list of members over which to calculate the standard deviation.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Numeric/Member | ✅ Yes | The value to evaluate (typically an Account or Measure). |
| `rangeList` | Member list | ✅ Yes | The group of members to evaluate against. E.g., `@CHILDREN("Total Entity")` or `@RANGE("Jan", "Dec")`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the sample standard deviation (N-1 denominator) of the values in the range. 
- If the number of data points is less than 2, it returns `#MISSING`.
- **Note on Skipping**: Unlike `@STDEV`, `@STDEVRANGE` does not inherently accept a `skipOption` in its standard signature in the same way; it evaluates the data present in the range. If skipping `#MISSING` is critical, the modern `@STDEV` with `SKIPBOTH` is often preferred.

---

## How It Works (Behind the Scenes)

1. **Intersection Construction**: `@STDEVRANGE(Revenue, @RANGE("Jan","Dec"))` builds the intersections for Revenue across all 12 months.
2. **Sample Variance Math**: It calculates the mean, finds the sum of squared differences from the mean, and divides by `N - 1`. Finally, it takes the square root.
3. **vs @STDEV**: Functionally, they do the same math. `@STDEVRANGE` is an older, more explicit function that enforces the `(value, range)` signature, but `@STDEV` is generally more robust due to explicit `SKIPBOTH` handling.

---

## Syntax Variants & Scenarios

### Variant 1: Annual Volatility

```essbase
"Rev_Volatility" = @STDEVRANGE("Revenue", @RANGE("Jan", "Dec"));
```

### Variant 2: Trailing 6-Month Volatility

```essbase
"Rolling_6M_Risk" = @STDEVRANGE("Sales", @XRANGE(@PRIOR(@CURRMBR("Period"), 5), @CURRMBR("Period")));
```

---

## Practical Examples

### Example 1: Identifying Highly Variable Accounts

**Scenario**: You want to flag OPEX accounts that fluctuate wildly month-to-month, requiring closer management scrutiny.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    FIX(@DESCENDANTS("OPEX"))
        /* Calculate standard deviation over the year */
        VAR vStDev = @STDEVRANGE(@CURRMBR("Account"), @RANGE("Jan", "Dec"));
        VAR vMean = @AVG(SKIPBOTH, @CURRMBR("Account"), @RANGE("Jan", "Dec"));
        
        IF(vMean > 0)
            /* Coefficient of Variation */
            VAR vCoV = vStDev / vMean;
            
            /* Flag if CoV > 0.4 (40% variation) */
            IF(vCoV > 0.4)
                "Review_Flag" = 1;
            ENDIF
        ENDIF
    ENDFIX
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Values | If months have `#MISSING` data, standard deviation calculations can be skewed wildly if they are treated as zero | Ensure data is continuous, or use `@STDEV` with `SKIPBOTH` instead of `@STDEVRANGE` |
| Population vs Sample | `@STDEVRANGE` uses `N-1`. If you need population variance, it is incorrect | Use `@STDEVP` for population standard deviation |
| Not using `@XRANGE` | `@RANGE("Jan":"Dec")` fails if the data crosses a year boundary | Use `@XRANGE` inside `@STDEVRANGE` for multi-year windows |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@STDEV`](./@STDEV.md) | Standard deviation function (more flexible, supports skip options explicitly) |
| [`@RANGE`](./@RANGE.md) | Generates the member list used by `@STDEVRANGE` |
| [`@XRANGE`](./@XRANGE.md) | Generates cross-dimensional lists for `@STDEVRANGE` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @STDEVRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/stdevrange.html)
