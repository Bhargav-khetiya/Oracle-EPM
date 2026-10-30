# @MATCH

## Overview

`@MATCH` is a **member selection and string searching function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It searches the database outline for members whose names or aliases match a specified wildcard pattern. 

### Why Does This Function Exist?

Standard member selections (`@CHILDREN("Parent")`) rely strictly on the outline hierarchy. But what if you need to select members based on their naming convention, regardless of where they live in the outline?
- Select all accounts ending in `_Elim` for an intercompany script.
- Select all entities starting with `UK_` across multiple regions.
- Search for a specific pattern dynamically generated at runtime.

`@MATCH` allows you to select members by text pattern rather than by hierarchy or attribute.

### When to Use It

- In `FIX` statements to dynamically group members based on naming conventions.
- When performing string-based filtering that UDAs or Attributes cannot solve.
- To execute calculations on a broad, cross-hierarchical set of members sharing a naming pattern.

---

## Category

**Member Selection / Text Pattern**

---

## Syntax

```essbase
@MATCH(dimName, "patternString")
```

### Formal Syntax

```
@MATCH(dimensionName, "wildcardPattern")
```

Where:
- `dimensionName` — The dimension to search within (e.g., `"Entity"`, `"Account"`).
- `"wildcardPattern"` — A string enclosed in quotes containing wildcard characters (`?` or `*`).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension | ✅ Yes | The name of the dimension to search. Must be provided as a string or member reference. |
| `patternString` | String | ✅ Yes | The pattern to match against member names or aliases. Uses standard wildcards: `*` (matches zero or more characters) and `?` (matches exactly one character). Case-sensitive in some Essbase configurations, but generally safer to assume exact case matches. |

---

## Return Value

**Return Type**: Member Set (a list of all members in the specified dimension that match the pattern).

---

## How It Works (Behind the Scenes)

1. **Outline Scan**: Essbase performs a scan of all members (and their aliases, depending on alias table settings) within the specified dimension.
2. **Pattern Matching**: 
   - `*` replaces any string of characters.
   - `?` replaces any single character.
3. **Performance**: Because `@MATCH` scans the entire dimension, it can be slower to evaluate during script compilation than a direct hierarchy reference (like `@CHILDREN`). However, in a `FIX` statement, this evaluation happens once at the start of the block, so the runtime impact is usually negligible.

---

## Syntax Variants & Scenarios

### Variant 1: Prefix Matching

```essbase
FIX(@MATCH("Entity", "UK_*"))
/* Matches UK_Retail, UK_Wholesale, UK_101 */
```

### Variant 2: Suffix Matching

```essbase
FIX(@MATCH("Account", "*_Elim"))
/* Matches Revenue_Elim, COGS_Elim */
```

### Variant 3: Contains Matching

```essbase
FIX(@MATCH("Product", "*Phone*"))
/* Matches SmartPhone, CellPhone_Accessories */
```

### Variant 4: Single Character Wildcard

```essbase
FIX(@MATCH("Entity", "Store_??"))
/* Matches Store_01, Store_99. Does NOT match Store_100 */
```

---

## Practical Examples

### Example 1: Intercompany Eliminations by Naming Convention

**Scenario**: You do not use a custom dimension for Intercompany, but instead append `_IC` to specific accounts. You want to clear these accounts during a reset script.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    /* Select every account ending in _IC */
    FIX(@MATCH("Account", "*_IC"))
        CLEARDATA @CURRMBR("Account");
    ENDFIX
ENDFIX
```

---

### Example 2: Prefix-based Tax Calculation

**Scenario**: Certain legal entities are prefixed with `US_`. You want to apply the US tax rate to them regardless of which regional parent they roll up to in the management hierarchy.

```essbase
FIX("FY25", "Working", @MATCH("Entity", "US_*"))
    "Tax_Expense" = "PreTax_Income" * 0.21; /* US Corporate Rate */
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing the dimension name | `@MATCH("*_Elim")` is invalid syntax | Always include the dimension: `@MATCH("Account", "*_Elim")` |
| Using `@MATCH` inside `IF` | `@MATCH` returns a *list* of members, not a Boolean. It cannot be used like `IF(@MATCH(...))` | Use `@ISMBR(@MATCH(...))` if you need to check if the current member matches a pattern in an `IF` statement |
| Alias Table Confusion | If members match based on an Alias, but the user is logged in with a different Alias table active, the calc may fail or return different results | Try to build naming conventions into the actual Member Name rather than relying on Aliases for `@MATCH` |
| Performance on huge dimensions | Scanning a 1-million member dimension using `*foo*` can cause compilation delays | Use hierarchical selections (`@DESCENDANTS`) if possible, or UDAs for faster filtering |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@UDA`](./@UDA.md) | Often a better, faster alternative to naming conventions |
| [`@ISMBR`](./@ISMBR.md) | Can be wrapped around `@MATCH` to test if the current member fits the pattern |
| [`@LIKE`](./@LIKE.md) | Similar string comparison, used more in MDX/ASO |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MATCH](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/match.html)
