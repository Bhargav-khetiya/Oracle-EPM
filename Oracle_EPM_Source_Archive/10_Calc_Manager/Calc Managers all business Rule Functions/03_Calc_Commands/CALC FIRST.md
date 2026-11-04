# CALC FIRST

## Overview

`CALC FIRST` is a **specialized native Essbase calculation directive** in Oracle EPM Cloud (PBCS/EPBCS). Similar to `CALC AVERAGE`, it overrides the standard additive consolidation logic (`+`, `-`) of a dimension. Instead of summing the children together, `CALC FIRST` commands the engine to look at the children of a parent and exclusively write the **numeric value of the very first child** into the parent block, completely ignoring the rest of the children.

### Why Does This Function Exist—

Standard dimensional consolidation is additive (e.g., `Jan + Feb + Mar = Q1`). 
However, "Opening Balances" (such as Opening Cash or Opening Inventory) are explicitly non-additive metrics. The Opening Cash for `Q1` is not the sum of Jan, Feb, and Mar. The Opening Cash for `Q1` is simply whatever the Opening Cash was in `Jan`. 
Natively, administrators handle this using complex `Dynamic Calc` formulas or localized `FIX` statements to map Jan's value up to Q1. But if the Time dimension is deeply nested, or the non-additive metrics are sparse, dynamic formulas can cause severe retrieval lag.
`CALC FIRST` allows you to physically store the first-child values. You tell the engine to roll up the Time dimension, but instead of adding the months together, it grabs the first month of the quarter and physically writes it into the Quarter block. This creates instant retrieval times for balance sheet roll-forwards and non-additive inventory metrics.

### When to Use It

- **Opening Balances**: Rolling up Opening Cash, Opening Retained Earnings, or Opening Headcount up the Time dimension so Quarter and Year parents correctly reflect the start of the period.
- **Baseline Forecasting**: Propagating the first month's "Baseline Run-Rate" up to the parent level for high-level variance analysis.
- **Snapshot Metrics**: Rolling up point-in-time snapshot metrics (like "Starting Share Price") up structural hierarchies.

---

## Category

**System & Optimization / Aggregation Directives / Calculation Commands**

---

## Syntax

```essbase
CALC FIRST (DimName);
```

*(Note: Because this is a macro command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimName` | Dimension | ✅ Yes | The exact name of the dimension that should be aggregated using "First Child" logic instead of Addition logic (usually the `"Time"` dimension). |

---

## Return Value

**Return Type**: System Action (Block Aggregation)

This command does not return a value. It triggers a physical structural rollup of the specified dimension.
- **First Child Override**: As the engine steps up the tree, it identifies the absolute first physical child of the parent (based on `.otl` outline order). It extracts that child's value and writes it directly to the parent block.
- **Consolidation Operators Ignored**: This command aggressively overrides the `+`, `-`, `*`, `/`, and `~` operators defined in the outline. All other children are ignored, regardless of their operators.
- **Empty Children**: If the first child evaluates to `#MISSING`, the parent will receive `#MISSING`, even if the second or third child has data.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine reads the `CALC FIRST ("Period");` command.
2. **Index Sweep**: It drops to Level 0 of the `"Period"` tree.
3. **Parent Evaluation**: It looks at a Level 1 parent (e.g., `"Q1"`).
4. **Target Lock**: It identifies the children of `"Q1"` (`"Jan"`, `"Feb"`, `"Mar"`).
5. **Data Extraction**: Instead of summing them, it locks onto the very first child (`"Jan"`). It reads the data block for `"Jan"`.
6. **Physical Write**: It writes that exact data payload into the `"Q1"` parent block on the disk.
7. **Climb**: It steps to Level 2 (`"YearTotal"`). It looks at its children (`"Q1"`, `"Q2"`). It locks onto `"Q1"`, extracts the data, writes it to `"YearTotal"`, and finishes.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Up Opening Balances

```essbase
/* 
   Rolls up the Period dimension. Parent periods (Quarters/Years) 
   will physically store the exact value of their first child.
*/
CALC FIRST ("Period");
```

---

## Practical Examples

### Example 1: Calculating Quarter and Year Opening Inventory

**Scenario**: A warehouse application tracks `"Opening_Inventory"`. The users want to query the Opening Inventory at the `"Q1"`, `"Q2"`, and `"YearTotal"` levels. The administrator uses `CALC FIRST` inside a highly targeted FIX statement to physically aggregate the metric.

```essbase
/* 
   1. We MUST isolate this calculation to ONLY the non-additive metric.
   If we don't FIX on Opening_Inventory, Essbase will apply CALC FIRST to EVERYTHING.
   It will make Q1 Revenue equal to Jan Revenue, destroying the P&L!
*/
FIX("Opening_Inventory", "Actual", "FY25")
    
    /* 
       2. We command the engine to roll up the Period tree using FIRST logic.
       3. Q1 physically stores Jan's inventory.
       4. Q2 physically stores Apr's inventory.
       5. YearTotal physically stores Q1's inventory (which is Jan's inventory).
    */
    CALC FIRST ("Period");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting to Isolate the Account | Destroying Financials | This is the single most catastrophic mistake you can make with this command. If you write `CALC FIRST("Period");` without fixing on a specific balance-sheet account, Essbase will apply this logic to the entire database. Your Total Revenue for the year will magically equal your January Revenue. You MUST explicitly `FIX` on the specific opening-balance accounts before firing this command |
| Using it on Dynamic Dimensions | No Effect | If the dimension you are calling (e.g., `"Period"`) is tagged entirely as `Dynamic Calc` in the outline, this command does absolutely nothing. `CALC FIRST` is a macro that writes physical data to the disk. It cannot write data to a Dynamic Calc member. You must use `@RANGEFIRSTVAL` inside member formulas for dynamic calculations |
| Assuming it Skips Missing | Literal First Child | `CALC FIRST` strictly pulls the first physical child in the outline. If `"Jan"` is `#MISSING` but `"Feb"` has data, `Q1` will be `#MISSING`. If you need the logic to find the "first month that actually has data", you CANNOT use this macro. You must write a custom calculation using `@RANGEFIRSTVAL(SKIPMISSING)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CALC LAST`](./CALC%20LAST.md) | The exact opposite. Rolls up the dimension by grabbing the very LAST child (Closing Balances) |
| [`CALC AVERAGE`](./CALC%20AVERAGE.md) | Rolls up the dimension by calculating the mathematical mean of all children |
| [`@RANGEFIRSTVAL`](./@RANGEFIRSTVAL.md) | The programmatic/formulaic equivalent. Used in member formulas rather than as a global script command |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — CALC FIRST](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_first.html)
