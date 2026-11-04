# CALC DIM

## Overview

`CALC DIM` is a **native Essbase calculation command** in Oracle EPM Cloud (PBCS/EPBCS). It is the primary, targeted macro used by administrators to force the calculation engine to structurally aggregate (roll up) specific, explicitly named dimensions in the database. 
Unlike `CALC ALL` (which blindly aggregates the entire database) or `AGG` (which is highly optimized but strictly limited to sparse dimensions), `CALC DIM` evaluates the full structural outline logic, including member formulas, hierarchical `+`, `-`, `*`, `/` operators, and complex dimension intersections, for the explicitly listed dimensions.

### Why Does This Function Exist—

When a user submits data to a Level 0 block (e.g., `"Store_101"`), the upper-level parent blocks (e.g., `"New_York"`, `"USA"`, `"Total_Company"`) do not automatically update. They remain stale until an aggregation script is run.
If you use `CALC ALL`, the engine wastes time recalculating dimensions that didn't change (like Historical Years) or dimensions that shouldn't be calculated (like Scenarios). 
`CALC DIM` provides surgical precision. It tells the engine: "Only calculate the exact dimension I tell you to." If data was only submitted to the `"Entity"` dimension, you write `CALC DIM("Entity");`. The engine aggregates the Entity tree, updates the parents, and ignores the rest of the database, massively reducing calculation times.

### When to Use It

- **Targeted Batch Aggregation**: Rolling up the `Entity`, `Product`, and `Cost_Center` dimensions during a nightly batch script after data loads.
- **Dense Dimension Calculation**: Executing structural math on Dense dimensions (like the `Account` or `Time` dimension). *(Note: The `AGG` command cannot be used on Dense dimensions. `CALC DIM` is the only way to structurally aggregate a Dense dimension via script).*
- **Formula Execution**: Forcing the engine to run complex member formulas attached to sparse parent members during the rollup process.

---

## Category

**System & Optimization / Aggregation Directives / Calculation Commands**

---

## Syntax

```essbase
CALC DIM (DimName1, [DimName2], ...);
```

*(Note: Because this is a macro command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimName1` | Dimension | ✅ Yes | The exact name of the first dimension you want to calculate (e.g., `"Entity"`). |
| `DimNameX` | Dimension | ❌ No | Additional dimensions to calculate simultaneously. Separate multiple dimensions with commas. |

---

## Return Value

**Return Type**: System Action (Block Aggregation)

This command does not return a numeric value. It executes a physical calculation and block-generation sweep.
- **Dense Dimensions**: If applied to a Dense dimension, Essbase calculates the blocks already resident in memory.
- **Sparse Dimensions**: If applied to a Sparse dimension, Essbase takes the existing Level 0 blocks, creates brand new blocks for the upper-level parents on the disk, and writes the summed data into them.
- **Operator Math**: It strictly obeys the structural operators in the `.otl` file. If a child has a `~` (Ignore) operator, its data is excluded from the parent's total.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine reads the `CALC DIM ("Entity", "Product");` command.
2. **Dimension Order**: Essbase optimizes the execution by natively calculating the dimensions in the order they are listed in the outline (Dense first, then Sparse), regardless of what order you typed them in the script.
3. **Bottom-Up Sweep**: It drops to the bottom of the first dimension tree.
4. **Execution**: It sums the children, evaluates any member formulas attached to the parent, writes the data to the parent block, and steps up to the next level.
5. **Completion**: Once the first dimension hits the Root node, it moves to the second dimension and repeats the process.

---

## Syntax Variants & Scenarios

### Variant 1: Single Dimension Aggregation

```essbase
/* 
   Rolls up ONLY the Entity dimension.
*/
CALC DIM ("Entity");
```

### Variant 2: Multi-Dimension Aggregation

```essbase
/* 
   Rolls up three separate dimensions in a single pass.
*/
CALC DIM ("Entity", "Product", "Market");
```

---

## Practical Examples

### Example 1: Calculating Dense Accounts and Rolling Sparse Entities

**Scenario**: A user saves data to a web form. The form contains base-level financial data. The administrator has attached a "Save Rule" to the form. The rule must calculate the Dense `"Account"` dimension (which contains complex formulas like `Margin = Rev - Cost`), and then roll that calculated data up the Sparse `"Entity"` tree to update the regional totals.

```essbase
/* 
   1. Fix on the specific slice of data the user is working on.
*/
FIX("Actual", "FY25", "Working")
    
    /* 
       2. Use CALC DIM to calculate the Dense Account dimension.
       This executes the Margin = Rev - Cost formulas inside the blocks.
       
       3. Use CALC DIM to roll up the Sparse Entity dimension.
       This takes the newly calculated Margins and rolls them up to Regional totals.
    */
    CALC DIM ("Account", "Entity");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| `CALC DIM` vs `AGG` | Performance Disaster | While `CALC DIM` works on sparse dimensions, it is significantly slower than the `AGG` command. `CALC DIM` opens the block, checks for formulas, executes structural logic, and writes the block. `AGG` strictly performs brute-force addition. In massive sparse dimensions with millions of blocks, `CALC DIM("Entity")` might take 30 minutes, whereas `AGG("Entity")` might take 3 minutes. **Best Practice**: Use `CALC DIM` for Dense dimensions. Use `AGG` for Sparse dimensions (unless the sparse dimension has complex parent formulas that must execute during rollup) |
| Using `@` Prefix | `@CALC DIM` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash immediately |
| Omitting Parentheses | `CALC DIM "Entity";` | The dimension list MUST be wrapped in parentheses. `CALC DIM ("Entity");` is the only valid syntax |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`AGG`](./AGG.md) | The high-speed alternative for rolling up Sparse dimensions (bypasses formula execution for raw speed) |
| [`CALC ALL EXCEPT DIM`](./CALC%20ALL%20EXCEPT%20DIM.md) | The inverse approach. Calculates everything EXCEPT the specified dimension |
| `CALC ALL` | Aggregates every single dimension in the database simultaneously |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — CALC DIM](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_dim.html)
