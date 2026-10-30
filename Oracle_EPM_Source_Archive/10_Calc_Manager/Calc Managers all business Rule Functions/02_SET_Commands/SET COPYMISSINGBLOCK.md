# SET COPYMISSINGBLOCK

## Overview

`SET COPYMISSINGBLOCK` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls the fundamental behavior of the `DATACOPY` command, specifically dictating whether the engine is allowed to create brand new, empty blocks when copying data from a source intersection to a destination intersection.

### Why Does This Function Exist?

The `DATACOPY` command (e.g., `DATACOPY "Actual" TO "Forecast"`) is heavily optimized. By default, Essbase only copies blocks that *already physically exist* in the destination. 
If `"Store_101"` has actuals, but the `"Forecast"` scenario for `"Store_101"` has never been used before, the Forecast block doesn't exist on the disk. By default, `DATACOPY` will skip it, meaning your Actuals will not copy over!
Essbase does this because creating millions of blocks takes time, and it assumes you only want to overwrite existing forecast data. 
If you *do* want Essbase to aggressively create brand new blocks in the destination so that 100% of the source data comes over, you must explicitly command it to do so using `SET COPYMISSINGBLOCK ON;`. 

### When to Use It

- **Scenario Seeding**: Copying the final `"Actual"` data into a brand new, empty `"Forecast"` scenario to serve as the baseline for the coming year.
- **New Entity Onboarding**: Copying baseline assumption drivers (like Tax Rates) from a `"Corporate_Default"` entity into a newly added, empty `"Store_500"` entity block.
- **Year-Over-Year Rollovers**: Rolling the final balances from `FY24` into the completely empty `FY25` blocks during the New Year initialization script.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET COPYMISSINGBLOCK ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `ON`: Forces `DATACOPY` to create brand new blocks in the destination if they don't exist (Slower, but guarantees 100% data transfer). <br>- `OFF`: Default behavior. `DATACOPY` only copies data if the destination block already physically exists (Fastest). |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a value. It alters the internal state of the `DATACOPY` processor for the duration of the script.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Block Generation**: When `ON`, it triggers the C-engine's internal Block Creation routines, which allocate physical memory on the disk for the destination sparse intersections before writing the copied data into them.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET COPYMISSINGBLOCK ON;`. It toggles the internal block-creation flag for the `DATACOPY` subroutine.
2. **Copy Trigger**: The engine hits `DATACOPY "Actual" TO "Forecast";`.
3. **Source Scan**: It finds data in `"Actual"->"Store_101"`.
4. **Destination Check**: It checks if `"Forecast"->"Store_101"` exists on the disk. It does not.
5. **Block Creation**: Because the flag is `ON`, the engine halts the copy, executes a disk-write to physically instantiate the new block for `"Forecast"->"Store_101"`, and then writes the copied Actual data into it.

---

## Syntax Variants & Scenarios

### Variant 1: Forcing Block Creation for Seeding

```essbase
/* 
   Placed before a DATACOPY command to ensure brand new 
   forecast blocks are generated on the disk.
*/
SET COPYMISSINGBLOCK ON;
```

---

## Practical Examples

### Example 1: Seeding the New Year Forecast

**Scenario**: On January 1st, the administrator runs a script to copy the Final Actuals of FY24 into the Working Forecast of FY25. Because FY25 is a brand new year, no users have submitted data yet; the entire FY25 slice of the database is completely empty (no blocks exist). If they run standard `DATACOPY`, absolutely nothing will happen. They must use `COPYMISSINGBLOCK ON`.

```essbase
/* 
   1. We force the engine to create new blocks during the copy.
*/
SET COPYMISSINGBLOCK ON;

/* 
   2. Fix on the specific accounts and entities we want to seed.
*/
FIX("Total_Accounts", @LEVEL0("Entity"), "Working")
    
    /* 
       3. We execute a complex cross-dimensional copy.
       Actual->FY24 is pushed to Forecast->FY25.
       Because of the SET command, Essbase will aggressively 
       create millions of new blocks for FY25 to hold the data.
    */
    DATACOPY "Actual"->"FY24" TO "Forecast"->"FY25";
    
ENDFIX

/* 
   4. It is best practice to turn it back off to protect 
   subsequent copies in the script.
*/
SET COPYMISSINGBLOCK OFF;
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding the Name | It does NOT copy `#MISSING` data | A very common misconception is that this command dictates whether `#MISSING` (empty) cells are copied over. It does NOT. `DATACOPY` never copies `#MISSING`. The command is literally named "Copy to a Missing BLOCK". It means "Create a block if it is missing." It is about structural block creation, not empty data replication |
| Leaving it `ON` permanently | Block Explosion and Massive Sluggishness | Block creation is the most expensive operation in Essbase. If you leave this `ON` permanently, and run massive `DATACOPY` statements across entire scenarios, you might accidentally create 500 million empty blocks, exploding the database size and crashing the server. ONLY turn it `ON` immediately before a specific seeding operation, and turn it `OFF` immediately after |
| Using `@` Prefix | `@SET COPYMISSINGBLOCK` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash immediately |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| `DATACOPY` | The primary data replication command that completely relies on this directive for block generation |
| [`SET CREATEBLOCKONEQ`](./SET%20CREATEBLOCKONEQ.md) | The equivalent directive, but specifically designed to control block creation for standard equations (`A = B`) rather than `DATACOPY` |
| `SET CREATENONMISSINGBLK` | Another variant of block creation control, often used with dense/sparse formula calculations |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET COPYMISSINGBLOCK](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_copymissingblock.html)
