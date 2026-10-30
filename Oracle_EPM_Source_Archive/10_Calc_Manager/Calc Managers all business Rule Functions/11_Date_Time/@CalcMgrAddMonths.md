# @CalcMgrAddMonths

## Overview

`@CalcMgrAddMonths` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It adds or subtracts a specified number of calendar months to a starting date formatted as a `YYYYMMDD` integer.

### Why Does This Function Exist?

While `@CalcMgrAddDays` is useful for short-term exact dates, financial and corporate modeling heavily relies on monthly cycles (amortization, depreciation, loan terms, contract lengths, subscription renewals). 
Adding exactly 3 months to Jan 15th should yield Apr 15th. However, if you simply added 90 days, you might yield Apr 14th or Apr 16th depending on the presence of leap years and varying month lengths. 
`@CalcMgrAddMonths` cleanly adds exact months, maintaining the same day of the month where possible, and automatically truncating if the target month doesn't have enough days (e.g., adding 1 month to Jan 31st yields Feb 28th).

### When to Use It

- To calculate long-term loan maturity dates (e.g., Origination Date + 36 Months).
- To determine straight-line depreciation or asset capitalization end dates.
- To project SaaS subscription or vendor contract renewal dates.
- When generating rolling monthly forecast periods in a driver-based model.

---

## Category

**Date & Time / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrAddMonths(date, months)
```

### Formal Syntax

```
@CalcMgrAddMonths(dateValue, monthsToAdd)
```

Where:
- `dateValue` — The starting baseline date, formatted as a `YYYYMMDD` integer (e.g., `20240115`).
- `monthsToAdd` — An integer representing the number of months to advance the calendar (use a negative integer to calculate historical or past dates).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Integer | ✅ Yes | The baseline date in YYYYMMDD format. This is usually read dynamically from an account in the outline. |
| `months` | Integer | ✅ Yes | The number of months to add or subtract. Can be hardcoded or dynamic based on another account. |

---

## Return Value

**Return Type**: Integer (YYYYMMDD format)

Returns a new integer representing the calculated date, correctly handling year rollovers and end-of-month truncation based on Gregorian calendar rules.

---

## How It Works (Behind the Scenes)

1. **Integer Parsing**: The function reads the `YYYYMMDD` integer (e.g., `20241031`). It splits this into Year (2024), Month (10), and Day (31).
2. **Calendar Initialization**: It instantiates a Java Calendar object and sets it to the parsed date.
3. **Month Advancement**: It increments or decrements the month counter by `monthsToAdd`. If it crosses a year boundary (e.g., adding 3 months to Nov), the year automatically increments.
4. **End of Month Truncation**: It verifies the target day. If the target month has fewer days than the starting day (e.g., Oct 31 -> Nov 31), it automatically truncates the day to the last valid day of the target month (e.g., Nov 30).
5. **Format Return**: It serializes the new date back into a `YYYYMMDD` integer.

---

## Syntax Variants & Scenarios

### Variant 1: Contract Renewal (Future Target)

```essbase
/* Add exactly 12 months to find the 1-year renewal date */
"Renewal_Date" = @CalcMgrAddMonths("Contract_Start_Date", 12);
```

### Variant 2: Historical Comparison (Past Lookback)

```essbase
/* Subtract exactly 6 months to find a historical comparison point */
"Lookback_Date" = @CalcMgrAddMonths("Current_Date", -6);
```

---

## Practical Examples

### Example 1: Calculating Asset Depreciation End Date

**Scenario**: You purchase a fixed asset. The useful life is defined in months (e.g., 60 months). You need to calculate the exact date when depreciation stops so that your balance sheet models automatically halt the accumulated depreciation schedule.

```essbase
FIX("FY25", "Working", @LEVEL0("Asset_Class"))
    
    IF("Purchase_Date" != #MISSING AND "Useful_Life_Months" > 0)
        /* Add the useful life (in months) to the purchase date */
        "Depreciation_End_Date" = @CalcMgrAddMonths("Purchase_Date", "Useful_Life_Months");
    ENDIF
    
ENDFIX
```

---

### Example 2: End-of-Month Truncation Logic (SaaS Billing)

**Scenario**: A SaaS subscription always bills on the exact same day every month. If a customer signs up on January 31st, the system must ensure the next bill lands on the correct last day of February, rather than throwing an invalid date error.

```essbase
FIX("FY25", "Working", @LEVEL0("Customer"))
    
    /* If Sub_Date = 20240131 (January 31st) */
    "Next_Bill_Date" = @CalcMgrAddMonths("Sub_Date", 1);
    
    /* Result will automatically truncate to 20240228 (or 20240229 on a leap year).
       The engine handles the calendar math seamlessly. */
    
ENDFIX
```

---

### Example 3: Dynamic Loan Amortization

**Scenario**: You originate a new loan, but the term length varies depending on the specific credit profile. You must calculate the maturity date dynamically based on a driver account.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Loan_Orig_Date" != #MISSING AND "Term_Months" != #MISSING)
        /* Add the dynamic Term_Months value to the Origination Date */
        "Loan_Maturity_Date" = @CalcMgrAddMonths("Loan_Orig_Date", "Term_Months");
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Multiplying Days manually | Using `@CalcMgrAddDays(Date, Months * 30)` | This will cause significant drift over time. 12 * 30 is 360 days, not a full 365-day year. Always use `@CalcMgrAddMonths` to ensure true calendar accuracy |
| Expecting exact day retention on short months | If you add 1 month to Jan 31, you get Feb 28. If you add *another* month to Feb 28, you get Mar 28 (not Mar 31) | Be aware that end-of-month truncation is a one-way operation. It does not remember the original "31st" intention if it passes through a shorter month |
| Invalid formats | Passing a standard mm/dd/yyyy string | Ensure the input is strictly an integer formatted as `YYYYMMDD` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrAddYears`](./@CalcMgrAddYears.md) | Shortcut function for adding years directly |
| [`@CalcMgrAddDays`](./@CalcMgrAddDays.md) | Shortcut function for adding exact calendar days |
| [`@CalcMgrMonthsBetween`](./@CalcMgrMonthsBetween.md) | Calculates the number of months *between* two dates, rather than generating a future date |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_addmonths.html)
