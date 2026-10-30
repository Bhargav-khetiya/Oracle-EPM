# @TODATEEX

## Overview

`@TODATEEX` is an **extended time series function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. While `@TODATE` only performs summation (adding values up to the current date), `@TODATEEX` allows you to apply **custom functions** (like Average, Minimum, or Maximum) over the period-to-date range.

### Why Does This Function Exist?

Summing period-to-date values is only one piece of time-series analysis:
- **YTD Average**: Calculating the average monthly headcount from the start of the year.
- **YTD Max**: Finding the peak inventory level reached so far this year.
- **YTD Min**: Identifying the lowest cash balance of the quarter-to-date.

`@TODATEEX` extends the boundary-control power of `@TODATE` but unlocks it for use with other statistical or mathematical functions.

### When to Use It

- To calculate Year-To-Date (YTD) averages
- To find the Maximum or Minimum value in a YTD or QTD window
- When standard `@TODATE` (which only sums) is insufficient

---

## Category

**Time Series / Accumulation**

---

## Syntax

```essbase
@TODATEEX(functionName, boundaryMember, memberList)
```

### Formal Syntax

```
@TODATEEX(function_Name, accumulationBoundary, memberNameList)
```

Where:
- `function_Name` — The function to apply over the range (e.g., `AVG`, `MIN`, `MAX`, `SUM`). Note: Do not include the `@` symbol in the function name here.
- `accumulationBoundary` — The ancestor member defining the period scope (e.g., `"YearTotal"`).
- `memberNameList` — The data members to evaluate.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `functionName` | Keyword | ✅ Yes | The mathematical function to apply over the period. Supported values typically include `SUM`, `AVG`, `MIN`, `MAX`. Passed without the `@` prefix. |
| `boundaryMember` | Member | ✅ Yes | Defines the scope of the calculation (e.g., `"YearTotal"` for YTD, `"Q1"` for QTD). Evaluation starts at the first leaf descendant of this member and ends at the current period. |
| `memberList` | Member list | ✅ Yes | The data member(s) to evaluate (e.g., `"Headcount"`). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the result of applying the specified function over the members in the generated period-to-date range.

---

## How It Works (Behind the Scenes)

1. **Range Generation**: Like `@TODATE`, it determines the first leaf period of the `boundaryMember` and builds a list up to the current period.
2. **Function Application**: Instead of defaulting to summation, it passes this generated list to the internal `functionName` specified.
3. **AVG Behavior**: When using `AVG`, it counts the number of periods in the generated range (e.g., in March, the denominator is 3). It handles `#MISSING` values based on standard Essbase averaging rules.

---

## Syntax Variants & Scenarios

### Variant 1: YTD Average

```essbase
"YTD_Avg_Headcount" = @TODATEEX(AVG, "YearTotal", "Headcount");
```

### Variant 2: QTD Maximum

```essbase
"QTD_Peak_Balance" = @TODATEEX(MAX, @PARENT(@CURRMBR("Period")), "Bank_Balance");
```

### Variant 3: Equivalent to @TODATE

```essbase
"YTD_Revenue" = @TODATEEX(SUM, "YearTotal", Revenue);
/* Functionally identical to @TODATE("YearTotal", Revenue) */
```

---

## Practical Examples

### Example 1: YTD Average Headcount

**Scenario**: Calculate the average number of employees YTD for productivity metrics.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "YTD_Avg_Headcount" = @TODATEEX(AVG, "YearTotal", "Headcount");
    
    IF("YTD_Avg_Headcount" > 0)
        "YTD_Rev_Per_Head" = @TODATE("YearTotal", Revenue) / "YTD_Avg_Headcount";
    ENDIF
ENDFIX
```

---

### Example 2: Tracking Peak Inventory

**Scenario**: Track the maximum inventory level reached during the current year to date.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "YTD_Max_Inventory" = @TODATEEX(MAX, "YearTotal", "Ending_Inventory");
ENDFIX
```
**What Happens**: 
- In Jan (Inv=100): YTD Max = 100
- In Feb (Inv=150): YTD Max = 150
- In Mar (Inv=120): YTD Max = 150 (since Feb was higher)

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `@` in the function name | `@TODATEEX(@AVG, ...)` is a syntax error | Omit the `@` symbol: `@TODATEEX(AVG, ...)` |
| Unsupported functions | Trying to use complex or custom functions inside `@TODATEEX` may fail | Stick to standard aggregations: `SUM`, `AVG`, `MIN`, `MAX` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@TODATE`](./@TODATE.md) | Standard YTD summation (cleaner if you only need SUM) |
| [`@AVG`](../07_Statistical/@AVG.md) | The underlying function used when passing `AVG` |
| [`@MAX`](../06_Mathematical/@MAX.md) | The underlying function used when passing `MAX` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @TODATEEX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/todateex.html)
