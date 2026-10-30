# 01 Execution Modes: Bottom-Up vs. Top-Down Calculation Engine Internals

## 1. The Two Essbase Calculation Execution Modes

At the heart of the Essbase Block Storage (BSO) calculation engine lies a fundamental operational fork: **Bottom-Up** calculation versus **Top-Down** calculation. The execution mode determines how the calculation engine traverses multidimensional coordinate space and allocates memory buffers.

```
+---------------------------------------------------------------------------------------------------+
|                                 BOTTOM-UP vs. TOP-DOWN TRAVERSAL                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  SCENARIO: Database has 500,000 potential sparse coordinate combinations.                         |
|            Only 5,000 sparse blocks actually contain data on disk (.pag).                         |
|                                                                                                   |
|  [MODE 1: BOTTOM-UP CALCULATION (OPTIMAL)]                                                        |
|  +---------------------------------------------------------------------------------------------+  |
|  | - Traverses ONLY existing physical blocks in memory cache.                                   |  |
|  | - Completely skips 495,000 non-existent blocks.                                              |  |
|  | - Processes 5,000 blocks in vectorized FPU memory.                                           |  |
|  | - Throughput: 50,000 to 200,000 blocks/second. Execution Time: 0.15s                          |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                                                                   |
|  [MODE 2: TOP-DOWN CALCULATION (POTENTIALLY CATASTROPHIC)]                                        |
|  +---------------------------------------------------------------------------------------------+  |
|  | - Evaluates the formula across the ENTIRE theoretical potential coordinate space.           |  |
|  | - Must check all 500,000 combinations to see if calculation conditions are met.              |  |
|  | - Forces block creation checks and index lookups for empty space.                           |  |
|  | - Throughput: 200 to 1,000 combinations/second. Execution Time: 45.0s (300x slower!)        |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. How the Engine Chooses the Execution Mode

Essbase analyzes member formulas and business rules during compilation and automatically assigns an execution mode according to deterministic rules:

### 2.1 Natural Bottom-Up Triggers:
* Formulas that reference members from **Dense dimensions only** (e.g., `"Sales" * "Markup"` where Account is Dense).
* Straightforward arithmetic operators (`+`, `-`, `*`, `/`) between dense coordinates within existing blocks.

### 2.2 Inadvertent Top-Down Triggers:
The compiler automatically degrades an execution to **Top-Down** if the formula contains:
1. **Cross-Dimensional Operators (`->`) referencing Sparse Dimensions** on the right-hand side.
2. **Essbase Range Functions**: `@SUMRANGE`, `@AVGRANGE`, `@MAXRANGE` across sparse members.
3. **Sparse `IF` Statements**: `IF (@ISMBR("SparseMember"))`.
4. **Complex Lead/Lag Functions across Sparse Boundaries**: `@PRIOR` referencing non-contiguous sparse blocks.

---

## 3. Forcing Bottom-Up Execution via `@CALCMODE`

When a developer knows that a formula can be safely executed across existing blocks without evaluating non-existent coordinates, they can explicitly override the engine compiler using the `@CALCMODE` function:

```sql
/* Forcing Bottom-Up Execution */
"Marketing_Alloc" (
  @CALCMODE(BOTTOMUP)
  "Marketing_Alloc" = "Corporate_Marketing"->"Total_Dept" * "Alloc_Pct";
)
```

### When is `@CALCMODE(BOTTOMUP)` Safe?
* When the target block **already exists** on disk.
* When the calculation does not require creating brand-new sparse blocks from non-existent intersections.

### When is `@CALCMODE(BOTTOMUP)` Dangerous?
* If the target sparse block does not exist, a Bottom-Up calculation will **completely skip that intersection**, resulting in missing calculated data! In that specific scenario, Top-Down execution (or `SET CREATEBLOCKONEQ ON`) is required.

