# 04 Hybrid BSO Engine Architecture, Dynamic Sparse Calc, and Function Compatibility

## 1. The Hybrid BSO Revolution

Historically, Essbase architectures forced a painful choice:
* **Block Storage (BSO)**: Supported rich calculation scripting, allocations, and cross-dimensional math, but suffered from massive database sizes and slow, multi-hour batch aggregation scripts (`CALC DIM` / `AGG`).
* **Aggregate Storage (ASO)**: Supported instantaneous query-time aggregations and massive dimensionality, but lacked procedural calculation script engines and data write-back capabilities.

**Hybrid BSO** unites these two architectures within a single database kernel. In Hybrid BSO, the cube retains full BSO procedural calculation capabilities, but upper-level summary members of **Sparse Dimensions can be set to Dynamic Calc**. Essbase aggregates these sparse hierarchies dynamically at query time using the high-speed ASO aggregation engine.

```
+---------------------------------------------------------------------------------------------------+
|                                     HYBRID BSO ARCHITECTURAL UNIFICATION                          |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [LEVEL 0 LEAF DATA]                                                                              |
|  Stored in BSO Dense/Sparse Block Architecture (.pag / .ind)                                      |
|  - Supports complex Calculation Manager Rules, Groovy, Driver-Based Math, Allocations             |
|                                                                                                   |
|  -----------------------------------------------------------------------------------------------  |
|                                                                                                   |
|  [UPPER-LEVEL SPARSE PARENTS (DYNAMIC CALC)]                                                      |
|  Evaluated Dynamically at Query Time via In-Memory ASO Engine                                      |
|  - Zero stored parent blocks on disk!                                                             |
|  - Eliminates all batch aggregation scripts (CALC DIM / AGG)!                                     |
|  - Database disk footprint shrinks by 70% to 90%!                                                 |
|  - Data load windows shrink from hours to seconds!                                                |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Impact on Calculation Manager Rule Design

The transition to Hybrid BSO dramatically simplifies Calculation Manager rule architecture:

### 2.1 The Death of Batch Aggregation Rules
In pure BSO applications, administrators maintained elaborate Rule Sets:
1. `Rule 1: Calculate Drivers (Level 0)`
2. `Rule 2: Aggregate Entities`
3. `Rule 3: Aggregate Cost Centers`
4. `Rule 4: Aggregate Products`
In Hybrid BSO, **Rules 2, 3, and 4 are completely eliminated**. The moment Rule 1 finishes calculating Level 0 leaf blocks, all upper-level parent summaries are instantly available for reporting!

### 2.2 Rules Focus Strictly on Level 0
Because upper levels calculate dynamically, Calculation Manager rules must be strictly anchored to Level 0 intersections:
```sql
/* Standard Hybrid BSO Rule Structure */
FIX("Forecast", "FY25", "Working", @LEVMBRS("Entity", 0), @LEVMBRS("Department", 0))
  "Revenue" = "Units" * "Price";
ENDFIX
/* No AGG or CALC DIM required! */
```

---

## 3. Function Compatibility Matrix in Hybrid BSO

While modern Hybrid BSO engines support virtually all common calculation functions, certain complex time-series or cross-cube operations cannot execute dynamically within a Hybrid query:

| Function Category | Supported in Hybrid Dynamic Calc | Execution Behavior & Engine Fallback |
| :--- | :--- | :--- |
| **Basic Arithmetic** (`+`, `-`, `*`, `/`) | **Fully Supported** | Vectorized in-memory resolution. |
| **Summations** (`@SUM`, `@SUMRANGE`) | **Fully Supported** | Ingested into ASO aggregation pipeline. |
| **Attributes & UDAs** (`@ISUDA`, `@ATTRIBUTE`) | **Fully Supported** | Filtered directly in index cache. |
| **Time-Series** (`@PRIOR`, `@NEXT`) | Supported with restrictions | Fast if referencing members within the same block. |
| **Allocations** (`@ALLOCATE`, `@MDALLOCATE`) | **Unsupported in Dynamic Calc** | Must execute inside stored Calculation Manager rules. |
| **Cross-Cube** (`@XREF`, `@XWRITE`) | **Unsupported in Dynamic Calc** | Prohibited in dynamic member formulas. |
| **Custom Defined Functions (CDF)** | Varies by implementation | May force engine fallback to slow single-threaded BSO mode. |

---

## 4. Sizing and Configuration for Hybrid BSO

To enable optimal Hybrid performance in EPM Cloud / Essbase:
1. Set the application configuration parameter: `ASODYNAMICAGGRUNTHEAD ON;` (or verify Cloud Hybrid Mode is active in Application Settings).
2. Ensure sparse dimension parents are explicitly tagged as **Dynamic Calc**.
3. Keep dense dimensions compact (e.g., Accounts and Periods) to maximize CPU L2/L3 cache residency.

