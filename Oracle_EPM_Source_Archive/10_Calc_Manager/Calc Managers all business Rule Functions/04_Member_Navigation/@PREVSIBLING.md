# @PREVSIBLING

## Overview

`@PREVSIBLING` is a **member navigation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **previous sibling** of a member — the member that appears immediately before it in outline order under the same parent.

### Why Does This Function Exist?

Sequential navigation within a hierarchy level enables:
- Period-over-period comparisons (Feb vs. Jan, Mar vs. Feb)
- Running totals that accumulate across siblings
- Sequential processing where each member depends on the previous
- Waterfall calculations that flow from one sibling to the next

### When to Use It

- For sequential period calculations (month-over-month changes)
- In running total or cumulative calculations
- When building waterfall or cascade calculations
- When you need the "previous" member at the same hierarchy level
- For sequential variance analysis

---

## Category

**Member / Relationship / Navigation**

---

## Syntax

```essbase
@PREVSIBLING(mbrName)
```

### Formal Syntax

```
@PREVSIBLING(memberNameOrFunction)
```

Where:
- `memberNameOrFunction` — The member whose previous sibling to find.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name or function | ✅ Yes | The reference member. @PREVSIBLING returns the sibling immediately before this member in outline order. If the member is the FIRST child (no previous sibling), returns `#MISSING` or the member itself depending on context. |

---

## Return Value

| Input | Returns |
|-------|---------|
| Has previous sibling | The previous sibling member |
| First child (no previous) | `#MISSING` or itself |

**Return Type**: Member reference

---

## How It Works (Behind the Scenes)

1. **Outline Order**: Siblings are ordered by their position in the outline. @PREVSIBLING returns the member immediately above (before) the specified member under the same parent.

2. **First Child**: If the specified member is the first child of its parent, there is no previous sibling. The behavior in this case depends on context — typically returns #MISSING.

3. **Time Dimension**: @PREVSIBLING is particularly useful for the Period dimension where months are sequential: @PREVSIBLING("Feb") = "Jan", @PREVSIBLING("Mar") = "Feb", etc.

4. **Non-Time Use**: Works on any dimension — @PREVSIBLING("Entity_B") returns "Entity_A" if A appears before B under the same parent.

---

## Syntax Variants & Scenarios

### Variant 1: Period-Over-Period

```essbase
"MoM_Change" = Revenue - Revenue -> @PREVSIBLING(@CURRMBR("Period"));
```

### Variant 2: Running Total

```essbase
"YTD_Revenue" = Revenue + "YTD_Revenue" -> @PREVSIBLING(@CURRMBR("Period"));
```

### Variant 3: Sequential Growth

```essbase
IF(Revenue -> @PREVSIBLING(@CURRMBR("Period")) > 0)
    "MoM_Growth" = (Revenue / Revenue -> @PREVSIBLING(@CURRMBR("Period"))) - 1;
ENDIF
```

### Variant 4: Waterfall Balance

```essbase
"Opening_Balance" = "Closing_Balance" -> @PREVSIBLING(@CURRMBR("Period"));
"Closing_Balance" = "Opening_Balance" + "Inflows" - "Outflows";
```

---

## Practical Examples

### Example 1: Month-Over-Month Variance

**Scenario**: Calculate the change in revenue from the previous month.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    FIX("Feb":"Dec")  /* Skip Jan — no previous month */
        "MoM_Variance" = Revenue - Revenue -> @PREVSIBLING(@CURRMBR("Period"));
        
        IF(Revenue -> @PREVSIBLING(@CURRMBR("Period")) > 0)
            "MoM_Pct" = @ROUND("MoM_Variance" / 
                Revenue -> @PREVSIBLING(@CURRMBR("Period")) * 100, 1);
        ENDIF
    ENDFIX
ENDFIX
```

---

### Example 2: Cumulative (YTD) Calculation

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    FIX("Jan")
        "YTD_Revenue" = Revenue;  /* First month = current month */
    ENDFIX
    FIX("Feb":"Dec")
        "YTD_Revenue" = Revenue + "YTD_Revenue" -> @PREVSIBLING(@CURRMBR("Period"));
    ENDFIX
ENDFIX
```

---

### Example 3: Cash Waterfall

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    FIX("Feb":"Dec")
        "Opening_Cash" = "Closing_Cash" -> @PREVSIBLING(@CURRMBR("Period"));
        "Closing_Cash" = "Opening_Cash" + "Net_Cash_Flow";
    ENDFIX
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not handling first period | @PREVSIBLING("Jan") has no previous — returns #MISSING | Handle Jan separately: `FIX("Jan")` then `FIX("Feb":"Dec")` |
| @PREVSIBLING vs. @PRIOR | @PREVSIBLING navigates siblings; @PRIOR navigates time periods | Use @PRIOR for time series; @PREVSIBLING for outline siblings |
| Assumes outline order = chronological | If periods aren't in chronological outline order, results are wrong | Ensure outline order matches expected sequence |
| Circular reference risk | `X = X -> @PREVSIBLING(...)` can cause circular dependency warnings | Use separate source and target members |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@NEXTSIBLING`](./@NEXTSIBLING.md) | Next sibling — opposite direction |
| [`@SIBLINGS`](./@SIBLINGS.md) | All siblings |
| [`@PRIOR`](./@PRIOR.md) | Prior period in time series |
| [`@SHIFT`](./@SHIFT.md) | Shift across periods |
| [`@LSIBLINGS`](./@LSIBLINGS.md) | All left (preceding) siblings |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @PREVSIBLING](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/prevsibling.html)
