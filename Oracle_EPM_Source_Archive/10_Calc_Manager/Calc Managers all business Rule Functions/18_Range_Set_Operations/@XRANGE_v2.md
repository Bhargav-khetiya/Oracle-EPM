# @XRANGE

## Overview

`@XRANGE` is a **cross-dimensional member selection function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that generates a continuous list of members between a specified start and end point **across two dimensions** (almost always Year and Period). It overcomes the limitation of `@RANGE`, which cannot cross dimension boundaries.

### Why Does This Function Exist—

Financial time-series data naturally spans across months and years. 
- Calculating a rolling 12-month average in March FY25 requires looking back through Feb FY25, Jan FY25, and into Dec FY24, Nov FY24, etc.
- A standard `@RANGE("Dec":"Feb")` or `@RANGE("Mar"->"FY24" : "Feb"->"FY25")` fails because it crosses the Year dimension boundary. 
- `@XRANGE` stitches the Year and Period dimensions together into a continuous timeline.

### When to Use It

- For trailing twelve months (TTM) or rolling average calculations
- For project lifecycle calculations that span multiple years
- In functions like `@SUM`, `@AVG`, `@MIN`, `@MAX` when the range crosses a year boundary
- In financial functions like `@NPV`, `@IRR`, `@PAYBACK` that evaluate cash flows over time

---

## Category

**Member Selection / Range / Cross-Dimensional**

---

## Syntax

```essbase
@XRANGE(yearStart->periodStart, yearEnd->periodEnd)
```

### Formal Syntax

```
@XRANGE(startCrossDimMbr, endCrossDimMbr)
```

Where:
- `startCrossDimMbr` — A cross-dimensional reference defining the start point (e.g., `"FY24"->"Oct"`).
- `endCrossDimMbr` — A cross-dimensional reference defining the end point (e.g., `"FY25"->"Mar"`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `startCrossDimMbr` | Cross-Dim Ref | ✅ Yes | The starting intersection (Year and Period). Can use dynamic functions like `@PRIOR`. |
| `endCrossDimMbr` | Cross-Dim Ref | ✅ Yes | The ending intersection (Year and Period). Can use dynamic functions like `@CURRMBR`. |

---

## Return Value

**Return Type**: Member Set (a continuous, chronological list of cross-dimensional intersections).

When used inside an aggregation function (like `@SUM`), it passes this list of intersections for evaluation.

---

## How It Works (Behind the Scenes)

1. **Timeline Construction**: Essbase evaluates the outline order of the Year dimension and the outline order of the Period dimension to construct a logical, continuous timeline.
2. **Chronological Iteration**: For `@XRANGE("FY24"->"Nov", "FY25"->"Feb")`, the engine generates:
   - `FY24 -> Nov`
   - `FY24 -> Dec`
   - `FY25 -> Jan`
   - `FY25 -> Feb`
3. **Function Wrapper Required**: Like `@RANGE`, `@XRANGE` doesn't calculate a value itself. It must be wrapped in a function like `@SUM` or `@AVG`.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Cross-Year Range

```essbase
@SUM(Revenue, @XRANGE("FY24"->"Oct", "FY25"->"Mar"))
```
Sums Revenue from Oct FY24 through Mar FY25 (6 months).

### Variant 2: Trailing 12 Months (TTM)

```essbase
@SUM(Revenue, @XRANGE(@SHIFT("Year", -1)->@NEXT("Period"), @CURRMBR("Year")->@CURRMBR("Period")))
```
*(Note: TTM syntax can be complex. Often, it's easier to use `@MOVSUM` for TTM if supported, but `@XRANGE` allows explicit control).*

### Variant 3: With Financial Functions

```essbase
"NPV" = @NPV("Cash_Flow", "Discount_Rate", @XRANGE("FY25"->"Jan", "FY29"->"Dec"));
```

---

## Practical Examples

### Example 1: Trailing 3-Month Average (Crossing Year)

**Scenario**: Calculate a rolling 3-month average of Revenue. In February FY25, this requires Dec FY24, Jan FY25, and Feb FY25.

```essbase
FIX("Forecast", "Working", @DESCENDANTS("Total Entity"))
    /* Assuming a custom UDF or complex logic to find the exact start period 3 months ago */
    /* Alternatively, using @PRIOR which CAN cross years if configured */
    
    /* Simplified conceptual representation: */
    "Rolling_3M_Avg" = @AVG(Revenue, @XRANGE("FY24"->"Dec", "FY25"->"Feb"));
ENDFIX
```
*(Note: To make this fully dynamic, EPM Cloud often relies on `@MOVSUM` or `@MOVAVG` which handle cross-year automatically, or uses substitution variables).*

---

### Example 2: Project Lifetime Cost

**Scenario**: A project starts in Nov FY24 and ends in Mar FY25. Sum the total costs.

```essbase
FIX("Working", @DESCENDANTS("Projects"))
    "Total_Project_Cost" = @SUM("Project_Expense", @XRANGE("FY24"->"Nov", "FY25"->"Mar"));
ENDFIX
```

---

### Example 3: NPV Calculation

**Scenario**: Evaluate a 5-year investment crossing from FY25 to FY29.

```essbase
FIX("Working", "Project_A")
    "Net_Present_Value" = @NPV("Net_Cash_Flow", 0.08, @XRANGE("FY25"->"Jan", "FY29"->"Dec"));
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `@RANGE` instead of `@XRANGE` | `@RANGE("FY24"->"Dec" : "FY25"->"Jan")` is invalid syntax and will fail | Always use `@XRANGE` when crossing two dimensions |
| Reversing Start and End | `@XRANGE("FY25"->"Jan", "FY24"->"Dec")` evaluates to an empty set | Ensure start comes chronologically before end in the outline |
| Missing Function Wrapper | `A = @XRANGE(...)` | Must wrap in `@SUM`, `@AVG`, etc. |
| Overcomplicating TTM | Writing complex dynamic `@XRANGE` logic for moving averages | Use `@MOVAVG` or `@MOVSUM` first; they handle cross-year time series automatically if the outline supports it |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@RANGE`](./@RANGE.md) | Single dimension range |
| [`@SUM`](../06_Mathematical/@SUM.md) | Frequently wraps @XRANGE |
| [`@NPV`](../08_Financial/@NPV.md) / [`@IRR`](../08_Financial/@IRR.md) | Financial functions that require @XRANGE for time bounds |
| [`@MOVSUM`](../17_Time_Series/@MOVSUM.md) | Built-in moving sum that handles cross-year without manual @XRANGE |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @XRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/xrange.html)
