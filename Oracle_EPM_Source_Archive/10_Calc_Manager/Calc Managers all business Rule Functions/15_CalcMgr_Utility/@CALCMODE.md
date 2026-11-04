# @CALCMODE

## Overview

`@CALCMODE` is a **native Essbase calculation engine directive** in Oracle EPM Cloud (PBCS/EPBCS). Unlike mathematical or logical functions that return data, `@CALCMODE` is a structural command that dictates **how the Essbase engine processes blocks of data in memory**. It explicitly overrides default block calculation behaviors (such as Top-Down vs. Bottom-Up processing, or Block vs. Cell mode), allowing administrators to forcibly optimize script performance or resolve complex order-of-operations data dependencies.

### Why Does This Function Exist—

By default, Essbase uses a highly optimized "Bottom-Up" calculation algorithm. When it sees an equation like `"Total_Sales" = "Units" * "Price";`, it scans the database for existing blocks of `Units` and `Price`, loads those blocks, calculates them, and saves `Total_Sales`. 
However, if `Total_Sales` relies on complex cross-dimensional logic or sparse `IF` statements (where the engine cannot easily predict which blocks need calculating), the Bottom-Up engine may fail to create the target blocks, resulting in `#MISSING` data. In these scenarios, the script must be forced into "Top-Down" mode, where the engine comprehensively loops through every possible combination of members, guaranteeing the calculation fires, but at the cost of massive performance degradation.
`@CALCMODE` exists to give you surgical control over this behavior. Instead of forcing the *entire* rule into Top-Down mode (which would crash the server), you can use `@CALCMODE(TOPDOWN)` on one specific, problematic equation, and then immediately switch back to `@CALCMODE(BOTTOMUP)` for the rest of the script.

### When to Use It

- **Resolving Sparse IF Dependencies**: Forcing Top-Down mode on a calculation that assigns data to a completely empty block based on complex external `IF` conditions.
- **Cell-Based Calculations**: Forcing Cell mode to calculate members one by one across a dense dimension, resolving tight circular reference dependencies within a single block.
- **Performance Tuning**: Forcing Bottom-Up mode on equations that Essbase defensively (and incorrectly) flagged as requiring Top-Down processing.

---

## Category

**Engine Directives / Calculation Modes / Essbase Native Functions**

---

## Syntax

```essbase
@CALCMODE(Mode_Directive)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Mode_Directive` | Keyword | ✅ Yes | The specific processing mode you want to enforce. Acceptable values: <br>`TOPDOWN` <br>`BOTTOMUP` <br>`BLOCK` <br>`CELL` |

---

## Mode Definitions

### 1. BOTTOMUP (Default)
Essbase only calculates blocks that already exist in memory (or have data in their dependencies). It is extremely fast and efficient. Use this to explicitly override Essbase if it defensively switched to Top-Down mode unnecessarily.

### 2. TOPDOWN
Essbase ignores the existing data footprint and systematically iterates through *every possible combination* of the sparse members defined in the `FIX` statement. It is incredibly slow, but guarantees that complex cross-dimensional `IF` logic will fire and create new blocks.

### 3. BLOCK (Default for Dense)
Essbase loads an entire data block (e.g., all Accounts and Periods for a specific Entity) into memory, calculates all formulas within that block simultaneously, and writes the block back to disk. This is highly efficient for standard math.

### 4. CELL
Essbase loads the block, but calculates it cell by cell, resolving the formula for `Jan` completely before moving to `Feb`. This is extremely slow, but absolutely mandatory if `Feb` relies on the calculated result of `Jan` (e.g., Cash Flow carry-forward logic).

---

## How It Works (Behind the Scenes)

1. **Directive Parsing**: When the Essbase compiler encounters `@CALCMODE`, it immediately alters the execution plan for the specific formula block it is attached to.
2. **Algorithm Switch**: 
   - If switched to `TOPDOWN`, the engine disables its "calculator cache" and builds a comprehensive loop matrix, visiting every sparse intersection defined by the current `FIX`.
3. **Execution**: The formula executes using the enforced algorithm.
4. **Reversion**: Unless specified otherwise, the engine usually reverts to its default optimized state for subsequent `FIX` blocks.

---

## Syntax Variants & Scenarios

### Variant 1: Forcing Top-Down for a Sparse IF Statement

```essbase
/* 
   Forces the engine to iterate through every employee to check the 
   global assumption, creating blocks for employees who have no data yet.
*/
@CALCMODE(TOPDOWN);
"Bonus" (
    IF("Global_Bonus_Flag"->"No_Entity" == 1)
        "Bonus" = 5000;
    ENDIF
)
```

---

## Practical Examples

### Example 1: Resolving Dense Circular References with CELL Mode

**Scenario**: A Cash Flow script calculates `Ending_Balance`. The rule is: `Ending_Balance = Beginning_Balance + Net_Change`. The `Beginning_Balance` of February is equal to the `Ending_Balance` of January. 
If Essbase runs this in default `BLOCK` mode, it calculates all `Ending_Balances` for the entire year simultaneously. Because Jan hasn't finished calculating before Feb asks for its value, Feb gets `#MISSING`. The administrator must force the engine to calculate Cell-by-Cell along the Time dimension.

```essbase
FIX("FY25", "Working", @LEVEL0("Entities"))
    
    /* 
       1. Force the engine out of Block Mode. 
       We need it to calculate one cell (month) at a time.
    */
    @CALCMODE(CELL);
    
    /* 
       2. Execute the Cash Flow logic. 
       Essbase will now calculate Jan Ending, write it to memory, 
       then calculate Feb Beginning using Jan Ending, and so on.
    */
    "Ending_Balance" = "Beginning_Balance" + "Net_Change";
    
    "Beginning_Balance" (
        IF(NOT @ISMBR("Jan"))
            "Beginning_Balance" = @PRIOR("Ending_Balance");
        ENDIF
    )
    
ENDFIX
```

### Example 2: Forcing Block Creation via TOPDOWN

**Scenario**: You need to assign $1,000 to every `Cost_Center` in `New_York`, even if the Cost Center currently has absolutely no data (no blocks exist). Because `Cost_Center` is sparse, Bottom-Up mode will see no data and skip the calculation entirely. You must force Top-Down mode.

```essbase
FIX("FY25", "Working", "New_York", @LEVEL0("Cost_Centers"))
    
    /* 
       1. Force the engine to visit every single Cost Center 
       defined in the FIX statement, regardless of whether data exists.
    */
    @CALCMODE(TOPDOWN);
    
    /* 
       2. Assign the value. 
       This will forcefully create blocks for every Cost Center.
       (WARNING: If there are 1,000,000 cost centers, this will take a long time).
    */
    "Corporate_Allocation" = 1000;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using TOPDOWN on Massive FIX Statements | Script runs for 5 hours | If you `FIX` on `@LEVEL0("Accounts")`, `@LEVEL0("Entities")`, and `@LEVEL0("Products")` (say, 10 million potential combinations), and you force `@CALCMODE(TOPDOWN)`, Essbase will attempt to visit all 10 million intersections, completely freezing the server. ONLY use `TOPDOWN` when your `FIX` statement is extremely narrow |
| Using `SET UPDATECALC OFF` Confusions | Misunderstanding Intelligent Calc | `@CALCMODE` controls *how* blocks are processed (Top vs Bottom). It does NOT control *which* blocks are processed based on dirty data flags. If you want to force calculation of clean blocks, use `SET UPDATECALC OFF;`, not `CALCMODE` |
| Syntax Placement | Placing it outside a formula | `@CALCMODE` is a function directive that must be attached to a specific member formula block, or placed at the top of a calculation script. If placed randomly inside an `IF` statement, it will fail to compile. It must precede the mathematical operation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`SET CREATENONMISSINGBLK`](./SET%20CREATENONMISSINGBLK.md) | A modern alternative to `TOPDOWN` mode. It allows Bottom-Up processing but forcefully creates blocks based on dense formula definitions. (Often preferred over `TOPDOWN` for performance) |
| [`@PRIOR`](./@PRIOR.md) | The function most frequently used alongside `@CALCMODE(CELL)` for time-series cash flow rolling |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — CALCMODE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calcmode.html)
