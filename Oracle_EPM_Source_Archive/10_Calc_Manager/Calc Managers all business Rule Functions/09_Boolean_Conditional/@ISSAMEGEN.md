# @ISSAMEGEN

## Overview

`@ISSAMEGEN` is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated belongs to the exact same top-down Generation as a specified reference member. It returns `TRUE` or `FALSE`.

### Why Does This Function Exist—

When applying logic across unbalanced hierarchies, you often want to target members that sit at the same conceptual tier (e.g., all "Regions" or all "Countries").
While you can use `@ISGEN("Entity", 3)`, that requires hardcoding the generation number `3`. If the outline changes and "Countries" are pushed down to Generation 4, you have to rewrite the script.
`@ISSAMEGEN` allows you to pick a "benchmark" member (e.g., `"USA"`) and say: *"Apply this logic to any member that is at the same tier as USA, whatever that tier happens to be."*

### When to Use It

- Inside `IF` statements to route logic horizontally across an outline tier.
- To avoid hardcoding integer generation numbers in your calculation scripts.
- When building dynamic templates that need to adjust to different outline structures automatically.

---

## Category

**Logical / Boolean / Hierarchy Context**

---

## Syntax

```essbase
@ISSAMEGEN(mbrName)
```

### Formal Syntax

```
@ISSAMEGEN(referenceMemberExpression)
```

Where:
- `referenceMemberExpression` — The specific member whose generation you want to use as the benchmark.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The benchmark member. The function asks: "Is the current member in the same generation as `mbrName`— |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member's Generation == `mbrName`'s Generation | `TRUE` (1) |
| Current member's Generation != `mbrName`'s Generation | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current cell being evaluated.
2. **Benchmark Resolution**: It finds `mbrName` in the outline and calculates its Generation number (e.g., USA is Gen 3).
3. **Current Resolution**: It calculates the Generation number of the current member (e.g., France is Gen 3).
4. **Comparison**: If the two integers match, it returns `TRUE`.

---

## Syntax Variants & Scenarios

### Variant 1: Routing Logic by Peer Group Tier

```essbase
IF(@ISSAMEGEN("USA"))
    /* Executes for USA, France, Japan, etc. (All Gen 3 members) */
ENDIF
```

---

## Practical Examples

### Example 1: Dynamic Tier-Based Revenue Allocation

**Scenario**: You have a global top-down adjustment that needs to be pushed exactly to the "Country" tier. You don't want to hardcode the generation number in case the hierarchy adds a "Super-Region" tier later.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Global"))
    
    /* USA is our benchmark for a "Country". 
       Apply the logic to any entity at the same generation as USA. */
    IF(@ISSAMEGEN("USA"))
        
        /* Fetch the global adjustment (stored at the root) */
        VAR vGlobalAdj = "Adjustment" -> "Total Global";
        
        /* Allocate based on revenue share */
        "Adjustment" = vGlobalAdj * ("Revenue" / "Revenue" -> "Total Global");
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Validating Data Entry Levels

**Scenario**: You want to ensure users only input data at the "Department" tier. You use "Dept_Marketing" as the benchmark.

```essbase
FIX("FY25", "Actual", @DESCENDANTS("Total Company"))
    
    IF("Input_Data" != #MISSING)
        IF(NOT @ISSAMEGEN("Dept_Marketing"))
            "Error_Flag" = 1;
        ENDIF
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for `FIX` statements | `FIX(@ISSAMEGEN("USA"))` is invalid syntax | Use `@GENMBRS("Entity", 3)` for `FIX` blocks. Use `@ISSAMEGEN` only in `IF` statements |
| Confusing `@ISSAMEGEN` with `@ISSIBLING` | `@ISSIBLING` requires members to share the *exact same parent*. `@ISSAMEGEN` only requires them to share the *same depth* from the top, even if they are in totally different branches | Use `@ISSAMEGEN` for global horizontal tiers, `@ISSIBLING` for immediate peer groups |
| Shared Members | The Generation of a shared member is based on its placement in the shared branch, not its primary branch | Be aware of which branch your script is evaluating |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISSAMELEV`](./@ISSAMELEV.md) | Checks if members share the same bottom-up Level |
| [`@ISGEN`](./@ISGEN.md) | Checks against a hardcoded integer or named generation rather than a benchmark member |
| [`@GEN`](./@GEN.md) | Returns the actual integer generation number |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISSAMEGEN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/issamegen.html)
