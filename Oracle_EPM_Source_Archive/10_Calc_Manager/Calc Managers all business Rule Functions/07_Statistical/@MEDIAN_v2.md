# @MEDIAN

## Overview

`@MEDIAN` is a **native Essbase mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of members, sorts their numeric values internally from lowest to highest, and returns the **exact middle value** (the 50th percentile) of the dataset.

### Why Does This Function Exist?

When benchmarking or creating standardized performance drivers, the standard Average (`@AVG`) is mathematically dangerous if the dataset contains massive outliers. 
For example, if you have 5 stores, and their daily sales are `$10`, `$15`, `$20`, `$25`, and `$1,000,000` (a flagship store), the Average is `$200,014`. If you set next year's budget using that average, 4 out of 5 stores will fail spectacularly because the average was corrupted by a single outlier.
`@MEDIAN` solves this. The median is a robust statistical measure of central tendency. It sorts the array `[10, 15, 20, 25, 1,000,000]` and picks the number physically in the middle. The Median is `$20`. By using `@MEDIAN` instead of `@AVG`, administrators can build statistical targets and drivers that reflect the true reality of the business, completely ignoring massive statistical anomalies.

### When to Use It

- **Peer Benchmarking**: Establishing a "Standard Operating Target" for a region based on the median performance of all stores in that region.
- **Pricing Models**: Calculating the median `"Material_Cost"` from 12 different historical vendor quotes to establish a baseline budget price that ignores unusually high or low quotes.
- **Salary Banding**: Determining the median `"Current_Salary"` for a specific job code to set the baseline for next year's compensation planning.

---

## Category

**Mathematical / Array Aggregation & Statistics / Essbase Native Functions**

---

## Syntax

```essbase
@MEDIAN(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, MemberRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ❌ No  | Determines how empty blocks or zero values are handled:<br>- `SKIPNONE`: Evaluates everything (default).<br>- `SKIPMISSING`: Ignores `#MISSING` blocks.<br>- `SKIPZERO`: Ignores blocks containing exactly `0`.<br>- `SKIPBOTH`: Ignores both `#MISSING` and `0`. |
| `MemberRange` | Member List | ✅ Yes | The array of members to evaluate. Can be a time range (`"Jan":"Dec"`), a hierarchy function (`@CHILDREN("East")`), or a cross-dimensional tuple. |

*(Note: If the `Skip_Flag` is omitted, the function defaults to `SKIPNONE`).*

---

## Return Value

**Return Type**: Numeric (Double)

Returns the median numeric value found within the evaluated range.
- **Odd Number of Values**: If there are 5 values, it returns the 3rd value.
- **Even Number of Values**: If there are 6 values, there is no single middle number. Essbase calculates the arithmetic average of the two middle values (the 3rd and 4th) and returns that average.
- **Missing Data Handling**: If the range is entirely `#MISSING` and you use `SKIPMISSING`, it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The C-engine compiles the `MemberRange` into an internal memory array.
2. **Flag Enforcement**: It applies the `Skip_Flag`. If `SKIPMISSING` is set, it instantly drops any empty blocks from the array, physically reducing the size (count) of the dataset.
3. **Sorting**: It executes an internal quick-sort, ordering all the remaining numerical values from absolute lowest to absolute highest.
4. **Middle Extraction**: It divides the count by 2. If the count is odd, it extracts the value at that exact index. If the count is even, it extracts the two values adjacent to the center and averages them.
5. **Return**: It returns the final calculated median.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Median Extraction

```essbase
/* 
   Finds the median value among all children of "Products".
   Ignores any products that haven't launched yet (#MISSING).
*/
"Median_Price" = @MEDIAN(SKIPMISSING, @CHILDREN("Products"));
```

---

## Practical Examples

### Example 1: Removing Start-up Outliers from Run Rates

**Scenario**: A company calculates its `"Monthly_Run_Rate"` based on the historical 12 months (`Jan` through `Dec`). However, they frequently open new stores. A new store might have `$0` in sales in Jan/Feb, and a massive `$50,000` Grand Opening spike in March, before settling into a normal `$10,000` rate. The standard `@AVG` gets corrupted by the zeros and the spike. The administrator uses `@MEDIAN` with `SKIPZERO` to find the true stabilized run rate.

```essbase
FIX("FY25", "Working", @LEVEL0("Stores"))
    
    /* 
       1. We calculate the median sales across the entire year.
       2. We use SKIPBOTH to explicitly drop #MISSING (before the store opened) 
       and 0 (days the store was closed).
    */
    "Monthly_Run_Rate" = @MEDIAN(SKIPBOTH, "Gross_Sales"->"Jan":"Dec");
    
    /* 
       Results:
       If the data is: [Missing, 0, 50k, 10k, 12k, 11k, 10k].
       The array drops Missing and 0.
       The array sorts: [10k, 10k, 11k, 12k, 50k].
       The median isolates the 11k in the middle.
       The massive 50k spike is completely neutralized.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| `SKIPNONE` with Negative Numbers | `#MISSING` is Zero | This is the most dangerous statistical mistake. If an array is `[-100, -500, -200]` and 4 months are `#MISSING`, `SKIPNONE` treats `#MISSING` as `0`. The sorted array becomes `[-500, -200, -100, 0, 0, 0, 0]`. The median is now `0`. It looks like the division broke even, when in reality it lost money every active month. ALWAYS use `SKIPMISSING` when evaluating arrays that contain negatives or volatile data |
| Forgetting `@LIST` for Non-Contiguous Ranges | `@MEDIAN("A", "B", "C")` | Like `@MAX` and `@AVG`, `@MEDIAN` expects a SINGLE range argument. If you try to pass distinct, unconnected members separated by a comma, the compiler will crash. You MUST wrap them in `@LIST("A", "B", "C")` |
| Overusing it on Massive Blocks | Performance Strain | `@AVG` just adds numbers and divides. `@MEDIAN` requires a full mathematical *sort* of the array in memory. If you use `@MEDIAN(@LEVEL0("Customers"))` on an application with 1,000,000 customers, the sorting overhead will cripple the calculation. Use it surgically on Time ranges or small peer groups |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@AVG`](./@AVG.md) | Calculates the arithmetic mean. Faster to process, but highly susceptible to outliers |
| [`@MODE`](./@MODE.md) | Calculates the most frequently occurring number in a dataset |
| [`@MAX`](../06_Mathematical/@MAX.md) | Finds the absolute highest number (the 100th percentile outlier) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MEDIAN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/median.html)
