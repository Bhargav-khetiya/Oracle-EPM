# 06 Aggregation Template: CALC DIM, AGG, Hourglass Principles, and Selective Rollups

## 1. Architectural Foundations of Hierarchical Aggregation

In multidimensional Block Storage (BSO) cubes, user data entry and formula calculations occur primarily at base leaf intersections (Level 0). To generate executive dashboards and corporate consolidated financial statements, summary parent blocks must be computed across sparse hierarchies.

The Calculation Manager **Aggregation Template** automates hierarchical rollups, optimizing engine performance by applying the mathematical **Hourglass Principle** and selecting between `CALC DIM` and `AGG`.

```
+---------------------------------------------------------------------------------------------------+
|                                     THE HOURGLASS ROLLUP ORDER                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  SPARSE DIMENSIONS (Ordered from Smallest to Largest Member Count)                                |
|                                                                                                   |
|  [Dimension 1: Scenario]       (3 members)    <-- Narrow Neck of Hourglass                        |
|             |                                                                                     |
|             v                                                                                     |
|  [Dimension 2: Version]        (5 members)                                                        |
|             |                                                                                     |
|             v                                                                                     |
|  [Dimension 3: Department]     (85 members)                                                       |
|             |                                                                                     |
|             v                                                                                     |
|  [Dimension 4: Entity]         (450 members)                                                      |
|             |                                                                                     |
|             v                                                                                     |
|  [Dimension 5: Product]        (1,200 members) <-- Wide Base of Hourglass                         |
|                                                                                                   |
|  MATHEMATICAL RULE:                                                                               |
|  Always aggregate from SMALLEST sparse dimension to LARGEST sparse dimension!                    |
|  Prevents exponential block explosion and minimizes disk thrashing.                              |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. `CALC DIM` vs. `AGG`: Engine Comparison

| Feature | `CALC DIM(DimName)` | `AGG(DimName)` |
| :--- | :--- | :--- |
| **Formula Execution** | Calculates member formulas AND rollups. | **Rollups ONLY** (Bypasses member formulas). |
| **Execution Speed** | Moderate. Evaluates complex mathematical operators. | **Blazingly Fast**. Optimized C++ summation loop. |
| **Consolidation Operators** | Supports `+`, `-`, `*`, `/`, `%`, `~`. | Supports standard consolidation operators `+`, `-`, `~`. |
| **When to Use** | Use when dimensions contain stored formulas on upper parents. | Use when hierarchies only need mathematical summation. |

---

## 3. Wizard Configuration Parameters

When using the Aggregation Template wizard:

| Step | Parameter | Description |
| :--- | :--- | :--- |
| **Step 1: Dimensions to Aggregate** | Dimension Checklist | Selects the sparse dimensions to roll up. |
| **Step 2: Rollup Order** | Dimension Sequence | Allows manual re-ordering to enforce the Hourglass Principle. |
| **Step 3: Aggregation Mode** | `AGG` / `CALC DIM` | Toggles between fast `AGG` and formula-evaluating `CALC DIM`. |
| **Step 4: Dimension Fixes** | Slicing Grid | Limits aggregation to active Scenario, Year, and Version slices. |
| **Step 5: Selective Aggregation** | Enable / Disable | Activates `SET AGGSPARSESEL ON;` to aggregate only blocks with data. |

---

## 4. Generated Essbase Script Structure

```sql
/*
 * Compiled Aggregation Template Script
 * Slices: Scenario: Forecast, Years: FY25, Version: Working
 * Enforces Hourglass Order: Department -> Entity -> Product
 */

SET UPDATECALC OFF;
SET AGGSPARSESEL ON; /* Skips empty parent blocks */

FIX("Forecast", "FY25", "Working")
  /* Execute fast AGG in ascending sparse size order */
  AGG("Department", "Entity", "Product");
ENDFIX
```

---

## 5. Aggregation in the Era of Hybrid BSO

In modern Oracle EPM Cloud applications running **Hybrid BSO mode**, physical aggregation scripts are often unnecessary:
* In Hybrid BSO, sparse dimensions can be set to **Dynamic Calc**.
* Essbase dynamically aggregates upper-level sparse parents at query time using the high-speed ASO aggregation engine.
* **Result**: Storage file sizes drop by 80–90%, batch calculation windows shrink to zero, and batch `AGG` scripts can be retired.

