# @CalcMgrCounterGetKeyText

## Overview

`@CalcMgrCounterGetKeyText` is a **custom Calc Manager memory retrieval function** in Oracle EPM Cloud (PBCS/EPBCS). It retrieves the text string currently stored inside a specific "key" (a named sub-bucket) located within a master hash map running in the background Java heap.

### Why Does This Function Exist—

Advanced calculation scripts often use hash maps (key-value pairs) to track text logs or statuses for multiple different members simultaneously. For example, a map named `"Validation_Logs"` might contain keys for each Region. The key `"North_America"` might hold the string `"Missing_Data, Unbalanced_Entries"`, while the key `"EMEA"` holds an entirely different text string.
While `@CalcMgrCounterAddText` (and its map variants) allows you to push strings *into* these memory locations, `@CalcMgrCounterGetKeyText` is the "Read" operation. It reaches into the master map, locates the specific key you request, extracts the composite text string, and brings it back into the active Essbase script so it can be evaluated, concatenated, or written to a String account/attribute.

### When to Use It

- At the end of a multi-pass calculation script, to retrieve dynamic string logs stored in memory and write them to centralized Text Attributes.
- To execute conditional branching logic based on a string status stored in a map (e.g., checking if the `"EMEA"` key contains the word `"Error"`).
- When passing a map of dynamic strings from an Essbase calculation back into a Groovy script interface.

---

## Category

**State Tracking / Memory / Map Functions / String / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterGetKeyText("CounterName", "KeyName")
```

### Formal Syntax

```
@CalcMgrCounterGetKeyText("counterNameString", "keyNameString")
```

Where:
- `"counterNameString"` — The exact name of the master map/counter bucket.
- `"keyNameString"` — The specific key (sub-bucket) whose string you want to retrieve.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the master counter/map. Must be in double quotes. |
| `"KeyName"` | String | ✅ Yes | The specific key to look up. Often generated dynamically by pulling the current member name via `@NAME(@CURRMBR("Dim"))`. |

---

## Return Value

**Return Type**: String

Returns the literal text string currently stored in the specified key.
- If the master map does not exist, it returns an empty string (`""`).
- If the master map exists but the specific key does not exist inside it, it returns an empty string (`""`).

---

## How It Works (Behind the Scenes)

1. **Map Lookup**: The Java engine searches the active memory heap for a hash map matching the `"CounterName"`.
2. **Key Lookup**: Once inside the map, it searches for the specific `"KeyName"`.
3. **Data Extraction**: It copies the text string stored at that location.
4. **Return**: It passes the string back to the Essbase calculation engine. *Crucially, this is a read-only operation. The text remains inside the map; it is not deleted or cleared by reading it.*

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Key Retrieval

```essbase
/* Reaches into the 'Region_Logs' map and pulls the string log for New York */
VAR vNYLogStr = @CalcMgrCounterGetKeyText("Region_Logs", "New_York");
```

### Variant 2: Dynamic Key Retrieval (Using Current Member)

```essbase
/* Pulls the string log associated with whatever Entity is currently being calculated */
VAR vEntityStr = @NAME(@CURRMBR("Entity"));
VAR vEntityLogStr = @CalcMgrCounterGetKeyText("Entity_Validation_Map", vEntityStr);
```

---

## Practical Examples

### Example 1: Multi-Pass Validation String Collection

**Scenario**: You have a validation script evaluating millions of cells. When it finds errors, it appends the name of the failing account to a Java string map, using the Entity name as the Key. 
In Pass 2, you iterate through the Entities, retrieve their custom error log strings from memory, and push them into a centralized "Exception_Notes" text attribute for users to read on a dashboard.

```essbase
/* PASS 1 is complete. The memory map "Entity_Error_Map" now holds keys for each entity, 
   and the values are comma-separated strings of the accounts that failed. */

/* PASS 2: Stamping the final string logs */
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 1. Extract the current Entity name to use as the lookup Key */
    VAR vEntityStr = @NAME(@CURRMBR("Entity"));
    
    /* 2. Retrieve their specific text log from the master map */
    VAR vErrorLogStr = @CalcMgrCounterGetKeyText("Entity_Error_Map", vEntityStr);
    
    /* 3. If a log exists (i.e., the string is not empty), write it to the attribute */
    IF(vErrorLogStr != "")
        
        /* Note: Writing strings to cells in pure Essbase is notoriously tricky, 
           this is often handled by a Groovy bridge or by pushing to a Smart List index, 
           but conceptually, you'd use a theoretical assignment here. */
           
        /* "Exception_Notes_Str" = vErrorLogStr; */
        
    ENDIF
    
ENDFIX

/* Clean up the massive map from the Java heap */
VAR vCleanup = @CalcMgrCounterClear("Entity_Error_Map");
```

---

### Example 2: Conditional Branching based on a Text Map

**Scenario**: A master job calculates global allocations. The status of each region (e.g., `"Complete"`, `"Failed"`, `"Pending"`) is maintained in a global string map called `"Region_Status"`. As the script hits a new region, it must check the string map to ensure the region's status is not `"Failed"` before proceeding with heavy calculations.

```essbase
FIX("FY25", "Working", @LEVEL0("Region"))
    
    VAR vRegionStr = @NAME(@CURRMBR("Region"));
    VAR vStatusStr = @CalcMgrCounterGetKeyText("Region_Status", vRegionStr);
    
    /* Compare the retrieved string to "Failed" (Ignoring case) */
    IF(NOT @CalcMgrCompare(vStatusStr, "Failed", true))
        
        /* Region is not failed, safe to proceed with calculations */
        "Allocated_Expense" = "Pool" * "Driver";
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using on Numeric Maps | Trying to pull text from a key that holds a numeric total | If the key was populated using a numeric function, trying to extract it as text will likely return an empty string or cause an engine error. Ensure you match your getters and setters (Text goes with Text, Numbers go with Numbers) |
| Case Sensitivity | Searching for `"new_york"` when the key was initialized as `"New_York"` | Keys in Java hash maps are strictly case-sensitive. If the case doesn't match exactly, the engine will assume the key doesn't exist and return an empty string `""` |
| Attempting Math | `IF(@CalcMgrCounterGetKeyText("Map", "Key") > 5)` | This function returns a literal Text String. You cannot use it in greater-than/less-than mathematical evaluations. If you need math, use `@CalcMgrCounterGetKeyNumber` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterGetKeyNumber`](./@CalcMgrCounterGetKeyNumber.md) | The exact equivalent function used for retrieving a *Numeric* total from a map instead of a string |
| [`@CalcMgrCounterGetText`](./@CalcMgrCounterGetText.md) | The generic version used to retrieve the string from a simple, global counter rather than a complex map |
| [`@CalcMgrCompare`](./@CalcMgrCompare.md) | The function typically used immediately after retrieving a string to evaluate its contents |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_countergetkeytext.html)
