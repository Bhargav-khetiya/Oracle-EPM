# @CalcMgrIsInList

## Overview

`@CalcMgrIsInList` is a **custom Calc Manager boolean search function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a dynamic array interrogation tool. It scans a provided array of numbers and checks if a **specific target value** exists *anywhere* within that array, returning a Boolean (`true` or `false`).

### Why Does This Function Exist—

When building dynamic logic, administrators often need to check if a specific condition has occurred historically. For example, "Did this product *ever* have negative sales in the last 12 months— 
In standard Essbase, you would have to write a massive, chained IF statement: `IF("Jan" < 0 OR "Feb" < 0 OR "Mar" < 0...)`. This is rigid, hard to read, and breaks if the number of periods changes.
`@CalcMgrIsInList` entirely eliminates this clunky logic. You can pass it an entire dynamic array (e.g., `@CHILDREN("YearTotal")`) and a target value (or use it in conjunction with other functions to detect specific triggers). It scans the entire array in memory and instantly returns `true` if the condition is met, drastically simplifying your code.

### When to Use It

- **Trigger Detection**: Checking if a specific error code (e.g., `-99`) was recorded anywhere across a 12-month array of status flags.
- **Historical Overrides**: Validating if a user applied a manual override flag (e.g., `1`) to any of the specific product lines within a product category array.
- **Smart Allocations**: Only executing a corporate overhead allocation to a region if that region's subsidiary array contains at least one active factory identifier.

---

## Category

**Arrays & Lists / Logic & Validation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrIsInList(numericList, targetValue)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numericList` | Array/List | ✅ Yes | The array of numeric values to be scanned (e.g., `@CHILDREN("All_Products")`). |
| `targetValue` | Numeric | ✅ Yes | The specific number you are looking for. |

---

## Return Value

**Return Type**: Boolean (`true` or `false`)

Returns `true` (evaluates to `1` in Essbase IF statements) if the `targetValue` is found at least once in the array.
Returns `false` (`0`) if the value is not found anywhere in the array.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine streams the array of data points and captures the target value.
2. **Evaluation Loop**: It initiates a rapid scan across the array indices.
3. **Equality Check**: It executes a strict equality check (`Array[i] == targetValue`).
4. **Short-Circuit Return**: The moment it finds a match, it halts the scan (optimizing performance) and returns `true`. If it reaches the end of the array without a match, it returns `false`.

---

## Syntax Variants & Scenarios

### Variant 1: Scanning for a specific Error Flag

```essbase
/* 
   Scans the 12 months for the value -99. 
   If found anywhere, it returns true (1). 
*/
IF(@CalcMgrIsInList(@CHILDREN("YearTotal"), -99))
    "Error_Detected" = 1;
ENDIF
```

---

## Practical Examples

### Example 1: Bypassing Allocations Based on Manual Overrides

**Scenario**: A corporate expense allocation distributes IT costs across 5 subsidiary departments (`Dept_1` through `Dept_5`). However, department managers can input a `1` into the `"Manual_Override_Flag"` account if they want to freeze their allocations. The script must scan the 5 departments. If ANY department has an override flag (`1`), the script must abort the allocation for the entire region to prevent imbalances.

```essbase
FIX("FY25", "Working", @LEVEL0("Regions"))
    
    /* 
       1. Check if the Override Flag exists anywhere in the array of Departments.
       We scan the children of Total_Departments looking for the exact value '1'.
    */
    VAR vOverrideExists = @CalcMgrIsInList(
        "Manual_Override_Flag"->@CHILDREN("Total_Departments"), 
        1
    );
    
    /* 
       2. Evaluate the result.
       If true, we skip the allocation. If false, we proceed.
    */
    IF(vOverrideExists)
        
        "Allocation_Status" = -99; /* Mark as manually locked */
        
    ELSE
        
        /* Execute the standard allocation logic for all departments */
        FIX(@CHILDREN("Total_Departments"))
            "Allocated_IT_Expense" = "Total_IT_Expense" * "Headcount_Pct";
        ENDFIX
        
        "Allocation_Status" = 1; /* Mark as successful */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Floating Point Imprecision | Searching for `14.95` | If your array contains `14.9500000000001` (due to floating point math drift) and you search for exactly `14.95`, `IsInList` uses strict equality (`==`). It will not find a match and will return `false`. Always round your array data, or search for clean integers (like flags `1` or `0`) when using exact-match array scanners |
| Searching for Missing | `@CalcMgrIsInList(..., #MISSING)` | You cannot safely search for `#MISSING` using this function. The Java array engine often treats `#MISSING` as a structural void rather than a comparable value, or occasionally casts it to `0`. If you need to know if an array has missing data, use `@CalcMgrGetListCount(..., true)` and compare it to `@CalcMgrGetListCount(..., false)` |
| Confusing with Count | Expecting it to say *how many times* it found the value | This is a strict Boolean scanner. If the value `-99` exists 5 times in the array, it will still just return `true` (or `1`). It does not count occurrences |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetListItem`](../11_Date_Time/@CalcMgrGetListItem.md) | Extracts the specific value located at a known index position within the array |
| [`@CalcMgrGetListCount`](../11_Date_Time/@CalcMgrGetListCount.md) | Counts the total number of items in the array |
| [`@CalcMgrIndexOf`](../10_String/@CalcMgrIndexOf.md) | The string equivalent of this function (used to find if a substring exists within a larger string) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_isinlist.html)
