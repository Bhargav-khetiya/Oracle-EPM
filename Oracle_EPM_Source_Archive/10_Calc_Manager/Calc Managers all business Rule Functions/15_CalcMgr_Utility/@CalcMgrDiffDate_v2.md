# @CalcMgrDiffDate

## Overview

`@CalcMgrDiffDate` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the mathematical difference between two dates, returning the result in a specified unit (days, months, weeks, or years).

### Why Does This Function Exist?

This function is functionally identical to [`@CalcMgrDateDiff`](../11_Date_Time/@CalcMgrDateDiff.md). The existence of both `@CalcMgrDiffDate` and `@CalcMgrDateDiff` in the Calc Manager library is an artifact of the library's historical evolution. Over time, as Oracle merged different custom function libraries (such as CDFs from classic Essbase and Groovy-based functions), duplicate naming conventions emerged. 
`@CalcMgrDateDiff` is generally the more modern and widely documented standard, but `@CalcMgrDiffDate` remains fully supported to ensure backward compatibility with older calculation scripts that rely on it.

### When to Use It

- To calculate **Days Sales Outstanding (DSO)** by finding the difference between an Invoice Date and the Current Date.
- To calculate an employee's tenure (in months or years) by finding the difference between their Hire Date and the Current Date.
- Generally, you should prefer `@CalcMgrDateDiff` for new development, but use this if you are maintaining a legacy script.

---

## Category

**Date & Time / Math / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDiffDate(fromDate, toDate, "datePart")
```

### Formal Syntax

```
@CalcMgrDiffDate(fromDateExpression, toDateExpression, "datePartString")
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

1. **Format Validation**: The function receives the two `YYYYMMDD` integers. 
2. **Calendar Initialization**: It initializes two internal `java.util.GregorianCalendar` objects representing the exact days.
3. **Difference Calculation**: It calculates the absolute chronological difference between the two calendars.
4. **Unit Conversion**: Based on your `"datePart"`, it converts that difference into the requested integer unit (e.g., days or months). Month and Year differences are truncated to the nearest whole integer.

---

## Syntax Variants & Scenarios

### Variant 1: Difference in Days

```essbase
/* Returns the number of days between Nov 1 and Dec 31 (Returns 60) */
"Days_Between" = @CalcMgrDiffDate(20241101, 20241231, "day");
```

### Variant 2: Difference in Months (Tenure)

```essbase
/* Calculates how many whole months an employee has worked */
"Tenure_Months" = @CalcMgrDiffDate("Hire_Date", @CalcMgrConvertJavaDateToDate(@CalcMgrGetCurrentDate()), "month");
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
        "Useful_Life_Months" = @CalcMgrDiffDate("In_Service_Date", "Retirement_Date", "month");
        
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
        "Days_Past_Due" = @CalcMgrDiffDate("Due_Date", vToday, "day");
        
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
| Passing Java Dates | `@CalcMgrDiffDate(vJavaDate1, vJavaDate2, "day")` | This function strictly expects Essbase integers (`YYYYMMDD`). If you pass raw Java Date objects (which are massive 13-digit millisecond timestamps), the function will fail. If you have Java Dates, use `@CalcMgrDaysBetween` or `@CalcMgrDateTimeDiff` instead |
| Passing Strings | `@CalcMgrDiffDate("2024-12-31", "2025-01-01", "day")` | The engine will evaluate the strings as `0` or throw an error. The dates must be `YYYYMMDD` numbers |
| Fractional Return Values | Expecting 1.5 months to return `1.5` | Calendar math in Java truncates to the lowest whole integer for months and years. If you need hyper-precision, calculate the difference in `"day"` and divide by `30.416` (average days in a month) yourself |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDateDiff`](../11_Date_Time/@CalcMgrDateDiff.md) | The more commonly used, identical twin of this function |
| [`@CalcMgrDaysDiff`](../11_Date_Time/@CalcMgrDaysDiff.md) | A streamlined version that explicitly calculates days, removing the need for the `"day"` string parameter |
| [`@CalcMgrDaysBetween`](../11_Date_Time/@CalcMgrDaysBetween.md) | Calculates days between two *Java Date* objects (not Essbase integers) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_diffdate.html)
