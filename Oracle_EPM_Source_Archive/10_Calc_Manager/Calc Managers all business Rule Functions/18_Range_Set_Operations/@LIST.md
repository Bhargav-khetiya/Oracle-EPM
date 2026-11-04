# @LIST

## Overview

`@LIST` is a **native Essbase member array function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an explicit array constructor, allowing administrators to group multiple distinct, unconnected members or member sets into a single, cohesive array parameter. 

### Why Does This Function Exist—

Many advanced mathematical functions in Essbase (like `@SUM`, `@MAX`, or `@AVG`) are strictly designed to accept a single "range" argument. 
If you want to sum Q1 and Q2, you pass the range `@SUM("Q1":"Q2")`. But what if you want to sum `"Jan"`, `"Mar"`, and `"Aug"`— They are not contiguous. You cannot use a colon (`:`). If you try to write `@SUM("Jan", "Mar", "Aug")`, the compiler will throw a severe syntax error, complaining that `@SUM` only accepts one argument, but you just passed three separate arguments separated by commas.
`@LIST` solves this syntax collision. It acts as an enclosure wrapper. By wrapping the members in `@LIST("Jan", "Mar", "Aug")`, you fuse them into a single, cohesive array object. You can then safely pass this single object into the `@SUM` function (`@SUM(@LIST("Jan", "Mar", "Aug"))`), satisfying the compiler and executing the math perfectly.

### When to Use It

- **Non-Contiguous Aggregation**: Summing, averaging, or finding the maximum value across specific, hand-picked periods or entities that do not share a parent and cannot be captured by a single range (`:`).
- **Function Parameters**: Wrapping multiple complex member selection functions (like combining two `@DESCENDANTS` calls) into a single array parameter to pass into custom Java CDFs.
- **Time-Series Grouping**: Creating custom quarters or half-years dynamically inside a calculation script without having to alter the physical `.otl` outline.

---

## Category

**Member Selection / Array Processing / Essbase Native Functions**

---

## Syntax

```essbase
@LIST(mbrName1, mbrName2, ...)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName1, 2...` | Member / Array | ✅ Yes | The discrete members, ranges, or member selection functions (e.g., `@CHILDREN`) that you want to bundle together. Separated by commas. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a unified, comma-separated array of all the provided members.
- **Passthrough**: The function does absolutely zero mathematical modification. It simply acts as a container, passing the contents forward to whatever function wraps it.
- **Flattening**: If you pass another array inside the list (e.g., `@LIST("Jan", @CHILDREN("Q2"))`), Essbase flattens it out internally so the wrapping function just sees one massive array of base members.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The compiler encounters the `@LIST` wrapper inside another function (e.g., `@SUM`).
2. **Ingestion**: It reads all the comma-separated arguments provided inside the parentheses.
3. **Resolution**: It resolves any nested functions (expanding `@CHILDREN` into its actual members).
4. **Encapsulation**: It treats the resulting massive string of members as a single, unified "List Object" in memory.
5. **Handoff**: It passes that single List Object to the primary mathematical function, bypassing the strict parameter-count limitations of the primary function.

---

## Syntax Variants & Scenarios

### Variant 1: Bundling Discrete Members for Math

```essbase
/* 
   Bundles three separate, unconnected months into a single array for SUM.
*/
"Custom_Total" = @SUM(@LIST("Jan", "Apr", "Jul"));
```

---

## Practical Examples

### Example 1: Calculating Averages Across Specific Historical Periods

**Scenario**: To calculate the `"Baseline_Forecast"` for the new year, the FP&A team dictates that the script must calculate the average sales from three very specific historical periods: `"FY22_Dec"`, `"FY23_Mar"`, and `"FY24_Jun"`. Because these periods span different years and quarters, no standard hierarchical function can grab them. The administrator uses `@LIST` to hand-pick them for the `@AVG` function.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. The @AVG function requires a single array to average.
       2. We use @LIST to bundle the three cross-dimensional periods together.
       (Note: We use the cross-dimensional operator -> to specify the exact periods).
    */
    "Baseline_Forecast" = @AVG(SKIPMISSING, 
        @LIST(
            "FY22"->"Dec", 
            "FY23"->"Mar", 
            "FY24"->"Jun"
        )
    );
    
    /* 
       3. @AVG receives the list, strips out any #MISSING values, 
       and calculates the perfect average.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it inside `FIX` | `FIX(@LIST("A", "B"))` | `@LIST` is designed to bypass parameter limits in **Mathematical Range Functions** (like `@SUM`). It is completely unnecessary inside a `FIX` statement. A `FIX` statement natively accepts an infinite number of comma-separated members. Writing `FIX(@LIST("A", "B"))` is redundant; just write `FIX("A", "B")` |
| Nesting Limit Exceeded | `@LIST(A, @LIST(B, C))` | While `@LIST` flattens standard selection functions, deeply nesting `@LIST` inside other `@LIST` functions can occasionally cause stack overflow compilation errors in older versions of Essbase. Keep your lists clean and single-tiered whenever possible |
| Forgetting to use it | `@MAX("A", "B")` | This is the inverse mistake. Administrators frequently forget that `@MAX` only accepts one argument. They write `@MAX("A", "B")` and the compiler crashes with `Error: Invalid number of arguments`. Whenever you need to pass multiple distinct members to a math function, you MUST wrap them: `@MAX(@LIST("A", "B"))` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SUM`](./@SUM.md) | One of the primary consumers of `@LIST`. Adds the bundled members together |
| [`@AVG`](./@AVG.md) | Another primary consumer. Averages the bundled members together |
| [`@MERGE`](./@MERGE.md) | A set-theory function that combines lists, but is used more for advanced Boolean/Selection filtering rather than just passing arguments to math functions |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — LIST](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/list.html)
