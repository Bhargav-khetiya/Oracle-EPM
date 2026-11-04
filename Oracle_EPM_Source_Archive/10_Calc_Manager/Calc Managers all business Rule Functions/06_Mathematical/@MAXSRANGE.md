# @MAXSRANGE

## Overview

`@MAXSRANGE` is a **native Essbase mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a distinct, explicitly provided list of numeric values or cross-dimensional intersections and returns the absolute **maximum numeric value** found within that specific list. 

### Why Does This Function Exist—

The standard `@MAX` function requires a structural *Member Range* (e.g., `"Jan":"Dec"` or `@CHILDREN("East")`). But what if the numbers you need to compare are entirely un-related— 
For example, what if you need to calculate a "Penalty Rate" that is defined as the *highest* value among three completely different, disconnected sources: The `"Standard_Rate"`, the `"Historical_Penalty"`, and a hardcoded minimum of `0.05`— 
You cannot use `@MAX` because `0.05` is not a dimension member, and the accounts are not siblings. You would have to write complex `IF` statements: `IF(A > B AND A > C) Then A`.
`@MAXSRANGE` solves this. It accepts a raw, comma-separated list of individual numeric values, hardcoded numbers, formulas, or distinct account intersections. It sweeps through this arbitrary list, compares the math, and returns the highest number. This completely breaks the requirement that array functions must operate on structural dimension ranges.

### When to Use It

- **Multi-Source Benchmarking**: Finding the highest metric among three completely unrelated cross-dimensional references (e.g., comparing `"Current_Forecast"`, `"Prior_Year_Actuals"`, and `"Budget"`).
- **Floor/Ceiling Math**: Implementing a "Floor" where a calculated value cannot drop below a certain number. E.g., `@MAXSRANGE(list, Calculated_Value, 0)` ensures the result never goes below zero.
- **Dynamic Array Injection**: Using custom Java CDFs that output numeric lists and passing those raw lists directly into a max evaluation.

---

## Category

**Mathematical / Array Aggregation / Essbase Native Functions**

---

## Syntax

```essbase
@MAXSRANGE(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, list_of_values)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ❌ No  | Determines how `#MISSING` or `0` values are handled:<br>- `SKIPNONE`: Evaluates everything (default).<br>- `SKIPMISSING`: Ignores `#MISSING` evaluations.<br>- `SKIPZERO`: Ignores evaluations resulting in `0`.<br>- `SKIPBOTH`: Ignores both `#MISSING` and `0`. |
| `list_of_values` | Numeric List| ✅ Yes | A comma-separated list of numeric inputs. These can be hardcoded numbers (`50`), account names (`"Revenue"`), full cross-dimensional pointers (`"Actual"->"FY23"`), or entire formulas (`"Price" * 1.5`). |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the absolute highest number found in the list.
- **Negative Support**: If the list evaluates to `[-5, -10, -20]`, the function returns `-5`.
- **Missing Data Handling**: If every single item in the list evaluates to `#MISSING`, and `SKIPMISSING` is applied, it returns `#MISSING`. If `SKIPNONE` is used, `#MISSING` is evaluated as `0`.

---

## How It Works (Behind the Scenes)

1. **Argument Parsing**: The C-engine reads the `list_of_values` parameter and evaluates every single item separated by commas.
2. **Mathematical Resolution**: If an item is a formula (e.g., `"Units" * "Price"`), it calculates the formula first and holds the resulting double in memory.
3. **Filtering**: It applies the `Skip_Flag`, deleting any elements from the temporary memory array that match the skip criteria.
4. **Comparison Sweep**: It compares all the remaining doubles in memory against each other.
5. **Return**: It outputs the single highest numeric value.

---

## Syntax Variants & Scenarios

### Variant 1: Establishing a Mathematical Floor

```essbase
/* 
   Calculates a Net Margin. If the Margin is negative, 
   it forces the result to 0 (because 0 is greater than any negative number).
*/
"Bonus_Metric" = @MAXSRANGE(SKIPNONE, ("Revenue" - "Expenses"), 0);
```

---

## Practical Examples

### Example 1: Multi-Scenario Variance Analysis

**Scenario**: Corporate dictates that the `"Base_Target"` for the upcoming year must be the absolute highest performance achieved across three different historical scenarios: `"FY23_Actual"`, `"FY24_Actual"`, or the `"FY24_Forecast"`. Because these are different Scenarios and Years, they cannot be bundled in a simple time-range. The administrator uses `@MAXSRANGE`.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. We use MAXSRANGE because we are comparing three distinct, 
       non-contiguous intersections.
       2. We use SKIPMISSING so that if an entity didn't exist in FY23, 
       the missing block doesn't skew the comparison to 0.
    */
    "Base_Target" = @MAXSRANGE(SKIPMISSING, 
        "Actual"->"FY23", 
        "Actual"->"FY24", 
        "Forecast"->"FY24"
    );
    
    /* 
       Results:
       If FY23 = 100k, FY24 = 120k, and Forecast = 115k.
       The function returns 120k and writes it to Base_Target.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `@MAXSRANGE` instead of `@MAX` | Poor Performance | If the members you want to evaluate *are* in a contiguous range (e.g., `"Jan":"Dec"`), DO NOT write `@MAXSRANGE(SKIPNONE, "Jan", "Feb", "Mar"...)`. `@MAX` is optimized to sweep dimensional arrays infinitely faster than `@MAXSRANGE` can parse individual comma-separated strings. Only use `@MAXSRANGE` when the inputs are disconnected or require inline math |
| Confusing `SKIPNONE` with Negatives | `#MISSING` is Zero | If you are trying to find the highest value among three cost centers that all lost money (`[-10, -20, #MISSING]`), `SKIPNONE` will evaluate `#MISSING` as `0`, and return `0`. You must use `SKIPMISSING` when comparing potential negative values |
| Syntax Errors with Commas | `(A, B)` vs `@LIST(A, B)` | Unlike `@MAX`, `@MAXSRANGE` is specifically designed to accept a raw comma-separated list of values directly in the parameter. You do NOT need to wrap the values in an `@LIST` function. Simply separate them with commas |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MINSRANGE`](./@MINSRANGE.md) | The exact opposite. Evaluates an arbitrary list of numeric values and returns the absolute lowest number |
| [`@MAX`](./@MAX.md) | The standard array version. Requires a structural member range (`Jan:Dec`) rather than an arbitrary numeric list |
| [`@MAXS`](./@MAXS.md) | A legacy variant that evaluates members sequentially, primarily used for conditional peak finding |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MAXSRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/maxsrange.html)
