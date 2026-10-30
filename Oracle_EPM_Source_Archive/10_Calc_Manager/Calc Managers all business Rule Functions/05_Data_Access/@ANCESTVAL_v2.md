# @ANCESTVAL

## Overview

`@ANCESTVAL` is a **data retrieval function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It returns the numeric data value of an ancestor of the specified member at a given generation or level. 

### Why Does This Function Exist?

While `@ANCEST` returns the *member reference* (which you must then use in a cross-dimensional operator like `"Revenue" -> @ANCEST(...)`), `@ANCESTVAL` directly fetches the numeric value from the current data intersection, shifted up to the specified ancestor.
It simplifies syntax when you just need the number (e.g., to use as a denominator) and don't need to dynamically assign data to that parent.

### When to Use It

- To pull a regional or global total directly into a calculation for percentage or share analysis.
- To use a parent-level assumption (like a corporate tax rate stored at the "Total Entity" level) while calculating base members.
- Whenever you need the value of an ancestor without the verbosity of a cross-dimensional operator (`->`).

---

## Category

**Data Retrieval / Hierarchy**

---

## Syntax

```essbase
@ANCESTVAL(dimName, genLevNum | genLevName [, mbrName])
```

### Formal Syntax

```
@ANCESTVAL(dimensionName, generationOrLevelParameter, [optionalMemberTarget])
```

Where:
- `dimensionName` — The dimension whose hierarchy you are navigating (e.g., `"Entity"`).
- `generationOrLevelParameter` — A number or name specifying how far up the tree to go (e.g., `2` or `"Region"`).
- `optionalMemberTarget` — (Optional) The specific account or measure to pull the value from. Defaults to the current member being calculated if omitted.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension | ✅ Yes | The dimension to navigate up. |
| `genLevNum` | Integer/String| ✅ Yes | The generation (top-down) or level (bottom-up) of the ancestor. |
| `mbrName` | Member | ❌ No | The specific measure to retrieve. If you are calculating `"ASP"`, but want the ancestor's `"Revenue"`, you specify `"Revenue"` here. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the data value residing at the ancestor's intersection. If the ancestor has no data, returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Context Shift**: Essbase takes the exact block/cell it is currently evaluating.
2. **Ascension**: It replaces the current member of `dimName` with its ancestor at `genLevNum`.
3. **Data Fetch**: It retrieves the number sitting at that new coordinate and returns it to the formula.

---

## Syntax Variants & Scenarios

### Variant 1: Implicit Measure

```essbase
/* Assuming we are calculating "Revenue" for NY */
"Share" = "Revenue" / @ANCESTVAL("Entity", 2);
/* Fetches the Revenue value of NY's Gen 2 ancestor (e.g., North_America) */
```

### Variant 2: Explicit Measure

```essbase
/* We are calculating "Bonus", but need the parent's "Net_Income" */
"Bonus" = @ANCESTVAL("Entity", 2, "Net_Income") * 0.01;
```

---

## Practical Examples

### Example 1: Calculating "Share of Parent" (Percentage of Total)

**Scenario**: You want to calculate what percentage each product's sales represent of its immediate parent category's sales.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    /* Level 1 is the immediate parent of a Level 0 member */
    VAR vParentSales = @ANCESTVAL("Product", 1, "Sales");
    
    IF(vParentSales > 0)
        "Share_Of_Category_Pct" = "Sales" / vParentSales;
    ENDIF
ENDFIX
```

---

### Example 2: Pulling Global Assumptions

**Scenario**: A global "Days Sales Outstanding (DSO)" assumption is input at "Total Geography" (Gen 2). You need to pull this value down to every individual country (Level 0) to calculate Accounts Receivable.

```essbase
FIX("FY25", "Working", @LEVEL0("Geography"))
    /* Fetch the DSO assumption from Gen 2 of the Geography dimension */
    VAR vGlobalDSO = @ANCESTVAL("Geography", 2, "DSO_Assumption");
    
    /* Calculate AR based on the global driver */
    "Accounts_Receivable" = ("Revenue" / 365) * vGlobalDSO;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not aggregating first | If you try to pull `"Revenue"` from a parent, but the parent hasn't been aggregated yet, `@ANCESTVAL` will return `#MISSING` | Ensure you run an `AGG` or `CALC DIM` on the dimension *before* using `@ANCESTVAL` if the parent value is dynamic |
| Using for Target Assignment | `@ANCESTVAL` returns a *number*, not a member. You cannot write `@ANCESTVAL(...) = 100` | Use `@ANCEST(...)` with a cross-dimensional operator if you need to push data *to* a parent |
| Gen vs Level Confusion | Gen counts from the Top (1). Level counts from the Bottom (0). Ensure you know your outline structure | Use generation targeting (e.g., Gen 3) if your hierarchy depth varies (unbalanced) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ANCEST`](../04_Member_Navigation/@ANCEST.md) | Returns the member reference, not the numeric data value |
| [`@PARENTVAL`](./@PARENTVAL.md) | Specifically returns the value of the immediate Level 1 parent |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ANCESTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ancestval.html)
