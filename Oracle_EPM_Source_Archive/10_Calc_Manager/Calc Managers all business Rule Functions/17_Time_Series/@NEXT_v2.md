# @NEXT

## Overview

`@NEXT` is a **member navigation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the value of a specified member from the *subsequent* member in the outline (typically the next time period). It is the forward-looking counterpart to `@PRIOR`.

### Why Does This Function Exist?

Financial modeling frequently requires looking ahead to pull values from future periods into the current calculation:
- **Pre-Payments / Accruals**: Recognizing an expense today based on a known payment due tomorrow.
- **Inventory Depletion**: Determining ending inventory today based on expected sales tomorrow.
- **Lead Times**: Calculating raw material requirements in Jan for production scheduled in Feb.

### When to Use It

- When a calculation requires data from the next period (e.g., `Next_Month_Sales`).
- To look forward multiple periods (e.g., `+3` months).
- When navigating across Year boundaries (requires `@XRANGE` integration, similar to `@PRIOR`).

---

## Category

**Member Selection / Navigation / Time Series**

---

## Syntax

```essbase
@NEXT(mbrName [, n, rangeList])
```

### Formal Syntax

```
@NEXT(valueExpression, [offsetCount], [navigationRange])
```

Where:
- `valueExpression` — The measure or account to pull data from (e.g., `"Sales"`).
- `offsetCount` — (Optional) The number of steps forward to look. Defaults to `1`.
- `navigationRange` — (Optional) The boundary of members to navigate through (e.g., `@CHILDREN("YearTotal")` or `@XRANGE`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member/Value | ✅ Yes | The account, measure, or member you want the value for. |
| `n` | Integer | ❌ No | How many steps forward to jump. If omitted, defaults to `1` (the immediate next member). |
| `rangeList` | Member list| ❌ No | The sequence of members determining the "timeline." If omitted, defaults to the `Time` dimension siblings at the same generation as the current member. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the value of `mbrName` from `n` periods in the future.
- If stepping forward `n` times exceeds the bounds of the `rangeList`, the function returns `#MISSING`.
- For example, `@NEXT` executed on "Dec" (the last month of the year) without an `@XRANGE` will return `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Context Check**: Essbase looks at the current member being calculated in the `Time` dimension (e.g., "Feb").
2. **Step Forward**: It steps forward `n` positions along the `rangeList` (e.g., to "Mar").
3. **Data Retrieval**: It grabs the value of `mbrName` at that future intersection and returns it to the current formula.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Next Period

```essbase
/* Grab next month's sales */
"Next_Sales" = @NEXT("Sales");
```

### Variant 2: Multiple Periods Ahead

```essbase
/* Look 3 months ahead */
"Future_Demand" = @NEXT("Sales", 3);
```

### Variant 3: Cross-Year Navigation (Crucial!)

```essbase
/* Grab next month's sales, safely crossing from Dec FY24 into Jan FY25 */
"Next_Sales" = @NEXT("Sales", 1, @XRANGE("FY24"->"Jan", "FY25"->"Dec"));
```

---

## Practical Examples

### Example 1: Inventory Reorder Point (Lead Time)

**Scenario**: You have a 2-month lead time on manufacturing. Your production requirement in the current month is based on the expected sales 2 months from now.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Products"))
    FIX("Jan":"Oct")
        /* Standard calculation inside a single year */
        "Production_Requirement" = @NEXT("Forecasted_Sales", 2);
    ENDFIX
    
    FIX("Nov":"Dec")
        /* Cross-year requirement for Nov/Dec */
        "Production_Requirement" = @NEXT("Forecasted_Sales", 2, @XRANGE("FY25"->"Jan", "FY26"->"Dec"));
    ENDFIX
ENDFIX
```

---

### Example 2: Checking for End of Life

**Scenario**: A product is End-of-Life (EOL) if there are zero sales expected next month.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Products"))
    IF("Forecasted_Sales" > 0 AND @NEXT("Forecasted_Sales") == #MISSING)
        "EOL_Flag" = 1;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Failing at Year-End | `@NEXT("Sales")` calculates on Dec FY24. The default range is `Jan:Dec`. There is no "next" month after Dec in that range, so it returns `#MISSING`. It does *not* automatically jump to Jan FY25 | Always use the 3rd parameter `@XRANGE` if your logic needs to span across years |
| Confusing with `@NEXTSIBLING` | `@NEXT` returns a *value*. `@NEXTSIBLING` returns a *member reference* | If you need the number (e.g., $100), use `@NEXT`. If you need the member (e.g., "Feb" to use in an IF statement), use `@NEXTSIBLING` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PRIOR`](./@PRIOR.md) | The exact opposite (looks backward instead of forward) |
| [`@NEXTSIBLING`](./@NEXTSIBLING.md) | Returns the member name of the next sibling, not its data value |
| [`@XRANGE`](../18_Range_Set_Operations/@XRANGE.md) | Essential for making `@NEXT` work across multiple years safely |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @NEXT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/next.html)
