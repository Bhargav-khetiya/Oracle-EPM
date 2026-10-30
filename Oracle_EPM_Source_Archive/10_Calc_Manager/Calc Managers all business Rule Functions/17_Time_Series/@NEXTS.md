# @NEXTS

## Overview

`@NEXTS` is a **time-series / navigation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the data value from a member that is a specified number of positions **ahead** (forward) in the outline order within the same level, while **skipping `#MISSING` values**. The "S" suffix stands for "Skip Missing."

### Why Does This Function Exist?

In financial forecasting and planning, you often need to look ahead in time periods to find the next available (non-missing) data point:
- Finding the next non-empty forecast period for interpolation
- Looking ahead to find the next populated rate or assumption
- Building forward-looking calculations that must skip gaps in data
- Creating rolling forecasts where some periods may not yet have data

### When to Use It

- When you need a forward-looking value but want to skip over `#MISSING` gaps
- When building interpolation or smoothing formulas that handle incomplete data
- When creating rolling calculations across periods with potential data holes
- Use `@NEXTS` instead of `@NEXT` when missing values should be bypassed

---

## Category

**Time Series / Navigation / Data Access**

---

## Syntax

```essbase
@NEXTS(member, n)
```

### Formal Syntax

```
@NEXTS(mbrName [, offset])
```

Where:
- `mbrName` — The member (typically a time period) from which to navigate forward
- `offset` — (Optional) Number of non-missing positions to skip forward. Defaults to 1.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name | ✅ Yes | The starting member from which to look forward. Typically a time-period member. Must be at the same level as the members being scanned. |
| `n` | Integer | ❌ No | Number of non-missing values to skip forward. Default is `1` (next non-missing). If `n = 2`, it finds the second non-missing value ahead. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Non-missing value found n positions ahead (skipping missing) | That numeric value |
| Fewer than n non-missing values exist ahead | `#MISSING` |
| Already at the last member in outline order | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Forward Scan**: Starting from the member immediately after the specified member in outline order (at the same level), Essbase scans forward through siblings.

2. **Skip Logic**: Each member encountered is evaluated. If its value is `#MISSING`, it is skipped and the scan continues. Each non-missing value decrements the counter `n`. When `n` reaches 0, that value is returned.

3. **Boundary Behavior**: If the scan reaches the end of the sibling list without finding `n` non-missing values, `#MISSING` is returned.

4. **Same Level Requirement**: `@NEXTS` only scans members at the **same level** in the outline hierarchy. It does not traverse up or down the hierarchy.

5. **Dense Dimension Performance**: `@NEXTS` is most efficient on dense dimensions (like Time) because all values are within the same block. On sparse dimensions, it requires reading multiple blocks.

6. **Current Context**: If no explicit member is provided and the function is evaluated within a FIX or member iteration, it uses the current member context as the starting point.

---

## Syntax Variants & Scenarios

### Variant 1: Default (Next Non-Missing Value)

```essbase
@NEXTS(Sales)
```
Returns the Sales value from the next non-missing period.

### Variant 2: Skip Multiple Non-Missing Values

```essbase
@NEXTS(Sales, 3)
```
Returns the Sales value from the 3rd non-missing period ahead.

### Variant 3: Cross-Dimensional

```essbase
@NEXTS("Actual" -> Sales, 1)
```
Returns the next non-missing Actual Sales value looking forward.

---

## Practical Examples

### Example 1: Fill Gaps with Next Available Value

**Scenario**: For any period where Forecast is missing, fill it with the next available forecast value.

```essbase
FIX("FY24", "Forecast", @CHILDREN("Total_Products"))
    IF("Revenue" == #MISSING)
        "Revenue" = @NEXTS(Revenue, 1);
    ENDIF
ENDFIX
```

**What Happens**: If March is `#MISSING` and April is also `#MISSING` but May has a value, `@NEXTS` in March returns May's value (skipping April's missing).

---

### Example 2: Forward-Looking Rate Lookup

**Scenario**: Find the next available exchange rate for currency conversion when current month rate is not yet entered.

```essbase
FIX("FY24", @CHILDREN("All_Currencies"))
    IF("Exchange_Rate" == #MISSING)
        "Exchange_Rate" = @NEXTS("Exchange_Rate", 1);
    ENDIF
ENDFIX
```

---

### Example 3: Moving Average with Non-Missing Values Only

**Scenario**: Calculate average of the current value and the next two non-missing values.

```essbase
FIX("FY24", "Forecast")
    "Smoothed_Rev" = (Revenue + @NEXTS(Revenue, 1) + @NEXTS(Revenue, 2)) / 3;
ENDFIX
```

---

### Example 4: Compare Current to Next Available

**Scenario**: Calculate the growth rate to the next non-missing period.

```essbase
FIX("FY24", "Actual")
    IF(@NEXTS(Revenue, 1) <> #MISSING AND Revenue <> 0)
        "Fwd_Growth" = (@NEXTS(Revenue, 1) - Revenue) / @ABS(Revenue) * 100;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing `@NEXTS` with `@NEXT` | `@NEXT` returns the value from the next member even if it's `#MISSING`; `@NEXTS` skips missing | Use `@NEXT` when you want the literal next member, `@NEXTS` when you want the next non-missing |
| Expecting cross-level navigation | `@NEXTS` only scans at the same level — it won't jump from Q1 to Jan | Ensure start and target members are at the same level |
| Infinite-looking loops | If all remaining members are `#MISSING`, `@NEXTS` returns `#MISSING` — no error, but potentially unexpected results | Always handle the `#MISSING` return case |
| Large offset values | `@NEXTS(member, 100)` on a 12-month dimension will always return `#MISSING` | Keep offset reasonable relative to dimension size |
| Using as write target | `@NEXTS` is a read function | Place it on the right side of `=` only |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@NEXT`](./@NEXT.md) | Returns next member's value WITHOUT skipping missing |
| [`@PRIORS`](./@PRIORS.md) | Returns a **prior** member's value, skipping missing — reverse direction |
| [`@PRIOR`](./@PRIOR.md) | Returns prior member's value WITHOUT skipping missing |
| [`@SHIFT`](./@SHIFT.md) | Shifts by a fixed number of members (no skip logic) |
| [`@NEXTSIBLING`](./@NEXTSIBLING.md) | Returns the next sibling member (not a value — returns a member reference) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @NEXTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/nexts.html)
- [Oracle Essbase Technical Reference — @NEXTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
