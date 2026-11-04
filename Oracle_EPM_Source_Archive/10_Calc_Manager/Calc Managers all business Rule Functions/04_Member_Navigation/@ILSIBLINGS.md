# @ILSIBLINGS

## Overview

`@ILSIBLINGS` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It queries the database outline and generates an array containing the target member, plus all of the **Left Siblings** of that target member (members that share the exact same parent and appear *before* the target member in the outline structure). 

*(The "I" stands for Inclusive, and the "L" stands for Left).*

### Why Does This Function Exist—

In time-series modeling (like Year-To-Date aggregations) or sequential phasing (like Project Milestones), the physical order of members in the database outline represents chronological progression (e.g., `Jan` is physically above `Feb`, `Feb` is above `Mar`).
If a calculation script needs to calculate a Year-To-Date sum for `"Mar"`, it needs to sum `"Jan"`, `"Feb"`, and `"Mar"`. 
Natively, you could use `@Y-T-D`, but that only works on dimensions explicitly tagged as "Time". If you have a custom `"Project_Phases"` dimension (`Phase1`, `Phase2`, `Phase3`), and you want the cumulative spend for `Phase3`, you cannot use Time functions.
`@ILSIBLINGS` solves this. By passing `"Phase3"`, Essbase looks at the outline, grabs all the siblings that appear *before* it (`Phase1`, `Phase2`), includes the target itself (`Phase3`), and returns the array. You can wrap this array in an `@SUM` function to instantly generate cumulative Year-To-Date style math on ANY dimension in the database.

### When to Use It

- **Custom Cumulative Math**: Creating "Life-To-Date" or "Year-To-Date" aggregations on custom, non-Time dimensions (like calculating cumulative units sold up to the current `"Milestone_4"`).
- **Sequential Allocations**: Ensuring that an allocation rule only distributes data to prior sequence nodes, preventing data from bleeding into future, unapproved nodes.
- **Reporting Ranges**: Creating a dynamic `DATAEXPORT` range that exports everything from the start of the year up to the current active month, without exporting future empty months.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@ILSIBLINGS(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member that serves as the anchor. The function will find all siblings structurally "above" this member. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members.
- **Order of Return**: The array is returned in the exact Top-Down order defined by the outline. (e.g., if you ask for the Left Siblings of `Mar`, it returns `"Jan", "Feb", "Mar"`).
- **Inclusion**: The target `MemberName` is ALWAYS the final member in the array.
- **Empty Traversal**: If you pass the very first child of a parent (e.g., `"Jan"`), it has no Left Siblings. The function will simply return `"Jan"` itself without throwing an error.

---

## How It Works (Behind the Scenes)

1. **Member Resolution**: Essbase evaluates the target `MemberName`.
2. **Outline Query**: It queries the active `.otl` outline. It finds the parent of the target member.
3. **Sibling Sweep**: It looks at all the children of that parent. It starts from the top and begins collecting members.
4. **Boundary**: As soon as it reaches the target `MemberName`, it collects it and STOPS scanning. (It completely ignores any Right Siblings).
5. **Return**: It returns the concatenated array to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Custom Year-To-Date Array

```essbase
/* 
   If Phase_3 shares a parent with Phase_1, Phase_2, Phase_4, and Phase_5.
   Returns: "Phase_1", "Phase_2", "Phase_3"
*/
@ILSIBLINGS("Phase_3")
```

---

## Practical Examples

### Example 1: Calculating Life-To-Date Spend on a Custom Dimension

**Scenario**: A Capital Planning application has a custom dimension called `Milestones` (`M1`, `M2`, `M3`, `M4`, `M5`). A script calculates `"Current_Spend"`. The finance team requires an account called `"Cumulative_Spend"` that sums the current milestone and all previous milestones. Because `Milestones` is not a Time dimension, `@Y-T-D` will not work. The script uses `@ILSIBLINGS` to build the sum range.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    /* 
       1. We dynamically calculate the Cumulative Spend for whatever 
       Milestone we are currently evaluating.
    */
    "Cumulative_Spend" = @SUM(@ILSIBLINGS(@CURRMBR("Milestones"))->"Current_Spend");
    
    /* 
       If the engine is currently calculating M3:
       @ILSIBLINGS returns M1, M2, M3.
       @SUM adds them together.
       "Cumulative_Spend" for M3 becomes the sum of M1 + M2 + M3.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Structural Dependence | Assuming alphabetical sorting | `@ILSIBLINGS` does NOT sort alphabetically. It relies 100% on the physical, structural order of the members in the Essbase `.otl` file. If an administrator accidentally drags `Phase4` above `Phase1` in the outline editor, this function will mathematically break. You must strictly enforce the chronological order of your outline members if you rely on Left/Right sibling functions |
| Confusing Left and Right | `@ILSIBLINGS` vs `@IRSIBLINGS` | Left Siblings (`ILSIBLINGS`) represent the PAST (members above the target). Right Siblings (`IRSIBLINGS`) represent the FUTURE (members below the target). If you want to calculate a "Balance to Go" or "Remaining Forecast", you need the future, so use `@IRSIBLINGS` |
| Using it inside IF statements | `IF(@ILSIBLINGS("Entity") == "USA")` | This function returns an array (a list of multiple members). You cannot use standard mathematical equality (`==`) to compare an array of multiple members to a single string inside an `IF` statement. This function belongs in `FIX` blocks or range functions like `@SUM`, `@AVG`, or `@MIN` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@LSIBLINGS`](./@LSIBLINGS.md) | The non-inclusive version. Returns all the prior siblings, but specifically EXCLUDES the target member itself |
| [`@IRSIBLINGS`](./@IRSIBLINGS.md) | The forward-looking counterpart. Returns the target member and all siblings structurally AFTER it (often used for "Remaining Balance" math) |
| [`@ISIBLINGS`](./@ISIBLINGS.md) | The universal version. Returns the target member, plus ALL siblings (both Left and Right) simultaneously |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ILSIBLINGS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ilsiblings.html)
