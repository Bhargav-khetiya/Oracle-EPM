# SET IGNORECONSTANTS

## Overview

`SET IGNORECONSTANTS` is a **specialized Essbase calculation directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls how the calculation engine optimizes blocks that contain nothing but constant equations or raw numeric data loads. Specifically, it dictates whether the engine should aggressively skip processing mathematical formulas on blocks where the data is entirely derived from hardcoded constants rather than dynamic dimensional references.

### Why Does This Function Exist?

When the Essbase compiler reads a script, it analyzes the equations to build an execution path.
If an equation is `"Sales" = "Units" * 10;`, Essbase knows it must evaluate the block, look up `"Units"`, multiply by 10, and write to `"Sales"`. 
However, if an equation is `"Sales" = 500;`, Essbase recognizes that this is a "Constant". It doesn't depend on any other data in the block. 
Historically, if Essbase saw a block that *only* contained constants, it would sometimes optimize the block heavily, or even skip standard formula passes on it, assuming the data was static and didn't need complex re-evaluation. 
`SET IGNORECONSTANTS OFF` is a safety override. It forces the engine to disable these hyper-aggressive static optimizations. It tells the engine: "Do not assume this block is simple just because it contains constants. Treat every equation, even constant ones, as a full mathematical operation that must be processed normally."

### When to Use It

- **Legacy Script Migrations**: Ensuring calculation consistency when migrating massive legacy scripts from older On-Premise Essbase versions (where constant optimization behaved differently) to modern EPM Cloud.
- **Complex Block Seeding**: Forcing the engine to properly register and calculate newly created blocks that were initialized entirely using constant equations (e.g., `SET CREATEBLOCKONEQ ON`).
- **Debugging Optimization Failures**: Turning optimizations off temporarily to determine if the C-engine's internal parsing algorithm is accidentally skipping blocks that need to be evaluated.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET IGNORECONSTANTS ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `OFF`: Disables constant optimization. Forces the engine to fully evaluate and process constant equations normally (Safest). <br>- `ON`: Allows the engine to use its internal algorithms to optimize or skip constant blocks (Fastest, Default). |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a numeric value. It alters the internal parsing and optimization algorithms of the C-engine compiler.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET IGNORECONSTANTS OFF;`. It sends an interrupt to the C-engine's formula parser, disabling the static-value optimization flag.
2. **Formula Parsing**: The engine evaluates the script: `"Setup_Fee" = 1000;`.
3. **Execution**: Because the flag is `OFF`, the engine does not attempt to aggressively optimize or bypass the block. It fully loads the block into memory, treats `1000` as a standard mathematical evaluation, writes the data to the block, and processes it normally.

---

## Syntax Variants & Scenarios

### Variant 1: Disabling Constant Optimizations

```essbase
/* 
   Placed at the top of a highly specific block-seeding script 
   to ensure the constants are evaluated properly.
*/
SET IGNORECONSTANTS OFF;
```

---

## Practical Examples

### Example 1: Seeding a New Scenario with Constants

**Scenario**: The administrator needs to initialize a brand new `"Sandbox"` scenario. They want every active store to start with exactly `$10,000` in `"Opening_Cash"`. To ensure the engine doesn't attempt to optimize away the constant seeding (which sometimes happens in highly complex sparse matrixes), they turn the optimization off.

```essbase
/* 
   1. Disable constant optimization to guarantee execution.
*/
SET IGNORECONSTANTS OFF;

/* 
   2. Enable block creation for the equation so the empty Sandbox receives the data.
*/
SET CREATEBLOCKONEQ ON;

FIX("Sandbox", "FY25", @LEVEL0("Entity"))
    
    /* 
       3. Seed the constant. 
       Because IGNORECONSTANTS is OFF, the engine treats this as a full calculation pass.
    */
    "Opening_Cash" = 10000;
    
ENDFIX

/* 
   4. Revert settings to default.
*/
SET CREATEBLOCKONEQ OFF;
SET IGNORECONSTANTS ON;
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it for Variables | Misunderstanding "Constants" | A constant is a hardcoded raw number (`500`). A cross-dimensional pointer (`"Sales"->"USA"`) is NOT a constant. A substitution variable (`&TargetVal`) is evaluated at compile time and becomes a constant. Do not confuse this command with variable processing or dynamic dependencies |
| Performance Degradation | Unnecessary Disabling | Modern EPM Cloud Essbase engines are incredibly smart. They optimize constant blocks perfectly 99% of the time. If you blindly throw `SET IGNORECONSTANTS OFF;` at the top of every script, you are disabling a powerful background optimization for absolutely no reason, making your scripts slower. Only use this command if you are actively troubleshooting a block-seeding failure where constant data is inexplicably disappearing |
| Using `@` Prefix | `@SET IGNORECONSTANTS` | This is a calculation macro. It is not a mathematical function. If you put an `@` symbol in front of it, the compiler will crash immediately |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`SET CREATEBLOCKONEQ`](./SET%20CREATEBLOCKONEQ.md) | Often paired with this directive. `CREATEBLOCKONEQ` physically creates the block for the constant, while `IGNORECONSTANTS OFF` ensures the formula engine evaluates the constant correctly |
| [`SET CREATENONMISSINGBLK`](./SET%20CREATENONMISSINGBLK.md) | The data-driven equivalent of block creation |

---

## Official Oracle Reference

- *(Oracle EPM Cloud Calculation Directives — SET IGNORECONSTANTS is an advanced optimization toggle primarily documented in legacy Essbase DBAG manuals).*
