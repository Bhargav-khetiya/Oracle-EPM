# @QUERYBOTTOMUP

## Overview

`@QUERYBOTTOMUP` is a **native Essbase calculation directive** in Oracle EPM Cloud (PBCS/EPBCS). It is an optimization toggle that alters how the Essbase engine resolves and processes specific complex queries within a calculation block. When applied, it forces the Essbase analytical engine to process the specified query starting from the leaf (Level 0) nodes and working its way upward, rather than the default top-down traversal.

*Note: This is a highly specialized internal optimization function. It is rarely used in standard FP&A scripting. It is primarily utilized by database administrators attempting to tune the performance of massively dense, sparse-spanning relational queries or complex custom Java CDFs that are timing out during execution.*

### Why Does This Function Exist—

Essbase outlines are hierarchical trees. When you run a query like "Find all members whose attribute is 'Red'", the engine typically starts at the root (`"Total_Company"`), looks at the children, looks at their children, and eventually hits the leaf nodes (Top-Down). 
However, in massive sparse dimensions with millions of leaf nodes and very flat hierarchies, Top-Down traversal can be incredibly inefficient. The engine wastes time navigating parent levels that don't hold the data it actually needs.
If you know that 100% of the relevant data is stored at Level 0, you want the engine to start at the bottom and only evaluate the leaf nodes. `@QUERYBOTTOMUP` forces the internal index scanner to flip its traversal direction. For specific types of Boolean searches or dimensional scans, this can reduce a 5-minute search down to milliseconds.

### When to Use It

- **Massive Attribute Scans**: Accelerating `@ISMBRWITHATTR` sweeps across sparse dimensions that contain hundreds of thousands of Level 0 members.
- **Flat Dimension Overrides**: Optimizing searches in dimension structures that are intentionally flat (e.g., a "Customer" dimension with 1 parent and 500,000 children).
- **Custom CDF Feeders**: Feeding dynamically generated bottom-up arrays into custom Java functions that expect data to arrive in Level 0 sequential order.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
@QUERYBOTTOMUP(Boolean_Expression)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Boolean_Expression`| Logic | ✅ Yes | The specific query, boolean check, or attribute function that you want the engine to optimize (e.g., `@ISMBRWITHATTR("Color", "Red")`). |

---

## Return Value

**Return Type**: Passthrough (Boolean)

The function acts as a wrapper. It does not generate data itself; it simply returns the exact Boolean result (`TRUE` or `FALSE`) of the `Boolean_Expression` contained inside it.
- **Transparency**: From a mathematical standpoint, `IF(@ISMBRWITHATTR("A"))` and `IF(@QUERYBOTTOMUP(@ISMBRWITHATTR("A")))` produce the exact same result. The only difference is the speed and internal memory route the engine takes to get there.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The compiler encounters the `@QUERYBOTTOMUP` wrapper.
2. **Index Override**: Before evaluating the logic inside the parentheses, it sends an interrupt to the Essbase Index Scanner, changing the traversal flag for this specific operation from `TOP_DOWN` to `BOTTOM_UP`.
3. **Execution**: The engine executes the inner boolean expression. Because of the flag, it jumps straight to the Level 0 blocks in the index and scans them sequentially, only walking up to parents if explicitly required by the math.
4. **Resolution**: It hands the `TRUE`/`FALSE` result back.
5. **Revert**: It reverts the Index Scanner back to its default state for the rest of the script.

---

## Syntax Variants & Scenarios

### Variant 1: Optimizing an Attribute Search

```essbase
/* 
   Forces the engine to search for "Red" products by scanning 
   Level 0 products first, rather than stepping down through the categories.
*/
IF(@QUERYBOTTOMUP(@ISMBRWITHATTR("Color", "Red")))
```

---

## Practical Examples

### Example 1: High-Speed Pricing Adjustments

**Scenario**: A company has 1,000,000 SKUs in the `"Product"` dimension. The hierarchy is very flat. The FP&A team needs to apply a 5% price hike, but ONLY to products manufactured in `"Germany"`. `"Country_Of_Origin"` is a User Defined Attribute (UDA). A standard `FIX(@UDA("Product", "Germany"))` takes 30 minutes to compile because the engine gets lost stepping down the tree. The admin uses `@QUERYBOTTOMUP` inside an `IF` statement to force a high-speed leaf scan.

```essbase
/* 
   1. We FIX on all Level 0 Products to establish the block constraint.
*/
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* 
       2. We use @QUERYBOTTOMUP to wrap the UDA check.
       This forces the engine to evaluate the UDA locally at the leaf node,
       rather than trying to resolve the UDA globally from the top-down.
    */
    IF(@QUERYBOTTOMUP(@ISUDA("Product", "Germany")))
        
        /* 
           3. Apply the price hike.
        */
        "Sales_Price" = "Sales_Price" * 1.05;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it on Deep Hierarchies | Performance Degradation | Bottom-Up is not a magic bullet. If your dimension has 15 deep, perfectly structured generations (like a standard Entity tree), Top-Down traversal is actually much faster because it allows the engine to skip massive branches of the tree instantly (e.g., "This branch is USA, ignore it, move to Europe"). If you force Bottom-Up on a deep tree, Essbase has to check every single leaf node in the USA anyway. Only use this on massively flat, sparse dimensions |
| Wrapping Non-Queries | Syntax Errors | You cannot use this function to wrap standard math (`@QUERYBOTTOMUP("Sales" * 5)`). It strictly takes Boolean logic/queries (functions that return TRUE/FALSE or arrays of members). It is an index router, not a math processor |
| Confusing with `@CALCMODE(BOTTOMUP)` | Block vs Index | `@CALCMODE(BOTTOMUP)` is a fundamental command that changes how Essbase calculates entire sparse blocks (preventing top-down block creation). `@QUERYBOTTOMUP` is a micro-optimization that only affects how Essbase searches the structural outline index for a specific `IF` statement. They are completely different optimization vectors |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISMBRWITHATTR`](./@ISMBRWITHATTR.md) | One of the most common functions wrapped inside `@QUERYBOTTOMUP` to accelerate attribute queries |
| [`@ISUDA`](./@ISUDA.md) | Another common function optimized by this wrapper for massive leaf-level tag scans |
| [`@CALCMODE`](./@CALCMODE.md) | The macro-level block calculation optimizer that dictates the fundamental execution path of the script |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — QUERYBOTTOMUP](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/querybottomup.html)
