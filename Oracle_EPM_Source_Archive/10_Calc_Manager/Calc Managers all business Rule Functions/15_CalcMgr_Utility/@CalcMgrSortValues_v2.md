# @CalcMgrSortValues

## Overview

`@CalcMgrSortValues` is a **custom Calc Manager array processing function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a dynamic array of numbers, **sorts them numerically** in memory (Ascending or Descending), and returns the **entire sorted array** back into the calculation script. 
*(Note: This function is functionally identical to `@CalcMgrSortList`. It exists as an alternative alias to align with other value-centric naming conventions in the Calc Manager library).*

### Why Does This Function Exist?

When analyzing historical data arrays—such as 12 months of sales, 5 years of expenses, or 100 regional performance metrics—the data is naturally stored chronologically or alphabetically based on the Essbase outline. 
If an administrator needs to execute Top-N tiering logic (e.g., applying a 5% bonus to the Top 3 regions, and a 1% bonus to the rest), they cannot process the array chronologically. 
`@CalcMgrSortValues` performs the necessary structural transformation. It takes the messy array, sorts it flawlessly in memory (e.g., Highest to Lowest), and returns the entire ordered list. You can then pass this sorted array into secondary extraction loops or statistical macros, enabling deep programmatic analysis inside standard Essbase rules.

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
@CalcMgrSortValues(numericList, sort_order)
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
- **CRITICAL**: Because this function returns an Array (a List), it CANNOT be saved directly into a standard Essbase numeric account cell, nor can it be used in basic arithmetic (e.g., `Value = Array * 2` will fail). It must be passed as an argument into *other* array-processing functions.

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

### Variant 1: Preparing an Array for Analysis (Descending)

```essbase
/* 
   Sorts the 12 months Descending (Highest to Lowest).
   The resulting list can now be passed to other extraction functions.
*/
VAR vSortedArray = @CalcMgrSortValues("Total_Sales"->@CHILDREN("YearTotal"), 0);
```

---

## Practical Examples

### Example 1: Calculating the Average of the Top 3 Months

**Scenario**: A retail company calculates baseline inventory quotas based on their absolute peak performance. They want to average only the Top 3 highest sales months of the year, completely ignoring the other 9 months. The script must sort the array, extract the first 3 indexes, and average them.

```essbase
FIX("FY25", "Working", @LEVEL0("Inventory"))
    
    IF("Total_Sales" != #MISSING)
        
        /* 
           1. Create the sorted array in memory. 
           Order: Descending (0) (Highest to Lowest).
        */
        VAR vSortedArray = @CalcMgrSortValues("Total_Sales"->@CHILDREN("YearTotal"), 0);
        
        /* 
           2. Extract the Top 3 values.
           (Because it's Descending, Index 0 is the absolute highest).
        */
        VAR vTop1 = @CalcMgrGetListItem(vSortedArray, 0);
        VAR vTop2 = @CalcMgrGetListItem(vSortedArray, 1);
        VAR vTop3 = @CalcMgrGetListItem(vSortedArray, 2);
        
        /* 
           3. Calculate the Peak Average.
        */
        "Peak_Sales_Average" = (vTop1 + vTop2 + vTop3) / 3;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Direct Arithmetic | `"Target" = @CalcMgrSortValues(...)` | You cannot assign the output of this function to a database cell. It is an Array (a List of multiple numbers). Essbase cells can only hold one number at a time. If you try to save it, the script will throw a Type Mismatch error. You must wrap the output in an extraction function (like `@CalcMgrGetListItem`) or an aggregation function |
| Misunderstanding Missing Data | Sorting arrays with `#MISSING` | The Java sorting engine usually pushes `#MISSING` (null/zero) values to the bottom of the array if sorting Descending, or to the top if sorting Ascending. This can severely corrupt positional extraction logic (e.g., Index 0 might just be `#MISSING` instead of the lowest real number). Always ensure you understand how your specific EPM version handles nulls during sorts |
| Destroying Member Relationships | Looking for "Which" month was highest | `SortValues` only sorts the raw *Numbers*. It completely destroys the relationship to the dimensional members. It cannot tell you that `"Jan"` is now at Index 0. It only knows that the number `50,000` is at Index 0 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrSortList`](./@CalcMgrSortList.md) | Functionally identical. It is literally an alias for `SortValues` |
| [`@CalcMgrSortAndReturn`](./@CalcMgrSortAndReturn.md) | Sorts the array and automatically extracts a single index value in one step, rather than returning the entire array |
| [`@CalcMgrGetListItem`](../11_Date_Time/@CalcMgrGetListItem.md) | Used to extract specific values out of the array after `SortValues` has finished sorting it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_sortvalues.html)
