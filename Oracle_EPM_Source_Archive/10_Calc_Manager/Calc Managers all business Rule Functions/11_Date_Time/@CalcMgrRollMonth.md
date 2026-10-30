# @CalcMgrRollMonth

## Overview

`@CalcMgrRollMonth` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a **Java Date Object** (or Timestamp) and mathematically rolls the **Month** forward or backward by a specific integer amount, returning an entirely new, modified Java Date Object.

### Why Does This Function Exist?

While `@CalcMgrRollDay` handles exact daily offsets (e.g., Net 45 Terms), many financial contracts operate on strict monthly cycles. If an enterprise software license begins on January 31st and lasts exactly 3 months, it does not last "90 days." It lasts exactly 3 calendar months. 
Calculating this manually in Essbase is nearly impossible. Adding `300` to `20240131` (moving the month digit up by 3) results in `20240431` (April 31st). But April only has 30 days. Attempting to use `20240431` in downstream logic will crash the calendar parser.
`@CalcMgrRollMonth` solves this effortlessly. By passing the Date Object and the integer `3`, the Java engine rolls the month forward. Crucially, if the original day (31st) does not exist in the target month (April), Java automatically snaps the day backward to the last valid day of that month (April 30th). This guarantees mathematically perfect, error-free contract math.

### When to Use It

- **Contract Expiration**: Calculating the exact end date of a 12-month, 24-month, or 36-month subscription.
- **Warranty Tracking**: Establishing the expiration date of a hardware warranty by rolling the Purchase Date forward by the `Warranty_Length_Months` driver.
- **Trailing Averages**: Rolling the current date backward by 6 months to establish the precise start date for a trailing 6-month moving average calculation.

---

## Category

**Date & Time / Calendar Math & Offsets / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrRollMonth(date, roll_amount)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The starting Java Date Object you want to modify. |
| `roll_amount` | Numeric | ✅ Yes | The exact number of months to roll the date. <br>`Positive Integer` = Rolls Forward. <br>`Negative Integer` = Rolls Backward. |

---

## Return Value

**Return Type**: Object (Java Date Object)

Returns a newly constructed Java Date Object representing the modified date.
- **Boundary Snapping**: If the target month does not have enough days to support the original day (e.g., rolling from Jan 31st to Feb), the engine will automatically snap the day to the last valid day of the target month (e.g., Feb 28th or 29th).
- **CRITICAL**: Because this function returns an Object, it CANNOT be saved directly into a standard Essbase numeric account. You must format the output object back into a `YYYYMMDD` integer.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the starting Date Object and the integer offset.
2. **Calendar Instantiation**: It converts the Date Object into a `java.util.Calendar` instance.
3. **Execution**: It executes the native Java `Calendar.add(Calendar.MONTH, roll_amount)` method. 
4. **Boundary Evaluation**: As months are added, if the calculation crosses December, Java natively increments the Year integer automatically. It also performs the critical day-snapping logic for months like February, April, June, September, and November.
5. **Return**: It collapses the Calendar back into a Date Object and returns it to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Forward by a Custom Length

```essbase
/* 
   Assumes vStartObj is Oct 15th, 2024. 
   Rolls forward 6 months. Resulting Object represents April 15th, 2025.
*/
VAR vEndObj = @CalcMgrRollMonth(vStartObj, 6);
```

---

## Practical Examples

### Example 1: Dynamic Contract Expiration with Boundary Snapping

**Scenario**: A SaaS company tracks software subscriptions. If a customer signs a 3-month contract on January 31st, the script must calculate the exact Expiration Date. Because April 31st doesn't exist, the script relies on Java to gracefully snap the expiration to April 30th. 

```essbase
FIX("FY25", "Working", @LEVEL0("Contracts"))
    
    IF("Contract_Start_Date" != #MISSING AND "Term_Months" > 0)
        
        /* 
           1. Convert the starting integer (e.g. 20240131) into a Java Date Object.
        */
        VAR vStartDateObj = @CalcMgrIntegerToDate("Contract_Start_Date");
        
        /* 
           2. Roll the date forward by the exact number of months.
           If Term = 3, Java attempts to build April 31st, fails, and snaps 
           the result perfectly to April 30th.
        */
        VAR vExpirationObj = @CalcMgrRollMonth(vStartDateObj, "Term_Months");
        
        /* 
           3. Format the Java Object back into a readable YYYYMMDD text string.
        */
        VAR vExpirationString = @CalcMgrFormatDate(vExpirationObj, "yyyyMMdd");
        
        /* 
           4. Convert the string back into a mathematical integer 
           and save it to the database. (Result: 20240430).
        */
        "Calculated_Expiration_Date" = @CalcMgrGetIntegerFromString(vExpirationString);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrRollMonth(20240131, 3)` | This function explicitly requires a **Java Date Object**. If you pass a raw Essbase integer, the Java engine will crash. Always use `@CalcMgrIntegerToDate` first |
| Saving the Output Directly | `"Target" = @CalcMgrRollMonth(...)` | You cannot assign the output of this function directly to an Essbase numerical account. It returns an Object. You must translate the object back into an integer (see Example 1) |
| Using it for Fixed Days | `RollMonth(Obj, 1)` (hoping to add exactly 30 days) | `RollMonth` is strictly Calendar Math. If you roll forward 1 month from Feb 1st, it adds 28 days (to March 1st). If you roll forward 1 month from July 1st, it adds 31 days (to August 1st). If your contract specifies exactly 30 days regardless of the month, you MUST use `@CalcMgrRollDay(Obj, 30)` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRollDay`](./@CalcMgrRollDay.md) | Rolls the calendar by fixed Days (e.g., adding exactly 90 days) rather than by Calendar Months |
| [`@CalcMgrRollYear`](./@CalcMgrRollYear.md) | Rolls the calendar by full Years (e.g., changing 2024 to 2025) |
| [`@CalcMgrIntegerToDate`](./@CalcMgrIntegerToDate.md) | The mandatory wrapper required to feed Essbase integers into this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_rollmonth.html)
