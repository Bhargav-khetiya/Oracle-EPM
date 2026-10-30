# @ANCEST

## Overview

`@ANCEST` is a **member navigation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the ancestor of a specified member at a specific generation or level in the outline. 

### Why Does This Function Exist?

When calculating at a detailed (base) level, you frequently need to reference a specific parent higher up the tree. However, hardcoding parent names breaks if the hierarchy reorganizes. 
- You need the regional parent of a specific store to calculate a "Share of Region" metric.
- You need the top-level "Total Entity" to find a global allocation rate.

`@ANCEST` dynamically walks up the outline tree from the current member and grabs the specific parent/grandparent at the level or generation you request.

### When to Use It

- To dynamically reference a parent for driver-based allocations.
- To calculate "percentage of total" or "share of parent" metrics.
- When traversing unbalanced hierarchies where you specifically need an ancestor at a known generation (e.g., Generation 3 is always the "Region" level).

---

## Category

**Member Selection / Navigation / Hierarchy**

---

## Syntax

```essbase
@ANCEST(mbrName, genLevNum | genLevName)
```

### Formal Syntax

```
@ANCEST(memberExpression, generationOrLevelParameter)
```

Where:
- `memberExpression` — The starting member (often `@CURRMBR("Dimension")`).
- `generationOrLevelParameter` — A number or name specifying how far up the tree to go. Can be a level number (e.g., `1`), a generation number (e.g., `3`), or a level/gen name.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The member whose ancestor you are trying to find. |
| `genLevNum` | Integer/String| ✅ Yes | The generation or level of the ancestor you want to retrieve. E.g., `3` (Generation 3), `1` (Level 1, immediate parent of level 0), or `"Region"` (if you named the generation). |

---

## Return Value

**Return Type**: Member Reference

Returns the member name of the ancestor.
- If the starting member is already at or above the specified generation/level, the function returns an empty string/null reference.
- If an invalid level is specified, it returns an error.

---

## How It Works (Behind the Scenes)

1. **Hierarchy Walk**: Essbase identifies the `mbrName` in the outline.
2. **Ascension**: It walks up the parent-child relationships until it hits a member that matches the `genLevNum` condition.
3. **Reference Output**: It returns that member reference, allowing you to use it on either the left side of an equation (as a target) or the right side (to pull a value).

*Remember: **Generation** counts Top-Down (Gen 1 is the absolute top). **Level** counts Bottom-Up (Level 0 is the lowest leaf node).*

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Generation 2 Ancestor

```essbase
@ANCEST(@CURRMBR("Entity"), 2)
/* Finds the Gen 2 parent of the current entity */
```

### Variant 2: Finding the Immediate Parent (Level 1)

```essbase
@ANCEST("Store_101", 1)
/* Equivalent to @PARENT("Store_101") */
```

### Variant 3: Target for Cross-Dimensional Push

```essbase
"Region_Subtotal" -> @ANCEST(@CURRMBR("Entity"), 3) = "Store_Revenue";
```

---

## Practical Examples

### Example 1: Calculating "Share of Region"

**Scenario**: You want to calculate what percentage each store contributes to its specific Region. Regions are fixed at Generation 3 in the Entity dimension.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    /* If the regional total is greater than 0, calculate the share */
    IF("Revenue" -> @ANCEST(@CURRMBR("Entity"), 3) > 0)
        "Share_of_Region_Pct" = "Revenue" / "Revenue" -> @ANCEST(@CURRMBR("Entity"), 3);
    ENDIF
ENDFIX
```
*Result: When calculating "Store_NY", it automatically grabs "Revenue->North_America". When calculating "Store_London", it grabs "Revenue->EMEA".*

---

### Example 2: Parking Eliminations at the Common Parent

**Scenario**: You need to calculate intercompany eliminations and park them at the first common parent (Level 1) above the operating companies.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    /* Push the elimination entry to the immediate parent (Level 1) */
    "Elimination_Adj" -> @ANCEST(@CURRMBR("Entity"), 1) = "IC_Payable" * -1;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Gen vs Level confusion | Gen 1 is the Top. Level 0 is the Bottom. `ANCEST(x, 1)` means Level 1 (immediate parent). `ANCEST(x, 2)` means Level 2 or Gen 2 depending on the engine context | Be extremely careful. In modern Essbase, if you just pass a number, it generally assumes **Level** if you pass 0, 1, 2, but it's much safer to use `@ANCESTVAL` or named generations if the hierarchy is unbalanced |
| Unbalanced Hierarchies | In an unbalanced hierarchy, Level 1 might be a Region for one branch, but a Country for another | Use Generation targeting (e.g., Gen 3) if your hierarchy design relies on generations to mean specific things (like Regions) |
| Using for Data Value | `"Value" = @ANCEST(...)` is technically valid if used properly in cross-dims, but `@ANCESTVAL` is explicitly designed to retrieve the numeric data value | Use `@ANCESTVAL` when you just need the number |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ANCESTVAL`](../05_Data_Access/@ANCESTVAL.md) | Returns the numeric data value of the ancestor directly |
| [`@PARENT`](./@PARENT.md) | Returns the immediate Level 1 parent (functionally equivalent to `@ANCEST(mbr, 1)`) |
| [`@CURRMBR`](./@CURRMBR.md) | Frequently used as the starting point for `@ANCEST` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ANCEST](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ancest.html)
