# SET FRMLRTDYNAMIC

## Overview

`SET FRMLRTDYNAMIC` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls how the calculation engine handles formulas that are attached to **Dynamic Calc** members when running a batch calculation script. Specifically, it dictates whether a script should temporarily calculate and store a dynamic value in memory so it can be referenced by other calculations downstream.

### Why Does This Function Exist—

In a standard Essbase outline, members tagged as `Dynamic Calc` do not store physical data on the disk. They are calculated on-the-fly when a user queries them in Smart View. 
However, what happens if your calculation script needs to use a dynamic member as an input for a physical calculation— 
For example, you want to calculate `"Bonus" = "Gross_Profit" * 0.10;`. But `"Gross_Profit"` is a `Dynamic Calc` member (`Revenue - Expenses`). 
By default, when Essbase runs the script and hits that equation, it dynamically calculates `"Gross_Profit"` in memory, uses the result to calculate `"Bonus"`, and writes `"Bonus"` to the disk. 
But if you reference `"Gross_Profit"` 50 times in your script, the engine will run the `Revenue - Expenses` math 50 times, slowing down the script. 
`SET FRMLRTDYNAMIC ON` commands the engine to calculate the Dynamic Calc formula *once*, cache the result in a temporary memory buffer (Runtime Dynamic), and reuse that cached result for the rest of the calculation, drastically improving script performance.

### When to Use It

- **Script Performance Tuning**: Caching heavy, complex `Dynamic Calc` ratios (like YTD averages or currency translation rates) so they don't have to be re-evaluated hundreds of times during a massive allocation loop.
- **Cross-Dimensional Dependencies**: Ensuring that a dynamic member resolves accurately before being passed into an array function like `@MOVAVG` or `@MOVSUMX` inside a calculation script.
- **Formula Referencing**: Safely allowing physical accounts to build formulas based on heavily nested dynamic hierarchies.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET FRMLRTDYNAMIC ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `ON`: Calculates the dynamic formula once, caches it in memory, and reuses it for the remainder of the script execution block. <br>- `OFF`: Default behavior. Dynamically recalculates the formula from scratch every single time it is referenced in the script. |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a numeric value. It modifies the internal memory caching protocol of the C-engine.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Physical Disk**: It does NOT convert the `Dynamic Calc` member into a stored member. It does not write the cached value to the disk. The value is strictly cached in the JVM's volatile memory for the duration of the script execution.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET FRMLRTDYNAMIC ON;`. It activates the temporary formula cache for dynamic members.
2. **First Reference**: The script executes `"Metric_A" = "Gross_Profit" * 5;`. 
3. **Cache Generation**: The engine sees that `"Gross_Profit"` is a `Dynamic Calc`. It calculates `Rev - Exp`, gets `$1,000`. It stores `$1,000` in the temporary memory cache for the current block. It calculates Metric A.
4. **Second Reference**: The script executes `"Metric_B" = "Gross_Profit" * 10;`.
5. **Cache Retrieval**: Instead of recalculating `Rev - Exp`, the engine instantly pulls `$1,000` from the cache. It calculates Metric B.

---

## Syntax Variants & Scenarios

### Variant 1: Activating the Formula Cache

```essbase
/* 
   Placed before a heavily repetitive calculation loop to prevent 
   the engine from constantly recalculating dynamic members.
*/
SET FRMLRTDYNAMIC ON;
```

---

## Practical Examples

### Example 1: Optimizing an Overhead Allocation

**Scenario**: A script allocates `"Corporate_Overhead"` down to 5,000 stores. The allocation driver is `"Net_Margin_%"` (a Dynamic Calc). The script must use this dynamic ratio 3 separate times inside the block (to calculate Tax, Bonus, and Overhead). If run natively, the engine calculates the Margin 15,000 times (5,000 stores x 3). The admin uses `FRMLRTDYNAMIC ON` to cut the calculation overhead by 66%.

```essbase
/* 
   1. We force the engine to cache dynamic calculations in memory.
*/
SET FRMLRTDYNAMIC ON;

FIX("Working", "FY25", @LEVEL0("Stores"))
    
    /* 
       2. First reference: The engine calculates Net_Margin_% from scratch.
       It caches the result in memory for this specific store.
    */
    "Allocated_Overhead" = "Total_Overhead"->"No_Store" * "Net_Margin_%";
    
    /* 
       3. Second reference: The engine instantly pulls the cached ratio.
    */
    "Manager_Bonus" = "Bonus_Pool" * "Net_Margin_%";
    
    /* 
       4. Third reference: The engine instantly pulls the cached ratio.
    */
    "Tax_Reserve" = "Net_Income" * "Net_Margin_%";
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Changing Base Data | Stale Cache | This is the danger of caching. If your script relies on a dynamic member (`"Margin" = "Rev" - "Exp"`), caches it, and then your script *changes* the `"Exp"` data... the cache is now stale. If you reference `"Margin"` again later in the script, it will pull the *old* cached margin, ignoring the fact that you just changed the expenses. If your script alters the base data that feeds a dynamic member, you MUST turn `FRMLRTDYNAMIC OFF` so the engine is forced to recalculate the fresh dynamic value |
| Using `@` Prefix | `@SET FRMLRTDYNAMIC` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash immediately |
| Assuming it Writes to Disk | No Persistent Data | Do not assume this command converts Dynamic members into Stored members. Once the script finishes, the cache is destroyed. If you look at the database through Smart View, the member is still Dynamic Calc and will calculate on-the-fly for the user |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| `Dynamic Calc` | The metadata property in the outline that this directive explicitly manages during script execution |
| [`SET HYBRIDBSOINCALCSCRIPT`](./SET%20HYBRIDBSOINCALCSCRIPT.md) | Another modern engine directive that dictates how dynamic members (specifically in Hybrid mode) are processed during batch calculations |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET FRMLRTDYNAMIC](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_frmlrtdynamic.html)
