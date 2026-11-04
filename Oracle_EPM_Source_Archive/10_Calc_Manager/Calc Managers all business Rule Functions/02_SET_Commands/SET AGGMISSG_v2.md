# SET AGGMISSG

## Overview

`SET AGGMISSG` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls how the calculation engine handles empty (`#MISSING`) blocks during sparse dimension aggregations (using the `AGG` or `CALC DIM` commands). It toggles whether the engine should aggressively attempt to aggregate missing children up to their parents, or whether it should completely ignore them.

*(Note: The default behavior in modern Essbase depends on the underlying server configuration, but it is overwhelmingly recommended to explicitly set this command at the top of every calculation script to guarantee predictable block behavior).*

### Why Does This Function Exist—

When Essbase rolls up a sparse dimension (like `"Entity"`), it has a choice. If `"Store_A"` has no data (`#MISSING`), does Essbase load the empty block into memory, do the math (`0 + 0`), and create a `#MISSING` parent block— 
If `AGGMISSG` is `ON`, Essbase will literally roll up `#MISSING` data. If you have 10,000 stores, and only 5 of them have data, Essbase will still create upper-level blocks for the parents of the 9,995 empty stores. This causes catastrophic **Block Explosion**, severely inflating the size of the database on disk and crippling aggregation performance.
If `AGGMISSG` is `OFF`, Essbase completely ignores `#MISSING` blocks. It only rolls up the 5 stores that actually have data, skipping the dead branches entirely. This makes the aggregation lightning fast.

### When to Use It

- **Standard Aggregation (`ON / OFF`)**: Almost universally set to `OFF` at the top of calculation scripts to prevent block explosion and ensure high-speed rollups.
- **Data Clearances (`ON`)**: Explicitly set to `ON` immediately before running a script that wipes data out of the database. If you clear data at Level 0, and then roll up with `OFF`, the parent blocks won't realize the children were deleted (because the children are now `#MISSING` and ignored). Setting it to `ON` forces the `#MISSING` status to roll up to the parents, properly clearing the upper levels.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET AGGMISSG ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `OFF`: Instructs the engine to ignore `#MISSING` blocks during aggregation (Fastest). <br>- `ON`: Instructs the engine to roll `#MISSING` blocks up the tree (Slowest, but required for data clearances). |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a value. It alters the internal state of the `AGG` and `CALC DIM` processors for the duration of the script.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Persistence**: The setting dies the moment the script finishes. It does not permanently alter the database server settings.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET AGGMISSG OFF;`. It sends an interrupt to the C-engine's index scanner, toggling the `SKIP_MISSING_BLOCKS` flag to TRUE.
2. **Aggregation Trigger**: Later in the script, the engine hits `AGG("Entity")`.
3. **Index Sweep**: The engine scans the Level 0 Entity blocks.
4. **Flag Enforcement**: Because the flag is active, any block that has no physical presence on the disk (or is marked as completely `#MISSING`) is instantly skipped. The engine doesn't even load it into RAM.
5. **Rollup**: It only performs math on the blocks that physically exist, creating parent blocks only where necessary.

---

## Syntax Variants & Scenarios

### Variant 1: Standard High-Speed Rollup

```essbase
/* 
   Placed at the absolute top of the script to protect against block explosion.
*/
SET AGGMISSG OFF;
```

---

## Practical Examples

### Example 1: The "Clear and Aggregate" Trap

**Scenario**: A user makes a mistake and loads $1,000,000 into `"Store_101"`. The nightly batch runs and aggregates it up to `"New_York"`. The next day, the admin writes a script to clear `"Store_101"` to fix the mistake. If they run the clear script with `AGGMISSG OFF`, the Level 0 data will clear, but `"New_York"` will still show $1,000,000 because the empty Level 0 block was ignored during the rollup! The admin must use `AGGMISSG ON` to force the clearance to bubble up.

```essbase
/* 
   1. The Admin forces the engine to aggregate missing blocks.
*/
SET AGGMISSG ON;

/* 
   2. Fix on the bad store and wipe the data.
*/
FIX("Store_101", "Actual", "FY25")
    CLEARBLOCK ALL;
ENDFIX

/* 
   3. We aggregate the Entity dimension.
   Because AGGMISSG is ON, Essbase sees that Store 101 is now empty.
   It rolls that "emptiness" up to New York, successfully subtracting 
   the $1,000,000 from the parent block and fixing the database.
*/
AGG ("Entity");

/* 
   4. It is best practice to turn it back off before the script ends 
   so subsequent calculations in the script run fast.
*/
SET AGGMISSG OFF;
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Leaving it `ON` permanently | Crippled Performance | If you leave `SET AGGMISSG ON;` at the top of a nightly batch script, your 5-minute aggregation might suddenly take 4 hours. It forces Essbase to do the math for every single empty cell in the database. Only turn it `ON` when explicitly necessary for data clearances or highly specific block-creation logic. Otherwise, it should always be `OFF` |
| Using `@` Prefix | `@SET AGGMISSG` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash immediately |
| Assuming it clears Dense data | Sparse Only | `AGGMISSG` specifically dictates how *Blocks* (Sparse intersections) roll up. If you clear data in a Dense dimension (e.g., `"Account"`), you do not need `AGGMISSG ON` to roll it up, because the block still exists; it just has a 0 inside it. `AGGMISSG` is strictly for Sparse dimension block hierarchies |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`AGG`](../03_Calc_Commands/AGG.md) | The primary aggregation command that consumes the `AGGMISSG` directive |
| [`CALC DIM`](../03_Calc_Commands/CALC DIM.md) | The targeted aggregation command that also obeys this directive |
| `CLEARBLOCK` | The data clearance command that usually necessitates turning `AGGMISSG` `ON` temporarily |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET AGGMISSG](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_aggmissg.html)
