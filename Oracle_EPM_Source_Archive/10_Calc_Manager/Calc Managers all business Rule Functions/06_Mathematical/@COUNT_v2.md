# @COUNT

## Overview

`@COUNT` is a **native Essbase statistical function** in Oracle EPM Cloud (PBCS/EPBCS). It counts the number of non-missing (or conditionally defined) data values within a specified range of members. It returns an integer representing the exact number of populated data points.

### Why Does This Function Exist—

When calculating averages, execution rates, or dynamic thresholds, you must know the denominator (how many items actually exist or have data). 
If a department has 12 months in a year, but they only started spending money in April, dividing their Total Year expenses by 12 yields an inaccurate monthly run-rate. You only want to divide by the number of months that actually had activity (9). 
`@COUNT` performs this validation dynamically. Instead of hardcoding denominators, you pass a range of members (like `@CHILDREN("YearTotal")`) to `@COUNT`. By default, it skips `#MISSING` data, meaning it will return exactly `9`. It also supports conditional skipping (e.g., counting `0` as `#MISSING`), ensuring that statistical calculations and historical rolling averages are mathematically accurate regardless of when data entry began.

### When to Use It

- **Dynamic Averages**: Calculating a dynamic denominator for run-rates (e.g., dividing YTD spend by the number of months that actually had spend, rather than dividing by 12).
- **Compliance Tracking**: Counting exactly how many individual Cost Centers actually submitted a budget greater than $0 this cycle.
- **Headcount Modeling**: Counting the number of active employees within a specific department array.

---

## Category

**Statistical / Aggregation & Math / Essbase Native Functions**

---

## Syntax

```essbase
@COUNT(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, memberList)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ✅ Yes | Defines exactly what should be ignored during the count. <br>`SKIPNONE`: Counts everything, even if the cell has `#MISSING` data. (Will just return the total number of members in the list).<br>`SKIPMISSING`: Ignores cells with no data. Counts cells with `0`.<br>`SKIPZERO`: Ignores cells with `0`. Counts `#MISSING`.<br>`SKIPBOTH`: Ignores both `#MISSING` and `0`. |
| `memberList` | Member Range | ✅ Yes | The array or list of members to evaluate (e.g., `@CHILDREN("Q1")` or `Jan:Dec`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the strict integer count of cells in the `memberList` that satisfy the `Skip_Flag` condition.
- **Output Storage**: Because this function evaluates an array and returns a single integer, it is almost always assigned to a summary member (like `"Total_Active_Months"` or `"Count_of_Employees"`).

---

## How It Works (Behind the Scenes)

1. **Array Generation**: Essbase evaluates the `memberList` and builds an array of data values currently residing in those intersections.
2. **Flag Evaluation**: It looks at the `Skip_Flag` directive to establish the counting rules.
3. **Iteration**: It iterates through the array. 
   - If `SKIPBOTH` is active, and it sees `#MISSING` or `0`, it ignores the cell.
   - If it sees a valid number (e.g., `150`), it increments the internal counter by 1.
4. **Return**: It passes the final integer tally back to the calculation script.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Active Month Counter

```essbase
/* 
   Counts how many months in the year actually had Expenses greater than $0.
   If Jan, Feb, and Mar are the only months with data, returns 3.
*/
"Active_Months" = @COUNT(SKIPBOTH, @CHILDREN("YearTotal"));
```

---

## Practical Examples

### Example 1: Calculating a Dynamic Run-Rate (YTD Average)

**Scenario**: FP&A needs to calculate the "Average Monthly Spend" for a department. However, some departments only open in June. If the script divides `YearTotal` by 12, the average will be artificially deflated. The script must dynamically count how many months actually had data, and divide the total by that exact count.

```essbase
FIX("FY25", "Working", @LEVEL0("Departments"))
    
    /* 
       1. Only execute the calculation on the YearTotal member.
       (We don't want to calculate this independently in every month).
    */
    FIX("YearTotal")
        
        /* 
           2. Count how many months actually had Operating Expenses.
           We use SKIPBOTH so that months with $0 spend are ignored.
        */
        VAR vActiveMonths = @COUNT(SKIPBOTH, @CHILDREN("YearTotal"));
        
        /* 
           3. Prevent Divide-by-Zero errors.
           If a department had zero spend all year, the count is 0.
        */
        IF(vActiveMonths > 0)
            
            /* Calculate the true run-rate */
            "Average_Monthly_Spend" = "Operating_Expenses" / vActiveMonths;
            
        ELSE
            
            "Average_Monthly_Spend" = #MISSING;
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using SKIPNONE Incorrectly | `"Count" = @COUNT(SKIPNONE, @CHILDREN("Q1"))` | If you use `SKIPNONE`, Essbase literally just counts how many members are in the list, regardless of data. `@CHILDREN("Q1")` has 3 members (Jan, Feb, Mar). It will ALWAYS return `3`, even if the entire database is completely empty. If you are trying to measure data activity, NEVER use `SKIPNONE` |
| Misunderstanding 0 vs `#MISSING` | `SKIPMISSING` when a user typed a literal `0` | In web forms, a user can type a `0` into a cell, or they can leave it blank (`#MISSING`). If you use `SKIPMISSING`, a typed `0` WILL be counted as an active data point. If `0` means "no activity" in your business logic, you MUST use `SKIPBOTH` to be safe |
| Writing to Level 0 Time Periods | Running `@COUNT` without fixing on a summary member | If you calculate `@COUNT(@CHILDREN("YearTotal"))` without `FIX("YearTotal")`, Essbase will execute the count 12 times (once in Jan, once in Feb, etc.) and write the exact same answer (e.g., `9`) into every single month. This bloats the database. Always direct array-aggregation functions to a single summary target |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@AVG`](../07_Statistical/@AVG.md) | A combined function that essentially runs `@SUM` and divides it by `@COUNT` under the hood in a single step |
| [`@SUM`](./@SUM.md) | The mathematical companion to `COUNT`. Used together to calculate manual averages |
| `@COUNTALL` | A legacy variant function that behaves similarly to `SKIPNONE`, blindly counting the number of members in a list rather than evaluating the data inside them |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — COUNT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/count.html)
