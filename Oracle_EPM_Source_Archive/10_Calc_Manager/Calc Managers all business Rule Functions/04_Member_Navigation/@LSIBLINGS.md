# @LSIBLINGS

## Overview

`@LSIBLINGS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates an array containing all of the **Left Siblings** of a specified target member (members that share the exact same parent and appear physically *before* the target member in the outline structure).

*(The "L" stands for Left. Crucially, this function is **non-inclusive**; it explicitly excludes the target member itself).*

### Why Does This Function Exist—

In time-series forecasting, calculating actuals versus budget often requires splitting the year. If you are forecasting starting in `"May"`, you need to know exactly which months came *before* May so you can lock their data or copy their actuals.
Because the physical outline order of Time dimensions represents chronological progression (`Jan` is above `Feb`, `Feb` is above `Mar`), you can use structural traversal to find the past. 
If you use `@ILSIBLINGS("May")`, it gives you Jan, Feb, Mar, Apr, AND May. But you don't want May; May is the current forecast month, not the past. 
`@LSIBLINGS("May")` solves this. It scans the outline, grabs all the siblings that appear before the target, stops exactly when it hits the target, and intentionally drops the target from the array. This gives you a pure, isolated array of strictly historical/prior members.

### When to Use It

- **Historical Data Locks**: Applying a `READONLY` or zero-out calculation strictly to the months that have already closed, dynamically anchored by the current active forecasting month.
- **Prior-Period Aggregations**: Summing up all expenses incurred *before* the current project milestone to calculate sunk costs, explicitly excluding the current milestone's spend.
- **Copying Actuals to Forecast**: Generating a dynamic source array to copy actuals into a forecast scenario strictly for the months that precede the current cut-over variable.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@LSIBLINGS(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member that serves as the anchor. The function will find all siblings structurally "above" (Left of) this member. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members.
- **Order of Return**: The array is returned in the exact Top-Down order defined by the outline. (e.g., if you ask for the Left Siblings of `Mar`, it returns `"Jan", "Feb"`).
- **Exclusion**: The target `MemberName` is NEVER included in the final array.
- **Empty Traversal**: If you pass the very first child of a parent (e.g., `"Jan"`), it has no Left Siblings. Because the function is non-inclusive, it will return an **empty set**. If used inside a `FIX`, the `FIX` will safely bypass the calculation for that block.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Outline Query**: It queries the active `.otl` outline. It finds the direct parent of the target member.
3. **Sibling Sweep**: It looks at all the children of that parent. It starts from the top (the absolute first child) and begins collecting members into an internal list.
4. **Boundary Detection**: As soon as it reaches the target `MemberName`, it STOPS scanning. It deliberately discards the target member and completely ignores any Right Siblings.
5. **Return**: It returns the concatenated array to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Pure Prior-Period Array

```essbase
/* 
   If Q3 shares a parent with Q1, Q2, and Q4.
   Returns: "Q1", "Q2"
*/
@LSIBLINGS("Q3")
```

---

## Practical Examples

### Example 1: Copying Historical Actuals to Forecast

**Scenario**: A rolling forecast model uses a substitution variable (`&CurrMnth`) to track the current active forecast month (e.g., `"Jun"`). The administrator needs a script that dynamically copies `"Actuals"` into the `"Forecast"` scenario, but ONLY for the months that have already happened (`Jan` through `May`). They use `@LSIBLINGS` wrapped around the substitution variable to generate the dynamic list of past months.

```essbase
/* 
   1. The FIX uses @LSIBLINGS to isolate the past.
   If &CurrMnth is "Jun", this array resolves strictly to: Jan, Feb, Mar, Apr, May.
   It explicitly EXCLUDES Jun, ensuring we don't overwrite the active forecast.
*/
FIX("Working", "Total_Company", @LSIBLINGS(&CurrMnth))
    
    /* 
       2. Copy the actuals into the forecast for these historical months.
    */
    "Forecast" = "Actuals";
    
ENDFIX

/* 
   The script is completely dynamic. When the admin changes &CurrMnth to "Jul" 
   next month, the script automatically copies Jan-Jun without any code changes.
*/
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Structural Dependence | Assuming alphabetical sorting | Like all sibling functions, `@LSIBLINGS` relies 100% on the physical, structural order of the members in the outline. If an administrator accidentally sorts the Time dimension alphabetically (`Apr`, `Aug`, `Dec`, `Feb`), this function will completely break chronological math. You must strictly enforce the chronological order of your outline |
| Confusing Left and Right | `@LSIBLINGS` vs `@RSIBLINGS` | Left Siblings (`LSIBLINGS`) represent the PAST (members above the target). Right Siblings (`RSIBLINGS`) represent the FUTURE (members below the target). If you want to calculate a "Balance to Go" (future), you must use `@RSIBLINGS` |
| Using it inside IF statements | `IF(@LSIBLINGS("Entity") == "USA")` | This function returns an array of multiple members. You cannot use standard mathematical equality (`==`) to compare an array of multiple members to a single string inside an `IF` statement. This function belongs in `FIX` blocks or array processing functions like `@SUM` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ILSIBLINGS`](./@ILSIBLINGS.md) | The inclusive version. Returns all the prior siblings AND the target member itself (often used for Year-To-Date math) |
| [`@RSIBLINGS`](./@RSIBLINGS.md) | The forward-looking counterpart. Returns all siblings structurally AFTER the target member (often used for Remaining Balance math) |
| [`@SIBLINGS`](./@SIBLINGS.md) | Returns ALL siblings (both Left and Right) but explicitly excludes the target member |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — LSIBLINGS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/lsiblings.html)
