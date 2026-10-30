# @CalcMgrExcelDAYSINMONTH

## Overview

`@CalcMgrExcelDAYSINMONTH` is a **custom Calc Manager date evaluation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts similarly to native Microsoft Excel date math, taking a specific Year and Month and returning the exact total number of calendar days in that month (e.g., returning `28`, `29`, `30`, or `31`).

### Why Does This Function Exist?

When calculating daily prorations in financial models (e.g., daily interest expense, daily rent, or allocating an annual budget down to a daily curve), you must know exactly how many days are in the month being calculated. 
If an employee is hired on March 15th, they worked 17 days out of a 31-day month. If they are hired on April 15th, they worked 16 days out of a 30-day month.
While you can theoretically build a massive `IF` statement in Essbase to check the month number (`IF(Month == 4 OR Month == 6 OR Month == 9...)`), doing so fails spectacularly for February, which alternates between 28 and 29 days depending on leap years. `@CalcMgrExcelDAYSINMONTH` resolves this instantly. You pass it the Year and Month, and the underlying Java engine automatically handles all calendar mapping (including complex leap-year algorithms), returning the exact denominator for your daily proration math.

### When to Use It

- **Daily Proration**: Determining the correct denominator when prorating mid-month hires, lease starts, or debt issuances.
- **Allocation Drivers**: Spreading a quarterly value evenly across the months based on the number of days in each month.
- **Calendar Boundary Math**: Determining the exact date of the end of the month (e.g., creating a date where `Day = @CalcMgrExcelDAYSINMONTH(Year, Month)`).

---

## Category

**Date & Time / Math / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDAYSINMONTH(year, month)
```

*(Note: While Excel doesn't have an explicit `DAYSINMONTH` function—users usually hack it using `=DAY(EOMONTH(date, 0))`—this Oracle function provides the direct equivalent).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `year` | Numeric | ✅ Yes | The 4-digit year (e.g., `2024`). The year is mandatory because it dictates the leap-year logic for February. |
| `month` | Numeric | ✅ Yes | The month number (from `1` to `12`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the exact number of days in the specified month.
- Typical return values are `28`, `29`, `30`, or `31`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine receives the Year and Month integers.
2. **Standard Evaluation**: For months 1, 3, 5, 7, 8, 10, and 12, it immediately returns `31`. For months 4, 6, 9, and 11, it returns `30`.
3. **Leap Year Algorithm**: If the `month` is `2`, it evaluates the `year`. If the year is evenly divisible by 4 (and not divisible by 100, unless it is also divisible by 400), it identifies a leap year and returns `29`. Otherwise, it returns `28`.
4. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding February Days in a Leap Year

```essbase
/* Year 2024 is a leap year. Month 2. Returns 29. */
"Days_In_Feb" = @CalcMgrExcelDAYSINMONTH(2024, 2);
```

### Variant 2: Combining with Extracted Date Parts

```essbase
/* Dynamically extracting the year and month from an invoice date */
VAR vDays = @CalcMgrExcelDAYSINMONTH(
    @CalcMgrExcelYEAR("Invoice_Date"), 
    @CalcMgrExcelMONTH("Invoice_Date")
);
```

---

## Practical Examples

### Example 1: Prorating a Mid-Month Lease Start

**Scenario**: A property management company signs a new tenant mid-month. The lease stipulates that partial months are prorated strictly based on the exact calendar days of that specific month. The lease starts on September 12, 2024. You need to calculate how many days are in September to determine the daily rent rate, and then charge them for the days they occupied the space.

```essbase
FIX("FY25", "Working", @LEVEL0("Leases"))
    
    IF("Lease_Start_Date" != #MISSING AND "Monthly_Rent" > 0)
        
        /* 1. Extract the Date Components */
        VAR vStartYear  = @CalcMgrExcelYEAR("Lease_Start_Date");
        VAR vStartMonth = @CalcMgrExcelMONTH("Lease_Start_Date");
        VAR vStartDay   = @CalcMgrExcelDAY("Lease_Start_Date");
        
        /* 2. Find the total days in that specific month (Denominator) */
        VAR vTotalDaysInMonth = @CalcMgrExcelDAYSINMONTH(vStartYear, vStartMonth);
        
        /* 3. Calculate the Daily Rent Rate */
        VAR vDailyRent = "Monthly_Rent" / vTotalDaysInMonth;
        
        /* 4. Calculate the Days Occupied (Total - Start + 1) 
           e.g., September: 30 - 12 + 1 = 19 days */
        VAR vDaysOccupied = vTotalDaysInMonth - vStartDay + 1;
        
        /* 5. Calculate Final First-Month Prorated Revenue */
        "Prorated_Rent_Revenue" = vDailyRent * vDaysOccupied;
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Forcing a Date to the Exact End of the Month

**Scenario**: You have an open invoice with an `"Invoice_Date"`. The company policy dictates that the `"Due_Date"` is strictly the very last day of the *next* month. If the invoice is in January, it's due Feb 28 (or 29). If it's in March, it's due April 30. You must figure out exactly what day that is.

```essbase
FIX("FY25", "Working", @LEVEL0("Invoice"))
    
    IF("Invoice_Date" != #MISSING)
        
        VAR vInvYear  = @CalcMgrExcelYEAR("Invoice_Date");
        VAR vInvMonth = @CalcMgrExcelMONTH("Invoice_Date");
        
        /* Shift to the next month */
        VAR vNextMonth = vInvMonth + 1;
        VAR vNextYear = vInvYear;
        
        /* Handle December rollover */
        IF(vNextMonth == 13)
            vNextMonth = 1;
            vNextYear = vNextYear + 1;
        ENDIF
        
        /* Find exactly how many days are in that target month */
        VAR vLastDay = @CalcMgrExcelDAYSINMONTH(vNextYear, vNextMonth);
        
        /* Construct the final due date using the components */
        "Due_Date_Serial" = @CalcMgrExcelDATE(vNextYear, vNextMonth, vLastDay);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a Full Date | `@CalcMgrExcelDAYSINMONTH("Invoice_Date")` | This function expects TWO distinct parameters: the Year and the Month. If you pass a single 8-digit date integer (like `20241025`), the function will fail. You must extract the year and month first using the respective extraction functions |
| Hardcoding Leap Years | Writing `IF(Year==2024)` in Essbase | Do not try to write your own leap year logic when passing data to this function. Simply pass the Year variable directly, and the Java engine will handle the math perfectly |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelYEAR`](./@CalcMgrExcelYEAR.md) | Extracts the Year component from a date (used as Param 1) |
| [`@CalcMgrExcelMONTH`](./@CalcMgrExcelMONTH.md) | Extracts the Month component from a date (used as Param 2) |
| [`@CalcMgrExcelDAYOFYEAR`](./@CalcMgrExcelDAYOFYEAR.md) | Calculates the day's position out of 365/366, rather than the days in a specific month |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldaysinmonth.html)
