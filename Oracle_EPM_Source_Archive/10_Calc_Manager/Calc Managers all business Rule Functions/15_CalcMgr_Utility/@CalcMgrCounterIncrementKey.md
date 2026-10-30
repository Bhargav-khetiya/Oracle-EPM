# @CalcMgrCounterIncrementKey

## Overview

`@CalcMgrCounterIncrementKey` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It adds a value of exactly `1` to a specific "key" (a named sub-bucket) located inside a master hash map running in the background Java heap.

### Why Does This Function Exist?

While `@CalcMgrCounterIncrement` works on simple, single-value global counters (e.g., tracking a single integer for "Global_Errors"), advanced Calc Manager logic frequently relies on **Hash Maps** to track multiple different subtotals simultaneously. 
For example, instead of tracking one massive global error count, you might want to track exactly how many errors occurred in *each* Region. You create a single master map called `"Region_Error_Counts"`. Inside this map, you have dynamic keys for `"Texas"`, `"California"`, and `"New_York"`. 
If you find an error in New York, you must target the specific "New_York" key to tick its count up by 1. `@CalcMgrCounterIncrementKey` provides a semantic, safe shortcut for finding a specific key within a specific map and adding exactly 1 to its total.

### When to Use It

- When utilizing advanced Hash Map logic (key-value pairs) to track multiple independent subtotals (like errors by Region, or inventory counts by Warehouse) simultaneously.
- When generating independent sequential IDs grouped by a specific parent member (e.g., Product 1, Product 2 for Region A; and Product 1, Product 2 for Region B).
- Whenever you are simply "counting" items associated with a specific dimensional member, rather than "summing" raw values.

---

## Category

**State Tracking / Memory / Map Functions / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterIncrementKey("CounterName", "KeyName")
```

### Formal Syntax

```
@CalcMgrCounterIncrementKey("counterNameString", "keyNameString")
```

Where:
- `"counterNameString"` — The exact name of the master map/counter bucket.
- `"keyNameString"` — The specific key (sub-bucket) you wish to increment from within that map.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the master counter/map. Must be in double quotes. |
| `"KeyName"` | String | ✅ Yes | The specific key to increment. If the key does not exist inside the map, the engine initializes it at 0, and then immediately increments it to `1`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the *new total value* of the specific key immediately after `1` is added to it. 
*(Note: You must assign the result of this function to a temporary dummy account or variable to force Essbase to evaluate and execute it).*

---

## How It Works (Behind the Scenes)

1. **Map Lookup**: The Java engine searches the active memory heap for a hash map matching the `"CounterName"`. If it doesn't exist, it creates the master map.
2. **Key Lookup**: Once inside the map, it searches for the specific `"KeyName"`. If the key doesn't exist, it initializes the key with a value of 0.
3. **Addition**: It adds exactly `1` to the value stored in that specific key. The rest of the keys in the map are untouched.
4. **Return**: It returns the new total for that specific key to the Essbase calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Key Increment

```essbase
/* Reaches into the 'Region_Errors' map and adds 1 to the 'New_York' key */
VAR vIgnore = @CalcMgrCounterIncrementKey("Region_Errors", "New_York");
```

### Variant 2: Dynamic Key Increment (Using Current Member)

```essbase
/* Increments the key associated with whatever Entity is currently being calculated */
VAR vEntityStr = @NAME(@CURRMBR("Entity"));
VAR vIgnore = @CalcMgrCounterIncrementKey("Entity_Validation_Map", vEntityStr);
```

---

## Practical Examples

### Example 1: Matrix Error Tracking (Subtotals by Region)

**Scenario**: You have a validation script that runs across thousands of stores. If a store has a negative gross margin, it is an error. Instead of just tracking a global total, you want to track exactly how many errors occurred *per Region*, without writing 50 different `FIX` statements. You can use a dynamic Map to track all 50 Regions simultaneously in a single pass.

```essbase
/* PASS 1: Iterate through all Level 0 Stores */
FIX("FY25", "Working", @LEVEL0("Store"))
    
    IF("Gross_Margin" < 0)
        
        /* 1. Extract the name of the store's parent Region to use as the Key */
        VAR vRegionStr = @NAME(@PARENT("Store"));
        
        /* 2. Increment the specific Region's key inside the master map by exactly 1 */
        VAR vDummy = @CalcMgrCounterIncrementKey("Region_Error_Map", vRegionStr);
        
    ENDIF
    
ENDFIX

/* PASS 2: Retrieve the final subtotals and stamp them at the Region level */
FIX("FY25", "Working", @IDESCENDANTS("Total Region"))
    
    IF(@ISLEV("Region", 1))
        
        VAR vCurrentRegion = @NAME(@CURRMBR("Region"));
        
        /* Pull the final tally for this specific Region from the memory bucket */
        "Total_Validation_Errors" = @CalcMgrCounterGetKeyNumber("Region_Error_Map", vCurrentRegion);
        
    ENDIF
    
ENDFIX

/* Cleanup */
VAR vClear = @CalcMgrCounterClear("Region_Error_Map");
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on simple counters | Trying to pass a key to a bucket created with `@CalcMgrCounterAddNumber` | Simple numeric counters do not have keys. This function is exclusively for complex Maps. If you need to increment a simple global counter, use `@CalcMgrCounterIncrement("Name")` without the key parameter |
| Custom addition amounts | `@CalcMgrCounterIncrementKey("Map", "Key", 5)` | This function ONLY adds exactly 1. It does not accept a value parameter. If you need to add a custom amount to a key, you must use a map-specific generic addition function (if available on your patch level) |
| Case Sensitivity | Searching for `"new_york"` when the key was initialized as `"New_York"` | Keys in Java hash maps are strictly case-sensitive. If you use `@NAME` to dynamically generate keys, ensure you use `@NAME` to dynamically target them later, ensuring exact string casing |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterDecrementKey`](./@CalcMgrCounterDecrementKey.md) | The direct opposite (subtracts exactly 1 from a specific key) |
| [`@CalcMgrCounterIncrement`](./@CalcMgrCounterIncrement.md) | The generic version used for simple, global counters rather than maps |
| [`@CalcMgrCounterGetKeyNumber`](./@CalcMgrCounterGetKeyNumber.md) | Retrieves the final total from the specific key after you are done incrementing it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterincrementkey.html)
