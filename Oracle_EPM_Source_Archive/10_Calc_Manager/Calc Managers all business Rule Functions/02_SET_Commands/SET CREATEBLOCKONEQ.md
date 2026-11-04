# SET CREATEBLOCKONEQ

## Overview

`SET CREATEBLOCKONEQ` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls the fundamental behavior of the Essbase calculation engine regarding the creation of empty Sparse blocks when evaluating standard mathematical equations (`A = B`). 

### Why Does This Function Exist—

By default, Essbase uses a "Bottom-Up" calculation methodology that is completely dependent on existing data. If you write the formula `"Commission" = "Sales" * 0.10;`, Essbase scans the database for blocks that already exist. If `"Store_101"` has `$100` of sales, the block exists. Essbase calculates the commission and writes `$10` into the block. 
But what if the equation is a constant— `"Tax_Rate" = 0.25;`. 
Because `"Tax_Rate"` doesn't rely on existing data (it's a hardcoded equation), Essbase doesn't know where to put it. By default, Essbase will ONLY write `0.25` into blocks that *already exist* on the disk (e.g., stores that already have sales data). If a store is brand new and has no data, its block doesn't exist, so it gets no Tax Rate.
If you explicitly want Essbase to aggressively create brand new blocks for EVERY SINGLE store in the scope of the `FIX` statement, just to hold that constant `0.25`, you must use `SET CREATEBLOCKONEQ ON;`. 

### When to Use It

- **Seeding Constants**: Distributing a flat corporate tax rate, standard discount rate, or inflation driver across a massive sparse dimension where many of the members do not yet have data blocks.
- **Top-Down Allocations to Empty Nodes**: Forcing an allocation payload into a target member that has never received data before (e.g., allocating "Corporate Overhead" to a brand new product line).
- **Targeted Equation Seeding**: Creating specific anchor blocks to serve as the foundation for complex future `DATACOPY` or dynamic calculation queries.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET CREATEBLOCKONEQ ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `ON`: Forces the engine to create brand new blocks for the target of an equation (`Left_Side = Right_Side`) if the block doesn't exist. <br>- `OFF`: Default behavior. The equation will only execute and store data if the block already physically exists on the disk. |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a value. It alters the internal state of the Block Generation processor.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Performance Impact**: When set to `ON`, it forces the engine to evaluate every single possible sparse intersection defined in the active `FIX` statement. If the `FIX` contains 1,000,000 potential intersections, Essbase will attempt to create 1,000,000 blocks, severely degrading performance.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET CREATEBLOCKONEQ ON;`. It toggles the block-creation flag for standard equations.
2. **Execution Trigger**: The engine hits `"Driver" = 500;`.
3. **Scope Check**: It looks at the `FIX` statement (e.g., `FIX("Store_101", "Store_102")`).
4. **Target Scan**: It checks if `"Store_101"` has a block. It does not.
5. **Block Generation**: Because the flag is `ON`, the engine halts, allocates physical memory on the disk for a brand new `"Store_101"` block, and writes `500` into it. It repeats this for `"Store_102"`.

---

## Syntax Variants & Scenarios

### Variant 1: Forcing Constant Seeding

```essbase
/* 
   Placed before a constant equation to ensure blocks are created.
*/
SET CREATEBLOCKONEQ ON;
```

---

## Practical Examples

### Example 1: Distributing a New Regional Driver

**Scenario**: A company opens 50 new cost centers in `"Region_West"`. These cost centers are brand new; they have zero historical data, and therefore no blocks exist on the server. The administrator needs to seed a `$500` `"Setup_Budget"` into every single one of them. If they use a standard equation, it will fail because the blocks don't exist. They must use `CREATEBLOCKONEQ ON`.

```essbase
/* 
   1. We force the engine to aggressively create blocks for equations.
*/
SET CREATEBLOCKONEQ ON;

/* 
   2. We FIX explicitly on the new Region's Level 0 children.
*/
FIX("Working", "FY25", "Setup_Budget", @LEVEL0("Region_West"))
    
    /* 
       3. The equation is a constant (Left Side = Right Side).
       Because of the SET command, Essbase will iterate through all 
       50 new cost centers, physically create 50 brand new blocks 
       on the disk, and write $500 into each one.
    */
    "Setup_Budget" = 500;
    
ENDFIX

/* 
   4. It is critical to turn it OFF immediately. If we leave it ON, 
   a later equation like "Sales" = "Units" * "Price" might accidentally 
   create millions of empty blocks.
*/
SET CREATEBLOCKONEQ OFF;
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Leaving it `ON` permanently | Massive Block Explosion | This is one of the most dangerous commands in Essbase. If you write `FIX(@LEVEL0("Entity"), @LEVEL0("Product"))` and execute an equation with `CREATEBLOCKONEQ ON`, Essbase will attempt to create a block for EVERY SINGLE STORE and EVERY SINGLE PRODUCT. If you have 1,000 stores and 10,000 products, it will try to create 10,000,000 blocks instantly. Your server will crash. ALWAYS use a hyper-targeted `FIX` statement before turning this `ON`, and turn it `OFF` immediately after the specific line of code that requires it |
| Using it for `DATACOPY` | Wrong Command | `CREATEBLOCKONEQ` only controls standard equations (`A = B`). If you are trying to force block creation for a `DATACOPY` command (`DATACOPY A TO B`), this command will do nothing. You must use `SET COPYMISSINGBLOCK ON;` for data replication |
| Expecting it to work on Dense Dimensions | Sparse Only | This command strictly dictates whether a physical *Block* (Sparse intersection) is created. If your equation is targeting a Dense dimension member, the block already exists (it just has `#MISSING` inside that specific cell). This command has no relevance to Dense dimension math |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`SET CREATENONMISSINGBLK`](./SET%20CREATENONMISSINGBLK.md) | A modern, much safer alternative that forces block creation based on the existence of data on the *Right Side* of the equation, rather than blindly creating blocks for everything in the `FIX` |
| [`SET COPYMISSINGBLOCK`](./SET%20COPYMISSINGBLOCK.md) | The equivalent directive used exclusively for `DATACOPY` commands |
| `DATAEXPORT` | Often used after block creation to ensure the newly minted constant data pushes cleanly to downstream systems |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET CREATEBLOCKONEQ](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_createblockoneq.html)
