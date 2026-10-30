# @MIN

## Overview

`@MIN` is a **native Essbase mathematical array function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specified range (array) of members and returns the **absolute lowest single numeric value** found across that entire dataset.

### Why Does This Function Exist?

In corporate finance, supply chain modeling, and risk analysis, identifying the lowest point in a dataset is just as critical as finding the peak. An administrator might need to find the absolute lowest cash balance achieved during the year to determine if the company requires a short-term revolver loan, or they might need to identify the lowest-performing store in a region to flag it for management review.
Without this function, you would be forced to write an infinitely complex nested `IF` structure: `IF(Jan < Feb AND Jan < Mar...)`. This is unmaintainable.
`@MIN` handles this natively. By passing an array of dimension members (e.g., `"Jan":"Dec"` or `@CHILDREN("Products")`), the C-engine rapidly sweeps all the specified blocks in memory, compares their values internally, and isolates the absolute minimum number, drastically simplifying script logic.

### When to Use It

- **Liquidity Analysis**: Finding the lowest cash balance across a rolling 12-month forecast to ensure the company does not breach its debt covenants.
- **Inventory Floors**: Identifying the minimum inventory level reached during the quarter to calculate "Safety Stock" replenishment requirements.
- **Pricing Optimization**: Scanning a list of historical vendor quotes (`@CHILDREN("Vendor_Quotes")`) and extracting the absolute lowest price to set the baseline budget.

---

## Category

**Mathematical / Array Aggregation / Essbase Native Functions**

---

## Syntax

```essbase
@MIN(SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH, MemberRange)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Skip_Flag` | Keyword | ❌ No  | Determines how empty blocks or zero values are handled during the comparison:<br>- `SKIPNONE`: Evaluates everything (default).<br>- `SKIPMISSING`: Ignores `#MISSING` blocks.<br>- `SKIPZERO`: Ignores blocks containing exactly `0`.<br>- `SKIPBOTH`: Ignores both `#MISSING` and `0`. |
| `MemberRange` | Member List | ✅ Yes | The array of members to evaluate. Can be a time range (`"Jan":"Dec"`), a hierarchy function (`@DESCENDANTS("USA")`), or a cross-dimensional tuple. |

*(Note: If the `Skip_Flag` is omitted, the function defaults to `SKIPNONE`).*

---

## Return Value

**Return Type**: Numeric (Double)

Returns the absolute lowest numeric value found within the evaluated range.
- **Negative Numbers**: The function respects absolute math. If the range contains `[-50, -20, 10]`, the minimum is `-50`.
- **Missing Data Handling**: If the range is entirely `#MISSING` and you use `SKIPMISSING`, it returns `#MISSING`. If you use `SKIPNONE`, `#MISSING` is mathematically evaluated as `0`. If your range contains `[50, 20, #MISSING]`, the minimum is `0` (the missing block).

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The engine parses the `MemberRange` into a contiguous array of memory blocks.
2. **Flag Enforcement**: It applies the `Skip_Flag`. If `SKIPMISSING` is set, it drops any empty blocks from the comparison array.
3. **Sequential Sweep**: It initializes an internal tracking variable with the highest possible double-precision number. It then sweeps through the array. 
4. **Comparison**: For each block, if the value is *less* than the tracking variable, the tracking variable is updated.
5. **Return**: Once the sweep finishes, it returns the final, lowest value of the tracking variable to the calculation engine.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Minimum Cash Balance

```essbase
/* 
   Finds the lowest cash position between Jan and Dec.
   SKIPMISSING ensures future, unforecasted months don't force a $0 result.
*/
"Lowest_Cash_Balance" = @MIN(SKIPMISSING, "Jan":"Dec");
```

---

## Practical Examples

### Example 1: Calculating Minimum Vendor Pricing

**Scenario**: A manufacturing company gathers quotes from 5 different suppliers for a specific raw material. The quotes are stored in `"Vendor_A"` through `"Vendor_E"` (which roll up to `"Total_Vendors"`). The supply chain team needs a script that automatically finds the lowest valid quote and writes it into the `"Approved_Budget_Price"` account. However, not all vendors bid on every material. If a vendor didn't bid, their quote is `#MISSING` or `0`. The script must use `SKIPBOTH` to ensure those non-bids aren't accidentally selected as the lowest price.

```essbase
FIX("FY25", "Working", @LEVEL0("Raw_Materials"))
    
    /* 
       1. We evaluate the 5 vendor children.
       2. We MUST use SKIPBOTH. If Vendor C didn't bid (Missing or 0), 
       a standard @MIN would see 0 as the lowest price, and budget $0 
       for the material, completely breaking the model.
    */
    "Approved_Budget_Price" = @MIN(SKIPBOTH, @CHILDREN("Total_Vendors"));
    
    /* 
       Results:
       Vendor_A = $15, Vendor_B = $12, Vendor_C = 0, Vendor_D = $14, Vendor_E = Missing.
       The function ignores C and E.
       It evaluates 15, 12, 14.
       The minimum is $12.
    */
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| `SKIPNONE` with Positive Numbers | `#MISSING` is Zero | This is the most catastrophic mistake when using `@MIN`. If your data is `[100, 200, 300]`, and Q4 is `#MISSING`, `SKIPNONE` treats `#MISSING` as `0`. Because $0$ is less than $100$, the function returns `0`. **You must almost always use `SKIPMISSING` or `SKIPBOTH` with `@MIN` to prevent empty blocks from destroying your minimums.** |
| Forgetting `@LIST` for Non-Contiguous Ranges | `@MIN("Jan", "Mar")` | Like `@MAX` and `@AVG`, `@MIN` expects a SINGLE range argument. If you try to pass two distinct, unconnected members separated by a comma, the compiler will crash. You MUST wrap them in `@LIST("Jan", "Mar")` so they are fused into a single array before `@MIN` evaluates them |
| Assuming it Returns the Member | `@MIN` returns the Number | This function returns the numeric *value* (e.g., `$12`). It does NOT return the *name* of the vendor that provided the quote. If you need to write `"Vendor_B"` to a text field, this function cannot do that natively. You would need a custom Java CDF or a complex secondary `IF` loop to trace the value back to its owner |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MAX`](./@MAX.md) | The exact opposite. Sweeps the array and returns the absolute highest numeric value |
| [`@MINS`](./@MINS.md) | A legacy variant that evaluates members sequentially based on their outline order, stopping evaluation if an internal condition is met (rarely used in modern scripts) |
| [`@MINSRANGE`](./@MINSRANGE.md) | A variant that accepts a numeric list (like `[10, 20, 30]`) directly rather than an outline member range |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — MIN](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/min.html)
