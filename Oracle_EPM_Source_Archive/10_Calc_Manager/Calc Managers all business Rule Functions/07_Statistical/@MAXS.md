# @MAXS

## Overview

`@MAXS` is a **native Essbase mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range of members and returns the highest numeric value found. However, unlike the standard `@MAX` function (which evaluates every single member independently), `@MAXS` is a **Sequential Evaluator**. It evaluates the array strictly in the order the members appear in the database outline, and it allows the use of an internal mathematical condition to define the array.

### Why Does This Function Exist—

The standard `@MAX` function is highly optimized for simple ranges (e.g., `"Jan":"Dec"`). However, in older versions of Essbase (prior to the introduction of advanced `IF` branching inside cross-dimensional arrays), administrators needed a way to find a maximum value *conditionally*. 
For example, what if you only want to find the maximum sales month, but ONLY among the months where `"Marketing_Spend"` was greater than `$10,000`— 
`@MAXS` was designed to handle these sequenced, conditional arrays. It steps through the members one by one. If the condition is met, it checks the maximum. If the condition fails, it skips that member.

*Note: In modern EPM Cloud, `@MAXS` is largely considered a legacy function. The standard `@MAX` function, combined with modern `IF` logic, `SKIPMISSING` flags, and temporary staging accounts, is almost universally preferred because it is significantly easier to read, debug, and compile.*

### When to Use It

- **Conditional Peaks**: Finding the highest value in an array, but strictly filtering the array on-the-fly based on a secondary metric (e.g., Max Sales where Headcount > 0).
- **Sequential Evaluation**: Forcing the math engine to evaluate an array strictly in the chronological/structural order defined by the `.otl` file.
- **Legacy Migrations**: Maintaining older calculation scripts that heavily utilized `MAXS` or `MINS` for conditional array processing.

---

## Category

**Mathematical / Array Aggregation / Essbase Native Functions**

---

## Syntax

```essbase
@MAXS(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, MemberRange)
```
*(Note: While the syntax appears identical to `@MAX`, the internal C-engine processes the `MemberRange` sequentially rather than in a parallel memory block, allowing for conditional expressions inside the range in specific legacy parsers).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ❌ No  | Determines how empty blocks or zero values are handled during the comparison:<br>- `SKIPNONE`: Evaluates everything (default).<br>- `SKIPMISSING`: Ignores `#MISSING` blocks.<br>- `SKIPZERO`: Ignores blocks containing exactly `0`.<br>- `SKIPBOTH`: Ignores both `#MISSING` and `0`. |
| `MemberRange` | Member List | ✅ Yes | The array of members to evaluate. This must be a sequence of members (like a time range) that the engine can step through in outline order. |

---

## Return Value

**Return Type**: Numeric (Double)

Returns the maximum numeric value found within the evaluated sequence.
- **Negative Numbers**: The function respects absolute math. If the sequence contains `[-50, -20, -10]`, the maximum is `-10`.
- **Missing Data Handling**: If the range is entirely `#MISSING` and you use `SKIPMISSING`, the function returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The engine looks at the `MemberRange`.
2. **Sequential Sweep**: Unlike `@MAX` (which can grab the array in bulk), `@MAXS` forces a strict sequential loop. It goes to the first member in the outline sequence.
3. **Condition Check**: It evaluates the value (and any implied conditions). 
4. **Comparison**: If valid and not skipped by the `Skip_Flag`, it updates its internal tracking variable if the value is higher.
5. **Next Member**: It steps to the exact next member in the physical outline and repeats.
6. **Return**: Once the sequence is exhausted, it returns the highest value.

---

## Syntax Variants & Scenarios

### Variant 1: Sequential Maximum

```essbase
/* 
   Finds the highest value sequentially between Jan and Dec.
*/
"Peak_Sales" = @MAXS(SKIPMISSING, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Extracting a Peak Value Safely

**Scenario**: A script needs to find the highest monthly `"Production_Volume"` for a factory. However, during months where the factory is shut down for maintenance, production is technically `0`, not `#MISSING`. The standard `@MAX` might evaluate `0` if all other months are negative (in a complex variance analysis). The administrator uses `@MAXS` with `SKIPBOTH` to sequentially step through the year, completely ignoring `#MISSING` blocks AND `0` blocks, ensuring the peak is a true operating peak.

```essbase
FIX("FY25", "Working", @LEVEL0("Factories"))
    
    /* 
       1. Sequentially scan the year.
       2. SKIPBOTH explicitly drops both #MISSING and 0 from the comparison.
    */
    "Peak_Production" = @MAXS(SKIPBOTH, "Jan":"Dec");
    
    /* 
       If Jan = 500, Feb = 0 (Shutdown), Mar = #MISSING, Apr = 200.
       The function ignores Feb and Mar.
       The peak is 500.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using `@MAXS` when `@MAX` is sufficient | Unnecessary overhead | Because `@MAXS` forces a strict outline-order sequential evaluation, it can be mathematically slower than `@MAX` in massive arrays. If you are just trying to find the highest number in a range (and don't care about the chronological sequence of the evaluation), always use `@MAX` |
| Forgetting `@LIST` for Non-Contiguous Ranges | `@MAXS("Jan", "Mar")` | Just like `@MAX`, `@MAXS` expects a SINGLE range argument. If you try to pass two distinct, unconnected members separated by a comma, the compiler will crash. You MUST wrap them in `@LIST("Jan", "Mar")` |
| `SKIPNONE` with Negative Numbers | `#MISSING` is Zero | If an array is `[-100, -500, -200]` and Q4 is `#MISSING`, `SKIPNONE` treats `#MISSING` as `0`. Since $0 > -100$, the function returns `0`. ALWAYS use `SKIPMISSING` when evaluating arrays containing negatives |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MAX`](./@MAX.md) | The standard, bulk-evaluation version of this function. Universally preferred in modern Cloud applications unless strict sequential legacy behavior is required |
| [`@MINS`](./@MINS.md) | The sequential equivalent for finding the absolute lowest value in a range |
| [`@MAXSRANGE`](./@MAXSRANGE.md) | A variant that accepts a numeric list (like `[10, 20, 30]`) directly rather than an outline member range |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MAXS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/maxs.html)
