# @MAX

## Overview

`@MAX` is a **native Essbase mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of members and returns the **highest single numeric value** found across that entire range. 

### Why Does This Function Exist?

When building financial allocations, inventory models, or performance benchmarking, scripts frequently need to identify the peak value within a dataset. For example, you might need to find the highest single month of `"Sales"` during the year to establish a seasonal benchmark, or find the maximum `"Headcount"` across all 50 states to determine which region requires the largest overhead allocation.
Natively, you could write a massive `IF` block: `IF(Jan > Feb AND Jan > Mar...)`. This is impossible to maintain and fails immediately if the outline changes.
`@MAX` solves this natively. By passing a time range (`"Jan":"Dec"`) or a structural array (`@CHILDREN("USA")`), the C-engine rapidly sweeps all the specified blocks in memory, compares their values internally, and outputs the absolute highest number, completely abstracting the complex comparison logic away from the developer.

### When to Use It

- **Peak Identification**: Finding the highest historical revenue month to calculate a "Peak Capacity" constraint for next year's forecast.
- **Inventory Watermarks**: Calculating the maximum inventory level reached during a quarter to determine warehousing storage requirements.
- **Benchmarking**: Finding the highest performing store in a region (`@MAX(@CHILDREN("East_Region"))`) and comparing all other stores against that benchmark.

---

## Category

**Mathematical / Array Aggregation / Essbase Native Functions**

---

## Syntax

```essbase
@MAX(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, MemberRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ❌ No  | Determines how empty blocks or zero values are handled during the comparison:<br>- `SKIPNONE`: Evaluates everything (default).<br>- `SKIPMISSING`: Ignores `#MISSING` blocks.<br>- `SKIPZERO`: Ignores blocks containing exactly `0`.<br>- `SKIPBOTH`: Ignores both `#MISSING` and `0`. |
| `MemberRange` | Member List | ✅ Yes | The array of members to evaluate. Can be a time range (`"Jan":"Dec"`), a hierarchy function (`@CHILDREN("Total_Year")`), or a cross-dimensional tuple. |

*(Note: If the `Skip_Flag` is omitted, the function defaults to `SKIPNONE`).*

---

## Return Value

**Return Type**: Numeric (Double)

Returns the maximum numeric value found within the evaluated range.
- **Negative Numbers**: The function respects absolute math. If the range contains `[-50, -20, -10]`, the maximum is `-10`.
- **Missing Data Handling**: If the range is entirely `#MISSING` and you use `SKIPMISSING`, the function will return `#MISSING`. If you use `SKIPNONE`, `#MISSING` is mathematically evaluated as `0`. If your range contains `[-50, -20, #MISSING]`, the maximum is `0` (the missing block).

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The engine parses the `MemberRange` into a contiguous array of memory blocks.
2. **Flag Enforcement**: It applies the `Skip_Flag`. If `SKIPMISSING` is set, it instantly drops any empty blocks from the internal array.
3. **Sequential Sweep**: It initializes a tracking variable with the lowest possible double-precision number. It sweeps through the array. 
4. **Comparison**: For each block, if the value is greater than the tracking variable, the tracking variable is updated.
5. **Return**: Once the sweep finishes, it returns the final value of the tracking variable to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Finding Peak Month (Ignoring Missing)

```essbase
/* 
   Finds the highest value between Jan and Dec.
   If some future months are #MISSING, they are safely ignored.
*/
"Peak_Sales" = @MAX(SKIPMISSING, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Calculating "High Water Mark" for Bonuses

**Scenario**: A sales organization awards bonuses based on a "High Water Mark". The bonus is calculated against the single highest month of revenue the salesperson achieved during the first half of the year (H1). The script uses `@MAX` to scan the historical months and isolate that peak value.

```essbase
FIX("FY25", "Working", @LEVEL0("Sales_Reps"))
    
    /* 
       1. We need to find the highest sales month in H1 (Jan through Jun).
       We use SKIPMISSING so that if a rep wasn't hired until March 
       (Jan/Feb are missing), those missing blocks don't skew the logic.
    */
    "High_Water_Mark" = @MAX(SKIPMISSING, @LIST("Jan":"Jun"));
    
    /* 
       2. Now we calculate the bonus based on that peak value.
       (e.g., Bonus is 10% of their best month).
    */
    "H1_Bonus" = "High_Water_Mark" * 0.10;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting `@LIST` for Non-Contiguous Ranges | `@MAX("Jan", "Mar")` | `@MAX` expects a SINGLE range argument. If you try to pass two distinct, unconnected members separated by a comma, the compiler will crash with an "Invalid number of arguments" error. If you are hand-picking specific members, you MUST wrap them in `@LIST("Jan", "Mar")` so they are fused into a single array before `@MAX` evaluates them |
| `SKIPNONE` with Negative Numbers | `#MISSING` is Zero | If a division has lost money every month (`[-100, -500, -200]`), but they haven't reported Q4 yet (so Oct, Nov, Dec are `#MISSING`), running `@MAX` with the default `SKIPNONE` flag will return `0`. It treats `#MISSING` as `0`, and $0 > -100$. This gives the illusion they broke even. ALWAYS use `SKIPMISSING` when evaluating arrays that contain negative numbers and empty blocks |
| Assuming it Returns the Member | `@MAX` returns the Number | This function returns the numeric *value* (e.g., `$500,000`). It does NOT return the *name* of the month that held the value. If you need to know *which* month was the highest (e.g., returning the string `"Mar"`), this function cannot do that. You would need a custom Java CDF or a complex nested `IF` structure |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MIN`](./@MIN.md) | The exact opposite. Sweeps the array and returns the absolute lowest numeric value |
| [`@MAXS`](../07_Statistical/@MAXS.md) | A legacy variant that evaluates members based on their outline order, stopping evaluation if an internal condition is met (rarely used in modern scripts) |
| [`@MAXSRANGE`](./@MAXSRANGE.md) | A variant that accepts a numeric list (like `[10, 20, 30]`) directly rather than an outline member range |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MAX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/max.html)
