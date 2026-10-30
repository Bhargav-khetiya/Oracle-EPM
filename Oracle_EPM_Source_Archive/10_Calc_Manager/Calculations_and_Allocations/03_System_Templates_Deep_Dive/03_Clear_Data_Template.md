# 03 Clear Data Template: Physical vs. Logical Clearing and Storage Slicing

## 1. Architectural Essence of Data Clearing

In financial planning, purging obsolete, restated, or temporary calculation data is necessary before recalculating or loading new figures. In Calculation Manager, the **Clear Data Template** provides a standardized interface to purge multidimensional data intersections without risking accidental database wipes.

```
+---------------------------------------------------------------------------------------------------+
|                                     CLEAR DATA ENGINE TOPOLOGY                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  CLEAR REGION SPECIFICATION:                                                                      |
|  FIX ("Forecast", "FY25", "Working", "Sales_East")                                                |
|                                                                                                   |
|                                  |                                                                |
|         +------------------------+------------------------+                                       |
|         |                                                 |                                       |
|         v                                                 v                                       |
|  [METHOD 1: PHYSICAL CLEAR (CLEARBLOCK)]           [METHOD 2: LOGICAL CLEAR (CLEARDATA)]           |
|  - Completely unlinks and deletes blocks          - Overwrites dense cells with #MISSING          |
|  - Frees physical disk space in .pag file         - Retains empty block in .ind file              |
|  - Accelerates subsequent calculations            - Ideal when blocks will be immediately reused  |
|  - Command: CLEARBLOCK ALL;                       - Command: CLEARDATA "Sales_Accounts";          |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Physical Clear vs. Logical Clear Mechanics

Choosing between Physical and Logical clearing profoundly influences Essbase storage performance:

| Attribute | Physical Clear (`CLEARBLOCK`) | Logical Clear (`CLEARDATA` / `#MISSING`) |
| :--- | :--- | :--- |
| **Storage Impact** | Deletes block header from index file (`.ind`). Frees disk blocks in `.pag`. | Block header remains in index. Internal cell values set to `#MISSING`. |
| **Database File Size** | Shrinks physical database size (reclaims space after restructure). | Database size remains unchanged. |
| **Subsequent Calc Speed** | **Fastest**: Subsequent calculations encounter fewer blocks. | **Slower**: Subsequent calculations must still process empty blocks. |
| **Index Fragmentation** | Can cause index fragmentation if cleared sporadically. | Zero index fragmentation. |
| **Execution Speed** | Fast (pointer unlinking). | Fast (bulk array overwrite). |

---

## 3. Clear Block Options in BSO

When configuring physical block clearing, Calculation Manager provides four distinct execution modes:

```sql
/* 1. CLEARBLOCK ALL: Deletes all blocks matching the FIX slice */
FIX("Forecast", "FY25", "Working")
  CLEARBLOCK ALL;
ENDFIX

/* 2. CLEARBLOCK UPPER: Deletes only intermediate and top parent blocks */
FIX("Actual", "FY24")
  CLEARBLOCK UPPER; /* Keeps Level 0 inputs intact; purges rollup blocks */
ENDFIX

/* 3. CLEARBLOCK NONINPUT: Deletes blocks created strictly by calculations */
FIX("Budget", "FY25")
  CLEARBLOCK NONINPUT; /* Preserves user-entered data; clears calc results */
ENDFIX

/* 4. CLEARBLOCK EMPTY: Deletes blocks that contain only #MISSING values */
CLEARBLOCK EMPTY; /* General database maintenance utility */
```

---

## 4. Clearing Data in ASO Cubes

When targeting Aggregate Storage Option (ASO) cubes, `CLEARBLOCK` does not exist. The template generates an **MDX Clear Region** command:

```sql
/* Physical MDX Clear on ASO Cube */
alter database [Vision].[OEP_REP] clear data in_region 
'CrossJoin({[Forecast]}, CrossJoin({[FY25]}, Descendants([Total_Expenses])))' 
physical;
```
* **Physical Option**: Immediately purges the records from the `.dat` storage files.
* **Logical Option**: Generates a negative compensation slice without rewriting existing slices.

---

## 5. Security Safeguards: Preventing Global Database Wipes

The greatest danger with clearing routines is an **Unbounded FIX**:
* If a developer omits the Scenario or Year dimension from the FIX statement, the clear command will execute across **ALL Scenarios and ALL Years**!
* **Safeguards Built into the Template**:
  * The Clear Data Template enforces mandatory selections for all sparse dimensions.
  * Runtime prompts can be flagged as **Required**, preventing users from launching a clear rule with blank parameters.

