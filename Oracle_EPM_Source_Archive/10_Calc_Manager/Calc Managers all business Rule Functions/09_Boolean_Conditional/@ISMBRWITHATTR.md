# @ISMBRWITHATTR

## Overview

`@ISMBRWITHATTR` is a **Boolean logical and comparison function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It checks whether the member currently being calculated possesses an attribute that satisfies a specific logical condition (e.g., "Is the Population attribute > 10000—). It returns `TRUE` or `FALSE`.

### Why Does This Function Exist—

Standard `@ISATTRIBUTE` only checks for an *exact match* of an attribute member (e.g., "Is this a 'Large' store—).
But Attribute Dimensions in Essbase can be **Numeric**, **Boolean**, or **Date** types. 
- You want to apply a bonus calculation to any store where the "Square_Footage" attribute is greater than 50,000.
- You want to apply an inflation factor to any product introduced before the "Launch_Date" of 01-01-2023.

`@ISMBRWITHATTR` allows you to evaluate mathematical and logical conditions against the metadata tags themselves.

### When to Use It

- Inside `IF` statements to route logic based on numeric or date comparisons of attribute metadata.
- To execute complex filtering without having to hardcode thousands of specific entity names.
- When you need conditional logic based on metadata rather than the numerical data residing in the cells.

---

## Category

**Logical / Boolean / Metadata Comparison**

---

## Syntax

```essbase
@ISMBRWITHATTR(attrDimName, "operator", value)
```

### Formal Syntax

```
@ISMBRWITHATTR(attributeDimensionName, "comparisonOperator", comparisonValue)
```

Where:
- `attributeDimensionName` — The name of the attribute dimension you are evaluating (e.g., `"Square_Footage"`).
- `"comparisonOperator"` — A standard operator enclosed in quotes: `"=="`, `"!="`, `">"`, `"<"`, `">="`, `"<="`.
- `comparisonValue` — The value to compare against. Can be a number, a date string, or a boolean (True/False).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `attrDimName` | Dimension | ✅ Yes | The name of the Attribute Dimension being checked. |
| `"operator"` | String | ✅ Yes | The comparison operator. Must be in quotes. |
| `value` | Num/String| ✅ Yes | The threshold value. If it's a number, do not use quotes (`50000`). If it's a date or string, use quotes (`"10-15-2023"`). |

---

## Return Value

**Return Type**: Boolean

| Condition | Returns |
|-----------|---------|
| Current member's attribute satisfies the condition | `TRUE` (1) |
| Current member fails the condition, or has no attribute | `FALSE` (0) |

---

## How It Works (Behind the Scenes)

1. **Context Context**: Essbase looks at the current base member being calculated (e.g., "Store_NY").
2. **Metadata Lookup**: It retrieves the value of the `attrDimName` attached to that specific member (e.g., Store_NY has a Square_Footage of 60000).
3. **Evaluation**: It runs the equation: `60000 > 50000`.
4. **Result**: Because the statement is true, it returns `TRUE`.

---

## Syntax Variants & Scenarios

### Variant 1: Numeric Comparison

```essbase
IF(@ISMBRWITHATTR("Square_Footage", ">", 50000))
    /* Execute logic for Mega Stores */
ENDIF
```

### Variant 2: Date Comparison

```essbase
IF(@ISMBRWITHATTR("Store_Open_Date", "<", "01-01-2020"))
    /* Execute logic for mature stores opened before 2020 */
ENDIF
```

### Variant 3: String/Text Comparison (Pattern Matching)

```essbase
IF(@ISMBRWITHATTR("Ounces", "==", "12_oz"))
    /* Similar to @ISATTRIBUTE, but explicitly checking the value */
ENDIF
```

---

## Practical Examples

### Example 1: Tiered Maintenance Costs by Square Footage

**Scenario**: You are calculating facility maintenance budgets. Instead of storing square footage as data, it is a numeric attribute on the Entity dimension. You apply different cost-per-sqft rates based on size thresholds.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Small spaces */
    IF(@ISMBRWITHATTR("SqFt", "<=", 10000))
        "Maintenance_Cost" = "Base_Cost" * 1.5;
        
    /* Medium spaces */
    ELSEIF(@ISMBRWITHATTR("SqFt", ">", 10000) AND @ISMBRWITHATTR("SqFt", "<=", 50000))
        "Maintenance_Cost" = "Base_Cost" * 1.2;
        
    /* Large spaces */
    ELSEIF(@ISMBRWITHATTR("SqFt", ">", 50000))
        "Maintenance_Cost" = "Base_Cost" * 1.0;
    ENDIF
    
ENDFIX
```

---

### Example 2: Mature Store Baseline adjustment

**Scenario**: Any store opened prior to a specific date is considered "Mature" and its baseline growth is capped at 3%. Newer stores are capped at 10%.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Revenue" > 0)
        /* Check the Date attribute */
        IF(@ISMBRWITHATTR("Open_Date", "<", "01-01-2018"))
            "Projected_Rev" = "Revenue" * 1.03; /* Mature Cap */
        ELSE
            "Projected_Rev" = "Revenue" * 1.10; /* Growth Cap */
        ENDIF
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Checking parents | In Essbase, attributes can only be assigned to Level 0 (leaf) members. `IF(@ISMBRWITHATTR(...))` will always evaluate to FALSE if calculating on a parent | Restrict logic to Level 0 members using `@ISLEV(Dim, 0)` before checking attributes |
| Missing quotes on the operator | `@ISMBRWITHATTR("SqFt", >, 10000)` is a syntax error | You must put the comparison operator in quotes: `">"` |
| Using for `FIX` statements | `FIX(@ISMBRWITHATTR(...))` is invalid syntax | Use `@WITHATTR("SqFt", ">", 10000)` for `FIX` blocks. Use `@ISMBRWITHATTR` only in `IF` statements |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@WITHATTR`](./@WITHATTR.md) | Returns the *list* of base members matching the condition (used in FIX blocks) |
| [`@ISATTRIBUTE`](./@ISATTRIBUTE.md) | Checks for a simple exact match of a boolean/text attribute |
| [`@ATTRIBUTEVAL`](./@ATTRIBUTEVAL.md) | Retrieves the numeric value of the attribute so you can use it in math (e.g., `Value * @ATTRIBUTEVAL("SqFt")`) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISMBRWITHATTR](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ismbrwithattr.html)
