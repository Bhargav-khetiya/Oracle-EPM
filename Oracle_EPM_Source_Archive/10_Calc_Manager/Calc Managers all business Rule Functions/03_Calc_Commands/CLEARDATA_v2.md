# CLEARDATA

## Overview

`CLEARDATA` is a **data management command** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **removes data values** from specified member intersections, setting them to `#MISSING`. It is one of the most frequently used commands in data lifecycle management — essential for resetting forecasts, clearing staging areas, and preparing data for reload.

### Why Does This Command Exist—

Before loading new data or running calculations, you often need a clean slate:
- **Forecast reset**: Clear last year's forecast before building a new one
- **Staging area cleanup**: Empty staging members before a data push
- **Scenario management**: Clear a "Working" scenario before copying from "Final"
- **Partial data clearing**: Remove specific accounts or entities without affecting others
- **Version management**: Clear draft versions before recalculation

### When to Use It

- Before running DATACOPY to avoid mixing old and new data
- At the start of a forecast business rule to reset prior values
- When clearing specific member intersections selectively
- To remove data from deactivated entities or discontinued accounts
- In data integration processes before loading external data

---

## Category

**Calc Script Command / Data Management / Clear**

---

## Syntax

```essbase
CLEARDATA memberSpec;
```

### Formal Syntax

```
CLEARDATA memberSpecification;
```

Where:
- `memberSpecification` — A member name, cross-dimensional reference, or member combination that identifies the data cells to clear. Can reference members from one or more dimensions.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `memberSpec` | Member specification | ✅ Yes | The member(s) whose data should be set to `#MISSING`. Can be a single member name (`"Revenue"`), a cross-dimensional reference (`"Revenue" -> "FY25"`), or used within a FIX block to target specific intersections. |

---

## Return Value

`CLEARDATA` does not return a value — it **sets target cells to `#MISSING`**.

---

## How It Works (Behind the Scenes)

1. **Block Removal**: In BSO, CLEARDATA works at the block level. When all cells in a data block become `#MISSING`, the block is physically removed from storage, freeing memory and disk space. This is fundamentally different from setting each cell to zero.

2. **Scope Interaction**: CLEARDATA is almost always used inside a FIX block. The FIX determines which blocks are affected. Without FIX, CLEARDATA would affect ALL intersections of the specified member across the entire database.

3. **Sparse vs. Dense**: Clearing a sparse member can remove entire blocks. Clearing a dense member sets cells to #MISSING within existing blocks but doesn't remove blocks unless ALL dense cells become #MISSING.

4. **Performance**: CLEARDATA is very fast because it operates at the block level. Clearing large sections of data (entire scenarios, years) is much faster than setting each cell to zero individually.

5. **Aggregation Impact**: After CLEARDATA, parent members will also show #MISSING if all children are cleared. You may need to re-aggregate after clearing and reloading data.

6. **Cannot Be Undone**: CLEARDATA is permanent. There is no undo. Always verify your FIX scope before running.

---

## Syntax Variants & Scenarios

### Variant 1: Clear a Single Member

```essbase
CLEARDATA "Revenue";
```
Clears Revenue across ALL other dimensions (use with caution!).

### Variant 2: Clear Within FIX Scope

```essbase
FIX("FY25", "Forecast")
    CLEARDATA "Revenue";
ENDFIX
```
Clears Revenue only in FY25 Forecast.

### Variant 3: Clear Entire Scenario

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    CLEARDATA @DESCENDANTS("Total Accounts");
ENDFIX
```
Clears all account data for FY25 Working across all entities.

### Variant 4: Clear with Cross-Dimensional Reference

```essbase
CLEARDATA "Working" -> "FY25";
```

### Variant 5: Clear Specific Accounts Only

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    CLEARDATA "Allocated_Overhead";
    CLEARDATA "Allocated_IT";
ENDFIX
```
Clears only allocation accounts before recalculating.

---

## Practical Examples

### Example 1: Clear and Recalculate Forecast

**Scenario**: Reset forecast data before running a new forecast calculation.

```essbase
/* Step 1: Clear existing forecast */
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    CLEARDATA @DESCENDANTS("Total Accounts");
ENDFIX

/* Step 2: Seed forecast from prior year actuals */
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    Revenue = Revenue -> "Actual" -> "FY24" * 1.08;
    COGS = COGS -> "Actual" -> "FY24" * 1.05;
ENDFIX
```

**What Happens**:
- Step 1 sets ALL account data to #MISSING in FY25 Forecast
- Step 2 writes new values based on prior year actuals
- No leftover data from previous forecast runs contaminates results

---

### Example 2: Clear Staging Before Data Push

```essbase
/* Clear staging area */
FIX("Working", "Jan":"Dec", @DESCENDANTS("Total Entity"))
    CLEARDATA "Staging_Revenue";
    CLEARDATA "Staging_COGS";
ENDFIX

/* Copy actuals to staging for review */
DATACOPY "Actual" TO "Staging_Revenue";
```

---

### Example 3: Clear Allocations Before Recalculation

```essbase
FIX("FY25", "Working")
    /* Clear all allocation results */
    FIX(@DESCENDANTS("Operating Departments"))
        CLEARDATA "IT_Allocation";
        CLEARDATA "HR_Allocation";
        CLEARDATA "Finance_Allocation";
    ENDFIX
    
    /* Now recalculate allocations fresh */
    FIX(@DESCENDANTS("Operating Departments"))
        "IT_Allocation" = "IT_Cost" -> "Corporate" * ("Headcount" / "Total_Headcount");
    ENDFIX
ENDFIX
```

---

### Example 4: Selective Clear for Entity Reorganization

**Scenario**: An entity was deactivated — clear its data.

```essbase
FIX("FY25", @DESCENDANTS("All Scenarios"))
    FIX("Deactivated_Entity_001")
        CLEARDATA @DESCENDANTS("Total Accounts");
    ENDFIX
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| CLEARDATA without FIX | Clears data across ALL dimensions — potentially the entire database | Always wrap CLEARDATA in a FIX block to scope it |
| Clearing parent members | Clearing a parent doesn't clear its children — they remain | Clear descendants: `CLEARDATA @DESCENDANTS("Parent")` |
| Forgetting to re-aggregate | After clearing and reloading, parent values may be stale | Run `AGG` or `CALC DIM` after CLEARDATA + data reload |
| CLEARDATA vs. setting to zero | CLEARDATA sets to #MISSING (removes blocks); `member = 0` sets to zero (keeps blocks) | Use CLEARDATA for true removal; use `= 0` if you need explicit zeros |
| No undo | CLEARDATA is permanent — there's no rollback | Test with a limited FIX scope first; keep backups |
| Clearing too broadly | `CLEARDATA "Revenue"` without FIX affects ALL scenarios and years | Scope to specific Scenario, Year, and Entity |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CLEARBLOCK`](./CLEARBLOCK.md) | Clears entire blocks — more granular control (UPPER, NONINPUT) |
| [`DATACOPY`](./DATACOPY.md) | Often used after CLEARDATA to load new data |
| [`FIX`](../01_Flow_Control/FIX.md) | Essential scope control for CLEARDATA |
| [`AGG`](./AGG.md) | Re-aggregate after clearing and reloading |
| [`SET CREATEBLOCKONEQ`](../02_SET_Commands/SET CREATEBLOCKONEQ.md) | Controls block creation after clearing |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — CLEARDATA](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/cleardata.html)
