# @CalcMgrCounterDecrement

## Overview

`@CalcMgrCounterDecrement` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It specifically subtracts a value of exactly `1` from an existing, named memory counter running in the background Java heap during the execution of a Business Rule.

### Why Does This Function Exist—

When developers track states or occurrences (e.g., keeping a running tally of active projects), they typically use `@CalcMgrCounterAddNumber("Count", 1)` to increment the counter, and `@CalcMgrCounterAddNumber("Count", -1)` to decrement it. 
However, decrementing a counter by exactly 1 is such a common programmatic operation (equivalent to the `i--` operator in Java/C++) that Calc Manager provides `@CalcMgrCounterDecrement` as a semantic shortcut. 
It makes the calculation script easier to read, explicitly communicating to the next developer that this line of code is stepping backward through a sequence, removing a flag, or counting down a loop, rather than performing standard addition with a negative variable.

### When to Use It

- When implementing a "Countdown" logic pattern (e.g., a "While loop" equivalent that counts down from 10 to 0).
- When a previously counted item is disqualified later in the calculation pass and needs to be removed from the running total.
- To track available inventory or available capacity slots in a resource planning model.

---

## Category

**State Tracking / Memory / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterDecrement("CounterName")
```

### Formal Syntax

```
@CalcMgrCounterDecrement("counterNameString")
```

Where:
- `"counterNameString"` — The unique name of the memory bucket you wish to decrement. Must be enclosed in double quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the numeric counter. If the counter does not exist, the engine initializes it at 0, and then immediately decrements it to `-1`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the *new total value* of the counter immediately after `1` is subtracted from it. 
*(Note: As with most Calc Manager custom functions, you must assign the result of this function to a temporary dummy account or variable to force Essbase to execute it).*

---

## How It Works (Behind the Scenes)

1. **Initialization Check**: The Java engine checks if a numeric counter named `"CounterName"` exists in the active memory heap. If it doesn't, it creates it and sets the baseline to `0`.
2. **Subtraction**: It subtracts exactly `1` from the counter's current total.
3. **Persistence**: The updated counter remains in memory until the entire Business Rule finishes executing (or until explicitly cleared), allowing it to be accessed from other `FIX` blocks.
4. **Return**: It returns the new total to the calculation context.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Decrement (Reversing an Increment)

```essbase
/* Removes 1 from the total 'ActiveProjects' count */
VAR vIgnore = @CalcMgrCounterDecrement("ActiveProjects");
```

---

## Practical Examples

### Example 1: Capacity Planning (Counting Down Slots)

**Scenario**: You have a training center with a strict capacity of exactly 50 seats per quarter. As you iterate through the list of newly hired employees, you check if they need training. If they do, you decrement the available seats counter. If the counter hits 0, you must stop assigning them to this quarter and push them to the next quarter.

```essbase
/* Initialize the starting capacity */
VAR vInit = @CalcMgrCounterAddNumber("Available_Seats", 50);

FIX("FY25", "Working", @LEVEL0("Employee"))
    
    IF("Needs_Training" == 1)
        
        /* Check if we still have capacity BEFORE assigning */
        IF(@CalcMgrCounterGetNumber("Available_Seats") > 0)
            
            /* Assign to Q1 */
            "Training_Quarter" = 1;
            
            /* Decrement the available capacity by exactly 1 */
            VAR vDummy = @CalcMgrCounterDecrement("Available_Seats");
            
        ELSE
            
            /* No seats left, push to Q2 */
            "Training_Quarter" = 2;
            
        ENDIF
        
    ENDIF
    
ENDFIX

/* Cleanup */
VAR vClear = @CalcMgrCounterClear("Available_Seats");
```

---

### Example 2: Disqualifying a Previously Counted Entity

**Scenario**: In Pass 1 of your script, you count every store that had positive revenue as an "Active_Store". In Pass 2, you perform deeper validation and discover some stores had positive revenue but zero units sold (bad data). You need to back them out of the global count.

```essbase
/* PASS 1 is already complete. The counter "Active_Stores" holds 150. */

/* PASS 2: Deeper Validation */
FIX("FY25", "Working", @LEVEL0("Store"))
    
    /* Check if the store was previously marked active, but failed the units test */
    IF("Active_Flag" == 1 AND "Units_Sold" == 0)
        
        /* Remove the flag */
        "Active_Flag" = 0;
        
        /* Decrement the global counter to correct the over-count */
        VAR vDummy = @CalcMgrCounterDecrement("Active_Stores");
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting custom subtraction | Trying to write `@CalcMgrCounterDecrement("Log", 5)` | This function ONLY subtracts exactly 1. It does not accept a value parameter. If you need to subtract a custom amount (like 5), you must use `@CalcMgrCounterAddNumber("Log", -5)` |
| Syntax execution failures | `@CalcMgrCounterDecrement("Seats");` | In Essbase, you cannot call a function in a vacuum. It must be assigned to an account or a variable. Use `VAR vDummy = @CalcMgrCounterDecrement(...)` |
| Negative underflow | Assuming the counter stops at 0 | This function will happily decrement a counter into negative numbers (`-1`, `-2`, `-3`). If your logic requires a floor of 0, you must write an `IF` statement to check `@CalcMgrCounterGetNumber` before allowing the decrement to occur |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterIncrement`](./@CalcMgrCounterIncrement.md) | The direct opposite (adds exactly 1 to the counter) |
| [`@CalcMgrCounterAddNumber`](./@CalcMgrCounterAddNumber.md) | Used when you need to subtract a number other than 1 (by passing a negative value) |
| [`@CalcMgrCounterDecrementKey`](./@CalcMgrCounterDecrementKey.md) | Subtracts 1 from a specific key inside a complex hash map, rather than a simple global counter |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterdecrement.html)
