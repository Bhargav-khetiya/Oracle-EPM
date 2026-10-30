# @ISATTRIBUTE

## Overview

`@ISATTRIBUTE` is a **Boolean logical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated is associated with a specific Attribute member from a designated Attribute Dimension. It returns `TRUE` or `FALSE`.

### Why Does This Function Exist?

Standard dimensions (like "Entity" or "Product") determine the primary structure of the database. **Attribute Dimensions** (like "Store_Size" or "Product_Color") are dynamically linked to base dimensions to provide rich, metadata-driven groupings without increasing the physical size (sparsity) of the cube.
While you can use `FIX(@ATTRIBUTE("Large"))` to isolate a calculation to Large stores, you often need to branch logic *within* a larger calculation block based on the attribute of the current member.

`@ISATTRIBUTE` allows you to ask: *"Does the Product I'm currently calculating have the 'Red' attribute?"*

### When to Use It

- Inside `IF` statements to route driver-based logic depending on attribute metadata.
- When applying tiered rates (e.g., Large stores get 5% growth, Small stores get 10%).
- As an alternative to `@ISUDA`, when the metadata is stored as formally typed Attributes rather than simple text UDAs.

---

## Category

**Logical / Boolean / Metadata Evaluation**

---

## Syntax

```essbase
@ISATTRIBUTE(attributeMember)
```

### Formal Syntax

```
@ISATTRIBUTE(attributeMemberExpression)
```

Where:
- `attributeMemberExpression` — The specific member from the Attribute Dimension you are checking for (e.g., `"Large"`, `"Red"`, `"Ounces_12"`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `attributeMember`| Member | ✅ Yes | The name of the attribute member. Note: You do not pass the base dimension name. Essbase automatically knows which base dimension the attribute is attached to. |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member is explicitly associated with `attributeMember` | `TRUE` (1) |
| Current member has a different attribute, or no attribute | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current intersection being calculated.
2. **Metadata Lookup**: It sees the `attributeMember` provided and checks its metadata to see which base dimension it is attached to (e.g., "Large" is attached to "Entity").
3. **Association Check**: It looks at the current "Entity" member being calculated and checks if its assigned attribute matches the one requested.

---

## Syntax Variants & Scenarios

### Variant 1: Routing by Store Size Attribute

```essbase
IF(@ISATTRIBUTE("Large"))
    /* Execute logic for Large stores */
ENDIF
```

---

## Practical Examples

### Example 1: Differentiated Growth Drivers by Size

**Scenario**: You are projecting next year's revenue based on current year actuals. The growth rate assumption depends on the physical size of the store (Small, Medium, Large), which is defined in the "Store_Size" attribute dimension attached to Entity.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Actual" -> "FY24" > 0)
        IF(@ISATTRIBUTE("Small"))
            "Revenue" = "Actual" -> "FY24" * 1.10; /* 10% Growth */
        ELSEIF(@ISATTRIBUTE("Medium"))
            "Revenue" = "Actual" -> "FY24" * 1.05; /* 5% Growth */
        ELSEIF(@ISATTRIBUTE("Large"))
            "Revenue" = "Actual" -> "FY24" * 1.02; /* 2% Growth */
        ELSE
            "Revenue" = "Actual" -> "FY24"; /* Flat if no attribute */
        ENDIF
    ENDIF
    
ENDFIX
```

---

### Example 2: Conditional Pricing by Packaging Type

**Scenario**: You are calculating cost of goods sold. The packaging cost differs if the product has the "Glass" attribute vs the "Plastic" attribute.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Product"))
    
    /* Ensure we only calculate at the base product level, since attributes
       are only assigned to Level 0 members in Essbase. */
    IF(@ISLEV("Product", 0))
        
        IF(@ISATTRIBUTE("Glass"))
            "Packaging_Cost" = "Units" * 0.50;
        ELSEIF(@ISATTRIBUTE("Plastic"))
            "Packaging_Cost" = "Units" * 0.15;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Checking parents | In Essbase, attributes can only be assigned to Level 0 (leaf) members. `IF(@ISATTRIBUTE("Large"))` will always evaluate to FALSE if calculating on a parent | Restrict logic to Level 0 members using `@ISLEV(Dim, 0)` before checking attributes |
| Using for `FIX` statements | `FIX(@ISATTRIBUTE("Large"))` is invalid syntax | Use `@ATTRIBUTE("Large")` for `FIX` blocks. Use `@ISATTRIBUTE` only in `IF` statements |
| Naming Conflicts | If you have two different attributes named "Active" in different attribute dimensions, `@ISATTRIBUTE("Active")` might resolve unpredictably | Use unique naming conventions for attribute members, or explicitly qualify them like `"Status_Active"` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ATTRIBUTE`](./@ATTRIBUTE.md) | Returns the *list* of base members with the attribute (used in FIX blocks) |
| [`@ISMBRWITHATTR`](./@ISMBRWITHATTR.md) | Checks if a member has *any* attribute that matches a specified condition (e.g., Size > 10) |
| [`@ISUDA`](./@ISUDA.md) | The equivalent check for User-Defined Attributes (UDAs) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISATTRIBUTE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isattribute.html)
