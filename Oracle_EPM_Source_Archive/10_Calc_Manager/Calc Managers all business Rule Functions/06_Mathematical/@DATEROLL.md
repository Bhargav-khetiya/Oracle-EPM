# @DATEROLL

## Overview

`@DATEROLL` is a **native Essbase date mathematics function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a **native Essbase Date Integer** (a Unix epoch timestamp representing seconds since Jan 1, 1970) and mathematically rolls a specific calendar component (such as Days, Months, or Years) forward or backward by a specified integer amount, returning a completely new Unix timestamp.

### Why Does This Function Exist?

Before Calc Manager introduced Java-based functions (like `@CalcMgrRollMonth`), Essbase still needed a way to project Unix timestamps into the future for things like asset retirement or contract expiration.
You cannot manually add `3` months to a Unix timestamp by adding seconds, because months have variable numbers of days. If you just add `2,592,000` seconds (30 days) to a timestamp in February, it will throw off the calendar. 
`@DATEROLL` bridges this gap natively. You pass it the Unix timestamp, a flag telling it what component to roll (e.g., `DP_MONTH`), and the amount (`3`). Essbase natively evaluates the Gregorian calendar, dynamically calculates how many exact seconds need to be added to correctly traverse leap years and month boundaries, and returns the modified Unix timestamp.

*Note: While highly optimized, most modern developers prefer `@CalcMgrRollDate` or `@CalcMgrRollMonth` because they integrate seamlessly with `YYYYMMDD` integers rather than requiring Unix timestamps. Use this primarily when working in older block architectures or when ultimate millisecond-level calculation speed is required on Unix data.*

### When to Use It

- **Warranty Expiration**: Rolling a Unix timestamp forward by `3` years (`DP_YEAR`) to establish the exact second a product warranty expires.
- **Contract End Dates**: Rolling a software license start date forward by `12` months (`DP_MONTH`).
- **SLA Deadlines**: Rolling a ticket submission timestamp forward by `48` hours (`DP_DAY` logic translated to time, or simply adding days) to set a strict cutoff.

---

## Category

**Date & Time / Native Essbase Date Math / Essbase Native Functions**

---

## Syntax

```essbase
@DATEROLL(date, date_part_flag, roll_amount)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Numeric | ✅ Yes | The Unix Epoch timestamp integer you want to modify (e.g., `1715731200`). |
| `date_part_flag` | Keyword | ✅ Yes | A strict keyword defining what piece of the calendar you want to roll: <br>`DP_YEAR` = Rolls full Years. <br>`DP_MONTH` = Rolls full Months. <br>`DP_DAY` = Rolls full Days. <br>`DP_WEEK` = Rolls full Weeks. |
| `roll_amount` | Numeric | ✅ Yes | The exact amount to roll the timestamp. <br>`Positive Number` = Rolls Forward. <br>`Negative Number` = Rolls Backward. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns a newly constructed Unix Epoch timestamp (seconds since 1970) representing the modified date.
- **Boundary Snapping**: If you use `DP_MONTH` to roll January 31st forward by 1 month, it attempts to create February 31st. Since that does not exist, the C-engine automatically snaps the timestamp backward to the last valid day of February.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: Essbase evaluates the Unix integer.
2. **Flag Interpretation**: It checks the requested `date_part_flag`.
3. **Algorithm Execution**: 
   - It converts the seconds into a human-readable Gregorian calendar layout.
   - It mathematically increments the specific component (e.g., adding `3` to the Month bucket).
   - It checks for leap years and illegal calendar days (like April 31st) and corrects them.
4. **Re-Compression**: It converts the finalized human calendar date *back* into total seconds since 1970.
5. **Return**: It returns that massive new integer back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Rolling Forward by 6 Months

```essbase
/* 
   Assumes vStartTimestamp is Jan 1st, 2024.
   Rolls forward 6 months. 
   Result is a timestamp representing July 1st, 2024.
*/
VAR vEndTimestamp = @DATEROLL(vStartTimestamp, DP_MONTH, 6);
```

---

## Practical Examples

### Example 1: Dynamic SaaS Contract Expiration 

**Scenario**: A tech company tracks thousands of SaaS subscriptions. The `Contract_Start` is stored as a Unix timestamp. The `Term_Months` is a user input (e.g., `12`, `24`, `36`). The script must dynamically calculate the exact `Contract_End` timestamp so it can be compared against `@TODAY()` in future rules.

```essbase
FIX("FY25", "Working", @LEVEL0("Subscriptions"))
    
    IF("Contract_Start" != #MISSING AND "Term_Months" > 0)
        
        /* 
           1. Roll the start timestamp forward by the Term Months.
           We use the DP_MONTH flag. Essbase handles the leap year math natively.
        */
        "Contract_End" = @DATEROLL("Contract_Start", DP_MONTH, "Term_Months");
        
        /* 
           2. Optional: We can immediately check if the contract is already expired 
           by comparing the newly generated timestamp to today's timestamp.
        */
        IF("Contract_End" < @TODAY())
            "Status_Flag" = -1; /* Expired */
        ELSE
            "Status_Flag" = 1;  /* Active */
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing YYYYMMDD Integers | `@DATEROLL(20240515, DP_MONTH, 3)` | This function DOES NOT understand `YYYYMMDD`. It assumes the number is seconds since 1970. If you pass `20240515`, it rolls a date in 1970 forward by 3 months, and outputs another tiny number. If your data is `YYYYMMDD`, you MUST use `@CalcMgrRollMonth` instead |
| Assuming Fractional Rolls | `@DATEROLL(Date, DP_MONTH, 1.5)` | The `roll_amount` strictly accepts whole integers. If you pass `1.5` (hoping to roll 1.5 months), Essbase will usually truncate it and only roll `1` month. You cannot execute fractional calendar math using this function |
| Using the Wrong Flag | Passing `DP_WEEKDAY` | While `@DATEPART` supports extracting the `DP_WEEKDAY` (e.g., finding out a day is a Tuesday), you cannot "roll" a date by a weekday. You can only roll by actual sequential time blocks (Years, Months, Weeks, Days). Ensure you only use valid roll flags |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrRollMonth`](./@CalcMgrRollMonth.md) | The modern Java equivalent. Natively handles `YYYYMMDD` inputs (via conversion) and is vastly superior if you are not using Unix timestamps |
| [`@DATEPART`](./@DATEPART.md) | The companion native function used to extract a piece of the calendar (like the Year) from a Unix timestamp |
| [`@TODAY`](./@TODAY.md) | Natively generates the current Unix timestamp |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — DATEROLL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/dateroll.html)
