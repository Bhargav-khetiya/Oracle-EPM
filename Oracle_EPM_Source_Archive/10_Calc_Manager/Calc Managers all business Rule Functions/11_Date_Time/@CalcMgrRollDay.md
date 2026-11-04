# @CalcMgrRollDay

## Overview

`@CalcMgrRollDay` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a **Java Date Object** (or Timestamp) and mathematically rolls the **Day of the Month** forward or backward by a specific integer amount, returning an entirely new, modified Java Date Object.
*(Note: This function is functionally identical to `@CalcMgrRollDate`. It exists as an alternative alias to directly align with the naming conventions of `@CalcMgrRollMonth` and `@CalcMgrRollYear`).*

### Why Does This Function Exist—

Calculating day offsets using basic arithmetic is impossible in EPM. If a manufacturing component expires exactly 45 days after production, and it was produced on October 25th (`20241025`), adding `45` mathematically results in `20241070` (October 70th), which corrupts the database. 
`@CalcMgrRollDay` natively understands the Gregorian Calendar. By passing it the Date Object and the integer `45`, the Java engine automatically rolls through the days, seamlessly crossing the month boundary into November, skipping over November 30th into December, and perfectly resolving the correct expiration date. 
Using `RollDay` (rather than `RollDate`) simply makes your calculation scripts easier to read when stacked next to other specific roll functions like `RollMonth`.

### When to Use It

- **Inventory Spoilage**: Dynamically calculating the exact `Spoilage_Date` by rolling the `Production_Date` forward by the specific shelf-life days of that SKU.
- **Service Level Agreements (SLAs)**: Calculating the exact final deadline for a ticket by rolling the `Submission_Date` forward by 3 days.
- **Accrual Windows**: Rolling the current date backward by 7 days to establish the strict cutoff for historical expense reimbursements.

---

## Category

**Date & Time / Calendar Math & Offsets / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrRollDay(date, roll_amount)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The starting Java Date Object you want to modify. |
| `roll_amount` | Numeric | ✅ Yes | The exact number of days to roll the date. <br>`Positive Integer` = Rolls Forward. <br>`Negative Integer` = Rolls Backward. |

---

## Return Value

**Return Type**: Object (Java Date Object)

Returns a newly constructed Java Date Object representing the modified date.
- **CRITICAL**: Because this function returns an Object, it CANNOT be saved directly into a standard Essbase numeric account. You must format the output object back into an Essbase `YYYYMMDD` integer (via string parsing) before saving it.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the starting Date Object and the integer offset.
2. **Calendar Instantiation**: It converts the Date Object into a `java.util.Calendar` instance.
3. **Execution**: It executes the native Java `Calendar.add(Calendar.DAY_OF_MONTH, roll_amount)` method. 
4. **Boundary Evaluation**: As days are mathematically added or subtracted, Java natively checks if the boundary of the month (or year) is crossed, adjusting the month/year integers automatically.
5. **Return**: It collapses the Calendar back into a Date Object and returns it to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Backward (Past Lookup)

```essbase
/* 
   Assumes vCurrentObj is May 5th. 
   Rolls backward 10 days. Resulting Object represents April 25th.
*/
VAR vLookupDateObj = @CalcMgrRollDay(vCurrentObj, -10);
```

---

## Practical Examples

### Example 1: Dynamic SLA Cutoff Calculation

**Scenario**: A support ticket tracking system requires all tickets to be resolved within 3 days. If a ticket was filed on `20240228` (Feb 28th), the script must calculate the strict SLA Deadline Date. (Since 2024 is a leap year, Feb has 29 days, so the answer should be March 2nd).

```essbase
FIX("FY24", "Working", @LEVEL0("Tickets"))
    
    IF("Ticket_Filing_Date" != #MISSING)
        
        /* 
           1. Convert the starting integer (e.g. 20240228) into a Java Date Object.
        */
        VAR vFilingDateObj = @CalcMgrIntegerToDate("Ticket_Filing_Date");
        
        /* 
           2. Roll the date forward by exactly 3 days.
           Java knows 2024 is a leap year, so it correctly bridges the boundary.
        */
        VAR vSlaDeadlineObj = @CalcMgrRollDay(vFilingDateObj, 3);
        
        /* 
           3. Format the Java Object back into a readable YYYYMMDD text string.
        */
        VAR vSlaDeadlineString = @CalcMgrFormatDate(vSlaDeadlineObj, "yyyyMMdd");
        
        /* 
           4. Convert the string back into a mathematical integer 
           and save it to the database. (Result: 20240302).
        */
        "Calculated_Deadline" = @CalcMgrGetIntegerFromString(vSlaDeadlineString);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrRollDay(20240228, 3)` | This function explicitly requires a **Java Date Object**. If you pass a raw Essbase integer, the Java engine will crash or interpret the number as milliseconds since 1970. Always use `@CalcMgrIntegerToDate` first |
| Saving the Output Directly | `"Deadline" = @CalcMgrRollDay(...)` | You cannot assign the output of this function directly to an Essbase numerical block account. It returns an Object. You must translate the object back into an integer using the formatting/parsing chain (see Example 1) |
| Using it for Multi-Month Jumps | `@CalcMgrRollDay(Obj, 90)` | While rolling forward 90 days is mathematically valid, if your business logic explicitly states "Add exactly 3 Months", rolling 90 days will give you the wrong answer (because some months have 31 days, and some have 28). If you need strict month logic, use `@CalcMgrRollMonth` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRollDate`](./@CalcMgrRollDate.md) | The exact same function. Literally an alias for `RollDay` |
| [`@CalcMgrRollMonth`](./@CalcMgrRollMonth.md) | Rolls the calendar by full Months (e.g., changing Jan to April) rather than by Days |
| [`@CalcMgrRollYear`](./@CalcMgrRollYear.md) | Rolls the calendar by full Years (e.g., changing 2024 to 2025) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_rollday.html)
