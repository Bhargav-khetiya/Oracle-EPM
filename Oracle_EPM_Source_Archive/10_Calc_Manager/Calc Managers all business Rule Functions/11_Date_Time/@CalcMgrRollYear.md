# @CalcMgrRollYear

## Overview

`@CalcMgrRollYear` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a **Java Date Object** (or Timestamp) and mathematically rolls the **Year** forward or backward by a specific integer amount, returning an entirely new, modified Java Date Object.

### Why Does This Function Exist?

When building long-term financial plans, administrators frequently project dates into the future. If a massive piece of capital equipment is purchased on `20240515` (May 15th, 2024), and it has a useful life of 5 years, the retirement date is `20290515`. 
While you can mathematically calculate this in Essbase by adding `50000` to the integer (`20240515 + 50000 = 20290515`), this basic math method catastrophically breaks during leap years. 
If equipment is purchased on `20240229` (February 29th, 2024 - a leap year), and you mathematically add 5 years to it (`20290229`), the result is April 29th in a non-leap year. This date does not exist, and downstream scripts will crash attempting to parse it. 
`@CalcMgrRollYear` completely protects your calendar math. By passing the Date Object and the integer `5`, the Java engine rolls the year forward. If the original date was February 29th, and the target year is not a leap year, Java automatically snaps the day backward to February 28th, preserving calendar integrity.

### When to Use It

- **Asset Retirement**: Calculating the exact final day of an asset's useful life by rolling the `Purchase_Date` forward by the `Useful_Life_Years` driver.
- **Multi-Year Renewals**: Automatically generating the next 3 renewal dates for an annual enterprise software contract.
- **Historical Trailing Averages**: Rolling the current date backward by 1 year to establish the exact start date for a trailing 12-month KPI calculation.

---

## Category

**Date & Time / Calendar Math & Offsets / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrRollYear(date, roll_amount)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The starting Java Date Object you want to modify. |
| `roll_amount` | Numeric | ✅ Yes | The exact number of years to roll the date. <br>`Positive Integer` = Rolls Forward into the future. <br>`Negative Integer` = Rolls Backward into the past. |

---

## Return Value

**Return Type**: Object (Java Date Object)

Returns a newly constructed Java Date Object representing the modified date.
- **Leap Year Snapping**: If the starting date is Feb 29th, and the target year does not contain a Feb 29th, the engine will automatically snap the day to Feb 28th.
- **CRITICAL**: Because this function returns an Object, it CANNOT be saved directly into a standard Essbase numeric account. You must format the output object back into a `YYYYMMDD` integer first.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the starting Date Object and the integer offset.
2. **Calendar Instantiation**: It converts the Date Object into a `java.util.Calendar` instance.
3. **Execution**: It executes the native Java `Calendar.add(Calendar.YEAR, roll_amount)` method. 
4. **Boundary Evaluation**: It adds the years, explicitly checking if the target year supports the current month/day configuration (specifically addressing leap year edge cases).
5. **Return**: It collapses the Calendar back into a Date Object and returns it to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Backward for Year-Over-Year Lookups

```essbase
/* 
   Assumes vCurrentObj is Nov 10th, 2024. 
   Rolls backward 1 year. Resulting Object represents Nov 10th, 2023.
*/
VAR vPriorYearObj = @CalcMgrRollYear(vCurrentObj, -1);
```

---

## Practical Examples

### Example 1: Dynamic Asset Retirement Date (Handling Leap Years)

**Scenario**: A CapEx planning application requires the script to automatically calculate the "Retirement Date" of a new asset based on its purchase date and its useful life. The script must safely handle assets purchased on Leap Days.

```essbase
FIX("FY25", "Working", @LEVEL0("Assets"))
    
    IF("Purchase_Date" != #MISSING AND "Useful_Life_Years" > 0)
        
        /* 
           1. Convert the starting integer (e.g. 20240229) into a Java Date Object.
        */
        VAR vPurchaseDateObj = @CalcMgrIntegerToDate("Purchase_Date");
        
        /* 
           2. Roll the date forward by the exact number of years.
           If Life = 5, Java attempts to build Feb 29th 2029, fails, and snaps 
           the result perfectly to Feb 28th 2029.
        */
        VAR vRetirementObj = @CalcMgrRollYear(vPurchaseDateObj, "Useful_Life_Years");
        
        /* 
           3. Format the Java Object back into a readable YYYYMMDD text string.
        */
        VAR vRetirementString = @CalcMgrFormatDate(vRetirementObj, "yyyyMMdd");
        
        /* 
           4. Convert the string back into a mathematical integer 
           and save it to the database. (Result: 20290228).
        */
        "Calculated_Retirement_Date" = @CalcMgrGetIntegerFromString(vRetirementString);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrRollYear(20240229, 5)` | This function explicitly requires a **Java Date Object**. If you pass a raw Essbase integer, the Java engine will crash. Always use `@CalcMgrIntegerToDate` first |
| Using Direct Math Instead | `Date + (Years * 10000)` | While multiplying the year by 10000 and adding it to the date (e.g., `20240515 + 50000 = 20290515`) is faster computationally, it completely lacks leap-year protection. If you use direct math on Feb 29th, you will corrupt your database. Always use `RollYear` if there is any chance your dates might fall on Leap Days |
| Saving the Output Directly | `"Target" = @CalcMgrRollYear(...)` | You cannot assign the output of this function directly to an Essbase numerical account. It returns an Object. You must translate the object back into an integer (see Example 1) |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRollDay`](./@CalcMgrRollDay.md) | Rolls the calendar by fixed Days rather than by Years |
| [`@CalcMgrRollMonth`](./@CalcMgrRollMonth.md) | Rolls the calendar by full Months (e.g., changing Jan to April) |
| [`@CalcMgrIntegerToDate`](./@CalcMgrIntegerToDate.md) | The mandatory wrapper required to feed Essbase integers into this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_rollyear.html)
