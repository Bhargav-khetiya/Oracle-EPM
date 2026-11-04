# @CalcMgrRollDate

## Overview

`@CalcMgrRollDate` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a **Java Date Object** (or Timestamp) and mathematically rolls the **Day of the Month** forward or backward by a specific number of days, returning an entirely new, modified Java Date Object.

### Why Does This Function Exist—

When executing financial logic that requires date offsets, standard Essbase math fails. If an invoice is dated `20240128` (January 28th), and payment terms are Net 5 (payment due in 5 days), you cannot simply add `5` to `20240128`. That yields `20240133` (January 33rd), which is not a real date. 
To properly calculate the offset, the engine must know that January has 31 days, so rolling 5 days forward should seamlessly click over into February 2nd. 
`@CalcMgrRollDate` leverages the Java Calendar engine to execute this exact offset math. By passing it a Date Object and the integer `5`, the engine evaluates the Gregorian calendar, automatically handles month-end boundaries, and perfectly rolls the date forward to `Feb 2, 2024`.

### When to Use It

- **Payment Term Calculations**: Dynamically calculating strict Due Dates by rolling the Invoice Date forward by the customer's specific Net Terms (e.g., 30, 45, 60 days).
- **Grace Periods**: Calculating the exact final day an employee can exercise stock options by rolling the Vesting Date forward by 90 days.
- **Accrual Windows**: Establishing a rigid 7-day cutoff window for month-end expense reporting by rolling the current date backward by 7 days.

---

## Category

**Date & Time / Calendar Math & Offsets / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrRollDate(date, roll_amount)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The starting Java Date Object you want to modify. |
| `roll_amount` | Numeric | ✅ Yes | The exact number of days to roll the date. <br>`Positive Integer` (e.g., `5`) = Rolls Forward into the future. <br>`Negative Integer` (e.g., `-5`) = Rolls Backward into the past. |

---

## Return Value

**Return Type**: Object (Java Date Object)

Returns a newly constructed Java Date Object representing the modified date.
- **CRITICAL**: Because this function returns an Object, it CANNOT be saved directly into a standard Essbase numeric account. You must mathematically convert the output object back into an Essbase `YYYYMMDD` integer using `@CalcMgrGetDatePart` or `@CalcMgrFormatDate` before attempting to save it.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the starting Date Object and the integer offset.
2. **Calendar Instantiation**: It converts the Date Object into a `java.util.Calendar` instance.
3. **Execution**: It executes the native Java `Calendar.add(Calendar.DAY_OF_MONTH, roll_amount)` method. 
4. **Calendar Evaluation**: As the days are added, Java natively checks if the day exceeds the maximum days for that specific month (e.g., 31 for Jan). If it does, it automatically increments the Month by 1, resets the Day, and continues counting.
5. **Return**: It collapses the Calendar back into a Date Object and passes it back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Forward by Net 30 Terms

```essbase
/* 
   Assumes vInvoiceObj is Jan 15th, 2024. 
   Rolls forward 30 days. Resulting Object represents Feb 14th, 2024.
*/
VAR vDueDateObj = @CalcMgrRollDate(vInvoiceObj, 30);
```

---

## Practical Examples

### Example 1: Dynamic Invoice Due Date Calculation

**Scenario**: A revenue planning application loads open invoices. The invoice date is stored as an integer (`YYYYMMDD`). The customer's payment terms (e.g., `30` or `45` days) are stored in a driver account. The script must dynamically calculate the exact due date of the invoice and store it back into Essbase as a `YYYYMMDD` integer so it can be used for cash flow forecasting.

```essbase
FIX("Working", @LEVEL0("Invoices"))
    
    IF("Invoice_Date" != #MISSING AND "Payment_Terms_Days" > 0)
        
        /* 
           1. Convert the starting YYYYMMDD integer into a Java Date Object.
           (e.g., 20240120 becomes Jan 20th).
        */
        VAR vInvoiceDateObj = @CalcMgrIntegerToDate("Invoice_Date");
        
        /* 
           2. Roll the date forward by the exact number of payment days.
           If Terms = 30, it rolls Jan 20 + 30 days to Feb 19th.
        */
        VAR vDueDateObj = @CalcMgrRollDate(vInvoiceDateObj, "Payment_Terms_Days");
        
        /* 
           3. The output is a Java Object. We cannot save objects to Essbase.
           We must format the object back into a YYYYMMDD text string.
        */
        VAR vDueDateString = @CalcMgrFormatDate(vDueDateObj, "yyyyMMdd");
        
        /* 
           4. Convert the string back into a mathematical integer 
           and save it into the target account. 
           (Result: 20240219).
        */
        "Calculated_Due_Date" = @CalcMgrGetIntegerFromString(vDueDateString);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrRollDate(20240128, 5)` | This function explicitly requires a **Java Date Object**. If you pass a raw Essbase integer (like `20240128`), the Java engine will crash. Always wrap your Essbase integers in `@CalcMgrIntegerToDate` first before rolling them |
| Saving the Output Directly | `"Target" = @CalcMgrRollDate(...)` | This function returns an Object. Essbase accounts can only hold Numbers (or Strings for Text Accounts). If you try to save the object directly into the database, it will throw a Type Mismatch validation error. You must convert the output object into an integer before saving (see Example 1) |
| Using it for Months | `@CalcMgrRollDate(Obj, 3)` (hoping to add 3 months) | The `RollDate` function specifically rolls **Days**. If you want to roll the calendar forward by exactly 3 months (ignoring how many days are in each month), you must use `@CalcMgrRollMonth` instead |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRollDay`](./@CalcMgrRollDay.md) | An identical alias function. It performs the exact same day-rolling math |
| [`@CalcMgrRollMonth`](./@CalcMgrRollMonth.md) | Rolls the calendar by full Months (e.g., changing Jan to April) rather than by Days |
| [`@CalcMgrRollYear`](./@CalcMgrRollYear.md) | Rolls the calendar by full Years (e.g., changing 2024 to 2025) |
| [`@CalcMgrIntegerToDate`](./@CalcMgrIntegerToDate.md) | The mandatory wrapper required to feed Essbase integers into this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_rolldate.html)
