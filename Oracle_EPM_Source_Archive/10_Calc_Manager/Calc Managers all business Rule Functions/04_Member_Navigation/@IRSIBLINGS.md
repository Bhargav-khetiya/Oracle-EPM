# @IRSIBLINGS

## Overview

`@IRSIBLINGS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates an array containing the target member, plus all of the **Right Siblings** of that target member (members that share the exact same parent and appear structurally *after* the target member in the outline).

*(The "I" stands for Inclusive, and the "R" stands for Right).*

### Why Does This Function Exist—

In time-series modeling (like "Balance to Go" or "Remaining Year Forecasting"), the physical order of members in the database outline represents chronological progression (e.g., `Jan` is physically above `Feb`, `Feb` is above `Mar`).
If a script needs to calculate the remaining projected revenue for the year starting from the current month (`"Mar"`), it needs to sum `"Mar"` through `"Dec"`.
Native Time functions (like `@Y-T-D`) look backward, not forward. 
`@IRSIBLINGS` solves this by natively looking forward. By passing `"Mar"`, Essbase looks at the outline, grabs all the siblings that appear *after* it (`Apr` through `Dec`), explicitly includes the target itself (`Mar`), and returns the array. Wrapping this in an `@SUM` function instantly generates "Balance to Go" math on ANY dimension, completely untethered from Time-dimension restrictions.

### When to Use It

- **Balance-To-Go Math**: Calculating the remaining forecasted spend for the rest of the year (Current Month + All Future Months).
- **Phased Project Accruals**: Summing up the unbilled amounts for all remaining project milestones (`Milestone_3` through `Milestone_5`).
- **Sequential Allocations**: Distributing a massive upfront cost strictly to future periods without altering historical actuals.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@IRSIBLINGS(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member that serves as the anchor. The function will find all siblings structurally "below" this member. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members.
- **Order of Return**: The array is returned in the exact Top-Down order defined by the outline. It ALWAYS begins with the target `MemberName`, followed by the right siblings. (e.g., if you ask for the Right Siblings of `Mar`, it returns `"Mar", "Apr", "May..."`).
- **Inclusion**: The target `MemberName` is ALWAYS the first member in the array.
- **Empty Traversal**: If you pass the very last child of a parent (e.g., `"Dec"`), it has no Right Siblings. The function will simply return `"Dec"` itself without throwing an error.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Outline Query**: It queries the active `.otl` outline. It finds the parent of the target member.
3. **Sibling Sweep**: It looks at all the children of that parent.
4. **Boundary Detection**: It ignores everything until it hits the target `MemberName`. Once it finds the target, it collects it, and then continues collecting every single member after it until the parent's children are exhausted.
5. **Return**: It returns the concatenated array to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Remaining Balance Array

```essbase
/* 
   If Q2 shares a parent with Q1, Q3, Q4.
   Returns: "Q2", "Q3", "Q4"
*/
@IRSIBLINGS("Q2")
```

---

## Practical Examples

### Example 1: Calculating "Balance to Go"

**Scenario**: A forecasting application uses substitution variables (`&CurrMnth`) to track the active forecasting period (e.g., `"May"`). The FP&A team needs a script that calculates `"Balance_to_Go_Revenue"`, which is the sum of the revenue from the Current Month through the end of the year. The script uses `@IRSIBLINGS` wrapped around the substitution variable.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* 
       1. We calculate the Balance to Go.
       If &CurrMnth is "May", @IRSIBLINGS returns May, Jun, Jul... Dec.
       @SUM adds them all together.
    */
    "Balance_to_Go_Revenue" = @SUM(@IRSIBLINGS(&CurrMnth)->"Forecast_Revenue");
    
    /* 
       Results:
       The account now perfectly holds the remaining value for the year, 
       automatically updating whenever the &CurrMnth variable is advanced.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Structural Dependence | Assuming alphabetical sorting | Like all sibling functions, `@IRSIBLINGS` does NOT sort alphabetically. It relies 100% on the physical, structural order of the members in the outline. If `Dec` is physically above `Jan` in the outline, asking for the Right Siblings of `Nov` will not return `Dec`. You must strictly enforce the chronological order of your outline |
| Confusing Right and Left | `@IRSIBLINGS` vs `@ILSIBLINGS` | Right Siblings (`IRSIBLINGS`) represent the FUTURE (members below the target). Left Siblings (`ILSIBLINGS`) represent the PAST (members above the target). If you want to calculate a "Year-To-Date" or cumulative past sum, use `@ILSIBLINGS`. If you want "Remaining Balance", use `@IRSIBLINGS` |
| Using it inside IF statements | `IF(@IRSIBLINGS("Entity") == "USA")` | This function returns a massive array of multiple members. You cannot use standard mathematical equality (`==`) to compare an array to a single string inside an `IF` statement. This function belongs in `FIX` blocks or array processing functions like `@SUM` or `@MAX` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@RSIBLINGS`](./@RSIBLINGS.md) | The non-inclusive version. Returns all the future siblings, but specifically EXCLUDES the target member itself |
| [`@ILSIBLINGS`](./@ILSIBLINGS.md) | The backward-looking counterpart. Returns the target member and all siblings structurally BEFORE it (used for Year-To-Date math) |
| [`@ISIBLINGS`](./@ISIBLINGS.md) | The universal version. Returns the target member, plus ALL siblings (both Left and Right) simultaneously |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — IRSIBLINGS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/irsiblings.html)
