# @CalcMgrExcelDAY

## Overview

`@CalcMgrExcelDAY` is a **custom Calc Manager date extraction function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DAY` function directly inside an Essbase calculation script. 
It analyzes an Excel Serial Date (or a standard Essbase `YYYYMMDD` integer) and extracts solely the **Day of the Month**, returning it as an integer between 1 and 31.

### Why Does This Function Exist?

When migrating logic from an Excel spreadsheet, you often encounter formulas like `=DAY(A1)` used to trigger conditional logic (e.g., "If the invoice date is past the 15th of the month, assign it to the late payment bucket").
While you can extract the day from a standard Essbase `YYYYMMDD` integer manually using mathematical modulus logic (e.g., `Date - (@TRUNC(Date / 100) * 100)`), this is tedious and completely breaks down if the data was loaded as an Excel Serial Date (e.g., `45657`).
`@CalcMgrExcelDAY` utilizes the Java engine to evaluate the date (safely handling both Serial Dates and `YYYYMMDD` integers) and extracts the exact calendar day with zero mathematical hacking required, ensuring perfect parity with legacy Excel models.

### When to Use It

- To trigger conditional logic based on the day of the month (e.g., bi-weekly payroll forecasting that shifts based on whether an employee was hired before or after the 15th).
- When isolating the day component to dynamically construct a new date (e.g., forcing a date to the end of the month).
- Whenever you need to migrate an Excel spreadsheet containing the `DAY` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDAY(date)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Integer | ✅ Yes | The date to evaluate. Can be passed as an Excel Serial Date (e.g., `45657`) or a standard Essbase integer (`20241231`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer between `1` and `31` representing the day of the month.
- e.g., `@CalcMgrExcelDAY(20241025)` returns `25`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the integer.
2. **Format Resolution**: It determines if the number is a Serial Date (typically < 100000) or an Essbase Date (e.g., `20240101`). 
3. **Extraction**: It initializes a calendar object and isolates the specific day component.
4. **Return**: Passes the resulting day integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting from a Serial Date

```essbase
/* Assume 45657 is Dec 31, 2024. Returns 31. */
"Day_Component" = @CalcMgrExcelDAY(45657);
```

### Variant 2: Extracting from a YYYYMMDD Date

```essbase
/* Extracts the day from an Essbase integer. Returns 15. */
"Day_Component" = @CalcMgrExcelDAY(20240315);
```

---

## Practical Examples

### Example 1: Prorating Mid-Month Hires

**Scenario**: In an HR planning model, you calculate a new hire's first-month salary based on their start date. If they start on the 1st, they get 100%. If they start on the 15th, they get 50%. You must extract the day of the month they were hired to calculate the exact proration factor.

```essbase
FIX("FY25", "Working", @LEVEL0("Employee"))
    
    IF("Hire_Date" != #MISSING)
        
        /* 1. Extract the Day of the Month (e.g., 15) */
        VAR vStartDay = @CalcMgrExcelDAY("Hire_Date");
        
        /* 2. Extract the Month and Year to find how many total days are in that specific month */
        VAR vStartMonth = @CalcMgrExcelMONTH("Hire_Date");
        VAR vStartYear = @CalcMgrExcelYEAR("Hire_Date");
        VAR vTotalDaysInMonth = @CalcMgrExcelDAYSINMONTH(vStartYear, vStartMonth);
        
        /* 3. Calculate the Proration Factor (Days worked / Total Days) */
        /* If hired on the 15th of a 30-day month: (30 - 15 + 1) / 30 = 16/30 = 0.533 */
        "Proration_Factor" = (vTotalDaysInMonth - vStartDay + 1) / vTotalDaysInMonth;
        
        /* 4. Apply to the first month's salary */
        "Salary_Expense" = "Monthly_Base_Pay" * "Proration_Factor";
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Forcing a Date to the First of the Month

**Scenario**: You have an exact invoice date (`20241025`). For financial forecasting, you need to align all cash flows to the 1st of the month (`20241001`). You use `DAY` to figure out how many days to subtract.

```essbase
FIX("FY25", "Working", @LEVEL0("Invoice"))
    
    IF("Invoice_Date" != #MISSING)
        
        /* Extract the day (25) */
        VAR vDay = @CalcMgrExcelDAY("Invoice_Date");
        
        /* Subtract the day and add 1. 20241025 - 25 + 1 = 20241001 */
        "Adjusted_Forecast_Date" = "Invoice_Date" - vDay + 1;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrExcelDAY(vJavaDate)` | This function strictly expects integers (Serial Dates or YYYYMMDD). If you pass a massive Java Date object, the function will fail or return garbage data. Use `@CalcMgrGetDatePart` if you need to extract days from a Java object |
| Passing 14-digit Timestamps | `@CalcMgrExcelDAY(20241025143000)` | The auto-resolver will likely fail to parse a 14-digit timestamp correctly. Ensure you are only passing 8-digit dates or Serial Dates |
| Evaluating Zeros | `@CalcMgrExcelDAY(0)` | If a cell is `0` instead of `#MISSING`, passing it to this function will treat it as Excel's epoch (January 0, 1900) and will likely return `0` or `1`. Always wrap in an `IF("Date" > 0)` block |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelMONTH`](./@CalcMgrExcelMONTH.md) | Extracts the Month component (`1-12`) from a date |
| [`@CalcMgrExcelYEAR`](./@CalcMgrExcelYEAR.md) | Extracts the Year component (e.g., `2024`) from a date |
| [`@CalcMgrExcelDATE`](./@CalcMgrExcelDATE.md) | Re-assembles extracted Year, Month, and Day integers back into a valid Excel Serial Date |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelday.html)
