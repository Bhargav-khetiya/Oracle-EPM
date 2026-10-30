# @MBRPARENT

## Overview

`@MBRPARENT` is a **member navigation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **name of the parent member** for a given member. Unlike `@PARENTVAL` (which returns the parent's data value), `@MBRPARENT` returns the parent **member itself** as a member reference, which can then be used in cross-dimensional references, conditional checks, or other member-based operations.

### Why Does This Function Exist?

In hierarchical planning applications, you often need to dynamically determine a member's parent to:
- Build cross-dimensional references that navigate to the parent level
- Implement roll-up or allocation logic that references the parent's data
- Create dynamic member comparisons based on hierarchy position
- Avoid hard-coding parent member names in business rules

### When to Use It

- When you need to **reference** the parent member dynamically (not just its value)
- In combination with `->` (cross-dimensional operator) to point to the parent's data
- When building dynamic rules where the hierarchy may change between planning cycles
- Use `@MBRPARENT` to get the member; use `@PARENTVAL` to directly get the parent's value

---

## Category

**Member / Navigation / Hierarchy**

---

## Syntax

```essbase
@MBRPARENT(member)
```

### Formal Syntax

```
@MBRPARENT(mbrName)
```

Where:
- `mbrName` — Any valid member name in the outline

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name / reference | ✅ Yes | The member whose parent you want to find. Can be a literal member name, `@CURRMBR(dimName)`, or another member function. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Member has a parent | The parent member reference |
| Member is a dimension root (no parent) | Undefined behavior — avoid using on dimension root members |

**Return Type**: Member reference (can be used in cross-dimensional references and member comparisons)

---

## How It Works (Behind the Scenes)

1. **Outline Lookup**: Essbase looks up the specified member in the outline hierarchy and returns a reference to its immediate (direct) parent.

2. **Single Level Up**: `@MBRPARENT` moves exactly **one level up** in the hierarchy. To go higher, nest calls: `@MBRPARENT(@MBRPARENT(member))`.

3. **Member Reference**: The return is a **member reference**, not a data value. You typically use it with `->` for cross-dimensional access, or in member comparison functions like `@ISMBR`.

4. **No Data Read**: `@MBRPARENT` does not read data from the database — it only inspects the outline metadata.

5. **Dynamic Resolution**: The parent relationship is resolved at runtime, making this function safe for use in rules that span changing hierarchies.

---

## Syntax Variants & Scenarios

### Variant 1: Get Parent of Current Member

```essbase
@MBRPARENT(@CURRMBR("Entity"))
```
Returns the parent member of the current entity being processed.

### Variant 2: Use in Cross-Dimensional Reference

```essbase
"Variance" = Revenue - Revenue -> @MBRPARENT(@CURRMBR("Scenario"));
```
Subtracts the parent scenario's Revenue from the current scenario's Revenue.

### Variant 3: Nested Parent (Grandparent)

```essbase
@MBRPARENT(@MBRPARENT(@CURRMBR("Product")))
```
Returns the grandparent of the current product member.

### Variant 4: In a Conditional Check

```essbase
IF(@ISMBR(@MBRPARENT(@CURRMBR("Entity")), "East_Region"))
    /* Current entity's parent is East_Region */
ENDIF
```

---

## Practical Examples

### Example 1: Percentage of Parent Revenue

**Scenario**: Calculate each entity's revenue as a percentage of its parent entity's revenue.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Entity"))
    "Rev_Pct_of_Parent" = Revenue / (Revenue -> @MBRPARENT(@CURRMBR("Entity"))) * 100;
ENDFIX
```

**What Happens**: For entity "US_East", if its parent is "North_America", this calculates `US_East Revenue / North_America Revenue * 100`.

---

### Example 2: Inherit Parent's Assumption Rate

**Scenario**: If a leaf entity doesn't have its own growth rate, inherit the parent entity's rate.

```essbase
FIX("FY24", "Forecast", @DESCENDANTS("Total_Entity"))
    IF("Growth_Rate" == #MISSING)
        "Growth_Rate" = "Growth_Rate" -> @MBRPARENT(@CURRMBR("Entity"));
    ENDIF
ENDFIX
```

---

### Example 3: Variance to Parent Allocation Share

**Scenario**: Compare each product's allocation share to what the parent product group expects.

```essbase
FIX("FY24", "Budget", @DESCENDANTS("Total_Products"))
    "Alloc_Variance" = "Alloc_Share" - ("Alloc_Share" -> @MBRPARENT(@CURRMBR("Product")));
ENDFIX
```

---

### Example 4: Dynamic Consolidation Ratio

**Scenario**: Calculate each entity's consolidation weight relative to its parent.

```essbase
FIX("FY24", @DESCENDANTS("Total_Entity"))
    IF("Total_Assets" -> @MBRPARENT(@CURRMBR("Entity")) <> 0)
        "Consol_Weight" = "Total_Assets" / ("Total_Assets" -> @MBRPARENT(@CURRMBR("Entity")));
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on root member | The dimension root has no parent — results are undefined | Add `IF(@LEV(@CURRMBR(dim)) < @LEV(rootMbr))` guard |
| Confusing with `@PARENTVAL` | `@MBRPARENT` returns a **member**; `@PARENTVAL` returns a **data value** | Use `@PARENTVAL` if you just need the numeric value directly |
| Confusing with `@PARENT` | `@PARENT` is typically used in member set contexts (FIX, range). `@MBRPARENT` is used for dynamic member references in formulas | Check the context — set function vs. formula reference |
| Division by zero | Parent's value could be zero or `#MISSING` when used as denominator | Always check `IF(expr <> 0)` before dividing |
| Expecting data at parent | Parent members may only have aggregated values, or they may be `#MISSING` if aggregation hasn't run | Ensure you run aggregation (AGG) before referencing parent values |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PARENT`](./@PARENT.md) | Returns parent as a member set — used in FIX, member ranges |
| [`@PARENTVAL`](../05_Data_Access/@PARENTVAL.md) | Returns the **data value** at the parent member directly |
| [`@ANCEST`](./@ANCEST.md) | Returns ancestor at a specific generation — more flexible |
| [`@ANCESTVAL`](../05_Data_Access/@ANCESTVAL.md) | Returns the data value at a specific ancestor |
| [`@ISPARENT`](../09_Boolean_Conditional/@ISPARENT.md) | Boolean check if one member is the parent of another |
| [`@CURRMBR`](./@CURRMBR.md) | Returns the current member — often used as input to `@MBRPARENT` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MBRPARENT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mbrparent.html)
- [Oracle Essbase Technical Reference — @MBRPARENT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
