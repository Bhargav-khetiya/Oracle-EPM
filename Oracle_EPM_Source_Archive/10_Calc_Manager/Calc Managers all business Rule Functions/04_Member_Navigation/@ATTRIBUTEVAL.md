# @ATTRIBUTEVAL

## Overview

`@ATTRIBUTEVAL` is a **data retrieval function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It retrieves the actual numeric value assigned to a numeric attribute for a specified base member. 

### Why Does This Function Exist?

Attributes in Essbase are not just text tags; they can be actual numbers (Numeric Attributes). For example, a store might have a numeric attribute called "Square_Footage" with a value of `50000`, or a product might have "Ounces" set to `12.5`.
Instead of storing these metrics as data intersections in the cube (which increases database size and calculation time), you store them as metadata.
`@ATTRIBUTEVAL` is the bridge that takes that metadata number and injects it into your mathematical equations as a data value.

### When to Use It

- To use physical metrics (size, weight, capacity) in calculations without storing them as Accounts or measures.
- When calculating driver-based models (e.g., Rent Expense = Square Footage * Cost Per SqFt).
- To dynamically pull thresholds or rates that are tied strictly to member metadata rather than time-varying data.

---

## Category

**Data Retrieval / Metadata Conversion**

---

## Syntax

```essbase
@ATTRIBUTEVAL(attrDimName)
```

### Formal Syntax

```
@ATTRIBUTEVAL(attributeDimensionName)
```

Where:
- `attributeDimensionName` — The exact name of the numeric attribute dimension you want to extract the value from.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `attrDimName` | Dimension | ✅ Yes | The name of the Numeric Attribute Dimension (e.g., `"Square_Footage"`). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the actual number stored in the attribute definition for the member currently being calculated.
If the current member has no attribute assigned from that dimension, it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current base member being calculated (e.g., "Store_NY").
2. **Metadata Lookup**: It checks the outline for the `attrDimName` assigned to "Store_NY".
3. **Data Casting**: It reads the string definition of the attribute (e.g., `"50000"`), converts it into a pure mathematical number (`50000.00`), and returns it to the formula.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Retrieval in Math

```essbase
"Capacity_Pct" = "Units_Produced" / @ATTRIBUTEVAL("Max_Capacity");
```

---

## Practical Examples

### Example 1: Rent Expense by Square Footage

**Scenario**: You want to calculate the baseline Rent Expense for every retail store. Rent is simply a corporate assumption ("Rent_Per_SqFt") multiplied by the physical size of the store. Size is an attribute, not an account.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Ensure we only calculate stores that actually have a square footage attribute */
    IF(@ATTRIBUTEVAL("Square_Footage") != #MISSING)
        
        "Rent_Expense" = @ATTRIBUTEVAL("Square_Footage") * "Rent_Per_SqFt";
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Weight-Based Shipping Costs

**Scenario**: Shipping cost is calculated based on the weight of the product. Weight is a numeric attribute attached to the Product dimension.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* Total Weight Shipped = Number of Units * Weight of one unit (from Attribute) */
    VAR vTotalWeight = "Units_Sold" * @ATTRIBUTEVAL("Weight_Lbs");
    
    /* Calculate Cost based on the total weight */
    "Shipping_Expense" = vTotalWeight * "Freight_Rate_Per_Lb";
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on Text/Boolean Attributes | `@ATTRIBUTEVAL("Color")` will fail or return `#MISSING` if "Color" is a text attribute (like "Red") | Only use `@ATTRIBUTEVAL` on Numeric attribute dimensions. Use `@ATTRIBUTESVAL` for text strings, or `@ATTRIBUTEBVAL` for Booleans |
| Missing Dimension | `@ATTRIBUTEVAL(50000)` is invalid | You must provide the name of the attribute dimension, not the value itself |
| Calculating on Parents | Attributes only exist at Level 0. `@ATTRIBUTEVAL` on a parent entity will return `#MISSING` | Restrict your `FIX` or `IF` logic to base-level members before using the function |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ATTRIBUTESVAL`](./@ATTRIBUTESVAL.md) | The equivalent function for extracting Text/String attributes |
| [`@ATTRIBUTEBVAL`](./@ATTRIBUTEBVAL.md) | The equivalent function for extracting Boolean (True/False) attributes |
| [`@ISMBRWITHATTR`](./@ISMBRWITHATTR.md) | Checks if the attribute value meets a mathematical condition (`> 50000`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ATTRIBUTEVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/attributeval.html)
