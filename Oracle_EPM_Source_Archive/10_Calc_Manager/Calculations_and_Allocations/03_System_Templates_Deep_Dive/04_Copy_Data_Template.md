# 04 Copy Data Template: Cross-Scenario Replication and DATACOPY Internals

## 1. Architectural Essence of Data Copying

In planning cycles, initiating a new forecast or budget version typically begins by copying an existing data slice (e.g., seeding the `FY25 Plan` with `FY24 Actuals`, or snapshotting `Working Version` to `Final Version`).

The Calculation Manager **Copy Data Template** generates optimized replication logic. At the engine level, it chooses between two vastly different copy mechanisms:
1. **Low-Level Block Copy (`DATACOPY`)**: A raw, block-to-block memory replication stream.
2. **Formula-Based Assignment Copy**: A cell-by-cell assignment loop used when data must be transformed or mapped across non-identical dimensional coordinates.

```
+---------------------------------------------------------------------------------------------------+
|                                      COPY DATA ENGINE SELECTION                                   |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  Are Source and Target identical in structure across all other dimensions—                        |
|                                 |                                                                 |
|         +-----------------------+-----------------------+                                         |
|         | YES                                           | NO (Requires Member Mapping / Math)     |
|         v                                               v                                         |
|  [BLOCK COPY: DATACOPY]                         [FORMULA ASSIGNMENT COPY]                         |
|  Command: DATACOPY "Actual" TO "Plan";          FIX ("FY25", "Plan", "Working")                  |
|  - Clones entire physical 64KB blocks in RAM    - Iterates cell by cell                           |
|  - Bypasses Essbase calculation FPU             - Allows 10% markup or member remapping           |
|  - Throughput: 1,000,000+ cells/second!         - Throughput: 25,000 cells/second                 |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Wizard Configuration Parameters

When using the Copy Data Template wizard:

| Step | Parameter | Description |
| :--- | :--- | :--- |
| **Step 1: Source Context** | Member Selections | Fixes the source slice to copy (e.g., `Scenario: "Actual"`, `Years: "FY24"`, `Version: "Final"`). |
| **Step 2: Target Context** | Destination Members | Specifies where the copy lands (e.g., `Scenario: "Plan"`, `Years: "FY25"`, `Version: "Working"`). |
| **Step 3: Member Mapping** | Source $\rightarrow$ Target Grid | Maps source members to target members when dimensional names differ. |
| **Step 4: Clean Target Option** | True / False | Executes a preliminary `CLEARBLOCK` on the target slice before copying to prevent stale leftover data. |
| **Step 5: Copy Options** | Comments, Supporting Detail | Toggles replication of relational cell text, attachments, and line-item details. |

---

## 3. The Power of Native `DATACOPY`

When the copy involves two members of the **same sparse dimension** (e.g., copying from Version `Working` to Version `Archive`), Calculation Manager leverages Essbase's native `DATACOPY` command:

```sql
/* Compiled High-Speed DATACOPY Script */
SET UPDATECALC OFF;

FIX("FY25", "Plan", @LEVMBRS("Entity", 0))
  DATACOPY "Working" TO "Archive_V1";
ENDFIX
```

### Why `DATACOPY` is 100x Faster than Cell Loops:
* `DATACOPY` does not parse or evaluate formulas.
* It allocates a new block header in the target index, performs a direct memory buffer copy (`memcpy`) of the 64KB dense array from the source block, and updates the index pointer.
* It can duplicate millions of cells in seconds without CPU calculation overhead.

---

## 4. Cross-Year Copying and Dimensional Shifts

When copying across different years or periods where dimensions shift, `DATACOPY` cannot be used directly because the block addresses differ. The template compiles an assignment loop:

```sql
/* Compiled Assignment Copy with Source Year Offset */
FIX("Plan", "Working", @LEVMBRS("Entity", 0), @LEVMBRS("Department", 0))
  FIX(@LEVMBRS("Account", 0), @LEVMBRS("Period", 0))
    "FY25" (
      "FY25" = "FY24"->"Actual";
    )
  ENDFIX
ENDFIX
```
* **Block Creation**: When copying across years into empty sparse blocks, ensure `SET CREATEBLOCKONEQ ON;` is enabled to guarantee new blocks are created on the target year.

