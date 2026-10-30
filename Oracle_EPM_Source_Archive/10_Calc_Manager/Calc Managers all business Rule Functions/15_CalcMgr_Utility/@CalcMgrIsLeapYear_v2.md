# @CalcMgrIsLeapYear

## Overview

`@CalcMgrIsLeapYear` is a **custom Calc Manager boolean calendar utility** in Oracle EPM Cloud (PBCS/EPBCS). It analyzes a **Java Date Object** (or Java Timestamp Object) and returns a simple Boolean (`true` or `false`) indicating whether the year contained within that date is a leap year (having 366 days instead of 365).

### Why Does This Function Exist?

In robust financial models, daily proration is critical. If a software company charges `$10,000` a year for a license, and a customer starts on July 1st, they must calculate the daily rate and multiply it by the remaining days. 
However, what is the daily rate? Is it `$10,000 / 365`? Or is it `$10,000 / 366`? If you hardcode `365` as the denominator in your Essbase scripts, your daily accrual math will break every 4 years, creating massive reconciliation imbalances in global ledgers. 
Calculating leap years mathematically inside an Essbase script is highly complex (the year must be divisible by 4, but NOT divisible by 100, UNLESS it is also divisible by 400). 
`@CalcMgrIsLeapYear` completely bypasses this logic. It taps directly into the Java Calendar engine, natively evaluates the year against standard Gregorian leap rules, and instantly returns `true` if it is a leap year. This allows your scripts to dynamically toggle between a 365 and 366 denominator effortlessly.

### When to Use It

- **Annual Proration**: Dynamically setting the denominator to `365` or `366` when calculating the daily run-rate of an annual contract.
- **Depreciation Calculation**: Ensuring strict daily depreciation models apply the correct fractional scaling across a leap year.
- **Calendar Construction**: Building custom multi-year forecast dates and correctly allowing February 29th to exist only when valid.

---

## Category

**Date & Time / Logic & Validation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrIsLeapYear(date)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Object | ✅ Yes | The Java Date/Timestamp Object to be evaluated. |

---

## Return Value

**Return Type**: Boolean (`true` or `false`)

Returns `true` (evaluates to `1` in Essbase IF statements) if the year is a leap year.
Returns `false` (`0`) if it is a standard 365-day year.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Date Object.
2. **Object Interrogation**: It instantiates a `java.util.GregorianCalendar` object based on the provided date.
3. **Execution**: It executes the native Java `GregorianCalendar.isLeapYear(year)` method, evaluating the exact year against the strict mathematical rules (mod 4, mod 100, mod 400).
4. **Return**: Passes the finalized Boolean back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Checking the Current Year

```essbase
/* 
   Assumes Today is sometime in 2024. 
   2024 is a leap year, so it returns true (1). 
*/
IF(@CalcMgrIsLeapYear(@CalcMgrGetCurrentDate()))
    "Total_Days_In_Year" = 366;
ENDIF
```

---

## Practical Examples

### Example 1: Dynamic Daily Revenue Recognition Denominator

**Scenario**: A SaaS company uses daily revenue recognition. When a contract is signed, the Annual Value must be divided by the total number of days in the current fiscal year to establish the exact daily rate. The script dynamically evaluates the year to determine the correct denominator.

```essbase
FIX("Working", @LEVEL0("Customers"))
    
    IF("Annual_Contract_Value" > 0 AND "Contract_Start_Date" != #MISSING)
        
        /* 1. Convert the Essbase YYYYMMDD integer into a Java Date Object */
        VAR vStartDateObj = @CalcMgrIntegerToDate("Contract_Start_Date");
        
        /* 2. Determine the Denominator dynamically */
        VAR vDenominator = 365;
        
        /* 
           3. Ask Java if the object belongs to a Leap Year. 
           If true, override the denominator to 366.
        */
        IF(@CalcMgrIsLeapYear(vStartDateObj))
            vDenominator = 366;
        ENDIF
        
        /* 4. Calculate the perfect daily rate */
        "Calculated_Daily_Rate" = "Annual_Contract_Value" / vDenominator;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing an Integer Year | `@CalcMgrIsLeapYear(2024)` | This is the most common mistake. This function explicitly requires a **Java Date Object**, NOT a raw 4-digit integer. If you pass `2024`, the Java engine will treat it as a massive serial number or crash. You must convert `2024` into a Date Object first (e.g., using `@CalcMgrGetCustomDate(2024, 0, 1)`) |
| Passing a YYYYMMDD Integer | `@CalcMgrIsLeapYear(20241231)` | Same as above. You cannot pass Essbase integers. Use `@CalcMgrIntegerToDate` to wrap the integer before passing it into this function |
| Attempting Direct Math | `Value * @CalcMgrIsLeapYear(Obj)` | Because this returns a Boolean (`true` or `false`), it translates to `1` or `0` in Essbase. If you multiply a value by it, you will either get the same value (if leap year) or `0`. Always use this function inside an `IF` statement condition block |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetMaxDaysInMonth`](../11_Date_Time/@CalcMgrGetMaxDaysInMonth.md) | While `IsLeapYear` checks the whole year, `GetMaxDaysInMonth` checks a specific month. It inherently understands leap years and will automatically return `29` for February if necessary |
| [`@CalcMgrGetDayOfYear`](../11_Date_Time/@CalcMgrGetDayOfYear.md) | Automatically adjusts its output (`1-366`) based on whether the internal object is a leap year or not |
| [`@CalcMgrIntegerToDate`](@CalcMgrConvertDateToJavaDate.md) | The wrapper function required to convert an Essbase `YYYYMMDD` integer into the object this function requires |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_isleapyear.html)
