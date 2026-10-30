# @CalcMgrCounterUpdate

## Overview

`@CalcMgrCounterUpdate` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It directly forces a new numeric value into a specific memory counter stored in the background Java heap, completely overwriting whatever value was previously stored there.

### Why Does This Function Exist?

Standard memory counters (`@CalcMgrCounterAddNumber`) are inherently additive. If a counter holds the value `5`, and you add `10`, the new value is `15`. 
However, in certain algorithmic flows, you don't want to *add* to the existing number; you want to *replace* it entirely. For example, if you are tracking the "Maximum Inventory Level" encountered during a loop, you want to continuously overwrite the counter with the new highest number you find, rather than adding the new number to the old number.
`@CalcMgrCounterUpdate` acts as a direct setter. It allows you to assign a specific, absolute value to a memory bucket, bypassing the additive logic. 

### When to Use It

- To implement "High-Water Mark" or "Low-Water Mark" logic (tracking the maximum or minimum value found during a script execution).
- To reset a counter to a specific baseline other than zero (e.g., resetting an available budget counter to `$1,000,000` at the start of a new department's loop).
- To act as a pure global variable setter in a Groovy-hybrid architecture.

---

## Category

**State Tracking / Memory / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterUpdate("CounterName", newValue)
```

### Formal Syntax

```
@CalcMgrCounterUpdate("counterNameString", numericValue)
```

Where:
- `"counterNameString"` — The exact name of the memory bucket you wish to update. Must be enclosed in double quotes.
- `numericValue` — The exact new numeric value to force into the bucket.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the specific numeric counter you want to overwrite. If it does not exist, it will be created and instantly assigned this value. |
| `newValue` | Numeric| ✅ Yes | The exact number to place into the memory bucket. Can be a hardcoded integer/decimal, or a dynamic data value pulled from an Essbase account. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the *new total value* of the counter (which is simply the `newValue` you just passed to it). 
*(Note: As with most Calc Manager custom functions, you must assign the result of this function to a temporary dummy account or variable to force Essbase to execute it).*

---

## How It Works (Behind the Scenes)

1. **Lookup/Initialization**: The Java engine checks the active memory heap for a counter named `"CounterName"`. If it does not exist, it creates it.
2. **Replacement**: It completely deletes whatever numeric value was stored in that bucket.
3. **Assignment**: It inserts the `newValue` into the bucket.
4. **Return**: It returns the `newValue` back to the Essbase engine to confirm the operation was successful.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Baseline Reset

```essbase
/* Forces the available budget bucket to exactly 500, regardless of previous value */
VAR vIgnore = @CalcMgrCounterUpdate("Available_Budget", 500);
```

### Variant 2: High-Water Mark Tracking

```essbase
/* If the current entity's profit is higher than the max recorded profit, overwrite it */
VAR vCurrentMax = @CalcMgrCounterGetNumber("Max_Profit_Recorded");

IF("Profit" > vCurrentMax)
    VAR vDummy = @CalcMgrCounterUpdate("Max_Profit_Recorded", "Profit");
ENDIF
```

---

## Practical Examples

### Example 1: Tracking the Peak Output of a Factory (High-Water Mark)

**Scenario**: You have 365 days of daily production data for a factory. You need to scan through all 365 days, find the single day with the absolute highest production volume, and stamp that "Peak Output" number into a summary reporting account.

```essbase
FIX("FY25", "Working", "Factory_A")
    
    /* Ensure we start with a clean slate of 0 */
    VAR vInit = @CalcMgrCounterClear("Peak_Output");
    
    /* Loop through the days */
    FIX(@LEVEL0("Time"))
        
        /* 1. Retrieve the current Max Value stored in memory */
        VAR vCurrentMax = @CalcMgrCounterGetNumber("Peak_Output");
        
        /* 2. Compare today's output to the Max */
        IF("Daily_Production_Units" > vCurrentMax)
            
            /* 3. Today was higher! Overwrite the memory bucket with today's value */
            VAR vDummy = @CalcMgrCounterUpdate("Peak_Output", "Daily_Production_Units");
            
        ENDIF
        
    ENDFIX
    
    /* After scanning all 365 days, retrieve the final highest number and stamp it */
    "Peak_Output_Summary" = @CalcMgrCounterGetNumber("Peak_Output");
    
ENDFIX

/* Cleanup */
VAR vClean = @CalcMgrCounterClear("Peak_Output");
```

---

### Example 2: Non-Zero Initialization for a Countdown

**Scenario**: In a standard training capacity script, you want to count down available seats as you iterate through employees. The number of available seats is not hardcoded; it is stored in a database account called `"Total_Available_Seats"` at the Department level. You must initialize the memory bucket with this dynamic number before beginning the employee loop.

```essbase
FIX("FY25", "Working", @LEVEL0("Department"))
    
    /* 1. Initialize the memory bucket with the dynamic starting capacity */
    VAR vSetup = @CalcMgrCounterUpdate("Remaining_Seats", "Total_Available_Seats");
    
    /* 2. Loop through the employees in this department */
    FIX(@LEVEL0("Employee"))
        
        IF("Requires_Training" == 1 AND @CalcMgrCounterGetNumber("Remaining_Seats") > 0)
            
            /* Assign the training flag */
            "Assigned_To_Training" = 1;
            
            /* Decrement the seats */
            VAR vDummy = @CalcMgrCounterDecrement("Remaining_Seats");
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting additive logic | Using `Update` when you meant `AddNumber` | If the counter is at 5, and you use `Update("Count", 2)`, the new total is 2, not 7. `Update` is a pure overwrite function. Use `@CalcMgrCounterAddNumber` for addition |
| Using it on a Text Counter | `Update("Log", "New String")` | This specific function is for Numeric variables. If you attempt to pass a string into it, Essbase validation will fail. To replace text, you must use `@CalcMgrCounterUpdateText` |
| Syntax execution failures | `@CalcMgrCounterUpdate("Cap", 500);` | In Essbase, you cannot call a function without assigning it. Use `VAR vDummy = @CalcMgrCounterUpdate(...)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterUpdateText`](./@CalcMgrCounterUpdateText.md) | The equivalent function for completely overwriting a text string in memory |
| [`@CalcMgrCounterAddNumber`](./@CalcMgrCounterAddNumber.md) | Used when you want to add to the existing number rather than replace it entirely |
| [`@CalcMgrCounterUpdateNumber`](./@CalcMgrCounterUpdateNumber.md) | A legacy variant often used interchangeably, though specific Map update functions exist |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterupdate.html)
