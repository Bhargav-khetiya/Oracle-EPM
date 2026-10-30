# @CalcMgrAddWeeks

## Overview

`@CalcMgrAddWeeks` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It adds or subtracts a specified number of calendar weeks to a starting date formatted as a `YYYYMMDD` integer.

### Why Does This Function Exist?

While most corporate finance models operate on monthly or quarterly cycles, certain industries (like Retail, Logistics, Manufacturing, and CPG) plan heavily on weekly cadences (e.g., the 4-4-5 retail calendar, weekly production runs, or bi-weekly payrolls). 
While you *could* achieve the exact same mathematical result by multiplying the number of weeks by 7 and using the `@CalcMgrAddDays` function, `@CalcMgrAddWeeks` provides a cleaner, more semantic function specifically designed to communicate intent in weekly planning models. It makes calculation scripts significantly easier to read and audit.

### When to Use It

- To calculate weekly production or delivery schedules (e.g., Order Date + 2 Weeks).
- In retail forecasting (e.g., finding the exact date for "Week 4" of a specific promotional event).
- When aligning dates in 52-week or 4-4-5 custom calendar applications.
- To project bi-weekly payroll or wage expenses based on starting dates.

---

## Category

**Date & Time / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrAddWeeks(date, weeks)
```

### Formal Syntax

```
@CalcMgrAddWeeks(dateValue, weeksToAdd)
```

Where:
- `dateValue` — The starting baseline date, formatted as a `YYYYMMDD` integer (e.g., `20241001`).
- `weeksToAdd` — An integer representing the absolute number of weeks to add. Use a negative integer to calculate historical or past dates.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Integer | ✅ Yes | The baseline date in YYYYMMDD format. Must be a valid date integer. |
| `weeks` | Integer | ✅ Yes | The number of weeks to add or subtract. |

---

## Return Value

**Return Type**: Integer (YYYYMMDD format)

Returns a new integer representing the calculated date (which will always be exactly `weeks * 7` days later than the baseline date). The function correctly handles month and year rollovers automatically.

---

## How It Works (Behind the Scenes)

1. **Validation**: The function reads the incoming `YYYYMMDD` integer.
2. **Calendar Object Translation**: It converts the integer components into a standard Java `Calendar` object, avoiding standard decimal arithmetic pitfalls.
3. **Date Math**: It advances the calendar object by exactly `weeks * 7` days. Because it uses the Calendar object, moving from October into November or navigating across a leap year is handled natively.
4. **Format Return**: It returns the new calculated date as a `YYYYMMDD` integer, ready to be stored in an Essbase data block.

---

## Syntax Variants & Scenarios

### Variant 1: Bi-Weekly Payroll Generation

```essbase
/* Add exactly 2 weeks to the last payroll date to find the next scheduled payroll run */
"Next_Payroll_Date" = @CalcMgrAddWeeks("Last_Payroll_Date", 2);
```

### Variant 2: Lookback Analysis (Trailing Data)

```essbase
/* Subtract 4 weeks to compare current metrics to last month's weekly run rate */
"Prior_Month_Run_Date" = @CalcMgrAddWeeks("Current_Date", -4);
```

---

## Practical Examples

### Example 1: Promotional Markdown Schedule (Retail Sector)

**Scenario**: A retailer runs a clearance promotion to liquidate old inventory. The first markdown happens immediately. The second markdown is scheduled exactly 3 weeks later, and the final deep-discount liquidation happens 6 weeks after the initial start.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    /* Ensure a valid promotion start date exists for the product */
    IF("Promo_Start_Date" != #MISSING)
        
        "Markdown_1_Date" = "Promo_Start_Date";
        
        /* Calculate Week 3 target */
        "Markdown_2_Date" = @CalcMgrAddWeeks("Promo_Start_Date", 3);
        
        /* Calculate Week 6 target */
        "Liquidation_Date" = @CalcMgrAddWeeks("Promo_Start_Date", 6);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Just-In-Time (JIT) Inventory Replenishment

**Scenario**: A manufacturer operates on a Just-In-Time supply chain. They require raw materials to arrive at the factory exactly 1 week prior to the production start date. 

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Production_Start_Date" != #MISSING)
        /* Subtract 1 week from the production date to find the material requirement date */
        "Required_Materials_Date" = @CalcMgrAddWeeks("Production_Start_Date", -1);
    ENDIF
    
ENDFIX
```

---

### Example 3: Construction Project Phasing

**Scenario**: A construction project has sequential phases. Phase 2 always begins exactly 4 weeks after Phase 1 begins.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    IF("Phase_1_Start" != #MISSING)
        /* Add 4 weeks to the Phase 1 start */
        "Phase_2_Start" = @CalcMgrAddWeeks("Phase_1_Start", 4);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Assuming a week is a month | A month is roughly 4.3 weeks. Adding 4 weeks to Jan 1 yields Jan 29, not Feb 1 | Never use `@CalcMgrAddWeeks(x, 4)` to simulate adding a month. Use `@CalcMgrAddMonths(x, 1)` to ensure alignment with standard monthly boundaries |
| Invalid integer formats | Passing a serial number or standard mm/dd/yyyy string instead of `YYYYMMDD` | Ensure the input date is stored natively as a `YYYYMMDD` integer in the account |
| Mixing with `@CalcMgrAddDate` | Using the generic function but forgetting the string quotes | If you use `@CalcMgrAddWeeks(date, 2)`, it works immediately. If you use the generic `@CalcMgrAddDate(date, 2, "week")`, you must include the string parameter |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrAddDays`](./@CalcMgrAddDays.md) | For finer daily control (e.g., adding 10 days rather than full weeks) |
| [`@CalcMgrAddMonths`](./@CalcMgrAddMonths.md) | For standard corporate monthly business cycles |
| [`@CalcMgrWeeksBetween`](../15_CalcMgr_Utility/@CalcMgrWeeksBetween.md) | Calculates the number of weeks *between* two existing dates |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_addweeks.html)
