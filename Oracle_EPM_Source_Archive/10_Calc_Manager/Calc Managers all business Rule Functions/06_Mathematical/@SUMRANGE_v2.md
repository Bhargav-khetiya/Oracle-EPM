# @SUMRANGE

## Overview

`@SUMRANGE` is a **native Essbase mathematical function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of cross-dimensional members, adds their numeric values together, and returns the **total sum**. 

### Why Does This Function Exist—

The standard `@SUM` function is incredibly powerful, but historically, older versions of the Essbase compiler struggled when administrators tried to sum complex, comma-separated cross-dimensional lists directly inside `@SUM` (e.g., summing `"FY24"->"Actual"` and `"FY25"->"Forecast"` together). 
`@SUMRANGE` was designed as an explicit array aggregator to ensure that complex, non-contiguous cross-dimensional tuples could be parsed, evaluated, and summed flawlessly without compiler confusion. 
*Note: In modern EPM Cloud, the standard `@SUM` function (combined with `@LIST`) has been upgraded to handle almost every scenario `@SUMRANGE` was built for. As a result, `@SUMRANGE` is largely functionally identical to `@SUM` today, but remains heavily prevalent in legacy scripts and specialized cross-dimensional integrations.*

### When to Use It

- **Cross-Scenario Aggregation**: Adding `"YTD_Actuals"` and `"Remaining_Forecast"` together to generate a `"Full_Year_Estimate"`.
- **Multi-Dimensional Grouping**: Summing up a specific metric across multiple un-related parents (e.g., adding the total revenue of the `"North_America"` branch to the total revenue of the `"Asia"` branch, bypassing Europe).
- **Legacy Migrations**: Maintaining older calculation scripts that heavily utilized `RANGE` functions for explicit array enforcement.

---

## Category

**Mathematical / Array Aggregation / Essbase Native Functions**

---

## Syntax

```essbase
@SUMRANGE(mbrName, rangeList)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target account or metric you want to sum (e.g., `"Sales"`). |
| `rangeList` | Member List | ✅ Yes | The array of members or cross-dimensional intersections across which the sum is calculated. This can be a simple range (`"Jan":"Dec"`) or a complex list of tuples. |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the calculated total sum of the values in the specified range.
- **Missing Data Handling**: `#MISSING` values are mathematically evaluated as `0`. They do not corrupt the sum. If you add `[100, #MISSING, 200]`, the result is `300`.
- **Empty Array**: If every single member in the `rangeList` is `#MISSING`, the function will return `#MISSING`.
- **Negative Numbers**: The sum respects absolute math. If the array is `[100, -50]`, the sum is `50`.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The C-engine compiles the `rangeList` into a memory array.
2. **Intersection Generation**: It fuses the `mbrName` (e.g., `"Sales"`) with every item in the array to create specific, queryable intersections (e.g., `"Sales"->"Jan"`, `"Sales"->"Feb"`).
3. **Sweep and Sum**: It initializes a tracking variable at `0`. It queries each intersection in the array, retrieves the value, and adds it to the tracker.
4. **Return**: Once the array is exhausted, it writes the final summed total to the current calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Cross-Dimensional Sum

```essbase
/* 
   Adds the actuals of FY24 to the forecast of FY25.
   (Assumes we are fixing on the Sales account).
*/
"Combined_Metric" = @SUMRANGE("Sales", @LIST("Actual"->"FY24", "Forecast"->"FY25"));
```

---

## Practical Examples

### Example 1: Calculating Full Year Estimate (FYE)

**Scenario**: The FP&A team uses a "Full Year Estimate" (FYE) metric. In June, the FYE should be the sum of 6 months of `"Actuals"` (Jan-Jun) plus 6 months of `"Forecast"` (Jul-Dec). The administrator uses `@SUMRANGE` to fuse these two completely different scenarios together into a single total.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. We use SUMRANGE on the Revenue account.
       2. The rangeList is a list combining two different cross-dimensional sets.
       (Actuals for H1, Forecast for H2).
    */
    "FYE_Revenue" = @SUMRANGE("Revenue", 
        @LIST(
            "Actual"->"Jan":"Jun", 
            "Forecast"->"Jul":"Dec"
        )
    );
    
    /* 
       Results:
       The engine queries Actual->Jan through Actual->Jun, sums them.
       It queries Forecast->Jul through Forecast->Dec, sums them.
       It adds both sums together and writes it to FYE_Revenue.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting `@LIST` for Comma Separated Tuples | Syntax Errors | If you are passing multiple disconnected intersections into the `rangeList` (like `"Actual"->"FY23", "Forecast"->"FY24"`), you CANNOT just separate them with commas inside `@SUMRANGE`. The function expects exactly TWO parameters (`mbrName`, `rangeList`). If you add a comma, it thinks you gave it three parameters and will crash. You MUST wrap the tuples in an `@LIST()` |
| Omitting the Target Member | `@SUMRANGE("Jan":"Dec")` | Unlike `@SUM`, which can imply the current account being calculated, `@SUMRANGE` strictly requires the target metric (`mbrName`) as the first parameter. If you only provide the time range, it will crash. Always explicitly state what you are summing: `@SUMRANGE("Sales", "Jan":"Dec")` |
| Using it inside `FIX` | `FIX(@SUMRANGE(...))` | This is a mathematical aggregation function. It returns a Number. It is NOT a member selection function. You CANNOT use it inside a `FIX` statement to select members. It must be used on the right side of a mathematical equation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SUM`](./@SUM.md) | The standard version. Functionally identical in modern Cloud, but often syntactically easier to use because it implies the current calculating account |
| [`@MAXSRANGE`](./@MAXSRANGE.md) | Evaluates a distinct list of cross-dimensional values, but returns the absolute highest number rather than the sum |
| [`@AVGRANGE`](../07_Statistical/@AVGRANGE.md) | Calculates the mathematical mean of the specified cross-dimensional array |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — SUMRANGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/sumrange.html)
