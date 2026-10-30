# @BETWEEN

## Overview

`@BETWEEN` is a **logical condition function** (often used with validation or custom formulas) that determines if a specific value falls within a defined lower and upper boundary.

*(Note: While commonly referenced in Business Rules graphical UI validation, pure Essbase Calc Script logic typically handles this natively via `AND` logic: `IF(Value >= X AND Value <= Y)`. However, modern Calc Manager provides `@BETWEEN` as an explicit macro/function to streamline code readability and GUI-based rule building.)*

### Why Does This Function Exist?

When building data validation rules, tiered pricing models, or threshold-based logic, you frequently need to check if a number sits inside a specific bracket.
Instead of writing verbose compound statements:
`IF("Revenue" >= 10000 AND "Revenue" <= 50000)`

`@BETWEEN` offers a cleaner, more readable syntax:
`IF(@BETWEEN("Revenue", 10000, 50000))`

### When to Use It

- When creating tiered logic (e.g., Tier 1: 0-100, Tier 2: 101-500, Tier 3: 501+).
- Inside data validation rules to flag inputs that fall outside acceptable historical ranges.
- To simplify complex `IF/ELSEIF` blocks.

---

## Category

**Logical / Boolean / Mathematical Comparison**

---

## Syntax

```essbase
@BETWEEN(testValue, lowerBound, upperBound)
```

### Formal Syntax

```
@BETWEEN(expressionToTest, minimumValue, maximumValue)
```

Where:
- `expressionToTest` — The variable, account, or measure you are evaluating (e.g., `"Margin_Pct"`).
- `minimumValue` — The floor of the acceptable range.
- `maximumValue` — The ceiling of the acceptable range.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `testValue` | Numeric | ✅ Yes | The value being checked. |
| `lowerBound`| Numeric | ✅ Yes | The lowest acceptable value (inclusive). |
| `upperBound`| Numeric | ✅ Yes | The highest acceptable value (inclusive). |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| `testValue` >= `lowerBound` AND `testValue` <= `upperBound` | `TRUE` (1) |
| `testValue` falls outside the bounds | `FALSE` (0) |

*(Note: The bounds are **inclusive**).*

---

## How It Works (Behind the Scenes)

1. **Evaluation**: Essbase calculates the numeric result of `testValue`.
2. **Double Comparison**: It internally executes a standard `>=` check against the lower bound and a `<=` check against the upper bound.
3. **Resolution**: If both checks pass, it returns `TRUE`.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Bracket Check

```essbase
IF(@BETWEEN("Gross_Margin", 0.40, 0.60))
    /* Margin is healthy */
ENDIF
```

---

## Practical Examples

### Example 1: Tiered Commission Rates

**Scenario**: Sales Reps earn commissions based on the total volume they sell. Different brackets yield different commission percentages.

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    /* Using @BETWEEN for clean, readable tiering */
    IF(@BETWEEN("Total_Sales", 0, 100000))
        "Commission_Rate" = 0.05;
        
    ELSEIF(@BETWEEN("Total_Sales", 100000.01, 500000))
        "Commission_Rate" = 0.08;
        
    ELSEIF("Total_Sales" > 500000)
        "Commission_Rate" = 0.12;
    ENDIF
    
    /* Calculate final commission */
    "Commission_Payout" = "Total_Sales" * "Commission_Rate";
    
ENDFIX
```

---

### Example 2: Data Quality Validation (Tolerance Check)

**Scenario**: You want to flag any manual forecast inputs that deviate more than 10% from the historical actuals. (i.e., The input must be *between* 90% and 110% of Actuals).

```essbase
FIX("FY25", "Forecast", @LEVEL0("Entity"))
    
    /* Calculate the acceptable boundaries based on FY24 Actuals */
    VAR vLowerLimit = "Revenue" -> "Actual" -> "FY24" * 0.90;
    VAR vUpperLimit = "Revenue" -> "Actual" -> "FY24" * 1.10;
    
    /* Check if the user's forecast is within bounds */
    IF(NOT @BETWEEN("Revenue", vLowerLimit, vUpperLimit))
        /* Input is out of bounds, set a warning flag for reporting */
        "Validation_Warning_Flag" = 1;
    ELSE
        "Validation_Warning_Flag" = 0;
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Assuming Exclusive Bounds | `@BETWEEN(10, 10, 20)` evaluates to `TRUE` because bounds are inclusive (`>=` and `<=`) | If you need strict exclusivity (`>` and `<`), you must write the `AND` statement manually |
| Reversed Bounds | `@BETWEEN("Value", 50, 10)` will always return `FALSE` because 10 is not greater than 50 | Always place the lowest number as the second argument, and the highest number as the third |
| Engine Support | While supported in Calc Manager UI and Groovy, older legacy Essbase BSO engines may occasionally balk at `@BETWEEN` if parsed strictly | If syntax errors occur in pure `.csc` scripts on legacy on-prem versions, revert to `IF(X >= Y AND X <= Z)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| Native `AND` | The underlying logical operator that `@BETWEEN` abstracts (`X >= Y AND X <= Z`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @BETWEEN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/between.html)
