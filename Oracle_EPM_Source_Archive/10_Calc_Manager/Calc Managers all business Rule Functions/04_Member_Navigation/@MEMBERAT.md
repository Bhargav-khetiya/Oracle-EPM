# @MEMBERAT

## Overview

`@MEMBERAT` is a **member selection function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns a specific member from a list based on its index position (its numeric placement within that list).

### Why Does This Function Exist?

When dealing with dynamic arrays of members (like `@CHILDREN("Total Entity")`), you sometimes need to isolate exactly one member from that list without knowing its explicit name.
- Grab the *first* child of a hierarchy to park rounding errors.
- Grab the *last* month of a quarter to calculate closing balances.
- Loop through a list of members dynamically using an index variable.

### When to Use It

- To extract a single, predictable member from a dynamic list (e.g., first, last, nth).
- Inside a `LOOP` where an integer variable dictates which member to process next.
- To handle default target assignments dynamically.

---

## Category

**Member Selection / Indexing**

---

## Syntax

```essbase
@MEMBERAT(memberList, index)
```

### Formal Syntax

```
@MEMBERAT(rangeList, indexPosition)
```

Where:
- `rangeList` — The list of members to select from (e.g., `@CHILDREN("Parent")`, `@SIBLINGS("Mbr")`).
- `indexPosition` — The position number of the member you want to extract.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `memberList`| Member list| ✅ Yes | The generated list of members. Can be an outline function like `@DESCENDANTS` or a comma-separated list `("Jan", "Feb", "Mar")`. |
| `index` | Integer | ✅ Yes | The 1-based index position of the target member. Positive numbers count from the beginning (1 = first). Negative numbers count from the end (-1 = last, -2 = second to last). |

---

## Return Value

**Return Type**: Single Member Reference

Returns the specific member at the given index. If the index is out of bounds (e.g., asking for the 10th member of a 5-member list), it returns an error or fails validation.

---

## How It Works (Behind the Scenes)

1. **List Generation**: Essbase compiles the `memberList` into an ordered internal array based on outline order (or explicit listing order).
2. **Indexing**: 
   - If `index > 0`, it counts forward from the start of the list.
   - If `index < 0`, it counts backward from the end of the list.
3. **Extraction**: It pulls that single member and substitutes the `@MEMBERAT` function call with that member reference.

---

## Syntax Variants & Scenarios

### Variant 1: First Member

```essbase
@MEMBERAT(@CHILDREN("Q1"), 1)
/* Returns "Jan" */
```

### Variant 2: Last Member (Negative Index)

```essbase
@MEMBERAT(@CHILDREN("Q1"), -1)
/* Returns "Mar" */
```

### Variant 3: Nth Member

```essbase
@MEMBERAT(@CHILDREN("Total_Entities"), 3)
/* Returns the 3rd child in the outline under Total_Entities */
```

---

## Practical Examples

### Example 1: Parking Rounding Errors on the First Child

**Scenario**: You are doing a top-down allocation and need to dump any penny rounding differences onto the very first entity in the hierarchy, regardless of what its name is.

```essbase
FIX("FY25", "Working")
    /* Spread corporate costs evenly */
    "Allocated_Cost" = @ALLOCATE(
        "Cost"->"Corporate", 
        @CHILDREN("Total Entity"), 
        spread, 
        roundAmt(2), 
        roundErrTo(@MEMBERAT(@CHILDREN("Total Entity"), 1)) /* Dumps to 1st child */
    );
ENDFIX
```

---

### Example 2: Dynamic Looping with Variables

**Scenario**: You want to execute a specific calculation block exactly 4 times, stepping through the four quarters.

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    VAR vIndex = 1;
    
    LOOP(4)
        /* Grab the specific quarter based on the current loop index */
        FIX(@MEMBERAT(@CHILDREN("YearTotal"), vIndex))
            /* Complex logic evaluated for this specific quarter */
            "Bonus_Accrual" = "Revenue" * 0.05;
        ENDFIX
        
        /* Increment for the next loop */
        vIndex = vIndex + 1;
    ENDLOOP
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| 0-Based Indexing | `@MEMBERAT` uses 1-based indexing. Passing `0` will cause an error | Use `1` for the first member, `2` for the second |
| Out of Bounds | `@MEMBERAT(@CHILDREN("Q1"), 4)` fails because Q1 only has 3 children | Ensure your index logic safely fits within the known bounds of the list |
| Not handling dynamic lists safely | If an outline changes (e.g., someone adds a new entity), the "3rd child" might not be the same entity tomorrow as it is today | Do not use `@MEMBERAT` for hardcoded mapping; use it for dynamic logic (like first/last) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@NEXT`](./@NEXT.md) | Moves forward one space from the *current* member |
| [`@PRIOR`](./@PRIOR.md) | Moves backward one space from the *current* member |
| [`@COUNT`](./@COUNT.md) | Useful for finding the maximum index size of a list |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @MEMBERAT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/memberat.html)
