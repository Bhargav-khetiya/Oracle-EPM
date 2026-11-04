# @CalcMgrExcelMONTH

## Overview

`@CalcMgrExcelMONTH` is a **custom Calc Manager date extraction function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `MONTH` function directly inside an Essbase calculation script. 
It analyzes an Excel Serial Date (or a standard Essbase `YYYYMMDD` integer) and extracts solely the **Month of the Year**, returning it as an integer between 1 and 12.

### Why Does This Function Exist—

When evaluating dates in Essbase, standard integers (`20241025`) contain the month embedded in the middle (`10`). While you can theoretically extract this using Essbase math (e.g., dividing by 100, truncating, and doing modulus logic), this is highly tedious and fails completely if the date is loaded as an Excel Serial Date (`45590`).
`@CalcMgrExcelMONTH` utilizes the Java engine to evaluate the date (safely handling both Serial Dates and `YYYYMMDD` formats automatically) and extracts the exact calendar month with zero mathematical hacking required. This ensures perfect parity with legacy Excel models that rely on `=MONTH(A1)` for seasonal aggregation or conditional logic.

### When to Use It

- **Seasonality Tracking**: Aggregating sales data from specific dates into "Month" buckets (e.g., assigning all transactions where `MONTH == 12` to a Holiday account).
- **Conditional Logic**: Triggering specific accruals or bonuses that only happen in specific months (e.g., Q1 bonuses trigger when `MONTH == 3`).
- Whenever you need to migrate an Excel spreadsheet containing the `MONTH` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelMONTH(date)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Integer | ✅ Yes | The date to evaluate. Can be passed as an Excel Serial Date (e.g., `45590`) or a standard Essbase integer (`20241025`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer between `1` (January) and `12` (December) representing the month of the year.
- e.g., `@CalcMgrExcelMONTH(20241025)` returns `10`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the integer.
2. **Format Resolution**: It intelligently determines if the number is a Serial Date (typically < 100000) or an Essbase Date (e.g., `20240101`). 
3. **Extraction**: It initializes a calendar object and isolates the specific month component.
4. **Return**: Passes the resulting month integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting from a Serial Date

```essbase
/* Assume 45590 is Oct 25, 2024. Returns 10. */
"Month_Component" = @CalcMgrExcelMONTH(45590);
```

### Variant 2: Extracting from a YYYYMMDD Date

```essbase
/* Extracts the month from an Essbase integer. Returns 3. */
"Month_Component" = @CalcMgrExcelMONTH(20240315);
```

---

## Practical Examples

### Example 1: Seasonal Commission Modifiers

**Scenario**: A retail company pays standard commissions to its sales reps. However, during the summer months (June, July, August), they pay a "Summer Surge" multiplier of 1.5x. The model logs every individual sale with an exact `"Transaction_Date"`. The script extracts the month to see if the multiplier applies.

```essbase
FIX("FY25", "Working", @LEVEL0("Transactions"))
    
    IF("Transaction_Date" != #MISSING AND "Sale_Amount" > 0)
        
        /* 1. Extract the Month */
        VAR vMonth = @CalcMgrExcelMONTH("Transaction_Date");
        
        /* 2. Check if the month is June (6), July (7), or August (8) */
        IF(vMonth >= 6 AND vMonth <= 8)
            
            /* Apply Summer Multiplier */
            "Commission_Expense" = ("Sale_Amount" * "Base_Commission_Rate") * 1.5;
            
        ELSE
            
            /* Standard Commission */
            "Commission_Expense" = "Sale_Amount" * "Base_Commission_Rate";
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Reassembling Dates Dynamically

**Scenario**: You have an exact invoice date (`20241025`). The contract dictates that payment is due on the 15th of the *following* month. You extract the month, add 1, and use `@CalcMgrExcelDATE` to reassemble a brand new due date.

```essbase
FIX("FY25", "Working", @LEVEL0("Invoice"))
    
    IF("Invoice_Date" != #MISSING)
        
        /* Extract components */
        VAR vYear = @CalcMgrExcelYEAR("Invoice_Date");
        VAR vMonth = @CalcMgrExcelMONTH("Invoice_Date");
        
        /* Calculate target month */
        VAR vNextMonth = vMonth + 1;
        VAR vNextYear = vYear;
        
        /* Handle December rollover (If Month 12 + 1 = 13, roll to Jan of next year) */
        IF(vNextMonth == 13)
            vNextMonth = 1;
            vNextYear = vNextYear + 1;
        ENDIF
        
        /* Reassemble the date for the 15th of the next month */
        "Calculated_Due_Date" = @CalcMgrExcelDATE(vNextYear, vNextMonth, 15);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Java Dates | `@CalcMgrExcelMONTH(vJavaDate)` | This function strictly expects integers (Serial Dates or YYYYMMDD). If you pass a massive Java Date object, the function will fail or evaluate incorrectly. Use `@CalcMgrGetDatePart` if you need to extract months directly from a Java object |
| Passing 14-digit Timestamps | `@CalcMgrExcelMONTH(20241025143000)` | The auto-resolver will likely fail to parse a 14-digit timestamp correctly. Ensure you are only passing 8-digit dates or Serial Dates |
| Evaluating Zeros | `@CalcMgrExcelMONTH(0)` | If an empty block is evaluated and a cell is `0` instead of `#MISSING`, passing it to this function will treat it as Excel's epoch (January 0, 1900) and will return `1`. Always wrap in an `IF("Date" > 0)` block |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelDAY`](./@CalcMgrExcelDAY.md) | Extracts the Day component (`1-31`) from a date |
| [`@CalcMgrExcelYEAR`](./@CalcMgrExcelYEAR.md) | Extracts the Year component (e.g., `2024`) from a date |
| [`@CalcMgrExcelDATE`](./@CalcMgrExcelDATE.md) | Re-assembles extracted Year, Month, and Day integers back into a valid Excel Serial Date |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelmonth.html)
