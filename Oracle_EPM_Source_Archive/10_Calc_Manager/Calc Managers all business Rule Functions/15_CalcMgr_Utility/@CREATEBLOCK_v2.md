# @CREATEBLOCK

## Overview

`@CREATEBLOCK` is a **database management and optimization function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager used in Block Storage Option (BSO) cubes. It forces the creation of a physical data block in the Essbase database for a specified sparse intersection, even if that intersection currently has no data (`#MISSING`).

### Why Does This Function Exist?

Essbase BSO cubes are highly optimized: they do not create physical storage blocks for sparse intersections until data actually exists there. This saves massive amounts of disk space and memory. However, this optimization causes a problem during calculations:
- If you write a formula like `A = B + C`, and Block A does not exist, Essbase skips the calculation entirely to save time. 
- In Top-Down Allocations or cross-dimensional pushes (e.g., allocating Corporate Overhead down to a new Department), the target Department might not have a block yet because it has no prior data. The allocation will silently fail to write the data.

`@CREATEBLOCK` allows the developer to say: "I am about to write data here. Create the block first so the calculation doesn't skip it."

### When to Use It

- Before running `@ALLOCATE` or `@MDALLOCATE` to ensure target blocks exist.
- When pushing data from one sparse dimension member to a newly created sparse dimension member.
- As a faster, more targeted alternative to `SET CREATENONMISSINGBLK ON`.
- When calculating constant values (e.g., `Price = 10`) across empty intersections.

---

## Category

**Database Optimization / Block Management**

---

## Syntax

```essbase
@CREATEBLOCK(sparseMemberOrCrossDim)
```

### Formal Syntax

```
@CREATEBLOCK(memberCrossDimExpression)
```

Where:
- `memberCrossDimExpression` — A member or cross-dimensional intersection (tuple) specifying where the block should be created. It must resolve to a specific sparse intersection.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `sparseMember` | Member/Tuple | ✅ Yes | The target intersection where a block is required. For example, `"New_Department"` or `"New_Department"->"FY25"`. |

---

## Return Value

**Return Type**: None (It is a directive, not a function that returns a value).

Returns `1` internally if successful, but it is not used mathematically in scripts. Its sole purpose is the side-effect of instantiating the data block in memory/disk.

---

## How It Works (Behind the Scenes)

1. **Top-Down Execution**: Essbase evaluates formulas in two modes: Bottom-Up (only on existing blocks) and Top-Down. To force block creation, calculations often drop into Top-Down mode (which is slower). `@CREATEBLOCK` allows you to explicitly manage this.
2. **Empty Block**: The function creates a block full of `#MISSING` values at the specified sparse intersection.
3. **Subsequent Calculations**: Once the block exists, standard Bottom-Up calculations (like `A = B + C`) will evaluate and write data to that block successfully.
4. **vs SET CREATENONMISSINGBLK**: `SET CREATENONMISSINGBLK ON` tells the engine to create blocks *everywhere* a calculation attempts to write, which can cause severe performance issues (Data Explosion). `@CREATEBLOCK` is surgical—it only creates blocks exactly where you tell it to.

---

## Syntax Variants & Scenarios

### Variant 1: Single Sparse Member

```essbase
@CREATEBLOCK("Department_101");
```

### Variant 2: Cross-Dimensional Sparse Intersection

```essbase
@CREATEBLOCK("Department_101"->"Product_X");
```

### Variant 3: Dynamic Block Creation in a Loop/Fix

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    @CREATEBLOCK(@CURRMBR("Entity"));
ENDFIX
```

---

## Practical Examples

### Example 1: Prepping for a Top-Down Allocation

**Scenario**: You are allocating Corporate Overhead to all Departments based on Headcount. Some new departments have Headcount (driver) but no financial data yet (no existing blocks).

```essbase
FIX("FY25", "Working", @DESCENDANTS("Departments"))
    /* Step 1: Force block creation if Headcount exists */
    IF("Headcount" > 0)
        @CREATEBLOCK(@CURRMBR("Department"));
    ENDIF
    
    /* Step 2: Now run the allocation safely */
    "Allocated_Overhead" = @ALLOCATE(
        "Overhead" -> "Corporate", 
        @CHILDREN("Total_Dept"), 
        "Headcount", 
        share
    );
ENDFIX
```

---

### Example 2: Pushing Constants to Empty Intersections

**Scenario**: Assigning a standard working days metric to all active entities, even if they have no financial data yet.

```essbase
FIX("FY25", "Working", @UDA("Entity", "Active"))
    /* If we just wrote "Working_Days" = 20, it would only write to existing blocks.
       By creating the block first, we ensure every active entity gets the value. */
       
    @CREATEBLOCK(@CURRMBR("Entity"));
    "Working_Days" = 20;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Creating blocks on Dense dimensions | Dense dimensions are inside the block. You cannot "create a block" for an Account if Account is Dense | `@CREATEBLOCK` only applies to Sparse dimensions |
| Data Explosion | `FIX(@DESCENDANTS("Entity")) @CREATEBLOCK(...)` might create 10,000 empty blocks, blowing up the database size | Always wrap `@CREATEBLOCK` in an `IF` statement (e.g., `IF(Driver > 0)`) to only create blocks where absolutely necessary |
| Forgetting to use it | "My script runs successfully but no data is written!" | This is the #1 symptom of missing blocks. Add `@CREATEBLOCK` or check your block creation logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| `SET CREATENONMISSINGBLK` | The global command alternative (easier to write, but highly dangerous to performance) |
| [`@ALLOCATE`](../08_Financial/@ALLOCATE.md) | Frequently relies on `@CREATEBLOCK` to prepare target intersections |
| `DATACOPY` | Implicitly creates blocks at the target destination |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @CREATEBLOCK](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/createblock.html)
