# @CalcMgrExcelRANK

## Overview

`@CalcMgrExcelRANK` is a **custom Calc Manager statistical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `RANK` function directly inside an Essbase calculation script. 
It analyzes an array of data, evaluates a specific numerical value, and returns the **absolute integer rank** of that value within the dataset (e.g., "Out of 50 stores, this store is #4").

### Why Does This Function Exist—

Performance ranking is a cornerstone of corporate reporting. Sales Directors want to see their "Top 10" reps. Supply Chain VPs want a list of their "Bottom 5" worst-performing vendors. 
To calculate an absolute integer rank manually in an Essbase calc script, you would have to write a highly inefficient looping mechanism: taking the current store's sales, looping through every other store in the dimension, checking if their sales are higher, and iterating a counter. This is violently destructive to system performance.
`@CalcMgrExcelRANK` completely eliminates the need for looping. It takes the specific value, evaluates it against a dynamic array in the high-speed Java engine, and instantly returns the exact integer rank (`1`, `2`, `3`), ensuring perfect parity with legacy Excel leaderboard reports.

### When to Use It

- **Leaderboards**: Assigning a 1 to N ranking for all sales reps in a territory to drive competitive dashboards.
- **Exception Reporting**: Tagging the worst-performing operational units (e.g., Rank #100) for executive review.
- Whenever you need to migrate an Excel spreadsheet containing the `RANK` function directly into an Essbase calculation.

---

## Category

**Statistical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelRANK(x, val1, val2, [val3...], [order])
```

### Formal Syntax

```
@CalcMgrExcelRANK(x, numericList, [order])
```

Where:
- `x` — The target numerical value you want to rank (e.g., `$450,000`).
- `numericList` — A comma-separated list of numbers, or a cross-dimensional range like `@CHILDREN("Stores")` that acts as the baseline comparison array.
- `order` — (Optional) `0` = Descending (Largest number is Rank 1). `1` = Ascending (Smallest number is Rank 1). Defaults to `0`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | Numeric | ✅ Yes | The value you want to find the rank for. **Must be passed as the VERY FIRST parameter.** |
| `val1, val2...` | Array/List | ✅ Yes | The baseline array of data to evaluate `x` against. |
| `order` | Numeric | ❌ No | `0` (Descending) or `1` (Ascending). If omitted, defaults to 0. **If provided, must be the VERY LAST parameter in the list.** |

---

## Return Value

**Return Type**: Numeric (Integer returned as double-precision floating point)

Returns the absolute integer rank of the value.
- **Ties**: If two values in the array are identical, they receive the exact same rank. (e.g., If the top two stores both sold exactly $500k, they are both Rank 1. The next store down will be Rank 3. There will be no Rank 2).
- If `x` does not exist anywhere within the array, the function mathematically calculates where it *would* fall and returns that integer.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine isolates the `x` parameter. It then checks the very last parameter to see if it is a standalone `0` or `1` acting as the `order` flag. It ingests the remaining array.
2. **Missing Handling**: It drops `#MISSING` values from the array.
3. **Sorting**: It sorts the array either descending (standard) or ascending based on the `order` flag.
4. **Ranking Algorithm**: It iterates through the array until it finds where `x` belongs, applying standard Excel tie-breaking logic.
5. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Leaderboard (Highest is #1)

```essbase
/* 
   Current store's sales: $450k. 
   Compares against all stores. Largest sales = Rank 1. 
*/
"Store_Rank" = @CalcMgrExcelRANK("Total_Sales", "Total_Sales"->@CHILDREN("All_Stores"), 0);
```

### Variant 2: Golf Score / Defect Rate (Lowest is #1)

```essbase
/* 
   Current factory's defect rate: 1.2%. 
   Compares against all factories. Smallest defect rate = Rank 1. 
*/
"Factory_Quality_Rank" = @CalcMgrExcelRANK("Defect_Rate", "Defect_Rate"->@CHILDREN("All_Factories"), 1);
```

---

## Practical Examples

### Example 1: Dynamic Top 10 Bonus Allocation

**Scenario**: A company wants to pay a special "President's Club" bonus to the absolute Top 5 sales reps in the entire company. The absolute dollar amount of sales doesn't matter, only their rank compared to everyone else. The script calculates the rank for every rep, and if the rank is 5 or better, it triggers the bonus.

```essbase
FIX("FY25", "Working", @LEVEL0("Sales_Reps"))
    
    /* Ensure the rep actually sold something */
    IF("Total_Sales" > 0)
        
        /* 
           1. Calculate exactly where this rep ranks compared to all reps.
           Order is 0 (Descending), so the highest seller is Rank 1.
        */
        "Calculated_Rank" = @CalcMgrExcelRANK(
            "Total_Sales", 
            "Total_Sales"->"No_Entity"->@CHILDREN("All_Sales_Reps"),
            0
        );
        
        /* 
           2. Evaluate the rank. If they are in the Top 5, award the bonus.
        */
        IF("Calculated_Rank" <= 5)
            "Presidents_Club_Bonus" = 10000;
        ELSE
            "Presidents_Club_Bonus" = 0;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Parameter Ordering | `@CalcMgrExcelRANK(@CHILDREN("Sales"), "Total_Sales")` | The `x` parameter (the target value) **MUST** be the very first parameter. The `order` flag **MUST** be the very last parameter. If you scramble the order, the function will attempt to use the first value in the array as the target, completely ruining the calculation |
| Expecting Continuous Ranks | Complaining that Rank 2 is missing | Standard `RANK` logic handles ties by giving both items the top rank, and skipping the subsequent ranks (e.g., `1, 1, 3`). This is mathematically correct. If you expect `1, 1, 2` (Dense Ranking), this function does not support that natively. You would have to build complex downstream logic to re-index the ranks |
| Ranking `#MISSING` Data | All empty stores tie for Rank 50 | If you do not wrap your rank calculation in an `IF("Sales" > 0)` block, the script will calculate the rank for every single empty, `#MISSING` store in the database. Since they all equal 0, they will all tie for last place. Always restrict ranking logic to valid data blocks |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelPERCENTRANK`](./@CalcMgrExcelPERCENTRANK.md) | Returns a percentile decimal (e.g., 0.85) rather than an absolute integer (e.g., Rank 4) |
| [`@CalcMgrExcelLARGE`](./@CalcMgrExcelLARGE.md) | The inverse usage: You provide the Rank (`4`), and it tells you the exact dollar amount that holds that rank |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelrank.html)
