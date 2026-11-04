# @CalcMgrExcelSUMPRODUCT

## Overview

`@CalcMgrExcelSUMPRODUCT` is a **custom Calc Manager mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `SUMPRODUCT` function directly inside an Essbase calculation script. 
It takes two (or more) identically sized arrays of data, multiplies the corresponding components in the arrays together, and then **sums all the resulting products** into a single master value.

### Why Does This Function Exist—

In FP&A modeling, you frequently have a Volume array (e.g., Units Sold) and a Rate array (e.g., Price). To calculate total revenue for a year, you must multiply `Jan_Units * Jan_Price`, then `Feb_Units * Feb_Price`, and so on, and then sum all 12 results together. 
Normally, in Essbase, this happens automatically at intersections (e.g., `"Revenue" = "Units" * "Price";`). However, if you are attempting to calculate a *Weighted Average* (e.g., "What was the true weighted average price of our products across all 50 regions—), you have to calculate `Sum(Units * Price)` and then divide by `Sum(Units)`. 
Doing this cleanly in an Essbase calculation script often requires creating temporary dummy accounts to hold the intermediate `Units * Price` products. `@CalcMgrExcelSUMPRODUCT` eliminates the need for temporary accounts. It allows you to pass the Unit array and the Price array simultaneously. It instantly processes the multiplication and summing entirely in Java memory, returning the final numerator required for weighted averages.

### When to Use It

- **Weighted Averages**: Instantly calculating the numerator for a weighted average calculation across dozens of children members without needing temporary holding accounts.
- **Matrix Math**: Calculating the dot-product of two distinct arrays for advanced operational modeling.
- Whenever you need to migrate an Excel spreadsheet containing the `SUMPRODUCT` function directly into an Essbase calculation.

---

## Category

**Mathematical / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelSUMPRODUCT(array1, array2, [array3...])
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `array1` | Array/List | ✅ Yes | The first array of data (e.g., `@CHILDREN("Q1_Units")`). |
| `array2` | Array/List | ✅ Yes | The second array of data (e.g., `@CHILDREN("Q1_Price")`). |
| `[arrayN]` | Array/List| ❌ No  | Any subsequent arrays to multiply against the first two. |

**CRITICAL REQUIREMENT**: All arrays passed must have the exact same number of elements (dimensions/length).

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the final summed value of the multiplied arrays.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine ingests all arrays. It strictly checks that `Length(Array1) == Length(Array2)`. If the arrays are different sizes, it cannot pair the elements properly, and it fails.
2. **Missing Handling**: It treats non-numeric or `#MISSING` data as `0`.
3. **Multiplication Loop**: It loops through the arrays by index. It multiplies `Array1[0] * Array2[0]`, then `Array1[1] * Array2[1]`, etc.
4. **Summation**: It adds all those intermediate products together into a single running total.
5. **Return**: Passes the final summed total back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Calculating Total Revenue dynamically across regions

```essbase
/* 
   Pairs the Units for each Region with the corresponding Price for that Region, 
   multiplies them, and sums the total. 
*/
"Global_Revenue" = @CalcMgrExcelSUMPRODUCT(
    "Units"->@CHILDREN("All_Regions"), 
    "Price"->@CHILDREN("All_Regions")
);
```

---

## Practical Examples

### Example 1: Calculating True Weighted Average Price

**Scenario**: A corporate dashboard shows the performance of 50 different retail stores. The executive wants to see the "Weighted Average Price" across all stores at the `Total_Geography` parent level. You cannot simply average the price account, because a store that sells 10,000 units should weight the average much heavier than a store that sells 5 units. The formula for Weighted Average is `SUMPRODUCT(Volume, Rate) / SUM(Volume)`.

```essbase
FIX("FY25", "Working", "Total_Geography")
    
    /* 
       Step 1: Calculate the numerator (Total Value).
       Multiply the Units at each store by the Price at that same store, and sum it all up.
    */
    VAR vTotalValue = @CalcMgrExcelSUMPRODUCT(
        "Units_Sold"->@CHILDREN("All_Stores"),
        "Average_Price"->@CHILDREN("All_Stores")
    );
    
    /* Step 2: Calculate the denominator (Total Volume) */
    VAR vTotalUnits = @SUM("Units_Sold"->@CHILDREN("All_Stores"));
    
    /* Step 3: Calculate the Weighted Average */
    IF(vTotalUnits > 0)
        "Weighted_Average_Price" = vTotalValue / vTotalUnits;
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatched Array Sizes | `SUMPRODUCT(@CHILDREN("Q1"), @CHILDREN("YearTotal"))` | This is the #1 reason this function fails. The function aligns the arrays by index (e.g., 1st item with 1st item). If Array 1 has 3 items, and Array 2 has 12 items, the Java engine cannot align them and will throw an error. The arrays must be perfectly identical in length |
| Using `#MISSING` data | Empty data in Array 1 | Unlike some functions that safely ignore `#MISSING`, `SUMPRODUCT` generally treats `#MISSING` elements as `0`. If `Units` is `0` but `Price` is `$50`, the product is `0`. This is mathematically correct, but you must ensure your data is clean |
| Dense Block Explosions | Running across large blocks without FIX | Because this function evaluates large arrays dynamically, it should generally be targeted at specific summary metrics. Placing it broadly across all products and all periods without tight `FIX` constraints can trigger massive performance degradation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@SUM`](./@SUM.md) | Standard addition of a single array |
| [`@CalcMgrExcelPRODUCT`](./@CalcMgrExcelPRODUCT.md) | Multiplies everything in a single array together (e.g., compounding growth rates), rather than multiplying two *different* arrays against each other |
| [`@CalcMgrExcelSUMSQ`](./@CalcMgrExcelSUMSQ.md) | Squares the items in an array and then sums them |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelsumproduct.html)
