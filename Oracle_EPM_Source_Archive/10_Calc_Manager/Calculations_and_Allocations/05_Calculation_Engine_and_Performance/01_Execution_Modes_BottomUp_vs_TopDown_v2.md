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

```essbase
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

---

## 4. Master Pedagogical Reference & Recall Guide (The 12 Pillars)

### 1. Core Idea
**Bottom-Up calculation evaluates formulas exclusively on existing physical data blocks in memory, running up to 300x faster than Top-Down calculation, which scans the entire theoretical universe of possible sparse coordinates.**

### 2. Simple Explanation & Analogy
* **Everyday Analogy**: Imagine a postal delivery driver with 5 packages to deliver in a sprawling rural county with 50,000 potential street addresses:
  * **Bottom-Up Driver**: Looks at the 5 packages, gets the 5 exact street addresses from the GPS, drives directly to those 5 houses, drops the packages, and finishes in 10 minutes.
  * **Top-Down Driver**: Drives down every single dirt road and knocks on all 50,000 doors in the county to ask, *"Do you happen to have a package today?"* — taking 3 full days to deliver the same 5 packages!

### 3. Purpose: Why It Matters
In enterprise Planning systems, business rules attached to Web Forms run while a live user waits for the browser to unlock. A Top-Down calculation causes web forms to freeze for 45 to 90 seconds, triggering HTTP 504 Gateway Timeouts and frustrates executive planners. Enforcing Bottom-Up calculation guarantees sub-second response times.

### 4. Connections to Other Concepts
* **Block Storage Physics ([Vol 01: Essbase_Internal_Architecture](../../../Essbase_Internal_Architecture/04_Block_Storage_Deep_Dive.md))**: Bottom-Up mode operates on the Page file (`.PAG`) blocks already loaded into the Essbase Data Cache.
* **Block Creation Integrity ([02_Block_Creation_and_Data_Integrity.md](./02_Block_Creation_and_Data_Integrity.md))**: If target blocks do not exist, developers must understand how to create blocks intentionally without relying on slow Top-Down scanning.
* **Groovy Dynamic micro-FIX ([06_Groovy_Business_Rules/02_Dynamic_FIX_Generation_and_Context_Slicing.md](../06_Groovy_Business_Rules/02_Dynamic_FIX_Generation_and_Context_Slicing.md))**: Groovy eliminates Top-Down degradation entirely by inspecting `cell.isEdited()` and wrapping the calculation in a narrow, explicit Bottom-Up `FIX`.

### 5. Prerequisites & Assumptions
* Understanding of Dense vs. Sparse outline dimensions.
* Basic knowledge of Essbase calculation script syntax (`FIX`, `ENDFIX`, `VAR`).

### 6. How It Works: Engine Decision Flowchart
```
                [MEMBER FORMULA / BUSINESS RULE]
                               │
            Does the formula reference members from
                   SPARSE dimensions or use
             sparse IF conditions / cross-dims?
                               │
               ┌───────────────┴───────────────┐
              NO                              YES
               │                               │
               ▼                               ▼
       [NATURAL BOTTOM-UP]             [NATURAL TOP-DOWN]
   • Traverses existing blocks     • Evaluates all potential coords
   • Fast vector math in FPU       • Checks empty index addresses
   • 0.15s execution               • 45.0s execution (300x slower!)
                                               │
                                   Can target blocks be
                                 guaranteed to exist on disk?
                                               │
                               ┌───────────────┴───────────────┐
                              YES                              NO
                               │                               │
                               ▼                               ▼
                     Apply @CALCMODE(BOTTOMUP)       Use targeted FIX or
                     to force fast execution         Groovy Dynamic micro-FIX
```

### 7. How to Do It: Optimization Procedure
1. Check the Essbase Application Log (`app.log`) for compiler warnings indicating Top-Down degradation:
   `Formula for member [X] will be executed in TOPDOWN mode.`
2. Inspect the formula for sparse references:
   * Is there an `IF (@ISMBR("SparseEntity"))`?
   * Is there a cross-dimensional pointer to a sparse member (e.g., `->"No_Department"`)?
3. Remove the sparse `IF` condition from the member formula and push it into a calculation script `FIX("SparseEntity")`.
4. If the target blocks are pre-existing, inject `@CALCMODE(BOTTOMUP)` directly above the formula assignment.
5. Recompile and verify the log confirms Bottom-Up execution.

### 8. Worked Example (Illustrative)
> *(Note: The following scenario is illustrative for learning purposes)*

* **Bad Practice (Triggers Catastrophic Top-Down Execution)**:
  ```essbase
  /* Account Member Formula on 'Travel_Allocation' (Sparse Entity check) */
  "Travel_Allocation" (
      IF(@ISMBR("US_East") OR @ISMBR("US_West"))
          "Travel_Allocation" = "Corporate_Travel"->"Total_Entity" * 0.15;
      ENDIF
  )
  ```
  *(Result: Essbase evaluates all 2,000 Entities across all Years and Scenarios in Top-Down mode; form freezes for 38 seconds).*

* **Best Practice (Pure Bottom-Up Execution via Calc Script FIX)**:
  ```essbase
  /* Business Rule Script */
  FIX("US_East", "US_West", "Plan", "FY25", "Working")
      "Travel_Allocation" (
          @CALCMODE(BOTTOMUP)
          "Travel_Allocation" = "Corporate_Travel"->"Total_Entity" * 0.15;
      )
  ENDFIX
  ```
  *(Result: Essbase traverses strictly the 2 target entity blocks; executes in 0.04 seconds!)*

### 9. Compare Choices: Execution Mode Comparison

| Feature / Metric | Bottom-Up Calculation | Top-Down Calculation |
| :--- | :--- | :--- |
| **Blocks Evaluated** | Only existing physical blocks in memory | Entire potential coordinate matrix |
| **Typical Throughput** | 50,000 to 200,000 blocks / sec | 200 to 1,000 combinations / sec |
| **Relative Speed** | **Fastest (Benchmark 1x)** | **Slowest (300x to 1,000x penalty)** |
| **Target Block Requirement** | Target block **must** already exist | Can evaluate across non-existent blocks |
| **Primary Trigger** | Formulas referencing Dense members only | Sparse `IF`, sparse cross-dims (`->`), range functions |
| **Override Command** | `@CALCMODE(BOTTOMUP)` | `@CALCMODE(TOPDOWN)` |

### 10. How to Validate Success
1. Open the Essbase Application Log (`Planning -> Jobs -> View Log`).
2. Verify that no warning lines read: `executed in TOPDOWN mode`.
3. Measure calculation elapsed time in the Job Console; confirm execution finishes in under 1 second.
4. Verify target cells contain expected calculation results.

### 11. Troubleshooting Common Issues
* **Symptom: A forced `@CALCMODE(BOTTOMUP)` formula ran in 0.01s, but target numbers are completely blank `#MISSING`.**
  * *Cause*: The target sparse data block had never been initialized or saved before. Because Bottom-Up only calculates existing blocks, it skipped the calculation entirely.
  * *Remedy*: Pre-create the block using `DATACOPY` from an existing account, or run a data load before the calculation.
* **Symptom: Adding `@CALCMODE(BOTTOMUP)` throws a syntax validation error.**
  * *Cause*: `@CALCMODE` is placed outside the member formula parenthesis or inside an unsupported dynamic calc member.
  * *Remedy*: Ensure `@CALCMODE(BOTTOMUP)` is placed immediately inside the formula parentheses: `"Member" ( @CALCMODE(BOTTOMUP) "Member" = ...; )`.

### 12. Remember and Explain It (Active Recall & Teach-Back)
* **Quick Recap**: Bottom-Up visits only blocks with data; Top-Down visits every possible address on the map. Never write an `IF` statement referencing a sparse dimension inside a member formula.
* **Recall Question 1**: What is the primary cause of inadvertent Top-Down calculation degradation in Essbase?
  * *Answer*: Referencing sparse dimensions in member formula `IF` statements or cross-dimensional operators (`->`).
* **Recall Question 2**: What is the risk of blindly forcing `@CALCMODE(BOTTOMUP)` on a calculation?
  * *Answer*: If the destination block does not already exist on disk, the calculation will silently skip it, leaving data `#MISSING`.
* **Teach-Back Prompt**: *Explain the delivery driver analogy to a junior developer and show them why pushing a sparse condition from an Account formula into a script FIX statement speeds up execution by 300x.*
