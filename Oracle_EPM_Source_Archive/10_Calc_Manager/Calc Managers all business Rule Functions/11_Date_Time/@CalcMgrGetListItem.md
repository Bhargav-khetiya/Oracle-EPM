# @CalcMgrGetListItem

## Overview

`@CalcMgrGetListItem` is a **custom Calc Manager array processing function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an array-extraction tool. You pass it an array of data points and a specific **index number**, and it reaches into the array, instantly grabbing and returning the exact value residing at that specific position.

### Why Does This Function Exist?

Standard Essbase calculates numbers perfectly, but it natively struggles with true "Array Indexing" (the ability to say: "Give me the 4th item in this list"). 
If a supply chain model needs to evaluate the trailing 6 months of sales and pull exactly the sales volume from the "3rd month back" to use as a baseline, writing that logic using standard `@PRIOR` or `IF` statements is clunky and rigid.
`@CalcMgrGetListItem` solves this by streaming the data into Java memory as a perfect 0-indexed array. By feeding it a dynamic index variable (e.g., `vTargetIndex`), the function instantly returns the exact value at that location, allowing for advanced modular looping, dynamic lookups, and algorithmic data processing directly inside an Essbase script.

### When to Use It

- **Dynamic Lookups**: Using a calculated integer (like "Month_Index") to instantly pull the corresponding historical exchange rate from a 12-item array.
- **Custom Looping**: Paired with `@CalcMgrGetListCount`, you can write custom Java loops that iterate through an array, processing items one by one.
- **Percentile Tracking**: Extracting the median or quartile boundary value after sorting an array.

---

## Category

**Arrays & Lists / Data Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetListItem(numericList, index, skipMissing)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numericList` | Array/List | ✅ Yes | The array of numeric values to be evaluated (e.g., `@CHILDREN("All_Products")`). |
| `index` | Numeric | ✅ Yes | The exact position in the array to extract. <br>**CRITICAL**: This is a **0-indexed** position. The first item in the list is `0`, the second is `1`. |
| `skipMissing` | Boolean | ✅ Yes | Determines how the array is built before the index is applied. <br>`true` = Drops all `#MISSING` data *before* assigning index numbers. <br>`false` = Preserves `#MISSING` data, meaning index `2` might return `#MISSING`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the specific numeric value residing at the requested index.
- If the `index` provided is larger than the size of the array, the function throws an Index Out of Bounds error and returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine streams the raw array data.
2. **Array Construction**: 
   - If `skipMissing == false`, it builds the array exactly as it appears in Essbase. (e.g., `[100, #MISSING, 200]`).
   - If `skipMissing == true`, it filters the data dynamically, collapsing the array. (e.g., `[100, 200]`).
3. **Index Retrieval**: It accesses the Java array at the precise index requested (`Array[index]`).
4. **Return**: Passes the resulting value back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting the 3rd Item (Preserving Structure)

```essbase
/* 
   We want the 3rd month (Index 2). 
   By passing 'false', we ensure the index numbers permanently map to the 
   calendar layout, even if Jan or Feb were empty. 
*/
"Third_Month_Value" = @CalcMgrGetListItem(@CHILDREN("YearTotal"), 2, false);
```

### Variant 2: Extracting the 1st Valid Item

```essbase
/* 
   We want the FIRST month that actually has data (Index 0). 
   By passing 'true', the array collapses, ensuring Index 0 is the first valid number. 
*/
"First_Valid_Data_Point" = @CalcMgrGetListItem(@CHILDREN("YearTotal"), 0, true);
```

---

## Practical Examples

### Example 1: Dynamic Rate Lookups

**Scenario**: A corporate allocations model applies a "Seasonality Multiplier" to a flat baseline budget. The 12 multipliers are stored in January through December. The script is currently calculating "October" (Month Index = 9). Instead of writing 12 IF statements, the script dynamically pulls the 10th item from the multiplier array using the index `9`.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    /* Iterate through the forecast months */
    FIX(@IDESCENDANTS("YearTotal"))
        
        /* 
           1. Assume we have a dynamic variable 'vMonthIndex' that knows what 
           month we are currently calculating (e.g., Oct = 9).
        */
        
        /* 
           2. Dynamically extract the multiplier from the 12-item array using the index.
           We pass 'false' to ensure the array doesn't collapse if a month is empty.
        */
        VAR vMultiplier = @CalcMgrGetListItem(
            "Seasonality_Multipliers"->@CHILDREN("YearTotal"), 
            vMonthIndex, 
            false
        );
        
        /* 3. Apply the multiplier to the budget */
        "Calculated_Budget" = "Baseline_Run_Rate" * vMultiplier;
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding 0-Indexing | Asking for the 1st item with `index=1` | This is a Java-backed function, so it is strictly **0-indexed**. The very first item in the list is `0`. The second is `1`. If you ask for `1` hoping to get January, you will get February. Always subtract 1 from human-readable logic |
| Array Collapse (SkipMissing) | Passing `true` when pulling by Month | If you have 12 months, and you want June (Index 5), you MUST set `skipMissing` to `false`. If you set it to `true`, and January happens to be `#MISSING`, the array will collapse. February will become Index 0, March Index 1, and June will suddenly become Index 4. The `true` flag is incredibly dangerous when positional structure is required |
| Index Out of Bounds | Requesting Index `15` on a 12-item list | If you request an index that doesn't exist, the function fails and returns `#MISSING`. Always ensure your index variable is mathematically constrained |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetListCount`](./@CalcMgrGetListCount.md) | Used to find the absolute total size of the list, ensuring you never pass an `index` that is out of bounds |
| [`@CalcMgrExcelSMALL`](./@CalcMgrExcelSMALL.md) | Instead of returning the item at a specific *position*, it sorts the list and returns the k-th *smallest* item |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getlistitem.html)
