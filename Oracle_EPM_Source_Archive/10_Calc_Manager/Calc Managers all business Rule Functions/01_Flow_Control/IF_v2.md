# IF

## Overview

`IF` is the **conditional logic command** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It evaluates a Boolean condition for each cell in the calculation scope and executes different code paths based on whether the condition is TRUE or FALSE. Along with `FIX`, `IF` is one of the two most frequently used commands in every business rule.

### Why Does This Command Exist—

Business logic is rarely uniform. Different accounts, entities, periods, or data conditions require different calculations:
- Revenue accounts might grow at one rate, expense accounts at another
- Entities in different regions might use different tax rates
- Zero or missing values need special handling to avoid divide-by-zero errors
- Certain members may need to be skipped entirely

`IF` enables all of this by providing cell-level conditional execution.

### When to Use It

- When different members need different formulas (e.g., revenue vs. expense accounts)
- When you need to check for `#MISSING` or zero before a division
- When you need to apply UDA-based or attribute-based logic
- When you need to set flags or status values based on data thresholds
- When combining with `@ISMBR` to apply member-specific formulas
- When you need to handle edge cases in complex calculations

---

## Category

**Calc Script Command / Flow Control / Conditional**

---

## Syntax

```essbase
IF(condition)
    /* statements when TRUE */
ENDIF
```

```essbase
IF(condition)
    /* statements when TRUE */
ELSE
    /* statements when FALSE */
ENDIF
```

```essbase
IF(condition)
    /* statements when condition1 is TRUE */
ELSEIF(condition2)
    /* statements when condition2 is TRUE */
ELSE
    /* statements when all conditions are FALSE */
ENDIF
```

### Formal Syntax

```
IF(booleanExpression)
    calcStatements
[ELSEIF(booleanExpression)
    calcStatements]...
[ELSE
    calcStatements]
ENDIF
```

Where:
- `booleanExpression` — Any expression that evaluates to TRUE or FALSE. Can use comparison operators (`>`, `<`, `>=`, `<=`, `==`, `!=`), logical operators (`AND`, `OR`, `NOT`), member functions (`@ISMBR`, `@UDA`, `@ISDESC`), or numeric comparisons.
- `calcStatements` — Any valid calculation statements.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `condition` | Boolean expression | ✅ Yes | Any expression evaluating to TRUE or FALSE. Can include comparison operators, Boolean functions like `@ISMBR`, `@UDA`, `@ISDESC`, or compound conditions with `AND`/`OR`/`NOT`. Numeric values are treated as: 0 = FALSE, non-zero = TRUE. `#MISSING` evaluates to FALSE. |

---

## Return Value

`IF` does not return a value — it controls **which code path executes** based on the condition.

---

## How It Works (Behind the Scenes)

1. **Cell-Level Evaluation**: Unlike `FIX` which operates at the block level, `IF` evaluates its condition **for every individual cell** in the current calculation scope. This makes it more flexible but potentially slower than FIX for member-based filtering.

2. **Evaluation Order**: The condition is evaluated first. If TRUE, the IF-block statements execute. If FALSE, the ELSEIF conditions are checked in order. If none match, the ELSE block executes (if present). Only ONE branch ever executes per cell.

3. **Short-Circuit Evaluation**: When using `AND`/`OR`, Essbase may short-circuit — if the first operand of `AND` is FALSE, the second is not evaluated. If the first operand of `OR` is TRUE, the second is not evaluated.

4. **Missing Value Behavior**: `#MISSING` in a condition behaves as FALSE in comparisons. `IF(#MISSING)` is FALSE. `IF(#MISSING > 0)` is FALSE. `IF(#MISSING == #MISSING)` behavior can be tricky — always use explicit `#MISSING` checks.

5. **Performance Impact**: Every `IF` condition is evaluated for every cell in scope. For member-based conditions (like `@ISMBR`), using `FIX` is generally faster because it filters at the block level. Use `IF` for data-dependent conditions that can't be predetermined.

6. **Nesting**: IF blocks can be nested inside other IF blocks, and inside FIX blocks. There is a practical nesting limit — deeply nested IF/ELSEIF chains can be hard to read and debug.

---

## Syntax Variants & Scenarios

### Variant 1: Simple IF/ENDIF

```essbase
IF(Revenue > 0)
    "Margin_Pct" = "Gross_Margin" / Revenue * 100;
ENDIF
```
Only calculates margin when Revenue is positive to avoid divide-by-zero.

### Variant 2: IF/ELSE/ENDIF

```essbase
IF(Revenue > 0)
    "Margin_Pct" = "Gross_Margin" / Revenue * 100;
ELSE
    "Margin_Pct" = 0;
ENDIF
```
Sets margin to 0 when Revenue is zero or missing.

### Variant 3: IF/ELSEIF/ELSE/ENDIF

```essbase
IF(@ISMBR("Revenue"))
    "Variance" = "Actual" - "Budget";
ELSEIF(@ISMBR("Expense"))
    "Variance" = "Budget" - "Actual";  /* Reversed for expenses */
ELSE
    "Variance" = "Actual" - "Budget";
ENDIF
```
Different variance calculation based on account type.

### Variant 4: Compound Conditions with AND/OR

```essbase
IF(Revenue > 0 AND Units > 0)
    "Average_Price" = Revenue / Units;
ELSE
    "Average_Price" = #MISSING;
ENDIF
```

### Variant 5: Using Boolean Functions

```essbase
IF(@UDA("Entity", "Intercompany"))
    "IC_Elimination" = Revenue * -1;
ENDIF
```
Uses UDA to identify intercompany entities.

### Variant 6: Nested IF Inside FIX

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@ISMBR(@DESCENDANTS("Revenue_Accounts")))
        IF("Actual" > "Budget")
            "Variance_Flag" = 1;  /* Favorable */
        ELSE
            "Variance_Flag" = -1;  /* Unfavorable */
        ENDIF
    ENDIF
ENDFIX
```

---

## Practical Examples

### Example 1: Safe Division Pattern

**Scenario**: Calculate variance percentage, handling zero and missing budget values.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF("Budget" != 0 AND "Budget" != #MISSING)
        "Variance_Pct" = ("Actual" - "Budget") / @ABS("Budget") * 100;
    ELSE
        "Variance_Pct" = #MISSING;
    ENDIF
ENDFIX
```

**What Happens**:
- For each cell, checks if Budget is non-zero and non-missing
- If safe, calculates percentage using @ABS to handle negative budgets
- If Budget is 0 or #MISSING, sets result to #MISSING to avoid errors

---

### Example 2: Account-Type-Aware Variance

**Scenario**: Revenue variances are favorable when Actual > Budget, but expense variances are favorable when Actual < Budget.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@ISMBR(@DESCENDANTS("Total Revenue")))
        "Variance" = "Actual" - "Budget";
    ELSEIF(@ISMBR(@DESCENDANTS("Total Expenses")))
        "Variance" = "Budget" - "Actual";
    ELSE
        "Variance" = "Actual" - "Budget";
    ENDIF
ENDFIX
```

---

### Example 3: Tiered Commission Calculation

**Scenario**: Sales commission rates vary by achievement level.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Sales Team"))
    IF("Achievement_Pct" >= 1.20)
        "Commission" = "Revenue" * 0.15;    /* 15% for 120%+ */
    ELSEIF("Achievement_Pct" >= 1.00)
        "Commission" = "Revenue" * 0.10;    /* 10% for 100-119% */
    ELSEIF("Achievement_Pct" >= 0.80)
        "Commission" = "Revenue" * 0.05;    /* 5% for 80-99% */
    ELSE
        "Commission" = 0;                    /* 0% below 80% */
    ENDIF
ENDFIX
```

---

### Example 4: Data Validation Flag

**Scenario**: Set a validation flag for data quality checks.

```essbase
FIX("FY25", "Working")
    IF(Revenue != #MISSING AND Revenue != 0)
        IF(COGS != #MISSING AND COGS != 0)
            IF(@ABS("Gross_Margin" / Revenue) > 0.90)
                "Validation_Flag" = 3;  /* Suspicious margin > 90% */
            ELSEIF(@ABS("Gross_Margin" / Revenue) < 0.01)
                "Validation_Flag" = 2;  /* Suspicious margin < 1% */
            ELSE
                "Validation_Flag" = 1;  /* OK */
            ENDIF
        ELSE
            "Validation_Flag" = 0;  /* Missing COGS */
        ENDIF
    ELSE
        "Validation_Flag" = 0;  /* Missing Revenue */
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing ENDIF | Every IF must have a matching ENDIF | Always write IF/ENDIF as a pair first |
| Using `=` instead of `==` for comparison | `=` is assignment, `==` is comparison | Use `==` for equality checks: `IF(x == 5)` |
| Using IF when FIX is better for members | `IF(@ISMBR("Jan"))` is slower than `FIX("Jan")` for member-based filtering | Use FIX for member scope, IF for data-dependent conditions |
| Not handling #MISSING | `IF(value > 0)` is FALSE when value is #MISSING, which may not be your intent | Explicitly check: `IF(value != #MISSING AND value > 0)` |
| Complex nested IFs becoming unreadable | Deep nesting makes debugging very difficult | Refactor into separate FIX blocks or use ELSEIF chains |
| Comparing strings incorrectly | `IF("member" == "value")` doesn't work for string comparison in Essbase | Use `@ISMBR`, `@UDA`, or member functions for member-based logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`ELSE`](./ELSE.md) | Alternative branch when IF condition is FALSE |
| [`ELSEIF`](./ELSEIF.md) | Additional conditional branch |
| [`ENDIF`](./ENDIF.md) | Required closing pair for IF |
| [`FIX`](./FIX.md) | Block-level scope — often used together with IF |
| [`@ISMBR`](../09_Boolean_Conditional/@ISMBR.md) | Tests current member — most common IF condition |
| [`@UDA`](../09_Boolean_Conditional/@UDA.md) | Tests User-Defined Attribute — common IF condition |
| [`@ISDESC`](../09_Boolean_Conditional/@ISDESC.md) | Tests if member is descendant — used in IF |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — IF](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/if.html)
- [Oracle Essbase Technical Reference — IF/ELSEIF/ELSE/ENDIF](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/conditional_blocks.html)
