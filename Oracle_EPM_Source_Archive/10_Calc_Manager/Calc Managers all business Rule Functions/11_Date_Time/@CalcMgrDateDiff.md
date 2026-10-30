# @CalcMgrDateDiff

## Overview

`@CalcMgrDateDiff` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the mathematical difference between two calendar dates, returning the result in a specified unit of measurement (such as days, months, weeks, or years).

### Why Does This Function Exist?

Standard Essbase dates are typically stored as literal `YYYYMMDD` integers (e.g., `20241231` and `20241101`). If you simply subtract one from the other (`20241231 - 20241101 = 130`), the result is a mathematically meaningless number because the integer system does not understand leap years, differing month lengths, or calendar logic.
`@CalcMgrDateDiff` bridges this gap. It takes two standard Essbase `YYYYMMDD` integers, translates them internally into Java calendar objects, calculates the true chronological span between them accounting for all calendar rules, and returns that duration exactly in the unit you requested.

### When to Use It

- To calculate **Days Sales Outstanding (DSO)** by finding the difference between an Invoice Date and the Current Date.
- To calculate an employee's tenure (in months or years) by finding the difference between their Hire Date and the Current Date.
- To determine the lifespan of an asset (in months) for depreciation schedules by comparing the In-Service Date to the Retirement Date.
- To measure compliance against SLA (Service Level Agreement) deadlines.

---

## Category

**Date & Time / Math / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDateDiff(fromDate, toDate, "datePart")
```

### Formal Syntax

```
@CalcMgrDateDiff(fromDateExpression, toDateExpression, "datePartString")
```

Where:
- `fromDateExpression` — The starting date, formatted as a standard `YYYYMMDD` integer.
- `toDateExpression` — The ending date, formatted as a standard `YYYYMMDD` integer.
- `"datePartString"` — A string indicating the unit of measurement for the returned duration (e.g., `"day"`, `"month"`). Must be in double quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `fromDate`| Integer | ✅ Yes | The starting date (`YYYYMMDD`). Can be a hardcoded number or an account containing the date integer. |
| `toDate`  | Integer | ✅ Yes | The ending date (`YYYYMMDD`). If this date is *before* the `fromDate`, the function will return a negative number. |
| `"datePart"`| String| ✅ Yes | The unit of measurement. Acceptable values (case-insensitive): `"day"`, `"week"`, `"month"`, `"year"`. |

---

## Return Value

**Return Type**: Integer / Numeric

Returns a numeric value representing the elapsed time between the two dates in the specified unit.
- If `toDate` is later than `fromDate`, the result is positive.
- If `toDate` is earlier than `fromDate`, the result is negative.
- If the dates are identical, the result is `0`.

---

## How It Works (Behind the Scenes)

1. **Format Validation**: The function receives the two `YYYYMMDD` integers. If you pass an invalid date (like `20241599`), the internal Java parser will attempt to roll it forward (e.g., treating month 15 as March of the next year), but this often leads to unpredictable results. The dates must be valid.
2. **Calendar Initialization**: It spins up two internal `java.util.GregorianCalendar` objects representing the exact days.
3. **Difference Calculation**: It calculates the absolute chronological difference between the two calendars.
4. **Unit Conversion**: Based on your `"datePart"`, it converts that difference into the requested integer unit. (Note: Month and Year differences are often truncated to the nearest whole integer, rather than returning fractions. E.g., a difference of 1.5 months will return `1`).

---

## Syntax Variants & Scenarios

### Variant 1: Difference in Days

```essbase
/* Returns the number of days between Nov 1 and Dec 31 (Returns 60) */
"Days_Between" = @CalcMgrDateDiff(20241101, 20241231, "day");
```

### Variant 2: Difference in Months (Tenure)

```essbase
/* Calculates how many whole months an employee has worked */
"Tenure_Months" = @CalcMgrDateDiff("Hire_Date", @CalcMgrGetCurrentDate(), "month");
```

---

## Practical Examples

### Example 1: Calculating Asset Depreciation Lifespan

**Scenario**: A Capex model stores the "In_Service_Date" (when the asset starts depreciating) and the "Retirement_Date" (when it stops) as `YYYYMMDD` integers. You need to calculate exactly how many months the asset will be active so you can divide the total cost evenly across those months.

```essbase
FIX("FY25", "Working", @LEVEL0("Asset"))
    
    /* Ensure both dates have been populated */
    IF("In_Service_Date" != #MISSING AND "Retirement_Date" != #MISSING)
        
        /* Calculate the total lifespan in months */
        "Useful_Life_Months" = @CalcMgrDateDiff("In_Service_Date", "Retirement_Date", "month");
        
        /* Calculate monthly depreciation expense */
        IF("Useful_Life_Months" > 0)
            "Monthly_Depreciation" = "Asset_Cost" / "Useful_Life_Months";
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Accounts Receivable Aging Buckets

**Scenario**: You want to flag invoices based on how many days past due they are. You compare the Invoice Due Date to the current system date.

```essbase
FIX("FY25", "Working", @LEVEL0("Invoice"))
    
    /* 1. Get the current date in YYYYMMDD format */
    VAR vToday = @CalcMgrConvertJavaDateToDate(@CalcMgrGetCurrentDate());
    
    /* 2. Check the difference in days */
    IF("Due_Date" != #MISSING)
        
        /* If today is past the due date, this will be positive */
        "Days_Past_Due" = @CalcMgrDateDiff("Due_Date", vToday, "day");
        
        /* Apply to aging buckets */
        IF("Days_Past_Due" > 90)
            "Aging_Bucket" = 4; /* Over 90 Days */
        ELSEIF("Days_Past_Due" > 60)
            "Aging_Bucket" = 3; /* 61-90 Days */
        ELSEIF("Days_Past_Due" > 30)
            "Aging_Bucket" = 2; /* 31-60 Days */
        ELSEIF("Days_Past_Due" > 0)
            "Aging_Bucket" = 1; /* 1-30 Days */
        ELSE
            "Aging_Bucket" = 0; /* Current / Not Due */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrDateDiff(vJavaDate1, vJavaDate2, "day")` | This function strictly expects Essbase integers (`YYYYMMDD`). If you pass raw Java Date objects (which are massive 13-digit millisecond timestamps), the function will fail. If you have Java Dates, use `@CalcMgrDaysBetween` or `@CalcMgrDateTimeDiff` instead |
| Passing Strings | `@CalcMgrDateDiff("2024-12-31", "2025-01-01", "day")` | The engine will evaluate the strings as `0` or throw an error. The dates must be `YYYYMMDD` numbers |
| Fractional Return Values | Expecting 1.5 months to return `1.5` | Calendar math in Java often truncates to the lowest whole integer for months and years. If you need hyper-precision, calculate the difference in `"day"` and divide by `30.416` (average days in a month) yourself |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | Specifically calculates days between two *Java Date* objects (not Essbase integers) |
| [`@CalcMgrDateTimeDiff`](./@CalcMgrDateTimeDiff.md) | Calculates the difference between two Java Date objects, allowing for `"hour"` and `"minute"` parts |
| [`@CalcMgrAddDatePart`](./@CalcMgrAddDatePart.md) | Adds a duration to a date, rather than finding the difference between two dates |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_datediff.html)
