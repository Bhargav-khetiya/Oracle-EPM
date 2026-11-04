# @CalcMgrGetMaxDaysInMonth

## Overview

`@CalcMgrGetMaxDaysInMonth` is a **custom Calc Manager date utility function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a specialized calendar query. You pass it a specific **Year** and **Month** (as integers), and it returns the exact **total number of days** in that specific month, flawlessly accounting for leap years.

### Why Does This Function Exist—

In corporate finance, expenses (like rent, software licenses, or payroll taxes) are often accrued on a daily basis. If a company pays `$31,000` in rent for January, the daily expense is `$1,000` (because January has 31 days). If they pay `$31,000` in February, the daily expense spikes because there are fewer days in the denominator.
To calculate daily accruals dynamically, the script must know exactly how many days are in the current period. Writing 12 nested `IF` statements (e.g., `IF(Month == 1) Days = 31`) is tedious, and writing custom logic to detect if the current year is divisible by 4 (to handle February leap years) is highly prone to error.
`@CalcMgrGetMaxDaysInMonth` offloads this entirely to the Java Calendar engine. By simply feeding it the current Year and Month, it instantly returns the correct denominator (`28`, `29`, `30`, or `31`), completely stabilizing your accrual calculations.

### When to Use It

- **Daily Expense Accruals**: Dynamically dividing a monthly budget by the exact number of days in that specific month to create daily run-rates.
- **End-of-Month Deadlines**: Calculating if "Today" is mathematically the final day of the month by checking if `CurrentDay == MaxDaysInMonth`.
- **Forecast Generation**: Constructing dynamic end-of-month `YYYYMMDD` integer dates (e.g., automatically knowing to attach `28` to the end of `202302`).

---

## Category

**Date & Time / Calendar Utilities / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetMaxDaysInMonth(year, month)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `year` | Numeric | ✅ Yes | A four-digit integer representing the Year (e.g., `2024`). |
| `month` | Numeric | ✅ Yes | An integer representing the Month. <br>**CRITICAL RULE**: Unlike `GetCustomDate`, this specific utility function expects standard **1-indexed** months. January is `1`, December is `12`. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the absolute number of days in that month.
- E.g., Passing `2024, 1` returns `31`.
- E.g., Passing `2024, 2` returns `29` (because 2024 is a leap year).
- E.g., Passing `2023, 2` returns `28`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the Year and Month integers.
2. **Translation**: Because this is a user-friendly wrapper function, it automatically subtracts `1` from your Month input behind the scenes so it can safely talk to the 0-indexed Java Calendar engine.
3. **Execution**: It instantiates a Calendar object for that specific year/month and executes the `Calendar.getActualMaximum(Calendar.DAY_OF_MONTH)` method.
4. **Return**: Passes the resulting integer (`28-31`) back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Checking February in a Leap Year

```essbase
/* 2024 is a leap year. Returns 29. */
VAR vFebDays = @CalcMgrGetMaxDaysInMonth(2024, 2);
```

---

## Practical Examples

### Example 1: Calculating Daily Rent Accruals

**Scenario**: A corporate rent model allocates flat monthly expenses down to a daily level for operational reporting. The administrator passes the Year and Month to the script via runtime prompts (e.g., `{Target_Year}` = 2024, `{Target_Month}` = 4). The script must determine how many days are in April, and calculate the daily run-rate.

```essbase
FIX("Working", @LEVEL0("Facilities"))
    
    IF("Monthly_Rent_Target" > 0)
        
        /* 
           1. Dynamically calculate the maximum days in the target month.
           E.g., If Year is 2024 and Month is 4 (April), it returns 30.
        */
        VAR vTotalDays = @CalcMgrGetMaxDaysInMonth({Target_Year}, {Target_Month});
        
        /* 
           2. Calculate the exact daily accrual rate.
        */
        "Daily_Rent_Accrual" = "Monthly_Rent_Target" / vTotalDays;
        
    ENDIF
    
ENDFIX
```

### Example 2: Building an End-of-Month Integer Date

**Scenario**: A script needs to generate a dynamic `YYYYMMDD` integer for the last day of the current calculation month, so it can be exported to an external SQL database.

```essbase
/* Assume we are calculating for 2024, Month 2 (Feb) */
VAR vYear = 2024;
VAR vMonth = 2;

/* Dynamically get the last day (29) */
VAR vLastDay = @CalcMgrGetMaxDaysInMonth(vYear, vMonth);

/* 
   Mathematically construct the YYYYMMDD integer:
   (2024 * 10000) + (2 * 100) + 29
   Result: 20240229
*/
"EOM_Date_Export" = (vYear * 10000) + (vMonth * 100) + vLastDay;
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing 0-Indexed Months | Passing `0` for January | While some Java-based creation functions (like `GetCustomDate`) require 0-indexed months, this specific wrapper function was built for end-users. It strictly expects **1-indexed** months (`1-12`). If you pass `0` hoping for January, the internal engine will subtract `1`, roll backward to the previous year, and calculate December of the prior year (returning `31`) |
| Two-Digit Years | Passing `24` instead of `2024` | The `year` parameter must be the full four-digit year. The Java engine mathematically relies on the full 4 digits to calculate whether it is a leap year (e.g., dividing by 4, 100, and 400). Passing `24` will cause a calendar calculation in the year 24 AD |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetDatePart`](./@CalcMgrGetDatePart.md) | If you already have a full Java Date Object, you can extract the max days directly using `@CalcMgrGetDatePart(dateObj, "lastdayofmonth")` rather than using this function |
| [`@CalcMgrGetCustomDate`](./@CalcMgrGetCustomDate.md) | Requires 0-indexed months, unlike this function which uses 1-12 |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getmaxdaysinmonth.html)
