# @CalcMgrAddDays

## Overview

`@CalcMgrAddDays` is a **custom Calc Manager date function** in Oracle EPM Cloud (PBCS/EPBCS). It adds or subtracts a specified number of exact calendar days to a starting date formatted as a `YYYYMMDD` integer.

### Why Does This Function Exist?

While you can technically use `@CalcMgrAddDate(Date, 30, "day")`, `@CalcMgrAddDays` is a cleaner, more concise shortcut specifically built for daily increments. 
It eliminates the need to pass the `"day"` string parameter, making the code slightly shorter, cleaner to read, and reducing the potential for syntax errors caused by forgotten quotation marks.
Because standard Essbase math cannot handle date addition (adding `30` to `20241215` yields `20241245`, an invalid date), this function safely navigates month boundaries, varying month lengths, and leap years.

### When to Use It

- To calculate short-term deadlines based on standard net terms (e.g., Invoice Date + 30 Days, or Net 60).
- To find exact target dates for shipping, fulfillment, or manufacturing lead times.
- To create a rolling daily forecast timeline for working cash flow models.
- When building daily-level granularity planning applications (like retail daily sales).

---

## Category

**Date & Time / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrAddDays(date, days)
```

### Formal Syntax

```
@CalcMgrAddDays(dateValue, daysToAdd)
```

Where:
- `dateValue` — The starting baseline date, formatted as a `YYYYMMDD` integer (e.g., `20241201`).
- `daysToAdd` — An integer representing the absolute number of calendar days to advance the date (use a negative integer to calculate a date in the past).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Integer | ✅ Yes | The baseline date in YYYYMMDD format. This is usually pulled dynamically from a driver account. |
| `days` | Integer | ✅ Yes | The number of days to add or subtract. Can be a hardcoded number or dynamically pulled from another account. |

---

## Return Value

**Return Type**: Integer (YYYYMMDD format)

Returns a new integer representing the calculated date, mathematically adjusting for month and year boundaries automatically.

---

## How It Works (Behind the Scenes)

1. **Format Validation**: The function reads the `YYYYMMDD` integer (e.g., `20241025`). It splits this into Year (2024), Month (10), and Day (25).
2. **Date Math Translation**: It converts the integer components into a standard Java `Calendar` object, which natively understands the Gregorian calendar rules.
3. **Rollover Calculation**: It adds the specified number of days. If the addition exceeds the length of the current month (e.g., adding 10 days to Oct 25 rolls over to Nov 4), the Calendar object handles the transition seamlessly.
4. **Format Return**: It repackages the new date back into a `YYYYMMDD` integer (e.g., `20241104`) and returns it to the Essbase data block.

---

## Syntax Variants & Scenarios

### Variant 1: Adding Days (Future Calculation)

```essbase
/* Add exactly 45 days to the invoice date */
"Payment_Due_Date" = @CalcMgrAddDays("Invoice_Date", 45);
```

### Variant 2: Subtracting Days (Past Calculation)

```essbase
/* Subtract exactly 14 days to determine when an order must be placed */
"Order_Placement_Date" = @CalcMgrAddDays("Required_Delivery_Date", -14);
```

---

## Practical Examples

### Example 1: Accounts Receivable (Net 30 Cash Flow Terms)

**Scenario**: You want to project a daily cash flow model. If an invoice is generated today, cash is expected to hit the bank account exactly 30 days later based on standard Net 30 payment terms.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* Check if an invoice was issued */
    IF("Invoice_Date" != #MISSING)
        /* Calculate exact expected cash receipt date */
        "Expected_Receipt_Date" = @CalcMgrAddDays("Invoice_Date", 30);
    ENDIF
    
ENDFIX
```

---

### Example 2: Manufacturing Lead Time Calculation (Dynamic Days)

**Scenario**: To meet a specific product launch date, manufacturing must begin a certain number of days prior. The lead time varies by product, so the number of days to subtract is dynamic rather than hardcoded.

```essbase
FIX("FY25", "Working", @LEVEL0("Product"))
    
    IF("Launch_Date" != #MISSING AND "Lead_Time_Days" != #MISSING)
        
        /* Because we want to subtract the days, we multiply the lead time by -1 */
        VAR vDaysToSubtract = "Lead_Time_Days" * -1;
        
        /* Apply the dynamic offset to find the manufacturing start date */
        "Mfg_Start_Date" = @CalcMgrAddDays("Launch_Date", vDaysToSubtract);
        
    ENDIF
    
ENDFIX
```

---

### Example 3: Calculating Next Inspection Date

**Scenario**: A piece of factory equipment requires a safety inspection every 180 days based on regulatory requirements.

```essbase
FIX("FY25", "Working", @LEVEL0("Equipment"))
    
    IF("Last_Inspection_Date" != #MISSING)
        /* Add 180 days to find the next mandatory inspection deadline */
        "Next_Inspection_Date" = @CalcMgrAddDays("Last_Inspection_Date", 180);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Standard Integer Addition | Writing `"Date" = "Date" + 30` | Adding 30 to `20241215` results in `20241245`, which is an invalid date. Always use `@CalcMgrAddDays` |
| Using string/MMDDYYYY formats | Passing `01152024` will cause the function to fail or return garbage data | Ensure all date accounts feeding into this function store values strictly as `YYYYMMDD` integers |
| Assuming Business Days | `@CalcMgrAddDays` adds *calendar* days, including weekends and holidays | If you need strictly business days, you must use a more complex custom script or rely on a centralized calendar mapping dimension |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrAddMonths`](./@CalcMgrAddMonths.md) | Shortcut function for adding months instead of days |
| [`@CalcMgrAddWeeks`](./@CalcMgrAddWeeks.md) | Shortcut function for adding weeks instead of days |
| [`@CalcMgrAddDate`](./@CalcMgrAddDate.md) | The generic version that allows for dynamic switching of the time unit (day/month/year) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_adddays.html)
