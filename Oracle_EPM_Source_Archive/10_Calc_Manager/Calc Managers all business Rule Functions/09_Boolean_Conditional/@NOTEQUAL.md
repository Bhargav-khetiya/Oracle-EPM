# @NOTEQUAL

## Overview

`@NOTEQUAL` is a **native Essbase mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of members and checks their numeric values against a specified target value. It then returns a new array containing **only the members whose values do NOT match the target**.

### Why Does This Function Exist—

When building array processing logic, you often need to filter a massive list of members based on their data values before handing that list off to another function.
For example, if you want to calculate the average sales for a region, but you explicitly want to exclude any store that had exactly `$500` in sales (perhaps $500 is a default placeholder value that corrupts the true average). 
You could write complex `IF` statements to skip those stores, but `IF` statements are slow. 
`@NOTEQUAL` acts as a rapid, in-memory array filter. You pass it a range (`@CHILDREN("Stores")`) and a target (`500`). It sweeps the stores, throws out any store that equals 500, and hands the clean, filtered array to the `@AVG` function. This allows for hyper-fast, dynamic array manipulation.

### When to Use It

- **Data Cleansing**: Stripping default placeholder values (like $999$ or $0$) out of an array before running statistical functions like Averages or Medians.
- **Exception Finding**: Using `@NOTEQUAL` to find all accounts that do not equal their prior-year budget, instantly isolating the variances.
- **Zero-Suppression**: Dropping all members that equal exactly `0` from a list before running a loop, drastically speeding up the calculation time.

---

## Category

**Mathematical / Array Filtering & Manipulation / Essbase Native Functions**

---

## Syntax

```essbase
@NOTEQUAL(MemberRange, numeric_value)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberRange` | Member List | ✅ Yes | The array of members to evaluate and filter (e.g., `"Jan":"Dec"`, `@CHILDREN("Vendors")`). |
| `numeric_value` | Numeric | ✅ Yes | The target mathematical value. Any member in the array whose data perfectly equals this value will be deleted from the output array. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a filtered, comma-separated array containing only the members that do NOT equal the target value.
- **Empty Result**: If every single member in the array perfectly matches the target value, the function returns an empty set. If this is wrapped inside a math function (like `@SUM`), it will safely return `#MISSING` or `0`.
- **Missing Data Handling**: `#MISSING` blocks are mathematically evaluated as `0`. If you ask `@NOTEQUAL(list, 0)`, it will aggressively strip out all blocks that are `0` AND all blocks that are `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The C-engine compiles the `MemberRange` into a memory array.
2. **Sequential Evaluation**: It iterates through the array. For each member, it retrieves the block's numeric value.
3. **Comparison**: It compares the block's value against the `numeric_value`.
4. **Filtering**: If the values are identical, it drops the member from the array. If they are different (not equal), it keeps the member.
5. **Return**: It returns the newly filtered array to the surrounding mathematical function.

---

## Syntax Variants & Scenarios

### Variant 1: Dropping Placeholders

```essbase
/* 
   Filters the 12 months, keeping only the months that do NOT equal 999.
*/
@NOTEQUAL("Jan":"Dec", 999)
```

---

## Practical Examples

### Example 1: Calculating Averages while Ignoring Default Load Values

**Scenario**: A massive data load from an external CRM occasionally inserts exactly `$1.00` into the `"Foot_Traffic"` account as a system default when a store's camera goes offline. If FP&A runs a standard `@AVG` on foot traffic, these `$1.00` days completely destroy the average. The administrator uses `@NOTEQUAL` to actively strip out any day that equals `$1.00` before running the average.

```essbase
FIX("FY25", "Working", @LEVEL0("Stores"))
    
    /* 
       1. The @NOTEQUAL function takes the full 30-day month array.
       2. It evaluates every day. Any day where traffic == 1 is deleted from the array.
       3. The clean array (containing only days with real traffic) 
       is handed directly to @AVG.
       4. SKIPMISSING ensures that if a day was genuinely missing (no data), 
       it doesn't drag the average down.
    */
    "Average_Daily_Traffic" = @AVG(SKIPMISSING, 
        @NOTEQUAL("Day_1":"Day_30", 1)
    );
    
    /* 
       Results:
       Data: [Day1: 500, Day2: 1, Day3: 400]
       NOTEQUAL strips Day2.
       AVG receives [Day1, Day3].
       Average = 450 (Correct).
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it inside `FIX` | `FIX(@NOTEQUAL(...))` | This is an array *evaluation* function, not a structural member selection function. It requires actively querying the data in the blocks to work. You CANNOT use it inside a `FIX` statement because `FIX` statements compile before the data blocks are actually loaded into memory. It can only be used on the right side of an equation, typically wrapped inside another math function like `@SUM` or `@AVG` |
| Floating Point Precision | Failing to match | If you attempt to strip out members that equal `10.5`, but the data in Essbase is actually `10.50000000001` (due to floating point drift), `@NOTEQUAL` will see them as different numbers and will NOT strip them out. Use this function primarily to strip integers or highly rounded thresholds |
| Forgetting Missing is Zero | Stripping too much | If you write `@NOTEQUAL(list, 0)`, you will strip out every store that had `$0` in sales, AND every store that hasn't opened yet (`#MISSING`). If you need to distinguish between real zeros and missing data, you cannot use this function; you must use standard `SKIPMISSING` or `SKIPZERO` flags inside `@AVG` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@EQUAL`](./@EQUAL.md) | The exact opposite. Sweeps the array and returns ONLY the members that perfectly match the target value |
| [`@GREATER`](./@GREATER.md) | Filters the array, keeping only members whose values are strictly greater than the target |
| [`@LESS`](./@LESS.md) | Filters the array, keeping only members whose values are strictly less than the target |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — NOTEQUAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/notequal.html)
