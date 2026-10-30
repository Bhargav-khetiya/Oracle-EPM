# 02 Allocate Level-to-Level Template: Cascading Waterfall Distributions

## 1. Architectural Essence of Level-to-Level Allocations

While standard allocations redistribute funds across a flat set of peers, enterprise cost accounting frequently requires **cascading, multi-tier waterfall allocations**. In a waterfall distribution, costs entered or calculated at high parent levels of a hierarchy are systematically pushed down through intermediate management tiers until they reach base operational leaf nodes.

```
+---------------------------------------------------------------------------------------------------+
|                                 LEVEL-TO-LEVEL WATERFALL ARCHITECTURE                             |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [LEVEL 3: Global Corporate Pool]                                                                 |
|  Total Executive IT Budget: $10,000,000                                                           |
|         |                                                                                         |
|         | Step 1: Push down to Level 2 based on Regional Server Usage                             |
|         v                                                                                         |
|  +-------------------------------------------------------------+                                  |
|  | LEVEL 2: Regional Operating Divisions                       |                                  |
|  | - Americas IT: $6,000,000 (60%)                             |                                  |
|  | - EMEA IT:     $3,000,000 (30%)                             |                                  |
|  | - APAC IT:     $1,000,000 (10%)                             |                                  |
|  +-------------------------------------------------------------+                                  |
|         |                                                                                         |
|         | Step 2: Push down to Level 1 based on Subsidiary Headcount                              |
|         v                                                                                         |
|  +-------------------------------------------------------------+                                  |
|  | LEVEL 1: Country Operating Units (e.g., US, Canada, Mexico) |                                  |
|  | - US IT: $4,500,000                                         |                                  |
|  | - Canada IT: $1,500,000                                     |                                  |
|  +-------------------------------------------------------------+                                  |
|         |                                                                                         |
|         | Step 3: Push down to Level 0 based on Department User Count                             |
|         v                                                                                         |
|  +-------------------------------------------------------------+                                  |
|  | LEVEL 0: Operational Cost Centers (Sales, R&D, Support)     |                                  |
|  | (Final leaf nodes consumed by operational P&L reports)      |                                  |
|  +-------------------------------------------------------------+                                  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Wizard Configuration Parameters

The **Allocate Level to Level** template provides specialized controls to manage recursive hierarchical descent:

| Wizard Step | Configuration Setting | Architectural Meaning |
| :--- | :--- | :--- |
| **Hierarchy Selection** | Hierarchy Tree / Dimension | Selects the dimension defining the waterfall path (e.g., `Entity`). |
| **Starting Level** | Integer (e.g., Level 3 or Gen 2) | The top parent level where the initial undistributed pool resides. |
| **Ending Level** | Level 0 (Base Leaf) | The terminal level where final values must be deposited. |
| **Cascade Direction** | Top-Down (Parent $\rightarrow$ Children) | Instructs the engine to iterate downwards level by level. |
| **Driver Selection per Level** | Driver Metric | Allows distinct drivers at each level (e.g., Revenue for Gen 2 $\rightarrow$ Gen 3, Headcount for Gen 3 $\rightarrow$ Gen 4). |
| **Offset Level Placement** | Parent / Clearing Account | Posts balancing contra-entries at each intermediate parent node to prevent double-counting. |

---

## 3. Generated Essbase Script Structure

To prevent double-counting as numbers cascade down hierarchies, the generated script must clear or offset the intermediate parent blocks:

```sql
/*
 * Compiled Level-to-Level Allocation
 * Cascades IT Pool from Gen 2 (Region) to Gen 3 (Country) to Gen 4 (Dept)
 */

FIX("Actual", "FY25", "Working", "IT_Expense")
  
  /* Step 1: Gen 2 to Gen 3 */
  FIX(@GENERATION("Entity", 3))
    "IT_Expense" = 
      @PARENTVAL("Entity", "IT_Expense") * 
      ("Headcount" / @PARENTVAL("Entity", @SUMRANGE("Headcount", @CHILDREN(@PARENT("Entity")))));
  ENDFIX

  /* Offset Gen 2 Parent to prevent double-counting */
  FIX(@GENERATION("Entity", 2))
    "IT_Expense_Offset" = -1 * "IT_Expense";
  ENDFIX

  /* Step 2: Gen 3 to Gen 4 (Level 0) */
  FIX(@LEVMBRS("Entity", 0))
    "IT_Expense" = 
      @PARENTVAL("Entity", "IT_Expense") * 
      ("Workstation_Count" / @PARENTVAL("Entity", @SUMRANGE("Workstation_Count", @CHILDREN(@PARENT("Entity")))));
  ENDFIX

  /* Offset Gen 3 Parents */
  FIX(@GENERATION("Entity", 3))
    "IT_Expense_Offset" = -1 * "IT_Expense";
  ENDFIX

ENDFIX
```

---

## 4. Architectural Safeguards: Preventing Double-Counting

In standard BSO cubes where upper levels dynamically roll up, leaving un-offset numbers at parent levels during a top-down allocation will result in **hyper-inflated reporting**:
* If $\$10,000,000$ at the parent is allocated to children without clearing or offsetting the parent, a subsequent aggregation will sum the $\$10,000,000$ children BACK into the parent, creating a reported total of **$\$20,000,000$**!
* **The Solution**: The Allocate Level-to-Level template enforces an immediate negative offset or physical clear on each parent tier the moment its children are populated.

