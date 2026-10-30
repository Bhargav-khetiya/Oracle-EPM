# @CalcMgrGetListCount

## Overview

`@CalcMgrGetListCount` is a **custom Calc Manager array/list processing function** in Oracle EPM Cloud (PBCS/EPBCS). It analyzes a standard Essbase numeric array or list and dynamically calculates exactly **how many total items** exist within that list.

### Why Does This Function Exist?

When processing dynamic cross-dimensional ranges in Essbase (like `@CHILDREN("Forecast_Months")`), the exact number of items in that list can change based on the outline structure or the specific context of the calculation block. 
If you are attempting to write a custom loop, calculate an average, or build a statistical variance array, you must know exactly what your denominator (`N`) is. While Essbase has native aggregate functions like `@AVG`, it historically lacked a clean way to simply count the number of valid items in a dynamic array and store that count in a variable. 
`@CalcMgrGetListCount` resolves this perfectly. It ingests the array, filters out invalid or `#MISSING` data points depending on your configuration, and returns a pure integer representing the exact size of the dataset.

### When to Use It

- **Custom Averaging**: Calculating a dynamic denominator when building custom weighting logic across a variable number of months.
- **Loop Bounds**: Determining the exact `Max_Index` to feed into a custom Java `@CalcMgr` FOR-loop.
- **Data Validation**: Counting how many children under a specific Cost Center actually have active expense data before executing an allocation.

---

## Category

**Arrays & Lists / Mathematical / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetListCount(numericList, skipMissing)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `numericList` | Array/List | ✅ Yes | The array of numeric values to be counted (e.g., `@CHILDREN("All_Products")`). |
| `skipMissing` | Boolean | ✅ Yes | Determines how to handle empty cells. <br>`true` = Only count cells that have actual data. <br>`false` = Count every single cell in the array, even if it is `#MISSING`. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns a pure integer representing the total count of evaluated items.
- E.g., If the array has 12 items, but 4 are `#MISSING`, and `skipMissing` is `true`, it returns `8`.
- E.g., If `skipMissing` is `false`, it returns `12`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine streams the array of data points.
2. **Evaluation Loop**: It initiates a basic counter (`count = 0`). It iterates through every element in the array.
3. **Missing Filtering**: If `skipMissing == true`, it checks if the element is `#MISSING`. If it is, it skips it. If it has data, it adds `+1` to the counter. (If `skipMissing == false`, it blindly adds `+1` for every element).
4. **Return**: Passes the finalized integer count back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Counting Only Active Data

```essbase
/* 
   Analyzes all 12 months. If only 3 months have data, it returns 3. 
*/
"Active_Months_Count" = @CalcMgrGetListCount(@CHILDREN("YearTotal"), true);
```

### Variant 2: Counting the Absolute Size of the Array

```essbase
/* 
   Analyzes all 12 months. Regardless of data, it returns 12. 
*/
"Total_Possible_Months" = @CalcMgrGetListCount(@CHILDREN("YearTotal"), false);
```

---

## Practical Examples

### Example 1: Calculating Average Productivity Per Active Employee

**Scenario**: A warehouse model tracks `"Widgets_Produced"` per shift. The model needs to calculate the average productivity per worker. However, not all workers show up for every shift. If you divide by the total number of employees in the database, the average will be artificially deflated. The script must dynamically count only the employees who actually produced widgets today (ignoring the `#MISSING` data).

```essbase
FIX("FY25", "Working", @LEVEL0("Shifts"))
    
    /* Ensure widgets were actually produced this shift */
    IF(@SUM("Widgets_Produced"->@CHILDREN("Warehouse_Employees")) > 0)
        
        /* 
           1. Count ONLY the employees who have active production data.
           We pass 'true' to skip missing.
        */
        VAR vActiveWorkers = @CalcMgrGetListCount(
            "Widgets_Produced"->@CHILDREN("Warehouse_Employees"), 
            true
        );
        
        /* 
           2. Calculate the Total Production.
        */
        VAR vTotalProduction = @SUM("Widgets_Produced"->@CHILDREN("Warehouse_Employees"));
        
        /* 
           3. Calculate the True Average.
        */
        "Avg_Widgets_Per_Worker" = vTotalProduction / vActiveWorkers;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Zero vs Missing | The database contains actual `0`s | If `skipMissing` is true, the function will ignore `#MISSING` cells. However, if your data load populated absent employees with hardcoded `0`s, the engine treats `0` as perfectly valid numeric data. It will count those employees, inflating your denominator. Ensure empty data is truly `#MISSING` and not hardcoded to `0` |
| Dense Block Explosions | Counting across massive cross-dims | Be careful when feeding massive arrays (like `@IDESCENDANTS("Total_Product")`) into array functions. The Essbase engine must dynamically evaluate every single cell in that cross-section. If the block is incredibly large, this can trigger massive memory overhead and slow down the calculation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetListItem`](./@CalcMgrGetListItem.md) | Once you know the total size of the list, you can use `GetListItem` to dynamically extract the exact value at a specific index position |
| [`@COUNT`](./@COUNT.md) | Native Essbase equivalent for counting data points across a range |
| [`@AVG`](./@AVG.md) | Native Essbase function that automatically handles the sum-and-divide logic without requiring you to manually count the denominator |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getlistcount.html)
