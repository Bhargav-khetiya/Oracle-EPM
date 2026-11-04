# @SHARE

## Overview

`@SHARE` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member and returns `TRUE` or `FALSE` based on whether the active member block is a **Shared Member** pointer in the database outline.

### Why Does This Function Exist—

Essbase outlines frequently utilize "Shared Members" (an alternate hierarchy technique). For example, `"Store_101"` might physically live under the `"Geographic"` branch, but it is *shared* under a secondary `"Management_Reporting"` branch. 
Data is only physically stored in the primary (base) member. The shared member is simply a virtual pointer that redirects queries to the base block.
Because of this, running aggressive calculation logic (like data clearing, complex allocations, or formula executions) on a Shared Member is dangerous. Essbase will automatically resolve the pointer, calculate the primary block, and then potentially calculate it *again* when it naturally sweeps the primary branch, causing massive data duplication or performance bloat.
`@SHARE` allows administrators to protect their calculation scripts. By wrapping logic in `IF(NOT @SHARE(@CURRMBR("Entity")))`, the engine will explicitly skip all shared members, guaranteeing that the mathematical logic is only executed exactly once on the primary storage blocks.

### When to Use It

- **Calculation Protection**: Ensuring that complex driver-based mathematical logic only runs on base members, preventing double-execution when sweeping multiple hierarchies.
- **Data Clearances**: Wrapping `CLEARBLOCK` commands so they only delete data from primary intersections, avoiding unnecessary cross-index lookups.
- **Custom Reporting Rollups**: Executing specialized variance math *only* on the shared reporting hierarchy, leaving the primary geographical hierarchy untouched.

---

## Category

**Boolean & Conditional / Hierarchy Attributes / Essbase Native Functions**

---

## Syntax

```essbase
@SHARE(MemberName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberName` | Member | ✅ Yes | The target member to evaluate. Usually passed dynamically via `@CURRMBR("Dimension")`. |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the evaluated member is a Shared Member pointer. Returns `FALSE` (0) if the member is the primary base storage node.
- **Dynamic Context**: Essbase sweeps the outline during a `FIX`. If the engine is currently calculating the physical block under `"Geographic"` (Primary), it returns `FALSE`. Later, when the engine sweeps into `"Management_Reporting"` and hits the shared instance of the exact same store, it returns `TRUE`.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine hits the `IF(@SHARE(...))` condition.
2. **Context Check**: It queries the active metadata state of the member currently loaded in memory.
3. **Outline Property Validation**: It checks the internal flag (the `+` or `~` symbol in the classic outline viewer) that designates whether this specific node is the primary storage index or an alternate shared index.
4. **Return**: It returns `TRUE` if the flag indicates a shared node, enabling or disabling the enclosed `IF` block.

---

## Syntax Variants & Scenarios

### Variant 1: Checking the Current Member

```essbase
/* 
   Returns TRUE only when the calculation engine sweeps 
   across an alternate hierarchy shared node.
*/
IF(@SHARE(@CURRMBR("Entity")))
```

---

## Practical Examples

### Example 1: Protecting a Global Overhead Allocation

**Scenario**: A massive script allocates `"Total_Overhead"` down to every Level 0 entity in the database. The `FIX(@LEVEL0("Entity"))` includes 10,000 primary stores and 5,000 shared store pointers in a secondary reporting hierarchy. If the allocation runs blindly, the shared members will execute, redirect to the primary blocks, and allocate the overhead *twice*. The administrator uses `@SHARE` to lock the script down.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. We evaluate the current entity being calculated.
       2. We use the NOT operator. If @SHARE is FALSE (it is a primary member),
       NOT FALSE becomes TRUE, and the math executes. 
       If @SHARE is TRUE (it is a shared member), NOT TRUE becomes FALSE, 
       and the engine skips it.
    */
    IF(NOT @SHARE(@CURRMBR("Entity")))
        
        /* 
           3. Execute the allocation ONLY on the primary storage blocks.
        */
        "Allocated_Overhead" = "Total_Overhead"->"No_Entity" * ("Revenue" / "Total_Revenue");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it inside `FIX` | `FIX(@SHARE("Entity"))` | `@SHARE` is a Boolean evaluation function. It returns `TRUE` or `FALSE`. It is NOT a member selection function (it does not return an array of members). You CANNOT use it inside a `FIX` statement to select all the shared members. If you need to fix on shared members, you must use the structural member selection equivalent: `@SHARED` |
| Over-Protecting | Skipping Implicit Shares | In older versions of Essbase, if a parent had only one child, Essbase automatically designated it as an "Implicit Share" for calculation optimization. `@SHARE` will evaluate Implicit Shares as `TRUE`. If your script skips shared members, it will completely skip that parent. In modern EPM Cloud, Implicit Sharing is largely disabled by default, but always verify your outline settings if a parent is mysteriously refusing to calculate |
| Confusing with UDA | `@ISMBRWITHATTR` | Shared status is a core, physical property of the outline index. It is not an attribute or a UDA. You cannot query for "Shared" using UDA functions. You must use this dedicated structural function |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SHARED`](@SHARE.md) | The Member Selection array version. Used inside `FIX` blocks to generate a list of all shared members, rather than returning a boolean |
| [`@CURRMBR`](../04_Member_Navigation/@CURRMBR.md) | The primary mechanism used to feed the active block pointer into the `@SHARE` evaluation |
| [`@ATTRIBUTE`](../04_Member_Navigation/@ATTRIBUTE.md) | Used to query secondary metadata tags (attributes) rather than primary structural outline flags |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — SHARE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/share_bool.html)
