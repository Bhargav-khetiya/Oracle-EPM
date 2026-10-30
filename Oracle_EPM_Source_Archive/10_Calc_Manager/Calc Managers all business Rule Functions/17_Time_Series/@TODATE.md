# @TODATE

## Overview

`@TODATE` is a **time series accumulation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that accumulates values over a specified period. It is the modern, more powerful successor to `@PTD`. It allows you to **explicitly define the boundaries** of accumulation (e.g., Year-to-Date, Quarter-to-Date) by specifying a "boundary member" (like Year or Quarter).

### Why Does This Function Exist?

While `@PTD` automatically calculates up to the immediate parent, it fails when hierarchies are complex. If your outline rolls Months into Quarters, and Quarters into Years, `@PTD` at the Month level will only calculate Quarter-To-Date (QTD), not Year-To-Date (YTD). 

`@TODATE` solves this by letting you specify the boundary: "Accumulate from the start of the [Year], up to the current [Month]."

### When to Use It

- To calculate explicit Year-To-Date (YTD) values regardless of intermediate hierarchy levels
- To calculate Quarter-To-Date (QTD) or Month-To-Date (MTD) values
- In reporting cubes to generate period-to-date metrics
- When you need precise control over the accumulation window

---

## Category

**Time Series / Accumulation**

---

## Syntax

```essbase
@TODATE(boundaryMember, memberList)
```

### Formal Syntax

```
@TODATE(accumulationBoundary, memberNameList)
```

Where:
- `accumulationBoundary` — The ancestor member or function defining the period over which to accumulate (e.g., `@CURRMBR("Year")`, `"Q1"`).
- `memberNameList` — The member(s) whose data should be accumulated (e.g., `"Revenue"`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `boundaryMember` | Member/Function | ✅ Yes | Defines the scope of accumulation. If you want YTD, pass the Year member or `@CURRMBR("Year")`. The accumulation starts from the first descendant of this boundary member and stops at the current period. |
| `memberList` | Member list | ✅ Yes | One or more data members (like accounts or measures) to accumulate. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Valid boundary and periods | Accumulated numeric sum |
| Current member not under boundary | `#MISSING` |
| No data in periods | `#MISSING` |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Boundary Resolution**: Essbase evaluates the `boundaryMember` to find its first leaf descendant in outline order.
2. **Range Construction**: It builds an implicit range from that first leaf descendant up to the current member being processed.
3. **Accumulation**: It sums the values of `memberList` across that generated range.
4. **Hierarchy Independence**: Because you specify the boundary, `@TODATE` ignores intermediate rollups. If you say `@TODATE("Total Year", Revenue)`, it sums from Jan to the current month, even if the months roll up to Quarters first.

---

## Syntax Variants & Scenarios

### Variant 1: Year-To-Date (YTD)

```essbase
"YTD_Revenue" = @TODATE(@CURRMBR("Year"), Revenue);
```
Assuming "Year" is the dimension containing FY25, etc., this gives YTD regardless of the Period dimension structure. If Period is structured `YearTotal -> Q1 -> Jan`, passing `YearTotal` forces a YTD calculation.

### Variant 2: Quarter-To-Date (QTD)

```essbase
"QTD_Revenue" = @TODATE(@PARENT(@CURRMBR("Period")), Revenue);
```
Assuming the immediate parent of a month is a quarter, this forces a QTD calculation.

### Variant 3: Multiple Accounts

```essbase
"YTD_Total_Expense" = @TODATE("YearTotal", "OpEx", "COGS");
```

---

## Practical Examples

### Example 1: Creating a Comprehensive YTD Measure

**Scenario**: Generate YTD figures for all P&L accounts in a reporting scenario.

```essbase
FIX("FY25", "Reporting", @DESCENDANTS("Total Entity"))
    FIX(@DESCENDANTS("Net_Income")) /* All P&L Accounts */
        "YTD_Measure" = @TODATE("YearTotal", @CURRMBR("Account"));
    ENDFIX
ENDFIX
```
**What Happens**: 
- For every account, for every month, it calculates the sum from the start of `YearTotal` (e.g., Jan) up to the current month.
- Bypasses the Quarter hierarchy level entirely.

---

### Example 2: YTD vs QTD Reporting

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "QTD_Sales" = @TODATE(@PARENT(@CURRMBR("Period")), "Sales");
    "YTD_Sales" = @TODATE("YearTotal", "Sales");
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Boundary member mismatch | If the current period isn't a descendant of the boundary member, `@TODATE` returns `#MISSING` | Ensure the boundary covers the periods being calculated (e.g., use `@ANCEST` if unsure) |
| Using on Balance Accounts | YTD sums of closing balances are mathematically wrong | Only use on Flow/Income Statement accounts |
| Performance hit on large blocks | Repeatedly calling `@TODATE` in dense formulas can be slow | Consider using `CALC DIM` on a YTD alternative hierarchy if performance is an issue |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@TODATEEX`](./@TODATEEX.md) | Extended version allowing customized formulas (not just summing) |
| [`@PTD`](./@PTD.md) | Older, less flexible version of period-to-date |
| [`@SUMRANGE`](./@SUMRANGE.md) | Can build similar logic manually |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @TODATE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/todate.html)
