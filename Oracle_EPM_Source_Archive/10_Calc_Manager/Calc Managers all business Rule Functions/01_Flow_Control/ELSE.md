# ELSE

## Overview

`ELSE` provides the **alternative execution path** in an `IF` block in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. When the IF condition (and any ELSEIF conditions) evaluate to FALSE, the statements inside the ELSE block execute. It's the "otherwise, do this" branch of conditional logic.

### Why Does This Command Exist—

Many calculations need to handle both the "true" and "false" cases:
- If Revenue > 0, calculate margin; **otherwise**, set margin to zero
- If a member is a leaf, apply the formula; **otherwise**, skip or apply a different formula
- If Budget exists, calculate variance; **otherwise**, set variance to #MISSING

Without ELSE, you'd need a separate IF with the negated condition, which is less readable and potentially processes cells twice.

### When to Use It

- When you need a default action when the IF condition is FALSE
- When setting a value regardless of the condition (one value if TRUE, another if FALSE)
- When handling #MISSING or zero as a special case
- When you need mutually exclusive code paths

---

## Category

**Calc Script Command / Flow Control / Conditional**

---

## Syntax

```essbase
IF(condition)
    /* executed when condition is TRUE */
ELSE
    /* executed when condition is FALSE */
ENDIF
```

### Formal Syntax

```
IF(booleanExpression)
    calcStatements
[ELSEIF(booleanExpression)
    calcStatements]...
ELSE
    calcStatements
ENDIF
```

Where:
- `ELSE` takes no parameters
- `ELSE` must appear after all `ELSEIF` branches (if any) and before `ENDIF`
- Only ONE `ELSE` is allowed per `IF` block
- The ELSE block executes only when ALL preceding conditions (IF and all ELSEIFs) are FALSE

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| *(none)* | — | — | `ELSE` takes no parameters. It simply marks the beginning of the alternative code path. |

---

## Return Value

`ELSE` does not return a value — it is a **structural command** that begins the alternative execution path.

---

## How It Works (Behind the Scenes)

1. **Exclusive Execution**: For each cell, EITHER the IF/ELSEIF block OR the ELSE block executes — never both. This is guaranteed by the Essbase evaluation engine.

2. **Evaluation Flow**: Essbase evaluates conditions top-to-bottom: IF condition → ELSEIF conditions (in order) → ELSE. The first TRUE condition wins. If none are TRUE, ELSE executes.

3. **Missing Values in ELSE**: When the IF condition involves a #MISSING value (e.g., `IF(Revenue > 0)` where Revenue is #MISSING), the condition is FALSE, so the ELSE block executes. This is a common source of bugs — developers forget that #MISSING falls through to ELSE.

4. **Optional**: ELSE is not required. IF/ENDIF without ELSE is valid — if the condition is FALSE, nothing happens for that cell.

5. **No Condition**: Unlike ELSEIF, ELSE does not take a condition. It's the catch-all fallback.

---

## Syntax Variants & Scenarios

### Variant 1: Simple IF/ELSE

```essbase
IF(Revenue > 0)
    "Margin" = "Gross Profit" / Revenue * 100;
ELSE
    "Margin" = 0;
ENDIF
```

### Variant 2: ELSE as Missing Value Handler

```essbase
IF("Budget" != #MISSING AND "Budget" != 0)
    "Var_Pct" = ("Actual" - "Budget") / @ABS("Budget") * 100;
ELSE
    "Var_Pct" = #MISSING;
ENDIF
```

### Variant 3: ELSE After ELSEIF Chain

```essbase
IF("Achievement" >= 1.20)
    "Bonus_Rate" = 0.20;
ELSEIF("Achievement" >= 1.00)
    "Bonus_Rate" = 0.10;
ELSEIF("Achievement" >= 0.80)
    "Bonus_Rate" = 0.05;
ELSE
    "Bonus_Rate" = 0;  /* Below 80% achievement */
ENDIF
```

### Variant 4: ELSE in Nested IF

```essbase
IF(@ISMBR(@DESCENDANTS("Revenue Accounts")))
    IF("Actual" > "Budget")
        "Status" = 1;  /* Favorable */
    ELSE
        "Status" = -1;  /* Unfavorable */
    ENDIF
ELSE
    IF("Actual" < "Budget")
        "Status" = 1;  /* Favorable for expenses */
    ELSE
        "Status" = -1;
    ENDIF
ENDIF
```

---

## Practical Examples

### Example 1: Percentage Calculation with Safe Denominator

**Scenario**: Calculate a ratio, defaulting to zero when the denominator is invalid.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@ABS("Total Revenue") > 0)
        "Revenue Mix" = Revenue / "Total Revenue" * 100;
    ELSE
        "Revenue Mix" = 0;
    ENDIF
ENDFIX
```

**What Happens**:
- If Total Revenue has a valid non-zero value, calculates the mix percentage
- If Total Revenue is 0 or #MISSING, sets Revenue Mix to 0 instead of causing an error

---

### Example 2: Sign Convention for Expense Accounts

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@ISMBR(@DESCENDANTS("Revenue")))
        "Variance" = "Actual" - "Budget";  /* Positive = favorable */
    ELSE
        "Variance" = "Budget" - "Actual";  /* Positive = favorable for expenses */
    ENDIF
ENDFIX
```

---

### Example 3: Default Values for Missing Data

```essbase
FIX("FY25", "Forecast")
    IF("Historical_Rate" != #MISSING)
        "Projected_Rate" = "Historical_Rate" * 1.03;
    ELSE
        "Projected_Rate" = 0.05;  /* Default 5% if no history */
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Multiple ELSE blocks | Only ONE ELSE is allowed per IF — second ELSE causes error | Use ELSEIF for additional conditions |
| ELSE with a condition | `ELSE(condition)` is invalid — ELSE takes no parameters | Use `ELSEIF(condition)` for additional conditions |
| ELSE after ENDIF | ELSE must come BEFORE ENDIF | Check your block structure |
| Forgetting #MISSING falls to ELSE | `IF(x > 0)` is FALSE for #MISSING, executing the ELSE branch | Handle #MISSING explicitly if needed |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`IF`](./IF.md) | The opening conditional — ELSE provides its alternative path |
| [`ELSEIF`](./ELSEIF.md) | Additional conditional branches before ELSE |
| [`ENDIF`](./ENDIF.md) | Closes the entire IF/ELSE block |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ELSE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/else.html)
