# SET CALCPARALLEL

## Overview

`SET CALCPARALLEL` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls the multi-threading capabilities of the Essbase C-engine. By default, Essbase calculation scripts execute on a single thread (sequentially processing one block at a time). `SET CALCPARALLEL` allows you to override this and command the server to spawn multiple concurrent threads, drastically reducing calculation times for massive data sweeps.

### Why Does This Function Exist?

If a company has 10,000 Level-0 stores, and the script must execute a heavy allocation formula on every single one, a single-threaded server will calculate Store 1, finish, calculate Store 2, finish, etc. This might take 30 minutes.
Modern EPM Cloud servers possess massive multi-core CPUs. If the server has 8 cores sitting idle, why use only one?
`SET CALCPARALLEL 8;` commands the engine to split the 10,000 stores into 8 distinct chunks (tasks). It assigns one chunk to each CPU core. The cores calculate the stores simultaneously. The 30-minute calculation finishes in 4 minutes. This is the single most powerful performance optimization command available to an administrator.

### When to Use It

- **Massive Sparse Aggregations**: Firing parallel threads before an `AGG("Entity", "Product")` command to roll up massive, unconnected branches of the database simultaneously.
- **Global Allocations**: Running a top-down allocation algorithm across thousands of base-level cost centers in a fraction of the time.
- **Overnight Batches**: Standardizing parallel execution at the top of the nightly batch script to ensure the data is ready for users by morning.

---

## Category

**System & Optimization / Multithreading Directives / Calculation Commands**

---

## Syntax

```essbase
SET CALCPARALLEL n;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `n` | Integer | ✅ Yes | The exact number of concurrent threads (CPU cores) you want the engine to spawn. <br>- EPM Cloud standard limit is typically `2` to `8` depending on your server tier. <br>- To disable parallel calculation, set it to `1` or `0`. |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a value. It alters the internal thread-spawning behavior of the Essbase kernel.
- **Task Generation**: When the engine hits a `FIX` or `AGG`, it looks at the target blocks. If `CALCPARALLEL 4` is active, it attempts to mathematically divide the blocks into 4 independent queues.
- **Mutex Locks**: It automatically handles memory safety (mutex locking) if two threads attempt to write to the same upper-level parent simultaneously.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET CALCPARALLEL 4;`. It flags the JVM to allocate 4 thread pools for this specific script.
2. **Task Evaluation**: The engine hits `AGG("Entity")`. It analyzes the sparse tree. It sees 4 major regions (North, South, East, West).
3. **Distribution**: It assigns the North branch to Thread 1, South to Thread 2, etc.
4. **Concurrent Math**: The 4 threads execute the rollup math simultaneously.
5. **Merge**: Once all 4 threads finish their queues, the engine merges the results and moves to the next line in the script.

---

## Syntax Variants & Scenarios

### Variant 1: Activating 4-Core Parallelism

```essbase
/* 
   Placed at the top of the script. Instructs the engine to 
   use up to 4 threads for any calculations that follow.
*/
SET CALCPARALLEL 4;
```

---

## Practical Examples

### Example 1: High-Speed Nightly Rollup

**Scenario**: The nightly batch takes too long. The administrator notices the server CPU is barely hitting 15% utilization during the `AGG("Entity", "Product")` step. They add `SET CALCPARALLEL` to parallelize the sparse aggregations.

```essbase
/* 
   1. We activate 4 threads for the script.
*/
SET CALCPARALLEL 4;

FIX("Actual", "FY25", "Working")
    
    /* 
       2. The engine will automatically divide the Entity and Product 
       sparse block combinations into 4 concurrent task queues.
       The aggregation finishes 4x faster.
    */
    AGG("Entity", "Product");
    
ENDFIX

/* 
   3. We drop it back to 1 (single-threaded) at the end of the script 
   just as a safety measure for any complex sequential logic that might follow.
*/
SET CALCPARALLEL 1;
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Data Dependencies (Race Conditions) | Corrupted Math | If your script contains complex cross-dimensional pointers where Store B's calculation *relies* on the finished result of Store A (`"Store_B" = "Store_A" * 1.5;`), you CANNOT use parallel calculation. If Thread 2 calculates Store B *before* Thread 1 finishes Store A, Store B gets `#MISSING`. Parallel processing is only for isolated, independent blocks. If you have dependencies, you must use single-threaded mode |
| Exceeding Server Limits | No Performance Gain | Setting `CALCPARALLEL 128` on a standard EPM Cloud server will not make it 128x faster. EPM Cloud restricts thread usage based on your licensing tier (often capping at 2, 4, or 8 threads). The engine will simply ignore the massive number and cap it at the server maximum |
| Failing to define `CALCTASKDIMS` | Inefficient Threading | Essbase guesses how to divide the blocks based on the last Sparse dimension in the outline. If that dimension is very small, Essbase might not be able to generate enough "Tasks" to feed 8 threads. Thread 1 gets all the work, and Threads 2-8 do nothing. To ensure perfect parallelism, you must pair this command with `SET CALCTASKDIMS` to explicitly tell the engine which dimensions to use for task routing |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`SET CALCTASKDIMS`](./SET%20CALCTASKDIMS.md) | The required companion command. Tells the engine *how* to chop up the blocks so they can be fed to the parallel threads efficiently |
| `AGG` | The command that benefits the most from parallelization |
| `ACCUMULATEVAR` | Ensures custom runtime variables survive the multi-threaded merge process |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET CALCPARALLEL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_calcparallel.html)
