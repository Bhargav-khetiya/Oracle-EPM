# @CalcMgrExcelYEARFRAC

## Overview

`@CalcMgrExcelYEARFRAC` is a **custom Calc Manager date manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `YEARFRAC` function directly inside an Essbase calculation script. 
It calculates the exact **fraction of a year** that has elapsed between two specific dates, based on various financial day-count conventions (like NASD 30/360 or Actual/Actual).

### Why Does This Function Exist—

In corporate finance, interest, depreciation, and contractual obligations are often tied to annual rates. If an annual interest rate is 6%, but a loan is only held from Feb 15th to Nov 4th, you must prorate that 6% based on exactly what fraction of the year the loan was active. 
Calculating this manually in Essbase is incredibly complex. You have to calculate the exact number of days between the two dates (accounting for leap years) and then divide by 365, 360, or 365.25 depending on the specific banking calendar the contract was signed under. 
`@CalcMgrExcelYEARFRAC` offloads all of this calendar and fractional math to the Java engine. It takes the start date, the end date, and the specific calendar basis, and instantly returns a precise decimal (e.g., `0.75` for 9 months), allowing you to accurately prorate annual financials without manual calendar loops.

### When to Use It

- **Interest Accruals**: Prorating an annual interest rate to calculate exact interest owed for a partial-year loan holding.
- **Contract Proration**: Calculating the exact fraction of an annual software license fee a customer owes if they start mid-year.
- Whenever you need to migrate an Excel spreadsheet containing the `YEARFRAC` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelYEARFRAC(start_date, end_date, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | Integer | ✅ Yes | The starting date (`YYYYMMDD`). |
| `end_date` | Integer | ✅ Yes | The ending date (`YYYYMMDD`). |
| `basis` | Numeric | ❌ No  | The day count basis. <br>`0` (Default) = US (NASD) 30/360. <br>`1` = Actual/Actual. <br>`2` = Actual/360. <br>`3` = Actual/365. <br>`4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the fraction of the year as a decimal.
- E.g., If the dates are exactly 6 months apart, it returns `0.50`.
- E.g., If the dates are 18 months apart, it returns `1.50`.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures both dates are valid integers. If the `basis` is omitted, it defaults to `0` (US 30/360).
2. **Day-Count Math**: It calculates the exact number of days between the two dates using the specified calendar `basis`. (e.g., under 30/360, February is mathematically treated as having 30 days).
3. **Fractional Division**: It takes the total calculated days and divides it by the denominator of the basis (e.g., 360 or 365).
4. **Return**: Passes the finalized decimal fraction back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Standard 30/360 Proration

```essbase
/* 
   Start: Jan 1, 2024
   End: Jun 30, 2024
   Basis: 0 (US 30/360)
   Result: Exactly 180 days / 360. Returns 0.50
*/
"Proration_Factor" = @CalcMgrExcelYEARFRAC(20240101, 20240630, 0);
```

### Variant 2: Actual/365 Proration

```essbase
/* 
   Start: Jan 1, 2024
   End: Jun 30, 2024
   Basis: 3 (Actual/365). 
   Because 2024 is a leap year, Actual days is 181. 
   Result: 181 / 365. Returns ~ 0.4958
*/
"Strict_Proration_Factor" = @CalcMgrExcelYEARFRAC(20240101, 20240630, 3);
```

---

## Practical Examples

### Example 1: Prorating Annual Software License Revenue

**Scenario**: A SaaS company signs an enterprise contract for `$120,000` per year. However, the customer signed on `"Contract_Start_Date"` (March 15th). The company can only recognize revenue through the end of the Fiscal Year (`"Fiscal_Year_End"` = Dec 31st). The FP&A team must calculate exactly what fraction of the annual fee should be recognized in the current year.

```essbase
FIX("FY25", "Working", @LEVEL0("Customers"))
    
    IF("Contract_Start_Date" != #MISSING AND "Annual_Contract_Value" > 0)
        
        /* 
           1. Calculate the exact fraction of the year the contract is active.
           Using Actual/365 basis (3) for precise daily revenue recognition.
        */
        "Current_Year_Proration" = @CalcMgrExcelYEARFRAC(
            "Contract_Start_Date", 
            "Assumptions"->"Fiscal_Year_End_Date", 
            3 
        );
        
        /* 
           2. Multiply the Annual Value by the Proration Fraction.
           E.g., $120,000 * 0.7972 = $95,664 to be recognized this year.
        */
        "Recognized_Revenue" = "Annual_Contract_Value" * "Current_Year_Proration";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Reverse Dates | End Date before Start Date | `YEARFRAC` technically calculates the absolute difference. If you put the End Date first, it will still return a positive fraction. However, it is best practice to keep them chronological. If you need to calculate negative accruals, multiply the result by `-1` manually |
| Passing Excel Serial Dates | `@CalcMgrExcelYEARFRAC(45657, 45800, 0)` | Unlike `YEAR` or `DAY`, which require Excel Serial Dates, this specific function (because it mimics a later Excel add-in function) requires native Essbase `YYYYMMDD` integers. If you pass an Excel serial number, the function will fail |
| Misunderstanding 30/360 | Complaining February calculations are "wrong" | By default, the function uses the US NASD 30/360 rule. This rule artificially treats February 28th as the 30th of the month for calculation purposes. If you want strict chronological day-counting, you MUST pass `1` (Actual/Actual) or `3` (Actual/365) as the basis parameter |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelDAYS360`](./@CalcMgrExcelDAYS360.md) | Calculates the raw number of days between two dates based on the 360-day calendar, without dividing by the year denominator |
| [`@CalcMgrDaysBetween`](./@CalcMgrDaysBetween.md) | Calculates the exact number of Actual days between two `YYYYMMDD` integers |
| [`@CalcMgrExcelToDate`](./@CalcMgrExcelToDate.md) | Can be used to convert an Excel Serial Date into the `YYYYMMDD` integer required by `YEARFRAC` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelyearfrac.html)
