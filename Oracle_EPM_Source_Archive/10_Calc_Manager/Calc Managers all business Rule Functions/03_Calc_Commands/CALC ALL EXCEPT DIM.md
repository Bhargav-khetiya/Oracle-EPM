# CALC ALL EXCEPT DIM

## Overview

`CALC ALL EXCEPT DIM` is a **native Essbase calculation command** in Oracle EPM Cloud (PBCS/EPBCS). It is an aggressive, macro-level directive that commands the Essbase calculation engine to execute a full, top-to-bottom structural aggregation (calculating all dimension trees, running all formulas, rolling up all parents)... **EXCEPT** for one explicitly specified dimension.

### Why Does This Function Exist?

The standard `CALC ALL;` command is the nuclear option of Essbase. It calculates everything. However, in modern multidimensional databases, calculating *everything* is rarely the correct path.
Often, a specific dimension (like `Currency` or `Scenario`) does not need to be aggregated. For example, if you just loaded Local Currency data for Actuals, you need to roll up the Entity dimension, the Product dimension, and the Time dimension. But you explicitly DO NOT want to aggregate the `Scenario` dimension (adding Actuals to Forecast is mathematically invalid). 
If you use `CALC ALL;`, Essbase might attempt to roll up scenarios if they have parent-child structures. 
To prevent this, you could write a massive `CALC DIM(Entity, Product, Time);` statement. But if someone adds a new `Customer` dimension next year, your script won't calculate it. 
`CALC ALL EXCEPT DIM` solves this by blacklisting. It tells the engine: "Calculate every single dimension in the database, including any new ones added in the future, BUT NEVER aggregate the Scenario dimension." This ensures future-proofed, safe aggregations.

### When to Use It

- **Scenario/Version Protection**: Executing a full database rollup while explicitly protecting non-additive dimensions (like `Scenario` or `Version`) from meaningless aggregations.
- **Currency Isolation**: Rolling up all geographical and product data for `Local_Currency` without attempting to calculate the `Reporting_Currency` structure (which requires a separate FX translation script first).
- **Time-Series Overrides**: Aggregating all structural data, but skipping the `Time` dimension if the Time dimension relies on complex custom Dynamic Time Series (DTS) logic that shouldn't be executed via standard batch aggregation.

---

## Category

**System & Optimization / Aggregation Directives / Calculation Commands**

---

## Syntax

```essbase
CALC ALL EXCEPT DIM (DimName);
```

*(Note: Because this is a macro command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimName` | Dimension | ✅ Yes | The exact name of the dimension that should be completely excluded from the aggregation sweep (e.g., `"Scenario"`). |

---

## Return Value

**Return Type**: System Action (Block Aggregation)

This command does not return a value. It triggers a massive structural sweep of the database index.
- **Aggregation Execution**: It reads the `+`, `-`, `*`, `/`, and `~` operators in the outline for every dimension *except* the one provided. It generates upper-level blocks and writes the summed data into them.
- **Calculation Order**: It obeys the internal Essbase calculation order (Dense dimensions first, then Sparse dimensions).

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine reads the `CALC ALL EXCEPT DIM` command.
2. **Dimension Audit**: It scans the active `.otl` file and builds a list of every dimension in the database.
3. **Blacklist Removal**: It looks at the `DimName` parameter and explicitly removes that dimension from the aggregation queue.
4. **Execution**: It fires the standard `CALC ALL` C-engine routines on the remaining dimensions. It calculates block formulas, rolls up the dense dimension, and then aggregates the sparse trees.
5. **Completion**: Once the upper-level blocks for the allowed dimensions are written to disk, it moves to the next line in the script.

---

## Syntax Variants & Scenarios

### Variant 1: Protecting Scenarios

```essbase
/* 
   Rolls up the entire database (Entity, Product, Account, Time, etc.)
   but explicitly refuses to aggregate the Scenario dimension.
*/
CALC ALL EXCEPT DIM ("Scenario");
```

---

## Practical Examples

### Example 1: Global Rollup with Currency Protection

**Scenario**: An overnight batch process loads base-level Actuals into the `"Local_Currency"` member of the `"Currency"` dimension. The administrator needs to roll up this data across all 8 custom dimensions (Entity, Product, Project, Customer, etc.). However, if the engine aggregates the `"Currency"` dimension, it will add `"Local_Currency"` and `"USD"` together into `"Total_Currency"`, which is meaningless garbage. The admin uses `CALC ALL EXCEPT DIM`.

```essbase
/* 
   1. Fix on the data we just loaded (Actuals, Local Currency, FY25).
*/
FIX("Actual", "Local_Currency", "FY25")
    
    /* 
       2. Command the engine to roll up every single dimension in the database
       to generate the parent-level totals (e.g., Total Company, Total Product).
       3. We explicitly blacklist the Currency dimension. It will be completely ignored.
    */
    CALC ALL EXCEPT DIM ("Currency");
    
ENDFIX

/* 
   4. (Later in the script, a separate FX translation block will convert 
   Local to USD).
*/
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `@` Prefix | `@CALC ALL` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash immediately |
| Omitting the Parentheses | `CALC ALL EXCEPT DIM "Scenario";` | The dimension name must be wrapped in parentheses. Failing to include them will cause a syntax parser failure |
| Overusing it in Massive Outlines | Fragmentation and Time | While `CALC ALL` is convenient, it is incredibly dangerous in massive databases with 15+ sparse dimensions. Rolling up *everything* can take hours and generate billions of empty blocks (block explosion). In highly optimized environments, administrators almost never use `CALC ALL`. They use targeted `CALC DIM()` or `AGGMISSG` commands to aggregate only the specific sparse branches that changed |
| Multiple Dimensions | `CALC ALL EXCEPT DIM ("A", "B")` | This syntax only accepts a SINGLE dimension. If you need to exclude two dimensions, you cannot use this command. You must explicitly list the dimensions you *do* want to calculate using `CALC DIM ("C", "D", "E");` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CALC DIM`](./CALC%20DIM.md) | The whitelist equivalent. Aggregates only the specific dimensions you explicitly provide |
| `CALC ALL` | The absolute nuclear option. Aggregates every single dimension in the database with no exceptions |
| [`CALC ALL EXCEPT MBR`](./CALC%20ALL%20EXCEPT%20MBR.md) | Similar concept, but blacklists a specific *member/branch* of a dimension rather than the entire dimension itself |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — CALC ALL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_all.html)
