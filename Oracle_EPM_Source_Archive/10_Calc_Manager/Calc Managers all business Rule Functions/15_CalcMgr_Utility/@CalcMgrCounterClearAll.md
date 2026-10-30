# @CalcMgrCounterClearAll

## Overview

`@CalcMgrCounterClearAll` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a master reset switch, completely deleting *every single* named memory counter (both text and numeric) from the background Java heap memory for the active execution session.

### Why Does This Function Exist?

While `@CalcMgrCounterClear("SpecificName")` is excellent for surgical precision (e.g., clearing a sub-total counter while leaving a grand-total counter intact), there are times when a Business Rule is so complex that tracking down and clearing every single individual counter name becomes a maintenance nightmare.
If a script utilizes 15 different counters to track various validation states, exception logs, and sequence IDs, missing just one `Clear` statement at the end of the script can cause a memory leak or cause data bleed into a subsequent script run in the same session.
`@CalcMgrCounterClearAll` provides a "scorched earth" initialization approach. It wipes the entire slate clean, guaranteeing that no rogue counters survive to pollute your calculations.

### When to Use It

- **Line 1 of a massive master script**: To absolutely guarantee that the execution environment is pristine before running complex logic.
- **The very last line of a script**: To perform total garbage collection and free up the Java heap memory.
- When you inherit a messy script with dozens of undocumented counters and you want to ensure they are all neutralized.

---

## Category

**State Tracking / Memory / Initialization / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterClearAll()
```

### Formal Syntax

```
@CalcMgrCounterClearAll()
```

*(Note: There are no parameters. It takes no arguments).*

---

## Parameters

**None.** The function operates globally on the active session's memory heap.

---

## Return Value

**Return Type**: Numeric (0)

Returns `0` upon successfully clearing the memory space. 
*(Note: As with most Calc Manager custom functions, you must assign the result of this function to a temporary dummy account or variable to force Essbase to evaluate and execute it).*

---

## How It Works (Behind the Scenes)

1. **Session Lookup**: The Java engine identifies the memory hash map associated with the current script execution session.
2. **Total Destruction**: It nullifies the entire map, instantly destroying all text counters, all numeric counters, and all sequence keys that were actively tracked.
3. **Return**: It returns `0` to the script, indicating the operation is complete.

---

## Syntax Variants & Scenarios

### Variant 1: Master Initialization (At the top of the script)

```essbase
/* Run this before any FIX statements to ensure a completely clean slate */
VAR vInit = @CalcMgrCounterClearAll();
```

---

## Practical Examples

### Example 1: Master Housekeeping in a Multi-Rule Job

**Scenario**: You have a Job that executes Rule 1, Rule 2, and Rule 3 sequentially. Rule 1 tracks 5 different error counters. Rule 2 tracks 10 counters. Rather than writing 15 individual clear statements, you place a `ClearAll` at the top of every rule to ensure they never accidentally inherit data from the previous rule in the Job.

```essbase
/* RULE 2 SCRIPT */

/* 1. SCORCHED EARTH INITIALIZATION */
/* Wipes out any counters lingering from Rule 1 */
VAR vInit = @CalcMgrCounterClearAll();

/* 2. THE LOGIC PASS */
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    IF("Gross_Margin" < 0)
        /* This initializes a brand new, empty counter */
        VAR vDummy = @CalcMgrCounterAddNumber("Rule2_Error_Count", 1);
    ENDIF
    
ENDFIX

/* 3. THE REPORTING PASS */
FIX("FY25", "Working", "System_Admin_Entity")
    "Total_Database_Errors" = @CalcMgrCounterGetNumber("Rule2_Error_Count");
ENDFIX

/* 4. TOTAL CLEANUP */
VAR vCleanup = @CalcMgrCounterClearAll();
```

---

### Example 2: Groovy Iteration Safety

**Scenario**: You are using a Groovy script to iterate through 50 different Regions, submitting a calculation script for each Region dynamically. Because they might run in the same session, you must guarantee that Region 2 doesn't inherit Region 1's validation logs.

```essbase
/* Inside the Essbase calc script deployed by Groovy */

/* Always clear everything first */
VAR vSafeStart = @CalcMgrCounterClearAll();

FIX("FY25", "Working", {RTP_Region})
    /* Perform region-specific logic and counter tracking here */
    /* ... */
ENDFIX

/* Always clear everything when finished */
VAR vSafeEnd = @CalcMgrCounterClearAll();
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it inside a loop | Placing `@CalcMgrCounterClearAll()` inside a dense data loop | If you are tracking a "Grand Total" counter and a "Sub-Total" counter, running `ClearAll` inside the loop will destroy the Grand Total too. If you only want to clear specific counters inside a loop, you must use `@CalcMgrCounterClear("SpecificName")` |
| Not assigning the function | `@CalcMgrCounterClearAll();` | You cannot call a function in a vacuum in Essbase. It must be assigned to a variable or account: `VAR vDummy = @CalcMgrCounterClearAll();` |
| Assuming it clears Essbase data | Thinking this function clears actual data blocks (like `CLEARBLOCK`) | This function *only* clears the invisible Java memory buckets (counters). It does absolutely nothing to the physical data stored in your Essbase cube |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterClear`](./@CalcMgrCounterClear.md) | The surgical version that only clears a single, explicitly named counter |
| [`@CalcMgrCounterClearKey`](./@CalcMgrCounterClearKey.md) | Used to clear specific hash keys (related to map/hash functions rather than simple counters) |
| [`@CalcMgrCounterAddNumber`](./@CalcMgrCounterAddNumber.md) | Creates and adds to a numeric counter (which will be destroyed by this function) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterclearall.html)
