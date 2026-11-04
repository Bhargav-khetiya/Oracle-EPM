# @ATTRIBUTEBVAL

## Overview

`@ATTRIBUTEBVAL` is a **data retrieval function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It retrieves the Boolean value (`True` or `False`) assigned to a Boolean attribute for a specified base member. 

### Why Does This Function Exist—

Attributes in Essbase can be configured as **Boolean** types, which inherently hold only a `True` or `False` state. (e.g., "Is_Flagship", "Is_Tax_Exempt").
While you can use `@ISATTRIBUTE("True")` to check conditions, sometimes you need to retrieve the actual Boolean state dynamically and assign it to a variable or use it to drive a mathematical multiplier (where True = 1, False = 0).
`@ATTRIBUTEBVAL` pulls the metadata boolean flag into the calculation engine as a usable logical state.

### When to Use It

- When evaluating an `IF` condition directly based on a Boolean attribute dimension.
- To use a boolean state as a mathematical multiplier (since `True` evaluates to `1` and `False` to `0` in Essbase math).
- When writing generic, highly dynamic logic that reads metadata flags to turn calculations on or off.

---

## Category

**Data Retrieval / Metadata Conversion / Boolean**

---

## Syntax

```essbase
@ATTRIBUTEBVAL(attrDimName)
```

### Formal Syntax

```
@ATTRIBUTEBVAL(attributeDimensionName)
```

Where:
- `attributeDimensionName` — The exact name of the Boolean attribute dimension you want to extract the value from.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `attrDimName` | Dimension | ✅ Yes | The name of the Boolean Attribute Dimension (e.g., `"Is_Tax_Exempt"`). |

---

## Return Value

**Return Type**: Boolean / Numeric (1 or 0)

Returns `1` if the attribute is True, and `0` if the attribute is False or not assigned.

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current base member being calculated (e.g., "Store_NY").
2. **Metadata Lookup**: It checks the outline for the Boolean `attrDimName` assigned to "Store_NY".
3. **Data Casting**: It translates the metadata state (`True` or `False`) into an engine-readable boolean/numeric state (`1` or `0`) and returns it.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Boolean Check

```essbase
IF(@ATTRIBUTEBVAL("Is_Tax_Exempt"))
    /* Math for tax exempt entities */
ENDIF
```

### Variant 2: Mathematical Multiplier

```essbase
/* If Is_Taxable is True (1), Tax = Revenue * 0.20
   If Is_Taxable is False (0), Tax = 0 */
"Tax_Expense" = ("Revenue" * 0.20) * @ATTRIBUTEBVAL("Is_Taxable");
```

---

## Practical Examples

### Example 1: Dynamic Tax Exclusion

**Scenario**: You have a global tax calculation, but certain entities are legally tax-exempt. This is flagged in the outline using a Boolean attribute dimension called "Tax_Exempt".

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* We only want to calculate tax for entities where Tax_Exempt is FALSE.
       We use NOT to invert the boolean logic. */
       
    IF(NOT @ATTRIBUTEBVAL("Tax_Exempt"))
        "Tax_Provision" = "PreTax_Income" * "Corp_Tax_Rate";
    ELSE
        /* Ensure no tax is recorded for exempt entities */
        "Tax_Provision" = 0;
    ENDIF
    
ENDFIX
```

---

### Example 2: Flagship Store Multiplier

**Scenario**: You are calculating a baseline marketing budget. Normal stores get $10,000. Flagship stores (defined by a boolean attribute) get double.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    VAR vBaseMarketing = 10000;
    
    /* @ATTRIBUTEBVAL returns 1 for Flagships, 0 for normal.
       (1 * 1) + 1 = 2 (Double budget)
       (0 * 1) + 1 = 1 (Normal budget) */
       
    "Marketing_Budget" = vBaseMarketing * ((@ATTRIBUTEBVAL("Is_Flagship") * 1) + 1);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on Text/Numeric Attributes | `@ATTRIBUTEBVAL("Size")` will fail if "Size" is numeric or text | Only use `@ATTRIBUTEBVAL` on strictly Boolean attribute dimensions |
| Using for `FIX` statements | `FIX(@ATTRIBUTEBVAL("Is_Flagship"))` is invalid | Use `FIX(@ATTRIBUTE("True"))` assuming the attribute values are literally "True"/"False" |
| Not handling nulls | If an entity has no attribute assigned at all, it usually evaluates to `False` (0). Ensure this default behavior aligns with your business logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ATTRIBUTEVAL`](./@ATTRIBUTEVAL.md) | The equivalent function for extracting Numeric attributes |
| [`@ATTRIBUTESVAL`](./@ATTRIBUTESVAL.md) | The equivalent function for extracting Text/String attributes |
| [`@ISATTRIBUTE`](../09_Boolean_Conditional/@ISATTRIBUTE.md) | Checks if an attribute matches explicitly, rather than pulling its native boolean state |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ATTRIBUTEBVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/attributebval.html)
