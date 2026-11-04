# @EQUAL

## Overview

`@EQUAL` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the database outline and generates a list of all members within a specified dimension that possess an **exact, specific string value** for a given Attribute, UDA (User Defined Attribute), or Alias.

*(Note: While Calc Manager allows string equality comparisons via `==` in IF statements, `@EQUAL` is specifically designed for generating arrays/lists of members to be used inside FIX statements or cross-dimensional allocations).*

### Why Does This Function Exist—

When building calculation scripts, you rarely want to run a rule on the entire database. You need to target specific subsets of data. 
If an administrator adds a custom Attribute Dimension called `Store_Size` (with members like `"Large"`, `"Medium"`, `"Small"`), they might need to apply a 5% overhead allocation ONLY to the `"Large"` stores. 
Writing a `FIX` statement listing every single large store manually is impossible to maintain. 
`@EQUAL` automates this targeting. By wrapping it inside a `FIX`, you tell Essbase: "Go look at the `Store_Size` attribute, and give me a list of every single Entity that has an exact match to `"Large"`." Essbase scans the outline in memory, instantly generates the array of matching stores, and locks the calculation block to only those members.

### When to Use It

- **Attribute-Based Calculation Routing**: Fixing a calculation script to run exclusively on Products that have the `"Discontinued"` status attribute.
- **Dynamic Allocations**: Generating a targeted list of Destination members for an `@ALLOCATE` function based on shared UDAs.
- **Alias-Driven Math**: Searching for members based on their readable Alias rather than their cryptic backend Member Name.

---

## Category

**Member Selection / Attributes & UDAs / Essbase Native Functions**

---

## Syntax

```essbase
@EQUAL(Attribute_Name, "Search_String")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Attribute_Name` | String / Member | ✅ Yes | The name of the Attribute Dimension, UDA classification, or Alias Table you are evaluating (e.g., `"Store_Size"`, `"Color"`, `"UDA"`). |
| `"Search_String"` | String | ✅ Yes | The exact text value you are looking for. **Must be enclosed in double quotes**. (e.g., `"Large"`, `"Red"`). |

---

## Return Value

**Return Type**: Member List (Array)

Returns an array of all members in the base dimension that perfectly match the search string criteria.
- **Exact Match Required**: The string must match perfectly. It is not a wildcard search (it is not a "contains" search).
- **Empty Lists**: If no members match the criteria, it returns an empty set. If used inside a `FIX`, this will cause the `FIX` statement to instantly terminate and skip the calculation (which is usually the desired behavior).

---

## How It Works (Behind the Scenes)

1. **Compilation Scan**: When the script compiles (usually during the `FIX` evaluation phase), Essbase intercepts the `@EQUAL` request.
2. **Index Query**: It bypasses the data blocks entirely and queries the outline metadata index in memory.
3. **Evaluation**: It checks every base member that is associated with the `Attribute_Name`. If the tagged value matches `"Search_String"` exactly, that member is added to a temporary array.
4. **Return**: It returns the fully populated array of members to the `FIX` statement or function block, isolating the calculation engine to that specific subset.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Attribute Selection

```essbase
/* 
   Generates a list of all Products where the "Color" attribute is exactly "Red".
*/
@EQUAL("Color", "Red")
```

---

## Practical Examples

### Example 1: Dynamic FIX Routing Based on Store Size

**Scenario**: A corporate overhead allocation rule runs monthly. The business logic dictates that `"Large"` stores absorb `$10,000` of overhead, while all other stores absorb nothing. Instead of writing `IF` statements inside the block (which is slow), the administrator uses `@EQUAL` to strictly limit the `FIX` statement to only the Large stores, drastically improving performance.

```essbase
/* 
   1. The FIX statement uses @EQUAL to query the "Store_Size" attribute dimension.
   It instantly builds a list of only the Large stores and locks the engine to them.
*/
FIX("FY25", "Working", @EQUAL("Store_Size", "Large"))
    
    /* 
       2. Assign the overhead. 
       Because of the FIX, this ONLY happens to Large stores. 
       We do not need an IF statement here.
    */
    "Corporate_Overhead" = 10000;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Quotes on the Search String | `@EQUAL("Store_Size", Large)` | The second parameter is a literal search string, NOT a member reference. It must be wrapped in double quotes. If you omit the quotes, Essbase will try to evaluate `Large` as a variable or member, fail to find it, and throw a syntax error |
| Using it for Substrings | `@EQUAL("Description", "Exp_")` | `@EQUAL` demands an EXACT match. If the description is `"Exp_Travel"`, and you search for `"Exp_"`, it will return an empty list. If you need to search for partial strings (wildcards), you MUST use `@LIKE` instead |
| Passing Data Values | `@EQUAL("Revenue", "1000")` | This function is strictly for evaluating Outline Metadata (Attributes, UDAs, Aliases). It CANNOT search data blocks. You cannot use it to find all entities where Revenue equals `$1,000`. To evaluate data conditionally, you must use standard `IF("Revenue" == 1000)` logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@LIKE`](./@LIKE.md) | The wildcard alternative to `@EQUAL`. It allows you to search for partial strings (e.g., `"Exp_*"`), making it much more flexible for description or alias routing |
| [`@NOTEQUAL`](./@NOTEQUAL.md) | The exact inverse. It returns all members that DO NOT match the search string |
| [`@UDA`](./@UDA.md) | A dedicated, faster selection function specifically built for targeting User Defined Attributes, often preferred over using `@EQUAL` for UDA lookups |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — EQUAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/equal.html)
