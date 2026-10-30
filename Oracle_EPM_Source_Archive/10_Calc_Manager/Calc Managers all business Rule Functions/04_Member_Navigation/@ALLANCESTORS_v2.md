# @ALLANCESTORS

## Overview

`@ALLANCESTORS` is a **member set (relationship) function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns **all ancestors** of a specified member — from the member's immediate parent all the way up to the root (dimension) member. Unlike `@ANCESTORS` which can be limited by generation, `@ALLANCESTORS` always returns the complete ancestral chain.

### Why Does This Function Exist?

In hierarchical planning dimensions (Entity, Account, Product, etc.), you often need to reference every parent, grandparent, and so on up to the dimension root. Common use cases:
- Rolling up values through the entire hierarchy
- Applying logic to all levels above a specific member
- Checking if a member sits anywhere below a specific ancestor
- Building dynamic aggregation paths

### When to Use It

- When you need to process or iterate through every ancestor of a member
- In FIX statements to restrict calculations to the full ancestry chain
- When building upward-cascading logic (e.g., approval workflows)
- For audit trails that need to show full hierarchy paths

---

## Category

**Member Set / Relationship**

---

## Syntax

```essbase
@ALLANCESTORS(member)
```

### Formal Syntax

```
@ALLANCESTORS(memberExpression)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name or member expression | ✅ Yes | The member whose ancestors you want to retrieve. Can be a literal member name in quotes, or a member-resolving function like `@CURRMBR`. The member itself is **NOT** included in the returned set. |

---

## Return Value

Returns a **member set** containing all ancestors of the specified member, from the immediate parent up to (and including) the dimension root.

| Condition | Returns |
|-----------|---------|
| Member has ancestors | Ordered set: parent, grandparent, ..., root |
| Member IS the root | Empty set (no ancestors exist) |
| Invalid member | Error |

**Return Type**: Member set

---

## How It Works (Behind the Scenes)

1. **Traversal Direction**: `@ALLANCESTORS` traverses the hierarchy **upward** — from the specified member toward the root. It starts at the member's immediate parent and continues climbing until it reaches the top-level dimension member.

2. **Set Order**: The returned set is ordered from the immediate parent first, then grandparent, and so on up to the root. This order is consistent and predictable.

3. **Excludes the Source Member**: The specified member itself is NOT included in the returned set. If you need the member plus all its ancestors, combine with `@MEMBER` or use `@IALLANCESTORS` (inclusive version).

4. **Shared Members**: If a member is shared (appears in multiple hierarchies), `@ALLANCESTORS` follows the PRIMARY hierarchy path — the one defined by the member's stored parent.

5. **Performance**: Since the ancestor chain is typically short (5-10 levels deep at most), `@ALLANCESTORS` is very efficient. The lookup is a simple pointer-following operation up the outline tree.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Ancestor Lookup

```essbase
@ALLANCESTORS("New_York")
```
If the hierarchy is: `Total_Entity > North_America > US_East > New_York`
Returns: `{US_East, North_America, Total_Entity}`

### Variant 2: Inside a FIX Statement

```essbase
FIX(@ALLANCESTORS("Product_A"))
    /* Calculation runs for all parents up to the root of Product dimension */
ENDFIX
```

### Variant 3: Dynamic with @CURRMBR

```essbase
@ALLANCESTORS(@CURRMBR("Entity"))
```
Returns all ancestors of whatever Entity member is currently being processed.

### Variant 4: Combined with Other Set Functions

```essbase
@REMOVE(@ALLANCESTORS("New_York"), "Total_Entity")
```
Returns all ancestors of New_York except the root Total_Entity member.

---

## Practical Examples

### Example 1: Propagate a Flag Up the Hierarchy

**Scenario**: If any leaf entity has a "Review_Needed" flag, mark all its ancestors with the same flag.

```essbase
FIX("Actual", "FY24", "Jan")
    @LEVMBRS("Entity", 0)(
        IF("Review_Needed" == 1)
            FIX(@ALLANCESTORS(@CURRMBR("Entity")))
                "Review_Needed" = 1;
            ENDFIX
        ENDIF
    )
ENDFIX
```

---

### Example 2: Audit Trail — Show Full Hierarchy Path

**Scenario**: Log the entire hierarchy path for each leaf member being calculated.

```essbase
FIX("Actual", "FY24")
    @LEVMBRS("Entity", 0)(
        @CalcMgrLogStrings(
            @CalcMgrConcat(
                "Member: ", @CURRMBR("Entity"),
                " | Ancestors: ", @NAME(@ALLANCESTORS(@CURRMBR("Entity")))
            )
        );
    )
ENDFIX
```

---

### Example 3: Conditional Logic Based on Ancestry

**Scenario**: Apply a tax rate based on whether the current entity falls under a specific regional parent.

```essbase
FIX("Actual", "FY24", @LEVMBRS("Entity", 0))
    IF(@ISANCEST("EMEA", @CURRMBR("Entity")))
        "Tax_Rate" = 0.25;
    ELSEIF(@ISANCEST("APAC", @CURRMBR("Entity")))
        "Tax_Rate" = 0.22;
    ELSE
        "Tax_Rate" = 0.30;
    ENDIF
ENDFIX
```

Note: In this case, `@ISANCEST` is simpler for checking a single ancestor. `@ALLANCESTORS` is better when you need the full set.

---

### Example 4: Copy Data to All Ancestor Levels

**Scenario**: Copy a status code from leaf to every level above.

```essbase
FIX("Working", "FY24")
    @LEVMBRS("Product", 0)(
        VAR statusVal = "Status_Code";
        FIX(@ALLANCESTORS(@CURRMBR("Product")))
            "Rollup_Status" = statusVal;
        ENDFIX
    )
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting the source member in the result | `@ALLANCESTORS` **excludes** the member itself | Use `@IALLANCESTORS` for the inclusive version |
| Using on the root member | The root/dimension member has no ancestors — returns an empty set | Check if member is root before calling |
| Confusing with `@ANCESTORS` | `@ANCESTORS` can be limited to a specific generation; `@ALLANCESTORS` always goes to the root | Use `@ANCESTORS` when you need a limited scope |
| Shared member behavior | With shared members, follows the primary hierarchy | Be aware of shared member structures |
| Empty set in FIX | If `@ALLANCESTORS` returns an empty set (e.g., called on root), the FIX block has no members to process | Add checks or ensure you're not calling on root members |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@IALLANCESTORS`](@IALLANCESTORS.md) | **Inclusive** version — includes the member itself plus all ancestors |
| [`@ANCESTORS`](@ANCESTORS.md) | Returns ancestors up to a specified generation (not necessarily all) |
| [`@IANCESTORS`](@IANCESTORS.md) | Inclusive version of @ANCESTORS |
| [`@LANCESTORS`](@LANCESTORS.md) | Left ancestors in a shared hierarchy |
| [`@PARENT`](@PARENT.md) | Returns only the immediate parent |
| [`@ANCEST`](@ANCEST.md) | Returns a specific ancestor at a given generation |
| [`@ISANCEST`](../09_Boolean_Conditional/@ISANCEST.md) | Boolean — checks if one member is an ancestor of another |
| [`@DESCENDANTS`](@DESCENDANTS.md) | Opposite direction — returns all descendants going downward |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ALLANCESTORS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/allancestors.html)
- [Oracle Essbase Technical Reference — Relationship Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/relationship_functions.html)
