# @CalcMgrCounterUpdateNumber

## Overview

`@CalcMgrCounterUpdateNumber` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It functions almost identically to `@CalcMgrCounterUpdate`—it directly forces a new numeric value into a specific memory counter stored in the Java heap, completely overwriting the previous value. 

### Why Does This Function Exist—

In the evolution of the Calc Manager Custom Function library, function names were iteratively standardized. The existence of both `@CalcMgrCounterUpdate` and `@CalcMgrCounterUpdateNumber` is largely an artifact of this evolution. 
`@CalcMgrCounterUpdateNumber` was introduced to explicitly mirror the naming convention of its sibling, `@CalcMgrCounterUpdateText`. By explicitly stating "Number" in the function name, it makes the codebase more self-documenting for future developers, clarifying that this memory bucket holds mathematical data, not string logs.
Under the hood, it performs the exact same direct-overwrite assignment logic as the standard `Update` function.

### When to Use It

- To implement "High-Water Mark" or "Low-Water Mark" logic (tracking the maximum or minimum value found during a script execution).
- To reset a counter to a specific dynamic baseline (e.g., refreshing a "Budget_Remaining" bucket based on a new cost center's data).
- To enforce strict naming conventions in your script, explicitly distinguishing between Number updates and Text updates.

---

## Category

**State Tracking / Memory / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterUpdateNumber("CounterName", newValue)
```

### Formal Syntax

```
@CalcMgrCounterUpdateNumber("counterNameString", numericValue)
```

Where:
- `"counterNameString"` — The exact name of the memory bucket you wish to update. Must be enclosed in double quotes.
- `numericValue` — The exact new numeric value to force into the bucket, overwriting what was there.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the specific numeric counter you want to overwrite. If it does not exist, it will be instantly created. |
| `newValue` | Numeric| ✅ Yes | The exact number to place into the memory bucket. Can be a hardcoded integer/decimal, or a dynamic data value pulled from an Essbase account. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the *new total value* of the counter (which is simply the `newValue` you just passed to it). 
*(Note: As with most Calc Manager custom functions, you must assign the result of this function to a temporary dummy account or variable to force Essbase to evaluate and execute it).*

---

## How It Works (Behind the Scenes)

1. **Lookup/Initialization**: The Java engine checks the active memory heap for a counter named `"CounterName"`. If it does not exist, it initializes it.
2. **Replacement**: It completely flushes whatever numeric value was previously stored in that bucket.
3. **Assignment**: It inserts the `newValue` directly into the bucket.
4. **Return**: It returns the `newValue` back to the Essbase engine.

---

## Syntax Variants & Scenarios

### Variant 1: Forcing a Reset

```essbase
/* The counter was previously 1500. This forces it to exactly 0. */
VAR vIgnore = @CalcMgrCounterUpdateNumber("Error_Count", 0);
```

### Variant 2: Capturing a Lowest Value (Low-Water Mark)

```essbase
/* If the current cost is lower than the lowest recorded cost, overwrite the record */
VAR vCurrentMin = @CalcMgrCounterGetNumber("Min_Cost_Recorded");

/* Assuming Min_Cost_Recorded was initialized artificially high (e.g., 999999) */
IF("Production_Cost" < vCurrentMin AND "Production_Cost" > 0)
    VAR vDummy = @CalcMgrCounterUpdateNumber("Min_Cost_Recorded", "Production_Cost");
ENDIF
```

---

## Practical Examples

### Example 1: Dynamic Rolling Forecast Initialization

**Scenario**: You are iterating through 12 months of a forecast. The first month's "Starting Cash" is pulled from actuals. Every subsequent month's "Starting Cash" is just the previous month's "Ending Cash". 
Because Essbase evaluates blocks somewhat unpredictably based on density, using a Java memory counter forces strict chronological tracking. You overwrite the memory bucket at the end of each month so the next month can read it.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 1. Initialize the bucket with the Actuals from Dec of Prior Year */
    VAR vSetup = @CalcMgrCounterUpdateNumber("Cash_Rollover", "Ending_Cash"->"Actual"->"FY24"->"Dec");
    
    /* 2. Iterate through the forecast months sequentially */
    FIX(@IDESCENDANTS("YearTotal"))
        
        /* Set Starting Cash from the memory bucket */
        "Starting_Cash" = @CalcMgrCounterGetNumber("Cash_Rollover");
        
        /* Calculate Ending Cash */
        "Ending_Cash" = "Starting_Cash" + "Cash_In" - "Cash_Out";
        
        /* Overwrite the memory bucket with the new Ending Cash for the next month to use */
        VAR vRollover = @CalcMgrCounterUpdateNumber("Cash_Rollover", "Ending_Cash");
        
    ENDFIX
    
ENDFIX

/* Cleanup */
VAR vClean = @CalcMgrCounterClear("Cash_Rollover");
```

---

### Example 2: Caching Exchange Rates to Avoid Repeated Lookups

**Scenario**: You are calculating 5,000 products for a specific European entity. The EUR-to-USD exchange rate does not change by product. Rather than executing a slow cross-dimensional lookup (`"FX_Rate"->"EUR"`) 5,000 times, you grab it once, push it to a memory counter, and then use the memory counter for the product loop, which is significantly faster.

```essbase
FIX("FY25", "Working", "Entity_Europe")
    
    /* 1. Cache the rate in memory before the dense loop */
    VAR vCache = @CalcMgrCounterUpdateNumber("Cached_FX", "FX_Rate"->"EUR");
    
    /* 2. Execute the massive product loop */
    FIX(@LEVEL0("Product"))
        
        /* Pull from memory instead of the database */
        "Revenue_USD" = "Revenue_Local" * @CalcMgrCounterGetNumber("Cached_FX");
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting additive logic | Using `UpdateNumber` when you meant `AddNumber` | If the counter is at 10, and you use `UpdateNumber("Count", 5)`, the new total is 5, not 15. This function is a pure overwrite. Use `@CalcMgrCounterAddNumber` if you want to sum values |
| Using on Text | `UpdateNumber("Log", "Error")` | This explicitly requires a numeric input. If you need to overwrite a text log, use `@CalcMgrCounterUpdateText` |
| Forgetting variable assignment | `@CalcMgrCounterUpdateNumber("Rate", 1.5);` | You cannot call a function in a vacuum. It must be assigned: `VAR vDummy = @CalcMgrCounterUpdateNumber(...)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterUpdate`](./@CalcMgrCounterUpdate.md) | The legacy, identically functioning version of this function |
| [`@CalcMgrCounterUpdateText`](./@CalcMgrCounterUpdateText.md) | The equivalent function for completely overwriting a text string in memory |
| [`@CalcMgrCounterUpdateNumberText`](./@CalcMgrCounterUpdateNumberText.md) | A specialized mapping function that updates a specific key in a hash map |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterupdatenumber.html)
