# @CalcMgrWeeksBetween

## Overview

`@CalcMgrWeeksBetween` is a **custom Calc Manager date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the exact **integer number of full weeks** that exist between two provided **Java Date Objects**.

### Why Does This Function Exist?

In retail, manufacturing, and HR planning, business logic is frequently driven by weekly cycles rather than monthly cycles (e.g., 4-4-5 accounting calendars, weekly payroll, or weekly supply chain lead times).
If an administrator needs to calculate how many weeks a temporary contractor has been active, standard Essbase math fails. Subtracting two integers (e.g., `20240215 - 20240101 = 114`) yields a mathematically useless number.
`@CalcMgrWeeksBetween` solves this by relying on the Java Calendar engine. By passing two Date Objects, the engine calculates the exact calendar delta in milliseconds, converts it to days, and divides by 7 to return the absolute integer number of *full* weeks (e.g., `6`) that sit between the two dates. 

### When to Use It

- **Weekly Payroll Models**: Calculating exactly how many weekly pay periods occurred between an employee's hire date and the end of the quarter.
- **Manufacturing Lead Times**: Determining how many full weeks of buffer inventory exist between a target shipping date and the current date.
- **4-4-5 Calendar Mapping**: Dynamically calculating weekly offsets to map standard Gregorian dates into a custom retail financial calendar.

---

## Category

**Date & Time / Date Differences / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrWeeksBetween(from_date, to_date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | Object | ✅ Yes | The starting Java Date Object (the older date). |
| `to_date` | Object | ✅ Yes | The ending Java Date Object (the newer date). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the pure integer number of full weeks between the two dates.
- **Directionality (CRITICAL)**: Unlike basic subtraction, this function is NOT absolute. 
  - If `from_date` is BEFORE `to_date` (e.g., Jan to March), it returns a **positive** integer (e.g., `8`).
  - If `from_date` is AFTER `to_date` (e.g., March to Jan), it returns a **negative** integer (e.g., `-8`).
- **Rounding Logic**: This function rounds *down* to the nearest full week based on 7-day increments. If the gap is 1 week and 6 days (13 days), it still returns `1`. It does not return decimals.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the two Date Objects.
2. **Delta Extraction**: It extracts the exact milliseconds since the Unix Epoch (1970) for both dates.
3. **Mathematical Delta**: It calculates the difference: `(Time2 - Time1)`.
4. **Division**: It divides the millisecond delta by `604800000` (the exact number of milliseconds in a 7-day week).
5. **Truncation**: It truncates the fractional remainder (effectively rounding down to the nearest integer week).
6. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard Positive Week Gap

```essbase
/* 
   Assumes Start is Jan 1, 2024. End is Jan 15, 2024.
   Exactly 14 days difference. 14 / 7 = 2.
   Returns 2. 
*/
VAR vWeeksElapsed = @CalcMgrWeeksBetween(vStartObj, vEndObj);
```

---

## Practical Examples

### Example 1: Calculating Contractor Accruals by Week

**Scenario**: A company pays contractors weekly. The contractor's `Start_Date` and `End_Date` are stored as `YYYYMMDD` integers. The script must calculate exactly how many weeks the contract spanned, and multiply that by their `Weekly_Rate` to calculate the total accrued expense for the project.

```essbase
FIX("Working", @LEVEL0("Contractors"))
    
    IF("Weekly_Rate" > 0 AND "Start_Date" != #MISSING)
        
        /* 1. Convert the integer dates into Java Objects */
        VAR vStartObj = @CalcMgrIntegerToDate("Start_Date");
        VAR vEndObj = @CalcMgrIntegerToDate("End_Date");
        
        /* 
           2. Calculate the total number of full weeks they worked.
           (e.g., Jan 1 to Jan 22 = 3 weeks).
        */
        VAR vTotalWeeks = @CalcMgrWeeksBetween(vStartObj, vEndObj);
        
        /* 
           3. Add 1 if you need inclusive billing 
           (e.g., billing for the week of the start date + elapsed weeks)
        */
        vTotalWeeks = vTotalWeeks + 1;
        
        /* 4. Calculate the Total Expense */
        "Total_Contract_Expense" = "Weekly_Rate" * vTotalWeeks;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@CalcMgrWeeksBetween(20240101, 20240115)` | This is the most common error. This function strictly requires **Java Date Objects**. If you pass native Essbase integers, the script will crash or calculate massive negative numbers. Always use `@CalcMgrIntegerToDate` first |
| Swapping Parameters | Passing `(End_Date, Start_Date)` | Order is critical. If you accidentally pass the newer date first, the function will output a **negative number**. If you multiply an expense by `-3` instead of `3`, your financial model will invert. Always pass the older date first, or use `@ABS()` to force the result positive |
| Relying on Calendar Weeks | Crossing a Sunday boundary | This function strictly calculates mathematical 7-day increments (`Days / 7`). It does NOT look at what day of the week it is. If you start on Saturday and end on Monday, they are in different "Calendar Weeks", but this function will return `0` because 7 days have not elapsed. If you need strict calendar week logic, you must use `@CalcMgrGetWeekOfYear` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrWeeksDiff`](./@CalcMgrWeeksDiff.md) | The fractional counterpart. Instead of rounding down to an integer (e.g., `1`), it returns the exact fractional week (e.g., `1.85`), useful for partial proration |
| [`@CalcMgrDaysBetween`](../11_Date_Time/@CalcMgrDaysBetween.md) | Calculates the exact number of days between two dates rather than weeks |
| [`@CalcMgrGetWeekOfYear`](../11_Date_Time/@CalcMgrGetWeekOfYear.md) | Extracts the specific week number of the year (1-52), useful if you need to know if two dates exist in different calendar weeks rather than just mathematical 7-day gaps |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_weeksbetween.html)
