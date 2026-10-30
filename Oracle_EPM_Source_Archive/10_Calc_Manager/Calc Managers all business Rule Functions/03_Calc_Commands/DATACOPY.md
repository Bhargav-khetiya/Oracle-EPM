# DATACOPY

## Overview

`DATACOPY` is a **data movement command** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **copies data** from one member intersection to another within the same database. It is one of the most commonly used commands for scenario seeding, version management, and data staging.

### Why Does This Command Exist?

Data frequently needs to be duplicated between members:
- **Forecast seeding**: Copy Actuals to Forecast as a starting point
- **Version management**: Copy Working to Final after approval
- **What-if analysis**: Copy Budget to a sandbox scenario for experimentation
- **Period rollover**: Copy December closing to January opening balance
- **Data staging**: Copy data to staging members for validation before finalizing

### When to Use It

- To seed a forecast from prior year actuals
- To copy an approved budget from Working to Final
- To create a backup of data before making changes
- To copy data between scenarios, versions, or years
- To initialize a new period with prior period data

---

## Category

**Calc Script Command / Data Management / Copy**

---

## Syntax

```essbase
DATACOPY source TO destination;
```

### Formal Syntax

```
DATACOPY sourceMember TO destinationMember;
```

Where:
- `sourceMember` — The member (or cross-dimensional reference) to copy FROM
- `destinationMember` — The member (or cross-dimensional reference) to copy TO
- Source and destination must be from the **same dimension**
- The `TO` keyword is required

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | Member name | ✅ Yes | The source member to copy data FROM. Can be a single member name or cross-dimensional reference. Must be from the same dimension as the destination. |
| `destination` | Member name | ✅ Yes | The destination member to copy data TO. Existing data at the destination is overwritten. Must be from the same dimension as the source. |

---

## Return Value

`DATACOPY` does not return a value — it **copies cell values** from source to destination intersections.

---

## How It Works (Behind the Scenes)

1. **Block-Level Copy**: DATACOPY operates at the block level in BSO. For each source block, it creates (or overwrites) a corresponding destination block with identical data. This makes it very efficient — much faster than cell-by-cell formula copying.

2. **Scope Interaction**: When used inside a FIX block, DATACOPY only copies blocks that match the FIX scope. This is critical — without FIX, DATACOPY copies ALL intersections.

3. **Block Creation**: If the destination block doesn't exist, DATACOPY creates it (subject to `SET COPYMISSINGBLOCK` settings). This means DATACOPY can create blocks that didn't previously exist.

4. **Missing Values**: If the source block exists but the destination doesn't, DATACOPY creates the destination block. If the source block doesn't exist (all #MISSING), behavior depends on `SET COPYMISSINGBLOCK` — by default, no destination block is created for missing source blocks.

5. **Same Dimension Only**: Source and destination must be from the same dimension. You can't copy from a Period member to a Scenario member. For cross-dimension operations, use formulas.

6. **Performance**: DATACOPY is one of the fastest operations in Essbase because it copies block data structures directly, without evaluating formulas or processing individual cells.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Scenario Copy

```essbase
DATACOPY "Actual" TO "Forecast";
```
Copies ALL Actual data to Forecast across ALL other dimensions.

### Variant 2: Scoped Copy with FIX

```essbase
FIX("FY25", @DESCENDANTS("Total Entity"))
    DATACOPY "Actual" TO "Forecast";
ENDFIX
```
Copies only FY25 Actual data to Forecast.

### Variant 3: Version Copy

```essbase
FIX("FY25", "Budget", @DESCENDANTS("Total Entity"))
    DATACOPY "Working" TO "Final";
ENDFIX
```
Finalizes the budget by copying Working to Final.

### Variant 4: Year-to-Year Copy

```essbase
FIX("Forecast", "Working", @DESCENDANTS("Total Entity"))
    DATACOPY "FY24" TO "FY25";
ENDFIX
```
Seeds FY25 forecast from FY24 data.

### Variant 5: Clear Then Copy

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    CLEARDATA @DESCENDANTS("Total Accounts");
ENDFIX

FIX("FY25", @DESCENDANTS("Total Entity"))
    DATACOPY "Actual" TO "Forecast";
ENDFIX
```
Clears destination first to avoid mixing old and new data.

### Variant 6: Copy Specific Account Range

```essbase
FIX("FY25", "Working", @DESCENDANTS("Revenue Accounts"))
    DATACOPY "Budget" TO "Forecast";
ENDFIX
```
Copies only revenue accounts from Budget to Forecast.

---

## Practical Examples

### Example 1: Forecast Seeding from Actuals

**Scenario**: At the start of the forecast cycle, seed the Forecast with prior year Actuals as a baseline.

```essbase
/* Step 1: Clear existing forecast */
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    CLEARDATA @DESCENDANTS("Total Accounts");
ENDFIX

/* Step 2: Copy actuals as baseline */
FIX("FY25", @DESCENDANTS("Total Entity"))
    DATACOPY "Actual" TO "Forecast";
ENDFIX

/* Step 3: Apply growth adjustments */
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    Revenue = Revenue * 1.08;
ENDFIX
```

**What Happens**:
- Step 1 ensures no leftover data from prior forecast
- Step 2 copies ALL Actual data (all accounts) to Forecast
- Step 3 applies an 8% growth to Revenue in the Forecast

---

### Example 2: Budget Approval Workflow

```essbase
/* Manager approves: copy Working to Final */
FIX("FY25", "Budget", @DESCENDANTS("Total Entity"))
    /* Clear Final first */
    CLEARDATA @DESCENDANTS("Total Accounts") -> "Final";
ENDFIX

FIX("FY25", "Budget", @DESCENDANTS("Total Entity"))
    DATACOPY "Working" TO "Final";
ENDFIX
```

---

### Example 3: Period Rollover (Opening Balance)

```essbase
FIX("FY25", "Jan", "Working")
    DATACOPY "Closing_Balance" -> "FY24" -> "Dec" TO "Opening_Balance";
ENDFIX
```

---

### Example 4: What-If Scenario Creation

```essbase
/* Create a sandbox from approved budget */
FIX("FY25", @DESCENDANTS("Total Entity"), @DESCENDANTS("Total Accounts"))
    DATACOPY "Budget" TO "Sandbox";
ENDFIX

/* Now users can modify Sandbox without affecting Budget */
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| DATACOPY without FIX | Copies ALL data — potentially millions of blocks | Always scope with FIX |
| Not clearing destination first | Old data in destination mixes with copied data | Clear destination with CLEARDATA before DATACOPY |
| Cross-dimension copy attempt | `DATACOPY "Jan" TO "Budget"` fails — different dimensions | Source and destination must be from the same dimension |
| Expecting formula results to copy | DATACOPY copies stored values, not dynamic calc results | Calculate first, then copy — or ensure source has stored values |
| SET COPYMISSINGBLOCK OFF | Missing source blocks won't create destination blocks | Set ON if you need to copy #MISSING intersections |
| Copying to the same member | `DATACOPY "Actual" TO "Actual"` is a no-op | Ensure source ≠ destination |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CLEARDATA`](./CLEARDATA.md) | Clear destination before copy |
| [`CLEARBLOCK`](./CLEARBLOCK.md) | Clear blocks before copy |
| [`FIX`](./FIX.md) | Essential scope for DATACOPY |
| [`SET COPYMISSINGBLOCK`](./SET%20COPYMISSINGBLOCK.md) | Controls missing block behavior |
| [`AGG`](./AGG.md) | Re-aggregate after copy |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — DATACOPY](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/datacopy.html)
