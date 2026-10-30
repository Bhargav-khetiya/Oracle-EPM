# @SPARENTVAL

## Overview

`@SPARENTVAL` is a **native Essbase cross-dimensional query function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating block, traces its lineage exactly one step upward to its **immediate Parent**, and retrieves the numeric data value from a specific account/metric at that parent node, **ignoring the structural calculation rules (like Dynamic Calc)** of that parent.

*(The "S" stands for Stored/Static).*

### Why Does This Function Exist?

When building step-down allocations, a Level 0 member (like `"Store_101"`) often needs to query data from its direct parent (`"New_York"`) to calculate its proportional share (e.g., `Store Sales / New York Sales`). 
The standard function for this is `@PARENTVAL`. However, `@PARENTVAL` strictly obeys the physical outline. If `"New_York"` is a `Dynamic Calc` member, querying it natively forces Essbase to pause calculating the store, run an on-the-fly aggregation of all NY stores to find the total, return the total to Store 101, and then repeat that massive aggregation for Store 102. This causes terrible performance degradation.
`@SPARENTVAL` bypasses this. It queries the *Stored* value of the direct parent. It completely ignores `Dynamic Calc` tags and structural aggregation logic. It simply looks at the block in memory (which was presumably populated by a prior step or data load) and extracts the static number. This makes it incredibly fast for complex, localized allocations.

### When to Use It

- **High-Speed Pro-Rata Allocations**: Extracting a localized `"Overhead_Pool"` value from a direct parent and pushing it down to immediate children without triggering dynamic block aggregations.
- **Parent/Child Validations**: Checking if the base node's data exceeds a `"Control_Threshold"` statically stored at the parent holding bucket.
- **Driver Retrieval**: Base nodes extracting static assumptions (like a localized growth rate) stored exclusively at their direct supervisor node.

---

## Category

**Mathematical / Hierarchy Traversal & Data Retrieval / Essbase Native Functions**

---

## Syntax

```essbase
@SPARENTVAL(DimName, mbrName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimName` | Dimension | ✅ Yes | The dimension tree to climb (e.g., `"Entity"`). Must be the exact dimension name. |
| `mbrName` | Member | ✅ Yes | The specific account or metric you want to retrieve from the immediate parent (e.g., `"Overhead_Pool"`). |

*(Note: Unlike `@SANCESTVAL`, you do not specify a Generation or Level integer. This function is hard-coded to step exactly ONE level upward to the direct parent).*

---

## Return Value

**Return Type**: Numeric (Double)

Returns the numeric data value stored at the parent's block intersection.
- **Static Retrieval**: It pulls the raw, static number from the block. It does not execute formulas or aggregations attached to the parent.
- **Top Level**: If the currently calculating member is the absolute root of the dimension (it has no parent), the function returns `#MISSING`.
- **Missing Data**: If the parent block physically exists but contains no data for that metric, it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Context Query**: Essbase locks onto the block currently being calculated (e.g., `Entity = Store_101`).
2. **Parent Resolution**: It climbs the `DimName` hierarchy upward exactly one step, identifying the direct parent (`New_York`).
3. **Data Query**: It constructs a virtual pointer to that parent's intersection (e.g., `New_York` -> `mbrName`).
4. **Static Extraction**: It reads the data block directly from memory. It explicitly bypasses the `AGG` engine and formula engine.
5. **Return**: It returns the raw number to the calculation block at Level 0.

---

## Syntax Variants & Scenarios

### Variant 1: Grabbing Parent Totals

```essbase
/* 
   Retrieves the "Total_Sales" value strictly from the immediate 
   Entity parent of the block currently being calculated.
*/
VAR vParentSales = @SPARENTVAL("Entity", "Total_Sales");
```

---

## Practical Examples

### Example 1: Localized Overhead Allocation

**Scenario**: A company has `"Regional_Overhead"` booked at various mid-level management nodes (e.g., `"New_York"`, `"Boston"`). This overhead must be allocated down to their direct children based on their percentage of `"Revenue"`. The administrator uses `@SPARENTVAL` to retrieve the parent overhead instantly without triggering dynamic math.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. Calculate the Revenue Ratio. 
       We divide local Revenue by the Direct Parent's Revenue 
       (using SPARENTVAL to grab the static parent total).
    */
    VAR vRatio = "Revenue" / @SPARENTVAL("Entity", "Revenue");
    
    /* 
       2. Retrieve the localized Overhead Pool.
       We grab the overhead strictly from the direct parent and multiply by the ratio.
    */
    "Allocated_Overhead" = @SPARENTVAL("Entity", "Regional_Overhead") * vRatio;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Dynamic Calculation | Missing Data | Because `@SPARENTVAL` explicitly bypasses the calculation engine to query the stored block, **the block must actually exist**. If `"New_York"` is a pure dynamic roll-up, and you have not run an aggregation script prior to this step, its stored block will be empty. `@SPARENTVAL` will return `#MISSING`. You must ensure the target data is physically stored/aggregated before using this function |
| Attempting Deep Traversal | Grabbing Grandparents | `@SPARENTVAL` is hardcoded to go exactly ONE step up. If you need data from the grandparent (e.g., `"USA"`, which is two steps up), this function cannot reach it. You MUST use `@SANCESTVAL` and specify the exact Generation or Level you want to hit |
| Using it inside `FIX` | Syntax Error | This is a data retrieval function that outputs a Number. You CANNOT use it inside a `FIX` statement to select members. It must be used on the right side of a mathematical equation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PARENTVAL`](./@PARENTVAL.md) | The standard version. Evaluates the parent block according to its structural outline rules (triggering Dynamic Calcs if necessary), rather than just grabbing the static stored block |
| [`@SANCESTVAL`](./@SANCESTVAL.md) | The deep-traversal version. Grabs static data, but allows you to climb as high as you want up the tree, rather than stopping at the direct parent |
| [`@PARENT`](../04_Member_Navigation/@PARENT.md) | A member selection function that returns the structural *Name* of the parent, rather than evaluating its numeric data |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — SPARENTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/sparentval.html)
