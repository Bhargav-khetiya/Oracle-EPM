# @NEXTSIBLING

## Overview

`@NEXTSIBLING` is a **member navigation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the *member name* of the immediate next sibling of a specified member. 

### Why Does This Function Exist?

While `@NEXT` is used to get the *data value* of the next period, `@NEXTSIBLING` is used to get the *member reference itself*. This is critical when you need to dynamically build target destinations for cross-dimensional pushes or when executing conditional logic based on outline structure.
- Find the next cost center in line.
- Check if the current month is the last sibling (if `@NEXTSIBLING` is empty).
- Dynamically target the next phase of a project.

### When to Use It

- When you need a Member Reference, not a numeric data value.
- To execute IF logic based on outline position.
- To push data into the subsequent sibling member.

---

## Category

**Member Selection / Navigation**

---

## Syntax

```essbase
@NEXTSIBLING(mbrName)
```

### Formal Syntax

```
@NEXTSIBLING(memberReference)
```

Where:
- `memberReference` — The member whose next sibling you want to find. Can be explicit (`"Jan"`) or contextual (`@CURRMBR("Period")`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member | ✅ Yes | The starting member. The function will look at this member's parent, look at its children, and return the one immediately following this one. |

---

## Return Value

**Return Type**: Member Reference

Returns the member that immediately follows `mbrName` under the same parent.
- If `mbrName` is the last sibling under its parent (e.g., "Dec" under "YearTotal"), `@NEXTSIBLING` returns an empty string/null reference, which evaluates to false in an `IF` check.

---

## How It Works (Behind the Scenes)

1. **Hierarchy Check**: Essbase locates the specified member in the outline.
2. **Sibling Navigation**: It moves exactly one slot down within the same generation under the same parent.
3. **Reference Return**: It returns the actual member name, allowing it to be used on the left side of an equation (as a target) or inside other member functions.

---

## Syntax Variants & Scenarios

### Variant 1: Push Data to Next Sibling

```essbase
/* If calculating on Jan, pushes data into Feb */
"Account_A" -> @NEXTSIBLING(@CURRMBR("Period")) = "Account_A" + 100;
```

### Variant 2: Check for End of List

```essbase
IF(@NEXTSIBLING(@CURRMBR("Period")) == "")
    /* We are on the last period (e.g., Dec) */
ENDIF
```

---

## Practical Examples

### Example 1: Rolling Phased Project Budgets

**Scenario**: You have project phases (Phase_1, Phase_2, Phase_3). If Phase 1 is completed under budget, you want to automatically roll the remaining budget into the next phase.

```essbase
FIX("FY25", "Working", @CHILDREN("Project_Phases"))
    /* Check if the current phase is complete and under budget */
    IF("Status" == 1 AND "Variance" > 0)
        /* Ensure there IS a next phase to roll into */
        IF(@ISMBR(@NEXTSIBLING(@CURRMBR("Project_Phase"))))
            /* Push the variance into the next sibling's budget */
            "Budget" -> @NEXTSIBLING(@CURRMBR("Project_Phase")) = 
                "Budget" -> @NEXTSIBLING(@CURRMBR("Project_Phase")) + "Variance";
                
            /* Zero out the variance in current phase */
            "Variance" = 0;
        ENDIF
    ENDIF
ENDFIX
```

---

### Example 2: Determining Year-End

**Scenario**: You need to execute a special tax calculation only on the last month of the year. Instead of hardcoding `"Dec"`, you check if the current month has a next sibling.

```essbase
FIX("FY25", "Working", @LEVEL0("Period"))
    /* If @NEXTSIBLING is null/invalid, @ISMBR returns false. 
       We invert it with NOT to mean: "If this is the LAST sibling" */
    IF(NOT @ISMBR(@NEXTSIBLING(@CURRMBR("Period"))))
        "Annual_Tax_Provision" = "YTD_Income" * 0.25;
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for Data Values | `"Value" = @NEXTSIBLING("Jan")` | This assigns the member "Feb" to a numeric value, causing an error. Use `@NEXT("Value")` if you want the data number |
| Cross-Parent Navigation | If evaluating "Mar" (Child of Q1), `@NEXTSIBLING` is null. It does *not* jump to "Apr" (Child of Q2) | Siblings must share the same immediate parent. Use `@SHIFT` or `@NEXT` if you need to cross parent boundaries |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@PREVSIBLING`](./@PREVSIBLING.md) | The exact opposite (returns the preceding member) |
| [`@NEXT`](./@NEXT.md) | Returns the numeric data value, not the member reference |
| [`@SIBLINGS`](./@SIBLINGS.md) | Returns all siblings, not just the next one |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @NEXTSIBLING](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/nextsibling.html)
