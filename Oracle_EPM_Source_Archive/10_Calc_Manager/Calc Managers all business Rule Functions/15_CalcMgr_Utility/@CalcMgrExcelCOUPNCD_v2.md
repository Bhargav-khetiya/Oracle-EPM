# @CalcMgrExcelCOUPNCD

## Overview

`@CalcMgrExcelCOUPNCD` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `COUPNCD` function directly inside an Essbase calculation script. 
It calculates the exact calendar **date** (returned as a standard `YYYYMMDD` integer) of the **N**ext **C**oupon **D**ate for a given bond or security, relative to the settlement date.

### Why Does This Function Exist—

In corporate finance and debt servicing models, debt tranches rarely have their coupon dates explicitly loaded into the database. Usually, the metadata only stores the "Issue Date", the "Maturity Date", and the "Frequency" (e.g., Semi-Annual). 
If an analyst needs to know exactly when the *next* cash outflow will occur so they can map the expense to the correct month in the forecast (e.g., "Will this interest hit the P&L in June or July—), building the calendar logic manually in Essbase is incredibly difficult. `@CalcMgrExcelCOUPNCD` resolves this. It uses the maturity date and the frequency to project the coupon schedule backwards, identifies which period the settlement date falls into, and returns the exact date of the next impending payment.

### When to Use It

- In Treasury Cash Flow forecasting models to map debt servicing payments to specific forecast months.
- When generating audit logs or reporting attributes indicating the exact date of the next required cash outflow.
- Whenever you need to migrate an Excel spreadsheet containing the `COUPNCD` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelCOUPNCD(settlement, maturity, frequency, basis)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the security is traded or evaluated. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the security expires. |
| `frequency` | Numeric | ✅ Yes | The number of coupon payments per year: Annual = `1`, Semi-annual = `2`, Quarterly = `4`. |
| `basis` | Numeric | ✅ Yes | The day count basis. `0` = US (NASD) 30/360, `1` = Actual/Actual, `2` = Actual/360, `3` = Actual/365, `4` = European 30/360. |

---

## Return Value

**Return Type**: Numeric (Integer representing a Date)

Returns an 8-digit integer representing the next coupon date (e.g., `20240701` for July 1, 2024).

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures dates are valid integers, `frequency` is exactly 1, 2, or 4, and `basis` is between 0 and 4. `settlement` must be chronologically before `maturity`.
2. **Schedule Extrapolation**: The engine takes the `maturity` date and projects backward in time using the `frequency` to build a theoretical payment schedule.
3. **Date Resolution**: It evaluates where the `settlement` date falls on that schedule, and identifies the very next date in the sequence.
4. **Return**: Passes the resulting calendar date back to Essbase as a standard `YYYYMMDD` integer.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Next Payment Date

```essbase
/* 
   Settlement: March 15, 2024
   Maturity: Dec 31, 2025
   Freq: 2 (Semi-Annual)
   Basis: 0 (US 30/360)
   Result: Calculates the date of the next payment.
*/
"Next_Payment_Date" = @CalcMgrExcelCOUPNCD(20240315, 20251231, 2, 0);
```

---

## Practical Examples

### Example 1: Mapping Coupon Payments to the Forecast

**Scenario**: You are running a 12-month rolling forecast. For a given debt tranche, you need to determine if a coupon payment will occur in the *current* month being forecasted, so you can calculate the cash outflow. The model iterates through the months, setting the "Settlement Date" to the 1st of each month.

```essbase
FIX("FY25", "Working", @LEVEL0("Debt_Tranche"))
    
    /* Iterate through the forecast months */
    FIX(@IDESCENDANTS("YearTotal"))
        
        /* 1. Calculate the exact Date of the Next Coupon Payment */
        "Target_Payment_Date" = @CalcMgrExcelCOUPNCD(
            "Assumptions"->"Current_Month_Start_Date", 
            "Maturity_Date", 
            "Payment_Frequency", 
            0
        );
        
        /* 2. Check if the payment date falls within the current month boundaries.
           (e.g., Target_Payment_Date >= 20240601 AND Target_Payment_Date <= 20240630) */
           
        IF("Target_Payment_Date" >= "Assumptions"->"Current_Month_Start_Date" AND 
           "Target_Payment_Date" <= "Assumptions"->"Current_Month_End_Date")
            
            /* The payment falls in this month. Map the cash outflow. */
            "Cash_Outflow_Interest" = "Expected_Coupon_Payment";
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misinterpreting the Output | Expecting a "Days Remaining" number | `COUPNCD` returns a calendar **Date** (e.g., `20240701`). If you want the mathematical number of days *until* that date, you must use `@CalcMgrExcelCOUPDAYSNC` |
| Passing Java Dates | `@CalcMgrExcelCOUPNCD(vJavaDate1...)` | All Calc Manager Excel functions strictly expect dates to be standard `YYYYMMDD` integers. If you pass a Java Date object, the math will fail or evaluate to `#MISSING` |
| Chronological Reversal | Settlement Date > Maturity Date | The settlement date must occur *before* the maturity date. If the bond has matured, there are no next coupon payments, and the function will fail |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelCOUPPCD`](./@CalcMgrExcelCOUPPCD.md) | Calculates the calendar date of the *Previous* coupon payment |
| [`@CalcMgrExcelCOUPDAYSNC`](../11_Date_Time/@CalcMgrExcelCOUPDAYSNC.md) | Calculates the mathematical number of days *until* the next coupon payment date |
| [`@CalcMgrExcelCOUPNUM`](./@CalcMgrExcelCOUPNUM.md) | Calculates the total number of coupon payments remaining until maturity |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelcoupncd.html)
