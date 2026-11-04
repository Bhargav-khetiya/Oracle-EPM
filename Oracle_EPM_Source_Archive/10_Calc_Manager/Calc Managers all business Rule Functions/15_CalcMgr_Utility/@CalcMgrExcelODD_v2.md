# @CalcMgrExcelODD

## Overview

`@CalcMgrExcelODD` is a **custom Calc Manager mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `ODD` function directly inside an Essbase calculation script. 
It analyzes a number, and if that number is not an odd integer, it forces the number **away from zero** to the nearest odd integer.

### Why Does This Function Exist—

Standard rounding (`@ROUND` or `@TRUNC`) typically rounds to the nearest whole integer. However, in physical logistics, manufacturing, and staffing models, requirements must sometimes be forced into highly specific numerical patterns. 
While rounding to *even* numbers is common for balancing (e.g., pallets on a truck), rounding to *odd* numbers is used in scenarios that require a definitive center point or tie-breaker (e.g., scheduling a committee of judges, or configuring machinery with a center-drive gear flanked by symmetrical support gears).
If you mathematically calculate that you need `4.2` judges for a panel, standard rounding gives you `4`. An even number of judges can result in a tie. You must forcefully round `4.2` up to `5`.
Writing custom modulus logic in Essbase to check if a number is odd, and if not, add an offset to force it to an odd integer, is tedious. `@CalcMgrExcelODD` handles this automatically in the Java engine, ensuring your rounding logic perfectly matches the legacy Excel model.

### When to Use It

- **Staffing / HR Models**: Forcing headcount requirements for committees or voting panels to an odd number to prevent ties.
- **Manufacturing Planning**: Rounding physical component requirements (like cogs or gears) that mandate an odd-numbered symmetrical layout.
- Whenever you need to migrate an Excel spreadsheet containing the `ODD` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelODD(number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The raw numeric value you want to round to an odd integer. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the rounded odd integer.
- If the `number` is already an exact odd integer (e.g., `5`), no rounding occurs, and the original number is returned.
- **Directional Note**: The function always rounds *away* from zero. Positive numbers round UP (e.g., `4.2` becomes `5`). Negative numbers round DOWN (e.g., `-4.2` becomes `-5`).

---

## How It Works (Behind the Scenes)

1. **Integer Check**: The Java engine checks if the number is already an odd integer (e.g., `number % 2 != 0`). If it is, it returns it instantly.
2. **Directional Math**: If the number is positive, it forces it up to the next odd integer. If it is negative, it forces it down to the next odd negative integer.
3. **Return**: It passes the finalized, odd value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Positive Number Rounding

```essbase
/* Calculation requires 4.2 units. Must round up to the next odd integer. Returns 5. */
"Units_To_Order" = @CalcMgrExcelODD(4.2);
```

### Variant 2: Negative Number Rounding

```essbase
/* Forecasting a negative variance of -2.1. Rounds away from zero to -3. */
"Odd_Negative_Variance" = @CalcMgrExcelODD(-2.1);
```

---

## Practical Examples

### Example 1: Preventing Ties in Panel Scheduling

**Scenario**: A corporate HR model dynamically calculates how many senior executives need to be pulled off their daily tasks to form an interview panel for a new VP candidate. The formula dictates `1.5` executives for every specialized skill the candidate possesses. If the candidate has 3 skills, the math dictates `4.5` executives. However, panels *must* have an odd number of voters to break ties. You use `ODD` to force the headcount.

```essbase
FIX("FY25", "Working", @LEVEL0("Recruiting_Events"))
    
    /* Calculate raw panel requirement (e.g., 3 * 1.5 = 4.5) */
    "Raw_Exec_Requirement" = "Candidate_Skills_Count" * 1.5;
    
    IF("Raw_Exec_Requirement" > 0)
        
        /* Force the requirement to an Odd Number for tie-breaking */
        /* E.g., 4.5 becomes 5. 6.1 becomes 7. */
        "Final_Panel_Headcount" = @CalcMgrExcelODD("Raw_Exec_Requirement");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with Standard Rounding | Expecting `4.2` to round to `3` | `ODD` does not care which odd number is mathematically *closer*. It always forcefully rounds *away* from zero to the *next* odd number. `4.2` becomes `5`, even though `3` is closer. If you want nearest-neighbor rounding, use `@ROUND("Value", 0)` and deal with even numbers manually |
| Negative Number Behavior | Expecting `-4.2` to become `-3` | Because the function always rounds *away* from zero, `-4.2` will be forced to `-5`, not `-3`. |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelEVEN`](./@CalcMgrExcelEVEN.md) | The direct counterpart: forcefully rounds a number away from zero to the nearest *even* integer |
| [`@CalcMgrExcelCEILING`](./@CalcMgrExcelCEILING.md) | Rounds a number UP to the nearest multiple of significance |
| [`@ROUND`](../06_Mathematical/@ROUND.md) | Native Essbase function for standard, nearest-neighbor rounding |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelodd.html)
