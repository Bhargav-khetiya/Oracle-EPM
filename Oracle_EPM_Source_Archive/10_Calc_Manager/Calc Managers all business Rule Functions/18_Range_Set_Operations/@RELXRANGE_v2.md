# @RELXRANGE

## Overview

`@RELXRANGE` is a **native Essbase time-series tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an advanced, multi-dimensional array generator. It accepts a specific "Anchor" block, a defined cross-dimensional time range (`XrangeList`), and an integer offset. It then generates a discrete array of members relative to that anchor, seamlessly crossing year boundaries.

### Why Does This Function Exist—

When building highly customized rolling functions or dynamic allocations, you often need to find a block of time relative to another block of time, but you aren't currently calculating that block.
For example, if the script is currently calculating `"Q1"` of `"FY25"`, but it needs to generate an array of the 3 months leading up to the `"Launch_Date"` (which is a completely different variable, say `"Mar"` of `"FY24"`). 
You cannot use standard `@PRIORS` because `@PRIORS` is anchored to the *currently calculating block* (FY25-Q1). 
`@RELXRANGE` allows you to break free of the current calculation context. You explicitly hand it an anchor (e.g., `"Mar"`). You hand it an offset (e.g., `-3`). And you hand it an `XrangeList` to stitch the years together. It jumps to March, steps back 3 months, generates the array `["Dec", "Jan", "Feb"]`, and hands that array back to you. It is the ultimate custom time-machine array generator.

### When to Use It

- **Dynamic Event Horizons**: Generating a 6-month historical array leading up to a specific "Store Opening Date" (which varies by store) to calculate pre-opening capitalized expenses.
- **Custom Prior-Period Indexing**: Providing relative arrays into advanced mathematical functions (`@SUM`, `@MAX`) that are anchored to substitution variables rather than the current `FIX` context.
- **Rolling Averages on Static Anchors**: Calculating a trailing average that always looks backward from the exact same month (e.g., Year-End Close), regardless of what month the engine is currently calculating.

---

## Category

**Mathematical / Array Processing & Shifting / Essbase Native Functions**

---

## Syntax

```essbase
@RELXRANGE(anchorMbr, shiftCnt, XrangeList)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `anchorMbr` | Member | ✅ Yes | The specific time member you want to start from (the anchor point). |
| `shiftCnt` | Integer | ✅ Yes | The mathematical offset. Negative (`-3`) looks backward/left. Positive (`3`) looks forward/right. |
| `XrangeList`| Member List | ✅ Yes | The custom multi-dimensional time range over which the shift occurs (e.g., `@XRANGE("FY24"->"Jan", "FY25"->"Dec")`). This is what allows the function to cross year boundaries. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of the structural time periods defined by the offset relative to the anchor.
- **Inclusivity vs Exclusivity**: If you specify a negative shift (`-3`), it returns the 3 members PRECEDING the anchor (exclusive of the anchor). If you specify a positive shift (`3`), it returns the 3 members SUCCEEDING the anchor (exclusive of the anchor).
- **Out of Bounds**: If the shift pushes the array entirely outside the bounds of the provided `XrangeList`, it returns an empty array.
- **Array Passthrough**: Because it returns an array of members, it must be wrapped in a mathematical function (like `@SUM(@RELXRANGE(...))`) to actually query the data in those blocks.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The C-engine hits `@RELXRANGE` inside a parent function (like `@AVG`).
2. **Boundary Setup**: It compiles the `XrangeList`, stitching the multiple years/periods into a single virtual timeline in memory.
3. **Anchor Lock**: It finds the `anchorMbr` inside that virtual timeline.
4. **Trajectory**: It reads the `shiftCnt`. If it is `-3`, it steps backwards from the anchor, collecting the 3 members into an array.
5. **Handoff**: It hands that array (e.g., `["FY24"->"Nov", "FY24"->"Dec", "FY25"->"Jan"]`) back to the parent function for calculation.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Preceding Quarter Across Years

```essbase
/* 
   If the anchor is FY25->Feb, and shift is -3.
   This returns an array of the 3 months PRIOR to Feb.
*/
VAR vAnchor = "Feb";
"Pre_Launch_Total" = @SUM(SKIPMISSING, 
    @RELXRANGE(vAnchor, -3, @XRANGE("FY24"->"Jan", "FY25"->"Dec"))
);
```

---

## Practical Examples

### Example 1: Summing Pre-Opening Expenses (Variable Anchors)

**Scenario**: A retail company capitalizes "Pre-Opening Expenses" for new stores. The rule is that the 3 months *immediately prior* to the `"Grand_Opening"` month can be capitalized. Every store has a different Grand Opening month, stored as a numeric date in a driver account. The FP&A admin uses `@RELXRANGE` to dynamically generate the 3-month look-back array based on that specific store's anchor month.

*(Assume we have already converted the driver date into an active member pointer stored in `vOpenMonth`)*.

```essbase
FIX("FY25", "Working", @LEVEL0("Stores"))
    
    /* 
       1. vOpenMonth holds the dynamic anchor (e.g., "Apr").
       2. We use @RELXRANGE to step backward -3 periods from "Apr", 
       crossing into FY24 if necessary.
       3. We wrap the resulting array in @SUM to grab the expenses.
    */
    "Capitalized_Expenses" = @SUM(SKIPMISSING, 
        @RELXRANGE(vOpenMonth, -3, @XRANGE("FY24"->"Jan", "FY25"->"Dec"))
    );
    
    /* 
       Results for Store 101 (Opened in Apr):
       The engine jumps to Apr. Steps back 3 months: Jan, Feb, Mar.
       Sums the expenses for those 3 months. Writes to Capitalized_Expenses.
       
       Results for Store 102 (Opened in Feb):
       The engine jumps to Feb. Steps back 3 months: FY24-Nov, FY24-Dec, FY25-Jan.
       Sums the expenses. Writes to Capitalized_Expenses.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting `XrangeList` Requirements | Syntax Failures | Unlike simple functions like `@PRIORS` (where `XrangeList` is optional), `@RELXRANGE` strictly requires the `XrangeList` as its third parameter. It cannot function without knowing the specific chronological boundaries it is allowed to operate within. You must explicitly build it using `@XRANGE` |
| Assigning the Output directly | `"Sales" = @RELXRANGE()` | As with all functions that end in "RANGE", this function generates an ARRAY of members, not a data value. You cannot assign an array to a data block. You MUST wrap `@RELXRANGE` inside a mathematical aggregator like `@SUM`, `@MAX`, or `@AVG` to actually process the data inside those blocks |
| Structural Dependence | Assuming alphabetical sorting | The `XrangeList` stitches members together based on their physical order in the outline. If `"Dec"` is physically placed above `"Jan"` in the outline by mistake, `@RELXRANGE` will literally step backward from Jan into Dec. You must strictly enforce chronological outline structures |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@XRANGE`](./@XRANGE.md) | The foundational utility function used to build the `XrangeList` required by this function |
| [`@PRIORS`](../17_Time_Series/@PRIORS.md) | Generates historical arrays, but is strictly anchored to the *current* calculating member, rather than allowing a custom anchor |
| [`@SHIFT`](../17_Time_Series/@SHIFT.md) | Shifts a data pointer by an offset, but returns a single value rather than an array of members |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — RELXRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/relxrange.html)
