# @ISRANGENONEMPTY

## Overview

`@ISRANGENONEMPTY` is a **native Essbase boolean array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates an entire array (or range) of members and returns `TRUE` if **at least one** block in that range contains real, non-missing data. It returns `FALSE` only if the entire range is completely empty (`#MISSING`).

### Why Does This Function Exist—

When building calculation scripts that execute massive top-down allocations or complex spreading logic, performance is everything. The slowest operation in Essbase is calculating blocks that don't need to be calculated.
If a script allocates `"Corporate_Overhead"` down to 500 stores, but only 3 of those stores actually have `"Direct_Expenses"` (the allocation driver), the script will waste immense time running math against 497 empty stores, generating thousands of `#MISSING` blocks.
Natively, you can check `IF("Direct_Expenses" != #MISSING)`, but that only works on a single cell. What if you need to know if the *entire Year* is empty before bothering to run a Year-To-Date formula— Or if an entire Region is empty before running a consolidation—
`@ISRANGENONEMPTY` solves this. You pass it a range (e.g., `Jan:Dec`, or `@CHILDREN("East_Region")`), and it performs a rapid block-scan. If it finds even a single valid number anywhere in that array, it returns `TRUE`, allowing the heavy mathematical logic to proceed.

### When to Use It

- **Allocation Bypasses**: Skipping complex top-down allocations for any Regions that have absolutely zero "Driver" data, drastically reducing calculation times.
- **Time-Series Triggers**: Preventing Year-To-Date or Moving Average scripts from executing if a project has not yet incurred a single dollar of historical spend.
- **Dynamic Block Creation**: Wrapping dense formula assignments inside this check to prevent Essbase from accidentally creating millions of empty blocks during sparse calculations.

---

## Category

**Boolean & Conditional / Array Processing / Essbase Native Functions**

---

## Syntax

```essbase
@ISRANGENONEMPTY(MemberRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MemberRange` | Member List | ✅ Yes | The array of members to scan for data. This can be a cross-dimensional tuple, a time range (e.g., `"Jan":"Dec"`), or a hierarchy function (e.g., `@CHILDREN("Total_Year")`). |

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the specified range contains **at least one cell** that has a valid numeric value (including `0`). 
Returns `FALSE` (0) if, and only if, **every single cell** in the specified range is `#MISSING`.
- **Zero is Data**: Be extremely careful: `0` is a real number. If a store has `$0` in sales, that cell is NOT empty. `@ISRANGENONEMPTY` will see the zero and return `TRUE`. It only returns `FALSE` for true `#MISSING` (null) states.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine hits the `IF(@ISRANGENONEMPTY(...))` block.
2. **Range Assembly**: It compiles the requested array of blocks based on the parameter.
3. **Optimized Scan**: It sweeps through the array. It does NOT do math; it simply checks the index metadata for block existence.
4. **Early Termination**: The instant it finds a block with data (even if it's the very first block), it immediately stops scanning and returns `TRUE`.
5. **Fail State**: If it reaches the absolute end of the array and every single block was `#MISSING`, it returns `FALSE`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking a Time Range

```essbase
/* 
   If Jan, Feb, or Mar has ANY data, it returns TRUE. 
   If Q1 is entirely empty, it returns FALSE.
*/
IF(@ISRANGENONEMPTY("Jan":"Mar"))
```

### Variant 2: Cross-Dimensional Range Check

```essbase
/* 
   Checks if the "Sales" account across all descendants of "East" has data.
*/
IF(@ISRANGENONEMPTY("Sales"->@DESCENDANTS("East")))
```

---

## Practical Examples

### Example 1: Bypassing Empty Project Allocations

**Scenario**: A massive CapEx script allocates `"IT_Support_Costs"` to 10,000 distinct Projects. The allocation driver is `"Direct_Labor"`. However, only 150 projects actually have Direct Labor in the current forecast. If the script runs blindly, it will create 9,850 empty allocation blocks, causing the database to explode in size. The script uses `@ISRANGENONEMPTY` to check the entire year for labor before executing the math.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    /* 
       1. For the current project, check if there is ANY Direct Labor 
       recorded anywhere between January and December.
    */
    IF(@ISRANGENONEMPTY("Direct_Labor"->"Jan":"Dec"))
        
        /* 
           2. Because the range is NOT empty (it returned TRUE),
           it is safe to execute the complex allocation.
        */
        "Allocated_IT" = "IT_Pool"->"No_Project" * ("Direct_Labor" / "Total_Labor"->"No_Project");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Confusing `0` with `#MISSING` | Returning TRUE unexpectedly | As mentioned, `0` is a valid block state in Essbase. If an administrator runs a clear script that writes `0` instead of `#MISSING` (`CLEARBLOCK` vs `"Account" = 0`), this function will treat those blocks as full of data. If you need to treat `0` as empty, you cannot use this function; you must write a custom `@SUM` or `@MAX` check |
| Using it to find specific values | `IF(@ISRANGENONEMPTY("Target") == 5)` | This is a boolean function. It strictly returns `1` (TRUE) or `0` (FALSE). It does not return the actual data inside the range. If you need to pull data from a range, use `@MAX` or `@AVG` |
| Over-Broad Ranges | Scanning the entire database | Do not pass `@DESCENDANTS("Total_Entity")` into this function unless strictly necessary. If you ask Essbase to scan 50,000 entities for every single step of a calculation, the scanning overhead will outweigh the time saved by skipping the empty blocks. Use it surgically on Time ranges or small sibling groups |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@COUNT`](../06_Mathematical/@COUNT.md) | Counts exactly *how many* cells in a range have data. (Often used with the `SKIPMISSING` flag to achieve similar bypass logic) |
| [`@ISMBR`](./@ISMBR.md) | Checks if you are currently sitting on a specific member, rather than checking if that member has data inside it |
| [`@CREATEBLOCK`](../15_CalcMgr_Utility/@CREATEBLOCK.md) | The function used when you actually *want* to force empty blocks into existence (the exact opposite of bypass logic) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISRANGENONEMPTY](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/israngenonempty.html)
