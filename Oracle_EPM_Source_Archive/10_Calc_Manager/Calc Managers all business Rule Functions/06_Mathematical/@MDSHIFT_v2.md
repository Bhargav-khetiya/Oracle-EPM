# @MDSHIFT

## Overview

`@MDSHIFT` is a **native Essbase multi-dimensional array function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an advanced data-pointer. It retrieves a data value from a completely different block in the database by physically "shifting" the calculation focus across **multiple dimensions simultaneously**, based on defined offset integers.

### Why Does This Function Exist—

Standard shift functions like `@PRIOR`, `@NEXT`, or `@SHIFT` are inherently one-dimensional. They allow you to shift across Time (`@PRIOR("Revenue")` gets last month). But what if you need to shift across Time AND across Products—
For example, if you are calculating the forecast for `"Product_v2"` in `"FY25"`, and the logic dictates that the forecast must be based on the actuals of the older `"Product_v1"` from `"FY24"`. 
You cannot use standard `@PRIOR` because the data is sitting in a completely different Product block. You *could* write complex cross-dimensional pointers (`"Product_v1"->"FY24"`), but if you have 50 products all replacing older versions, hardcoding them is impossible.
`@MDSHIFT` solves this natively. You give it a target account, and then provide a series of dimensional offsets. You can tell Essbase: "Get the data for this metric, but step backward 1 Year, AND step backward 1 Product in the outline." Essbase handles the multi-dimensional triangulation and returns the single data value.

### When to Use It

- **Multi-Dimensional Lagging**: Replicating a 3-month trailing average from a *different* scenario (shifting back in Time, and shifting back in Scenario).
- **Product Lifecycle Transitions**: Copying legacy data from deprecated members into new active members by shifting across custom arrays in the Product dimension.
- **Advanced Moving Windows**: Creating dynamic rolling logic that crosses the year-boundary seamlessly while simultaneously shifting data across different legal entities.

---

## Category

**Mathematical / Array Processing & Shifting / Essbase Native Functions**

---

## Syntax

```essbase
@MDSHIFT(mbrName, shiftCnt1, dimName1, [range1], [shiftCntX, dimNameX, rangeX...])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target account or metric whose data you want to retrieve (e.g., `"Sales"`). |
| `shiftCnt` | Integer | ✅ Yes | The mathematical number of steps to move. Negative (`-1`) moves backward/left in the outline. Positive (`1`) moves forward/right. |
| `dimName` | Dimension | ✅ Yes | The specific dimension across which the shift occurs. |
| `range` | Member List | ❌ No  | A defined array boundaries for the shift (e.g., `"Jan":"Dec"`). If the shift falls outside this range, it returns `#MISSING`. If omitted, it uses the lowest-level members of the specified dimension. |

*(Note: You can stack multiple `shiftCnt`, `dimName`, and `range` sets sequentially inside the same function to shift across 2, 3, or more dimensions).*

---

## Return Value

**Return Type**: Numeric (Double)

Returns the numeric data value located at the newly calculated, shifted intersection.
- **Out of Bounds**: If any of the dimensional shifts push the pointer outside of the defined ranges (or off the edge of the outline), the entire function returns `#MISSING`.
- **Directionality**: The shift is strictly dictated by the physical structural order of the outline (Top-Down/Left-Right).

---

## How It Works (Behind the Scenes)

1. **Anchor Identification**: Essbase locks onto the currently calculating block (e.g., `FY25`, `Product_v2`, `Sales`).
2. **Dimension 1 Shift**: It parses the first `shiftCnt` and `dimName`. It identifies `Product_v2` in the outline, steps backward (if `-1`) to `Product_v1`.
3. **Dimension 2 Shift**: It parses the second `shiftCnt` and `dimName`. It identifies `FY25` in the outline, steps backward to `FY24`.
4. **Data Retrieval**: It constructs a virtual cross-dimensional pointer (`Sales` -> `Product_v1` -> `FY24`), queries that specific block, retrieves the numeric value, and returns it to the original calculating block.

---

## Syntax Variants & Scenarios

### Variant 1: 2-Dimensional Shift

```essbase
/* 
   Retrieves "Units", shifting back 1 period in Time, 
   and shifting back 1 member in the Product dimension.
*/
"Historical_Proxy" = @MDSHIFT("Units", -1, "Time", -1, "Product");
```

---

## Practical Examples

### Example 1: Multi-Scenario Year-Over-Year Math

**Scenario**: The `"Working"` forecast for `"FY25"` must be seeded with data from the `"Final"` scenario of `"FY24"`. Both the Scenario and the Year must shift simultaneously. 
(Assume the outline order is: Scenarios: `Final`, `Working`. Years: `FY24`, `FY25`).

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. We are calculating FY25 Working. 
       We need to retrieve the "Revenue" from the block that is 
       1 step backward in Scenario, AND 1 step backward in Year.
    */
    "Forecast_Seed" = @MDSHIFT("Revenue", 
        -1, "Scenario", 
        -1, "Year"
    );
    
    /* 
       Results:
       Current Block: FY25 -> Working.
       MDSHIFT steps Scenario backward from Working to Final.
       MDSHIFT steps Year backward from FY25 to FY24.
       It queries Final -> FY24 -> Revenue, and writes that value into 
       the FY25 -> Working -> Forecast_Seed block.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Structural Dependence | Assuming logical sorting | Just like standard `@SHIFT`, `@MDSHIFT` blindly steps up and down the physical `.otl` outline. If an administrator sorts the Scenarios alphabetically, `"Final"` might suddenly appear *after* `"Working"`. The `-1` shift will fail, crashing the calculation. You MUST strictly control the chronological/logical ordering of any dimension you intend to shift across |
| Missing Range Boundaries | Shifting into the void | If you are shifting across `Months`, and the engine is sitting on `Jan`, a `-1` shift goes off the edge of the year and returns `#MISSING`. If you want to seamlessly shift from `Jan` back into `Dec` of the prior year, `@MDSHIFT` cannot do that natively (unless you structure a massive multi-year chronological time dimension). You must use complex `IF` logic or the specialized `@PRIOR` function with `XrangeList` |
| Over-Complication | Using `@MDSHIFT` for static pointers | If you just want to pull `"Actuals"` into `"Forecast"`, do not use `@MDSHIFT` to shift `-1` in Scenario. Just use standard cross-dimensional pointers (`"Forecast" = "Actuals";`). `@MDSHIFT` should ONLY be used when the shift is dynamic and must run sequentially across a range of calculating members |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SHIFT`](../17_Time_Series/@SHIFT.md) | The single-dimension version. Shifts data backward or forward, but only across one dimension at a time |
| [`@PRIOR`](../17_Time_Series/@PRIOR.md) | The time-series specific version of shifting. Extremely powerful because it natively handles year-boundary crossings, which `@MDSHIFT` cannot easily do |
| [`@NEXT`](../17_Time_Series/@NEXT.md) | The forward-looking time-series equivalent |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MDSHIFT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mdshift.html)
