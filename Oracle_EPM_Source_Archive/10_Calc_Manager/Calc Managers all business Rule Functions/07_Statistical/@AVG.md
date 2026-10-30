# @AVG

## Overview

`@AVG` is a **statistical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It calculates the mathematical average (mean) of a specified set of members or values.

### Why Does This Function Exist?

Averaging is one of the most fundamental operations in financial modeling:
- Calculating Average Selling Price (ASP) across a range of products.
- Finding the average headcount across 12 months.
- Determining average inventory balances to calculate inventory turnover.

Essbase automatically aggregates data based on the outline (using `+`, `-`, etc.), but it does not natively average parent members unless explicitly told to do so via a two-pass calculation or formula. `@AVG` allows you to compute these means dynamically within a calc script.

### When to Use It

- When calculating year-to-date (YTD) or full-year averages across time periods.
- When creating custom sub-totals that represent a mean rather than a sum.
- When you need to specify how to handle `#MISSING` data (whether to include it in the denominator or ignore it).

---

## Category

**Statistical / Mathematical / Aggregation**

---

## Syntax

```essbase
@AVG(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, mbrList)
```

### Formal Syntax

```
@AVG(skipParameter, memberListExpression)
```

Where:
- `skipParameter` — A required keyword telling Essbase how to handle empty or zero data when calculating the denominator.
- `memberListExpression` — The list of members (usually Time periods, Entities, or Products) to average across.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `skipParameter`| Keyword| ✅ Yes | Must be one of: <br> `SKIPNONE` (include all members in denominator). <br> `SKIPMISSING` (exclude #MISSING from denominator). <br> `SKIPZERO` (exclude 0s from denominator). <br> `SKIPBOTH` (exclude both 0 and #MISSING). |
| `mbrList` | Member list| ✅ Yes | The members to average. Can be a comma-separated list `("Jan", "Feb", "Mar")` or a range function like `@CHILDREN("Q1")`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the mathematical mean (Sum of values / Count of valid values).
If all members in the list are skipped (e.g., using `SKIPMISSING` on a list of empty members), it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Summation**: Essbase loops through the `mbrList` and adds up the values of the current measure across those members.
2. **Counting**: It counts the number of members in the list, applying the `skipParameter`.
   - E.g., if the list is `Jan=10, Feb=#MISSING, Mar=20` and you use `SKIPMISSING`, the count is 2. If you use `SKIPNONE`, the count is 3.
3. **Division**: It divides the Sum by the Count and returns the result.

---

## Syntax Variants & Scenarios

### Variant 1: Skipping Missing Data (Most Common)

```essbase
"Avg_Sales" = @AVG(SKIPMISSING, @CHILDREN("YearTotal"));
/* If only 10 months have data, divides by 10 */
```

### Variant 2: Strict Division (Including Everything)

```essbase
"Avg_Headcount" = @AVG(SKIPNONE, @CHILDREN("YearTotal"));
/* Always divides by 12, even if some months are empty */
```

### Variant 3: Comma-Separated List

```essbase
"Q1_Avg" = @AVG(SKIPMISSING, "Jan", "Feb", "Mar");
```

---

## Practical Examples

### Example 1: Average Headcount for Turnover Metrics

**Scenario**: You need to calculate Employee Turnover (Total Terminations / Average Headcount). Headcount is measured monthly. If a future month is `#MISSING` (not planned yet), it should not drag down the average.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Calculate Average Headcount for the year, ignoring empty future months */
    "Avg_Headcount" = @AVG(SKIPMISSING, @CHILDREN("YearTotal")->"Headcount");
    
    /* Calculate Turnover Rate */
    IF("Avg_Headcount" > 0)
        "Turnover_Rate" = "Terminations" / "Avg_Headcount";
    ENDIF
    
ENDFIX
```
*(Note the syntax: `@CHILDREN("YearTotal")->"Headcount"`. This targets a specific account while iterating over the periods).*

---

### Example 2: Average Selling Price Rollup

**Scenario**: You have calculated ASP at the base level. When you roll up the Product hierarchy, you want the parent ASP to be the mathematical average of the children's ASPs (rather than the sum). 
*(Note: A true weighted ASP is `Parent_Rev / Parent_Units`, but sometimes a simple mathematical average of the children is requested).*

```essbase
FIX("FY25", "Working")
    /* Calculate parents based on children */
    FIX(@IDESCENDANTS("Total Product"))
        
        /* Only apply to parents (Level > 0) */
        IF(NOT @ISLEV("Product", 0))
            "ASP" = @AVG(SKIPBOTH, @CHILDREN(@CURRMBR("Product")));
        ENDIF
        
    ENDFIX
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting the Skip Parameter | `@AVG("Jan", "Feb")` is a syntax error | You must explicitly declare how to handle missing data: `@AVG(SKIPNONE, "Jan", "Feb")` |
| Using for cross-dimensional ranges | `@AVG` requires a list of members from the *same* dimension. It cannot average across multiple dimensions easily | Use `@AVGRANGE` if you need to generate a cross-dimensional list to average |
| Mathematical weighting | `@AVG` is a simple mean. It does not calculate weighted averages | If you need a weighted average (like ASP), calculate it manually: `Parent = Sum(Rev) / Sum(Units)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@AVGRANGE`](./@AVGRANGE.md) | Specifically designed to calculate an average of a single measure across a dynamic range of members from another dimension |
| [`@SUM`](./@SUM.md) | Calculates the numerator of the average |
| [`@COUNT`](./@COUNT.md) | Calculates the denominator of the average |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @AVG](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/avg.html)
