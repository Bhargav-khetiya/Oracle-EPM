# CLEARBLOCK

## Overview

`CLEARBLOCK` is a **block-level data management command** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that clears data within the **current data block** during calculation. Unlike `CLEARDATA` which targets specific members, `CLEARBLOCK` operates on the block currently being processed and provides options to clear different types of cells within that block.

### Why Does This Command Exist?

In BSO (Block Storage Option), data is stored in blocks defined by sparse dimension intersections. Within each block, data cells are categorized as:
- **Input cells**: Values entered by users or loaded from external sources
- **Non-input (calculated) cells**: Values derived from formulas or aggregation
- **Upper-level cells**: Parent/aggregate member values

`CLEARBLOCK` allows you to selectively clear these categories without affecting input data — crucial for recalculation scenarios where you want to preserve manual inputs while recalculating derived values.

### When to Use It

- To clear calculated/aggregated values before recalculation (preserving inputs)
- To remove upper-level (parent) values before re-aggregation
- To clear all data in a block as part of a formula
- To reset derived metrics while keeping base data
- During consolidation processes to clear prior consolidation results

---

## Category

**Calc Script Command / Data Management / Block**

---

## Syntax

```essbase
CLEARBLOCK ALL;
CLEARBLOCK UPPER;
CLEARBLOCK NONINPUT;
```

### Formal Syntax

```
CLEARBLOCK clearOption;
```

Where:
- `clearOption` — Specifies which cells within the block to clear.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `clearOption` | Keyword | ✅ Yes | One of three options: **`ALL`** — clears every cell in the block (input and calculated). **`UPPER`** — clears only parent/aggregate-level cells (upper-level consolidation points). **`NONINPUT`** — clears only calculated/derived cells, preserving user-entered input data. |

---

## Return Value

`CLEARBLOCK` does not return a value — it **sets cells to `#MISSING`** based on the specified option.

---

## How It Works (Behind the Scenes)

1. **Block Context**: CLEARBLOCK operates on the block currently being processed. It's typically used inside a member formula or within a FIX block that iterates over blocks.

2. **Cell Classification**: Essbase tracks whether each cell was directly loaded/entered (input) or calculated through formulas/aggregation (non-input). CLEARBLOCK NONINPUT uses this classification.

3. **Block Removal**: If `CLEARBLOCK ALL` clears every cell in a block, the block itself is removed from memory and storage, similar to CLEARDATA.

4. **Upper-Level Determination**: "Upper" cells are those at parent/aggregate levels in dense dimensions. CLEARBLOCK UPPER targets these while preserving leaf-level data.

5. **Timing**: CLEARBLOCK is often used at the start of a calculation to clean up before recalculating. The clear happens immediately — subsequent statements in the same pass see #MISSING values.

6. **Performance**: CLEARBLOCK is highly efficient as it operates on the in-memory block without needing to identify individual cells.

---

## Syntax Variants & Scenarios

### Variant 1: Clear All Data in Block

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    CLEARBLOCK ALL;
    Revenue = Units * Price;
ENDFIX
```

### Variant 2: Clear Only Calculated Values

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    CLEARBLOCK NONINPUT;
    /* Recalculate derived values, inputs are preserved */
    "Gross Margin" = Revenue - COGS;
    "GM_Pct" = "Gross Margin" / Revenue * 100;
ENDFIX
```

### Variant 3: Clear Upper-Level Before Aggregation

```essbase
FIX("FY25", "Working")
    CLEARBLOCK UPPER;
ENDFIX
AGG("Account", "Entity");
```

### Variant 4: In a Member Formula

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Revenue"(
        CLEARBLOCK NONINPUT;
        "Revenue" = "Units" * "Price";
    )
ENDFIX
```

---

## Practical Examples

### Example 1: Recalculate Without Losing Inputs

**Scenario**: Users have entered Units and Price. You need to recalculate all derived metrics without disturbing their inputs.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    CLEARBLOCK NONINPUT;
    
    /* All derived values are now #MISSING. Recalculate: */
    Revenue = Units * Price;
    COGS = Units * "Unit Cost";
    "Gross Margin" = Revenue - COGS;
    "Operating Income" = "Gross Margin" - "Operating Expenses";
ENDFIX
```

**What Happens**:
- CLEARBLOCK NONINPUT sets all formula-derived cells to #MISSING
- Units, Price, Unit Cost, Operating Expenses (user inputs) are preserved
- Revenue, COGS, Gross Margin, Operating Income are recalculated fresh

---

### Example 2: Pre-Aggregation Cleanup

```essbase
/* Clear stale parent values */
FIX("FY25", "Working")
    CLEARBLOCK UPPER;
ENDFIX

/* Fresh aggregation */
AGG("Account");
AGG("Entity");
AGG("Period");
```

---

### Example 3: Full Reset and Seed

```essbase
/* Clear everything in Forecast */
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    CLEARBLOCK ALL;
ENDFIX

/* Seed from Actuals */
DATACOPY "Actual" TO "Forecast";
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| CLEARBLOCK ALL when you mean NONINPUT | ALL removes user inputs too — data loss | Use NONINPUT to preserve entered data |
| Using CLEARBLOCK without FIX | Affects all blocks in the database | Always scope with FIX |
| Forgetting to recalculate after NONINPUT | Derived values are now #MISSING — forms show blanks | Always follow CLEARBLOCK with calculation statements |
| CLEARBLOCK vs. CLEARDATA confusion | CLEARBLOCK works on the current block; CLEARDATA targets specific members | Use CLEARDATA for member-specific clearing; CLEARBLOCK for block-level |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CLEARDATA`](./CLEARDATA.md) | Clears specific member data — more targeted |
| [`AGG`](./AGG.md) | Re-aggregate after CLEARBLOCK UPPER |
| [`FIX`](./FIX.md) | Scopes which blocks CLEARBLOCK affects |
| [`DATACOPY`](./DATACOPY.md) | Often follows CLEARBLOCK ALL to reload data |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — CLEARBLOCK](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/clearblock.html)
