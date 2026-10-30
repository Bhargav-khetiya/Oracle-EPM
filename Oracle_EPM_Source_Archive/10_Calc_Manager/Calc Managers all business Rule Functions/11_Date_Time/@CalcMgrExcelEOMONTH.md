# @CalcMgrExcelEOMONTH

## Overview

`@CalcMgrExcelEOMONTH` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `EOMONTH` function directly inside an Essbase calculation script. 
It takes a starting date, shifts it forward (or backward) by a specified number of months, and mathematically forces the resulting date to be the **very last day** of that new month.

### Why Does This Function Exist?

In accounting and corporate finance, cash flows and accruals are almost universally aligned to the "End of Month". If an invoice is issued on October 12, and the payment terms are "Net 60", the payment is technically due on December 11. However, FP&A models usually don't forecast cash flows on a daily basis; they forecast them monthly, pushing that cash outflow to the end of December (December 31).
Calculating the "End of Month" dynamically in Essbase is highly complex. If you shift a date into February, you must know if it's a leap year to determine if the end of the month is the 28th or 29th. If you shift into April, the end is the 30th. 
`@CalcMgrExcelEOMONTH` handles all of this leap-year and calendar-boundary math inside the Java engine. It shifts the month, identifies the correct last day, and returns a perfectly formatted end-of-month date.

### When to Use It

- **Cash Flow Forecasting**: Standardizing highly specific transaction dates (like invoice dates or ship dates) to the final day of the month for standardized reporting.
- **Contract Billing**: Determining the exact final date of an annual subscription or lease agreement (e.g., 12 months after the start date, at the end of the month).
- Whenever you need to migrate an Excel spreadsheet containing the `EOMONTH` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelEOMONTH(start_date, months)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | Integer | ✅ Yes | The starting date. Can be passed as an Excel Serial Date or a standard `YYYYMMDD` Essbase integer. |
| `months` | Numeric | ✅ Yes | The number of months to shift before finding the end of the month. Pass `0` to find the end of the *current* month. Pass positive/negative integers to shift into the future/past. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the exact date of the end of the month.
- **Crucial Note**: The function typically returns the date in the exact same format it was provided. If you pass a Serial Date, you get a Serial Date. If you pass `YYYYMMDD`, you get `YYYYMMDD`. 

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the date and the shift integer.
2. **Calendar Math**: It initializes a calendar object, shifts the month by the specified `months` parameter (automatically rolling over the year if crossing December).
3. **Boundary Execution**: It invokes the native Java calendar logic to find the maximum valid day for that specific month and year combination (e.g., identifying leap years for February).
4. **Day Replacement**: It forcefully replaces the "Day" component of the shifted date with that maximum valid day.
5. **Return**: Passes the resulting date integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the End of the Current Month

```essbase
/* 
   Start: Feb 12, 2024 (Leap Year)
   Shift: 0 Months (Current Month)
   Result: 20240229
*/
"End_Of_Current_Month" = @CalcMgrExcelEOMONTH(20240212, 0);
```

### Variant 2: Shifting Forward to a Future Month-End

```essbase
/* 
   Start: Oct 15, 2024
   Shift: 1 Month Forward
   Result: 20241130 (Nov 30, 2024)
*/
"Next_Month_End" = @CalcMgrExcelEOMONTH(20241015, 1);
```

---

## Practical Examples

### Example 1: Standardizing Accounts Payable Cash Outflows

**Scenario**: You are forecasting cash flow. The system loaded thousands of open invoices with their exact `"Invoice_Date"`. The supplier terms are 90 days (roughly 3 months). You want to forecast the cash leaving the bank account on exactly the last day of the month, 3 months from now.

```essbase
FIX("FY25", "Working", @LEVEL0("Invoice"))
    
    IF("Invoice_Date" != #MISSING)
        
        /* 
           Invoice_Date = 20240114.
           Shift 3 months forward -> April.
           Force to the end of April -> 20240430.
        */
        "Forecasted_Cash_Outflow_Date" = @CalcMgrExcelEOMONTH("Invoice_Date", 3);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Contract Expiration Date Generation

**Scenario**: A customer signs a 1-year (12-month) software lease on May 5th, 2024. The contract clearly stipulates that billing continues until the absolute end of the month in which the contract expires. You shift forward 12 months, and force it to the end of May.

```essbase
FIX("FY25", "Working", @LEVEL0("Contracts"))
    
    IF("Contract_Start_Date" != #MISSING)
        
        /* 
           Start: 20240505
           Shift 12 months, force to end of month.
           Result: 20250531
        */
        "Contract_Billing_End_Date" = @CalcMgrExcelEOMONTH("Contract_Start_Date", 12);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Mismatching Formats | Passing `20241025` but expecting a Serial Date | The EPM Calc Manager wrapper attempts to return the date in the same format it was passed. If you need absolute certainty that the output is an Essbase integer (`YYYYMMDD`), explicitly cast it: `@CalcMgrExcelToDate(@CalcMgrExcelEOMONTH(...))` |
| Confusing with EDATE | Expecting the exact day to be preserved | If you shift Jan 15 forward by 1 month using `EOMONTH`, it yields Feb 28/29. It will NOT yield Feb 15. If you want to preserve the exact day of the month across the shift, you must use `@CalcMgrExcelEDATE` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelEDATE`](./@CalcMgrExcelEDATE.md) | Shifts the date forward by `X` months, but preserves the *exact day* rather than forcing it to the end of the month |
| [`@CalcMgrExcelDAYSINMONTH`](./@CalcMgrExcelDAYSINMONTH.md) | Returns just the integer representing the number of days in the month (e.g., `31`), rather than returning a full `YYYYMMDD` date |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceleomonth.html)
