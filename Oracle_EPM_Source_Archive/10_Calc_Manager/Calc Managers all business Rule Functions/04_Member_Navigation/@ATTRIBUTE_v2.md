# @ATTRIBUTE

## Overview

`@ATTRIBUTE` is a **member selection function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It returns a list of all base (Level 0) members in a dimension that are associated with a specific Attribute member.

### Why Does This Function Exist—

Attribute dimensions (like "Size", "Color", "Region_Type") categorize base members of standard dimensions (like "Store" or "Product") without exploding the size of the database. 
When you need to run a calculation on all "Large" stores, you could try to group them all under a single "Total Large Stores" parent. But what if you also need to group them by "East Coast vs West Coast"— You can't build hierarchies for every possible combination without making a mess.
Attributes solve this by tagging members. `@ATTRIBUTE` is the function that reads those tags and translates them into a list of target members for your calculation.

### When to Use It

- Inside a `FIX` statement to isolate calculations to a specific group of members sharing a trait.
- To execute targeted allocations (e.g., allocating marketing expense only to products with the "New_Launch" attribute).
- Inside cross-dimensional aggregations like `@SUMRANGE`.

---

## Category

**Member Selection / Metadata**

---

## Syntax

```essbase
@ATTRIBUTE(attributeMember)
```

### Formal Syntax

```
@ATTRIBUTE(attributeMemberExpression)
```

Where:
- `attributeMemberExpression` — The specific member from the Attribute Dimension you are targeting (e.g., `"Large"`, `"Red"`, `"True"`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `attributeMember`| Member | ✅ Yes | The name of the attribute member. You do not pass the base dimension name. Essbase automatically knows which base dimension the attribute is attached to. |

---

## Return Value

**Return Type**: Member Set (List)

Returns a list of all Level 0 members in the base dimension that have the `attributeMember` assigned to them.
*(Note: In Essbase, attributes can only be assigned to Level 0 members).*

---

## How It Works (Behind the Scenes)

1. **Metadata Query**: Essbase looks up `attributeMember` in the outline.
2. **Dimension Mapping**: It identifies the base dimension the attribute is linked to (e.g., "Large" is linked to "Entity").
3. **Scan & Compile**: It scans all Level 0 members of that base dimension, compiling a list of every member tagged with "Large".
4. **Execution**: This list is passed to the `FIX` statement or aggregation function.

---

## Syntax Variants & Scenarios

### Variant 1: Basic FIX Isolation

```essbase
FIX(@ATTRIBUTE("Large"))
    /* Executes math on all Large stores */
ENDFIX
```

### Variant 2: Combining Multiple Attributes (Intersection)

```essbase
/* Executes only for stores that are BOTH Large and located in Urban areas */
FIX(@ATTRIBUTE("Large") AND @ATTRIBUTE("Urban"))
    "Rent_Expense" = "Square_Footage" * 150;
ENDFIX
```

---

## Practical Examples

### Example 1: Targeted Pricing Updates

**Scenario**: You want to increase the price of all "Glass" packaged products by 5% due to supply chain costs, while leaving "Plastic" alone.

```essbase
FIX("FY25", "Working", @ATTRIBUTE("Glass"))
    
    /* This automatically loops through every product tagged as Glass */
    IF("Price" > 0)
        "Price" = "Price" * 1.05;
    ENDIF
    
ENDFIX
```

---

### Example 2: Attribute-Based Allocation

**Scenario**: A special "Green_Initiative" budget pool needs to be spread evenly, but only across factories that have the "Eco_Friendly" attribute.

```essbase
FIX("FY25", "Working")
    
    /* We use @COUNT with @ATTRIBUTE to find the denominator dynamically */
    VAR vEcoFactoryCount = @COUNT(SKIPNONE, @ATTRIBUTE("Eco_Friendly"));
    
    IF(vEcoFactoryCount > 0)
        FIX(@ATTRIBUTE("Eco_Friendly"))
            /* Spread the pool evenly among the Eco factories */
            "Facility_Upgrade_Budget" = "Green_Initiative_Pool" -> "Corporate" / vEcoFactoryCount;
        ENDFIX
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using in `IF` statements | `IF(@ATTRIBUTE("Large"))` is invalid syntax. `@ATTRIBUTE` generates a *list*, not a Boolean | Use `IF(@ISATTRIBUTE("Large"))` to check the condition of a single cell |
| Naming Conflicts | If you have "Active" as an attribute for Employees and "Active" as an attribute for Projects, `@ATTRIBUTE("Active")` can fail or act unpredictably | Use unique naming conventions for attribute members (e.g., `"Emp_Active"`, `"Proj_Active"`) |
| Expecting parent members | `@ATTRIBUTE` will *never* return a parent member because attributes are only assigned to Level 0 members | Do not use `@ATTRIBUTE` if you are trying to calculate or fix on intermediate rollups |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISATTRIBUTE`](../09_Boolean_Conditional/@ISATTRIBUTE.md) | The Boolean equivalent for testing a single member in an `IF` statement |
| [`@WITHATTR`](../09_Boolean_Conditional/@WITHATTR.md) | A more complex selection function that allows logical conditions (e.g., Size > 500) |
| [`@UDA`](../09_Boolean_Conditional/@UDA.md) | The equivalent selection function for User-Defined Attributes (UDAs) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ATTRIBUTE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/attribute.html)
