# @MDALLOCATE

## Overview

`@MDALLOCATE` is a **multi-dimensional data distribution function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It extends the functionality of `@ALLOCATE` by allowing you to spread a data value across a specified range of members in **multiple dimensions simultaneously**, rather than being restricted to a single dimension.

### Why Does This Function Exist—

Standard allocations (`@ALLOCATE`) handle pushing data down a single hierarchy (e.g., allocating Corporate IT costs down to Departments). However, complex business models often require multi-dimensional cascading:
- **Shared Services**: Allocating a central HR pool down to both *Departments* AND *Regions* at the same time based on a driver (like Headcount) that exists at the Dept/Region intersection.
- **Top-Down Budgeting**: Pushing a top-level revenue target down to *Products* AND *Customers* simultaneously based on historical actuals mix.
- **Multi-Step Elimination**: Bypassing the need for sequential allocations (Allocate to Region, then Allocate to Product) by doing it in one step.

### When to Use It

- When the target of your allocation involves crossing multiple dimensions (e.g., Entity and Product).
- When the driver data (the allocation basis) exists at the granular, multi-dimensional intersections.
- When you need precise "penny rounding" control across a multi-dimensional matrix.

---

## Category

**Data Distribution / Allocation / Multi-Dimensional**

---

## Syntax

```essbase
@MDALLOCATE(amount, numDims, rangeList..., allocBasis, [roundMethod], [zeroHandling])
```

### Formal Syntax

```
@MDALLOCATE(amountExpr, numberOfDims, rangeList1, [rangeList2...], basisMbr, [roundOption], [zeroOption])
```

Where:
- `amountExpr` — The total amount to be distributed.
- `numberOfDims` — The number of dimensions being allocated across (integer).
- `rangeList` — The member lists for each dimension (you must provide exactly as many range lists as `numberOfDims`).
- `basisMbr` — The allocation driver (e.g., "Headcount") or keyword (`spread`, `share`).
- `roundOption` — (Optional) How to handle rounding differences.
- `zeroOption` — (Optional) How to handle `#MISSING` or `0` values in the basis.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `amount` | Numeric | ✅ Yes | The source value to allocate. |
| `numDims` | Integer | ✅ Yes | The number of target dimensions (e.g., `2` for Entity and Product). |
| `rangeLists` | Member lists| ✅ Yes | A comma-separated series of range lists, matching `numDims`. E.g., `@CHILDREN("Entity"), @CHILDREN("Product")`. |
| `allocBasis` | Member/Key| ✅ Yes | The driver for the allocation (e.g., `"Headcount"`), or `spread`. |
| `roundMethod` | Keyword | ❌ No | e.g., `roundAmt`, `roundErrTo` for penny rounding control. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the allocated portion of the amount for the current multi-dimensional intersection being evaluated.

---

## How It Works (Behind the Scenes)

1. **Matrix Construction**: Essbase builds a virtual matrix of all possible intersections defined by the multiple `rangeList` parameters.
2. **Sum the Basis**: It evaluates the `allocBasis` at every intersection in that matrix and sums it to find the global denominator.
3. **Calculate Share**: For each intersection, it calculates the share: `Intersection_Basis / Global_Basis`.
4. **Rounding Correction**: If a rounding option is specified, it tracks fractional pennies lost across the entire matrix and assigns the remainder to the specific cross-dimensional intersection specified in `roundErrTo`.

---

## Syntax Variants & Scenarios

### Variant 1: Two-Dimensional Allocation

```essbase
"Allocated_Overhead" = @MDALLOCATE(
    "Overhead_Pool"->"Corporate"->"No_Product", 
    2,                               /* 2 Dimensions */
    @CHILDREN("Total Entity"),       /* Dim 1 Range */
    @CHILDREN("Total Product"),      /* Dim 2 Range */
    "Headcountâ”‚                     /* Driver */
    share
);
```

### Variant 2: Three-Dimensional Even Spread

```essbase
"Target_Revenue" = @MDALLOCATE(
    1000000, 
    3, 
    @CHILDREN("North_America"), 
    @CHILDREN("Smartphones"), 
    @CHILDREN("Retail_Channels"), 
    spread                           /* Divide evenly across all combinations */
);
```

---

## Practical Examples

### Example 1: Allocating Freight Costs to Product and Customer

**Scenario**: You have a pool of Freight costs booked at a generic `No_Product` / `No_Customer` level. You need to allocate it down to specific Products and Customers based on `Units_Shipped`.

```essbase
FIX("FY25", "Working", @CHILDREN("Total Product"), @CHILDREN("Total Customer"))
    "Freight_Expense" = @MDALLOCATE(
        "Freight_Expense" -> "No_Product" -> "No_Customer", /* Source Pool */
        2,                                                  /* 2 Dimensions */
        @CHILDREN("Total Product"),                         /* Dim 1: Products */
        @CHILDREN("Total Customer"),                        /* Dim 2: Customers */
        "Units_Shippedâ”‚                                    /* Driver */
        share,
        roundAmt(2),                                        /* Round to cents */
        roundErrTo("Product_Other", "Customer_Other")       /* Dump penny here */
    );
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatch between `numDims` and ranges | If `numDims` is 3, but you only provide 2 range lists, the script will fail validation | Ensure the number of range arguments exactly matches `numDims` |
| Rounding Error Destination | `roundErrTo` in `@MDALLOCATE` requires a member from *every* dimension being allocated | E.g., `roundErrTo("Entity_A", "Product_B")`. If you only provide one, it fails |
| Block Creation | `@MDALLOCATE` assigns values, but if the target blocks don't exist, the allocation might fail to write | Use `SET CREATENONMISSINGBLK ON` or `@CREATEBLOCK` to ensure targets exist |
| Extreme Performance Hit | Allocating across 3 dense dimensions with hundreds of members creates millions of iterations | Be very precise with your ranges; avoid `@DESCENDANTS` of huge dimensions if possible |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ALLOCATE`](./@ALLOCATE.md) | Single-dimensional allocation (faster and simpler if only one dimension is needed) |
| [`@CREATEBLOCK`](../15_CalcMgr_Utility/@CREATEBLOCK.md) | Often needed before multi-dimensional allocations to ensure sparse blocks exist |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MDALLOCATE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mdallocate.html)
