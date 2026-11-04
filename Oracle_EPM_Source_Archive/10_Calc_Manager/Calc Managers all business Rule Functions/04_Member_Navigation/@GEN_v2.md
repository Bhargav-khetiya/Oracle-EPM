# @GEN

## Overview

`@GEN` is a **hierarchy context function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It returns the integer generation number of a specified member within its dimension.

### Why Does This Function Exist—

In Essbase, **Generations** count from the top of the hierarchy down. Generation 1 is the absolute root member of a dimension. Generation 2 comprises the immediate children of the root, and so on.
Generations are highly stable for horizontal alignment in unbalanced hierarchies. For example, if Gen 2 is always "Region" and Gen 3 is always "Country", you can safely rely on Gen 3 to mean "Country", even if one country has states (Level 0) and another does not.

`@GEN` tells you exactly how many steps a member is from the top of the dimension.

### When to Use It

- Inside `IF` statements to route logic based on a member's top-down depth.
- When traversing unbalanced hierarchies where relying on `@LEV` (bottom-up) is dangerous due to differing branch depths.
- To dynamically pass a generation integer into functions like `@ANCEST`.

---

## Category

**Hierarchy / Member Context**

---

## Syntax

```essbase
@GEN(dimName, mbrName)
```

### Formal Syntax

```
@GEN(dimensionName, memberExpression)
```

Where:
- `dimensionName` — The dimension the member belongs to.
- `memberExpression` — The specific member you are checking (usually `@CURRMBR("Dimension")`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension | ✅ Yes | The dimension to check (must be a string or member reference). |
| `mbrName` | Member | ✅ Yes | The member whose generation you want to find. |

---

## Return Value

**Return Type**: Integer

Returns the generation number of the member.
- **Generation 1**: The root of the dimension (e.g., "Total Entity").
- **Generation 2**: The first tier of children (e.g., "North America", "EMEA").
- **Generation N**: Any subsequent descendant tier.

---

## How It Works (Behind the Scenes)

1. **Context Lookup**: Essbase queries the outline metadata for `mbrName`.
2. **Top-Down Count**: It calculates the path from the absolute root of the dimension down to `mbrName`.
3. **Integer Return**: It returns that count as an integer, allowing you to use it in mathematical comparisons (`>`, `<`, `==`).

---

## Syntax Variants & Scenarios

### Variant 1: Checking the Current Member

```essbase
IF(@GEN("Entity", @CURRMBR("Entity")) == 3)
    /* Do something only for Gen 3 members (e.g., Countries) */
ENDIF
```
*(Note: `@ISGEN("Entity", 3)` is a cleaner, more efficient way to write this exact equality check).*

### Variant 2: Less-Than Comparisons (Upper Tiers Only)

```essbase
IF(@GEN("Product", @CURRMBR("Product")) < 3)
    /* Do something only for Gen 1 (Total) and Gen 2 (Category) */
ENDIF
```

---

## Practical Examples

### Example 1: Enforcing Tiered Assumptions

**Scenario**: You have different hurdle rates for investments depending on how granular the planning is. Gen 2 (Divisions) use 10%, Gen 3 (Departments) use 12%, and anything deeper uses 15% due to higher risk.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Company"))
    VAR vMyGen = @GEN("Entity", @CURRMBR("Entity"));
    
    IF(vMyGen == 2)
        "Hurdle_Rate" = 0.10;
    ELSEIF(vMyGen == 3)
        "Hurdle_Rate" = 0.12;
    ELSEIF(vMyGen > 3)
        "Hurdle_Rate" = 0.15;
    ENDIF
ENDFIX
```

---

### Example 2: Dynamic Parent Reference in Unbalanced Hierarchy

**Scenario**: You need to calculate a ratio against the Generation 2 parent, but you are looping through members at Gen 4, Gen 5, and Gen 6. You want a dynamic offset.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    /* Find out how deep we currently are */
    VAR vMyGen = @GEN("Entity", @CURRMBR("Entity"));
    
    /* We always want Gen 2. Instead of hardcoding 2 (which might confuse some logic), 
       we could use the difference if needed for an offset function, 
       but for ANCEST we can just pass the integer 2 directly. */
       
    IF(vMyGen > 2)
        "Ratio_to_Div" = "Revenue" / "Revenue" -> @ANCEST("Entity", 2);
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Level vs Gen confusion | Gen 1 is the Top. Level 0 is the Bottom. Do not use `@GEN(..., 0)` because Generation 0 does not exist | Remember: Top-Down = Gen. Bottom-Up = Level |
| Using `@GEN` for simple equality | `IF(@GEN(...) == 3)` is slower than native Boolean checks | Use `IF(@ISGEN("Entity", 3))` for pure `IF` statement checks |
| Shared Members | The Generation of a shared member is based on its placement in the shared branch, not its primary branch | Be aware of which branch your `FIX` is traversing |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISGEN`](../09_Boolean_Conditional/@ISGEN.md) | The Boolean equivalent for testing if a member is at a specific generation (Faster for `IF` statements) |
| [`@LEV`](./@LEV.md) | Returns the bottom-up Level number instead of the top-down Generation number |
| [`@CURRGEN`](./@CURRGEN.md) | Specifically returns the generation of the *current* member without needing the `mbrName` argument |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @GEN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/gen.html)
