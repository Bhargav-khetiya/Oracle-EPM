# @SANCESTVAL

## Overview

`@SANCESTVAL` is a **native Essbase cross-dimensional query function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating block, traces its lineage upward to a specified ancestral generation or level, and retrieves the numeric data value from a specific account/member at that exact ancestral node, **ignoring the structural calculation rules (like Dynamic Calc or Consolidation operators)** of that ancestor.

*(The "S" stands for Stored/Static).*

### Why Does This Function Exist—

When building massive top-down allocations, a Level 0 member (like `"Store_101"`) often needs to query data from its parent (like `"New_York"`) or its grandparent (like `"Total_USA"`) to calculate its proportional share (e.g., `Store Sales / USA Sales`). 
The standard function for this is `@ANCESTVAL`. However, `@ANCESTVAL` strictly obeys the physical outline. If `"Total_USA"` is a `Dynamic Calc` member, querying it natively will force the Essbase engine to stop calculating the store, run an on-the-fly aggregation of all USA stores to find the total, return the total to Store 101, and then repeat that massive aggregation for Store 102, Store 103, etc. This causes extreme performance degradation (fragmentation).
`@SANCESTVAL` exists to bypass this. It queries the *Stored* value of the ancestor. It completely ignores `Dynamic Calc` tags and structural aggregation logic. It simply looks at the block in memory (which was presumably populated by a prior step or data load) and extracts the static number. This makes it infinitely faster for complex top-down querying, provided the parent block was pre-populated.

### When to Use It

- **High-Speed Pro-Rata Allocations**: Extracting a corporate `"Overhead_Pool"` value from a Generation 2 parent and pushing it down to Level 0 children without triggering thousands of dynamic block aggregations.
- **Top-Down Targeting**: A base-level project looking upward to find the `"Approved_Budget_Cap"` set at the Division level to determine if it is in breach of funding.
- **Driver Retrieval**: Base nodes extracting static assumptions (like Tax Rates or FX Rates) stored at regional consolidation nodes.

---

## Category

**Mathematical / Hierarchy Traversal & Data Retrieval / Essbase Native Functions**

---

## Syntax

```essbase
@SANCESTVAL(DimName, genNum | levNum, mbrName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimName` | Dimension | ✅ Yes | The dimension tree to climb (e.g., `"Entity"`). Must be the exact dimension name. |
| `genNum | levNum` | Integer | ✅ Yes | The mathematical stopping point for the upward climb. Can be a Generation (Top-Down, e.g., `2`) or a Level (Bottom-Up, e.g., `1`). |
| `mbrName` | Member | ✅ Yes | The specific account or metric you want to retrieve from that ancestor (e.g., `"Overhead_Pool"`). |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the numeric data value stored at the ancestor's block intersection.
- **Static Retrieval**: It pulls the raw, static number from the block. It does not execute formulas attached to the ancestor.
- **Out of Bounds**: If the current member is actually *higher* than the specified Level, or if the specified ancestor does not exist, the function returns `#MISSING`.
- **Current Member Retrieval**: If the engine is already calculating a member at the exact specified Generation/Level, the function simply returns the value of `mbrName` from the current block without climbing.

---

## How It Works (Behind the Scenes)

1. **Context Query**: Essbase locks onto the block currently being calculated (e.g., `Entity = Store_101`).
2. **Lineage Trace**: It climbs the `DimName` hierarchy upward from `Store_101`.
3. **Target Lock**: It stops climbing the absolute instant it reaches the specified `genNum` or `levNum` (e.g., hitting `New_York` at Gen 3).
4. **Data Query**: It constructs a virtual pointer to that ancestor's intersection (e.g., `New_York` -> `mbrName`).
5. **Static Extraction**: It reads the data block directly. It explicitly bypasses the `AGG` engine and formula engine.
6. **Return**: It returns the raw number to the calculation block at Level 0.

---

## Syntax Variants & Scenarios

### Variant 1: Climbing by Generation

```essbase
/* 
   Climbs the Entity tree up to Generation 2 (usually Regions or Divisions).
   Retrieves the "Corporate_Tax_Rate" from that Gen 2 node.
*/
"Local_Tax_Expense" = "Net_Income" * @SANCESTVAL("Entity", 2, "Corporate_Tax_Rate");
```

---

## Practical Examples

### Example 1: Optimized Top-Down Allocation

**Scenario**: A company has `$1,000,000` in `"Marketing_Overhead"` booked at the `Level 1` (Region) members (e.g., `"North_America"`). This overhead must be allocated down to the `Level 0` stores based on their percentage of `"Revenue"`. The administrator must ensure the calculation runs as fast as possible, so they use `@SANCESTVAL` to retrieve the Level 1 overhead without triggering dynamic math.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. Calculate the Revenue Ratio. 
       We divide local Revenue by the Level 1 Revenue (using SANCESTVAL to grab it).
    */
    VAR vRatio = "Revenue" / @SANCESTVAL("Entity", 1, "Revenue");
    
    /* 
       2. Retrieve the Level 1 Overhead Pool.
       We climb the Entity tree to Level 1, grab the Overhead, and multiply by the ratio.
    */
    "Allocated_Marketing" = @SANCESTVAL("Entity", 1, "Marketing_Overhead") * vRatio;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Dynamic Calculation | Missing Data | Because `@SANCESTVAL` explicitly bypasses the calculation engine to query the stored block, **the block must actually exist**. If `"Total_USA"` is a pure dynamic roll-up, and you have not run an aggregation script prior to this step, its stored block will be empty. `@SANCESTVAL` will return `#MISSING`. You must ensure the target data is physically stored/aggregated before using this function |
| Confusing Generation and Level | Going the wrong direction | Generations (`genNum`) start from the top of the tree (Root = Gen 1). Levels (`levNum`) start from the bottom (Leaf = Level 0). If you write `@SANCESTVAL("Entity", 2, "Sales")`, the engine will behave entirely differently depending on whether you meant Generation 2 (the Division) or Level 2 (a local management tier). Be absolutely certain which system your outline relies on |
| Using it inside `FIX` | Syntax Error | This is a data retrieval function that outputs a Number. You CANNOT use it inside a `FIX` statement to select members. It must be used on the right side of a mathematical equation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ANCESTVAL`](./@ANCESTVAL.md) | The standard version. Evaluates the ancestor block according to its structural outline rules (triggering Dynamic Calcs if necessary), rather than just grabbing the static stored block |
| [`@PARENTVAL`](./@PARENTVAL.md) | A specialized version that always grabs data from the *direct* parent (Level + 1), rather than requiring you to specify an exact Generation or Level integer |
| [`@MDANCESTVAL`](./@MDANCESTVAL.md) | The multi-dimensional version, allowing you to climb multiple different dimension hierarchies simultaneously |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — SANCESTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/sancestval.html)
