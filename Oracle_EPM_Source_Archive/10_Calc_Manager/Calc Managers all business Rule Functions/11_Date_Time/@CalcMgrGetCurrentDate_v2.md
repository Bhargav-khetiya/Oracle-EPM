# @CalcMgrGetCurrentDate

## Overview

`@CalcMgrGetCurrentDate` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a dynamic system clock query, pinging the underlying EPM Java application server and returning the **Current Date** (strictly the year, month, and day) exactly at the moment the calculation script is executed.

### Why Does This Function Exist?

In robust EPM applications, calculations must frequently evaluate the "Current Date" without requiring the administrator to manually update a substitute variable every single morning. For example, if a script needs to calculate "Days Sales Outstanding" (DSO) based on today's date, or verify if an employee's hire date is in the past, the script must pull the live date automatically.
While Essbase has native functions like `@TODAY`, the native Essbase functions often return values in legacy formats that cannot be seamlessly passed into Calc Manager's advanced Java date-math functions (like `@CalcMgrDaysBetween`). 
`@CalcMgrGetCurrentDate` solves this by returning a pure **Java Date Object**. This object is completely compatible with the entire suite of Calc Manager custom date functions, ensuring you can calculate exact day differences, extract the current Year/Month, or format the date into a custom string dynamically.

### When to Use It

- **Dynamic Rolling Forecasts**: Identifying the exact current day to dynamically clear data from "Actuals" and begin the "Forecast" block.
- **Accrual Calculations**: Calculating the exact number of days between an invoice date and "Today" to calculate late-fee interest accruals.
- **Audit Logging**: Stamping the exact date a specific calculation script was executed into a central tracking cube.

---

## Category

**Date & Time / System Queries / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetCurrentDate()
```

*(Note: This function takes absolutely no parameters. Do not pass arguments into the parentheses).*

---

## Parameters

**None.**

---

## Return Value

**Return Type**: Object (Java Date)

Returns a Java Date Object representing the current server date (e.g., `Wed Dec 31 00:00:00 UTC 2024`).
- **CRITICAL**: Because this returns a Java Object, it **cannot** be saved directly into a standard Essbase numeric account cell. It must either be converted into an integer (using `@CalcMgrIntegerToDate` in reverse, or extracting the YYYYMMDD parts) or passed directly into another function.
- Note: This function zeros out the *time* component (Hours, Minutes, Seconds). It represents the start of the current day. If you need the exact time, use `@CalcMgrGetCurrentDateTime`.

---

## How It Works (Behind the Scenes)

1. **Server Ping**: The Java engine queries the host EPM server's operating system clock.
2. **Object Instantiation**: It creates a new `java.util.Date` or `java.util.Calendar` object.
3. **Truncation**: It strictly zeroes out the hour, minute, second, and millisecond fields, isolating just the Calendar Day.
4. **Return**: Passes the resulting Object back to Essbase for immediate use in other formulas.

---

## Syntax Variants & Scenarios

### Variant 1: Storing the Object in a Temporary Variable

```essbase
/* Captures today's date as an object in memory so it doesn't have to ping the server repeatedly */
VAR vToday = @CalcMgrGetCurrentDate();
```

---

## Practical Examples

### Example 1: Dynamic "Days Past Due" Calculation

**Scenario**: A treasury application tracks outstanding invoices. The invoice creation date is stored as a `YYYYMMDD` integer in `"Invoice_Date"`. Every night, an automated batch script runs to calculate exactly how many days have elapsed between the invoice date and "Today". If the invoice is more than 30 days old, it triggers a late fee calculation.

```essbase
FIX("FY25", "Working", @LEVEL0("Customers"), @LEVEL0("Invoices"))
    
    IF("Invoice_Date" != #MISSING AND "Invoice_Paid_Flag" == 0)
        
        /* 
           1. Get the current Server Date (Java Object)
        */
        VAR vTodayObj = @CalcMgrGetCurrentDate();
        
        /* 
           2. Convert the integer Invoice Date into a Java Object 
           so it can be mathematically compared.
        */
        VAR vInvoiceObj = @CalcMgrIntegerToDate("Invoice_Date");
        
        /* 
           3. Calculate the exact number of days between them.
           The "d" parameter tells the function to return Days.
        */
        "Days_Past_Due" = @CalcMgrDateTimeDiff(vInvoiceObj, vTodayObj, "d");
        
        /* 4. Apply Late Fees */
        IF("Days_Past_Due" > 30)
            "Calculated_Late_Fee" = "Invoice_Amount" * 0.05;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting Direct Storage | `"System_Date" = @CalcMgrGetCurrentDate();` | Essbase standard numeric accounts cannot hold Java Objects. If you try to save the result of this function directly into an account block, it will either throw a Type Mismatch validation error, or force the object into a completely useless hash string. You must convert it first (e.g., extracting the Year, Month, Day to build an integer) |
| Timezone Discrepancies | Assuming "Today" means the user's local timezone | This function returns the current date of the *physical Oracle EPM Server* (usually UTC), NOT the local timezone of the user running the rule. If a user in Sydney runs this rule at 8:00 AM on a Tuesday, the server in Chicago might still think it is Monday night. If your logic requires local timezone awareness, use `@CalcMgrGetCurrentDateTZ` instead |
| Performance Hits | Calling it 10,000 times in an IF loop | Pinging the server clock takes microscopic fractions of a second, but if you put this function *inside* a `FIX` loop containing 1 million members, it will ping the server 1 million times, slowing down your script. Always declare it as a `VAR` *outside* your `FIX` statements to capture the date once, and reuse that variable |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetCurrentDateTime`](./@CalcMgrGetCurrentDateTime.md) | Captures the exact current Time (Hours, Minutes, Seconds) in addition to the Date |
| [`@CalcMgrGetCurrentDateTZ`](./@CalcMgrGetCurrentDateTZ.md) | Captures the current date adjusted for a specific user-defined Timezone |
| [`@CalcMgrDateTimeDiff`](@CalcMgrDateDiff.md) | The primary function used to calculate the difference between the current date and historical dates |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getcurrentdate.html)
