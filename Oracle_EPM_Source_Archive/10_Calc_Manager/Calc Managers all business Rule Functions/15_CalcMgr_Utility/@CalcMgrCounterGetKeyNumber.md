# @CalcMgrCounterGetKeyNumber

## Overview

`@CalcMgrCounterGetKeyNumber` is a **custom Calc Manager memory retrieval function** in Oracle EPM Cloud (PBCS/EPBCS). It retrieves the numeric value currently stored inside a specific "key" (a named sub-bucket) located within a master hash map running in the background Java heap.

### Why Does This Function Exist?

When developers build complex logic, they often use hash maps (key-value pairs) to track subtotals for dozens or hundreds of different members simultaneously. For example, a map named `"Department_Expenses"` might contain keys like `"IT"`, `"HR"`, and `"Finance"`, each holding their own running numeric total.
Functions like `@CalcMgrCounterAddNumber` (which has variants for maps) allow you to put data *into* the map. But eventually, you need to extract that data and stamp it into an Essbase data block so users can report on it. 
`@CalcMgrCounterGetKeyNumber` acts as the "Read" operation. It reaches into the master map, finds the specific key you ask for, and pulls the number out so it can be assigned to an Essbase account.

### When to Use It

- At the end of a multi-pass calculation script, to retrieve dynamic subtotals stored in memory and write them to the database.
- To execute conditional branching logic based on a running total (e.g., checking if the `"IT"` key has exceeded a budget threshold).
- When retrieving a generated Sequence ID for a specific entity out of a centralized mapping table.

---

## Category

**State Tracking / Memory / Map Functions / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterGetKeyNumber("CounterName", "KeyName")
```

### Formal Syntax

```
@CalcMgrCounterGetKeyNumber("counterNameString", "keyNameString")
```

Where:
- `"counterNameString"` — The exact name of the master map/counter bucket.
- `"keyNameString"` — The specific key (sub-bucket) whose value you want to retrieve.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the master counter/map. Must be in double quotes. |
| `"KeyName"` | String | ✅ Yes | The specific key to look up. Often generated dynamically by pulling the current member name via `@NAME(@CURRMBR("Dim"))`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the numeric value currently stored in the specified key.
- If the master map does not exist, it returns `0`.
- If the master map exists but the specific key does not exist inside it, it returns `0`.

---

## How It Works (Behind the Scenes)

1. **Map Lookup**: The Java engine searches the active memory heap for a hash map matching the `"CounterName"`.
2. **Key Lookup**: Once inside the map, it searches for the specific `"KeyName"`.
3. **Data Extraction**: It copies the numeric value stored at that location.
4. **Return**: It passes the number back to the Essbase calculation engine. *Crucially, this is a read-only operation. The data remains inside the map; it is not deleted or cleared by reading it.*

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Key Retrieval

```essbase
/* Reaches into the 'Region_Errors' map and pulls the number of errors for New York */
"NY_Error_Count" = @CalcMgrCounterGetKeyNumber("Region_Errors", "New_York");
```

### Variant 2: Dynamic Key Retrieval (Using Current Member)

```essbase
/* Pulls the value associated with whatever Entity is currently being calculated */
VAR vEntityStr = @NAME(@CURRMBR("Entity"));
"Entity_Total_Errors" = @CalcMgrCounterGetKeyNumber("Entity_Validation_Map", vEntityStr);
```

---

## Practical Examples

### Example 1: Multi-Pass Matrix Subtotaling

**Scenario**: You have an extremely dense transactional model. You need to calculate the total shipping weight for every single customer across thousands of products. Because looping through the sparse product combinations is slow, you use a fast Top-Down pass to dump the weights into a Java memory map, using the Customer Name as the Key. In Pass 2, you simply read the map to stamp the final totals.

```essbase
/* PASS 1 is complete. The memory map "Customer_Weight_Map" now holds thousands of keys, 
   where the Key is the Customer Name, and the Value is their total shipping weight. */

/* PASS 2: Stamping the final results */
FIX("FY25", "Working", @LEVEL0("Customer"))
    
    /* 1. Extract the current Customer name to use as the lookup Key */
    VAR vCustomerStr = @NAME(@CURRMBR("Customer"));
    
    /* 2. Retrieve their specific subtotal from the master map and assign it to an account */
    "Total_Shipping_Weight" = @CalcMgrCounterGetKeyNumber("Customer_Weight_Map", vCustomerStr);
    
ENDFIX

/* Clean up the massive map from the Java heap */
VAR vCleanup = @CalcMgrCounterClear("Customer_Weight_Map");
```

---

### Example 2: Threshold Alerting

**Scenario**: A script tracks the total capital expenditure requested across different departments in a map called `"Dept_CapEx_Requests"`. As you iterate through the approval workflow, you check if a department has exceeded the $1M threshold before allowing a new request to be approved.

```essbase
FIX("FY25", "Working", @LEVEL0("Project"))
    
    VAR vDeptStr = @ATTRIBUTESVAL("Owning_Dept_Text");
    
    IF(vDeptStr != "")
        
        /* Check the running total for this specific department in the memory map */
        IF(@CalcMgrCounterGetKeyNumber("Dept_CapEx_Requests", vDeptStr) > 1000000)
            
            /* Threshold exceeded, flag the new project for manual review */
            "Requires_VP_Approval" = 1;
            
        ELSE
            
            /* Under threshold, auto-approve */
            "Requires_VP_Approval" = 0;
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on simple counters | Trying to pull a key from a bucket created with `@CalcMgrCounterAddNumber` | Simple numeric counters do not have keys. This function is exclusively for complex Maps. To retrieve the total from a simple, global counter, use `@CalcMgrCounterGetNumber("Name")` without the key parameter |
| Case Sensitivity | Searching for `"new_york"` when the key was initialized as `"New_York"` | Keys in Java hash maps are strictly case-sensitive. If the case doesn't match exactly, the engine will assume the key doesn't exist and return `0`. Ensure you use `@NAME` consistently to generate and retrieve keys |
| Expecting `#MISSING` | Assuming an empty key returns `#MISSING` | Java memory maps return `0` for numeric values that don't exist. If you need to differentiate between "The total was exactly 0" and "This key never existed", standard counters cannot help you |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterGetKeyText`](./@CalcMgrCounterGetKeyText.md) | The exact equivalent function used for retrieving a *String* from a map instead of a number |
| [`@CalcMgrCounterGetNumber`](./@CalcMgrCounterGetNumber.md) | The generic version used to retrieve the total from simple, global counters rather than maps |
| [`@CalcMgrCounterClearKey`](./@CalcMgrCounterClearKey.md) | Deletes the key entirely from the map after you are done reading it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_countergetkeynumber.html)
