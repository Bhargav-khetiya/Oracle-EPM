# SET CREATENONMISSINGBLK

## Overview

`SET CREATENONMISSINGBLK` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls how the calculation engine handles Sparse Block creation during mathematical equations (`A = B`). 

Unlike `SET CREATEBLOCKONEQ` (which blindly creates blocks for every member in the `FIX` statement), `SET CREATENONMISSINGBLK` is a highly intelligent, conditionally safe macro. It tells the engine: "Only create a brand new block for the Left Side of the equation **IF** the data on the Right Side of the equation actually exists (is non-missing)."

### Why Does This Function Exist—

Essbase's default Bottom-Up calculation engine only evaluates blocks that already exist. 
Imagine you want to calculate `"Bonus" = "Salary" * 0.10;`. 
`"Salary"` is a Dense account. `"Bonus"` is a Dense account. `"Store_101"` has a block because it had Sales. But `"Store_200"` is a brand new cost center; it only has `"Salary"` data loaded into it. It has no Sales, so its block technically doesn't exist in the calculation index yet.
If you run `"Bonus" = "Salary" * 0.10;`, Essbase skips Store 200 entirely because it thinks the block is empty. 
If you use `CREATEBLOCKONEQ ON`, Essbase will create a block for EVERY store in the company, even the ones with no Salary, exploding the database size.
`SET CREATENONMISSINGBLK ON` is the perfect middle ground. It tells Essbase to scan the Right Side (`"Salary"`). If `"Salary"` has data, Essbase safely creates a block for that specific store and writes the `"Bonus"`. If `"Salary"` is `#MISSING`, it skips the store. This allows safe, data-driven block creation without the catastrophic risk of a full-database block explosion.

### When to Use It

- **Driver-Based Calculations**: Calculating dependent metrics (like Benefits, Payroll Taxes, or Commissions) across sparse dimension hierarchies where the base driver (Salary or Sales) exists, but the target block has not yet been initialized.
- **Top-Down Sparse Allocations**: Pushing data from a parent node down to specific children, but strictly limiting the creation of new child blocks to only those children who possess a valid allocation driver (like Square Footage).
- **Cross-Dimensional Movement**: Moving data from one Sparse dimension intersection to an entirely different Sparse intersection (`"Actual"->"FY24" = "Forecast"->"FY25"`), creating the new block safely.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET CREATENONMISSINGBLK ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `ON`: Intelligently creates a block for the target ONLY if the source equation yields valid, non-missing data. <br>- `OFF`: Default behavior. Evaluates math strictly on pre-existing blocks. |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a value. It alters the internal state of the Block Generation processor.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Performance Impact**: While vastly safer than `CREATEBLOCKONEQ`, it is still slower than `OFF` because the engine must actively scan the Right Side of the equation for every potential intersection to determine if block creation is warranted.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET CREATENONMISSINGBLK ON;`.
2. **Execution Trigger**: The engine hits `"Bonus" = "Salary" * 0.10;`.
3. **Scope Scan**: It looks at the `FIX` statement and sees 1,000 potential stores.
4. **Intelligent Validation**: For Store 1, it looks at the Right Side (`"Salary"`). Store 1 has no Salary. It skips Store 1. For Store 2, it sees `$100,000` in Salary.
5. **Block Generation**: It halts, allocates physical memory on the disk for a brand new Store 2 block, calculates the math (`$10,000`), and writes the Bonus into the new block.

---

## Syntax Variants & Scenarios

### Variant 1: Safe Equation Block Generation

```essbase
/* 
   Placed before a mathematical calculation to ensure targets are 
   generated only if the driver data exists.
*/
SET CREATENONMISSINGBLK ON;
```

---

## Practical Examples

### Example 1: Safe Payroll Tax Calculation

**Scenario**: An HR application calculates `"Payroll_Tax"`. The tax is 5% of `"Base_Salary"`. Some cost centers are brand new and only have Salary data loaded (their blocks are effectively empty from a calculation standpoint). The admin must calculate the tax, but they cannot afford to explode the database by creating blocks for all 5,000 dead cost centers. They use `CREATENONMISSINGBLK`.

```essbase
/* 
   1. We force the engine to create blocks intelligently based on data presence.
*/
SET CREATENONMISSINGBLK ON;

FIX("Working", "FY25", @LEVEL0("Cost_Centers"))
    
    /* 
       2. The equation is evaluated.
       If Base_Salary is #MISSING, Essbase ignores the cost center.
       If Base_Salary has data, Essbase creates the block (if necessary) 
       and writes the Payroll_Tax into it.
    */
    "Payroll_Tax" = "Base_Salary" * 0.05;
    
ENDFIX

/* 
   3. It is best practice to turn it OFF immediately to protect 
   subsequent dense-matrix calculations.
*/
SET CREATENONMISSINGBLK OFF;
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it with Constants | `"Account" = 500;` | This is a logical trap. If you write `"Account" = 500;` with `CREATENONMISSINGBLK ON`, what is the Right Side— The Right Side is `500`. `500` is non-missing. Therefore, Essbase will evaluate the Right Side as TRUE for every single member in the `FIX`, and will aggressively create blocks for everyone, effectively mirroring the catastrophic behavior of `CREATEBLOCKONEQ`. This command is ONLY safe when the Right Side of the equation contains a Sparse dimension pointer or a data-driven account |
| Forgetting to Turn it Off | Slowing Down the Script | If you leave this `ON` for the entire script, Essbase will constantly check the Right Side of every equation to see if it needs to create a block. This adds unnecessary overhead to standard dense calculations. Always turn it `OFF` when the specific block-creation phase is over |
| Using it for `DATACOPY` | Wrong Command | This command controls block creation for mathematical equations. It does not affect the `DATACOPY` command. You must use `SET COPYMISSINGBLOCK ON` for data replication |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`SET CREATEBLOCKONEQ`](./SET%20CREATEBLOCKONEQ.md) | The aggressive alternative. Blindly creates blocks for the target regardless of whether the source data exists or not |
| [`SET COPYMISSINGBLOCK`](./SET%20COPYMISSINGBLOCK.md) | The equivalent directive used exclusively for `DATACOPY` commands |
| `@CREATEBLOCK` | A cell-level function that can forcefully create a block without relying on a global `SET` directive |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET CREATENONMISSINGBLK](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_createnonmissingblk.html)
