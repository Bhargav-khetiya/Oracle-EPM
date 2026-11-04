# @HspDateRoll

## Overview

`@HspDateRoll` is a **Hyperion Planning (HSP) custom date function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It takes a **`YYYYMMDD` formatted integer** (e.g., `20240115`) and mathematically rolls a specific calendar component (such as Days, Months, or Years) forward or backward by a specified amount, returning a newly constructed `YYYYMMDD` integer.

### Why Does This Function Exist—

Standard Essbase block storage only understands numbers. If a user inputs a contract start date of `20240115` (Jan 15, 2024), and the contract is for `3` months, the system needs to calculate the end date.
You cannot just add `300` to `20240115` (which equals `20240415`), because standard math breaks down at year and month boundaries. (e.g., `20241115` + `300` = `20241415`, which is not a valid date). 
The native `@DATEROLL` function exists to solve this, but it *only* accepts Unix timestamps (seconds since 1970). `@HspDateRoll` was created as the Hyperion Planning bridge: it accepts user-friendly `YYYYMMDD` integers, natively handles the complex Gregorian calendar math (including leap years and month rollovers), and outputs a perfectly formatted `YYYYMMDD` integer back into the database.

*Note: In modern EPM Cloud, this function has been largely superseded by the Java-based `@CalcMgrRollDate` and `@CalcMgrRollMonth`. `@HspDateRoll` is considered legacy, but remains fully supported for backward compatibility.*

### When to Use It

- **Legacy Expiration Dates**: Calculating the exact `YYYYMMDD` expiration date of an asset by rolling its `Purchase_Date` forward by its `Useful_Life_Months`.
- **Payment Offsets**: Determining a vendor's "Net 30" payment date by rolling the `Invoice_Date` forward by `30` days.
- **Automated True-Ups**: Rolling an active forecast date backward by 1 year (`DP_YEAR`, `-1`) to dynamically target the equivalent prior-year actuals date.

---

## Category

**Date & Time / Date Rolling / Custom HSP Functions**

---

## Syntax

```essbase
@HspDateRoll(date, date_part_flag, roll_amount)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Numeric | ✅ Yes | The starting date, strictly formatted as a `YYYYMMDD` integer (e.g., `20240115`). |
| `date_part_flag` | Keyword | ✅ Yes | A strict keyword defining what piece of the calendar to roll: <br>`DP_YEAR` = Rolls full Years. <br>`DP_MONTH` = Rolls full Months. <br>`DP_DAY` = Rolls full Days. <br>`DP_WEEK` = Rolls full Weeks. |
| `roll_amount` | Numeric | ✅ Yes | The exact amount to roll. <br>`Positive Number` = Rolls Forward. <br>`Negative Number` = Rolls Backward. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns a newly constructed `YYYYMMDD` integer representing the modified date.
- **Boundary Snapping**: If you roll January 31st (`20240131`) forward by 1 month (`DP_MONTH`), February 31st does not exist. The engine intelligently snaps the date backward to the last valid day of the target month (`20240229`).

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The engine ingests the `YYYYMMDD` integer and parses it into Year, Month, and Day arrays.
2. **Addition Math**: It applies the `roll_amount` to the specific bucket requested by the `date_part_flag` (e.g., adding `3` to the Month bucket).
3. **Calendar Validation**: It checks for overflows (e.g., Month `14` becomes Year + 1, Month `2`). It factors in leap year days (like Feb 29th).
4. **Re-Compilation**: It concatenates the new Year, Month, and Day back into a single `YYYYMMDD` integer block (e.g., `20240415`).
5. **Return**: It writes that integer back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Forward by 6 Months

```essbase
/* 
   Assumes start is 20240115 (Jan 15).
   Rolls forward 6 months. 
   Result is 20240715 (July 15).
*/
VAR vEndDate = @HspDateRoll(20240115, DP_MONTH, 6);
```

---

## Practical Examples

### Example 1: Establishing Warranty Expirations

**Scenario**: A manufacturing cube tracks serial numbers. The `Sale_Date` is stored as `YYYYMMDD`. Every product comes with a standard 36-month warranty. The script must dynamically generate the `Warranty_Expiration_Date` so that downstream reporting can highlight items that are falling out of warranty.

```essbase
FIX("FY25", "Working", @LEVEL0("Products"))
    
    IF("Sale_Date" != #MISSING)
        
        /* 
           1. We roll the YYYYMMDD Sale Date forward by 36 Months.
           Using DP_MONTH ensures we don't have to manually calculate 
           how many days are in 3 years.
        */
        "Warranty_Expiration_Date" = @HspDateRoll("Sale_Date", DP_MONTH, 36);
        
        /* 
           2. Optional: Convert Today into YYYYMMDD and check if it expired.
        */
        VAR vTodayDate = @HspDateToString(@TODAY());
        
        IF(vTodayDate > "Warranty_Expiration_Date")
            "Warranty_Status" = -1; /* Expired */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Unix Timestamps | `@HspDateRoll(@TODAY(), DP_MONTH, 1)` | This is the most common error. `@HspDateRoll` strictly requires `YYYYMMDD` format. `@TODAY()` outputs a Unix timestamp (seconds since 1970). If you pass a Unix timestamp, it will attempt to parse it as a year (Year `1715`) and completely fail. You MUST use `@DATEROLL` if your input is a Unix timestamp, or convert it first |
| Fractional Rolls | `@HspDateRoll(Date, DP_MONTH, 1.5)` | The `roll_amount` strictly accepts whole integers. If you pass `1.5`, Essbase will truncate it and only roll `1` month. You cannot execute fractional calendar math |
| Relying on Legacy Functions | Using `@Hsp` for new builds | If you are building a new application in EPM Cloud, do not use this function. Use the modern Java `@CalcMgrRollDate` function. The Java engine is significantly more robust and handles edge-case boundary snapping with greater precision. Use `@HspDateRoll` only when maintaining legacy On-Premise scripts |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRollDate`](./@CalcMgrRollDate.md) | The modern, Java-based replacement for this function. Faster, safer, and supports more complex calendar operations |
| [`@DATEROLL`](./@DATEROLL.md) | The native Essbase equivalent that STRICTLY rolls Unix timestamps (seconds since 1970) rather than `YYYYMMDD` formats |
| [`@HspDateDiff`](./@HspDateDiff.md) | The companion function used to mathematically calculate the difference between two `YYYYMMDD` dates rather than rolling them |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspdateroll.html)
