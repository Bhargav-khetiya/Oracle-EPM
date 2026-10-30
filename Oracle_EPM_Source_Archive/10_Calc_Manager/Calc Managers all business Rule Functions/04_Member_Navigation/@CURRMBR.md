# @CURRMBR

## Overview

`@CURRMBR` is a **native Essbase hierarchical evaluation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an absolute spatial pointer. As the calculation engine loops through millions of data intersections, `@CURRMBR` dynamically queries the engine to ask: "What exact member of this specific dimension are you calculating right now?"

### Why Does This Function Exist?

When writing advanced cross-dimensional formulas or relative allocations, you cannot hardcode member names. 
For example, if you want to copy `"Budget"` data to `"Forecast"`, but ONLY if the current `"Location"` is an American state, you can't write 50 different `IF` statements. You must write one dynamic formula that evaluates the current location block in memory. 
`@CURRMBR` provides this dynamic reflection. By wrapping it inside a relative function (like `@ISANCEST("USA", @CURRMBR("Location"))`), the script checks the *current* member. If the engine is currently calculating `"Texas"`, it evaluates `true` and executes the copy. If it moves to `"London"`, it evaluates `false`. 
It is arguably one of the most critical structural functions in Essbase, serving as the foundational pointer for almost all dynamic array selections (like `@RELATIVE(@CURRMBR("Entity"), 0)`).

### When to Use It

- **Dynamic Allocations**: Finding the exact base-level descendants of *whatever* parent cost center the engine is currently calculating (e.g., `@DESCENDANTS(@CURRMBR("Cost_Center"))`), rather than hardcoding the parent.
- **Cross-Dimensional String Logging**: Passing the name of the current entity being calculated into `@CalcMgrLogMemberStrings` so the Job Console outputs a readable audit trail.
- **Relative Checks**: Verifying if the currently calculating member belongs to a specific shared hierarchy tree or UDA grouping.

---

## Category

**Hierarchy & Outline / Member Attributes & Pointers / Essbase Native Functions**

---

## Syntax

```essbase
@CURRMBR(DimensionName)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DimensionName` | String | ✅ Yes | The exact name of the dimension you want the pointer for (e.g., `"Entity"`, `"Period"`). <br>*Note: This must be the actual Dimension Name, not a member name.* |

---

## Return Value

**Return Type**: Member Object

Returns a strict Member Object pointing to the active intersection.
- **Not a String**: Unlike `@NAME`, this function returns the actual mathematical reference to the member in the outline. You cannot perform text string concatenation directly on `@CURRMBR`. If you need the string name (e.g., `"New_York"`), you must wrap it: `@NAME(@CURRMBR("Entity"))`.
- **Dimensional Lock**: It ONLY returns the member for the dimension you asked for.

---

## How It Works (Behind the Scenes)

1. **Context Awareness**: The Essbase engine spins through a `FIX` statement block by block. Let's assume it is currently processing Block: `[FY25, Working, New_York, Q1]`.
2. **Dimension Query**: The script executes `@CURRMBR("Entity")`.
3. **Pointer Resolution**: The engine queries its internal execution context map. It looks up the active position for the `"Entity"` dimension.
4. **Return**: It instantly returns the member reference `New_York` to the formula, allowing the formula to use `New_York` as an argument for other functions.

---

## Syntax Variants & Scenarios

### Variant 1: Dynamic Relative Selection

```essbase
/* 
   Generates a list of all Level 0 children sitting directly beneath 
   whatever Entity the engine is currently processing.
*/
@RELATIVE(@CURRMBR("Entity"), 0)
```

---

## Practical Examples

### Example 1: Dynamic Top-Down Allocation

**Scenario**: A script is `FIX`ed on 10 different Parent Regions. It needs to allocate the `"Overhead_Expense"` sitting at each Parent Region down to its respective base-level stores. The script cannot hardcode `@RELATIVE("North_America", 0)` because it also needs to calculate `"Europe"`. It uses `@CURRMBR` to dynamically target the descendants of *whichever* region it is currently calculating.

```essbase
FIX("FY25", "Working")
    
    /* 1. Loop through all Parent Regions */
    FIX(@DESCENDANTS("Total_Geography"))
        
        IF(@ISLEV("Entity", 1) AND "Overhead_Expense" > 0)
            
            /* 
               2. The engine is on a Parent (e.g. North_America).
               Use @CURRMBR to dynamically define the target allocation list.
               Essbase translates @RELATIVE(@CURRMBR("Entity"),0) into 
               "Give me all leaf nodes under North_America".
            */
            @ALLOCATE(
                "Overhead_Expense", 
                @RELATIVE(@CURRMBR("Entity"), 0), 
                "Headcount", 
                , 
                share
            );
            
            /* 3. Clear the parent pool */
            "Overhead_Expense" = 0;
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

### Example 2: Dynamic Job Console Logging

**Scenario**: A complex calculation throws a validation error when `"Net_Income" < 0`. To help the administrator debug, the script must log exactly *which* Cost Center failed.

```essbase
FIX(@LEVEL0("Cost_Centers"))
    
    IF("Net_Income" < 0)
        
        /* 
           1. Extract the active Cost Center member.
           2. Wrap it in @NAME to convert the Member Object into a Text String.
        */
        VAR vFailedEntityStr = @NAME(@CURRMBR("Cost_Center"));
        
        /* 
           3. Log it to the console.
        */
        VAR vLog = @CalcMgrLogMemberStrings("Failure detected on Entity: ", vFailedEntityStr);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing a Member Name | `@CURRMBR("New_York")` | This function expects the **Dimension Name**, not the member. The engine doesn't need you to tell it the member; you are asking the engine *for* the member. Write `@CURRMBR("Entity")` |
| Using it in `ISMBR` Redundantly | `IF(@ISMBR(@CURRMBR("Entity")))` | Checking if the current member is the current member is a tautology that always evaluates to true. It is computationally wasteful. `CURRMBR` is meant to be passed into *relative* functions (like `@ANCESTORS` or `@CHILDREN`), not equality checks |
| String Concatenation Failures | `String = "ID_" + @CURRMBR("Entity")` | `@CURRMBR` returns a mathematical Member Object, not a string. You cannot concatenate text with a Member Object. You MUST wrap it in `@NAME()` to cast it to a string first: `@NAME(@CURRMBR("Entity"))` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@NAME`](./@NAME.md) | The mandatory wrapper function used to convert the Member Object returned by `@CURRMBR` into a readable text string |
| [`@RELATIVE`](./@RELATIVE.md) | The most common partner function. `@CURRMBR` is frequently passed into `@RELATIVE` to dynamically select descendants of the active block |
| [`@CURRMBRRANGE`](./@CURRMBRRANGE.md) | A specialized variant that generates a range of members (an array) relative to the current member, heavily used in time-series rolling averages |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — CURRMBR](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/currmbr.html)
