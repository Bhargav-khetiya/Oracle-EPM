# 15 — Fragmentation, Defragmentation, & Corruption Recovery

---

## 15.1 The Physics of Fragmentation in `.PAG` Files

In an Oracle Essbase BSO database, data is stored in **Page files (`.PAG`)** as compressed binary blocks. While reading blocks is sequential and fast, frequent data entry, batch data loading, and calculation scripts cause **physical file fragmentation**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        HOW FRAGMENTATION OCCURS                        │
├────────────────────────────────────────────────────────────────────────┤
│ 1. INITIAL STATE:                                                      │
│    Block A is written to .PAG file: Size = 3 KB (Compressed)           │
│    [.PAG File Offset 0000: Block A (3 KB)]                             │
│                                                                        │
│ 2. USER ENTERS ADDITIONAL DATA:                                        │
│    User inputs data into 5 additional months in Block A.               │
│    Block A is recompressed in Data Cache: New Size = 5 KB              │
│                                                                        │
│ 3. THE HOLE (FRAGMENTATION):                                           │
│    Block A (5 KB) CANNOT fit into the original 3 KB slot on disk!      │
│    • Essbase marks the old 3 KB slot as "FREE SPACE" (a "Hole").       │
│    • Essbase writes the 5 KB Block A to the END of the .PAG file.      │
│    • The old 3 KB slot remains unused and empty.                       │
│                                                                        │
│ 4. OVER TIME:                                                          │
│    Thousands of block updates create gigabytes of uncompacted "holes". │
│    .PAG file grows to 12 GB, even though real data is only 3 GB!       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 15.2 Measuring Fragmentation

You can measure database fragmentation in Essbase Administration Services (EAS), MaxL, or Planning Application Diagnostics:

### Key Metrics to Examine:
1. **`Average Compression Ratio`**: Compares uncompressed block size to disk storage.
2. **`Page File Size vs. Estimated Real Data Size`**:
   $$\text{Fragmentation \%} = \left(1 - \frac{\text{Actual Blocks} \times \text{Avg Compressed Size}}{\text{Total .PAG Files Size}}\right) \times 100\%$$
3. *Threshold*: If Fragmentation exceeds **30% – 40%**, performance suffers because disk heads must jump over fragmented gaps during query retrieval.

---

## 15.3 Defragmentation Strategies

There are two primary methods to defragment an Essbase database:

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│       METHOD 1: FORCED RESTRUCTURE   │       METHOD 2: EXPORT / CLEAR / LOAD│
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Fast, automated administrative fix.│ • The Gold Standard of Cube Health.  │
│ • Rewrites .PAG files from scratch.  │ • Purges all fragmented space.       │
│ • Eliminates all free-space holes.   │ • Rebuilds clean B-tree index .IND.  │
│ • Execution Time: 5 - 15 minutes.    │ • Execution Time: 30 - 60 minutes.   │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

### Method 1: Forced Restructure (via MaxL):
```sql
/* Force Essbase to read all blocks and rewrite contiguous .PAG files */
alter database 'FinPlan'.'FinPlan' force restructuring;
```

### Method 2: Export $\rightarrow$ Clear $\rightarrow$ Reload (The Gold Standard):
1. **Export Level 0 Data**:
   ```sql
   export database 'FinPlan'.'FinPlan' level0 data to data_file 'C:\Backups\FinPlan_L0.txt';
   ```
2. **Clear All Data**:
   ```sql
   alter database 'FinPlan'.'FinPlan' reset;
   ```
3. **Reload Data File**:
   ```sql
   import database 'FinPlan'.'FinPlan' data from data_file 'C:\Backups\FinPlan_L0.txt';
   ```
4. **Run Aggregation**:
   ```sql
   execute calculation 'FinPlan'.'FinPlan'.'AGG_ALL';
   ```
* *Result*: Disk footprint typically shrinks by **50% to 75%**, and query speeds improve dramatically.

---

## 15.4 Index File (`.IND`) Corruption & Recovery

The **`.IND` (Index)** file contains the balanced B-tree mapping sparse member combinations to their byte offsets inside `.PAG`.

### Causes of Corruption:
* Server power failure or unexpected reboot during an active calculation.
* Hard kill of the `ESSSVR` process (`kill -9` or Task Manager termination).
* Operating system disk full error while writing index pages.

### Symptoms:
* **Error 1008106**: `Exception error in Essbase kernel during index lookup`.
* Data previously entered disappears or reappears inconsistently.
* Essbase crashes when a specific department or entity is queried.

### Recovery Procedure:
1. Stop the database.
2. If using Oracle EPM Cloud: Run **Cube Refresh** with **Rebuild Outline** selected.
3. If using on-premise Essbase:
   * Delete or rename the corrupted `appname.ind` file.
   * Perform an **Outline-driven restructure**; Essbase will scan the existing `.PAG` files, extract the block headers, and reconstruct a fresh `.IND` B-tree from the physical page blocks!
