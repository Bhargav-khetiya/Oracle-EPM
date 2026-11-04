# @CalcMgrSortList

## Overview

`@CalcMgrSortList` is a **custom Calc Manager array processing function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a dynamic array of numbers, **sorts them numerically** in memory (Ascending or Descending), and returns the **entire sorted array** back into the calculation script. 

### Why Does This Function Exist—

While `@CalcMgrSortAndReturn` is excellent for grabbing a single value (like the 3rd highest month), many advanced statistical models require operating on an entire dataset in order of magnitude, rather than chronologically. 
For example, if you want to calculate the median (the true middle value) of a 12-month array, you cannot just grab Index 6 chronologically. You must first sort the array from lowest to highest, and *then* grab the middle values. 
`@CalcMgrSortList` performs this structural transformation. It takes a messy, chronological array (like Jan-Dec sales), sorts it perfectly in memory, and returns that sorted array list. You can then pass this sorted array directly into statistical functions (like Medians, Percentiles, or Trimmed Means), unlocking massive analytical power within standard Essbase calculations.

### When to Use It

- **Statistical Pre-Processing**: Sorting an array Ascending before passing it into a custom median or quartile calculation macro.
- **Top-N Loop Processing**: Sorting an array of 100 products Descending, and then using a custom `FOR` loop to only process the first 10 items (the Top 10 products).
- **Outlier Trimming**: Sorting an array, and then safely dropping the first two items (lowest) and the last two items (highest) to calculate a normalized Trimmed Mean.

---

## Category

**Arrays & Lists / Structural Modification / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrSortList(numericList, sort_order)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numericList` | Array/List | ✅ Yes | The array of numeric values to be sorted (e.g., `@CHILDREN("All_Products")`). |
| `sort_order` | Numeric | ✅ Yes | `1` = Ascending (Lowest to Highest). <br>`0` = Descending (Highest to Lowest). |

---

## Return Value

**Return Type**: Array (Numeric List)

Returns a newly constructed array list containing the exact same numbers, but strictly ordered.
- **CRITICAL**: Because this function returns an Array (a List), it CANNOT be saved directly into a standard Essbase numeric account cell, nor can it be used in basic arithmetic (e.g., `Value = Array * 2` will fail). It must be passed as an argument into *other* array-processing functions (like `@SUM`, `@CalcMgrGetListItem`, or `@CalcMgrGetMedian`).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine streams the raw array data.
2. **Array Construction**: It builds a Java `ArrayList` in memory, collapsing the Essbase block structure.
3. **Sorting Engine**: It executes `Collections.sort()` against the array. 
   - If `1` (Ascending), it sorts normally.
   - If `0` (Descending), it applies `Collections.reverseOrder()`.
4. **Return**: It returns the entire sorted `ArrayList` object back to Essbase, where it resides temporarily in memory.

---

## Syntax Variants & Scenarios

### Variant 1: Preparing an Array for Analysis

```essbase
/* 
   Sorts the 12 months Ascending (Lowest to Highest).
   The resulting list can now be passed to other functions.
*/
VAR vSortedArray = @CalcMgrSortList("Total_Sales"->@CHILDREN("YearTotal"), 1);
```

---

## Practical Examples

### Example 1: Dynamic Median Calculation (Manual Array Tracing)

**Scenario**: A script needs to calculate the Median sales value across 12 months. (While `@CalcMgrGetMedian` exists, this example demonstrates how you can manually manipulate sorted arrays for custom statistics). To find the median manually, the script must sort the array Ascending, find the exact middle indexes (Index 5 and Index 6), and average them.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    IF("Total_Sales" != #MISSING)
        
        /* 
           1. Create the sorted array in memory. 
           Order: Ascending (1) (Lowest to Highest).
        */
        VAR vSortedArray = @CalcMgrSortList("Total_Sales"->@CHILDREN("YearTotal"), 1);
        
        /* 
           2. Extract the middle values.
           Because there are 12 items (even number), the median is the average 
           of the two middle items (Index 5 and Index 6).
        */
        VAR vMiddle1 = @CalcMgrGetListItem(vSortedArray, 5);
        VAR vMiddle2 = @CalcMgrGetListItem(vSortedArray, 6);
        
        /* 
           3. Calculate the exact median.
        */
        "Median_Sales" = (vMiddle1 + vMiddle2) / 2;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Direct Arithmetic | `"Target" = @CalcMgrSortList(...)` | You cannot assign the output of this function to a database cell. It is an Array (a List of multiple numbers). Essbase cells can only hold one number at a time. If you try to save it, the script will throw a Type Mismatch error. You must wrap the output in an extraction function (like `@CalcMgrGetListItem`) or an aggregation function |
| Misunderstanding Missing Data | Sorting arrays with `#MISSING` | The Java sorting engine usually pushes `#MISSING` (null/zero) values to the bottom of the array if sorting Descending, or to the top if sorting Ascending. This can severely corrupt positional extraction logic (e.g., Index 0 might just be `#MISSING` instead of the lowest real number). Always ensure you understand how your specific EPM version handles nulls during sorts |
| Destroying Member Relationships | Looking for "Which" month was highest | `SortList` only sorts the raw *Numbers*. It completely destroys the relationship to the dimensional members. It cannot tell you that `"Jan"` is now at Index 11. It only knows that the number `50,000` is at Index 11 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrSortValues`](./@CalcMgrSortValues.md) | Functionally identical. It is literally an alias for `SortList` |
| [`@CalcMgrSortAndReturn`](./@CalcMgrSortAndReturn.md) | Sorts the array and automatically extracts a single index value in one step, rather than returning the entire array |
| [`@CalcMgrGetListItem`](../11_Date_Time/@CalcMgrGetListItem.md) | Used to extract specific values out of the array after `SortList` has finished sorting it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_sortlist.html)
