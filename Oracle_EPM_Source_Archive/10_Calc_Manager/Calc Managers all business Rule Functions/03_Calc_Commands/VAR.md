# VAR

## Overview

`VAR` declares a **temporary variable** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager business rules. Variables store intermediate values — strings, numbers, member names, or function results — that can be reused throughout the calculation script. They make code cleaner, more readable, more maintainable, and often faster.

### Why Does This Command Exist?

Without variables, you'd have to repeat complex expressions everywhere they're used:
- Repeating `@NAME(@CURRMBR("Entity"))` ten times in a script is error-prone and hard to read
- Calculating the same subtotal multiple times wastes compute cycles
- Hardcoding values like tax rates makes scripts inflexible when rates change
- Complex formulas with nested functions become unreadable without intermediate variables

### When to Use It

- To store frequently referenced member names for readability
- To capture the result of an expensive calculation once and reuse it
- To parameterize values like rates, thresholds, or factors for easy maintenance
- To build dynamic member names through string concatenation
- To store Boolean flags for conditional logic
- To make complex formulas self-documenting with descriptive variable names

---

## Category

**Calc Script Command / Variable Declaration**

---

## Syntax

```essbase
VAR varName = value;
VAR varName;
```

### Formal Syntax

```
VAR variableName [= initialValue];
```

Where:
- `variableName` — A user-defined name following Essbase naming rules (no spaces, starts with letter or underscore). Common convention is to prefix with `v` (e.g., `vRate`, `vEntity`).
- `initialValue` — Optional. Can be a numeric literal, string literal, member function, or expression. If omitted, the variable is uninitialized.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `variableName` | Identifier | ✅ Yes | The name of the variable. Must start with a letter or underscore. Cannot contain spaces or special characters. Case-insensitive. Convention: prefix with `v` (e.g., `vRate`, `vEntity`, `vMonth`). |
| `initialValue` | Any | ❌ No | The initial value. Can be: a numeric constant (`0.05`), a string literal (`"Jan"`), a function result (`@NAME(@CURRMBR("Entity"))`), or any valid expression. If omitted, the variable is uninitialized and must be assigned before use. |

---

## Return Value

`VAR` does not return a value — it **declares and optionally initializes** a variable for use in subsequent calculations.

---

## How It Works (Behind the Scenes)

1. **Scope**: Variables declared with `VAR` are local to the current calculation script. They exist from the point of declaration until the script completes. They are NOT persistent — they don't survive across different business rule executions.

2. **Type Inference**: Essbase variables are dynamically typed based on their initial value. Assigning a string makes it a string variable; assigning a number makes it numeric. You cannot change the type after initialization.

3. **Evaluation Timing**: `VAR` declarations at the top of a script (outside any FIX block) are evaluated once. Inside a FIX block, they're evaluated in the context of that block. Inside a member formula block, they may be re-evaluated per member combination.

4. **Memory**: Variables consume minimal memory. Even in large scripts with many variables, the overhead is negligible compared to data block processing.

5. **String Variables**: String variables can hold member names, and these can be used in cross-dimensional references and member specifications. This is one of the most powerful uses of VAR.

6. **Interaction with ACCUMULATEVAR**: The `ACCUMULATEVAR` command can be used with VAR to accumulate values across calculation passes, useful for running totals or counters.

---

## Syntax Variants & Scenarios

### Variant 1: Numeric Variable

```essbase
VAR vTaxRate = 0.21;
"Tax_Expense" = "Pre_Tax_Income" * vTaxRate;
```
Stores a tax rate for reuse — easy to update in one place.

### Variant 2: String Variable with Member Name

```essbase
VAR vCurrEntity = @NAME(@CURRMBR("Entity"));
```
Captures the current entity name as a string for logging or dynamic references.

### Variant 3: Computed Value

```essbase
VAR vTotalRevenue = "Revenue" -> "Total Entity";
"Revenue_Share" = Revenue / vTotalRevenue;
```
Calculates total once, reuses for each entity's share calculation.

### Variant 4: Dynamic Member Reference

```essbase
VAR vPriorYear = @CONCATENATE("FY", @CalcMgrIntegerToString(@CalcMgrGetYear(@CalcMgrGetCurrentDate()) - 1));
"Growth" = Revenue / (Revenue -> vPriorYear) - 1;
```
Dynamically builds prior year member name.

### Variant 5: Multiple Variables

```essbase
VAR vRate = 0.05;
VAR vThreshold = 1000;
VAR vEntity = @NAME(@CURRMBR("Entity"));
VAR vPeriod = @NAME(@CURRMBR("Period"));
```
Declare all variables at the top of the script for clarity.

### Variant 6: Boolean-Style Flag

```essbase
VAR vIsLeaf = @ISIBOTTOM("Entity");
IF(vIsLeaf)
    Revenue = Units * Price;
ENDIF
```
Stores a Boolean test result for reuse.

---

## Practical Examples

### Example 1: Growth Rate Calculation

**Scenario**: Apply a configurable growth rate to forecast revenue.

```essbase
VAR vGrowthRate = 0.08;  /* 8% growth — change here to update everywhere */

FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    Revenue = Revenue -> "FY24" * (1 + vGrowthRate);
    "Service_Revenue" = "Service_Revenue" -> "FY24" * (1 + vGrowthRate);
    "Product_Revenue" = "Product_Revenue" -> "FY24" * (1 + vGrowthRate);
ENDFIX
```

**What Happens**:
- `vGrowthRate` is defined once at the top
- All three revenue lines use the same rate
- To change from 8% to 10%, update only one line

---

### Example 2: Dynamic Member Name Construction

**Scenario**: Build a prior year member name dynamically.

```essbase
VAR vCurrentYear = @NAME(@CURRMBR("Year"));
VAR vYearNum = @CalcMgrGetIntegerFromString(@CalcMgrSubstring(vCurrentYear, 2, 4));
VAR vPriorYear = @CalcMgrConcat("FY", @CalcMgrIntegerToString(vYearNum - 1));

FIX("Forecast", @DESCENDANTS("Total Entity"))
    "YoY_Growth" = Revenue / (Revenue -> vPriorYear) - 1;
ENDFIX
```

---

### Example 3: Debugging with Variables

**Scenario**: Use variables to capture intermediate values for logging.

```essbase
VAR vEntity = @NAME(@CURRMBR("Entity"));
VAR vPeriod = @NAME(@CURRMBR("Period"));
VAR vRevenue = Revenue;
VAR vCOGS = COGS;
VAR vMargin = vRevenue - vCOGS;

@CalcMgrLogStrings("Entity: ", vEntity, " Period: ", vPeriod);
@CalcMgrLogValues("Revenue: ", vRevenue, " COGS: ", vCOGS, " Margin: ", vMargin);

"Gross_Margin" = vMargin;
```

---

### Example 4: Threshold-Based Classification

**Scenario**: Classify accounts based on variance magnitude.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vVariance = @ABS("Actual" - "Budget");
    VAR vBudget = @ABS("Budget");
    VAR vPct = 0;
    
    IF(vBudget > 0)
        vPct = vVariance / vBudget;
    ENDIF
    
    IF(vPct > 0.10)
        "Risk_Flag" = 3;   /* High risk: >10% variance */
    ELSEIF(vPct > 0.05)
        "Risk_Flag" = 2;   /* Medium risk: 5-10% */
    ELSE
        "Risk_Flag" = 1;   /* Low risk: <5% */
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using VAR inside a formula block incorrectly | VAR scope rules differ inside member formula blocks vs. top-level | Declare variables at the top of the script or at the beginning of FIX blocks |
| Assuming variables persist across rules | Variables are local to one script execution — they don't carry over | Use substitution variables or data cells for cross-rule persistence |
| Forgetting the semicolon | `VAR vRate = 0.05` without `;` causes a syntax error | Always end with semicolon: `VAR vRate = 0.05;` |
| Variable name conflicts | Using names that match member names or functions causes confusion | Prefix all variables with `v`: `vRevenue`, `vEntity`, `vRate` |
| Type mismatch | Assigning a string to a numeric variable or vice versa | Be consistent with types — don't mix string and numeric assignments |
| Using uninitialized variables | Accessing a VAR before assigning a value gives unpredictable results | Always initialize: `VAR vCount = 0;` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`ARRAY`](./ARRAY.md) | Declares an array variable — for multiple indexed values |
| [`ACCUMULATEVAR`](./ACCUMULATEVAR.md) | Accumulates variable values across passes |
| [`@NAME`](./@NAME.md) | Commonly used to get member name into a VAR |
| [`@CURRMBR`](./@CURRMBR.md) | Gets current member — commonly stored in VAR |
| [`@CalcMgrConcat`](./@CalcMgrConcat.md) | Concatenates strings — used to build dynamic member names in VARs |
| [`FIX`](./FIX.md) | VAR declarations often appear at the top of or within FIX blocks |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — VAR](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/var.html)
- [Oracle Essbase Technical Reference — Variable Declaration](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/variables.html)
