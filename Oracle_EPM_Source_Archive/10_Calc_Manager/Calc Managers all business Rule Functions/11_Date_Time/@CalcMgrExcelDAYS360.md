# @CalcMgrExcelDAYS360

## Overview

`@CalcMgrExcelDAYS360` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `DAYS360` function directly inside an Essbase calculation script. 
It calculates the number of days between two dates based on a **360-day year** (where every single month is considered to have exactly 30 days).

### Why Does This Function Exist?

In corporate finance, banking, and real estate, interest payments and accounting accruals are frequently calculated using a standardized 360-day year. This eliminates the mathematical fluctuations caused by months having 28, 29, 30, or 31 days. If you charge daily interest in a 360-day system, the interest expense in February is identical to the interest expense in March.
Recreating the 30/360 day-count calendar rules manually using standard Essbase math (e.g., trying to flatten February to 30 days) is practically impossible to do cleanly without massive, brittle `IF` statements.
`@CalcMgrExcelDAYS360` leverages the Java financial engine to execute the exact same algorithm as Excel, returning the precise 360-basis day count between two dates, ensuring your Essbase accrual models match legacy spreadsheets perfectly.

### When to Use It

- **Debt Servicing**: Calculating accrued interest for corporate bonds or commercial paper that explicitly dictate a NASD 30/360 day-count basis.
- **Rent Proration**: Calculating daily prorated rent in real estate models where leases are standardly evaluated on a 360-day calendar.
- Whenever you need to migrate an Excel spreadsheet containing the `DAYS360` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelDAYS360(start_date, end_date, method)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | Integer | ✅ Yes | The starting date (`YYYYMMDD`). |
| `end_date` | Integer | ✅ Yes | The ending date (`YYYYMMDD`). |
| `method` | Boolean | ✅ Yes | `0` (False) = US (NASD) Method. `1` (True) = European Method. This dictates how the 31st of a month is handled mathematically. |

### The Methods Explained
- **US Method (0)**: If the start date is the 31st, it is treated as the 30th. If the end date is the 31st, and the start date is *not* the 30th or 31st, the end date rolls over to the 1st of the next month.
- **European Method (1)**: Regardless of the start date, if either the start or end date falls on the 31st, they are treated as the 30th of the same month.

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the integer number of days between the two dates on a 360-day calendar.
- If `end_date` is earlier than `start_date`, the function returns a negative number.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers.
2. **Boundary Adjustment**: It evaluates the `start_date` and `end_date`. Depending on the `method` selected (US vs. Euro), it forcefully alters any 31st days (or February 28/29th days) to mathematically behave like the 30th.
3. **Difference Calculation**: It executes a simple formula: `((EndYear - StartYear) * 360) + ((EndMonth - StartMonth) * 30) + (EndDay - StartDay)`.
4. **Return**: Passes the resulting integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard US Corporate Bond (NASD)

```essbase
/* 
   Start: Jan 15, 2024
   End: Dec 31, 2024 (Treated as Dec 30)
   Method: 0 (US)
   Result: 345 Days
*/
"Accrual_Days" = @CalcMgrExcelDAYS360(20240115, 20241231, 0);
```

---

## Practical Examples

### Example 1: Prorating Commercial Rent (360-Day Basis)

**Scenario**: A commercial real estate company signs a new tenant mid-month. The lease stipulates that partial months are prorated using a 360-day calendar (1/30th of the monthly rent per day). The lease starts on August 19. You need to calculate how many days to charge rent for in August (Aug 19 to Aug 31). On a standard calendar, this is 13 days. On a 360 calendar, the 31st is treated as the 30th, resulting in 12 days.

```essbase
FIX("FY25", "Working", @LEVEL0("Leases"))
    
    IF("Lease_Start_Date" != #MISSING AND "Monthly_Rent" > 0)
        
        /* Define the end of the month (e.g., Aug 31) */
        VAR vMonthEnd = 20240831;
        
        /* 1. Calculate the days on a 360 basis (US Method) */
        /* Start: Aug 19. End: Aug 31 (treated as Aug 30). Result: 12 days. */
        "Prorated_Days" = @CalcMgrExcelDAYS360("Lease_Start_Date", vMonthEnd, 0);
        
        /* 2. Calculate the Rent Expense (Daily Rate * Prorated Days) */
        /* (Monthly Rent / 30) * 12 */
        "Recognized_Rent_Revenue" = ("Monthly_Rent" / 30) * "Prorated_Days";
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Calculating Annualized Interest

**Scenario**: A treasury department calculates accrued interest on short-term corporate paper. The interest is calculated as `Principal * Rate * (Days / 360)`. You must use `DAYS360` to get the correct numerator for this equation.

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Tranche"))
    
    IF("Maturity_Date" > "Assumptions"->"Current_Settlement_Date")
        
        /* 1. Get the 360-based days elapsed since the Issue Date */
        "Accrued_Days_360" = @CalcMgrExcelDAYS360(
            "Issue_Date", 
            "Assumptions"->"Current_Settlement_Date", 
            0 /* US Method */
        );
        
        /* 2. Calculate Accrued Interest */
        IF("Accrued_Days_360" > 0)
            
            "Accrued_Interest_Expense" = "Principal" * "Annual_Rate" * ("Accrued_Days_360" / 360);
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using for Standard Math | Replacing `DateDiff` | Do not use `DAYS360` to calculate actual elapsed time (e.g., how old an employee is, or how long a project took). This is a purely financial/accounting construct. It will drop days from 31-day months and artificially add days to February. Use `@CalcMgrDaysDiff` for true calendar math |
| Passing Java Dates | `@CalcMgrExcelDAYS360(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Method Mismatch | Using Euro (1) instead of US (0) | While they often yield similar results, the US and European methods handle the 31st of the month very differently. Consult the specific legal definition of the bond or contract to ensure you pass the correct boolean flag |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDaysDiff`](./@CalcMgrDaysDiff.md) | Calculates the true, exact calendar days between two dates (the real-world alternative to this function) |
| [`@CalcMgrExcelYEARFRAC`](./@CalcMgrExcelYEARFRAC.md) | Calculates the fraction of a year between two dates, and can be parameterized to use 30/360 logic internally |
| [`@CalcMgrExcelACCRINTM`](./@CalcMgrExcelACCRINTM.md) | Automatically applies 30/360 logic internally when the `basis` is set to `0` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceldays360.html)
