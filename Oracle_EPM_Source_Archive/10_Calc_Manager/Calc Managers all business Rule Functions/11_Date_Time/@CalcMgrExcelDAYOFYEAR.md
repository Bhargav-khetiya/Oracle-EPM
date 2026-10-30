# @CalcMgrExcelDAYOFYEAR

## Overview

`@CalcMgrExcelDAYOFYEAR` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It analyzes a provided date and returns its numerical position within the calendar year (from `1` to `365` or `366`).

### Why Does This Function Exist?

In manufacturing, retail, and supply chain models, time is frequently analyzed using the "Julian Day" or "Day of Year" format. For example, January 1st is Day 1. February 1st is Day 32. December 31st is Day 365 (or 366 in a leap year).
This is crucial for calculating seasonality curves, daily depreciation, or prorating annual subscription contracts. Calculating this manually in Essbase requires complex arrays mapping the cumulative days in each month and injecting `IF` statements to handle leap years. 
While Microsoft Excel does not have a native `=DAYOFYEAR()` function (Excel users typically hack it using `=A1-DATE(YEAR(A1),1,1)+1`), Oracle provided `@CalcMgrExcelDAYOFYEAR` in the Calc Manager Excel library to streamline this incredibly common forecasting requirement, handling all leap-year logic seamlessly in Java.

### When to Use It

- **Seasonality Indexing**: Aligning daily sales data across multiple years by comparing their "Day of Year" rather than specific calendar dates (since weekends shift).
- **Daily Proration**: Calculating what percentage of an annual budget has elapsed (`DayOfYear / 365`).
- **Manufacturing Tracking**: Converting calendar dates into Julian formats often required by legacy ERP or shop-floor systems.

---

## Category

**Date & Time / Math / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDAYOFYEAR(date)
```

### Formal Syntax

```
@CalcMgrExcelDAYOFYEAR(numericExpression)
```

Where:
- `numericExpression` — The date to evaluate. Can be passed as an Excel Serial Date or a standard Essbase `YYYYMMDD` integer.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Integer | ✅ Yes | The date to evaluate (e.g., `20241231`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer between `1` and `366` representing the day's ordinal position in the year.
- e.g., `@CalcMgrExcelDAYOFYEAR(20240201)` returns `32`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the integer.
2. **Format Resolution**: It determines if the number is a Serial Date or an Essbase Date.
3. **Calendar Extrapolation**: It spins up an internal Java `GregorianCalendar` object for the specified date.
4. **Extraction**: It calls the native Java `Calendar.DAY_OF_YEAR` method, which automatically accounts for whether the specific year provided is a leap year.
5. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting from a YYYYMMDD Date

```essbase
/* Assume 2024 is a leap year. Dec 31, 2024. Returns 366. */
"Day_Of_Year" = @CalcMgrExcelDAYOFYEAR(20241231);
```

### Variant 2: Calculating Percentage of Year Elapsed

```essbase
/* Determines how much of the year is gone */
"Pct_Year_Elapsed" = @CalcMgrExcelDAYOFYEAR(20240701) / 366;
```

---

## Practical Examples

### Example 1: Prorating an Annual Software Contract

**Scenario**: An IT budgeting model allocates software expenses daily. A department signs an annual contract mid-year (e.g., August 15). The total contract cost is $100,000. You need to expense only the portion of the contract that applies to the current year. You can do this by finding the Day of Year for the start date, subtracting it from the total days in the year, and calculating the percentage.

```essbase
FIX("FY24", "Working", @LEVEL0("Contracts"))
    
    IF("Contract_Start_Date" != #MISSING AND "Total_Contract_Value" > 0)
        
        /* 1. Extract the Year from the Start Date */
        VAR vYear = @CalcMgrExcelYEAR("Contract_Start_Date");
        
        /* 2. Determine if it's a leap year by checking if Dec 31 of that year is day 365 or 366 */
        VAR vDec31 = (vYear * 10000) + 1231;
        VAR vTotalDaysInYear = @CalcMgrExcelDAYOFYEAR(vDec31);
        
        /* 3. Get the Day of Year for the contract start date */
        VAR vStartDOY = @CalcMgrExcelDAYOFYEAR("Contract_Start_Date");
        
        /* 4. Calculate Days Active in the current year (Total - Start + 1) */
        VAR vDaysActive = vTotalDaysInYear - vStartDOY + 1;
        
        /* 5. Calculate the expensed portion */
        "FY_Expense" = "Total_Contract_Value" * (vDaysActive / vTotalDaysInYear);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Generating a Julian Date for an ERP Export

**Scenario**: A legacy mainframe system requires manufacturing completion dates to be exported in a pseudo-Julian format: `YYYYDDD` (e.g., 2024, Day 32 = `2024032`). You use `DAYOFYEAR` and basic math to construct this.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    IF("Completion_Date" != #MISSING)
        
        /* Extract Year (e.g., 2024) */
        VAR vYear = @CalcMgrExcelYEAR("Completion_Date");
        
        /* Extract Day of Year (e.g., 32) */
        VAR vDOY = @CalcMgrExcelDAYOFYEAR("Completion_Date");
        
        /* Build the Julian Integer: (2024 * 1000) + 32 = 2024032 */
        "Julian_Export_Date" = (vYear * 1000) + vDOY;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting Leap Years | Assuming the denominator is always 365 | If you divide the output of this function by 365 to find a percentage, you will break during leap years (where Dec 31 returns 366, resulting in a percentage > 100%). You must calculate the total days in the year dynamically if you are creating percentages |
| Passing Java Dates | `@CalcMgrExcelDAYOFYEAR(vJavaDate)` | This function strictly expects integers (Serial Dates or YYYYMMDD). If you pass a massive Java Date object, the function will fail. Use `@CalcMgrGetDatePart` if you need to evaluate Java objects |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelDAY`](./@CalcMgrExcelDAY.md) | Extracts the day of the month (1-31) rather than the day of the year |
| [`@CalcMgrExcelDAYS360`](./@CalcMgrExcelDAYS360.md) | Calculates days between two dates assuming every year has exactly 360 days (often used in financial modeling instead of exact calendar days) |
| [`@CalcMgrExcelYEAR`](./@CalcMgrExcelYEAR.md) | Extracts the Year component from a date |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldayofyear.html)
