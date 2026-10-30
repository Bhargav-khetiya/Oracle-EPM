# @CalcMgrIsListItem

## Overview

`@CalcMgrIsListItem` is a **custom Calc Manager array processing function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an exact positional interrogation tool. You pass it a numeric array, a specific **index number**, and a **target value**, and it checks if that exact target value resides at that exact index position in the array.

### Why Does This Function Exist?

While `@CalcMgrIsInList` scans the entire array to see if a value exists *anywhere*, it cannot tell you *where* it is. Conversely, while `@CalcMgrGetListItem` pulls whatever value is sitting at a specific index, it requires you to write a separate `IF` statement to evaluate it.
Sometimes, business logic requires checking a specific spatial condition in a single line of code. For example, "Is the very first month of this forecast exactly zero?" or "Did the 3rd product in this category trigger an error?"
`@CalcMgrIsListItem` bridges this gap. It goes directly to the specified index in the Java array memory space and performs a strict Boolean equality check against your target value. It returns `true` if they match perfectly, and `false` if they don't (or if the index doesn't exist), allowing you to write highly compressed, readable IF statements.

### When to Use It

- **Positional Validation**: Verifying that the *first* item (Index 0) in an array contains a specific baseline initialization flag.
- **Sequential Error Checking**: Iterating through an array with a `FOR` loop, checking each exact position sequentially to see if it equals `-99`.
- **Targeted Trigger Detection**: Specifically monitoring the final item in a dynamic list (e.g., Q4) to see if it hit a target threshold, ignoring the rest of the year.

---

## Category

**Arrays & Lists / Logic & Validation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrIsListItem(numericList, index, targetValue, skipMissing)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numericList` | Array/List | ✅ Yes | The array of numeric values to be evaluated (e.g., `@CHILDREN("All_Products")`). |
| `index` | Numeric | ✅ Yes | The exact position in the array to check. <br>**CRITICAL**: This is a **0-indexed** position. The first item is `0`. |
| `targetValue` | Numeric | ✅ Yes | The exact number you are hoping to find at that position. |
| `skipMissing` | Boolean | ✅ Yes | Determines how the array is built before checking the index. <br>`true` = Drops all `#MISSING` data *before* mapping the index. <br>`false` = Preserves the exact structural mapping. |

---

## Return Value

**Return Type**: Boolean (`true` or `false`)

Returns `true` (evaluates to `1`) if the value sitting exactly at `index` is mathematically equal to `targetValue`.
Returns `false` (`0`) if the values do not match, or if the `index` provided is out of bounds.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine streams the raw array data.
2. **Array Construction**: 
   - If `skipMissing == false`, it builds the array exactly as it appears in Essbase.
   - If `skipMissing == true`, it filters the data, collapsing the array structure.
3. **Index Access**: It accesses the Java array at the requested index (`Array[index]`). If the index is larger than the array, it returns `false`.
4. **Equality Check**: It executes a strict check (`Array[index] == targetValue`).
5. **Return**: Passes the Boolean result back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Checking the First Valid Item

```essbase
/* 
   Checks if the FIRST month that actually has data (Index 0, skipMissing=true) 
   is exactly equal to 0. 
*/
IF(@CalcMgrIsListItem(@CHILDREN("YearTotal"), 0, 0, true))
    "Starting_Balance" = "Default_Balance";
ENDIF
```

---

## Practical Examples

### Example 1: Q1 Baseline Validation

**Scenario**: A dynamic forecasting model relies on January being the baseline. If a user manually overrides January to exactly `-99`, the script must detect that specific override and wipe the rest of the year. The script shouldn't wipe the year if they put `-99` in March. It only cares about the very first month (Index 0).

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* 
       1. Check if the FIRST month (Index 0) is exactly -99.
       We pass 'false' to skipMissing to ensure Index 0 is strictly January,
       even if January happens to be #MISSING.
    */
    VAR vIsOverrideTriggered = @CalcMgrIsListItem(
        "Forecast"->@CHILDREN("YearTotal"), 
        0, 
        -99, 
        false
    );
    
    /* 
       2. If true, wipe the entire year.
    */
    IF(vIsOverrideTriggered)
        
        FIX(@CHILDREN("YearTotal"))
            "Forecast" = #MISSING;
        ENDFIX
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding 0-Indexing | Passing `index=1` for January | Like all Java-backed list functions, this is strictly **0-indexed**. The very first item is `0`. If you ask for `1` hoping to check January, you are actually checking February. Always subtract 1 from human-readable positional logic |
| Floating Point Equality | Searching for `14.95` | If the value at the index is `14.9500000000001` (due to floating point math drift) and you pass exactly `14.95` as your target, it uses strict equality (`==`) and returns `false`. Always ensure your target and your array data are rounded, or search for integer flags (like `1` or `0`) |
| Array Collapse (SkipMissing) | Passing `true` when checking positional logic | If you have 12 months, and you want to check June (Index 5), you MUST set `skipMissing` to `false`. If you set it to `true`, and January is `#MISSING`, the array will collapse. June will suddenly become Index 4, and your check will evaluate July's data by mistake |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetListItem`](../11_Date_Time/@CalcMgrGetListItem.md) | Extracts the actual value at the index, rather than just returning a true/false boolean |
| [`@CalcMgrIsInList`](./@CalcMgrIsInList.md) | Checks if the target value exists *anywhere* in the list, rather than checking a specific index position |
| [`@CalcMgrGetListCount`](../11_Date_Time/@CalcMgrGetListCount.md) | Used to find the absolute total size of the list, ensuring you know how many indexes are available |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_islistitem.html)
