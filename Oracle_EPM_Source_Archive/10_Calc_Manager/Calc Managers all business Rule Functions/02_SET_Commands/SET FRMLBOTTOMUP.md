# SET FRMLBOTTOMUP

## Overview

`SET FRMLBOTTOMUP` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It overrides the default calculation methodology for complex formulas executed on sparse dimension members. It explicitly forces the engine to calculate the formula using a **Bottom-Up** block resolution path, rather than a Top-Down resolution path.

### Why Does This Function Exist?

Essbase has two fundamental ways to calculate a block:
1. **Top-Down**: It looks at the formula on the parent, decides it needs children, creates potential virtual blocks for every child, steps down the tree, does the math, and rolls back up. This is incredibly safe, but in a massive sparse dimension, creating virtual blocks for millions of children who don't even have data takes an eternity.
2. **Bottom-Up**: It ignores the parent formula. It looks at the Level 0 data blocks that *actually exist*. It grabs them, pushes them up the tree, and calculates the parent. This is lightning fast because it ignores empty branches entirely.

By default, Essbase is highly conservative. If a sparse formula contains cross-dimensional pointers (e.g., `"Sales" -> "USA"`), complex `IF` statements, or non-additive math, the engine gets scared. It assumes a Bottom-Up calculation might miss something, so it defaults to the slow, miserable Top-Down execution.
`SET FRMLBOTTOMUP ON` allows the administrator to override the engine's fear. It forces the engine to execute the complex formula using the high-speed Bottom-Up methodology.

### When to Use It

- **Aggressive Performance Tuning**: Forcing a complex sparse allocation formula to run Bottom-Up, cutting calculation times from hours to minutes.
- **Complex IF Statements**: Overriding the default Top-Down penalty incurred whenever an `IF` statement is used on a Sparse dimension block.
- **Cross-Dimensional Math**: Executing mathematical ratios (`A / B`) on upper-level sparse members without triggering a full top-down tree evaluation.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET FRMLBOTTOMUP ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `ON`: Forces the C-engine to execute sparse formulas using a Bottom-Up block evaluation (Fastest). <br>- `OFF`: Allows the engine to use its default logic, which will almost always revert to Top-Down for complex formulas (Safest, but Slowest). |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a numeric value. It alters the fundamental calculation index methodology.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Warning Suppression**: When active, the Job Console will no longer throw warnings about "Formula calculated top-down due to complex dependencies" because you have explicitly overridden the behavior.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET FRMLBOTTOMUP ON;`. It flags the JVM to ignore Top-Down safety protocols for sparse formulas.
2. **Execution Trigger**: The engine encounters a complex formula on a Sparse parent: `"Total_Overhead" = "Pool" * "Driver";`.
3. **Block Scanning (Bottom-Up)**: Instead of starting at `"Total_Overhead"` and looking down, the engine drops to Level 0.
4. **Data Driven**: It looks for stores that actually have `"Pool"` and `"Driver"` data blocks.
5. **Ascension**: It calculates the math at the base, and rolls it up the tree, completely ignoring any branches that didn't have base-level data.

---

## Syntax Variants & Scenarios

### Variant 1: Forcing High-Speed Block Execution

```essbase
/* 
   Placed at the top of an allocation script to ensure the engine 
   doesn't bog down attempting a Top-Down evaluation of the hierarchy.
*/
SET FRMLBOTTOMUP ON;
```

---

## Practical Examples

### Example 1: Optimizing a Sparse Allocation IF Statement

**Scenario**: A script distributes a `$1M` pool to 10,000 Level-0 stores. The script contains an `IF` statement on a Sparse dimension (`IF("Store_Type" == "Flagship")`). Essbase sees the Sparse `IF` and instantly defaults to Top-Down execution. It attempts to create virtual blocks for all 10,000 stores to check their type, taking 45 minutes. The admin adds `SET FRMLBOTTOMUP ON`.

```essbase
/* 
   1. Force Bottom-Up execution to bypass the top-down IF statement penalty.
*/
SET FRMLBOTTOMUP ON;

FIX("FY25", "Working")
    
    /* 
       2. The engine evaluates the IF statement.
       Because of Bottom-Up, it ONLY checks stores that already 
       physically exist in the database (they have data). It ignores 
       the thousands of empty stores entirely.
    */
    "Allocated_Bonus" (
        IF(@ISMBRWITHATTR("Store_Type", "Flagship"))
            "Allocated_Bonus" = "Bonus_Pool"->"No_Store" * 0.10;
        ENDIF
    )
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding Data Dependencies | Incomplete Math | Essbase defaults to Top-Down for a reason: Safety. Bottom-Up calculation ONLY executes on blocks that already exist. If your formula is `A = B + C`, but block `A` doesn't exist yet, a Bottom-Up execution will NEVER calculate it, because it skips missing blocks. Top-Down would have forced the block to create. If you force Bottom-Up, you MUST ensure that the target blocks exist (either naturally, or by using `SET CREATENONMISSINGBLK ON`) before the math runs |
| Using it for Dense Dimensions | Irrelevant | This command strictly dictates how *Sparse* dimension blocks are traversed. Dense dimensions are calculated inside the memory array of the block itself. There is no such thing as Top-Down vs Bottom-Up for a Dense calculation. This command has absolutely no effect on Dense formulas |
| Ignoring the Console | Silent Failures | If you force Bottom-Up on a formula that mathematically requires a Top-Down execution (like a complex cross-dimensional allocation targeting empty sparse intersections), the script will report "Success", but the data simply won't be there. Always manually validate the data output when switching from Top-Down to Bottom-Up |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`SET CREATENONMISSINGBLK`](./SET%20CREATENONMISSINGBLK.md) | Often paired with `FRMLBOTTOMUP` to ensure that even though the engine is running fast, it still creates the necessary target blocks |
| `@CALCMODE` | The older, function-level equivalent that can be attached directly to a member formula in the outline (e.g., `@CALCMODE(BOTTOMUP)`) |
| [`@QUERYBOTTOMUP`](./@QUERYBOTTOMUP.md) | A micro-optimization wrapper used inside specific `IF` statements to force leaf-node index scanning |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET FRMLBOTTOMUP](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_frmlbottomup.html)
