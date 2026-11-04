# SET CALCTASKDIMS

## Overview

`SET CALCTASKDIMS` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It is the mandatory companion command to `SET CALCPARALLEL`. While `CALCPARALLEL` tells the server *how many* threads to spawn, `SET CALCTASKDIMS` tells the server **how to chop up the database** into discrete "tasks" to feed those threads evenly. 

### Why Does This Function Exist—

When you turn on `SET CALCPARALLEL 4`, Essbase has to divide the calculation workload into at least 4 chunks (tasks) so it can hand one chunk to each thread.
By default, Essbase looks at the very last Sparse dimension in your outline (e.g., `"Scenario"`). It creates one task for every member in that dimension. 
If `"Scenario"` only has 2 members (`"Actual"`, `"Forecast"`), Essbase can only create 2 tasks. Even if you asked for 4 threads, 2 threads will get work, and 2 threads will sit completely idle. Your performance will suffer.
`SET CALCTASKDIMS` overrides this default behavior. It allows you to specify a massive Sparse dimension (like `"Entity"` or `"Product"`) to act as the "Task Router". If `"Entity"` has 10,000 members, Essbase chops the workload into 10,000 independent tasks. The 4 threads will aggressively consume those tasks from the queue, ensuring 100% CPU utilization and maximum performance.

### When to Use It

- **Optimizing Parallel Execution**: Forcing the engine to use a deeply populated sparse dimension as the task router to guarantee that all spawned CPU threads receive enough work.
- **Preventing Bottlenecks**: Overriding the default task routing if the final sparse dimension in the outline is structurally small (like `Version` or `Scenario`).
- **Complex Aggregations**: Specifying multiple sparse dimensions (e.g., `CALCTASKDIMS 2`) to create millions of micro-tasks for massive, multi-dimensional `AGG` sweeps.

---

## Category

**System & Optimization / Multithreading Directives / Calculation Commands**

---

## Syntax

```essbase
SET CALCTASKDIMS n;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `n` | Integer | ✅ Yes | The number of Sparse dimensions (counting backwards from the end of the outline) to use for task generation. <br>- Default is `1` (uses only the very last sparse dimension). <br>- Setting to `2` uses the last two sparse dimensions. |

*(Alternative Syntax): EPM Cloud also supports explicitly naming the dimensions: `SET CALCTASKDIMS(DimName1, DimName2);` which is much safer and more robust than counting backwards.*

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a value. It alters the internal task-queuing algorithm of the Essbase C-engine.
- **Task Queue Saturation**: It ensures the internal multi-threading queue is saturated with enough discrete jobs so that no CPU core goes idle during the calculation block.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET CALCTASKDIMS("Entity");` alongside `SET CALCPARALLEL 4;`.
2. **Task Matrix Generation**: The engine looks at the `"Entity"` dimension. It sees 10,000 stores. It builds an internal queue of 10,000 calculation tasks (one for each store).
3. **Queue Distribution**: Thread 1 takes Task 1. Thread 2 takes Task 2. Thread 3 takes Task 3. Thread 4 takes Task 4.
4. **Saturation Execution**: Because there are 10,000 tasks, the moment a thread finishes a store, it instantly grabs the next available store from the queue. All 4 cores run at 100% capacity until the queue hits 0.

---

## Syntax Variants & Scenarios

### Variant 1: Explicit Dimension Routing (Recommended)

```essbase
/* 
   Explicitly tells the engine to chop the workload up based on the 
   Product and Entity dimensions, ignoring whatever the last dimension is.
*/
SET CALCTASKDIMS("Entity", "Product");
```

### Variant 2: Numeric Backward Routing (Legacy)

```essbase
/* 
   Tells the engine to look at the outline, start at the bottom, 
   and use the bottom 3 Sparse dimensions to chop up the workload.
*/
SET CALCTASKDIMS 3;
```

---

## Practical Examples

### Example 1: Guaranteeing 100% Core Utilization

**Scenario**: A script uses `SET CALCPARALLEL 4` to aggregate the database. However, the last Sparse dimension in the outline is `"Version"`, which only has 1 member in the `FIX` (`"Working"`). Essbase only creates 1 task. 3 CPU cores do nothing. The aggregation takes 20 minutes. The administrator adds `CALCTASKDIMS` to force the routing to use the `"Entity"` dimension (which has 5,000 members).

```essbase
/* 
   1. Activate 4 threads.
*/
SET CALCPARALLEL 4;

/* 
   2. Force Essbase to chop the workload into 5,000 tasks based on the Entity tree.
*/
SET CALCTASKDIMS("Entity");

FIX("Actual", "FY25", "Working")
    
    /* 
       3. The engine feeds the 5,000 tasks evenly to the 4 threads. 
       The aggregation finishes in 4 minutes instead of 20.
    */
    AGG("Entity", "Product");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using Dense Dimensions | Syntax Error | You CANNOT use Dense dimensions (like `Account` or `Time`) as task routers. A calculation "Task" in Essbase is fundamentally a sparse block execution. If you try to write `SET CALCTASKDIMS("Account")`, the compiler will either throw an error or silently ignore it, returning to the default single sparse router |
| Too Many Task Dimensions | Memory Overhead | While having too few tasks leaves threads idle, having *too many* tasks destroys RAM. If you write `SET CALCTASKDIMS 6` on a massive database, Essbase might try to create a queue of 5 Billion micro-tasks. The server will run out of RAM and crash before the calculation even starts. Only provide enough dimensions to generate between 1,000 and 100,000 tasks |
| Forgetting `CALCPARALLEL` | No Effect | `CALCTASKDIMS` does absolutely nothing if the server is running on a single thread. You must pair it with `SET CALCPARALLEL n` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`SET CALCPARALLEL`](./SET%20CALCPARALLEL.md) | The required companion command that actually spawns the threads that consume the tasks |
| `AGG` | The primary aggregation command that relies on optimized task routing to run efficiently |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET CALCTASKDIMS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_calctaskdims.html)
