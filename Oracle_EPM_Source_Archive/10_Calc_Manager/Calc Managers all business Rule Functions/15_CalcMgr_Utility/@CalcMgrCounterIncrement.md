# @CalcMgrCounterIncrement

## Overview

`@CalcMgrCounterIncrement` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It specifically adds a value of exactly `1` to an existing, named memory counter running in the background Java heap during the execution of a Business Rule.

### Why Does This Function Exist?

When developers track states or occurrences (e.g., keeping a running tally of active projects, or counting validation errors), they typically use `@CalcMgrCounterAddNumber("Count", 1)` to increment the counter.
However, incrementing a counter by exactly 1 is the single most common programmatic operation in all of computer science (equivalent to the `i++` operator in Java/C++). Because of its ubiquity, Calc Manager provides `@CalcMgrCounterIncrement` as a semantic shortcut. 
It makes the calculation script easier to read, explicitly communicating to the next developer that this line of code is simply "ticking a counter up by one", rather than performing arbitrary addition with a variable. It guarantees the increment is exactly 1, reducing the risk of typos where a developer might accidentally write `AddNumber("Count", 10)`.

### When to Use It

- To count the total number of anomalies, validation errors, or exceptions encountered during a script run.
- When generating a sequential ID for a list of items (1, 2, 3...).
- To track the number of loops or passes successfully completed in a complex architecture.
- Whenever you are simply "counting" items rather than "summing" values.

---

## Category

**State Tracking / Memory / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterIncrement("CounterName")
```

### Formal Syntax

```
@CalcMgrCounterIncrement("counterNameString")
```

Where:
- `"counterNameString"` — The unique name of the memory bucket you wish to increment. Must be enclosed in double quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the numeric counter. If the counter does not exist, the engine initializes it at 0, and then immediately increments it to `1`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the *new total value* of the counter immediately after `1` is added to it. 
*(Note: As with most Calc Manager custom functions, you must assign the result of this function to a temporary dummy account or variable to force Essbase to execute it).*

---

## How It Works (Behind the Scenes)

1. **Initialization Check**: The Java engine checks if a numeric counter named `"CounterName"` exists in the active memory heap. If it doesn't, it creates it and sets the baseline to `0`.
2. **Addition**: It adds exactly `1` to the counter's current total.
3. **Persistence**: The updated counter remains in memory until the entire Business Rule finishes executing (or until explicitly cleared), allowing it to be accessed from other `FIX` blocks.
4. **Return**: It returns the new total to the calculation context.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Increment (Counting Errors)

```essbase
/* Adds 1 to the total 'Global_Errors' count */
VAR vIgnore = @CalcMgrCounterIncrement("Global_Errors");
```

---

## Practical Examples

### Example 1: Tracking Total Validation Errors (The Semantic Way)

**Scenario**: You have a validation script that runs across thousands of cost centers. If a cost center has a negative gross margin, it is an error. You want to count exactly how many errors occurred. While you could use `AddNumber("Count", 1)`, using `Increment` is semantically cleaner.

```essbase
/* PASS 1: Iterate through the entities and build the running total */
FIX("FY25", "Working", @LEVEL0("CostCenter"))
    
    IF("Gross_Margin" < 0)
        /* Flag the error locally */
        "Validation_Error_Flag" = 1;
        
        /* TICK the global counter up by 1 */
        VAR vDummy = @CalcMgrCounterIncrement("Global_Error_Count");
    ENDIF
    
ENDFIX

/* PASS 2: Retrieve the final total and stamp it in the Admin console */
FIX("FY25", "Working", "Admin_CostCenter")
    
    /* Pull the final tally from the memory bucket */
    "Total_Database_Errors" = @CalcMgrCounterGetNumber("Global_Error_Count");
    
    /* Good Housekeeping: Clear the counter */
    VAR vClear = @CalcMgrCounterClear("Global_Error_Count");
    
ENDFIX
```

---

### Example 2: Generating a Sequential ID

**Scenario**: You are generating a list of newly approved projects and writing them to a log. You assign each one a sequential ID (1, 2, 3...) based on the order they were processed during this script run. Because `Increment` returns the new total immediately, it is perfect for this.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    /* If the project is approved, but doesn't have an ID yet */
    IF("Approval_Status" == 1 AND "Assigned_ID" == #MISSING)
        
        /* The first time this runs, it initializes at 0, increments to 1, and assigns 1.
           The next time, it increments to 2, and assigns 2. */
        "Assigned_ID" = @CalcMgrCounterIncrement("Project_ID_Sequence");
        
    ENDIF
    
ENDFIX

/* Cleanup */
VAR vCleanup = @CalcMgrCounterClear("Project_ID_Sequence");
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting custom addition | Trying to write `@CalcMgrCounterIncrement("Count", 5)` | This function ONLY adds exactly 1. It does not accept a value parameter. If you need to add a custom amount (like 5), you must use `@CalcMgrCounterAddNumber("Count", 5)` |
| Syntax execution failures | `@CalcMgrCounterIncrement("Seats");` | In Essbase, you cannot call a function in a vacuum. It must be assigned to an account or a variable. Use `VAR vDummy = @CalcMgrCounterIncrement(...)` |
| Forgetting to clear | Running a rule back-to-back | If you run the validation rule twice, the second run will pick up exactly where the first run left off (e.g., starting the count at 50 instead of 0). Always use `@CalcMgrCounterClear` at the start or end of your scripts |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterDecrement`](./@CalcMgrCounterDecrement.md) | The direct opposite (subtracts exactly 1 from the counter) |
| [`@CalcMgrCounterAddNumber`](./@CalcMgrCounterAddNumber.md) | Used when you need to add a number other than 1 (or add dynamic data values instead of simple counting) |
| [`@CalcMgrCounterIncrementKey`](./@CalcMgrCounterIncrementKey.md) | Adds 1 to a specific key inside a complex hash map, rather than a simple global counter |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterincrement.html)
