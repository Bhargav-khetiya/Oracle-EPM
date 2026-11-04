# @RANGELASTVAL

## Overview

`@RANGELASTVAL` is a **native Essbase mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of members strictly in the order they appear in the outline, and returns the **numeric value of the very last member** in that range.

### Why Does This Function Exist—

In corporate finance and reporting, the concept of a "Closing Balance" or "Ending Headcount" is ubiquitous. 
If you want to know how much cash the company has at the end of the year, you don't sum the months together (cash isn't additive). You simply need the value from the absolute final period of the year. 
If you hardcode `"Closing_Cash" = "Dec"`, the script breaks if the company transitions to a Fiscal Calendar ending in `"Mar"`. Furthermore, if the current forecast only has data through `"Oct"`, looking at `"Dec"` will return `#MISSING`, making the YTD reporting inaccurate.
`@RANGELASTVAL` solves this dynamically. You pass it a range (`@CHILDREN("YearTotal")`). It sweeps the array, completely ignores the beginning and middle, and extracts the exact numeric value belonging to the final chronological member. When combined with `SKIPMISSING`, it dynamically finds the "Latest Available Data Point" (e.g., Oct's balance), regardless of where you are in the year.

### When to Use It

- **Closing Balances**: Extracting the exact final period's cash, inventory, or retained earnings balance to push to the balance sheet.
- **Latest Run-Rates**: Grabbing the final recorded salary amount in a historical array to use as the baseline jumping-off point for next year's forecast.
- **YTD Thresholds**: Combined with `SKIPMISSING`, finding the most recent month of Actuals to calculate the current Year-To-Date status without hardcoding the current month variable.

---

## Category

**Mathematical / Array Aggregation & Bookends / Essbase Native Functions**

---

## Syntax

```essbase
@RANGELASTVAL(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, MemberRange)
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

Returns the numeric data value belonging to the final valid member in the defined array.
- **Absolute Last**: If `SKIPNONE` is used, it returns the value of the literal final member in the array (e.g., `"Dec"`), even if that value is `#MISSING` or `0`.
- **Last Valid**: If `SKIPMISSING` is used, it starts at the end of the array and steps backward. It returns the value of the very first member it finds (starting from the back) that actually contains data.
- **Empty Array**: If the entire array is empty (and a skip flag is used), it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The C-engine compiles the `MemberRange` into a sequential memory array based strictly on the physical `.otl` order.
2. **Reverse Search**: It starts at the absolute final index (the last member).
3. **Flag Check**: It checks the value against the `Skip_Flag`. If the flag dictates the block should be skipped (e.g., it is `#MISSING` and `SKIPMISSING` is active), it steps backwards one index (to the second-to-last member).
4. **Target Lock**: The absolute instant it finds a block that satisfies the flag constraints, it locks onto that value.
5. **Early Termination**: It returns the locked value immediately, completely ignoring the earlier months.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Latest Valid Data Point

```essbase
/* 
   Finds the last month in the year that actually had revenue.
   If Actuals are only loaded through "Aug", this returns Aug's value,
   ignoring the empty Sep-Dec blocks.
*/
"Current_Run_Rate" = @RANGELASTVAL(SKIPMISSING, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Calculating Closing Headcount

**Scenario**: HR requires an `"Ending_Headcount"` metric for the year. Headcount is a non-additive measure (you don't add January's headcount to February's headcount). The total for the year is simply whatever the headcount was on the very last day of the year. The administrator uses `@RANGELASTVAL` to extract it.

```essbase
FIX("FY25", "Working", @LEVEL0("Cost_Centers"))
    
    /* 
       1. Dynamically grab the absolute last period of the year.
       We use SKIPNONE because if the cost center was shut down in Nov, 
       and Dec is legitimately 0 or Missing, the Ending Headcount 
       should correctly report 0.
    */
    "Ending_Headcount" = @RANGELASTVAL(SKIPNONE, @CHILDREN("YearTotal"));
    
    /* 
       Results:
       If Headcount was: [Jan: 10, Feb: 12 ... Nov: 15, Dec: 15].
       The function skips straight to Dec, sees 15, and writes 15 to the target.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding `SKIPNONE` | Missing Closing Balances | If you write `@RANGELASTVAL(SKIPNONE, "Jan":"Dec")`, and you run this in July (meaning Aug-Dec are empty `#MISSING` blocks), `SKIPNONE` forces the engine to return `Dec`'s value. The function will return `#MISSING`. If your goal was to find the *Latest Available Actuals* (which would be July), you MUST use `SKIPMISSING`. Understand the difference between "Final Chronological Period" and "Most Recent Valid Period" |
| Assuming it Returns the Member | `@RANGELASTVAL` returns the Number | This function returns the numeric *value* (e.g., `50` employees). It does NOT return the *name* of the month (e.g., `"Dec"`). If you need to know exactly *when* the closing balance occurred, you need a custom Java CDF |
| Forgetting `@LIST` for Non-Contiguous Ranges | `@RANGELASTVAL("A", "B", "C")` | Like `@MAX` and `@AVG`, this function expects a SINGLE range argument. If you try to pass distinct, unconnected members separated by commas, the compiler will crash. You MUST wrap them in `@LIST("A", "B", "C")` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@RANGEFIRSTVAL`](./@RANGEFIRSTVAL.md) | The exact opposite. Sweeps the array and returns the value of the very FIRST member (Opening Balance) |
| `@LASTSIBLING` | A member selection function that returns the physical *Name/Block* of the last member, rather than evaluating its numeric data |
| [`@PRIOR`](../17_Time_Series/@PRIOR.md) | A shifting function often used in conjunction to find previous balances relative to a specific anchor point |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — RANGELASTVAL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/rangelastval.html)
