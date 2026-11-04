# @ABS

## Overview

`@ABS` is a **mathematical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **absolute value** of a given numeric expression. The absolute value of a number is its distance from zero on the number line, regardless of direction — meaning it always returns a non-negative result.

### Why Does This Function Exist—

In financial planning and budgeting, you often need to work with magnitudes regardless of sign. For example:
- Comparing the size of variances without caring whether they are favorable or unfavorable
- Calculating percentage differences where the denominator could be negative
- Ensuring positive values for ratio calculations
- Removing sign from expense accounts that use sign-flip conventions

### When to Use It

- When you need to strip the sign from a value and work only with its magnitude
- In variance analysis where you need the absolute difference
- In conditional logic where you compare magnitudes
- In allocation bases where negative values would distort proportions

---

## Category

**Mathematical / Numeric**

---

## Syntax

```essbase
@ABS(expression)
```

### Formal Syntax

```
@ABS(numericExpression)
```

Where:
- `numericExpression` — Any valid numeric expression, member combination, or calculation that resolves to a numeric value.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `expression` | Numeric expression | ✅ Yes | Any valid Essbase numeric expression. Can be a constant, a member, a cross-dimensional reference, another function call, or any arithmetic expression. If the cell value is `#MISSING`, the result is `#MISSING`. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Positive number | Same positive number |
| Negative number | Positive equivalent (sign removed) |
| Zero | Zero (0) |
| `#MISSING` | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Evaluation Order**: `@ABS` evaluates its argument expression first, then applies the absolute value transformation. This means any embedded functions, cross-dimensional references, or arithmetic operations within the expression are fully resolved before `@ABS` acts on the result.

2. **Block-Level Behavior**: `@ABS` operates at the **cell level** — it processes each individual cell in the calculation range independently. It does not aggregate or look across cells.

3. **Sparse vs. Dense**: `@ABS` can be used on both sparse and dense dimensions. Since it's a simple mathematical transformation, there are no special sparse/dense considerations.

4. **Missing Values**: If the input expression evaluates to `#MISSING`, `@ABS` returns `#MISSING` — it does NOT treat `#MISSING` as zero.

5. **Data Type**: Essbase stores all numeric values as double-precision floating-point numbers. `@ABS` works within this precision.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Member Reference

```essbase
@ABS(Sales)
```
Returns the absolute value of the `Sales` member in the current context.

### Variant 2: Cross-Dimensional Reference

```essbase
@ABS("Sales" -> "Jan")
```
Returns the absolute value of `Sales` for `Jan`.

### Variant 3: Arithmetic Expression

```essbase
@ABS(Actual - Budget)
```
Returns the absolute value of the difference between `Actual` and `Budget`.

### Variant 4: Nested Functions

```essbase
@ABS(@SUM(Sales))
```
First sums `Sales` across its children, then takes the absolute value.

### Variant 5: Used Inside a Conditional

```essbase
IF(@ABS(Variance) > 1000)
    Flag = 1;
ENDIF
```
Checks if the magnitude of variance exceeds 1000, regardless of sign.

### Variant 6: Complex Expression

```essbase
@ABS(("Revenue" - "Cost_of_Goods") / "Revenue" * 100)
```
Returns the absolute value of the gross margin percentage.

---

## Practical Examples

### Example 1: Basic Variance Analysis

**Scenario**: Calculate the absolute variance between Actual and Budget for all accounts.

```essbase
FIX("FY24", "Working")
    "Abs_Variance" = @ABS("Actual" - "Budget");
ENDFIX
```

**What Happens**:
- For each cell in the FIX range, it subtracts Budget from Actual
- If Actual = 500, Budget = 600, result = @ABS(-100) = **100**
- If Actual = 700, Budget = 600, result = @ABS(100) = **100**

---

### Example 2: Percentage Variance with Safe Denominator

**Scenario**: Calculate percentage variance, but the base (Budget) could be negative.

```essbase
FIX("FY24", "Working")
    IF(@ABS("Budget") > 0)
        "Pct_Variance" = ("Actual" - "Budget") / @ABS("Budget") * 100;
    ELSE
        "Pct_Variance" = #MISSING;
    ENDIF
ENDFIX
```

**Why @ABS Here—**: If Budget is -1000 and Actual is -800, without @ABS the percentage would be `(-800 - (-1000)) / (-1000) * 100 = -20%`. With @ABS on the denominator, you get the correct `20%`.

---

### Example 3: Allocation Base Cleansing

**Scenario**: You're allocating costs based on headcount, but some departments have negative adjustments.

```essbase
FIX("FY24", "Jan", "Final")
    "Allocation_Base"(
        IF(@ABS("Headcount") > 0)
            "Allocated_Cost" = "Total_Cost" * @ABS("Headcount") / @SUM(@ABS("Headcount"), @CHILDREN("All_Departments"));
        ENDIF
    )
ENDFIX
```

---

### Example 4: Using @ABS with @ROUND

**Scenario**: Round the absolute variance to 2 decimal places.

```essbase
"Rounded_Abs_Variance" = @ROUND(@ABS("Actual" - "Budget"), 2);
```

---

### Example 5: Materiality Threshold Check

**Scenario**: Flag accounts where the absolute variance exceeds 5% of budget.

```essbase
FIX("FY24", @DESCENDANTS("Total_Accounts"))
    IF(@ABS("Budget") > 0)
        IF(@ABS("Actual" - "Budget") / @ABS("Budget") > 0.05)
            "Material_Flag" = 1;
        ELSE
            "Material_Flag" = 0;
        ENDIF
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Assuming `#MISSING` becomes 0 | `@ABS(#MISSING)` returns `#MISSING`, not 0 | Use `IF` to check for `#MISSING` first, or use `SET AGGMISSG ON` if appropriate |
| Using @ABS on a member set | `@ABS` works on numeric expressions, not member sets like `@CHILDREN` | Apply `@ABS` to each cell value, not to member functions |
| Ignoring division by zero | `@ABS(0)` is still 0 — using it as a denominator causes `#MISSING` | Always check `@ABS(value) > 0` before dividing |
| Double-negation logic errors | `@ABS` removes the sign — if you later negate the result, you may get wrong signs | Review your formula logic carefully |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ROUND`](./@@ROUND.md) | Often used together — round after taking absolute value |
| [`@INT`](./@@INT.md) | Truncates to integer; sometimes confused with @ABS |
| [`@MAX`](./@@MAX.md) | Can be used as `@MAX(value, -value)` as an alternative to @ABS |
| [`@MIN`](./@@MIN.md) | Complementary — finds minimum values |
| [`@MOD`](./@@MOD.md) | Modulus — another mathematical function |
| [`@TRUNCATE`](./@@TRUNCATE.md) | Removes decimal portion, different from absolute value |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ABS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/abs.html)
- [Oracle Essbase Technical Reference — @ABS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
