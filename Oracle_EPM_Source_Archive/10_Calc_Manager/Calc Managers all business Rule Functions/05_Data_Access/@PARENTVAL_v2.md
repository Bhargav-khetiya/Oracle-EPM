# @PARENTVAL

## Overview

`@PARENTVAL` is a **data access function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **data value stored at the parent member** of the current member. Unlike `@PARENT` which returns the member itself, `@PARENTVAL` returns the **numeric value** — making it directly usable in calculations.

### Why Does This Function Exist?

Many financial calculations need to reference the parent's aggregated value:
- Calculating percentage contribution to parent total
- Comparing a child's performance against the parent average
- Building top-down disaggregation formulas
- Computing variance between child and parent metrics

`@PARENTVAL` provides a shorthand for what would otherwise require `Value -> @PARENT(@CURRMBR("Dim"))`.

### When to Use It

- To calculate member's percentage share of parent total
- When computing per-child averages based on parent aggregate
- In top-down allocation or disaggregation patterns
- When comparing child metrics against parent benchmarks
- To compute child-to-parent ratios

---

## Category

**Member / Data Access / Navigation**

---

## Syntax

```essbase
@PARENTVAL(dimName)
```

### Formal Syntax

```
@PARENTVAL(dimensionName)
```

Where:
- `dimensionName` — The dimension for which to retrieve the parent member's value.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension name | ✅ Yes | The dimension in which to look up the parent. @PARENTVAL reads the value at the parent member of the current member in this dimension, with all other dimensions from the current context. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Parent has stored data | Numeric value at parent |
| Parent data is #MISSING | `#MISSING` |
| Current member is root | Its own value (no parent) |

**Return Type**: Numeric (double-precision floating point)

---

## How It Works (Behind the Scenes)

1. **Implicit Cross-Reference**: `@PARENTVAL("Entity")` is equivalent to reading the current account/period/scenario value at the parent entity. It's a shorthand for a cross-dimensional read.

2. **Aggregation Dependency**: @PARENTVAL reads STORED parent values. If the parent hasn't been aggregated yet (AGG hasn't run), the value may be stale. Always ensure parents are aggregated before using @PARENTVAL.

3. **Dense Dimension Behavior**: When used on a dense dimension (like Account), @PARENTVAL reads within the same block. When used on a sparse dimension (like Entity), it reads from a different block.

4. **Current Context**: @PARENTVAL uses the current calculation context for all dimensions except the specified one, where it moves to the parent.

5. **Root Member**: If the current member IS the root, @PARENTVAL returns the root's own value (equivalent to no movement).

---

## Syntax Variants & Scenarios

### Variant 1: Simple Percentage of Parent

```essbase
"Rev_Share" = Revenue / @PARENTVAL("Entity") * 100;
```

### Variant 2: Variance from Parent Average

```essbase
"Var_from_Avg" = Revenue - (@PARENTVAL("Entity") / @NUMCHILDREN(@PARENT(@CURRMBR("Entity"))));
```

### Variant 3: In a Condition

```essbase
IF(@PARENTVAL("Account") > 0)
    "Pct_of_Total" = Revenue / @PARENTVAL("Account") * 100;
ENDIF
```

### Variant 4: Multi-Dimension Use

```essbase
"Entity_Mix" = Revenue / @PARENTVAL("Entity") * 100;
"Account_Mix" = Revenue / @PARENTVAL("Account") * 100;
```

---

## Practical Examples

### Example 1: Revenue Share of Division

**Scenario**: Calculate each entity's revenue as a percentage of its division (parent).

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@PARENTVAL("Entity") > 0)
        "Revenue_Share" = Revenue / @PARENTVAL("Entity") * 100;
    ELSE
        "Revenue_Share" = #MISSING;
    ENDIF
ENDFIX
```

**What Happens**:
- For Entity_NA under Americas: Revenue_Share = Entity_NA Revenue / Americas Revenue × 100
- If Americas Revenue = 0 or #MISSING, sets share to #MISSING

---

### Example 2: Top-Down Target Disaggregation

```essbase
FIX("FY25", "Forecast", @CHILDREN("Americas"))
    IF(@PARENTVAL("Entity") > 0)
        Revenue = "Target_Revenue" -> @PARENT(@CURRMBR("Entity")) *
            (Revenue -> "FY24" / @PARENTVAL("Entity") -> "FY24");
    ENDIF
ENDFIX
```

---

### Example 3: Performance Index

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vChildCount = @NUMCHILDREN(@PARENT(@CURRMBR("Entity")));
    IF(vChildCount > 0 AND @PARENTVAL("Entity") > 0)
        "Performance_Index" = Revenue / (@PARENTVAL("Entity") / vChildCount);
    ENDIF
ENDFIX
```
Index > 1 means above average; < 1 means below average.

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Stale parent values | If AGG hasn't run, parent values are outdated | Run `AGG("Entity")` before using @PARENTVAL |
| @PARENTVAL vs. @PARENT | @PARENTVAL returns the numeric VALUE; @PARENT returns the MEMBER | Use @PARENTVAL for calculations; @PARENT for references |
| Division by zero | @PARENTVAL may be 0 or #MISSING | Always check: `IF(@PARENTVAL("Entity") > 0)` |
| Using on root member | @PARENTVAL at root returns its own value — share = 100% always | Check level before calculating share |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PARENT`](../04_Member_Navigation/@PARENT.md) | Returns the parent MEMBER (not the value) |
| [`@SPARENTVAL`](./@SPARENTVAL.md) | Parent value for shared members |
| [`@ANCESTVAL`](./@ANCESTVAL.md) | Value at a specific ancestor level |
| [`@SANCESTVAL`](./@SANCESTVAL.md) | Shared ancestor value |
| [`@CHILDREN`](../04_Member_Navigation/@CHILDREN.md) | Children of a member |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @PARENTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/parentval.html)
