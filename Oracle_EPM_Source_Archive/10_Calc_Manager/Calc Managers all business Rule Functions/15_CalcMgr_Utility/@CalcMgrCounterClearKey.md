# @CalcMgrCounterClearKey

## Overview

`@CalcMgrCounterClearKey` is a **custom Calc Manager memory management function** in Oracle EPM Cloud (PBCS/EPBCS). It targets and deletes a specific "key" (a named sub-bucket) from within a specific named counter (a hash map) in the background Java memory heap.

### Why Does This Function Exist—

Standard Calc Manager counters (`@CalcMgrCounterAddNumber`) are simple buckets: you put a number in, you take the total out.
However, advanced Calc Manager logic allows you to track complex **Hash Maps** (dictionaries of key-value pairs). Instead of having just one global "Error_Count" bucket, you might have a master bucket called "Entity_Errors", and inside that bucket, you have specific "Keys" for each entity (e.g., Key: `New_York`, Value: `5`).
If you need to reset the error count for `New_York` back to zero, but you want to keep the error counts for `Texas` and `California` intact, you cannot use `@CalcMgrCounterClear("Entity_Errors")`—that would destroy the entire master bucket. 
`@CalcMgrCounterClearKey` acts as a surgical laser, allowing you to reach into the master bucket and delete exactly one specific key-value pair, leaving the rest of the map unharmed.

### When to Use It

- When utilizing advanced Hash Map logic (key-value pairs) inside a Business Rule.
- To reset the counter for a specific dimensional member while preserving the running totals for other members in the same global map.
- When iterating through a complex cross-dimensional matrix and freeing up Java heap memory key-by-key as you finish processing them.

---

## Category

**State Tracking / Memory / Map Functions / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterClearKey("CounterName", "KeyName")
```

### Formal Syntax

```
@CalcMgrCounterClearKey("counterNameString", "keyNameString")
```

Where:
- `"counterNameString"` — The exact name of the master map/counter bucket.
- `"keyNameString"` — The specific key (sub-bucket) you wish to delete from within that map.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the master counter/map. Must be in double quotes. |
| `"KeyName"` | String | ✅ Yes | The specific key to delete. Often generated dynamically by pulling the current member name via `@NAME(@CURRMBR("Dim"))`. |

---

## Return Value

**Return Type**: Numeric (0)

Returns `0` upon successfully clearing the specific key. 
*(Note: As with most Calc Manager custom functions, you must assign the result of this function to a temporary dummy account or variable to force Essbase to evaluate and execute it).*

---

## How It Works (Behind the Scenes)

1. **Map Lookup**: The Java engine searches the active memory heap for a hash map matching the `"CounterName"`.
2. **Key Lookup**: Once inside the map, it searches for the specific `"KeyName"`.
3. **Surgical Destruction**: If it finds the key, it deletes the key-value pair from the map. The rest of the map remains completely untouched.
4. **Return**: It returns `0`. If the counter or the key didn't exist, it still safely returns `0`.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Key Deletion

```essbase
/* Reaches into the 'Region_Errors' map and deletes the 'New_York' key */
VAR vClear = @CalcMgrCounterClearKey("Region_Errors", "New_York");
```

### Variant 2: Dynamic Key Deletion (Using Current Member)

```essbase
/* Deletes the key associated with whatever Entity is currently being calculated */
VAR vEntityStr = @NAME(@CURRMBR("Entity"));
VAR vClear = @CalcMgrCounterClearKey("Entity_Validation_Map", vEntityStr);
```

---

## Practical Examples

### Example 1: Multi-Pass Matrix Processing

**Scenario**: You have a complex allocation script. In Pass 1, you build a massive map in memory tracking the "Allocation_Pool" for every single Cost Center. The map name is `"Alloc_Map"`, and the keys are the Cost Center names. 
In Pass 2, you iterate through the Cost Centers to push the data out. Once a Cost Center is fully pushed, you want to delete its key from the map to free up memory (since hash maps can grow extremely large and cause out-of-memory errors on massive cubes).

```essbase
/* PASS 2: Pushing the data */
FIX("FY25", "Working", @LEVEL0("CostCenter"))
    
    /* 1. Get the current cost center name as a string to use as the Key */
    VAR vCostCenterStr = @NAME(@CURRMBR("CostCenter"));
    
    /* 2. Retrieve the mapped value from memory (assuming GetNumber can pull it) */
    "Allocated_Out" = @CalcMgrCounterGetNumber("Alloc_Map", vCostCenterStr);
    
    /* 3. We are done with this Cost Center. Surgically delete its key from the map 
       to free up Java heap memory for the remainder of the loop. */
    VAR vMemFree = @CalcMgrCounterClearKey("Alloc_Map", vCostCenterStr);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it on a standard counter | Running this on a simple `@CalcMgrCounterAddNumber` bucket | Simple counters do not have keys. They are just a single integer value. This function is exclusively for complex Maps (key-value pairs) generated by other advanced functions. To clear a simple counter, use `@CalcMgrCounterClear` |
| Not assigning the function | `@CalcMgrCounterClearKey("Map", "Key");` | You cannot call a function in a vacuum. It must be assigned to a variable: `VAR vDummy = @CalcMgrCounterClearKey(...)` |
| Case Sensitivity | Searching for `"new_york"` when the key was created as `"New_York"` | Keys in Java hash maps are strictly case-sensitive. If you use `@NAME` to dynamically generate keys, ensure you use `@NAME` to dynamically target them later, ensuring the exact same string casing |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterClear`](./@CalcMgrCounterClear.md) | The standard function to delete an entire counter/map entirely |
| [`@CalcMgrCounterClearAll`](./@CalcMgrCounterClearAll.md) | Wipes all counters and maps from memory globally |
| [`@NAME`](./@NAME.md) | Crucial for dynamically passing member names as Keys into these functions |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterclearkey.html)
