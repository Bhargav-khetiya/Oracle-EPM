# @CalcMgrAddYears

## Overview

`@CalcMgrAddYears` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It adds or subtracts a specified number of calendar years to a starting date formatted as a `YYYYMMDD` integer.

### Why Does This Function Exist?

In corporate finance, strategic planning often spans multiple years (e.g., 3-Year, 5-Year, or 10-Year Long Range Plans). While you could technically multiply a year by 365 and use `@CalcMgrAddDays`, or multiply by 12 and use `@CalcMgrAddMonths`, leap years and varying month lengths introduce significant drift and rounding errors when calculating exact anniversary dates over long periods.
`@CalcMgrAddYears` specifically isolates the "Year" component of the `YYYYMMDD` integer, increments it, and correctly handles edge cases like leap years (e.g., adding 1 year to Feb 29, 2024 automatically adjusts to Feb 28, 2025). This ensures exact calendar accuracy for long-term forecasting.

### When to Use It

- To calculate long-term asset retirement or replacement dates (e.g., Purchase Date + 10 Years).
- To project vesting schedules for employee stock options (e.g., Grant Date + 4 Years).
- To determine the expiration date of long-term commercial leases or multi-year vendor contracts.
- When generating rolling multi-year forecast periods in a Long Range Planning (LRP) model.

---

## Category

**Date & Time / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrAddYears(date, years)
```

### Formal Syntax

```
@CalcMgrAddYears(dateValue, yearsToAdd)
```

Where:
- `dateValue` — The starting baseline date, formatted as a `YYYYMMDD` integer (e.g., `20240115`).
- `yearsToAdd` — An integer representing the absolute number of years to advance the calendar. Use a negative integer to calculate historical or past dates.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Integer | ✅ Yes | The baseline date in YYYYMMDD format. This is usually read dynamically from an account in the outline (e.g., "Contract_Start"). |
| `years` | Integer | ✅ Yes | The number of years to add or subtract. Can be hardcoded or dynamic based on another account (e.g., "Useful_Life_Years"). |

---

## Return Value

**Return Type**: Integer (YYYYMMDD format)

Returns a new integer representing the calculated date, correctly handling leap year rollovers based on standard Gregorian calendar rules.

---

## How It Works (Behind the Scenes)

1. **Integer Parsing**: The function reads the `YYYYMMDD` integer (e.g., `20240229`). It splits this into Year (2024), Month (02), and Day (29).
2. **Calendar Initialization**: It instantiates a Java Calendar object and sets it to the parsed date.
3. **Year Advancement**: It increments or decrements the year counter by `yearsToAdd`. 
4. **Leap Year Truncation**: It verifies the target day. If the starting date was February 29th (a leap year), and the target year is not a leap year (e.g., 2025), the Java Calendar object natively truncates the day to the last valid day of February (February 28th).
5. **Format Return**: It serializes the new date back into a `YYYYMMDD` integer (e.g., `20250228`) and returns it to the Essbase data block.

---

## Syntax Variants & Scenarios

### Variant 1: Stock Option Vesting (Future Target)

```essbase
/* Add exactly 4 years to find the fully vested date */
"Fully_Vested_Date" = @CalcMgrAddYears("Option_Grant_Date", 4);
```

### Variant 2: Historical Trailing Comparison (Past Lookback)

```essbase
/* Subtract exactly 3 years to find a historical comparison point for a 3-Year CAGR */
"Lookback_Date" = @CalcMgrAddYears("Current_Date", -3);
```

---

## Practical Examples

### Example 1: Calculating Asset Retirement Date

**Scenario**: You purchase a fixed asset (e.g., a heavy manufacturing machine). The useful life is defined in years (e.g., 10 years). You need to calculate the exact date when the asset is fully depreciated and scheduled for retirement/replacement, so your CapEx model can automatically trigger a replacement capital purchase in the correct future month.

```essbase
FIX("FY25", "Working", @LEVEL0("Asset_Class"))
    
    IF("Purchase_Date" != #MISSING AND "Useful_Life_Years" > 0)
        /* Add the useful life (in years) to the purchase date */
        "Asset_Retirement_Date" = @CalcMgrAddYears("Purchase_Date", "Useful_Life_Years");
    ENDIF
    
ENDFIX
```

---

### Example 2: Long-Term Lease Expiration Tracking

**Scenario**: A commercial real estate company signs 10-year, 15-year, and 20-year leases. The system needs to calculate the exact expiration date to trigger a renewal negotiation workflow 12 months prior to the expiration.

```essbase
FIX("FY25", "Working", @LEVEL0("Property"))
    
    /* Calculate the exact Expiration Date */
    IF("Lease_Commencement_Date" != #MISSING AND "Lease_Term_Years" > 0)
        
        "Lease_Expiration_Date" = @CalcMgrAddYears("Lease_Commencement_Date", "Lease_Term_Years");
        
        /* Using a nested date function, we can also calculate the 
           Notification Date (12 months prior to Expiration) */
        "Renewal_Notice_Date" = @CalcMgrAddMonths("Lease_Expiration_Date", -12);
        
    ENDIF
    
ENDFIX
```

---

### Example 3: Employee Anniversary Tracking

**Scenario**: HR wants to project bonuses for employees who hit their 5-year or 10-year service anniversaries.

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    IF("Hire_Date" != #MISSING)
        /* Calculate precise anniversaries */
        "5_Year_Anniversary" = @CalcMgrAddYears("Hire_Date", 5);
        "10_Year_Anniversary" = @CalcMgrAddYears("Hire_Date", 10);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Multiplying Days manually | Using `@CalcMgrAddDays(Date, Years * 365)` | This will cause drift due to leap years (which add an extra day every 4 years). Over a 10-year period, your calculated date will be off by 2 or 3 days. Always use `@CalcMgrAddYears` for perfect calendar accuracy |
| Expecting Feb 29 retention | If you add 4 years to Feb 29, 2024, you get Feb 29, 2028 (correct). But if you add 1 year to Feb 29, 2024, you get Feb 28, 2025. If you add 3 *more* years to that result, you get Feb 28, 2028, not Feb 29 | Be aware that truncation to Feb 28 is a one-way operation. The calendar does not remember that the original date was a leap day if you pass through non-leap years |
| Invalid formats | Passing a standard mm/dd/yyyy string | Ensure the input is strictly an integer formatted as `YYYYMMDD` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrAddMonths`](./@CalcMgrAddMonths.md) | Shortcut function for adding months directly |
| [`@CalcMgrAddDays`](./@CalcMgrAddDays.md) | Shortcut function for adding exact calendar days |
| [`@CalcMgrDateToExcel`](./@CalcMgrDateToExcel.md) | Can be used to convert the resulting `YYYYMMDD` integer into an Excel serial date if required for reporting exports |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_addyears.html)
