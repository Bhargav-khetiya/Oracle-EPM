# SET HYBRIDBSOINCALCSCRIPT

## Overview

`SET HYBRIDBSOINCALCSCRIPT` is a **native Essbase system directive** in modern Oracle EPM Cloud (PBCS/EPBCS). It acts as the master toggle switch to determine whether a Calculation Script is allowed to leverage the **Hybrid Aggregation Engine** (which processes sparse Dynamic Calc parent members lightning-fast in memory) or if it must revert to the legacy Block Storage (BSO) engine protocols.

### Why Does This Function Exist?

Historically, Essbase databases were either pure BSO (Block Storage, where data is physically calculated and stored on disk) or pure ASO (Aggregate Storage, where data is calculated dynamically in memory on-the-fly). 
Modern Oracle EPM introduced **Hybrid Essbase**, combining both. You load data into Level-0 BSO blocks, but you tag the Sparse parent members (like `"Total_Region"`) as `Dynamic Calc`. When a user runs a report, Hybrid Essbase aggregates the entire region in RAM instantly, completely eliminating the need for 3-hour nightly batch aggregations.
However, Calculation Scripts are inherently a BSO technology. When a BSO calc script encounters a Hybrid `Dynamic Calc` sparse parent, it traditionally panics and either fails or reverts to extremely slow, non-hybrid BSO math. 
`SET HYBRIDBSOINCALCSCRIPT FULL;` explicitly commands the BSO Calc Script to utilize the high-speed Hybrid ASO engine in the background whenever it encounters a dynamic member. It allows scripts to seamlessly interface with modern Hybrid outlines without crippling performance.

### When to Use It

- **Hybrid Outline Calculations**: ANY time you are writing a Calculation Manager rule in an EPM Cloud application that has Hybrid Essbase enabled (which is virtually all modern applications).
- **Cross-Dimensional Dynamic Queries**: If a Level-0 store needs to calculate its share of the Total Region (`"Store_101" / "Total_Region"`), and the Region is a Hybrid Dynamic Calc, this command ensures the retrieval of the Regional total is instantaneous.
- **Top-Down Allocations in Hybrid**: Forcing the engine to rapidly aggregate dynamic pools in memory before pushing the data down to base-level blocks.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET HYBRIDBSOINCALCSCRIPT NONE | FULL;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `NONE | FULL` | Keyword | ✅ Yes | The explicit mode toggle. <br>- `FULL`: Enables full Hybrid engine resolution for dynamic members encountered inside the script (Fastest, Modern Standard). <br>- `NONE`: Disables the Hybrid engine, forcing the script to use legacy BSO dynamic calculation protocols (Extremely slow, used only for troubleshooting). |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a numeric value. It dictates which internal calculation processor the JVM routes dynamic requests to.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Dependency**: The underlying application *must* have Hybrid Essbase enabled at the server level. If the server is legacy pure BSO, this command has no effect.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET HYBRIDBSOINCALCSCRIPT FULL;`. It enables the Hybrid Router for the script.
2. **Dynamic Request**: The script attempts to evaluate: `VAR vTotalSales = "Total_Region" -> "Sales";`. `"Total_Region"` is a Sparse Dynamic Calc.
3. **Engine Routing**: Because the flag is `FULL`, the BSO script hands the request to the Hybrid ASO processor in RAM.
4. **Resolution**: The Hybrid processor instantly aggregates the 500 Level-0 stores in memory and hands the total (`$5,000,000`) back to the BSO script.
5. **Execution**: The script continues its execution using the instantly retrieved number.

---

## Syntax Variants & Scenarios

### Variant 1: Modern Script Header

```essbase
/* 
   Should be placed at the absolute top of almost every calculation 
   script in a modern Hybrid EPM Cloud application.
*/
SET HYBRIDBSOINCALCSCRIPT FULL;
```

---

## Practical Examples

### Example 1: Allocating a Hybrid Dynamic Pool

**Scenario**: A company does not physically aggregate their Sparse `"Entity"` dimension anymore; it is tagged `Dynamic Calc` for Hybrid. The FP&A admin needs to allocate `"Corporate_Overhead"` down to the Level-0 stores based on their share of `"Total_Company"` Sales. If they don't enable Hybrid in the script, asking for `"Total_Company"` will cause the script to run legacy BSO dynamic math, taking 20 minutes just to find the total. The admin uses the directive to make it instant.

```essbase
/* 
   1. Enable the Hybrid Engine for this script.
*/
SET HYBRIDBSOINCALCSCRIPT FULL;

FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       2. The script asks for "Total_Company" -> "Sales".
       3. The Hybrid Engine intercepts the request, aggregates the entire 
       company in RAM in milliseconds, and returns the denominator.
       4. The BSO script executes the allocation block by block.
    */
    "Allocated_Overhead" = "Corporate_Overhead"->"No_Entity" * ("Sales" / "Total_Company"->"Sales");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Omission in Hybrid Apps | Script Timeouts | If you build a modern Hybrid application (where all sparse parents are Dynamic Calc), and you forget to include `SET HYBRIDBSOINCALCSCRIPT FULL;` at the top of your business rules, those rules will likely time out or crash when they attempt to query parent members. The legacy BSO engine cannot handle massive dynamic sparse hierarchies. This directive is mandatory in modern cloud architecture |
| Expecting it to Aggregate | It doesn't write data | This command allows the script to *read* dynamic members very fast. It does NOT command the script to permanently aggregate and store data. If `"Total_Region"` is Dynamic Calc, it will always be Dynamic Calc. You cannot use `CALC DIM` to physically store data into a Dynamic member, regardless of what this setting is |
| Using `@` Prefix | `@SET HYBRIDBSOINCALCSCRIPT` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash immediately |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| `Dynamic Calc` | The metadata property in the outline that this directive empowers |
| [`SET FRMLRTDYNAMIC`](./SET%20FRMLRTDYNAMIC.md) | A companion setting that tells the script whether to cache the result of the Hybrid dynamic calculation once it is retrieved |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET HYBRIDBSOINCALCSCRIPT](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_hybridbsoincalcscript.html)
