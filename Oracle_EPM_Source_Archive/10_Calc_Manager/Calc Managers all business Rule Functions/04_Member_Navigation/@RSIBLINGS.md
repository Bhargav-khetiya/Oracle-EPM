# @RSIBLINGS

## Overview

`@RSIBLINGS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates an array containing all of the **Right Siblings** of a specified target member (members that share the exact same parent and appear physically *after* the target member in the outline structure).

*(The "R" stands for Right. Crucially, this function is **non-inclusive**; it explicitly excludes the target member itself).*

### Why Does This Function Exist?

In time-series forecasting, administrators frequently need to isolate the "Future" or calculate a "Balance to Go". If the current active forecast month is `"May"`, the business needs to execute predictive logic on all the months that come *after* May (Jun-Dec) without accidentally overwriting the actuals that live in Jan-May.
Because the physical outline order of Time dimensions represents chronological progression (`May` is above `Jun`, `Jun` is above `Jul`), you can use structural traversal to find the future. 
If you use `@IRSIBLINGS("May")`, it gives you May, Jun, Jul, Aug, etc. But May is already locked; you only want the pure future.
`@RSIBLINGS("May")` solves this. It scans the outline, identifies the target, explicitly ignores the target, and collects every single sibling that appears physically below/after it. This gives you a pure, isolated array of strictly future/remaining members.

### When to Use It

- **Balance to Go (BTG) Projections**: Calculating the remaining budget available for the rest of the year by executing math strictly on the months succeeding the current period.
- **Future-Period Clearances**: Zeroing out forecast data for all future months when a project's `"End_Date"` variable is triggered in the middle of the year.
- **Phase-Out Allocations**: Applying a declining depreciation schedule only to the remaining useful periods of an asset's lifespan.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@RSIBLINGS(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member that serves as the anchor. The function will find all siblings structurally "below" (Right of) this member. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members.
- **Order of Return**: The array is returned in the exact Top-Down order defined by the outline. (e.g., if you ask for the Right Siblings of `Mar`, it returns `"Apr", "May", "Jun"...`).
- **Exclusion**: The target `MemberName` is NEVER included in the final array.
- **Empty Traversal**: If you pass the absolute *last* child of a parent (e.g., `"Dec"`), it has no Right Siblings. Because the function is non-inclusive, it will return an **empty set**. If used inside a `FIX`, the `FIX` will safely bypass the calculation for that block.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Outline Query**: It queries the active `.otl` outline. It finds the direct parent of the target member.
3. **Target Lock**: It looks at the children of that parent. It scans down the list until it finds the target member.
4. **Sibling Sweep**: It completely ignores the target and every member above it (Left Siblings). It immediately begins collecting every member below the target into an internal list.
5. **Return**: Once it hits the end of the parent's branch, it returns the concatenated array to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Pure Future-Period Array

```essbase
/* 
   If Q2 shares a parent with Q1, Q3, and Q4.
   Returns: "Q3", "Q4"
*/
@RSIBLINGS("Q2")
```

---

## Practical Examples

### Example 1: Calculating "Balance To Go" for Forecast

**Scenario**: A rolling forecast model uses a substitution variable (`&CurrMnth`) to track the current active close month (e.g., `"May"`). The administrator needs a script that calculates the "Balance to Go" (how much budget is left for the rest of the year) and evenly spreads that remaining budget across the future months (`Jun` through `Dec`). They use `@RSIBLINGS` to dynamically isolate the future.

```essbase
/* 
   1. Calculate the Remaining Budget in memory.
*/
VAR vRemainingBudget = "Total_Annual_Budget" - @SUM(SKIPMISSING, @LSIBLINGS(&CurrMnth), &CurrMnth);

/* 
   2. The FIX uses @RSIBLINGS to isolate the future.
   If &CurrMnth is "May", this array resolves strictly to: Jun, Jul, Aug... Dec.
   It explicitly EXCLUDES May.
*/
FIX("Working", "Total_Company", @RSIBLINGS(&CurrMnth))
    
    /* 
       3. Allocate the remaining budget evenly across these future months.
       (Assuming 7 months remaining in the year).
    */
    "Forecast" = vRemainingBudget / 7;
    
ENDFIX

/* 
   The script is completely dynamic. When the admin changes &CurrMnth to "Jun" 
   next month, the script automatically re-focuses the allocation to Jul-Dec.
*/
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Structural Dependence | Assuming alphabetical sorting | Like all sibling functions, `@RSIBLINGS` relies 100% on the physical, structural order of the members in the outline. If the Time dimension is sorted improperly, this function will completely break chronological math. You must strictly enforce the chronological order of your outline |
| Confusing Right and Left | `@RSIBLINGS` vs `@LSIBLINGS` | Right Siblings (`RSIBLINGS`) represent the FUTURE (members below the target). Left Siblings (`LSIBLINGS`) represent the PAST (members above the target). If you want to lock historical actuals, you must use `@LSIBLINGS` |
| Using it inside IF statements | `IF(@RSIBLINGS("Entity") == "USA")` | This function returns an array of multiple members. You cannot use standard mathematical equality (`==`) to compare an array of multiple members to a single string inside an `IF` statement. This function belongs in `FIX` blocks or array processing functions like `@SUM` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@IRSIBLINGS`](./@IRSIBLINGS.md) | The inclusive version. Returns all the future siblings AND the target member itself |
| [`@LSIBLINGS`](./@LSIBLINGS.md) | The backward-looking counterpart. Returns all siblings structurally BEFORE the target member (often used for locking history) |
| [`@SIBLINGS`](./@SIBLINGS.md) | Returns ALL siblings (both Left and Right) but explicitly excludes the target member |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — RSIBLINGS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/rsiblings.html)
