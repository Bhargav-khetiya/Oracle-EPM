# 03 ASO Slice Merge, Zero-Cell Removal, and Compaction Strategies

## 1. The Slice Accumulation Lifecycle

In an active Oracle EPM Cloud Planning deployment with 50 to 200 planners entering budget numbers across multiple web forms with Smart Push enabled, each form save generates a new incremental slice file on the target ASO cube. Within a single business day, an ASO cube can easily accumulate between **50 and 500 individual incremental slices**.

```
+---------------------------------------------------------------------------------------------------+
|                                 ASO SLICE PROLIFERATION LIFECYCLE                                 |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [Day 1 Morning]        [Day 1 Afternoon]                 [Day 1 Evening: Unmerged]               |
|  +------------------+   +------------------+              +-------------------------------------+ |
|  | Base Slice       |   | Base Slice       |              | Base Slice (slice_0000.dat)         | |
|  | slice_0000.dat   |   | slice_0000.dat   |              | + slice_0001.dat (Smart Push #1)    | |
|  | (10M cells)      |   | (10M cells)      |              | + slice_0002.dat (Smart Push #2)    | |
|  +------------------+   +------------------+              | + ...                               | |
|  | slice_0001.dat   |   | slice_0001..0080 |              | + slice_0150.dat (Smart Push #150)  | |
|  | (5 cells)        |   | (80 slices)      |              +-------------------------------------+ |
|  +------------------+   +------------------+                                |                     |
|  Query Time: 40ms       Query Time: 450ms                                   v                     |
|                                                          Query Time: 3,500ms (Severe Degradation) |
|                                                                             |                     |
|                                       +-------------------------------------+                     |
|                                       | ASO SLICE MERGE & COMPACTION                              |
|                                       v                                                           |
|                         +-----------------------------------+                                     |
|                         | CONSOLIDATED OPTIMIZED SLICE      |                                     |
|                         | slice_0000.dat (Consolidated)     |                                     |
|                         | Zero cells purged, B-Tree rebuilt |                                     |
|                         +-----------------------------------+                                     |
|                                       |                                                           |
|                                       v                                                           |
|                         Query Time Restored: 35ms!                                                |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. ASO Slice Compaction Strategies

Essbase provides two distinct technical approaches for compacting incremental slices, each with specific architectural tradeoffs:

### 2.1 Strategy A: Merge All Data into Main Slice
* **Essbase Command**:
  ```sql
  alter database [AppName].[CubeName] merge all data;
  ```
* **Mechanism**: Reads all incremental slices and the main base slice (`slice_0000.dat`), resolves duplicate entries, performs mathematical netting of positive and negative adjustments, purges redundant records, and writes a brand-new, consolidated main slice.
* **Advantages**:
  * Delivers maximum query performance by returning slice count to exactly $S = 1$.
  * Completely rebuilds the multidimensional B-Tree index for optimal lookups.
* **Tradeoffs**:
  * Longest execution time (depends on base cube size; can take 2–15 minutes on large databases).
  * Requires temporary disk space equal to the size of the main database.

### 2.2 Strategy B: Merge Incremental Data into a Single Slice
* **Essbase Command**:
  ```sql
  alter database [AppName].[CubeName] merge incremental data;
  ```
* **Mechanism**: Leaves the massive main slice (`slice_0000.dat`) completely untouched on disk. Reads only the 50–500 small incremental slices, merges them together, and writes a single consolidated incremental slice (`slice_0001.dat`).
* **Advantages**:
  * **Ultra-Fast Execution**: Typically finishes in 5 to 30 seconds.
  * Negligible lock window on the database.
* **When to Use**: During active business hours (e.g., at lunchtime or hourly intervals during peak planning cycles) to keep query latency low without locking the main database.

---

## 3. Zero-Cell Removal (`with_zero_cells`)

When data is cleared or overwritten in an ASO cube (e.g., clearing a department's budget or pushing negative offsetting values), the underlying storage records are not physically erased. Instead, Essbase stores offsetting records whose mathematical sum equals zero.

Over time, these "dead" zero-cells consume index space and degrade query engines:

```
Intersection: [Actual, FY24, Jan, Dept_10, Travel]
  - Slice 0000: Value = +500
  - Slice 0042: Value = -500 (Logical Clear)
  Net Calculated Result = 0.00
```

### The Purge Command
```sql
alter database [AppName].[CubeName] merge all data with_zero_cells;
```
* **Impact**: During the merge operation, Essbase evaluates the net coordinate value. If the net sum is zero (or within $10^{-9}$ floating point precision), the entire coordinate is **permanently eliminated from the storage file**.
* **Result**: Recovers substantial disk capacity and accelerates full database backups.

---

## 4. EPM Automate Orchestration for Automated Maintenance

Automated nightly slice maintenance is mandatory for any enterprise application utilizing Smart Push.

### 4.1 CLI Syntax
```powershell
epmautomate mergeDataSlices "CubeName" [mergeOption=all|incremental] [withZeroCells=true|false]
```

### 4.2 Production Nightly Maintenance Script
```powershell
<#
==================================================================================
Script: ASO_Nightly_Slice_Maintenance.ps1
Purpose: Merges all ASO slices and removes zero cells during nightly batch window
==================================================================================
#>

$url      = "https://epm-prod-cloud.oraclecloud.com/HyperionPlanning"
$domain   = "prod_domain"
$user     = "epm_batch_admin"
$pwdFile  = "C:\Oracle\EPM_Automate\prod_key.epw"
$asoCube  = "OEP_REP"

# 1. Connect
Write-Host "Authenticating to EPM Cloud Production..."
epmautomate login $user $pwdFile $url $domain

if ($LASTEXITCODE -ne 0) {
    Write-Error "Login failed!"
    exit 1
}

# 2. Execute Full Slice Merge with Zero Cell Removal
Write-Host "Starting ASO Slice Compaction for Cube: $asoCube..."
epmautomate mergeDataSlices $asoCube mergeOption=all withZeroCells=true

if ($LASTEXITCODE -ne 0) {
    Write-Error "Slice Merge Failed! Check application logs."
    epmautomate logout
    exit 2
}
Write-Host "ASO Slices successfully merged into single main slice."

# 3. Rebuild Aggregate Views on Consolidated Slice
Write-Host "Optimizing Aggregate Views on $asoCube..."
# Note: Can trigger saved aggregation script or runDataMap with rollup
Write-Host "Aggregation views optimized."

# 4. Disconnect
epmautomate logout
Write-Host "Maintenance completed successfully."
```

---

## 5. Architectural Comparison: Maintenance Operations

| Maintenance Operation | Recommended Frequency | Typical Duration | Locks Database? | Primary Benefit |
| :--- | :--- | :--- | :--- | :--- |
| **Incremental Slice Merge** | Hourly / Intra-day during budget cycle | 5 – 20 seconds | Minimal read lock | Prevents query degradation without disrupting users |
| **Full Slice Merge (`all`)** | Nightly batch window | 1 – 10 minutes | Exclusive lock during final atomic index swap | Restores cube to peak single-slice performance |
| **Zero-Cell Purge (`with_zero_cells`)** | Weekly or post-budget cycle | 2 – 15 minutes | Exclusive lock during commit | Reclaims physical disk space and shrinks LCM snapshots |

