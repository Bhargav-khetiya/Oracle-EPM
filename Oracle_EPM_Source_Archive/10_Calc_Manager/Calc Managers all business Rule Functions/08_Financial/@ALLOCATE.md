# @ALLOCATE

## Overview

`@ALLOCATE` is a **data distribution function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that spreads a data value (an amount) across a specified range of members based on an allocation method (such as an even spread, a driver-based share, or a percentage basis).

### Why Does This Function Exist—

Allocations are the backbone of management reporting:
- **Overhead Distribution**: Spreading corporate IT costs down to operating departments.
- **Top-Down Targeting**: Pushing a total regional sales target down to individual stores.
- **Cost Absorption**: Distributing rent expense based on square footage.

While you can write manual allocation math (e.g., `Child = Parent * (Child_Driver / Parent_Driver)`), `@ALLOCATE` simplifies this by handling the math, the rounding, and the potential zero-driver errors automatically within a single function.

### When to Use It

- When you need to distribute an amount from a source to multiple destinations.
- When you want built-in handling for rounding differences (allocating the penny).
- When the allocation basis is standard (Even, Basis, Share).
- *Note: For allocations involving multiple dimensions simultaneously, use `@MDALLOCATE`.*

---

## Category

**Data Distribution / Allocation**

---

## Syntax

```essbase
@ALLOCATE(amount, rangeList, allocBasis, [roundMethod], [zeroHandling])
```

### Formal Syntax

```
@ALLOCATE(amountExpr, allocationRange, basisMbr, [roundOption], [zeroOption])
```

Where:
- `amountExpr` — The total amount to be distributed.
- `allocationRange` — The list of members that will receive the allocated amounts (e.g., `@CHILDREN("Total Entity")`).
- `basisMbr` — The member containing the driver data used for the allocation, or a keyword for flat distribution.
- `roundOption` — (Optional) How to handle rounding differences.
- `zeroOption` — (Optional) How to handle `#MISSING` or `0` values in the basis.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `amount` | Numeric/Member | ✅ Yes | The source value to allocate. |
| `rangeList` | Member list | ✅ Yes | The target members receiving the allocation. |
| `allocBasis` | Member/Keyword | ✅ Yes | The driver for the allocation. Can be a member name (e.g., `"Headcount"`), or a keyword like `basis` (use exact values) or `spread` (even distribution). |
| `roundMethod` | Keyword | ❌ No | e.g., `roundAmt`, `roundErrTo` to manage the "penny rounding" problem. |
| `zeroHandling`| Keyword | ❌ No | e.g., `SKIPNONE`, `SKIPMISSING`, `SKIPZERO` to determine what happens if a target has no driver data. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the allocated portion of the amount for the current member being evaluated in the `rangeList`.

---

## How It Works (Behind the Scenes)

1. **Sum the Basis**: Essbase first evaluates the `allocBasis` across the entire `rangeList` and sums it to find the total denominator.
2. **Calculate Share**: For each member in the range, it calculates its share: `Current_Basis / Total_Basis`.
3. **Multiply**: It multiplies the `amount` by the share.
4. **Rounding Correction**: If a rounding option is specified, it tracks fractional pennies lost to rounding and assigns the remainder to a specified member to ensure the allocated total exactly matches the source amount.

---

## Syntax Variants & Scenarios

### Variant 1: Driver-Based Allocation (Share)

```essbase
"Allocated_IT" = @ALLOCATE("IT_Pool"->"Corporate", @CHILDREN("Total Entity"), "Headcount", share);
```
*(Uses Headcount to distribute the IT Pool).*

### Variant 2: Even Spread (Spread)

```essbase
"Allocated_Rent" = @ALLOCATE("Total_Rent", @CHILDREN("Total Entity"), spread);
```
*(Distributes the rent equally among all children).*

---

## Practical Examples

### Example 1: Allocating Corporate Overhead

**Scenario**: Allocate $100,000 of HR overhead to all departments based on their headcount. Round the results to 2 decimal places, and dump any rounding errors into the "Administration" department.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Departments"))
    /* Assuming we are calculating at the department level */
    "Allocated_HR_Cost" = @ALLOCATE(
        "HR_Pool" -> "Corporateâ”‚   /* Amount to allocate */
        @CHILDREN("Total_Dept"),    /* Target Range */
        "Headcountâ”‚                /* Driver */
        roundAmt(2),                /* Round to 2 decimals */
        roundErrTo("Administration") /* Put the penny here */
    );
ENDFIX
```

---

### Example 2: Top-Down Revenue Targets

**Scenario**: Executive management set a global revenue target. Push this target down to the regions evenly.

```essbase
FIX("FY25", "Target", @CHILDREN("Total Geography"))
    "Revenue" = @ALLOCATE(
        "Revenue" -> "Total Geography", /* The top-level target */
        @CHILDREN("Total Geography"),   /* The regions */
        spread,                         /* Divide evenly */
        roundAmt(0)                     /* Whole numbers only */
    );
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not using `@MDALLOCATE` for multi-dim | `@ALLOCATE` distributes across a range of members in *one* dimension | If you need to allocate across Entity AND Product simultaneously, use `@MDALLOCATE` |
| Rounding Errors | Allocating $100 across 3 entities evenly gives 33.33 each. The total is 99.99. You lost a penny | Always use `roundAmt` and `roundErrTo` for financial allocations |
| Missing Driver Data | If the total of the driver across the range is 0, the allocation fails (divide by zero) | Use `IF` statements to verify the total driver > 0 before calling `@ALLOCATE` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MDALLOCATE`](./@MDALLOCATE.md) | Multi-dimensional allocation |
| [`@CREATEBLOCK`](./@CREATEBLOCK.md) | Often needed before allocation to ensure target blocks exist |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ALLOCATE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/allocate.html)
