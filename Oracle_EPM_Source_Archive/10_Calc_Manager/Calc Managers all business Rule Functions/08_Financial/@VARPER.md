# @VARPER

## Overview

`@VARPER` is a **financial and reporting function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It calculates the **Variance Percentage** between two members (typically Actual and Budget), automatically honoring the `Expense` vs `Revenue` reporting attributes of the Account dimension to ensure the percentage is directionally correct.

*Note: `@VARPER` is functionally identical to [`@VARIANCEP`](./@VARIANCEP.md). Both exist as aliases for the same underlying engine operation. Many developers prefer `@VARPER` simply because it is shorter to type.*

### Why Does This Function Exist?

Calculating variance percentages manually is fraught with errors because you must handle account types (Revenue vs. Expense) and division-by-zero scenarios:
- **Revenue**: (Actual 120 - Budget 100) / Budget 100 = +20% (Favorable)
- **Expense**: Standard math: (Actual 120 - Budget 100) / Budget 100 = +20% (Mathematically positive, but financially unfavorable). It *should* be -20%.
- **Zero Budget**: If Budget is 0, dividing by Budget throws a divide-by-zero error or `#MISSING`.

`@VARPER` handles all three of these problems automatically.

### When to Use It

- When creating dynamic Variance % reporting scenarios.
- In reporting cubes to provide a universal "% Var" metric for all P&L accounts.
- To avoid writing complex `IF` statements checking for division by zero and account types.

---

## Category

**Financial / Variance**

---

## Syntax

```essbase
@VARPER(mbrName1, mbrName2)
```

### Formal Syntax

```
@VARPER(member1_Actual_or_Current, member2_Budget_or_Target)
```

Where:
- `member1` — The actual, forecast, or current value being evaluated.
- `member2` — The budget, plan, or target value to compare against (used as the denominator).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName1` | Member | ✅ Yes | The first member (e.g., `"Actual"` or `"FY25"`). |
| `mbrName2` | Member | ✅ Yes | The second member (e.g., `"Budget"` or `"FY24"`). This is the base/denominator of the percentage calculation. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the financial variance as a percentage (a decimal value, e.g., `0.20` for 20%). 
- For Non-Expense accounts: `(mbrName1 - mbrName2) / ABS(mbrName2)`
- For Expense accounts: `(mbrName2 - mbrName1) / ABS(mbrName2)`
- If `mbrName2` is 0 or `#MISSING`, it returns `#MISSING` (or a configured error value depending on application settings).

---

## How It Works (Behind the Scenes)

1. **Account Type Logic**: Just like `@VARIANCE`, it reads the Account Type property. It flips the subtraction order for Expense accounts so that an overspend results in a negative percentage.
2. **Absolute Denominator**: It divides by the *absolute value* of `mbrName2`. This ensures that if the budget was a negative number (e.g., an expected loss), a better-than-expected result remains mathematically positive.
3. **Zero Handling**: It inherently protects against division-by-zero errors.

---

## Syntax Variants & Scenarios

### Variant 1: Actual vs Budget %

```essbase
"Var_Pct" = @VARPER("Actual", "Budget");
```

### Variant 2: Year-Over-Year Growth %

```essbase
"YoY_Growth_Pct" = @VARPER("FY25", "FY24");
```

### Variant 3: Converted to Whole Numbers

```essbase
/* To display as 20.5 instead of 0.205 in some reporting tools */
"Var_Pct_Formatted" = @VARPER("Actual", "Budget") * 100;
```

---

## Practical Examples

### Example 1: Global Variance % Calculation

**Scenario**: Calculate a universal "Variance %" scenario that works correctly for both Sales and OPEX, and doesn't break if the budget is zero.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"), @DESCENDANTS("Net_Income"))
    /* 
       For Sales: (Actual(120) - Budget(100)) / 100 = 0.20 (+20% Favorable)
       For OPEX: (Budget(100) - Actual(120)) / 100 = -0.20 (-20% Unfavorable)
       If Budget is 0: Returns #MISSING safely.
    */
    "Variance_Pct" = @VARPER("Actual", "Budget");
ENDFIX
```

---

### Example 2: Dynamic Variance Reporting with Thresholds

**Scenario**: Calculate the variance percentage, and flag any accounts that are more than 10% unfavorable for management review.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Variance_Pct" = @VARPER("Actual", "Budget");
    
    /* Because VARPER handles the signs, Unfavorable is ALWAYS negative */
    IF("Variance_Pct" < -0.10)
        "Requires_Review_Flag" = 1;
    ELSE
        "Requires_Review_Flag" = 0;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Reversing the arguments | `@VARPER("Budget", "Actual")` divides by Actual instead of Budget, and flips the favorable/unfavorable logic | Always pass `(Actual, Target)` |
| Confusing with `@VARIANCEP` | `@VARPER` and `@VARIANCEP` are essentially identical aliases in Essbase | You can use either, but consistency is key |
| Expecting statistical variance % | This is a financial reporting function, not a statistical variance function | N/A |
| Applying to Balance Sheet | Variance % on closing balances can be misleading | Usually reserved for Flow/P&L accounts |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@VARIANCE`](./@VARIANCE.md) | Calculates the raw dollar variance, honoring account types |
| [`@VARIANCEP`](./@VARIANCEP.md) | An identical alias for `@VARPER` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @VARPER](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/varper.html)
