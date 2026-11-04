# CALC TWOPASS

## Overview

`CALC TWOPASS` is a **specialized native Essbase calculation command** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an aggressive recalculation macro that explicitly hunts down and re-executes formulas attached to members tagged with the **"Two-Pass"** metadata property in the database outline. 

### Why Does This Function Exist—

Essbase calculates multidimensional databases in a highly specific order (Dense dimensions first, then Sparse dimensions). 
Because of this sequence, ratio calculations (like `"Gross_Margin_Percent"`) often calculate incorrectly at the parent level. 
For example, if `Margin_%` is `(Margin / Revenue)`, Essbase calculates the ratio at the Level 0 Store. When Essbase rolls up the Sparse Entity tree to `"Total_Region"`, it natively adds the Level 0 percentages together (e.g., `10% + 15% + 12% = 37%`). A Regional Margin of 37% is mathematically absurd. The Region must re-calculate its *own* formula using the fully rolled-up Regional Margin and Regional Revenue.
To fix this, administrators tag the `Margin_%` account as "Two-Pass". But the database doesn't automatically re-calculate it just because it's tagged. You must explicitly fire the `CALC TWOPASS;` command at the very end of your script. This tells the engine: "Sweep the outline one last time, find anything tagged Two-Pass, and recalculate its formula at the parent level so the ratios are correct."

### When to Use It

- **Ratio Corrections**: Recalculating percentage metrics (Margin %, Tax Rate %, Conversion Rate %) at the parent hierarchy levels after a massive sparse dimension aggregation.
- **Variance Formulas**: Correcting `"Actual_vs_Budget"` parent-level variances that were destroyed by standard additive consolidation logic.
- **Complex Interdependencies**: Forcing a final recalculation sweep for dynamic metrics that depend on fully aggregated totals (like `"Store_Percent_of_Total_Company"`).

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
CALC TWOPASS;
```

*(Note: Because this is a macro command, it does NOT use the `@` prefix, and it must end with a semicolon `;`. It does not accept any parameters).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| None | N/A | N/A | This command requires no parameters. It blindly sweeps the active blocks in memory looking for the Two-Pass metadata tag. |

---

## Return Value

**Return Type**: System Action (Formula Execution)

This command does not return a single numeric value. It executes a physical recalculation sweep.
- **Target Selection**: It only affects members physically tagged as `Two-Pass` in the `.otl` dimension outline.
- **Block Re-write**: It executes the formula attached to those Two-Pass members on the upper-level blocks and overwrites the garbage additive data that was left there by the standard aggregation.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine reads the `CALC TWOPASS;` command at the end of the script.
2. **Metadata Sweep**: It scans the database outline and identifies all members tagged with the internal `Two-Pass` boolean property.
3. **Block Loading**: It identifies all the parent-level blocks in the current `FIX` scope.
4. **Formula Execution**: It re-executes the formulas for the Two-Pass members inside those parent blocks, utilizing the newly aggregated parent-level totals (e.g., using `Total_Region -> Margin` instead of `Store_101 -> Margin`).
5. **Disk Write**: It overwrites the old, invalid summed data with the newly calculated correct ratio.

---

## Syntax Variants & Scenarios

### Variant 1: End-of-Script Execution

```essbase
/* 
   Placed at the absolute end of an aggregation script to ensure 
   all ratios are correct at the parent level.
*/
CALC TWOPASS;
```

---

## Practical Examples

### Example 1: Full Batch Aggregation and Ratio Correction

**Scenario**: The nightly batch script must aggregate the entire database. It calculates the Dense Account formulas, rolls up the Sparse Entity dimension, and rolls up the Sparse Product dimension. If the script ends there, every single ratio account (like `"Gross_Margin_%"`) will be wrong at the Entity and Product parent levels. The administrator uses `CALC TWOPASS` as the final step.

```essbase
/* 1. Fix on the data load scope */
FIX("Actual", "FY25", "Working")
    
    /* 2. Calculate the Dense accounts (Formulas execute at Level 0) */
    CALC DIM ("Account");
    
    /* 3. Aggregate the Sparse dimensions (Level 0 ratios are improperly added together) */
    AGG ("Entity", "Product");
    
    /* 4. Fire the Two-Pass sweep to fix the upper-level ratios */
    CALC TWOPASS;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it on Dynamic Calc | Wasted Effort | If an account is tagged as `Dynamic Calc`, it calculates on-the-fly when a user queries it in Smart View. Essbase automatically applies Two-Pass logic to `Dynamic Calc` queries. `CALC TWOPASS` is explicitly designed to fix physical, **Stored** blocks on the disk. Firing this command on a database where all ratios are `Dynamic Calc` is completely pointless and wastes calculation time |
| Firing it Before Aggregation | Math Sequence Failure | If you run `CALC TWOPASS` *before* you run `AGG("Entity")`, the parent blocks don't have the summed totals yet. The ratios will calculate against empty parent blocks, returning `#MISSING`. You must ALWAYS place `CALC TWOPASS` at the absolute end of the script, after all aggregations are finished |
| Using `@` Prefix | `@CALC TWOPASS` | This is a calculation macro. It is not a mathematical function. If you put an `@` symbol in front of it, the compiler will crash immediately |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CALC DIM`](./CALC%20DIM.md) | The targeted dimension calculation command that usually precedes a Two-Pass sweep |
| `AGG` | The sparse aggregation command that causes the ratio distortion requiring the Two-Pass sweep to fix |
| `Dynamic Calc` | A metadata property that provides on-the-fly ratio accuracy, often eliminating the need for `CALC TWOPASS` in modern outline design |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — CALC TWOPASS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_twopass.html)
