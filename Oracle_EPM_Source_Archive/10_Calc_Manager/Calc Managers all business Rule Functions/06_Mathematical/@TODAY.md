# @TODAY

## Overview

`@TODAY` is a **native Essbase date & time function** in Oracle EPM Cloud (PBCS/EPBCS). It accesses the physical server's internal clock and returns the **current system date** represented as a numeric integer.

### Why Does This Function Exist—

When building automated, lights-out forecasting models, calculations are often heavily dependent on the passage of time. 
For example, you might have an `"Aging_Report"` that tracks how many days an invoice has been outstanding. To calculate that, you must subtract the `"Invoice_Date"` from "Today". 
If you use substitution variables (`&CurrentDate`), a human administrator must manually log in and update that variable every single day. If they forget, the aging report breaks. 
`@TODAY` solves this natively. By calling this function, the calculation script automatically polls the operating system clock, generating an exact, real-time date integer. This enables fully autonomous date-math, aging calculations, and conditional time-boxing without any human intervention.

### When to Use It

- **Aging Reports**: Subtracting an asset's `"Purchase_Date"` from `@TODAY` to dynamically calculate exactly how many days old the asset is.
- **Accrual True-Ups**: Calculating the precise number of days between the start of the year and "Today" to generate a dynamic, daily pro-rata expense accrual.
- **Data Load Stamping**: Writing the exact date of script execution into a `"Last_Calculated_Date"` metadata account, providing a clear audit trail for users viewing the data on reports.

---

## Category

**Date & Time / Chronological Math / Essbase Native Functions**

---

## Syntax

```essbase
@TODAY()
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| None | N/A | N/A | This function requires absolutely no parameters. However, the empty parentheses `()` are strictly required by the compiler syntax. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the current system date as an integer.
- **Format**: The integer is formatted as `YYYYMMDD`. (For example, August 24th, 2026 is returned as the integer `20260824`).
- **Server Time**: The date returned is strictly based on the **Server's** timezone (in Oracle EPM Cloud, this is universally UTC/GMT). It does NOT care what timezone the user executing the script is in.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The C-engine encounters `@TODAY()` during calculation.
2. **System Call**: It executes an internal system call to the underlying Linux/Windows operating system running the Essbase JVM.
3. **Extraction**: It pulls the current Date payload from the OS clock.
4. **Formatting**: It formats that payload into the `YYYYMMDD` standard required by Essbase date-math functions.
5. **Return**: It returns that integer to the calculation block so it can be used in formulas.

---

## Syntax Variants & Scenarios

### Variant 1: Stamping the Audit Date

```essbase
/* 
   Writes the current integer date into a tracking account.
   If run on Nov 15, 2025, it writes the number 20251115 into the block.
*/
"Last_Updated" = @TODAY();
```

---

## Practical Examples

### Example 1: Dynamic Invoice Aging (Days Outstanding)

**Scenario**: A treasury application tracks outstanding invoices. It contains an account called `"Invoice_Date"` (stored as an integer, e.g., `20241001`). The system runs an automated script every night at midnight to calculate the `"Days_Outstanding"`. The administrator uses `@TODAY()` combined with `@DATEDIFF` to calculate the exact number of days that have passed.

```essbase
FIX("FY25", "Working", @LEVEL0("Invoices"))
    
    /* 
       1. Check if the invoice is active (it has a date).
    */
    IF("Invoice_Date" > 0)
        
        /* 
           2. Use @DATEDIFF to subtract the Invoice Date from Today.
           @TODAY() dynamically provides the end-date for the math.
        */
        "Days_Outstanding" = @DATEDIFF("Invoice_Date", @TODAY());
        
        /* 
           3. If it's over 90 days, flag it for collections.
        */
        IF("Days_Outstanding" > 90)
            "Collections_Flag" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Timezone Drifts | "It's returning tomorrow's date!" | Oracle EPM Cloud servers are hosted in UTC (Coordinated Universal Time). If you run a script in California at 6:00 PM Pacific Time on August 1st, it is already 1:00 AM on August 2nd in UTC. `@TODAY()` will return `20260802`. If your logic strictly requires local time boundary enforcement, you must write custom logic to adjust the integer based on your timezone |
| Standard Math vs Date Math | `20260802 - 20260730` | Because `@TODAY()` returns an integer like `20260802`, you CANNOT just subtract another date from it using standard subtraction (`-`). Standard math thinks the difference between 20260802 and 20260730 is `72`. But in date math, the difference is only `3` days! You MUST use `@DATEDIFF` to evaluate the gap between two date integers |
| Forgetting Parentheses | `@TODAY` | In Essbase, functions requiring no parameters still demand empty parentheses. If you write `"Date" = @TODAY;`, the compiler will crash. You must write `"Date" = @TODAY();` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@DATEDIFF`](./@DATEDIFF.md) | The required mathematical function used to calculate the actual number of days between `@TODAY()` and a historical date |
| [`@DATEPART`](./@DATEPART.md) | Extracts specific pieces of the date (like isolating just the "Month" or "Year" from the `YYYYMMDD` integer returned by `@TODAY`) |
| [`@DATEROLL`](./@DATEROLL.md) | Allows you to take `@TODAY()` and roll it forward or backward by a specific number of months to calculate expiration dates |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — TODAY](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/today.html)
