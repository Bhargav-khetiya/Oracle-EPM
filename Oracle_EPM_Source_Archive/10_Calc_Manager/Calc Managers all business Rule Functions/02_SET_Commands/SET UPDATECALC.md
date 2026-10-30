# SET UPDATECALC

## Overview

`SET UPDATECALC` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls the **Intelligent Calculation** feature of the Essbase engine. Intelligent Calculation is a highly advanced internal tracking system that monitors whether a data block is "Clean" (has not been changed since the last calculation) or "Dirty" (has been modified by a user or data load). `SET UPDATECALC` explicitly commands the script whether to use this tracking system to skip clean blocks, or to forcefully recalculate everything.

### Why Does This Function Exist?

Aggregating a massive database takes time. If you have 1,000,000 blocks, a full `CALC ALL` might take 2 hours. 
However, what if a user only updated data in *one* block (`"Store_101"`)? It is incredibly wasteful to recalculate the other 999,999 blocks that didn't change. 
Essbase's internal Intelligent Calculation system flags `"Store_101"` as "Dirty". It flags all the other blocks as "Clean". 
By default, standard calculation scripts often run blindly and calculate everything anyway. 
`SET UPDATECALC ON;` commands the engine to look at the flags. The engine sweeps the index, sees 999,999 Clean blocks, and instantly skips them. It only evaluates `"Store_101"`, calculates its math, updates the parents, and finishes the 2-hour script in 2 seconds. This is the holy grail of Essbase performance optimization.

### When to Use It

- **Continuous Intra-Day Aggregations**: Running aggregations every 10 minutes during a busy planning cycle. By using Intelligent Calc, the script only aggregates the exact nodes that users modified in the last 10 minutes.
- **Massive Sparse Hierarchies**: Optimizing `CALC DIM` sweeps on enormous Entity dimensions where only a fraction of the entities receive daily updates.
- **Forced Resets (`OFF`)**: Explicitly turning it `OFF` during the weekend maintenance batch to guarantee a 100% full, fresh recalculation of the entire database, curing any potential flag corruption.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET UPDATECALC ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `ON`: Enables Intelligent Calculation. The engine skips all blocks marked as Clean, only calculating Dirty blocks (Fastest). <br>- `OFF`: Disables Intelligent Calculation. The engine brute-forces the calculation on every single block in the scope, ignoring the flags (Slowest, but guarantees a 100% full sweep). |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a numeric value. It toggles the internal Index Scanner behavior.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Flag Reset**: When a Dirty block is successfully calculated, Essbase automatically clears the flag, marking the block as Clean again.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET UPDATECALC ON;`. It activates the Intelligent Index Scanner.
2. **Sweep Trigger**: The engine hits `CALC DIM("Entity");`.
3. **Block Evaluation**: It approaches `"Store_101"`. It checks the physical block header on the disk.
4. **Flag Route**: If the header says `Clean`, the engine completely bypasses the block and its formulas. If the header says `Dirty` (because a user submitted a web form), the engine loads the block, calculates the formulas, aggregates it to the parent, and changes the header back to `Clean`.
5. **Propagation**: If `"Store_101"` is Dirty, the engine knows that its parent (`"New_York"`) must also be Dirty because its child changed. It cascades the Dirty status up the tree automatically.

---

## Syntax Variants & Scenarios

### Variant 1: Activating Intelligent Calc

```essbase
/* 
   Placed at the top of a script to ensure the engine only processes 
   data that has actually changed since the last run.
*/
SET UPDATECALC ON;
```

---

## Practical Examples

### Example 1: Intra-Day Fast Aggregation

**Scenario**: It is the final day of the budget cycle. 500 users are simultaneously entering data into web forms. The administrator has scheduled a script to aggregate the database every 15 minutes so executives can see the global totals update. If the script calculates everything, it takes 30 minutes, meaning it overlaps and crashes. The admin uses `UPDATECALC ON` to ensure it only aggregates what the users just typed.

```essbase
/* 
   1. Enable Intelligent Calculation tracking.
*/
SET UPDATECALC ON;

FIX("Forecast", "FY25", "Working")
    
    /* 
       2. The engine evaluates the Entity and Product trees.
       It scans the headers. It only rolls up the specific branches 
       where users clicked "Submit" in the last 15 minutes.
       The aggregation finishes in 45 seconds.
    */
    CALC DIM ("Entity", "Product");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Cross-Dimensional Blindness | Corrupted Math | This is the fatal flaw of Intelligent Calculation. The "Clean/Dirty" flag is stored on the physical block. If Store B's formula is `"Sales" = "Store_A" * 1.5;`. And a user updates Store A. Store A becomes Dirty. **Store B remains Clean**, because no one touched Store B directly. If you run `UPDATECALC ON`, it calculates Store A, sees Store B is Clean, skips Store B, and leaves Store B with the old, mathematically incorrect data! You CANNOT use Intelligent Calc if your script relies heavily on complex cross-dimensional pointers or dynamic driver dependencies |
| Using `AGG` Instead of `CALC DIM` | Command Restrictions | In older versions of Essbase, Intelligent Calculation tracking ONLY worked for `CALC ALL` and `CALC DIM` commands. It completely ignored the `AGG` command (which always calculates everything). While modern EPM Cloud is better at this, it is still a best practice to force a full recalculation (`UPDATECALC OFF`) during the overnight batch to ensure 100% data integrity |
| Using `@` Prefix | `@SET UPDATECALC` | This is a calculation macro. It is not a mathematical function. If you put an `@` symbol in front of it, the compiler will crash immediately |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CALC DIM`](./CALC%20DIM.md) | The primary calculation macro that utilizes the Clean/Dirty flags to optimize performance |
| `CALC ALL` | Also heavily relies on Intelligent Calc to prevent 10-hour full-database sweeps |
| [`SET CALCPARALLEL`](./SET%20CALCPARALLEL.md) | The other half of the optimization equation (Multi-threading). Combining Intelligent Calc with Parallel processing creates the fastest possible scripts |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET UPDATECALC](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_updatecalc.html)
