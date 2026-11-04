# @MODE

## Overview

`@MODE` is a **native Essbase mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of members, analyzes the numeric data within them, and returns the **most frequently occurring value** in that dataset. 

### Why Does This Function Exist—

In operational planning and retail analytics, standard averages (`@AVG`) and medians (`@MEDIAN`) don't always tell the whole story. 
For example, if a store sells shoes, and over 7 days the daily "Units Sold" were `[2, 2, 2, 8, 10, 15, 20]`, the Average is `8.4`. The Median is `8`. But if you look at the raw data, the most common reality on any given day is that they sell exactly `2` shoes. 
If Supply Chain needs to know the most "typical" baseline daily volume to stock in the back room, the mathematical Mode (`2`) provides the most accurate operational insight.
`@MODE` automates this natively. By passing a time range or structural array to the function, the Essbase C-engine sweeps the blocks, builds an internal frequency map of all the values, and outputs the number that appeared the most often.

### When to Use It

- **Typical Volume Analysis**: Determining the most common daily transaction count or foot-traffic volume for a retail location, ignoring outlier spikes or slow days.
- **Standardized Pricing**: Analyzing 50 different historical invoices for a specific raw material and extracting the most commonly paid price to set a realistic budget baseline.
- **Categorical Tagging**: If a dimension uses numbers to represent status flags (e.g., `1` = Pending, `2` = Approved), you can use `@MODE` across a region to determine the most common status of the stores within that region.

---

## Category

**Mathematical / Array Aggregation & Statistics / Essbase Native Functions**

---

## Syntax

```essbase
@MODE(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, MemberRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ❌ No  | Determines how empty blocks or zero values are handled:<br>- `SKIPNONE`: Evaluates everything (default).<br>- `SKIPMISSING`: Ignores `#MISSING` blocks.<br>- `SKIPZERO`: Ignores blocks containing exactly `0`.<br>- `SKIPBOTH`: Ignores both `#MISSING` and `0`. |
| `MemberRange` | Member List | ✅ Yes | The array of members to evaluate. Can be a time range (`"Jan":"Dec"`), a hierarchy function (`@CHILDREN("Products")`), or a cross-dimensional tuple. |

*(Note: If the `Skip_Flag` is omitted, the function defaults to `SKIPNONE`).*

---

## Return Value

**Return Type**: Numeric (Double)

Returns the most frequently occurring numeric value found within the evaluated range.
- **Multiple Modes (Ties)**: If the dataset has a tie (e.g., `[5, 5, 10, 10]`), the function traditionally returns the *lowest* of the tied values (so it would return `5`).
- **No Repeating Values**: If every single number in the dataset is unique (e.g., `[1, 2, 3, 4, 5]`), there is mathematically no mode. Essbase traditionally handles this by returning `#MISSING` or the absolute lowest value, depending on the specific engine patch.
- **Missing Data Handling**: If the range is entirely `#MISSING` and you use `SKIPMISSING`, it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The C-engine compiles the `MemberRange` into an internal memory array.
2. **Flag Enforcement**: It applies the `Skip_Flag`. If `SKIPMISSING` is set, it instantly drops any empty blocks from the array.
3. **Frequency Mapping**: It iterates through the remaining values, building an internal hash map or frequency table that tallies how many times each specific double-precision number appears.
4. **Peak Extraction**: It scans the frequency table to find the highest tally.
5. **Return**: It returns the numeric value associated with that highest tally.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Typical Price

```essbase
/* 
   Finds the most frequently occurring value among all children of "Vendors".
   Ignores any vendors that haven't bid (#MISSING).
*/
"Typical_Price" = @MODE(SKIPMISSING, @CHILDREN("Vendors"));
```

---

## Practical Examples

### Example 1: Identifying Typical Daily Volumes

**Scenario**: A warehouse model holds daily shipping volume (`"Units_Shipped"`) for a 30-day month. Operations needs to know the "Typical" volume to staff for. The standard average is skewed high because of massive end-of-month pushes. The administrator uses `@MODE` to find the most common baseline day.

```essbase
FIX("FY25", "Working", @LEVEL0("Warehouses"))
    
    /* 
       1. We calculate the mode across all 30 days.
       2. We use SKIPBOTH to explicitly drop days where the warehouse was closed 
       (Missing or 0), so 0 doesn't accidentally become the Mode.
    */
    "Typical_Daily_Volume" = @MODE(SKIPBOTH, "Day_1":"Day_30");
    
    /* 
       Results:
       If the data is 20 days of exactly 500 units, and 10 days of 5,000 units.
       The Average is 2,000.
       The Mode is 500.
       Operations staffs for 500.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| `SKIPNONE` with Missing Data | `#MISSING` is Zero | This is the most dangerous statistical mistake. If you have a 12-month array, and 8 of those months are `#MISSING`, `SKIPNONE` evaluates all 8 missing blocks as `0`. Because `0` appears 8 times, `0` instantly becomes the Mode! It looks like your typical sales are $0. ALWAYS use `SKIPMISSING` or `SKIPBOTH` when evaluating arrays with empty blocks |
| Floating Point Precision Limits | No Exact Matches | The Mode function requires *exact* numeric matches. If your data is highly precise floating-point decimals (e.g., `10.0001`, `10.0002`, `10.0003`), Essbase will see every single number as unique. There will be no mode. `@MODE` is almost exclusively useful on clean integers (like Headcount or Units) or heavily rounded price values |
| Forgetting `@LIST` for Non-Contiguous Ranges | `@MODE("A", "B", "C")` | Like `@MAX` and `@AVG`, `@MODE` expects a SINGLE range argument. If you try to pass distinct, unconnected members separated by commas, the compiler will crash. You MUST wrap them in `@LIST("A", "B", "C")` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MEDIAN`](./@MEDIAN.md) | Calculates the exact middle value of a sorted dataset. Better for continuous decimal data than `@MODE` |
| [`@AVG`](./@AVG.md) | Calculates the arithmetic mean. Faster to process, but highly susceptible to outliers |
| [`@MAX`](./@MAX.md) | Finds the absolute highest number (the 100th percentile outlier) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MODE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mode.html)
