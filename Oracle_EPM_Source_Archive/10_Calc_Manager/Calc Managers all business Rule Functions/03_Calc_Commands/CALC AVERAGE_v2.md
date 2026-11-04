# CALC AVERAGE

## Overview

`CALC AVERAGE` is a **specialized native Essbase calculation directive** in Oracle EPM Cloud (PBCS/EPBCS). Unlike standard `CALC DIM` or `AGG` commands (which strictly perform mathematical addition when rolling up parent branches), `CALC AVERAGE` overrides the structural hierarchy logic and forces the calculation engine to mathematically **AVERAGE** the children together as it rolls up the dimension tree, rather than summing them.

### Why Does This Function Exist—

By default, Essbase outlines are designed for additive consolidation. If you have a `"Product"` dimension, the parent `"Total_Product"` is simply the sum of its children (`Shoes + Shirts + Hats`). 
However, some metrics are non-additive. For example, if you are tracking `"Customer_Satisfaction_Score"`, you cannot add the scores together. If Store A scores `90%` and Store B scores `90%`, the Regional Total is not `180%`. The Regional Total must be `90%`.
Natively, administrators handle this using `Dynamic Calc` block formulas (`@AVG(SKIPMISSING, @CHILDREN(@CURRMBR))`) or two-pass ratio math. But if the dimension is massive, dynamic calcs can cripple retrieval performance. 
`CALC AVERAGE` allows you to physically store the averages. You command the engine to roll up the hierarchy, but instead of adding the children, it sweeps the children, averages them, and writes the average into the parent block on the disk. This creates lightning-fast retrieval times for non-additive KPI metrics.

### When to Use It

- **KPI Consolidations**: Rolling up non-additive metrics like `"Net_Promoter_Score"`, `"Average_Wait_Time"`, or `"Capacity_Utilization"` across geographical or product hierarchies.
- **Stored Ratios**: Physically calculating and storing gross margin percentages at the parent level during the overnight batch, eliminating the need for heavy two-pass dynamic calculations during the day.
- **Historical Blending**: Averaging historical Actuals across multiple legacy cost centers into a single parent node for blended baseline reporting.

---

## Category

**System & Optimization / Aggregation Directives / Calculation Commands**

---

## Syntax

```essbase
CALC AVERAGE (DimName);
```

*(Note: Because this is a macro command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimName` | Dimension | ✅ Yes | The exact name of the dimension that should be aggregated using Average math instead of Addition math (e.g., `"Entity"`). |

---

## Return Value

**Return Type**: System Action (Block Aggregation)

This command does not return a value. It triggers a physical structural rollup of the specified dimension.
- **Average Math**: As the engine steps up the tree, it counts the valid children, sums them, divides by the count, and writes the result to the parent block.
- **Missing Data Handling**: The internal engine uses `SKIPMISSING` logic by default. If a parent has 3 children, but 1 is `#MISSING`, it sums the 2 valid children and divides by 2. It does not divide by 3.
- **Consolidation Operators Ignored**: This command aggressively overrides the `+`, `-`, `*`, `/`, and `~` operators defined in the outline. Every child is treated equally in the average.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine reads the `CALC AVERAGE ("Entity");` command.
2. **Index Sweep**: It drops to the absolute bottom (Level 0) of the `"Entity"` tree.
3. **Parent Evaluation**: It looks at a Level 1 parent. It queries all Level 0 children attached to that parent.
4. **Math Override**: Instead of using standard `AGG` addition, it calculates the mean of the valid children.
5. **Physical Write**: It writes the average into the Level 1 parent block on the disk.
6. **Climb**: It steps to Level 2, averages the Level 1 parents together, writes to Level 2, and repeats until it hits the root.

---

## Syntax Variants & Scenarios

### Variant 1: Averaging KPIs across Entities

```essbase
/* 
   Rolls up the Entity dimension. Parent entities will store 
   the mathematical mean of their children, rather than the sum.
*/
CALC AVERAGE ("Entity");
```

---

## Practical Examples

### Example 1: Rolling up Customer Satisfaction Scores

**Scenario**: A retail company tracks `"CSAT_Score"` (Customer Satisfaction). This metric is loaded at the Level-0 store level. The business needs this score available at the District, Region, and Total Company levels. Because it is a percentage (0 to 100), it cannot be added. The admin uses `CALC AVERAGE` to physically roll up the score.

```essbase
/* 
   1. We MUST isolate this calculation to ONLY the non-additive metric.
   If we don't FIX on the specific KPI, Essbase will average Revenue and Expense too, 
   completely destroying the financial data.
*/
FIX("CSAT_Score", "Actual", "FY25")
    
    /* 
       2. We command the engine to roll up the Entity tree using Average math.
       3. Store A (90) and Store B (80) will be averaged.
       4. The parent District will physically store 85.
    */
    CALC AVERAGE ("Entity");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting to Isolate the Account | Destroying Financials | This is the most dangerous mistake. If you write `CALC AVERAGE("Entity");` without fixing on a specific KPI, Essbase will average EVERYTHING. It will average `"Total_Revenue"`. If Store A made $100 and Store B made $200, the company total will be reported as $150, instead of $300. You MUST explicitly `FIX` on the specific statistical/KPI accounts before firing this command |
| Averages of Averages (Weighting) | Mathematical Inaccuracy | `CALC AVERAGE` performs a simple mean at each level. If District 1 has 50 stores (Avg Score: 90) and District 2 has 2 stores (Avg Score: 50), this command will average the two Districts together for the Region: `(90 + 50) / 2 = 70`. This is mathematically incorrect for weighted metrics (the true average is `(4500 + 100) / 52 = 88.4`). For true weighted averages, you CANNOT use this command; you must use custom cross-dimensional ratio math |
| Using `@` Prefix | `@CALC AVERAGE` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CALC DIM`](./CALC%20DIM.md) | The standard version. Rolls up the dimension using strict additive addition based on the outline operators |
| [`@AVG`](../07_Statistical/@AVG.md) | The cell-level mathematical function. Used to calculate averages horizontally across arrays (like Time), rather than vertically up a structural dimension |
| `AGG` | The modern standard for sparse-dimension aggregations, always using addition rather than averaging |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — CALC AVERAGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_average.html)
