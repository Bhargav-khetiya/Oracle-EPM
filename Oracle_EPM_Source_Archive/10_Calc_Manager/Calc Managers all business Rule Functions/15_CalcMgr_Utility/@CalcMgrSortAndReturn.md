# @CalcMgrSortAndReturn

## Overview

`@CalcMgrSortAndReturn` is a **custom Calc Manager array processing function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an advanced, one-step array sorter and extractor. It takes a dynamic array of numbers, **sorts them numerically** in memory (Ascending or Descending), and immediately **returns the specific value sitting at a requested index position** of that newly sorted array.

### Why Does This Function Exist—

When building complex financial logic, administrators often need to find specific statistical data points within a historical trend. For example: "What was the 3rd highest revenue month this year—
If you use standard Essbase logic, finding the 3rd highest number is nearly impossible. You would have to write massive, chained comparison loops (`IF Jan > Feb AND Jan > Mar...`). 
`@CalcMgrSortAndReturn` entirely automates this. You simply pass it the array of the 12 months, tell it to sort Descending (highest to lowest), and ask for the value at Index `2` (the 3rd item). The Java engine handles all the complex array sorting in a fraction of a millisecond, returning the exact number you requested, allowing you to instantly build advanced tiered-pricing or risk-modeling algorithms.

### When to Use It

- **Tiered Performance Metrics**: Finding the 2nd lowest performing product in a category by sorting Ascending and grabbing the value at Index `1`.
- **Top-N Allocations**: Distributing bonus pools only to the 3rd highest salesperson in a region.
- **Statistical Outlier Removal**: Sorting an array of 12 months of expenses, ignoring Index `0` (the highest anomaly), and grabbing Index `1` to establish a normalized run-rate.

---

## Category

**Arrays & Lists / Sorting & Extraction / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrSortAndReturn(numericList, sort_order, index)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numericList` | Array/List | ✅ Yes | The array of numeric values to be sorted (e.g., `@CHILDREN("YearTotal")`). |
| `sort_order` | Numeric | ✅ Yes | `1` = Ascending (Lowest to Highest). <br>`0` = Descending (Highest to Lowest). |
| `index` | Numeric | ✅ Yes | The exact position in the *sorted* array you want to extract. <br>**CRITICAL**: This is a **0-indexed** position. The very first item is `0`. |

---

## Return Value

**Return Type**: Numeric

Returns the exact numeric value sitting at the requested index position of the newly sorted array.
- E.g., If the array is `[10, 50, 20]`, sorted Descending (`0`), it becomes `[50, 20, 10]`. Asking for index `1` returns `20`.
- **Missing Data Handling**: If the index requested is completely out of bounds (e.g., asking for index `15` on a 12-item array), the function will return `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine streams the raw array data.
2. **Array Construction**: It builds a Java `ArrayList` in memory, collapsing and normalizing the data structure.
3. **Sorting Engine**: It executes `Collections.sort()` against the array. 
   - If `1` (Ascending), it sorts normally.
   - If `0` (Descending), it applies `Collections.reverseOrder()`.
4. **Index Extraction**: It goes to the requested index position (`Array[index]`) and pulls the value.
5. **Return**: Passes the finalized value back to Essbase for immediate calculation.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the 2nd Highest Value

```essbase
/* 
   Sorts the children of Total_Products Descending (Highest to Lowest).
   Extracts Index 1 (the 2nd item in the list).
*/
VAR vSecondHighest = @CalcMgrSortAndReturn("Revenue"->@CHILDREN("Total_Products"), 0, 1);
```

---

## Practical Examples

### Example 1: Calculating the 3rd Highest Month of the Year

**Scenario**: A commission calculation script requires the administrator to find the 3rd highest sales month of the year to establish a baseline quota for next year. Instead of writing complex `IF` blocks to compare all 12 months, the administrator uses `SortAndReturn` to isolate the exact value instantly.

```essbase
FIX("FY25", "Working", @LEVEL0("Employees"))
    
    IF("Total_Sales" > 0)
        
        /* 
           1. Pass the 12 months of sales into the array.
           2. Sort Descending (0), so January-December are reordered Highest to Lowest.
           3. Extract Index 2 (Because Java is 0-indexed, Index 2 = the 3rd item).
        */
        VAR vThirdHighestMonth = @CalcMgrSortAndReturn(
            "Total_Sales"->@CHILDREN("YearTotal"), 
            0, 
            2
        );
        
        /* 
           4. Set the quota for next year based on that 3rd highest month 
           (adding a 10% stretch target).
        */
        "Next_Year_Quota" = vThirdHighestMonth * 1.10;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding 0-Indexing | Passing `index=3` to find the 3rd highest | This is the most common error. The array is strictly **0-indexed**. The highest number (Index 1st) is at position `0`. The 2nd highest is at position `1`. The 3rd highest is at position `2`. Always subtract 1 from your human-readable positional logic |
| Sorting Ascending by Mistake | Using `1` when looking for Top Performers | If you use `1` (Ascending), the array is sorted Lowest to Highest. If you then ask for index `0`, you are pulling the absolutely *worst* performing month. To find Top Performers, you must always use `0` (Descending) |
| Assuming it Maps Back to Members | Trying to find *which* month was highest | `SortAndReturn` ONLY returns the numerical value (e.g., `$50,000`). It completely destroys the relationship between the number and the month name during the sort. It cannot tell you that `"March"` was the highest month. If you need to know the member name, you must use complex `@CalcMgrIndexOf` cross-matching or custom Java logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrSortList`](./@CalcMgrSortList.md) | Returns the entire sorted array back into memory, rather than extracting just a single value |
| [`@CalcMgrSortValues`](./@CalcMgrSortValues.md) | Functionally identical to `SortList` (an alias used for full array sorting) |
| [`@CalcMgrGetListItem`](./@CalcMgrGetListItem.md) | Extracts a value at an index position, but from the raw, *unsorted* array |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_sortandreturn.html)
