# @CalcMgrGetCustomDate

## Overview

`@CalcMgrGetCustomDate` is a **custom Calc Manager date instantiation function** in Oracle EPM Cloud (PBCS/EPBCS). It takes three distinct integers (Year, Month, and Day) and systematically fuses them together into a highly precise **Java Date Object**.

### Why Does This Function Exist?

When building calculation scripts that forecast future operations, administrators frequently need to construct dynamic dates. For example, calculating the "Contract Renewal Date" by extracting the Year from a start date, adding 5 to it, and keeping the same Month and Day. 
Once those new mathematical integers (e.g., Year = `2029`, Month = `10`, Day = `15`) are calculated, they must be converted back into a unified Date Object so they can be passed into downstream date-math functions like `@CalcMgrDaysBetween`.
While Essbase can easily concatenate integers into a `YYYYMMDD` integer (`20291015`), a pure integer is completely useless if you want to use the advanced Java calendar engine to calculate time differences or day-of-week logic. `@CalcMgrGetCustomDate` perfectly constructs a true Java Date Object from the raw integer components, instantly validating the calendar logic (e.g., automatically rolling over if you accidentally pass "Day 32") and returning an object ready for advanced Java processing.

### When to Use It

- **Dynamic Forecasting**: Constructing future milestone dates (e.g., Year + 3) to test against SLA deadlines.
- **Data Integration Cleanup**: Reassembling dates from a flat file where the Year, Month, and Day were loaded into three separate Essbase numeric accounts.
- **Contract Expiration Logic**: Building a strict "End of Year" object (Current Year, 12, 31) to dynamically calculate how many days are left in the current fiscal period.

---

## Category

**Date & Time / Object Instantiation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetCustomDate(year, month, day)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `year` | Numeric | ✅ Yes | A four-digit integer representing the Year (e.g., `2024`). |
| `month` | Numeric | ✅ Yes | An integer representing the Month. <br>**CRITICAL RULE**: In Java Calendar architecture, months are 0-indexed. January is `0`, December is `11`. (If you pass `12`, it will roll over to January of the *next* year). |
| `day` | Numeric | ✅ Yes | An integer representing the Day of the Month (e.g., `1` to `31`). |

---

## Return Value

**Return Type**: Object (Java Date)

Returns a highly precise Java Date Object.
- **CRITICAL**: Because this returns a Java Object, it **cannot** be saved directly into a standard Essbase numeric account cell. It must either be converted into an integer (using `@CalcMgrFormatDate` to force `YYYYMMDD` format) or passed directly into another date-math function.
- Note: This function zeros out the *time* component (Hours, Minutes, Seconds). It represents exactly Midnight (00:00:00) of the constructed day.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the three integers.
2. **Object Instantiation**: It creates a new `java.util.Calendar` object.
3. **Property Injection**: It sets the `Calendar.YEAR`, `Calendar.MONTH`, and `Calendar.DAY_OF_MONTH` properties using your integers.
4. **Calendar Validation (Rollover)**: Java's calendar engine is smart. If you pass `month = 1` (February) and `day = 30`, it will realize February 30th does not exist. It will automatically roll the calendar forward to March 1st or March 2nd (depending on leap years).
5. **Truncation**: It zeroes out the Hours, Minutes, and Seconds.
6. **Return**: Passes the finalized Java Date Object back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Creating a Strict End-of-Year Date Object

```essbase
/* 
   Year: 2024
   Month: 11 (December, because Java months are 0-indexed)
   Day: 31
   Result: Creates a Java Date Object for Dec 31, 2024.
*/
VAR vEndOfYearObj = @CalcMgrGetCustomDate(2024, 11, 31);
```

---

## Practical Examples

### Example 1: Calculating Days Remaining Until Year-End

**Scenario**: A treasury model calculates daily interest on corporate cash balances. It must calculate exactly how many days remain between "Today" and December 31st of the current year. The script dynamically extracts the current year, constructs a December 31st Object, and calculates the difference.

```essbase
FIX("FY25", "Working", "No_Entity")
    
    /* 1. Get Today's Date as a Java Object */
    VAR vTodayObj = @CalcMgrGetCurrentDate();
    
    /* 2. Extract the current 4-digit Year from Today */
    VAR vCurrentYear = @CalcMgrGetDatePart(vTodayObj, "year");
    
    /* 
       3. Construct a Custom Date Object for Dec 31st of this specific year.
       Remember: Month 11 is December!
    */
    VAR vDec31Obj = @CalcMgrGetCustomDate(vCurrentYear, 11, 31);
    
    /* 
       4. Calculate the exact number of Days between Today and Dec 31st.
    */
    "Days_Remaining_In_Year" = @CalcMgrDateTimeDiff(vTodayObj, vDec31Obj, "d");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting Month is 0-Indexed | Passing `12` for December | In Java (and thus in this function), months are `0-11`. January is `0`. December is `11`. If you pass `12`, the Java calendar engine thinks you mean "The month after December". It will automatically roll the year forward +1, and set the month to January (`0`). This will violently break your downstream math |
| Passing YYYYMMDD | `@CalcMgrGetCustomDate(20241231, 11, 31)` | The `year` parameter explicitly expects a 4-digit integer (e.g., `2024`). If you pass a full YYYYMMDD string or integer, it will create a date in the year 20,241,231 AD. Your script will either crash or return massive invalid numbers |
| Attempting Direct Storage | `"Target" = @CalcMgrGetCustomDate(...)` | Essbase standard numeric accounts cannot hold Java Objects. If you try to save the result directly, it will fail. If you just want to create a `20241231` integer to store in an account, do NOT use this function. Simply write: `(Year * 10000) + (Month * 100) + Day` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetCustomDateTime`](./@CalcMgrGetCustomDateTime.md) | Constructs a Date Object but allows you to specify the exact Hour, Minute, and Second |
| [`@CalcMgrGetDatePart`](./@CalcMgrGetDatePart.md) | The exact inverse function: Takes a Java Date Object and extracts the individual Year, Month, or Day integer |
| [`@CalcMgrIntegerToDate`](../15_CalcMgr_Utility/@CalcMgrConvertDateToJavaDate.md) | A faster way to construct a Date Object if you already have a `YYYYMMDD` integer (e.g., `20241231`) rather than three separate components |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getcustomdate.html)
