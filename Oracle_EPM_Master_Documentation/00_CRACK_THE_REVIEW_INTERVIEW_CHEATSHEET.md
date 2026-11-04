# 00: Emergency Technical Review Cheat Sheet — Fresher to FTE Conversion Kit

> [!IMPORTANT]
> **Purpose of this Document**: This is your rapid-recall, zero-fluff interview survival guide. Senior Oracle EPM Architects and Review Panels do not test textbook definitions; they ask **twisted scenario questions, edge-case traps, and operational failure diagnoses** to see if you have true hands-on understanding. Master these 50 core rules, traps, and answers cold.

<!-- ===================================================================== -->
<!-- 📊 LIVE INTERACTIVE VISUAL CARD: TOP 10 GOLDEN LAWS QUICK NAVIGATOR -->
<!-- ===================================================================== -->
<details open>
<summary><b>📊 Live Interactive Architecture Card: Top 10 Golden Laws & Rapid Recall (Click to Collapse / Expand)</b></summary>

<br/>

> [!TIP]
> **Interactive Standalone Dashboard:** Open [`card_00_cheatsheet.html`](interactive_cards/card_00_cheatsheet.html) in your browser for a live interactive filterable search card!

| # | Core Concept | Physical Engine Mechanism | Consultant Golden Rule |
|---|---|---|---|
| **1** | **Evaluation Order vs Solve Order** | UI Data Type vs Essbase Math (0–127) | Set `Account` to Rank 1 in Evaluation Order; higher Solve Order calculates LAST and wins. |
| **2** | **Implied Sharing & Security** | Single-child parent = memory alias pointer | Tag single-child parents with `Never Share` or use Hybrid Dynamic Calc (`~`). |
| **3** | **Single-to-Multi Child Evolution** | 2nd child breaks implied share | Adding a child instantiates stored block; historical reports show `#Missing` without re-calc. |
| **4** | **Grid Spread with Locked Cells** | Proportional spread excludes locked cells | Parent total = User Input + Locked Historical values. |
| **5** | **Solve Order Collision** | Multi-dimensional dynamic calc priority | Ratios (`Margin %` = 10) &rarr; Variances (`Variance %` = 20) &rarr; Cross-dim KPIs (30). |
| **6** | **Two-Pass Calculation Fallacy** | $\sum A/B \neq \sum A / \sum B$ | Ratios cannot be summed. Two-Pass (Accounts & Time only) or Solve Order re-evaluates. |
| **7** | **Block Explosion (`CREATENONMISSINGBLK`)** | Cartesian product block instantiation | Purge with `CLEARBLOCK EMPTY;`. Always ensure `SET CREATENONMISSINGBLK OFF;`. |
| **8** | **Source Cube Property** | Multi-cube formula syntax isolation | Wrap formulas in `<PlanType>` blocks to prevent Database Refresh compilation aborts. |
| **9** | **ASO Slice Merging & Zero Cells** | Immutable append-only columnar slices | `Merge Incremental` preserves views; `Merge All + Drop Zero Cells` compacts disk. |
| **10** | **Smart View Formula Preservation** | Grid cell overwrite on refresh | Check "Preserve Formulas and Comments in Ad-Hoc Operations" in Member Options. |

</details>

---

## The 10 "Golden Laws" Interviewers Test

| # | The Core Concept | The "Twisted" Trap Interviewers Set | The Bulletproof Consultant Answer |
|---|---|---|---|
| **1** | **Evaluation Order vs. Solve Order** | *"We set Solve Order to 20, but the cell still displays `$1.00` instead of `Active` on the web form. Is Essbase broken?"* | **No**. Solve Order is an **Essbase math engine setting** ($0-127$). What controls visual formatting (Currency vs. Smart List vs. Date) is **Evaluation Order in Planning Application Settings**. To fix it, move `Account` to Rank 1 (Top Priority) in Evaluation Order. |
| **2** | **Implied Sharing & Security** | *"User has Write access to Child, but Read-Only to Parent. Can they alter the parent's data?"* | **YES, if Implied Sharing is active!** For a single-child stored parent, parent and child point to the **exact same physical memory cell**. Submitting to the child silently mutates the parent. To fix: set child to **`Never Share`**. |
| **3** | **Single-to-Multi Child Evolution** | *"We added a new subsidiary under an existing entity last week. Why did historical numbers for 2023 change on closed audited reports?"* | In 2023, the parent had only one child, so **Implied Sharing** held the data without needing `CALC ALL`. When the second child was added, implied sharing broke automatically. Because 2023 was historical and locked, `CALC ALL` was not run, leaving the parent empty (`#MISSING`). |
| **4** | **Grid Spread with Security** | *"User entered \$500K at Q1 with Proportional Spread. After submit and refresh, Q1 shows \$700K! Is this a calculation bug?"* | **No**. March (\$200K) is **Read-Only** (period closed). The spread engine excludes March and spreads the full \$500K across writable months (Jan=\$250K, Feb=\$250K). When Q1 recalculates, it sums Jan (\$250K) + Feb (\$250K) + locked March (\$200K) = **\$700K**. |
| **5** | **Solve Order Collision** | *"At the intersection of `Margin %` and `Variance %`, the cell shows 100%, but the CFO expected +15% pts. Why?"* | **Solve Order is inverted**. Account (`Margin %`) has a higher Solve Order than Version (`Variance %`), so Version evaluated first ($\Delta \text{GP} / \Delta \text{Rev} = 200/200 = 100\%$). To fix: give `Variance %` a **higher Solve Order** (e.g., 30) than `Margin %` (e.g., 20) so the variance evaluates over the finished margins. |
| **6** | **Two-Pass Calculation Fallacy** | *"Why can't I just roll up Margin % using `+` in the outline?"* | Because ratios are non-additive: $\sum \frac{A_i}{B_i} \neq \frac{\sum A_i}{\sum B_i}$. Summing 40% + 10% gives 50%, whereas the true weighted margin is $\frac{800+100}{2000+1000} = 30\%$. **Two-Pass** calculates components first, then recalculates the ratio at parent levels. |
| **7** | **Block Explosion (`CREATENONMISSINGBLK`)** | *"A junior consultant added one line to an allocation rule, and the disk filled up with 500 GB in 2 hours. What line did they add?"* | `SET CREATENONMISSINGBLK ON;` inside a broad sparse `FIX` assigning `0`. Essbase treats `0` as non-missing and attempts to create physical blocks for the entire Cartesian space ($2,000 \times 10,000 = 20,000,000$ blocks). |
| **8** | **Source Cube Property** | *"Database refresh failed with `Unknown member [Depr_Method] in formula`. But the formula works in CapEx! Why did it fail?"* | The account member is deployed to `FinPlan`, where `Depr_Method` does not exist. The member's **Source Cube** must be set to `CapEx`, and formula deployment for `FinPlan` must be **unchecked** so it deploys as a clean stored cell. Data moves via **Smart Push**. |
| **9** | **ASO Slice Merging** | *"What is the difference between `merge incremental data` and `merge all data drop zero cells` in ASO?"* | `merge incremental data` merges only delta slices, **leaving the main slice and pre-built aggregate views completely intact** (safe for intraday). `merge all data` consolidates everything into `slice_0000.dat`, purges zero cells, but **completely invalidates/drops all aggregate views** (nightly maintenance only). |
| **10** | **Smart View Formula Preservation** | *"User complains that every time they click Refresh in Smart View, their Excel formulas (`=SUM(B2:B10)`) get deleted. How do you fix it?"* | In Smart View Options $\to$ **Sheet Options** $\to$ **Data Options**, enable the checkbox **"Preserve Formulas and Comments in Ad-Hoc Grids"**. If unchecked, Essbase overwrites formula cells with retrieved numbers. |

---

## 25 Rapid-Fire Twisted Technical Questions & Answers

### 1. "Can you write data to an Upper-Level (Parent) member in Hybrid BSO?"
**Answer**: **NO**. In Hybrid BSO, upper-level sparse parent blocks do not exist physically on disk; they are calculated dynamically at query runtime by the ASO vector engine. Data entry can only target **Level 0 (leaf) stored blocks**. If parent entry is needed on forms, Planning's Grid Spread engine must distribute the value to Level 0 children.

### 2. "Why is ASO faster than BSO for retrievals, but why can't we use ASO for our primary budgeting cube?"
**Answer**: ASO is faster for retrievals because it stores data as compressed coordinate tuples and bitmap indices with pre-materialized aggregation views, avoiding heavy block decompressions. However, **ASO cannot execute procedural calculation scripts** (`FIX`, `LOOP`, `DATACOPY`, `@PRIOR`, driver allocations). Budgeting requires complex allocations and write-back calculations, which only BSO / Hybrid BSO supports.

### 3. "What happens if a calculation script has `CALCPARALLEL 8`, but only 1 CPU core is working?"
**Answer**: **Thread starvation due to task sizing**. By default, Essbase uses only the last sparse dimension to divide tasks. If that dimension has only 2 members, only 2 tasks are generated (6 threads idle). To fix: add **`SET CALCTASKDIMS 2;`** (or 3) to force the compiler to combine the last two sparse dimensions, generating dozens of tasks to saturate all 8 threads.

### 4. "What is the `.tct` file in BSO, and what happens if the server crashes during data submission?"
**Answer**: The `.tct` (Transaction Control Table) is BSO's **write-ahead transaction log**. When a write occurs, the engine logs states (`PENDING` $\to$ `WRITING` $\to$ `COMMITTED`). If the server crashes during `WRITING`, the recovery manager inspects the `.tct` on startup, identifies incomplete writes, and restores pre-image blocks from undo logs, rolling back the transaction to guarantee ACID integrity.

### 5. "What causes `Error: Lock timeout waiting for block` in a Planning form?"
**Answer**: **Block-level lock contention**. In BSO, locking occurs at the **block level**, not the cell level. If 20 users submit forms targeting cells that reside within the **exact same sparse block** (e.g., all writing to `Corporate_Entity`), the first user locks the entire block, and the remaining 19 users enter a serialized wait queue. If a transaction holds the lock longer than `LOCKTIMEOUT` (typically 60–300s), subsequent users get timed out.

### 6. "How do you calculate BSO Data Block Size, and what is the optimal range?"
**Answer**:
$$\text{Block Size (bytes)} = \prod \text{Stored Members in Dense Dimensions} \times 8 \text{ bytes}$$
- **Optimal Target Range**: **8 KB to 100 KB** (sweet spot: 50 KB–80 KB).
- **If < 8 KB**: High index overhead, millions of tiny blocks, severe I/O thrashing.
- **If > 100 KB**: Wasted memory, poor cache residency, high write amplification.

### 7. "Does adding Shared Members to an Alternate Hierarchy in a Sparse dimension increase block size?"
**Answer**: **NO**. In a Sparse dimension, shared members only add navigation paths in the B-Tree index pointing to existing blocks. Physical block size remains completely unchanged. (Adding stored members to a **Dense** dimension *does* expand block size).

### 8. "How does Hybrid BSO execute a calculation script with `SET HYBRIDBSOINCALCSCRIPT FULL;`?"
**Answer**: It allows the procedural calculation script to use the high-speed **ASO dynamic aggregation kernel** to read upper-level parent data on-the-fly in RAM during calculations. Without this setting (`NONE`), referencing a parent entity in a driver ratio requires parent blocks to be physically pre-calculated and stored on disk.

### 9. "What is the difference between Bottom-Up and Top-Down formula execution?"
**Answer**:
- **Bottom-Up**: Evaluates **only blocks that already exist** in the database. Fast, vectorized, memory-speed execution.
- **Top-Down**: Iterates through the **entire Cartesian product** of all fixed dimensions, testing whether each combination should create a block. 10x to 100x slower.
- **Force Bottom-Up**: Use `@CALCMODE(BOTTOMUP);`.

### 10. "In ASO, what does the `NONEMPTYMEMBER` directive do in an MDX formula?"
**Answer**: It instructs the MDX evaluation engine to evaluate the calculated formula **only if the specified driver member is not `#MISSING`**. If the driver is `#MISSING`, the entire calculation is skipped, preventing Cartesian loops across millions of empty cells and avoiding query timeouts.

### 11. "When would you use Groovy instead of a classic Calculation Manager business rule?"
**Answer**:
1. **Dynamic Grid Scoping**: Groovy can scan the active form grid (`operation.grid.dataCellIterator { it.isEdited() }`) and execute a calculation *only on cells modified by the user*, turning a 45-second calc into sub-second.
2. **Pre-Execution Validation**: Validating inputs before Essbase runs (`throwVetoException`).
3. **External REST Integrations**: Calling external web services or orchestrating Smart Push dynamically.

### 12. "What is the difference between `CLEARBLOCK ALL`, `CLEARBLOCK UPPER`, and `CLEARBLOCK EMPTY`?"
**Answer**:
- `CLEARBLOCK ALL`: Deletes **all blocks** (data and blocks) within scope.
- `CLEARBLOCK UPPER`: Deletes only **consolidated parent blocks** (Level 1+), preserving Level 0 input data.
- `CLEARBLOCK EMPTY`: Scans blocks and deletes **only blocks where every single cell evaluates to `#MISSING`**, freeing up B-Tree index space and shrinking `.pag` files without touching live data.

### 13. "What happens if a user submits `#MISSING` to every cell in a BSO block in Smart View?"
**Answer**: The data values become `#MISSING`, but **the physical block itself remains allocated on disk and indexed in the B-Tree**. It becomes an "empty block." To remove it physically, you must run `CLEARBLOCK EMPTY;`.

### 14. "In Smart View, what is the difference between 'Submit Data' and 'Submit Data Without Refresh'?"
**Answer**:
- `Submit Data`: Sends modified cells to the server, commits to disk, runs attached "Run on Save" business rules, and executes a full grid refresh to display recalculated numbers.
- `Submit Data Without Refresh`: Submits data to the server and commits, but **skips the read refresh**, providing ultra-low network latency for high-speed bulk data entry.

### 15. "Why does Microsoft Excel 32-bit crash with Smart View on large sheets, and how do you fix it?"
**Answer**: 32-bit Windows applications have a hard **2 GB virtual address space limit**. Large ad-hoc grids spanning tens of thousands of cells exhaust this 2 GB limit, freezing Excel. The permanent fix is upgrading to **64-bit Microsoft Office**, which accesses virtually unlimited RAM.

### 16. "What is an Infolet, and how does its 3-sided card architecture work?"
**Answer**: An Infolet is a lightweight, responsive executive KPI component in Cloud EPM:
- **Front Side**: Glanceable high-level KPI and sparkline (e.g., `Net Revenue: $45M`).
- **Back Side**: 3D flip card displaying an underlying variance driver chart (e.g., regional breakdown).
- **Expanded View**: Full-screen modal overlay displaying the underlying detailed planning form for write-back.

### 17. "What is the difference between Smart Push and Data Maps in Cloud EPM?"
**Answer**: They use the same underlying data movement engine, but:
- **Data Maps**: Defined administrative mappings executed manually, scheduled in batch, or called via EPM Automate.
- **Smart Push**: A Data Map **attached directly to a Planning Data Form** that triggers automatically and synchronously (or asynchronously) **upon form save**, pushing data from the source cube to the target cube instantly.

### 18. "In Dashboards 2.0, why don't slow queries freeze the entire dashboard like legacy Composite Forms did?"
**Answer**: Legacy Composite Forms loaded embedded forms serially (synchronously). Dashboards 2.0 uses **asynchronous REST queries per widget** powered by Oracle JET Redwood. Each widget runs its query in an independent thread; fast KPI tiles render in 100ms, while complex grids load independently with non-blocking spinners.

### 19. "What is the structural tie-breaking sequence when two Solve Orders are tied in Essbase?"
**Answer**:
1. If one member is in the **Accounts** dimension $\implies$ **Accounts wins**.
2. If neither is in Accounts, but one is in **Time** $\implies$ **Time wins**.
3. If neither is in Accounts or Time $\implies$ The dimension appearing **earlier in outline sequence wins**.

### 20. "Can a member tagged as `Label Only` store data?"
**Answer**: **NEVER**. Label Only members allocate zero physical bytes in data blocks and cannot store numbers under any conditions. They serve strictly as structural visual headers.

### 21. "What is the consequence of adding a member to a Dense dimension vs. a Sparse dimension in classic BSO?"
**Answer**:
- Adding a **Dense** member alters the internal block size of every single block in the database, triggering a **Full Database Restructure** (can take hours on large cubes).
- Adding a **Sparse** member does not alter block size; it triggers only an **Index Restructure** (rewriting the B-Tree index in minutes).

### 22. "What is the difference between an Attribute Dimension and a User-Defined Attribute (UDA)?"
**Answer**:
- **Attribute Dimension**: Classification metadata that appears as a queryable dimension in Smart View grids; supports dynamic rollups and cross-tab filtering without expanding block size.
- **UDA**: Freeform text label assigned to outline members; cannot be pivoted or queried in grids; used strictly inside calc scripts via `@ISUDA("Tag")` for boolean routing.

### 23. "Why does `DATACOPY` between sparse dimensions cause unexpected database expansion?"
**Answer**: `DATACOPY SparseA TO SparseB;` scans every existing block for `SparseA` and creates a brand new physical data block for `SparseB`. If `SparseA` has 50,000 blocks, `DATACOPY` instantly instantiates **50,000 new data blocks**, doubling the database size immediately.

### 24. "In Groovy, how do you prevent empty member sets from causing calc errors?"
**Answer**:
```groovy
if (modifiedDepts.isEmpty()) {
    println "No departments modified. Skipping calculation."
    return
}
```
In Essbase calc scripts, use **`SET EMPTYMEMBERSETS ON;`** so empty FIX sets exit gracefully instead of terminating with a fatal error.

### 25. "What is the recommended Solve Order assignment matrix for an enterprise P&L?"
**Answer**:
- **Tier 0 (SO = 0)**: Base additive consolidations (`Entity`, `Product` rollups).
- **Tier 1 (SO = 5)**: Time Period consolidations (`Q1`, `Q2`, `YearTotal`).
- **Tier 2 (SO = 10)**: Currency translation (`USD_Reporting`) and Time views (`YTD`).
- **Tier 3 (SO = 20)**: Account dynamic ratios (`Gross_Margin_%`, `ASP`).
- **Tier 4 (SO = 30)**: Version variances (`Variance`, `Variance_%`).

---

## 5 Practical Debugging Workflows to Memorize

### Workflow 1: User says a form is taking 45 seconds to save
1. Check if a business rule is set to **"Run on Save"**.
2. Check rule execution time in **Application $\to$ Jobs**.
3. If rule is slow, inspect the `FIX` statement: Is it calculating the entire cube instead of the form's POV?
4. Replace the broad calc script with a **Groovy rule** that scans only edited cells using `dataCellIterator`.
5. Check if **Smart Push** is attached to the form and running synchronously; if large, consider moving to background or narrowing the push intersection.

### Workflow 2: Ratio displays incorrect sum at Parent Entity
1. Check the Account member's storage property: Is it `Stored` or `Dynamic Calc`?
2. If stored, did Pass 2 run? (Stored ratios require Two-Pass or explicit parent recalculation).
3. If Dynamic Calc in Hybrid/ASO, check **Solve Order**: Is Solve Order higher than the Entity dimension (SO = 0)?
4. Set `Solve Order = 20` on the ratio account. Refresh and verify.

### Workflow 3: Database Refresh Fails on Metadata Deployment
1. Open the refresh error log.
2. If `Unknown member in formula`: Check the **Source Cube** property. Uncheck formula deployment for plan types that lack the referenced dimensions.
3. If `Base member must precede shared member`: Open dimension hierarchy, find the shared member, and move the base prototype member **above / before** the shared instance.
4. If `Formula on Label Only member`: Change member data storage to `Dynamic Calc`.

### Workflow 4: Smart View grid returns `#MISSING` for an entire row that has data
1. Check active **Alias Table**: Did the user type an alias from another table?
2. Check **User Security**: Does the user have `None` access to that Entity or Account?
3. Check **Cell-Level Security**: Is there a restriction rule masking that intersection?
4. Check **Suppression Options**: Is "Suppress Missing Rows" mistakenly filtering out rows?

### Workflow 5: Parent cell value doesn't match entered amount during Grid Spread
1. Check member access permissions for all children: Are any children **Read-Only**?
2. If a child is Read-Only, Grid Spread distributes the target amount *only across writable children*, adding the locked child's value back to the total.
3. Educate the user or filter out locked periods using substitution variables (`&CurMonth to &EndYear`).

---

*Keep this document open during your review preparation. Every single concept here represents an actual interview filter used by senior EPM review panels.*

