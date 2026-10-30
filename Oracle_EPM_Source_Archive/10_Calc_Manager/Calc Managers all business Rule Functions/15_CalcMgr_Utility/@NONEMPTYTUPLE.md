# @NONEMPTYTUPLE

## Overview

`@NONEMPTYTUPLE` is a **performance optimization directive** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager used primarily in ASO (Aggregate Storage Option) procedural calculations (Custom Calculation Scripts / MDX). It acts as a hint to the calculation engine to evaluate formulas *only* where data actually exists at a specified cross-dimensional intersection (a tuple), significantly reducing calculation time and memory footprint.

*Note: This is an ASO/MDX specific feature. For BSO cubes, optimization relies on Block calculation logic (Sparse/Dense) and `SET CREATENONMISSINGBLK`.*

### Why Does This Function Exist?

ASO cubes do not have blocks. When a custom calculation formula is written in ASO MDX (e.g., `[Revenue] = [Units] * [Price]`), the engine theoretically has to evaluate that formula for *every single possible intersection* of the database, even if it's completely empty. This causes massive performance degradation or memory errors.
`@NONEMPTYTUPLE` tells the engine: "Only calculate this formula if there is a number at this specific tuple."

### When to Use It

- In ASO Custom Calculation rules to optimize performance.
- When you are assigning a value based on a driver, and you only want the calculation to run where the driver exists.
- To prevent "data explosion" in ASO where the system attempts to calculate zero values across the entire cube.

---

## Category

**MDX / Performance Optimization (ASO Only)**

---

## Syntax

```mdx
[Target_Member] = [Formula] , @NONEMPTYTUPLE([Tuple]);
```

### Formal Syntax

```
Member_Formula , @NONEMPTYTUPLE( [Dim1].[Member1], [Dim2].[Member2]... )
```

Where:
- `Member_Formula` — The standard MDX assignment formula.
- `[Tuple]` — A comma-separated list of members representing a specific intersection. If this intersection is empty (null), the formula is skipped.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Tuple` | MDX Intersection | ✅ Yes | A specific, fully qualified or partially qualified intersection (e.g., `([Units], [Actual])`). The engine checks if data exists here before executing the formula. |

---

## Return Value

**Return Type**: None (It is a compiler directive, not a function that returns a value).

---

## How It Works (Behind the Scenes)

1. **Tuple Evaluation**: Before evaluating the MDX assignment, the ASO engine checks the data value at the tuple specified in `@NONEMPTYTUPLE`.
2. **Execution Gate**: 
   - If the tuple contains a non-null value, the engine evaluates the formula for the current context.
   - If the tuple is null/empty, the engine skips the calculation entirely for that context.
3. **Data Explosion Prevention**: By anchoring the calculation to an existing driver (like `[Units]`), it restricts the mathematical operations to only the active intersections, making ASO calculations lightning fast.

---

## Syntax Variants & Scenarios

### Variant 1: Single Member Tuple

```mdx
[Revenue] = [Units] * [Price] , @NONEMPTYTUPLE([Units]);
```
*Calculates Revenue only where Units exist.*

### Variant 2: Multi-Member Tuple

```mdx
[Total_Cost] = [Headcount] * [Rate] , @NONEMPTYTUPLE(([Headcount], [Working]));
```
*Calculates only where Headcount exists in the Working scenario.*

---

## Practical Examples

### Example 1: Standard Rate x Volume Calculation in ASO

**Scenario**: You have an ASO cube where you are calculating Revenue based on Units and a global Price assumption.

```mdx
/* ASO Custom Calculation Script */
[Revenue] = [Units] * ([Price], [No_Product], [No_Customer]) , @NONEMPTYTUPLE([Units]);
```

**What Happens**: 
- The engine scans the cube for any intersection where `[Units]` is not empty.
- When it finds `[Units] = 10` for `[Product A]`, it executes the multiplication using the global price.
- It completely ignores `[Product B]` if there are no units, preventing the calculation of 0 revenue.

---

### Example 2: Allocation in ASO

**Scenario**: Allocating a corporate IT pool down to departments based on Headcount.

```mdx
/* ASO Allocation Script */
[Allocated_IT_Cost] = ([IT_Cost_Pool], [Corporate_Dept]) * 
                      ([Headcount] / ([Headcount], [Total_Department])) 
                      , @NONEMPTYTUPLE([Headcount]);
```
*By anchoring to `[Headcount]`, the allocation only executes for departments that actually have employees, saving massive calculation time.*

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using in BSO cubes | `@NONEMPTYTUPLE` is an MDX directive for ASO cubes. It does not work in standard BSO Essbase Calc Scripts | Use `SET CREATENONMISSINGBLK ON` or `FIX` blocks on sparse dimensions in BSO |
| Using the wrong tuple | If you anchor to `[Price]`, and `[Price]` exists everywhere but `[Units]` only exists in 5 places, you will calculate thousands of empty rows | Always anchor `@NONEMPTYTUPLE` to the most restrictive driver (usually the volume or actuals metric) |
| Missing parentheses for multi-member tuples | `@NONEMPTYTUPLE([Units], [Actual])` is invalid syntax for a tuple | Enclose the tuple in parentheses: `@NONEMPTYTUPLE(([Units], [Actual]))` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| `SET CREATENONMISSINGBLK` | The BSO equivalent for preventing data explosion |
| `NON EMPTY` | Standard MDX query syntax (used in reporting, not calculation scripts) |

---

## Official Oracle Reference

- [Oracle EPM Cloud MDX Functions — NONEMPTYTUPLE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mdx_nonemptytuple.html)
