# @SHIFTSIBLING

## Overview

`@SHIFTSIBLING` is a **native Essbase member selection/shifting function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a target member and navigates horizontally across its structural peer group (its siblings). It steps backward (left) or forward (right) by a specified integer offset, and returns the **physical member name** (or pointer) of the sibling sitting at that offset.

### Why Does This Function Exist?

When building dynamic calculation scripts, administrators often need to reference a peer member relative to the member currently being calculated. 
For example, if you are forecasting `"Version_3"`, you might need to copy the starting balance from `"Version_2"`. You don't want to hardcode `"Version_2"`, because next month you'll be on `"Version_4"` and need `"Version_3"`. 
You can't use `@PRIOR` because `@PRIOR` is strictly for retrieving *data* across Time dimensions. If you want to actually return the structural *name* of a sibling in the Version dimension so you can use it in a cross-dimensional pointer (e.g., `Value -> Prior_Version`), you need a structural function.
`@SHIFTSIBLING` solves this. By calling `@SHIFTSIBLING(-1)`, Essbase looks at the current Version, steps one sibling to the left, and returns the actual member pointer (e.g., `"Version_2"`). You can then use this pointer dynamically anywhere in your script.

### When to Use It

- **Version Control**: Dynamically shifting between forecast versions (`"Draft_V1"`, `"Draft_V2"`) to calculate variances or carry over opening balances without hardcoding the version names.
- **Peer-to-Peer Allocations**: Pushing an overhead allocation from `"Store_A"` to `"Store_B"` (if they are structured sequentially in the outline) by dynamically shifting the target pointer `+1`.
- **Sequential Phases**: In project planning, automatically rolling unspent budget from `"Phase_1"` into `"Phase_2"` by shifting the pointer forward along the project sibling tier.

---

## Category

**Member Selection / Hierarchy Traversal & Shifting / Essbase Native Functions**

---

## Syntax

```essbase
@SHIFTSIBLING(mbrName, shiftCnt)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The anchor member from which the shift begins. Commonly dynamically provided via `@CURRMBR("Dimension")`. |
| `shiftCnt` | Integer | ✅ Yes | The mathematical offset. <br>- Negative (`-1`): Shifts Left/Up (backward in the sibling tier). <br>- Positive (`1`): Shifts Right/Down (forward in the sibling tier). |

---

## Return Value

**Return Type**: Member (Pointer)

Returns the structural member object located at the specified offset.
- **Out of Bounds**: If the shift pushes the pointer past the absolute first sibling (e.g., trying to shift `-1` from `"Jan"`) or past the absolute last sibling, the function returns an **empty set**. If this is used on the right side of an equation, it will generally result in `#MISSING`.
- **Exclusivity**: The members MUST share the exact same parent. If `"Dec"` and `"Jan"` are in different years (different parents), shifting `+1` from `"Dec"` will NOT jump to `"Jan"`. It will hit the wall of the parent and return empty. To cross parent boundaries, you must use `@PRIOR` with an `@XRANGE`.

---

## How It Works (Behind the Scenes)

1. **Anchor Identification**: Essbase resolves the `mbrName` (e.g., `"Phase_2"`).
2. **Parent Resolution**: It identifies the direct parent of that anchor.
3. **Array Generation**: It identifies all children of that parent, creating a horizontal array of siblings in strict outline order.
4. **Index Shift**: It locates the anchor in the array, applies the `shiftCnt` to the index (e.g., `-1`), and moves to the new index (e.g., `"Phase_1"`).
5. **Return**: It returns that specific member pointer to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Previous Version

```essbase
/* 
   If evaluating "Draft_V3", this returns a pointer to "Draft_V2".
*/
VAR vPriorVersion = @SHIFTSIBLING(@CURRMBR("Version"), -1);
```

---

## Practical Examples

### Example 1: Dynamic Version Carry-Over

**Scenario**: A forecasting application uses multiple draft versions (`"Draft_v1"`, `"Draft_v2"`, `"Draft_v3"`). When a new draft is initialized, the administrator wants a script that automatically copies the `"Final_Review"` data from the *previous* draft version into the new draft as a starting point. They use `@SHIFTSIBLING` to dynamically generate the cross-dimensional pointer.

```essbase
/* 
   1. The script is triggered on the active draft version (e.g., Draft_v3).
*/
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       2. We use @SHIFTSIBLING to find the version immediately to the left.
       For Draft_v3, this function returns a pointer to Draft_v2.
       We then use that pointer (->) to retrieve the Final_Review data 
       from Draft_v2, and copy it into the Starting_Balance of Draft_v3.
    */
    "Starting_Balance" = "Final_Review" -> @SHIFTSIBLING(@CURRMBR("Version"), -1);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Data | `@SHIFTSIBLING = 500` | This function returns a structural Member Pointer (a name), NOT a numeric data value. If you write `"Sales" = @SHIFTSIBLING("Store_A", 1)`, the compiler will crash because you are trying to stuff the literal word `"Store_B"` into a numeric database block. You must use it as a cross-dimensional pointer: `"Sales" = "Sales" -> @SHIFTSIBLING(...)` |
| Crossing Parent Boundaries | Month-to-Month shifting | Do NOT use this function to shift time periods across year boundaries. If you shift `-1` from `"Jan"`, the function will fail because `"Dec"` is not a sibling of `"Jan"` (they have different parents: FY24 vs FY25). If you need to shift across Time, you MUST use the data-retrieval function `@PRIOR` or `@NEXT` combined with `@XRANGE` |
| Zero Offset | `@SHIFTSIBLING(Target, 0)` | A shift of `0` means "do not move." While technically valid in some compiler versions (it just returns the target itself), it is mathematically pointless and adds unnecessary function-evaluation overhead to the script |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PRIOR`](./@PRIOR.md) | Shifts backwards, but specifically returns the *data value* of the block, and natively supports crossing parent boundaries in Time |
| [`@NEXT`](./@NEXT.md) | Shifts forwards, returning the *data value* |
| [`@SIBLINGS`](./@SIBLINGS.md) | Returns an array of ALL siblings, rather than shifting to one specific sibling |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — SHIFTSIBLING](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/shiftsibling.html)
