# 02 Block Creation, SET CREATEBLOCKONEQ, and Database Size Explosion

## 1. The Block Storage Reality: Sparse Memory Allocation

In Essbase Block Storage (BSO) architecture, data is physically stored in 64KB–256KB multidimensional arrays called **Blocks**. A block exists on disk only if at least one numeric data cell within that sparse coordinate intersection contains a non-missing value.

If a calculation formula attempts to write a calculated value to a coordinate whose sparse combination does not exist, the Essbase kernel faces a fundamental dilemma: **it cannot store a cell without creating the entire underlying physical block**.

```
+---------------------------------------------------------------------------------------------------+
|                                 SPARSE BLOCK CREATION MECHANISMS                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  1. DIRECT DATA ENTRY (Web Form / Smart View / Data Load):                                        |
|     - User enters $100 into empty intersection.                                                   |
|     - Essbase allocates block header in .ind file, formats dense array in .pag file.              |
|                                                                                                   |
|  2. DATACOPY COMMAND:                                                                             |
|     - DATACOPY "Working" TO "Forecast";                                                           |
|     - Automatically creates matching target blocks by cloning existing source blocks.             |
|                                                                                                   |
|  3. FORMULA ASSIGNMENT WITH 'SET CREATEBLOCKONEQ ON':                                             |
|     - SET CREATEBLOCKONEQ ON;                                                                     |
|     - Target = Source * Driver;                                                                   |
|     - If Target sparse block is missing, Essbase formats and writes a new block to disk.          |
|                                                                                                   |
|  4. FORMULA ASSIGNMENT WITH 'SET CREATEBLOCKONEQ OFF' (DEFAULT):                                  |
|     - Target = Source * Driver;                                                                   |
|     - If Target sparse block is missing, CALCULATION IS SILENTLY SKIPPED! Data is not written.    |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. The Danger of Uncontrolled Block Explosion

Enabling `SET CREATEBLOCKONEQ ON;` without strict multidimensional boundaries (FIX statements) is the number one cause of **catastrophic database size explosion** in Hyperion/EPM environments.

### Mathematical Proof of Block Explosion:
* Application Dimensions:
  * Entity: Sparse ($2,000$ members)
  * Department: Sparse ($500$ members)
  * Product: Sparse ($1,000$ members)
  * Total Potential Sparse Combinations: $2,000 \times 500 \times 1,000 = \mathbf{1,000,000,000 \text{ combinations}}$
* Active Blocks with Real Data: **$10,000 \text{ blocks}$** (Database size: $\approx 150 \text{ MB}$).

#### The Erroneous Calculation Script:
```sql
/* Unbounded sparse calculation with block creation enabled */
SET CREATEBLOCKONEQ ON;

FIX("Forecast", "FY25", "Working")
  /* Notice: Missing FIX on Entity, Department, and Product! */
  "Allocated_Overhead" = "Corporate_Pool" * 0.001;
ENDFIX
```

#### The Aftermath:
* Essbase attempts to evaluate all $1,000,000,000$ combinations.
* It instantiates hundreds of thousands of new 64KB blocks populated with negligible or zero numbers.
* Database explodes from **$150 \text{ MB}$ to over $35 \text{ GB}$ in 10 minutes**!
* Disk space exhausts, backup snapshots fail, and subsequent aggregations slow down by $50\times$.

---

## 3. Best Practices for Safe Block Creation

1. **Always Keep `SET CREATEBLOCKONEQ OFF` by Default**: Enable it strictly within an isolated, tightly-scoped FIX statement where block creation is mathematically intended.
2. **Prefer `DATACOPY` to Seed Blocks**: Before calculating new targets, use `DATACOPY` to establish the exact sparse block structure, then calculate using Bottom-Up mode with `CREATEBLOCKONEQ OFF`.
3. **Automate Empty Block Purges**: Embed `CLEARBLOCK EMPTY;` into weekly maintenance scripts to eliminate blocks where all cells have reverted to `#MISSING`.

