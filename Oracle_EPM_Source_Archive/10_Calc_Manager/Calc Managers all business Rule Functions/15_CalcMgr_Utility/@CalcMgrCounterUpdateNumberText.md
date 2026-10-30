# @CalcMgrCounterUpdateNumberText

## Overview

`@CalcMgrCounterUpdateNumberText` is a **custom Calc Manager map management function** in Oracle EPM Cloud (PBCS/EPBCS). Despite its somewhat confusing name, it serves a highly specific purpose: it directly overwrites the numeric value stored inside a specific "key" (a named sub-bucket) located within a master hash map running in the Java heap memory.

### Why Does This Function Exist?

When dealing with advanced Hash Maps (key-value pairs), you often need to target a specific key. 
If you want to *add* to a key's value, you use `@CalcMgrCounterIncrementKey`.
If you want to *overwrite* a key's value entirely, you need an "Update" function designed specifically for maps. 
The name `@CalcMgrCounterUpdateNumberText` indicates that you are updating a **Number** (the value) associated with a **Text** string (the Key). It allows you to forcefully set the total for `"New_York"` to exactly `500`, regardless of what New York's total was previously, without affecting the totals for `"Texas"` or `"California"` stored in the exact same master map.

### When to Use It

- When maintaining a dynamic Map (Dictionary) in memory where you need to frequently reset or explicitly set the numeric values of specific keys.
- To implement "High-Water Mark" logic across a matrix of different members (e.g., tracking the peak sales for *every* individual product simultaneously).
- When initializing specific keys within a map to a baseline value before running a calculation loop.

---

## Category

**State Tracking / Memory / Map Functions / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrCounterUpdateNumberText("CounterName", "KeyName", newValue)
```

### Formal Syntax

```
@CalcMgrCounterUpdateNumberText("counterNameString", "keyNameString", numericValue)
```

Where:
- `"counterNameString"` — The exact name of the master map/counter bucket.
- `"keyNameString"` — The specific key (sub-bucket) within the map you wish to update.
- `numericValue` — The exact new numeric value to force into that key.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"CounterName"`| String | ✅ Yes | The name of the master map. If it does not exist, it will be created. |
| `"KeyName"` | String | ✅ Yes | The specific key to overwrite. Often generated dynamically using `@NAME(@CURRMBR("Dim"))`. If the key doesn't exist, it is created. |
| `newValue` | Numeric| ✅ Yes | The new number to place into the key. |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the *new total value* of the key (which is simply the `newValue` you just passed to it). 
*(Note: You must assign the result of this function to a temporary dummy account or variable to force Essbase to execute it).*

---

## How It Works (Behind the Scenes)

1. **Map Lookup**: The Java engine checks the active memory heap for a hash map matching the `"CounterName"`. If it doesn't exist, it creates the master map.
2. **Key Lookup**: Once inside the map, it searches for the specific `"KeyName"`.
3. **Replacement**: It completely deletes whatever numeric value was previously stored in that specific key.
4. **Assignment**: It inserts the `newValue` directly into the key. The rest of the keys in the map are untouched.
5. **Return**: It returns the `newValue` back to the Essbase engine.

---

## Syntax Variants & Scenarios

### Variant 1: Hardcoded Key Overwrite

```essbase
/* Forces the value of the 'New_York' key inside the 'Regional_Budgets' map to exactly 0 */
VAR vIgnore = @CalcMgrCounterUpdateNumberText("Regional_Budgets", "New_York", 0);
```

### Variant 2: Dynamic Key Overwrite (Using Current Member)

```essbase
/* Caches the current Product's specific price into the master Pricing Map */
VAR vProdStr = @NAME(@CURRMBR("Product"));
VAR vIgnore = @CalcMgrCounterUpdateNumberText("Pricing_Map", vProdStr, "Unit_Price");
```

---

## Practical Examples

### Example 1: Tracking the Peak Output for 100 Factories Simultaneously

**Scenario**: You have 365 days of data for 100 different factories. You need to find the absolute highest daily production volume for *each* factory. Doing this with 100 separate global counters would be a nightmare. Instead, you use a single Map (`"Peak_Factory_Output"`), where the Key is the Factory Name, and the Value is their peak output.

```essbase
/* Ensure we start with a clean slate */
VAR vInit = @CalcMgrCounterClearAll();

FIX("FY25", "Working", @LEVEL0("Factory"))
    
    /* Extract the current factory name to use as the Key */
    VAR vFactStr = @NAME(@CURRMBR("Factory"));
    
    FIX(@LEVEL0("Time"))
        
        /* 1. Retrieve the current Max Value for this specific factory */
        VAR vCurrentMax = @CalcMgrCounterGetKeyNumber("Peak_Factory_Output", vFactStr);
        
        /* 2. Compare today's output to this factory's historical Max */
        IF("Daily_Production_Units" > vCurrentMax)
            
            /* 3. Today was higher! Overwrite this factory's key with today's value. 
               The other factories in the map are completely unaffected. */
            VAR vDummy = @CalcMgrCounterUpdateNumberText("Peak_Factory_Output", vFactStr, "Daily_Production_Units");
            
        ENDIF
        
    ENDFIX
    
    /* After scanning all 365 days, retrieve the final highest number and stamp it */
    "Peak_Output_Summary" = @CalcMgrCounterGetKeyNumber("Peak_Factory_Output", vFactStr);
    
ENDFIX

/* Cleanup */
VAR vClean = @CalcMgrCounterClear("Peak_Factory_Output");
```

---

### Example 2: Caching Cross-Dimensional Rates

**Scenario**: A script calculates revenue for a matrix of Products and Regions. The Tax Rate varies by Region but applies equally to all Products. To avoid looking up the Tax Rate millions of times in a dense block, you build a map of Tax Rates by Region first, then apply them.

```essbase
/* PASS 1: Build the Tax Rate Map */
FIX("FY25", "Working", @LEVEL0("Region"), "No_Product")
    
    VAR vRegionStr = @NAME(@CURRMBR("Region"));
    
    /* Explicitly cache the Tax Rate into the Map */
    VAR vCache = @CalcMgrCounterUpdateNumberText("Region_Tax_Map", vRegionStr, "Tax_Rate");
    
ENDFIX

/* PASS 2: Execute the massive Product loop */
FIX("FY25", "Working", @LEVEL0("Region"), @LEVEL0("Product"))
    
    VAR vCurrentReg = @NAME(@CURRMBR("Region"));
    
    /* Pull the cached rate from the Map for the current Region */
    "Tax_Expense" = "Revenue" * @CalcMgrCounterGetKeyNumber("Region_Tax_Map", vCurrentReg);
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Name Confusion | Thinking this function updates a Text variable | The name `UpdateNumberText` means "Update the Number associated with this Text Key". The value you pass *must* be a number. The key *must* be a string |
| Additive expectation | Expecting it to sum the values | If the `Texas` key holds `10`, and you pass `5` to this function, the new value is `5`. It overwrites the key completely. If you want to sum values into a key, use `@CalcMgrCounterIncrementKey` or wait for a map addition function |
| Forgetting to use Map Getters | Trying to read the result with `@CalcMgrCounterGetNumber` | This function pushes data into a Map. You cannot read a Map with a simple getter. You must read it back out using `@CalcMgrCounterGetKeyNumber("Map", "Key")` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrCounterUpdateNumber`](./@CalcMgrCounterUpdateNumber.md) | The generic version used for simple, global counters rather than maps |
| [`@CalcMgrCounterGetKeyNumber`](./@CalcMgrCounterGetKeyNumber.md) | The required function to read the data back out of the key after you update it |
| [`@CalcMgrCounterIncrementKey`](./@CalcMgrCounterIncrementKey.md) | Used if you want to add 1 to the key's value rather than overwrite it entirely |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_counterupdatenumbertext.html)
