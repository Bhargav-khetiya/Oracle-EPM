# @CalcMgrAddDatePart

## Overview

`@CalcMgrAddDatePart` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It adds or subtracts a specified number of time units (days, months, or years) to a serialized date (a date stored as a single contiguous integer, often used internally in Java/Groovy date formats).

### Why Does This Function Exist—

While `@CalcMgrAddDate` works specifically with `YYYYMMDD` integer formats (like `20241231`), sometimes you are dealing with dates that have been serialized into continuous numbers (e.g., number of days since a specific epoch, or full timestamp integers).
`@CalcMgrAddDatePart` provides a similar math capability but is often used interchangeably in Calc Manager GUI rules when the underlying date variable is strongly typed as a `Date` object rather than a raw integer. 
Dates are notoriously difficult to calculate using standard arithmetic due to leap years, varying month lengths (28, 29, 30, 31 days), and year rollovers. This function encapsulates the complex calendrical logic required to execute these shifts accurately.

### When to Use It

- When manipulating `Date` type variables inside Calc Manager rather than raw integers.
- To add specific units (months, days, weeks) safely across leap years and varying month lengths.
- When you need to build dynamic timelines for employee onboarding, asset capitalization, or project phasing.
- When `@CalcMgrAddDate` fails due to date-format mismatch errors in GUI-built business rules.

---

## Category

**Date & Time / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrAddDatePart(date, amount, "datePart")
```

### Formal Syntax

```
@CalcMgrAddDatePart(dateVariableOrValue, amountToAdd, "datePartString")
```

Where:
- `dateVariableOrValue` — A valid date object or serialized date integer representing the baseline date.
- `amountToAdd` — The number of units to add. Use a negative integer for subtraction to look into the past.
- `"datePartString"` — The unit of time to add. Must be enclosed in double quotes. Valid options are `"day"`, `"month"`, or `"year"`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Date/Int | ✅ Yes | The starting date, typically retrieved from an account or passed as a variable. |
| `amount` | Integer | ✅ Yes | The number of units to add or subtract. |
| `"datePart"`| String | ✅ Yes | The unit of measurement in quotes (e.g., `"month"`, `"day"`, `"year"`). Case sensitivity generally depends on the exact EPM version, but lowercase is standard practice. |

---

## Return Value

**Return Type**: Date / Integer

Returns the new calculated date, respecting the calendar bounds of the original date format. If the function is evaluated inside a numeric data block, it returns the serialized integer equivalent of the resulting date.

---

## How It Works (Behind the Scenes)

1. **Date Object Construction**: Calc Manager uses underlying Java libraries to construct a proper `java.util.Calendar` object from the input integer.
2. **Calendar Math Application**: It applies the `amount` to the requested Calendar `datePart`. 
   - *Example 1*: If you add 1 month to January 31st, the underlying engine recognizes that February does not have 31 days. It automatically truncates the result to the last valid day of February (the 28th, or 29th on a leap year).
   - *Example 2*: If you subtract 5 days from January 3rd, it seamlessly rolls backward into December of the prior year.
3. **Format Return**: It returns the modified date in the same serialized format it received, allowing the calculation engine to store it in a data block.

---

## Syntax Variants & Scenarios

### Variant 1: Adding Months to a Variable

```essbase
/* Assume vStartDate is a Date variable initialized earlier in the script */
VAR vEndDate = @CalcMgrAddDatePart(vStartDate, 6, "month");
```

### Variant 2: Subtracting Years for Historical Lookbacks

```essbase
/* Calculate a date exactly 3 years prior to the current context date */
"Lookback_Date" = @CalcMgrAddDatePart("Current_Date", -3, "year");
```

---

## Practical Examples

### Example 1: Probation End Date (90 Days)

**Scenario**: You want to calculate exactly 90 days after a new hire's start date to determine when their healthcare benefits become active.

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    /* Ensure the employee has a valid hire date before running the math */
    IF("Hire_Date" != #MISSING)
        /* Add exactly 90 days to the Hire Date */
        "Benefits_Eligible_Date" = @CalcMgrAddDatePart("Hire_Date", 90, "day");
    ENDIF
    
ENDFIX
```

---

### Example 2: Commercial Lease Expiration

**Scenario**: A commercial lease is signed for a standard term of 5 years. You must calculate the expiration date to begin projecting rent escalations or renewal negotiations.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Lease_Start" != #MISSING)
        /* Add 5 full years to the start date */
        "Lease_End" = @CalcMgrAddDatePart("Lease_Start", 5, "year");
    ENDIF
    
ENDFIX
```

---

### Example 3: Quarterly Subscription Renewal

**Scenario**: A software subscription renews every quarter (3 months). Given an initial sign-up date, determine the date of the next billing cycle.

```essbase
FIX("FY25", "Working", @LEVEL0("Customer"))
    
    IF("Initial_Signup_Date" != #MISSING)
        /* Advance the calendar by 3 months */
        "Next_Billing_Date" = @CalcMgrAddDatePart("Initial_Signup_Date", 3, "month");
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing Quotes on Date Part | `@CalcMgrAddDatePart(Date, 5, year)` is invalid syntax and will fail validation | The third parameter must be a string enclosed in double quotes: `"year"` |
| Mixing Data Formats | Trying to pass a `YYYYMMDD` integer (like `20241231`) into a function that expects a Java serial date, or vice versa | If `YYYYMMDD` is strictly used in your cube, `@CalcMgrAddDate` is often safer. `@CalcMgrAddDatePart` is better for strict `Date` type variables in GUI Business Rules |
| Assuming 30 Days = 1 Month | Calculating `@CalcMgrAddDatePart(Date, 30, "day")` instead of `1, "month"` | A month is not always 30 days. Always use the `"month"` parameter if the business logic dictates a monthly cycle rather than a strict 30-day countdown |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrAddDate`](./@CalcMgrAddDate.md) | Specifically tuned for `YYYYMMDD` integer formats commonly used in older Essbase models |
| [`@CalcMgrAddDays`](./@CalcMgrAddDays.md) | A simplified version that doesn't require the `"day"` string parameter |
| [`@CalcMgrAddMonths`](./@CalcMgrAddMonths.md) | A simplified version that doesn't require the `"month"` string parameter |
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | Calculates the difference between two dates rather than generating a future date |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_adddatepart.html)
