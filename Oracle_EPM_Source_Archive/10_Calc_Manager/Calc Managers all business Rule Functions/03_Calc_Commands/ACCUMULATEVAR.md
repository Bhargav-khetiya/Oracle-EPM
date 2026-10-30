# ACCUMULATEVAR

## Overview

`ACCUMULATEVAR` is a **specialized Calculation Manager command** (rather than a native Essbase `@` function) used in Oracle EPM Cloud (PBCS/EPBCS). It acts as a runtime directive that forces a specific custom variable (`VAR` or `ARRAY`) to retain its accumulated state and roll its value forward across successive blocks, iterations, or even parallel execution threads, rather than resetting to zero at the start of each new block.

### Why Does This Function Exist?

By default, when Essbase executes a calculation script inside a `FIX` statement, it calculates one block (e.g., `"Store_101"`), and then moves to the next block (`"Store_102"`). 
If you define a custom tracking variable (`VAR vCounter = 0;`), that variable exists *locally* within the calculation context of the current block. When the engine finishes Store 101 and moves to Store 102, `vCounter` is destroyed and reset to 0. 
If you are trying to build a global running total (e.g., counting exactly how many stores across the entire company had negative profit, and then writing that final total to a corporate dashboard account), a standard `VAR` fails because it keeps resetting. 
`ACCUMULATEVAR` overrides this default block-level scoping. It elevates the variable to a **Global/Thread level**. The variable acts like a snowball, accumulating data as the engine sweeps across thousands of blocks, preserving the running total until the very end of the script.

### When to Use It

- **Global Counters**: Tracking how many entities passed or failed a specific data-quality validation check during a massive consolidation sweep.
- **Running Totals**: Accumulating a running sum of a highly specific, dynamically calculated metric that isn't stored natively in the outline (e.g., dynamically calculated Tier 3 Tax brackets).
- **Parallel Processing Protection**: Ensuring that when Essbase uses `CALCPARALLEL` to calculate 5 different branches of the hierarchy simultaneously, the custom variable safely aggregates the results from all 5 threads without corrupting the memory address.

---

## Category

**System & Optimization / Variable Management & Directives / Calculation Commands**

---

## Syntax

```essbase
ACCUMULATEVAR VariableName;
```

*(Note: Because this is a command directive, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `VariableName`| Variable | ✅ Yes | The name of the custom variable (previously defined using `VAR` or `ARRAY`) that you want to elevate to global accumulation status. |

---

## Return Value

**Return Type**: Passthrough (State Modification)

This command does not "return" a number that you can assign to a block (`"Sales" = ACCUMULATEVAR` is a fatal syntax error). 
Instead, it modifies the internal memory behavior of the specified variable, ensuring that any math performed on that variable (e.g., `vCounter = vCounter + 1;`) is preserved globally across block boundaries.

---

## How It Works (Behind the Scenes)

1. **Variable Declaration**: The compiler sees `VAR vTotalFailed = 0;`. It allocates local memory for it.
2. **Elevation**: The compiler sees `ACCUMULATEVAR vTotalFailed;`. It elevates the memory address from the local Block Thread to the Global Script Thread.
3. **Execution Loop**: The engine enters the `FIX` statement and evaluates Store 1. Store 1 fails the test. `vTotalFailed` becomes `1`.
4. **Boundary Crossing**: The engine moves to Store 2. Because of the directive, the engine does NOT reset `vTotalFailed`. It remains `1`.
5. **Parallel Merge**: If the engine spawns 4 parallel threads, and each thread accumulates its own count, `ACCUMULATEVAR` instructs the C-engine to execute a thread-safe mathematical merge (mutex lock) at the end of the calculation, perfectly combining the totals from all threads into the final variable.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Accumulation Declaration

```essbase
VAR vTotalStores = 0;
ACCUMULATEVAR vTotalStores;
```

---

## Practical Examples

### Example 1: Global Validation Counter

**Scenario**: An administrator runs an overnight data load. They have a script that checks every single store's `"Net_Income"`. If the Net Income is exactly `$0` (which implies the store failed to load data properly), they want to add `1` to a global counter. At the end of the script, they write the total number of failed stores into a corporate tracking metric called `"Data_Errors"`.

```essbase
/* 
   1. Declare the variable at the top of the script.
   2. Immediately elevate it to an accumulating global variable.
*/
VAR vErrorCount = 0;
ACCUMULATEVAR vErrorCount;

/* 
   3. Sweep all Level 0 Stores.
*/
FIX("FY25", "Working", @LEVEL0("Stores"))
    
    /* 
       4. Because of the block-calculation structure, we must bind the logic 
       to a specific anchor account (e.g., "Net_Income") so the engine evaluates it once per store.
    */
    "Net_Income" (
        IF("Net_Income" == 0)
            /* Accumulate the error */
            vErrorCount = vErrorCount + 1;
        ENDIF
    )
    
ENDFIX

/* 
   5. After the FIX is completely finished, we write the accumulated snowball 
   into the global Corporate entity. We use a targeted block creation statement.
*/
FIX("Corporate", "FY25", "Working")
    
    "Data_Errors" = vErrorCount;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `@` Prefix | `@ACCUMULATEVAR` | This is a calculation directive (like `SET CALCPARALLEL` or `CLEARBLOCK`), not a mathematical function. If you put an `@` symbol in front of it, the compiler will crash immediately |
| Placing it inside the `FIX` | Resetting the state | You MUST declare `VAR` and `ACCUMULATEVAR` at the absolute top of your script, BEFORE the `FIX` statement begins. If you put the declaration inside the `FIX`, the engine will execute the declaration command for every single block, continually resetting the variable and completely destroying the accumulation logic |
| Forgetting Block Binding | Over-counting | In Essbase, an `IF` statement inside a `FIX` (without being bound to a specific member) evaluates for *every single dense member in the block*. If your block has 50 accounts, `vCounter = vCounter + 1` will execute 50 times per store! You must bind the accumulation logic to a single anchor account (like `"Net_Income" ( IF... ) `) to ensure it only counts once per sparse intersection |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| `VAR` / `ARRAY` | The foundational commands used to declare the custom memory variables that `ACCUMULATEVAR` modifies |
| `SET CALCPARALLEL` | Often used in conjunction. `ACCUMULATEVAR` is explicitly designed to safely merge totals when parallel processing is active |

---

## Official Oracle Reference

- *(Oracle EPM Cloud Calculation Directives — ACCUMULATEVAR is a Calculation Manager specific directive that interfaces with the Essbase JVM).*
