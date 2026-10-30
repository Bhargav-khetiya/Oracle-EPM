# @ISSIBLING

## Overview

`@ISSIBLING` is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated is a sibling of a specified member. It returns `TRUE` or `FALSE`.

### Why Does This Function Exist?

Siblings are members that share the exact same immediate parent in the outline. 
- You may want to execute logic on a peer group (e.g., all states under "USA") without having to explicitly name the parent.
- You might have a specific reference member (e.g., a benchmark store) and want to calculate the variance for all of its peers without hardcoding the list of peers.

`@ISSIBLING` allows you to dynamically identify these peer relationships during a calculation.

### When to Use It

- Inside `IF` statements to isolate calculations to the peer group of a specific member.
- To execute differential logic: e.g., "If I am the benchmark member, do X; if I am a sibling of the benchmark, do Y."
- To avoid hardcoding a parent name when you only know a child's name.

---

## Category

**Logical / Boolean / Hierarchy Context**

---

## Syntax

```essbase
@ISSIBLING(mbrName)
```

### Formal Syntax

```
@ISSIBLING(memberExpression)
```

Where:
- `memberExpression` — The specific member you are testing the current context against.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The target member. The function asks: "Is the current member a sibling of this `mbrName`?" |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member shares the same immediate parent as `mbrName` | `TRUE` (1) |
| Current member is exactly `mbrName` | `TRUE` (1) *(See Note)* |
| Current member has a different parent | `FALSE` (0) |

*Note: In Essbase, a member is considered a sibling of itself for the purposes of sibling functions, unless explicitly documented otherwise in specific MDX contexts. `@ISSIBLING("Store_A")` evaluated on `"Store_A"` will typically return TRUE.*

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current cell being evaluated.
2. **Parent Resolution**: It finds the parent of the current member, and it finds the parent of the `mbrName` provided in the function.
3. **Comparison**: If the two parents match exactly, the function returns `TRUE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking against a specific member

```essbase
IF(@ISSIBLING("Q1"))
    /* Executes for Q1, Q2, Q3, Q4 (assuming they all share 'YearTotal') */
ENDIF
```

---

## Practical Examples

### Example 1: Peer Group Benchmarking

**Scenario**: You have a "Benchmark_Store" in a region. You want to calculate how far every other store in that exact region deviates from the benchmark's performance.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* We only want to run this math for the siblings of the benchmark store */
    IF(@ISSIBLING("Benchmark_Store"))
        
        /* If we are evaluating the benchmark itself, variance is 0 */
        IF(@ISMBR("Benchmark_Store"))
            "Variance_to_Benchmark" = 0;
        ELSE
            /* For the peers, calculate the difference */
            "Variance_to_Benchmark" = "Revenue" - "Revenue" -> "Benchmark_Store";
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Target Override based on a Primary Measure

**Scenario**: A user inputs a new target assumption into a specific primary measure ("Target_Base"). You want to apply an override logic to all of its sibling measures within the same account category without explicitly listing them.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Accounts"))
    IF(@ISSIBLING("Target_Base"))
        /* Execute logic for all peers in the Target group */
        "Adj_Value" = "Current_Value" * 1.05;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for `FIX` statements | `FIX(@ISSIBLING("Q1"))` is invalid syntax | Use `@SIBLINGS("Q1")` for `FIX` blocks. Use `@ISSIBLING` only in `IF` statements |
| Cross-parent expectations | If "Store_NY" is under "North_America" and "Store_London" is under "EMEA", they are NOT siblings | `@ISSIBLING` strictly checks for the *exact same immediate parent* |
| Self-exclusion | Assuming `@ISSIBLING("A")` evaluates to FALSE when the current member is `"A"` | Use `IF(@ISSIBLING("A") AND NOT @ISMBR("A"))` if you need to exclude the target member itself |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SIBLINGS`](./@SIBLINGS.md) | Returns the *list* of siblings (used in FIX blocks) |
| [`@ISMBR`](./@ISMBR.md) | Checks if a member is exactly the specified member |
| [`@ISDESC`](./@ISDESC.md) | Checks if a member is a descendant (child, grandchild) of the specified member |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISSIBLING](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/issibling.html)
