# @RANGEFIRSTVAL

## Overview

`@RANGEFIRSTVAL` is a **native Essbase mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of members strictly in the order they appear in the outline, and returns the **numeric value of the very first member** in that range.

### Why Does This Function Exist—

When building balance sheet roll-forwards, inventory tracking, or head-count logic, calculations are inherently tied to "Opening Balances". 
If you want to calculate the annual change in inventory, you need to know exactly what the inventory was on the absolute first day (or month) of the year, regardless of what happened in the middle of the year. 
If you try to write `"Opening_Balance" = "Jan"`, you are hardcoding the first period. If the business switches to a Fiscal Year starting in `"Oct"`, your hardcoded script instantly breaks. 
`@RANGEFIRSTVAL` solves this elegantly. You give it a dynamic range (`@CHILDREN("YearTotal")`). It sweeps the array, completely ignores everything in the middle, and extracts the exact numeric value belonging to the absolute first chronological member in that specific subset. If the outline shifts, the function adapts perfectly.

### When to Use It

- **Opening Balances**: Extracting the exact first period's cash or inventory balance from a dynamic time array to calculate year-over-year movement.
- **Run-Rate Baselines**: Grabbing the first reported salary amount in a 12-month array to establish the baseline before applying complex compounding growth rates to the rest of the year.
- **Missing Data Fallbacks**: Combined with `SKIPMISSING`, finding the first *valid* data entry in a sequence (e.g., finding the exact month a new store opened and recorded its first dollar of sales).

---

## Category

**Mathematical / Array Aggregation & Bookends / Essbase Native Functions**

---

## Syntax

```essbase
@RANGEFIRSTVAL(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, MemberRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ❌ No  | Determines how empty blocks or zero values are handled:<br>- `SKIPNONE`: Evaluates everything (default).<br>- `SKIPMISSING`: Ignores `#MISSING` blocks.<br>- `SKIPZERO`: Ignores blocks containing exactly `0`.<br>- `SKIPBOTH`: Ignores both `#MISSING` and `0`. |
| `MemberRange` | Member List | ✅ Yes | The array of members to evaluate. Usually a time range (`"Jan":"Dec"`) or a hierarchy function (`@CHILDREN("YearTotal")`). |

*(Note: If the `Skip_Flag` is omitted, the function defaults to `SKIPNONE`).*

---

## Return Value

**Return Type**: Numeric (Double)

Returns the numeric data value belonging to the first valid member in the defined array.
- **Absolute First**: If `SKIPNONE` is used, it returns the value of the literal first member in the array, even if that value is `#MISSING` or `0`.
- **First Valid**: If `SKIPMISSING` is used, it steps through the array sequentially. It skips any members that are `#MISSING` and returns the value of the very first member that actually contains data.
- **Empty Array**: If the entire array is empty (and a skip flag is used), it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The C-engine compiles the `MemberRange` into a sequential memory array based strictly on the physical `.otl` order.
2. **Sequential Search**: It starts at Index 0 (the first member).
3. **Flag Check**: It checks the value against the `Skip_Flag`. If the flag dictates the block should be skipped (e.g., it is `#MISSING` and `SKIPMISSING` is active), it steps to Index 1, and so on.
4. **Target Lock**: The absolute instant it finds a block that satisfies the flag constraints, it locks onto that value.
5. **Early Termination**: It completely ignores the rest of the array. It does not evaluate them. It returns the locked value immediately, making it incredibly fast.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the First Recorded Sale

```essbase
/* 
   Finds the first month in the year that actually had revenue.
   Ignores any months where the store was closed or unbuilt (#MISSING or 0).
*/
"Opening_Sales" = @RANGEFIRSTVAL(SKIPBOTH, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Calculating Annual Inventory Turnover

**Scenario**: A warehouse calculates an "Annual Turnover Ratio" at the end of the year. The formula requires the `"Opening_Inventory"` and the `"Closing_Inventory"`. Because different regions have different fiscal calendars (some start in Jan, some in April), the administrator cannot hardcode the months. They use `@RANGEFIRSTVAL` to dynamically grab the opening balance.

```essbase
FIX("FY25", "Working", @LEVEL0("Warehouses"))
    
    /* 
       1. Dynamically grab the absolute first period of the year.
       We use SKIPNONE because if the Opening Inventory was legitimately 0 
       or Missing on Day 1, we need to know that mathematically.
    */
    "Opening_Inventory" = @RANGEFIRSTVAL(SKIPNONE, @CHILDREN("YearTotal"));
    
    /* 
       2. (Assume we use @RANGELASTVAL to get Closing_Inventory)
    */
    "Closing_Inventory" = @RANGELASTVAL(SKIPNONE, @CHILDREN("YearTotal"));
    
    /* 
       3. Calculate the Turnover (Cost of Goods / Average Inventory).
    */
    "Turnover_Ratio" = "COGS" / (("Opening_Inventory" + "Closing_Inventory") / 2);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding `SKIPNONE` | Missing Opening Balances | If you write `@RANGEFIRSTVAL(SKIPNONE, "Jan":"Dec")`, and the store didn't open until March, `Jan` is `#MISSING`. `SKIPNONE` forces the engine to return Jan's value. The function will return `#MISSING`. If your goal was to find the *first time the store actually had inventory*, you MUST use `SKIPMISSING`. Understand the difference between "First Chronological Period" and "First Period With Data" |
| Assuming it Returns the Member | `@RANGEFIRSTVAL` returns the Number | This function returns the numeric *value* (e.g., `500` units). It does NOT return the *name* of the month (e.g., `"Jan"`). If you need to know exactly *when* the opening balance occurred, this function cannot do that. You would need a custom Java CDF or a complex secondary `IF` loop to trace the date |
| Forgetting `@LIST` for Non-Contiguous Ranges | `@RANGEFIRSTVAL("A", "B", "C")` | Like `@MAX` and `@AVG`, this function expects a SINGLE range argument. If you try to pass distinct, unconnected members separated by commas, the compiler will crash. You MUST wrap them in `@LIST("A", "B", "C")` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@RANGELASTVAL`](./@RANGELASTVAL.md) | The exact opposite. Sweeps the array and returns the value of the very LAST member (Closing Balance) |
| `@FIRSTSIBLING` | A member selection function that returns the physical *Name/Block* of the first member, rather than evaluating its numeric data |
| [`@MAX`](../06_Mathematical/@MAX.md) | Sweeps the array but returns the absolute highest number, regardless of where it appears chronologically |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — RANGEFIRSTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/rangefirstval.html)
