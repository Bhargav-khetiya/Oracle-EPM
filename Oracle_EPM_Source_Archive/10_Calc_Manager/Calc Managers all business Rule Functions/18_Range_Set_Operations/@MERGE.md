# @MERGE

## Overview

`@MERGE` is a **member set function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **combines (unions) two or more member sets** into a single member set, removing duplicates. It performs a set union operation — the resulting set contains all unique members from all input sets.

### Why Does This Function Exist?

In planning applications, you frequently need to combine members from different branches or categories:
- Merging members from different hierarchy branches into a single calculation scope
- Combining results of multiple member selection functions
- Building custom member sets that don't follow a single hierarchy path
- Creating complex FIX statements that target members from multiple areas

### When to Use It

- When you need to combine members from different member set functions
- In FIX statements to scope calculations across non-contiguous hierarchy branches
- When building custom member lists by merging multiple sources
- When you need the union of two or more sets without duplicates

---

## Category

**Member Set / Set Operations**

---

## Syntax

```essbase
@MERGE(setExpression1, setExpression2 [, setExpressionN...])
```

### Formal Syntax

```
@MERGE(memberSet1, memberSet2 [, memberSet3, ...])
```

Where each parameter is a member set function or member list.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `setExpression1` | Member set | ✅ Yes | First member set. Can be any function that returns a member set (e.g., `@CHILDREN`, `@DESCENDANTS`, `@LEVMBRS`). |
| `setExpression2` | Member set | ✅ Yes | Second member set to merge with the first. |
| `setExpressionN` | Member set | ❌ No | Additional member sets. No fixed limit. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Sets have unique members | Union of all members |
| Sets have overlapping members | Union with duplicates removed |
| Empty sets | Non-empty members from other sets |

**Return Type**: Member set (used in FIX, LOOP, or other set contexts)

---

## How It Works (Behind the Scenes)

1. **Set Union**: `@MERGE` performs a mathematical set union. Each input set is resolved, and all unique members are combined.

2. **Duplicate Removal**: If the same member appears in multiple input sets, it appears only once in the result.

3. **Order**: The resulting set typically follows outline order, regardless of input order.

4. **Same Dimension**: All member sets should contain members from the same dimension.

5. **Static Resolution**: The merged set is resolved at the start of calculation.

---

## Syntax Variants & Scenarios

### Variant 1: Merge Two Child Sets

```essbase
@MERGE(@CHILDREN("East_Region"), @CHILDREN("West_Region"))
```
Combines children of East and West regions.

### Variant 2: Merge Across Levels

```essbase
@MERGE(@LEVMBRS("Entity", 0), @LEVMBRS("Entity", 2))
```
Combines leaf members and gen-2 members.

### Variant 3: Merge with Explicit Members

```essbase
@MERGE(@CHILDREN("Q1"), @LIST("Jul", "Aug", "Sep"))
```
Combines Q1 months with specific Q3 months.

### Variant 4: Multiple Sets

```essbase
@MERGE(@CHILDREN("Revenue"), @CHILDREN("COGS"), @CHILDREN("OpEx"))
```
Merges children from three different account groups.

---

## Practical Examples

### Example 1: Cross-Branch Calculation

**Scenario**: Run a calculation for entities from both domestic and key international markets.

```essbase
FIX("FY24", "Actual", @MERGE(@CHILDREN("Domestic"), @LIST("UK", "Germany", "Japan")))
    "Growth_Rate" = (Revenue - Revenue -> "FY23") / @ABS(Revenue -> "FY23") * 100;
ENDFIX
```

---

### Example 2: Combined Account Processing

**Scenario**: Process both revenue and direct cost accounts together for margin calculation.

```essbase
FIX("FY24", @MERGE(@DESCENDANTS("Total_Revenue"), @DESCENDANTS("Total_COGS")))
    "Annual_Total" = @SUM(Jan:Dec);
ENDFIX
```

---

### Example 3: Selective Period Aggregation

**Scenario**: Calculate totals for only Q1 and Q3 (skip Q2 and Q4).

```essbase
FIX("FY24", "Actual", @MERGE(@CHILDREN("Q1"), @CHILDREN("Q3")))
    "H1_H2_Selected" = Revenue;
ENDFIX
```

---

### Example 4: Multi-Level Entity Selection

**Scenario**: Process both leaf entities and regional summaries.

```essbase
FIX("FY24", @MERGE(@LEVMBRS("Entity", 0), @LIST("North_America", "EMEA", "APAC")))
    "Report_Include" = 1;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Cross-dimension merge | Merging sets from different dimensions causes errors | Ensure all sets contain members from the same dimension |
| Expecting intersection | `@MERGE` is **union** (OR), not **intersection** (AND) | Use `@INTERSECT` for set intersection |
| Large merged sets | Merging huge sets can impact performance | Keep merged sets as small as practical |
| Using in arithmetic | Returns a member SET, not a value | Use in FIX, LOOP, or set contexts only |
| Duplicate concern | Duplicates are automatically removed — no error | This is expected behavior |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@INTERSECT`](./@INTERSECT.md) | Set **intersection** — members in both sets |
| [`@REMOVE`](./@REMOVE.md) | Set **difference** — removes members of one set from another |
| [`@LIST`](./@LIST.md) | Creates a set from explicit member names |
| [`@CHILDREN`](./@CHILDREN.md) | Returns children — common input to `@MERGE` |
| [`@DESCENDANTS`](./@DESCENDANTS.md) | Returns descendants — common input to `@MERGE` |
| [`@EXPAND`](./@EXPAND.md) | Expands a member set — related set operation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MERGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/merge.html)
- [Oracle Essbase Technical Reference — @MERGE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
