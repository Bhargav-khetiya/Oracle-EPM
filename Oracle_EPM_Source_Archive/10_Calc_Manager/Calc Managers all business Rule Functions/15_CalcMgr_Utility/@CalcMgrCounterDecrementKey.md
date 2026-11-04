# @CalcMgrCounterDecrementKey

## Overview

`@CalcMgrCounterDecrementKey` is a **custom Calc Manager state-tracking function** in Oracle EPM Cloud (PBCS/EPBCS). It subtracts a value of exactly `1` from a specific "key" (a named sub-bucket) located inside a master hash map running in the background Java heap.

### Why Does This Function Exist—

While `@CalcMgrCounterDecrement` works on simple, single-value global counters (e.g., a total counter named "Global_Errors"), advanced Calc Manager logic often relies on **Hash Maps** to track multiple different totals simultaneously. 
For example, instead of having 50 separate counters for 50 different states, you have a single master map called `"State_Error_Counts"`. Inside this map, you have keys like `"Texas"`, `"California"`, and `"New_York"`. 
If you find a false positive error in New York and need to remove it from the running total, you must target the specific "New_York" key. `@CalcMgrCounterDecrementKey` provides a semantic shortcut for subtracting exactly 1 from a specific key within a specific map.

### When to Use It

- When utilizing advanced Hash Map logic (key-value pairs) to track multiple independent subtotals inside a Business Rule.
- When a previously counted item associated with a specific dimensional member (like a Product or Entity) is disqualified and needs to be backed out of the map's subtotal.
- To manage available inventory or capacity slots across a matrix of different warehouses simultaneously.

---

## Category

**State Tracking / Memory / Map Functions / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterDecrementKey("CounterName", "KeyName")
```

### Formal Syntax

```
@CalcMgrCounterDecrementKey("counterNameString", "keyNameString")
```

Where:
- `"counterNameString"` — The exact name of the master map/counter bucket.
- `"keyNameString"` — The specific key (sub-bucket) you wish to decrement from within that map.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the master counter/map. Must be in double quotes. |
| `"KeyName"` | String | ✅ Yes | The specific key to decrement. If the key does not exist inside the map, the engine initializes it at 0, and then immediately decrements it to `-1`. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the *new total value* of the specific key immediately after `1` is subtracted from it. 
*(Note: You must assign the result of this function to a temporary dummy account or variable to force Essbase to evaluate and execute it).*

---

## How It Works (Behind the Scenes)

1. **Map Lookup**: The Java engine searches the active memory heap for a hash map matching the `"CounterName"`. If it doesn't exist, it creates the map.
2. **Key Lookup**: Once inside the map, it searches for the specific `"KeyName"`. If the key doesn't exist, it initializes the key with a value of 0.
3. **Subtraction**: It subtracts exactly `1` from the value stored in that specific key. The rest of the keys in the map are untouched.
4. **Return**: It returns the new total for that key to the Essbase calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Key Decrement

```essbase
/* Reaches into the 'Region_Errors' map and removes 1 from the 'New_York' key */
VAR vIgnore = @CalcMgrCounterDecrementKey("Region_Errors", "New_York");
```

### Variant 2: Dynamic Key Decrement (Using Current Member)

```essbase
/* Decrements the key associated with whatever Entity is currently being calculated */
VAR vEntityStr = @NAME(@CURRMBR("Entity"));
VAR vIgnore = @CalcMgrCounterDecrementKey("Entity_Validation_Map", vEntityStr);
```

---

## Practical Examples

### Example 1: Multi-Warehouse Capacity Planning (Dynamic Matrix)

**Scenario**: You are running a script that assigns large incoming shipments to different regional warehouses. Each warehouse is tracked dynamically using a Key in a master map called `"Warehouse_Capacity"`. 
You run a pass that assigns a shipment to a warehouse, but in a subsequent pass, a secondary system check determines that the shipment requires refrigeration, which the assigned warehouse lacks. You must back the shipment out, decrementing the capacity used for that specific warehouse.

```essbase
/* We are currently iterating through the shipments */
FIX("FY25", "Working", @LEVEL0("Shipments"))
    
    /* Check if the shipment was flagged as invalid for its assigned warehouse */
    IF("Refrigeration_Required" == 1 AND "Warehouse_Has_Fridge" == 0)
        
        /* 1. Extract the name of the assigned warehouse as a string to use as the Key */
        VAR vAssignedWhse = @ATTRIBUTESVAL("Assigned_Warehouse_Text");
        
        IF(vAssignedWhse != "")
            
            /* 2. Remove the shipment from the warehouse's capacity total. 
               This decrements the value of that specific key by 1. */
            VAR vDummy = @CalcMgrCounterDecrementKey("Warehouse_Capacity", vAssignedWhse);
            
            /* 3. Flag the shipment to be re-routed */
            "Needs_Rerouting" = 1;
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on simple counters | Trying to pass a key to a bucket created with `@CalcMgrCounterAddNumber` | Simple numeric counters do not have keys. This function is exclusively for complex Maps. If you need to decrement a simple counter, use `@CalcMgrCounterDecrement("Name")` without the key parameter |
| Custom subtraction amounts | `@CalcMgrCounterDecrementKey("Map", "Key", 5)` | This function ONLY subtracts exactly 1. It does not accept a value parameter. If you need to subtract a custom amount from a key, you must use a map-specific addition function with a negative number |
| Case Sensitivity | Searching for `"new_york"` when the key was initialized as `"New_York"` | Keys in Java hash maps are strictly case-sensitive. If you use `@NAME` to dynamically generate keys, ensure you use `@NAME` to dynamically target them later, ensuring exact string casing |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterIncrementKey`](./@CalcMgrCounterIncrementKey.md) | The direct opposite (adds exactly 1 to a specific key) |
| [`@CalcMgrCounterDecrement`](./@CalcMgrCounterDecrement.md) | The generic version used for simple, global counters rather than maps |
| [`@CalcMgrCounterClearKey`](./@CalcMgrCounterClearKey.md) | Completely deletes the key from the map, rather than just subtracting 1 from its value |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterdecrementkey.html)
