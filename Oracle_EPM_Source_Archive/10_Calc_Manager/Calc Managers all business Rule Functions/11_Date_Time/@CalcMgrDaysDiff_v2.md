# @CalcMgrDaysDiff

## Overview

`@CalcMgrDaysDiff` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the exact number of calendar days between two standard Essbase `YYYYMMDD` integers. 

### Why Does This Function Exist—

Standard Essbase dates are stored as literal integers (e.g., `20241231`). You cannot perform standard subtraction on them (`20241231 - 20240101`) because the integer math does not understand that months have 30 or 31 days, or that leap years exist.
While `@CalcMgrDateDiff` can also calculate the difference in days (by passing `"day"` as the third parameter), `@CalcMgrDaysDiff` is a dedicated, streamlined function that assumes you *always* want the result in days. By dropping the third parameter, it makes the calculation script slightly cleaner and more readable for developers exclusively executing daily math.

### When to Use It

- To calculate **Days Sales Outstanding (DSO)** by finding the difference between an Invoice Date and the Current Date (stored as integers).
- To track project duration (in days) by subtracting the Project Start Date from the Project End Date.
- To execute working capital models that require the exact number of days between two arbitrary time points.
- Whenever you need to calculate days using `YYYYMMDD` integers without writing the verbose `"day"` string parameter required by `@CalcMgrDateDiff`.

---

## Category

**Date & Time / Math / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDaysDiff(fromDate, toDate)
```

### Formal Syntax

```
@CalcMgrDaysDiff(fromDateExpression, toDateExpression)
```

Where:
- `fromDateExpression` — The starting date, formatted as a standard `YYYYMMDD` integer.
- `toDateExpression` — The ending date, formatted as a standard `YYYYMMDD` integer.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `fromDate`| Integer | ✅ Yes | The starting date (`YYYYMMDD`). Can be a hardcoded number or an account containing the date integer. |
| `toDate`  | Integer | ✅ Yes | The ending date (`YYYYMMDD`). If this date is *before* the `fromDate`, the function will return a negative number. |

---

## Return Value

**Return Type**: Integer / Numeric

Returns a numeric value representing the exact number of calendar days between the two dates.
- If `toDate` is later than `fromDate`, the result is positive.
- If `toDate` is earlier than `fromDate`, the result is negative.
- If the dates are identical, the result is `0`.

---

## How It Works (Behind the Scenes)

1. **Format Validation**: The function receives the two `YYYYMMDD` integers. 
2. **Calendar Initialization**: It spins up two internal `java.util.GregorianCalendar` objects representing the exact days.
3. **Difference Calculation**: It calculates the absolute chronological difference between the two calendars in milliseconds.
4. **Conversion**: It divides the milliseconds into exactly 24-hour days, dropping any fractional artifacts, and returns a clean integer to the Essbase calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Difference

```essbase
/* Returns the number of days between Nov 1 and Dec 31 (Returns 60) */
"Days_Between" = @CalcMgrDaysDiff(20241101, 20241231);
```

### Variant 2: Conditional Evaluation (Is it overdue—)

```essbase
/* If the project ended more than 30 days after its target date, flag it */
IF(@CalcMgrDaysDiff("Target_End_Date", "Actual_End_Date") > 30)
    "Overdue_Flag" = 1;
ENDIF
```

---

## Practical Examples

### Example 1: Daily Revenue Proration

**Scenario**: A company sells subscriptions. You have a "Subscription_Start" date and a "Subscription_End" date stored as integers. You need to calculate the exact number of days the subscription spans so you can divide the total contract value into a daily rate for proration.

```essbase
FIX("FY25", "Working", @LEVEL0("Customer"))
    
    /* Ensure both dates have been populated */
    IF("Subscription_Start" != #MISSING AND "Subscription_End" != #MISSING)
        
        /* Calculate the total lifespan in days */
        "Total_Contract_Days" = @CalcMgrDaysDiff("Subscription_Start", "Subscription_End");
        
        /* Calculate the daily revenue rate */
        IF("Total_Contract_Days" > 0)
            "Daily_Revenue_Rate" = "Total_Contract_Value" / "Total_Contract_Days";
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Calculating Age of Inventory

**Scenario**: A retail model tracks when a batch of inventory arrived at the warehouse (`"Arrival_Date"`). You want to know exactly how old the inventory is relative to the current system date.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* 1. Get the current date in YYYYMMDD format */
    VAR vToday = @CalcMgrConvertJavaDateToDate(@CalcMgrGetCurrentDate());
    
    /* 2. Check the difference in days */
    IF("Arrival_Date" != #MISSING)
        
        /* If today is past the arrival date, this will be positive */
        "Inventory_Age_Days" = @CalcMgrDaysDiff("Arrival_Date", vToday);
        
        /* Apply to aging buckets */
        IF("Inventory_Age_Days" > 365)
            "Inventory_Status" = 2; /* Obsolete / Aging */
        ELSE
            "Inventory_Status" = 1; /* Fresh */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrDaysDiff(vJavaDate1, vJavaDate2)` | This function strictly expects Essbase integers (`YYYYMMDD`). If you pass raw Java Date objects, the function will fail. If you have Java Dates, use `@CalcMgrDaysBetween` instead |
| Passing Strings | `@CalcMgrDaysDiff("2024-12-31", "2025-01-01")` | The engine will evaluate the strings as `0` or throw an error. The dates must be `YYYYMMDD` numbers. If you have strings, convert them first |
| Reversing the order | Putting the newer date first | `DaysDiff(20241231, 20240101)` will yield a negative number (`-364`). Always put the older/starting date in parameter 1, and the newer/target date in parameter 2 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDateDiff`](./@CalcMgrDateDiff.md) | The generic version of this function that allows you to calculate Months, Weeks, or Years instead of just Days |
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | The exact equivalent function, but designed specifically for internal Java Date objects rather than integers |
| [`@CalcMgrDaysToDate`](../15_CalcMgr_Utility/@CalcMgrConvertDateToJavaDate.md) | Reverses the logic (takes a number of days and turns it into a calendar date) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_daysdiff.html)
