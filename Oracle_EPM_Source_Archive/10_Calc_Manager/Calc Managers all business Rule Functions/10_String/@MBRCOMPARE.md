# @MBRCOMPARE

## Overview

`@MBRCOMPARE` is a **native Essbase boolean/numeric function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates two structural member names and compares them lexicographically (alphabetically) to determine their sorting order. It returns a mathematical integer representing whether the first member is less than, equal to, or greater than the second member.

### Why Does This Function Exist—

In highly dynamic, loop-based calculation scripts or custom allocation engines, administrators sometimes need to execute logic conditionally based on the alphabetical names of the dimension members. 
For example, if a script processes a list of Projects (`"Proj_A"`, `"Proj_B"`, `"Proj_C"`), and you only want to execute the math for projects that come alphabetically *after* `"Proj_B"`, you need a way to mathematically compare text.
Standard Essbase math (`"Proj_A" > "Proj_B"`) will crash the compiler because you cannot use mathematical operators on strings. 
`@MBRCOMPARE` bridges this gap. It acts like a classic C-level `strcmp()` function. It takes two members, evaluates their string names based on their ASCII character values, and outputs an integer (`-1`, `0`, `1`). Because it outputs a number, you can safely wrap it inside an `IF` statement to build advanced string-sorting logic directly in Essbase.

### When to Use It

- **Alphabetical Filtering**: Executing a calculation loop only on members that fall within a specific alphabetical range (e.g., executing only on entities from A to M).
- **String Equivalence Validation**: Checking if a dynamically generated member reference (like `@CURRMBR`) is exactly equal to a hardcoded string or another member reference.
- **Sorting Logic**: Providing the comparison backbone for custom Java CDFs or macro loops that attempt to sort arrays alphabetically in memory.

---

## Category

**String Processing / Comparisons & Equivalence / Essbase Native Functions**

---

## Syntax

```essbase
@MBRCOMPARE(mbrName1, mbrName2)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName1` | Member | ✅ Yes | The first structural member (or string representing a member) to evaluate. |
| `mbrName2` | Member | ✅ Yes | The second structural member (or string) to evaluate against the first. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the lexicographical relationship between the two member names.
- **`-1`**: `mbrName1` is strictly **less than** `mbrName2` (it comes first alphabetically).
- **`0`**: The members are **exactly identical**.
- **`1`**: `mbrName1` is strictly **greater than** `mbrName2` (it comes later alphabetically).

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The engine resolves both parameters. If they are structural members (`"Entity_A"`), it extracts their raw text names.
2. **ASCII Comparison**: It compares the two strings character-by-character from left to right.
3. **Casing Check**: It evaluates the strict ASCII values of the characters. (In ASCII, uppercase `A` is 65, lowercase `a` is 97).
4. **Return**: The moment it finds a differing character, it evaluates which ASCII value is larger, and immediately returns `-1` or `1`. If it hits the end of the string and they are identical in value and length, it returns `0`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking for Equality

```essbase
/* 
   Because the strings are identical, it returns 0.
*/
VAR vStatus = @MBRCOMPARE("New_York", "New_York");
```

---

## Practical Examples

### Example 1: Alphabetical Batch Processing

**Scenario**: A massive aggregation takes 4 hours. To prevent timeout crashes, the administrator splits the aggregation into two batches: Entities A through M, and Entities N through Z. They use `@MBRCOMPARE` to dynamically check the name of the current entity and only execute the math if the entity falls in the A-M bucket.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. We compare the active entity against the letter "N".
       If the entity starts with A-M, it is "less than" N.
       Therefore, @MBRCOMPARE will return -1.
    */
    IF(@MBRCOMPARE(@CURRMBR("Entity"), "N") < 0)
        
        /* 
           2. Execute Batch 1 (A through M).
        */
        "Agg_Flag" = 1;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Reverse Boolean Logic | `IF(@MBRCOMPARE(A, B) == 1)` for Equality | In standard boolean logic, `1` means True. **In C-string comparisons, `0` means True (Zero Differences).** If you write `IF(Compare == 1)` hoping to catch identical members, your script will actually trigger whenever the first member is simply alphabetically greater than the second. Always use `== 0` for inclusion logic |
| Case Sensitivity | `"apple"` vs `"Apple"` | This function is strictly tied to ASCII values, making it **case-sensitive**. Uppercase letters have lower ASCII values than lowercase letters. Therefore, `@MBRCOMPARE("Zebra", "apple")` will shockingly return `-1` (Zebra is less than apple), because `Z` (90) is less than `a` (97). If you have messy data, this function will break |
| Comparing Member Objects vs Strings | Missing Quotes | While the function accepts structural members, if you pass a dynamic function like `@CURRMBR`, ensure it resolves correctly. In older Essbase versions, it was highly recommended to wrap member functions in `@NAME` (e.g., `@NAME(@CURRMBR("Entity"))`) to ensure the compiler strictly treated it as text before running the ASCII comparison |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspStringCompare`](./@HspStringCompare.md) | The legacy Hyperion Planning specific version of this function, though they perform almost exactly the same task |
| [`@CalcMgrCompare`](./@CalcMgrCompare.md) | The modern Java equivalent. It is vastly superior because it allows you to explicitly toggle case-sensitivity, bypassing the uppercase/lowercase ASCII nightmare |
| [`@NAME`](./@NAME.md) | Casts a structural member into a text string |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MBRCOMPARE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/mbrcompare.html)
