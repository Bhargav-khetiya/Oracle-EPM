# @VARIANCE

## Overview

`@VARIANCE` is a **financial and statistical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. 
**CRITICAL NOTE**: In Essbase and Calc Manager, `@VARIANCE` is typically a **financial function** used to calculate the difference between two members (e.g., Actual vs. Budget), honoring the `Expense` reporting attribute. 
*Do not confuse this with the statistical variance of a sample, which is calculated using the `@VAR` function.*

### Why Does This Function Exist?

Standard subtraction (`Actual - Budget`) works fine for Revenue accounts, but fails for Expense accounts where a lower actual is a *positive* variance (favorable). 
- **Revenue**: Actual (120) - Budget (100) = +20 (Favorable)
- **Expense**: Actual (120) - Budget (100) = +20 (Unfavorable). Standard math makes this positive, but financially it should be negative or flagged as unfavorable.

`@VARIANCE` automatically reads the Account dimension's **UDA/Account Type** (Revenue vs. Expense) and adjusts the math accordingly, ensuring variances are always directionally correct for financial reporting.

### When to Use It

- When calculating Variance (Actual vs. Budget, Forecast vs. Actual).
- In Variance reporting cubes where you need a single dynamic calculation for both Income and Expense accounts.
- To ensure "Favorable" is always positive and "Unfavorable" is always negative.

---

## Category

**Financial / Variance**

---

## Syntax

```essbase
@VARIANCE(mbrName1, mbrName2)
```

### Formal Syntax

```
@VARIANCE(member1_Actual_or_Current, member2_Budget_or_Target)
```

Where:
- `member1` — The actual or current value being evaluated.
- `member2` — The budget, plan, or target value to compare against.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName1` | Member | ✅ Yes | The first member (usually Actual, Forecast, or Current Year). |
| `mbrName2` | Member | ✅ Yes | The second member (usually Budget, Plan, or Prior Year). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the financial variance. 
- For Non-Expense accounts: `member1 - member2`
- For Expense accounts: `member2 - member1`

---

## How It Works (Behind the Scenes)

1. **Account Type Check**: When `@VARIANCE` executes, it checks the underlying Account Type property of the current Account member in the block.
2. **Dynamic Math**: 
   - If the account is tagged as an **Expense** type, the formula executed is `mbrName2 - mbrName1` (Target - Actual).
   - If the account is **Revenue, Asset, Liability, or Equity**, the formula is `mbrName1 - mbrName2` (Actual - Target).
3. **Hierarchy**: This works seamlessly across an entire P&L hierarchy, automatically flipping signs without complex `IF` statements.

---

## Syntax Variants & Scenarios

### Variant 1: Actual vs Budget

```essbase
"Var_Act_vs_Bud" = @VARIANCE("Actual", "Budget");
```

### Variant 2: Current vs Prior Year

```essbase
"Var_YoY" = @VARIANCE("FY25", "FY24");
```

### Variant 3: Forecast vs Target

```essbase
"Var_Fcst_vs_Target" = @VARIANCE("Forecast", "Target");
```

---

## Practical Examples

### Example 1: Global Variance Calculation

**Scenario**: Calculate a universal "Variance" scenario that works correctly for both Sales and OPEX.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"), @DESCENDANTS("Net_Income"))
    /* 
       For Sales: Actual(120) - Budget(100) = +20 (Favorable)
       For OPEX: Budget(100) - Actual(120) = -20 (Unfavorable)
    */
    "Variance" = @VARIANCE("Actual", "Budget");
ENDFIX
```

---

### Example 2: Variance Percentage Calculation

**Scenario**: Calculate the Variance Percentage safely, honoring account types.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Variance" = @VARIANCE("Actual", "Budget");
    
    /* Using @VARPER is better, but here is the manual implementation for understanding */
    IF(@ABS("Budget") > 0)
        "Var_Pct" = "Variance" / @ABS("Budget") * 100;
    ELSE
        "Var_Pct" = #MISSING;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with Statistical Variance | `@VARIANCE` is a financial subtraction function. It does not calculate the statistical variance of a dataset | Use `@VAR` for sample statistical variance, or `@VARP` for population statistical variance |
| Reversing the arguments | `@VARIANCE("Budget", "Actual")` will flip the financial meaning, making favorable unfavorable | Always pass `(Actual, Target)` |
| Missing Account Types | If the Account dimension is not properly tagged with Revenue/Expense types, the function defaults to standard subtraction | Ensure metadata properties (Account Type) are correctly configured in the outline |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@VARPER`](../08_Financial/@VARPER.md) | Variance Percentage (calculates the % difference honoring expense types) |
| [`@VAR`](./@VAR.md) | The actual STATISTICAL function for sample variance |
| [`@VARP`](../08_Financial/@VARIANCEP.md) | The actual STATISTICAL function for population variance |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @VARIANCE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/variance.html)
