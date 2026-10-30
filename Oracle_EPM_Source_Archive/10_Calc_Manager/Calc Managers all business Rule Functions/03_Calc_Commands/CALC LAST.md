# CALC LAST

## Overview

`CALC LAST` is a **specialized native Essbase calculation directive** in Oracle EPM Cloud (PBCS/EPBCS). Just like `CALC FIRST`, it aggressively overrides the standard additive consolidation logic (`+`, `-`) of a dimension outline. Instead of summing the children together to calculate the parent, `CALC LAST` commands the engine to look at the children and exclusively write the **numeric value of the very last child** into the parent block, completely ignoring the previous children.

### Why Does This Function Exist?

In corporate accounting, closing metrics are pervasive. "Closing Cash", "Closing Headcount", "Ending Retained Earnings", and "Ending Inventory" are all non-additive metrics. The Closing Cash for `Q1` is not the sum of Jan, Feb, and Mar. The Closing Cash for `Q1` is simply whatever the cash balance was at the end of `Mar`. 
If you try to map this dynamically using `@PRIOR` or complex `IF` statements in a massive outline, the retrieval time for parent-level balance sheets becomes disastrous.
`CALC LAST` is the physical aggregation solution. You tell the engine to roll up the Time dimension, but instead of adding the months, it grabs the last month of the quarter and physically writes it into the Quarter block on the disk. This creates instantaneous query performance for executive balance sheet dashboards.

### When to Use It

- **Closing Balances**: Rolling up Closing Cash, Ending Inventory, or Closing Headcount up the Time dimension so Quarter and Year parents correctly reflect the final state of the period.
- **Latest Run-Rates**: Pushing the final month's run-rate metrics up to the parent level for high-level baseline comparative reporting.
- **Ending Snapshots**: Aggregating ending liability or debt metrics that do not naturally sum over time.

---

## Category

**System & Optimization / Aggregation Directives / Calculation Commands**

---

## Syntax

```essbase
CALC LAST (DimName);
```

*(Note: Because this is a macro command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimName` | Dimension | ✅ Yes | The exact name of the dimension that should be aggregated using "Last Child" logic instead of Addition logic (usually the `"Time"` or `"Period"` dimension). |

---

## Return Value

**Return Type**: System Action (Block Aggregation)

This command does not return a value. It triggers a physical structural rollup of the specified dimension.
- **Last Child Override**: As the engine steps up the tree, it identifies the absolute final physical child of the parent (based on `.otl` outline order). It extracts that child's value and writes it directly to the parent block.
- **Consolidation Operators Ignored**: This command aggressively overrides the `+`, `-`, `*`, `/`, and `~` operators defined in the outline. All prior children are ignored, regardless of their operators.
- **Empty Children**: If the last child evaluates to `#MISSING`, the parent will receive `#MISSING`, even if the previous children contained massive amounts of data.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine reads the `CALC LAST ("Period");` command.
2. **Index Sweep**: It drops to Level 0 of the `"Period"` tree.
3. **Parent Evaluation**: It looks at a Level 1 parent (e.g., `"Q1"`).
4. **Target Lock**: It identifies the children of `"Q1"` (`"Jan"`, `"Feb"`, `"Mar"`).
5. **Data Extraction**: Instead of summing them, it locks onto the very last child (`"Mar"`). It reads the data block for `"Mar"`.
6. **Physical Write**: It writes that exact data payload into the `"Q1"` parent block on the disk.
7. **Climb**: It steps to Level 2 (`"YearTotal"`). It looks at its children (`"Q1"`, `"Q2"`, `"Q3"`, `"Q4"`). It locks onto `"Q4"`, extracts the data, writes it to `"YearTotal"`, and finishes.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Up Closing Balances

```essbase
/* 
   Rolls up the Period dimension. Parent periods (Quarters/Years) 
   will physically store the exact value of their final child.
*/
CALC LAST ("Period");
```

---

## Practical Examples

### Example 1: Calculating Quarter and Year Closing Headcount

**Scenario**: HR tracks `"Closing_Headcount"` every month. The executives want to view the Closing Headcount at the Quarter and Year-Total level on their physical dashboard. The administrator uses `CALC LAST` inside a heavily protected FIX statement to roll up the non-additive metric.

```essbase
/* 
   1. We MUST isolate this calculation to ONLY the non-additive metric.
   If we don't FIX on Closing_Headcount, Essbase will apply CALC LAST to EVERYTHING.
   It will make Q1 Revenue equal to Mar Revenue, destroying the income statement!
*/
FIX("Closing_Headcount", "Actual", "FY25")
    
    /* 
       2. We command the engine to roll up the Period tree using LAST logic.
       3. Q1 physically stores Mar's headcount.
       4. Q2 physically stores Jun's headcount.
       5. YearTotal physically stores Q4's headcount (which is Dec's headcount).
    */
    CALC LAST ("Period");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting to Isolate the Account | Destroying Financials | Just like `CALC FIRST`, this is the single most catastrophic mistake you can make. If you write `CALC LAST("Period");` without fixing on a specific balance-sheet account, Essbase will apply this logic to the entire database. Your Total Revenue for the year will literally just be your December Revenue. You MUST explicitly `FIX` on the specific closing-balance accounts before firing this macro |
| Assuming it Finds Latest Actuals | Literal Last Child | `CALC LAST` strictly pulls the last physical child in the outline (e.g., `"Dec"`). If you run this script in July, August through December are `#MISSING`. `CALC LAST` will grab December, see `#MISSING`, and write `#MISSING` to the YearTotal. If you want the "Latest Active Run-Rate" (which would be July), you CANNOT use this command. You must write a custom calculation using `@RANGELASTVAL(SKIPMISSING)` |
| Using it on Dynamic Dimensions | No Effect | If the dimension you are calling (e.g., `"Period"`) is tagged entirely as `Dynamic Calc` in the outline, this command does absolutely nothing. `CALC LAST` writes physical data to the disk. It cannot write data to a Dynamic Calc member |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CALC FIRST`](./CALC%20FIRST.md) | The exact opposite. Rolls up the dimension by grabbing the very FIRST child (Opening Balances) |
| [`CALC AVERAGE`](./CALC%20AVERAGE.md) | Rolls up the dimension by calculating the mathematical mean of all children |
| [`@RANGELASTVAL`](./@RANGELASTVAL.md) | The programmatic/formulaic equivalent. Used in member formulas to dynamically find closing values, capable of utilizing `SKIPMISSING` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — CALC LAST](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_last.html)
