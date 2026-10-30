# @UDA

## Overview

`@UDA` is a **Boolean filtering function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that tests whether a member has a specific **User-Defined Attribute (UDA)** assigned to it, or returns a list of members that have that UDA. It is widely used for dynamic member selection and conditional logic based on metadata tags rather than outline hierarchy.

### Why Does This Function Exist?

Hierarchies organize data in one way (e.g., Geography: NA, EMEA, APAC), but business logic often requires cross-cutting groupings:
- Calculating taxes only for "Taxable" entities, regardless of region
- Applying inflation only to "Controllable" expenses
- Allocating costs only to "Active" cost centers
- Identifying "Intercompany" trading partners

UDAs allow you to tag members with these characteristics, and `@UDA` lets your calc scripts read those tags.

### When to Use It

- In `FIX` statements to dynamically scope calculations to tagged members
- In `IF` statements to apply conditional logic based on a member's tag
- To build dynamic member lists without hardcoding member names
- When business logic crosses standard hierarchy boundaries
- To make scripts maintenance-free (update the UDA in the dimension editor, and the script automatically adapts)

---

## Category

**Member Selection / Boolean / Metadata**

---

## Syntax

```essbase
@UDA(dimName, UDA_String)
```

### Formal Syntax

```
@UDA(dimensionName, UDA_Name)
```

Where:
- `dimensionName` — The dimension to search for the UDA.
- `UDA_Name` — The exact name of the User-Defined Attribute as a string (in quotes).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension name | ✅ Yes | The dimension that contains the members with the UDA (e.g., `"Entity"`, `"Account"`). |
| `UDA_String` | String | ✅ Yes | The name of the UDA to look for, enclosed in double quotes (e.g., `"Taxable"`, `"Active"`). UDAs are case-insensitive in Essbase, but matching exact case is best practice. |

---

## Return Value

| Context | Returns |
|---------|---------|
| Used in `FIX` | A member set containing all members in the dimension with the specified UDA |
| Used in `IF` | Boolean: `TRUE` if the current member has the UDA, `FALSE` if it does not |

**Return Type**: Member Set (in FIX) or Boolean (in IF)

---

## How It Works (Behind the Scenes)

1. **Dual Behavior**: `@UDA` acts differently depending on where it's used. In a `FIX`, it acts as a member selector (returning a list). In an `IF`, it acts as a Boolean test (returning True/False for the current cell).
2. **Dynamic Resolution**: The members associated with a UDA are evaluated when the calc script compiles/runs. If metadata changes, the script automatically picks up the new members without code changes.
3. **Performance**: `@UDA` in a `FIX` is extremely fast and efficient because it resolves to a static member list before the calculation blocks are processed. In an `IF`, it evaluates per cell, which is slower.
4. **Hierarchy Independence**: UDAs flatly tag members, ignoring where they live in the outline. This is perfect for alternate rollups or cross-hierarchy logic.

---

## Syntax Variants & Scenarios

### Variant 1: In FIX (Member Selection)

```essbase
FIX(@UDA("Entity", "Taxable"))
    /* Calculates only for Taxable entities */
ENDFIX
```

### Variant 2: In IF (Boolean Test)

```essbase
IF(@UDA("Account", "Controllable"))
    /* Applies logic only if the current account is Controllable */
ENDIF
```

### Variant 3: Multiple UDAs in FIX

```essbase
FIX(@UDA("Entity", "Active"), @UDA("Account", "Expense"))
    /* Intersects Active entities with Expense accounts */
ENDFIX
```

### Variant 4: With Other Functions

```essbase
FIX(@INTERSECT(@UDA("Entity", "Store"), @DESCENDANTS("North_America")))
    /* Only NA entities that are tagged as Stores */
ENDFIX
```

---

## Practical Examples

### Example 1: Selective Tax Calculation

**Scenario**: Calculate tax expense only for entities tagged as "Taxable".

```essbase
/* Best Practice: Use UDA in FIX for performance */
FIX("FY25", "Working", @UDA("Entity", "Taxable"))
    "Tax_Expense" = "PreTax_Income" * "Tax_Rate";
ENDFIX

/* Alternative: Using UDA in IF (slower, but useful if part of complex logic) */
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(@UDA("Entity", "Taxable"))
        "Tax_Expense" = "PreTax_Income" * "Tax_Rate";
    ELSE
        "Tax_Expense" = 0;
    ENDIF
ENDFIX
```

---

### Example 2: Expense Inflation Driver

**Scenario**: Apply a 3% inflation increase only to "Controllable" expenses.

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    FIX(@UDA("Account", "Controllable"))
        "Forecast_Value" = "Actual" -> "FY24" * 1.03;
    ENDFIX
    
    /* Non-controllable remain flat */
    /* ... logic for non-controllable ... */
ENDFIX
```

---

### Example 3: Intercompany Eliminations

**Scenario**: Clear balances for accounts tagged for intercompany elimination.

```essbase
FIX("Elimination_Entity", "Working")
    FIX(@UDA("Account", "IC_Eliminate"))
        CLEARDATA @CURRMBR("Account");
    ENDFIX
ENDFIX
```

---

### Example 4: Currency Conversion Tagging

**Scenario**: Only convert entities tagged with "Local_Currency".

```essbase
FIX("FY25", "Working", @UDA("Entity", "Local_Currency"))
    "Revenue_USD" = "Revenue_Local" * "FX_Rate";
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using IF instead of FIX | `IF(@UDA(...))` checks the UDA for every cell, which is slower | Put `@UDA` in the `FIX` statement whenever possible to filter blocks at the start |
| Missing dimension parameter | `@UDA("Taxable")` is invalid syntax | Always include the dimension: `@UDA("Entity", "Taxable")` |
| Typo in UDA name | If the UDA string doesn't match metadata exactly, it returns an empty set or False | Verify UDA spelling in the dimension editor |
| UDA on sparse vs dense | Using UDA on a dense dimension in FIX still loads the whole block | Understand block structure; UDAs on sparse dimensions filter blocks efficiently |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@WITHATTR`](./@WITHATTR.md) | Selects members based on Attributes (different from UDAs) |
| [`@ISMBR`](./@ISMBR.md) | Tests if current member matches a specific name/list |
| [`@ISDESC`](./@ISDESC.md) | Tests if current member is a descendant of another |
| [`FIX`](../01_Flow_Control/FIX.md) | Where @UDA is most commonly used for scoping |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @UDA](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/uda.html)
