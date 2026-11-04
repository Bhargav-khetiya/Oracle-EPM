# @ISUDA

## Overview

`@ISUDA` is a **logical evaluation function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated has a specific User-Defined Attribute (UDA) attached to it in the outline. It returns a Boolean value (`TRUE` or `FALSE`).

### Why Does This Function Exist—

UDAs are custom tags assigned to members in the outline (e.g., tagging certain entities as "Active", "Closed", or "JointVenture"). While you can use `@UDA` to grab a list of all members with that tag for a `FIX` statement, you often need to evaluate the tag *dynamically* during a calculation:
- "If this entity is a JointVenture, apply a 50% multiplier."
- "If this account is tagged as Non-Operating, exclude it from the EBITDA subtotal."

`@ISUDA` allows you to build conditional logic based on these metadata tags.

### When to Use It

- Inside `IF` statements to route logic based on member metadata rather than member names.
- To build dynamic, maintenance-free calculations (when a new entity is added, simply tag it in the outline; the calc script doesn't need to change).
- When a single hierarchy is insufficient to group members, and cross-cutting tags are used instead.

---

## Category

**Logical / Boolean / Metadata Evaluation**

---

## Syntax

```essbase
@ISUDA(dimName, "UDA_String")
```

### Formal Syntax

```
@ISUDA(dimensionName, "udaName")
```

Where:
- `dimensionName` — The dimension containing the member currently being evaluated (e.g., `"Entity"`).
- `"udaName"` — The exact string name of the User-Defined Attribute (e.g., `"Active"`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension | ✅ Yes | The name of the dimension to check (must be provided as a string or member reference). |
| `udaString` | String | ✅ Yes | The name of the UDA. **Must be enclosed in quotes**. It is generally case-insensitive in modern EPM Cloud, but matching exact case is best practice. |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member in `dimName` has the UDA | `TRUE` (1) |
| Current member does not have the UDA | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current intersection being calculated.
2. **Dimension Targeting**: It isolates the member belonging to the `dimName` specified.
3. **Metadata Lookup**: It checks the outline definition of that member to see if the `udaString` is in its UDA list.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Conditional

```essbase
IF(@ISUDA("Entity", "JointVenture"))
    /* Execute JV logic */
ENDIF
```

### Variant 2: Combining UDA Checks

```essbase
IF(@ISUDA("Entity", "Active") AND NOT @ISUDA("Entity", "Elimination"))
    /* Only calculate active, non-elimination entities */
ENDIF
```

---

## Practical Examples

### Example 1: Differentiated Allocation Multipliers

**Scenario**: You are calculating corporate overhead allocation. Fully owned entities absorb 100% of their share. Joint Ventures only absorb 50%.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    /* Assume a driver-based allocation has already placed the gross amount in "Gross_Alloc" */
    
    IF("Gross_Alloc" != #MISSING)
        IF(@ISUDA("Entity", "JointVenture"))
            "Net_Alloc" = "Gross_Alloc" * 0.50;
        ELSE
            "Net_Alloc" = "Gross_Alloc" * 1.00;
        ENDIF
    ENDIF
ENDFIX
```

---

### Example 2: Global FX Overrides

**Scenario**: Certain accounts (like Historical Equity) should not be translated using standard Average/Ending rates, but use historical overrides.

```essbase
FIX("FY25", "Actual", @LEVEL0("Account"))
    /* Check if the account has the "Historical_Rate" UDA */
    IF(@ISUDA("Account", "Historical_Rate"))
        /* Use a specific override rate stored in a different cube/intersection */
        "USD" = "Local_Currency" * "Hist_FX_Rate";
    ELSE
        /* Standard translation */
        "USD" = "Local_Currency" * "Avg_FX_Rate";
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing the dimension name | `@ISUDA("JointVenture")` is invalid syntax | You must explicitly declare which dimension you are checking: `@ISUDA("Entity", "JointVenture")` |
| Missing quotes | `@ISUDA("Entity", JointVenture)` | The UDA name must be enclosed in quotes |
| Confusing `@UDA` and `@ISUDA` | `@UDA` returns a *list of members* (used in `FIX`). `@ISUDA` returns a *Boolean* (used in `IF`) | Use `FIX(@UDA(...))` for block isolation, use `IF(@ISUDA(...))` for cell logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@UDA`](./@UDA.md) | Returns the list of members possessing a UDA (used in FIX blocks) |
| [`@ISMBR`](./@ISMBR.md) | Checks if a member matches a specific name rather than a UDA tag |
| [`@ISATTR`](./@ISATTR.md) | Similar function, but checks formally defined Attributes instead of UDAs |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISUDA](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isuda.html)
