# @CalcMgrAddDate

## Overview

`@CalcMgrAddDate` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It allows you to add or subtract a specific number of days, months, or years to a starting date, returning a new, mathematically correct future or past date.

### Why Does This Function Exist—

Essbase natively handles dates as either raw integers (YYYYMMDD) or serialized numbers (days since Jan 1, 1970). 
If you try to natively add 1 month to `20241215`, you can't just add `100` mathematically (`20241315` is an invalid date). 
Date math requires understanding leap years, varying month lengths, and year boundaries. `@CalcMgrAddDate` handles all this complex calendrical math for you automatically.

### When to Use It

- Calculating maturity dates for loans or bonds (e.g., Origination Date + 36 Months).
- Calculating warranty expiration dates (e.g., Sale Date + 1 Year).
- Determining probation period end dates for employees (e.g., Hire Date + 90 Days).

---

## Category

**Date & Time / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrAddDate(startDate, amount, "datePart")
```

### Formal Syntax

```
@CalcMgrAddDate(dateValue, amountToAdd, "datePartString")
```

Where:
- `dateValue` — The starting date, formatted in the standard `YYYYMMDD` integer format (e.g., `20240115`).
- `amountToAdd` — An integer representing how many units to add (use negative numbers to subtract).
- `"datePartString"` — A string indicating what unit of time to add. Options: `"day"`, `"month"`, or `"year"`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `startDate` | Integer | ✅ Yes | The baseline date in YYYYMMDD format. Often pulled from an account like `"Hire_Date"`. |
| `amount` | Integer | ✅ Yes | The number to add. Can be positive (future) or negative (past). |
| `"datePart"`| String | ✅ Yes | The unit to modify. Must be in quotes: `"day"`, `"month"`, or `"year"`. |

---

## Return Value

**Return Type**: Integer (YYYYMMDD format)

Returns a new integer representing the calculated date.

---

## How It Works (Behind the Scenes)

1. **Parsing**: The function parses the `YYYYMMDD` integer into its constituent Year, Month, and Day parts.
2. **Calendrical Math**: It applies the `amount` to the specific `datePart`, respecting the rules of the Gregorian calendar (e.g., adding 1 month to Jan 31st results in Feb 28th or 29th).
3. **Re-encoding**: It packages the resulting date back into the `YYYYMMDD` integer format and returns it.

---

## Syntax Variants & Scenarios

### Variant 1: Adding Days

```essbase
/* Add 90 days to a date */
"Probation_End" = @CalcMgrAddDate("Hire_Date", 90, "day");
```

### Variant 2: Adding Months (Cross-Year)

```essbase
/* Adding 3 months to Nov 2024 (20241101) returns Feb 2025 (20250201) */
"First_Payment_Date" = @CalcMgrAddDate("Loan_Start_Date", 3, "month");
```

### Variant 3: Subtracting Years

```essbase
/* Subtract 5 years */
"Asset_Purchase_Date" = @CalcMgrAddDate("Retirement_Date", -5, "year");
```

---

## Practical Examples

### Example 1: Warranty Expiration Tracking

**Scenario**: You sell heavy machinery. A standard warranty lasts exactly 2 years from the date of sale. You need to calculate the exact expiration date to forecast warranty liability reserves.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* Ensure a sale date exists */
    IF("Sale_Date" != #MISSING)
        /* Add 2 years to the sale date */
        "Warranty_Expiration_Date" = @CalcMgrAddDate("Sale_Date", 2, "year");
    ENDIF
    
ENDFIX
```

---

### Example 2: Loan Amortization Maturity

**Scenario**: A corporate loan originates on a specific date and has a term of 36 months. You need to calculate the final maturity date.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* If there is an active loan with an origination date */
    IF("Loan_Origination_Date" != #MISSING AND "Loan_Term_Months" > 0)
        
        /* Add the term months to the origination date */
        "Loan_Maturity_Date" = @CalcMgrAddDate("Loan_Origination_Date", "Loan_Term_Months", "month");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Invalid Date Formats | Passing `01152024` (MMDDYYYY) to the function | The function requires `YYYYMMDD` (e.g., `20240115`). Ensure your input accounts are formatted correctly |
| Missing quotes on date part | `@CalcMgrAddDate(Date, 5, month)` is a syntax error | You must wrap the date part parameter in quotes: `"month"` |
| Using on Serial Dates | If your date is stored as "Days since 1970" (Unix epoch), this function will fail | Use `@CalcMgrAddDays` or standard math for epoch dates, and reserve `@CalcMgrAddDate` for `YYYYMMDD` integers |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | Calculates the difference between two dates rather than adding to a date |
| [`@CalcMgrGetCurrentDate`](./@CalcMgrGetCurrentDate.md) | Gets today's date in YYYYMMDD format to use as the starting point |
| [`@TODATEEX`](../17_Time_Series/@TODATEEX.md) | Parses string dates into integers for use in these functions |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_adddate.html)
