# @RANGE

## Overview

`@RANGE` is a **member selection function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that generates a continuous **list of members** between a specified start and end member, inclusive, across one or more dimensions. It is primarily used within functions like `@SUM`, `@AVG`, or `@MIN` to define the scope of data to aggregate.

### Why Does This Function Exist—

Standard range notation (`"Jan":"Mar"`) works well for single dimensions and fixed ranges, but business logic often requires dynamic ranges or ranges that cross dimension boundaries:
- Summing from a dynamic start period to a dynamic end period (e.g., project lifecycle)
- Averaging over a rolling window of periods
- Aggregating across a specific set of scenarios or versions
- Overcoming the limitations of the `:` operator in complex formulas

### When to Use It

- Inside aggregation functions (`@SUM`, `@AVG`, `@MAX`, `@MIN`)
- When the start or end member is determined dynamically by a function (like `@CURRMBR` or `@PRIOR`)
- When you need a list of members for statistical functions (`@STDEV`, `@TREND`)
- To define a moving window for rolling calculations

---

## Category

**Member Selection / Range**

---

## Syntax

```essbase
@RANGE(mbrName, rangeDef)
```

### Formal Syntax

```
@RANGE(memberName, [startMember]:[endMember])
```

Where:
- `memberName` — A member from a dimension (typically a measure or account) to evaluate across the range.
- `rangeDef` — The definition of the range, usually provided as `startMbr:endMbr` or just a member list.

*(Note: In practice, `@RANGE` is heavily overloaded. Sometimes you just pass the member and the cross-dimensional range, or a member list. The most common use is `@RANGE(Account, start:end)`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name | ✅ Yes | The data member (e.g., `"Revenue"`) that will be evaluated across the range. |
| `rangeDef` | Range definition | ✅ Yes | The start and end members separated by a colon (e.g., `"Jan":"Mar"`), or a function that returns a member list (e.g., `@CHILDREN("Q1")`). The members must belong to the same dimension unless using `@XRANGE`. |

---

## Return Value

**Return Type**: Member Set (a list of cross-dimensional intersections of `mbrName` and each member in the `rangeDef`).

When used inside a function like `@SUM`, it passes this list of intersections to the function to be evaluated.

---

## How It Works (Behind the Scenes)

1. **Intersection Generation**: `@RANGE("Revenue", "Jan":"Mar")` effectively generates the list: `"Revenue"->"Jan"`, `"Revenue"->"Feb"`, `"Revenue"->"Mar"`.
2. **Outline Order**: The range is determined by the outline order. It includes the start member, the end member, and all members physically between them in the outline hierarchy at the same level.
3. **Level Requirement**: The start and end members of the range should typically be at the same level in the hierarchy.
4. **Function Wrapper**: `@RANGE` does not calculate anything itself; it simply builds the list of members for an enclosing mathematical or statistical function to process.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Range inside @SUM

```essbase
@SUM(@RANGE("Revenue", "Jan":"Jun"))
```
Sums Revenue for Jan through Jun. (Equivalent to `@SUM("Revenue"->"Jan":"Jun")`).

### Variant 2: Dynamic End Member

```essbase
@AVG(@RANGE("Inventory", "Jan":@CURRMBR("Period")))
```
Year-to-Date (YTD) average ending inventory up to the current month.

### Variant 3: With Member Function

```essbase
@MAX(@RANGE("Sales", @CHILDREN("Q1")))
```
Finds the maximum sales month within Q1.

---

## Practical Examples

### Example 1: Year-To-Date (YTD) Summation

**Scenario**: Calculate YTD Revenue dynamically based on the current period.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    FIX("Jan":"Dec")
        "YTD_Revenue" = @SUM(@RANGE("Revenue", "Jan":@CURRMBR("Period")));
    ENDFIX
ENDFIX
```

**What Happens**:
- In Jan: Sums `Jan:Jan`.
- In Mar: Sums `Jan:Mar`.
- In Dec: Sums `Jan:Dec`.

---

### Example 2: Rolling 3-Month Average

**Scenario**: Calculate a moving average of the current and past two months.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    FIX("Mar":"Dec")
        "Rolling_3M_Avg" = @AVG(@RANGE("Revenue", @PRIOR(@CURRMBR("Period"), 2):@CURRMBR("Period")));
    ENDFIX
ENDFIX
```
*(Note: Care must be taken at the start of the year. If `@PRIOR` crosses years, `@XRANGE` must be used instead of `@RANGE`.)*

---

### Example 3: Finding Minimum Stock Level

**Scenario**: Find the lowest inventory level during the first half of the year.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Min_H1_Stock" = @MIN(@RANGE("Ending_Inventory", "Jan":"Jun"));
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Crossing year/dimension boundaries | `@RANGE("Revenue", "Dec":"Feb")` fails if Dec and Feb are in different parent years | Use `@XRANGE` for ranges that cross dimension boundaries (like Time and Year) |
| Using @RANGE standalone | `@RANGE` returns a list, not a value. `A = @RANGE(...)` is an error | Always wrap `@RANGE` in a function like `@SUM`, `@AVG`, `@MIN`, `@MAX` |
| Different hierarchy levels | `"Q1":"Dec"` spans different levels and yields unpredictable results | Ensure start and end members are at the same generation/level |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@XRANGE`](./@XRANGE.md) | Cross-dimensional range (essential for crossing Year boundaries) |
| [`@SUM`](./@SUM.md) | Frequently wraps @RANGE |
| [`@AVG`](./@AVG.md) | Frequently wraps @RANGE |
| [`@MAXRANGE`](./@MAXRANGE.md) / [`@MINRANGE`](./@MINRANGE.md) | Find max/min within a range |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @RANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/range.html)
