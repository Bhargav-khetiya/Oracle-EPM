# @WITHATTR

## Overview

`@WITHATTR` is a **member selection function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns all members in a base dimension that are associated with a specific **Attribute**. It allows you to dynamically select members based on their attribute values, operators, or a combination of attributes.

### Why Does This Function Exist?

Essbase supports Attribute Dimensions, which are dynamically linked to base dimensions (e.g., a "Store Size" attribute tied to the "Entity" dimension). You often need to calculate based on these attributes:
- Calculate different marketing expenses based on "Store Size" (e.g., "Large", "Small")
- Apply specific pricing logic to products with a "Color" attribute of "Red"
- Select all customers with "Revenue Band" > 50M
- Filter members without hardcoding them in scripts

### When to Use It

- In `FIX` statements to scope calculations to members matching an attribute criteria
- When business logic depends on dynamic groupings managed outside the main hierarchy
- To apply varying rates, assumptions, or drivers based on attribute values
- To filter members based on numeric attribute comparisons (e.g., > 10)

---

## Category

**Member Selection / Attributes**

---

## Syntax

```essbase
@WITHATTR(attributeMember [, operator, value])
```

### Formal Syntax

```
@WITHATTR(attrMbrName [, "operator", valueStringOrNumber])
```

Where:
- `attrMbrName` — The name of the attribute member to search for (e.g., `"Large"`, `"Red"`).
- `operator` — (Optional) Comparison operator enclosed in quotes: `"=="`, `"!="`, `">"`, `"<"`, `">="`, `"<=`". Default is `"=="`.
- `value` — (Optional) The value to compare against. Used primarily with numeric attributes, boolean attributes, or date attributes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `attributeMember` | Member name | ✅ Yes | The attribute member name, attribute dimension name, or attribute value. |
| `operator` | String | ❌ No | Comparison operator in quotes. Valid values: `"=="`, `"!="`, `">"`, `"<"`, `">="`, `"<=`". If omitted, implies equality `"=="` with the `attributeMember`. |
| `value` | String/Numeric | ❌ No | The value to compare the attribute against. Required if an operator other than `"=="` is used. |

---

## Return Value

**Return Type**: Member Set (a list of members from the base dimension that meet the attribute criteria).

---

## How It Works (Behind the Scenes)

1. **Attribute Linkage**: When you call `@WITHATTR`, Essbase scans the base dimension to find all members that have the specified attribute relationship.
2. **Dynamic**: If metadata changes (e.g., a store changes from "Small" to "Large"), the calc script dynamically picks up the change without needing an update.
3. **Execution Phase**: When used in a `FIX` statement, `@WITHATTR` is evaluated during the block selection phase, making it highly efficient.
4. **Data Types**: Attributes can be Text, Numeric, Boolean, or Date. The operators you use must match the attribute type (e.g., `">"` is generally for Numeric/Date attributes).

---

## Syntax Variants & Scenarios

### Variant 1: Simple Equality (Text Attribute)

```essbase
FIX(@WITHATTR("Large"))
    /* Calculates for all entities with Store Size = Large */
ENDFIX
```

### Variant 2: Using the Dimension Name

```essbase
FIX(@WITHATTR("Store Size", "==", "Large"))
```

### Variant 3: Numeric Comparison

```essbase
FIX(@WITHATTR("Ounces", ">", 12))
    /* Products where Ounces attribute is greater than 12 */
ENDFIX
```

### Variant 4: Boolean Attribute

```essbase
FIX(@WITHATTR("Caffeinated", "==", True))
```

### Variant 5: Combining Multiple Attributes

```essbase
FIX(@INTERSECT(@WITHATTR("Large"), @WITHATTR("Red")))
    /* Large AND Red products */
ENDFIX
```

---

## Practical Examples

### Example 1: Segmented Pricing

**Scenario**: Apply a 5% price increase to "Premium" tier products and a 2% increase to "Standard" tier products.

```essbase
FIX("FY25", "Working")
    /* Premium Products */
    FIX(@WITHATTR("Premium"))
        "Price" = "Price" -> "FY24" * 1.05;
    ENDFIX
    
    /* Standard Products */
    FIX(@WITHATTR("Standard"))
        "Price" = "Price" -> "FY24" * 1.02;
    ENDFIX
ENDFIX
```

---

### Example 2: Numeric Attribute Thresholds

**Scenario**: Calculate a volume discount only for products where the "Pack Size" attribute is greater than 24.

```essbase
FIX("FY25", "Working", @WITHATTR("Pack Size", ">", 24))
    "Discount" = "Gross Sales" * 0.10;
ENDFIX
```

---

### Example 3: Excluding an Attribute

**Scenario**: Calculate marketing expense for all products EXCEPT those tagged as "Discontinued".

```essbase
FIX("FY25", "Working", @WITHATTR("Status", "!=", "Discontinued"))
    "Marketing_Expense" = "Expected_Sales" * 0.05;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing quotes around operator | `@WITHATTR("Size", >, 10)` fails syntax check | Use quotes: `@WITHATTR("Size", ">", 10)` |
| Using @WITHATTR in IF | `@WITHATTR` returns a member list, not a Boolean, so it fails in `IF(@WITHATTR(...))` | Use `@ATTRIBUTE` for Boolean checks in `IF` statements |
| Incorrect attribute type | Using `">"` on a Text attribute yields unpredictable or error results | Ensure operators match the attribute data type |
| Assuming implicit intersection | `FIX(@WITHATTR("Red"), @WITHATTR("Large"))` means RED **OR** LARGE in some contexts depending on dimension | Use `@INTERSECT` to explicitly mean RED **AND** LARGE |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ATTRIBUTE`](./@ATTRIBUTE.md) | Boolean test for IF statements (True/False if member has attribute) |
| [`@UDA`](./@UDA.md) | Member selection based on User-Defined Attributes (Tags) |
| [`@ATTRIBUTEVAL`](./@ATTRIBUTEVAL.md) | Returns the numeric value of an attribute |
| [`FIX`](./FIX.md) | Where @WITHATTR is predominantly used |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @WITHATTR](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/withattr.html)
