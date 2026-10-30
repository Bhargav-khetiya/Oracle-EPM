# @ISIPARENT

## Overview

`@ISIPARENT` is a **Boolean relationship function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that checks whether a specified member is the **parent** of another member, **inclusive** — meaning the member itself is also considered its own parent. It returns `TRUE` (non-zero) if the first member is the parent of the second member, or if the two members are the same member.

### Why Does This Function Exist?

In hierarchical dimension structures (Entity, Account, Product, etc.), you often need to verify parent-child relationships in conditional logic:
- Applying different calculation rules based on hierarchy position
- Validating data entry at the correct hierarchy level
- Routing allocations based on organizational structure
- The "inclusive" variant (`@ISIPARENT`) is useful when you want a condition that is true for both the parent AND the member itself

### When to Use It

- When you need to check if member A is the parent of member B, OR if A equals B
- In conditional logic (`IF` blocks) to branch calculations based on hierarchy
- When building dynamic business rules that adapt to hierarchy changes
- Use `@ISIPARENT` over `@ISPARENT` when you need the inclusive check (member counts as its own parent)

---

## Category

**Boolean / Relationship / Hierarchy**

---

## Syntax

```essbase
@ISIPARENT(parentMember, childMember)
```

### Formal Syntax

```
@ISIPARENT(mbrName1, mbrName2)
```

Where:
- `mbrName1` — The potential parent member to test
- `mbrName2` — The potential child member to test against

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName1` | Member name | ✅ Yes | The member to test as the potential parent. Must be a valid member in the outline. Can be a member name, alias, or a function that returns a member (e.g., `@CURRMBR`). |
| `mbrName2` | Member name | ✅ Yes | The member to test as the potential child. Must be in the same dimension as `mbrName1`. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| `mbrName1` is the direct parent of `mbrName2` | `TRUE` (non-zero) |
| `mbrName1` equals `mbrName2` (same member) | `TRUE` (non-zero) — this is the "inclusive" part |
| `mbrName1` is NOT the parent and is NOT the same member | `FALSE` (0) |

**Return Type**: Boolean (used in `IF` conditions)

---

## How It Works (Behind the Scenes)

1. **Hierarchy Lookup**: Essbase checks the outline hierarchy to determine whether `mbrName1` is the **direct** parent of `mbrName2`. It does NOT check grandparent or higher ancestors — only the immediate parent.

2. **Inclusive Logic**: The "I" prefix stands for **Inclusive**. Unlike `@ISPARENT`, `@ISIPARENT` also returns TRUE when `mbrName1` and `mbrName2` are the **same member**. Think of it as: "Is mbrName1 the parent of mbrName2, or IS mbrName1 the same as mbrName2?"

3. **Same Dimension Requirement**: Both members must belong to the same dimension. Cross-dimension parent checks are not supported.

4. **No Block Impact**: As a Boolean function, `@ISIPARENT` does not read or write data values. It only inspects the outline metadata.

5. **Dynamic Evaluation**: If the outline hierarchy changes (members moved, added, or deleted), `@ISIPARENT` reflects the current hierarchy at calculation time.

---

## Syntax Variants & Scenarios

### Variant 1: Direct Parent Check

```essbase
IF(@ISIPARENT("Electronics", @CURRMBR("Product")))
    /* TRUE for "Electronics" itself AND any direct child of Electronics */
ENDIF
```

### Variant 2: With @CURRMBR

```essbase
IF(@ISIPARENT(@CURRMBR("Entity"), "East_Region"))
    /* TRUE if the current entity IS East_Region or is a direct child of East_Region */
ENDIF
```

### Variant 3: Comparing Two Specific Members

```essbase
IF(@ISIPARENT("Total_Revenue", "Product_Revenue"))
    "Flag" = 1;
ENDIF
```

---

## Practical Examples

### Example 1: Selective Allocation Rule

**Scenario**: Apply an overhead allocation only to entities that are direct children of "Corporate" or to Corporate itself.

```essbase
FIX("FY24", "Working", @DESCENDANTS("Total_Entity"))
    IF(@ISIPARENT("Corporate", @CURRMBR("Entity")))
        "Overhead_Alloc" = "Total_Overhead" * "Revenue" / "Corp_Total_Revenue";
    ENDIF
ENDFIX
```

**What Happens**: The allocation runs for "Corporate" itself and for each direct child of "Corporate" (e.g., "Corp_Finance", "Corp_HR", "Corp_IT"). Other entities are skipped.

---

### Example 2: Hierarchy-Aware Margin Calculation

**Scenario**: Calculate margin differently depending on whether the current account is a parent-level summary or a leaf-level detail.

```essbase
FIX("FY24", "Actual")
    IF(@ISIPARENT("Total_Revenue", @CURRMBR("Account")))
        "Margin_Pct" = ("Total_Revenue" - "Total_COGS") / "Total_Revenue" * 100;
    ELSE
        "Margin_Pct" = ("Revenue" - "COGS") / "Revenue" * 100;
    ENDIF
ENDFIX
```

---

### Example 3: Data Validation Check

**Scenario**: Flag if data has been entered at a parent level (which should only hold aggregated values).

```essbase
FIX("FY24", "Input", @DESCENDANTS("All_Products"))
    IF(@ISIPARENT(@CURRMBR("Product"), @CURRMBR("Product")))
        /* This is always true for the member itself — so this alone isn't useful */
        /* Combine with @CHILDREN or @LEV to make meaningful checks */
        IF(@LEV(@CURRMBR("Product")) > 0)
            /* This is a parent member */
            IF("Manual_Input" <> #MISSING)
                "Validation_Flag" = 1; /* Data entered at parent level — investigate */
            ENDIF
        ENDIF
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing `@ISIPARENT` with `@ISPARENT` | `@ISIPARENT` is **inclusive** (member = itself counts as parent). `@ISPARENT` is exclusive. | Use `@ISPARENT` if you do NOT want the self-match |
| Expecting grandparent to return TRUE | `@ISIPARENT` only checks **direct** parent, not ancestors | Use `@ISIANCEST` for ancestor checks |
| Cross-dimension check | Both members must be in the same dimension | Ensure both parameters reference the same dimension |
| Using in data calculations | `@ISIPARENT` returns Boolean, not a data value | Use only in `IF` conditions, not in arithmetic expressions |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISPARENT`](./@ISPARENT.md) | **Exclusive** parent check — does NOT include self |
| [`@ISIANCEST`](./@ISIANCEST.md) | Inclusive ancestor check — checks all ancestors, not just parent |
| [`@ISICHILD`](./@ISICHILD.md) | Inclusive child check — reverse direction |
| [`@ISIDESC`](./@ISIDESC.md) | Inclusive descendant check — checks all descendants |
| [`@PARENT`](./@PARENT.md) | Returns the parent member (not a Boolean check) |
| [`@ISMBR`](./@ISMBR.md) | Tests if current member matches a specific member |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISIPARENT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isiparent.html)
- [Oracle Essbase Technical Reference — @ISIPARENT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
