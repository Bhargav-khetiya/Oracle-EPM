# @IRDESCENDANTS

## Overview

`@IRDESCENDANTS` is a **member set function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **right descendants** of a specified member, **inclusive** — meaning the member itself is included in the returned set along with its right-branch descendants. "Right descendants" follow the rightmost (last child) path downward through the hierarchy.

### Why Does This Function Exist—

In hierarchies where the right branch represents a specific category (e.g., "Other" categories, adjustment members, or the last-reported entity):
- Target calculations to the right branch including the parent
- Build member sets for FIX statements that scope to the right hierarchy path
- Implement logic that processes the "last" branch of the hierarchy with its parent

### When to Use It

- When you need right-branch descendants **plus** the member itself
- In FIX statements to scope calculations to the right hierarchy path inclusively
- When the rightmost branch has special calculation treatment (e.g., "Other" or "Adjustments")
- Use `@IRDESCENDANTS` for inclusive; use `@RDESCENDANTS` for exclusive

---

## Category

**Member Set / Relationship / Hierarchy**

---

## Syntax

```essbase
@IRDESCENDANTS(member)
```

### Formal Syntax

```
@IRDESCENDANTS(mbrName)
```

Where:
- `mbrName` — Any valid member in the outline

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name | ✅ Yes | The member whose right descendants (inclusive of itself) you want to retrieve. Can be a literal member name or `@CURRMBR(dimName)`. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Member has children | The member itself PLUS its right-branch descendants |
| Member is a leaf (no children) | Just the member itself (set of one) |

**Return Type**: Member set (used in FIX, member ranges, loops)

---

## How It Works (Behind the Scenes)

1. **Inclusive**: The "I" prefix means the member itself is included in the returned set.

2. **Right-Branch Navigation**: Starting from the given member, Essbase follows the **rightmost (last) child** at each level downward, collecting all members along this path.

3. **Plus Self**: The starting member is prepended to the set, so the result is `{member} ∪ {right-branch descendants}`.

4. **Member Set Context**: Returns a set — use in FIX, LOOP, or other set operations.

5. **Static Resolution**: The set is determined once at the start of calculation.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Usage

```essbase
FIX(@IRDESCENDANTS("Total_Entity"))
    /* Processes Total_Entity PLUS its right-branch descendants */
ENDFIX
```

### Variant 2: With Other Functions

```essbase
@COUNT(@IRDESCENDANTS("Year"))
```
Returns the count of the member plus its right-branch descendants.

### Variant 3: Combined with FIX

```essbase
FIX("FY24", "Actual", @IRDESCENDANTS("All_Products"))
    "Flag" = 1;
ENDFIX
```

---

## Practical Examples

### Example 1: Right-Branch Adjustments Processing

**Scenario**: Process adjustments that are stored in the rightmost branch of the entity hierarchy, including the parent adjustment member.

```essbase
FIX("FY24", "Actual", @IRDESCENDANTS("Adjustments"))
    "Adjusted_Revenue" = "Base_Revenue" + "Manual_Adj";
ENDFIX
```

---

### Example 2: Last Quarter Processing

**Scenario**: In a Year dimension where Q4 is the last child, process Q4 and its months plus Year total.

```essbase
FIX("FY24", @IRDESCENDANTS("Year"))
    /* Processes Year total + Q4 + Oct + Nov + Dec (right branch) */
    AGG("Period");
ENDFIX
```

---

### Example 3: "Other" Category Calculations

**Scenario**: The "Other Products" member is the rightmost child — calculate its residual value.

```essbase
FIX("FY24", "Budget", @IRDESCENDANTS("Other_Products"))
    "Revenue" = "Total_Market_Revenue" - @SUM(@LSIBLINGS("Other_Products"));
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing with `@RDESCENDANTS` | `@RDESCENDANTS` is exclusive (does NOT include the member). `@IRDESCENDANTS` is inclusive. | Use `@RDESCENDANTS` when you don't want the parent member |
| Confusing with `@IDESCENDANTS` | `@IDESCENDANTS` returns ALL descendants (inclusive). `@IRDESCENDANTS` returns only RIGHT descendants (inclusive). | Use `@IDESCENDANTS` for the full subtree |
| Using in arithmetic | Returns a member SET, not a value | Use in FIX, LOOP, or set functions only |
| Leaf members | For a leaf, returns just the member itself (set of one) | This is expected behavior — not an error |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@RDESCENDANTS`](./@RDESCENDANTS.md) | Right descendants **exclusive** (does not include self) |
| [`@ILDESCENDANTS`](./@ILDESCENDANTS.md) | **Inclusive left** descendants |
| [`@LDESCENDANTS`](./@LDESCENDANTS.md) | Left descendants exclusive |
| [`@IDESCENDANTS`](./@IDESCENDANTS.md) | Inclusive ALL descendants |
| [`@DESCENDANTS`](./@DESCENDANTS.md) | ALL descendants exclusive |
| [`@IRSIBLINGS`](./@IRSIBLINGS.md) | Inclusive right siblings |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @IRDESCENDANTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/irdescendants.html)
- [Oracle Essbase Technical Reference — @IRDESCENDANTS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
