# @CalcMgrCounterGetNumber

## Overview

`@CalcMgrCounterGetNumber` is a **custom Calc Manager memory retrieval function** in Oracle EPM Cloud (PBCS/EPBCS). It retrieves the current mathematical total stored inside a specific global numeric counter in the background Java heap memory.

### Why Does This Function Exist—

When you use `@CalcMgrCounterAddNumber` to build a running total (e.g., counting validation errors across 100 entities), you are putting data *into* an invisible Java memory bucket. 
Eventually, you must take that total *out* of memory so that you can stamp it into a physical Essbase data block for reporting, or evaluate it in an `IF` statement to determine how the rest of the script should behave. 
`@CalcMgrCounterGetNumber` is the dedicated "Read" operation. It accesses the memory heap, finds the named counter, and returns the total.

### When to Use It

- At the end of a multi-pass calculation script, to retrieve dynamic subtotals stored in memory and write them to a centralized database account (e.g., an Admin or Log entity).
- To execute conditional branching logic based on a running total (e.g., checking if the global error count has exceeded a maximum threshold, triggering an abort sequence).
- When retrieving a globally tracked Sequence ID.

---

## Category

**State Tracking / Memory / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterGetNumber("CounterName")
```

### Formal Syntax

```
@CalcMgrCounterGetNumber("counterNameString")
```

Where:
- `"counterNameString"` — The exact unique name of the memory bucket whose value you wish to retrieve. Must be enclosed in double quotes.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the specific numeric counter you want to read. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the numeric value currently stored in the specified counter.
- If the counter does not exist (perhaps because no data was ever added to it, or it was misspelled), it safely returns `0`.

---

## How It Works (Behind the Scenes)

1. **Lookup**: The Java engine searches the active memory heap for a counter object matching the exact `"CounterName"`.
2. **Data Extraction**: If found, it copies the numeric value currently stored at that location.
3. **Return**: It passes the number back to the Essbase calculation engine. *Crucially, this is a read-only, non-destructive operation. The data remains inside the memory bucket; reading the counter does not reset it to zero. You must use `@CalcMgrCounterClear` to explicitly reset it.*

---

## Syntax Variants & Scenarios

### Variant 1: Stamping a Result to the Database

```essbase
/* Reaches into memory and pulls the total error count, stamping it into an account */
"Global_Total_Errors" = @CalcMgrCounterGetNumber("Error_Count");
```

### Variant 2: Conditional Evaluation

```essbase
/* Checks the current value of the counter without writing it to the database */
IF(@CalcMgrCounterGetNumber("Error_Count") > 50)
    /* Too many errors, trigger an alert flag */
    "Critical_System_Alert" = 1;
ENDIF
```

---

## Practical Examples

### Example 1: The Full Multi-Pass Validation Cycle

**Scenario**: You have a validation script that runs across thousands of cost centers. If a cost center has a negative gross margin, it is an error. You want to count exactly how many errors occurred globally, and stamp that final total number into a centralized "System_Admin" entity so the administrator can see the health of the database.

```essbase
/* PASS 1: Iterate through the entities and build the running total */
FIX("FY25", "Working", @LEVEL0("CostCenter"))
    
    IF("Gross_Margin" < 0)
        /* Add 1 to the global counter */
        VAR vDummy = @CalcMgrCounterAddNumber("Global_Error_Count", 1);
    ENDIF
    
ENDFIX

/* PASS 2: Retrieve the final total and stamp it in the Admin console */
FIX("FY25", "Working", "Admin_CostCenter")
    
    /* READ OPERATION: Pull the final tally from the memory bucket */
    "Total_Database_Errors" = @CalcMgrCounterGetNumber("Global_Error_Count");
    
    /* GOOD HOUSEKEEPING: Clear the counter from memory now that we are done with it */
    VAR vClear = @CalcMgrCounterClear("Global_Error_Count");
    
ENDFIX
```

---

### Example 2: Generating a Sequential ID

**Scenario**: You are generating a list of newly approved projects and writing them to a log. You assign each one a sequential ID (1, 2, 3...) based on the order they were processed during this script run. You need to use the `GetNumber` function to stamp the ID into the project itself.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    IF("Approval_Status" == 1 AND "Assigned_ID" == #MISSING)
        
        /* 1. Increment the sequence counter */
        VAR vDummy = @CalcMgrCounterAddNumber("Project_ID_Sequence", 1);
        
        /* 2. Read the current value of the counter and assign it to the project */
        "Assigned_ID" = @CalcMgrCounterGetNumber("Project_ID_Sequence");
        
    ENDIF
    
ENDFIX

/* Cleanup */
VAR vCleanup = @CalcMgrCounterClear("Project_ID_Sequence");
```
*(Note: You can actually combine these two steps by assigning the output of `AddNumber` directly to the account, but writing it this way is sometimes clearer for junior developers reading the code).*

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting it to clear memory | Assuming `GetNumber` acts like a "Cut" operation | `GetNumber` is a "Copy" operation. It leaves the counter perfectly intact in memory. If you run the script again, it will pick up exactly where it left off. You must explicitly use `@CalcMgrCounterClear` to destroy the counter |
| Typographical Errors | Writing `@CalcMgrCounterGetNumber("error_count")` when the counter was created as `"Error_Count"` | Counter names are strictly case-sensitive. If the case doesn't match exactly, the engine will assume the counter doesn't exist and will return `0` |
| Using it for Maps | Trying to read from a Hash Map | If the counter was built using Map functions (with keys), this function will not work. You must use `@CalcMgrCounterGetKeyNumber` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterAddNumber`](./@CalcMgrCounterAddNumber.md) | The required predecessor function that actually builds the total |
| [`@CalcMgrCounterClear`](./@CalcMgrCounterClear.md) | Must be used after `GetNumber` if you want to ensure the memory is wiped clean |
| [`@CalcMgrCounterGetText`](./@CalcMgrCounterGetText.md) | The equivalent function for pulling text string logs out of memory |
| [`@CalcMgrCounterGetKeyNumber`](./@CalcMgrCounterGetKeyNumber.md) | Used to retrieve totals from specific keys inside complex maps, rather than simple global counters |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_countergetnumber.html)
