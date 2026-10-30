# @COMPOUND

## Overview

`@COMPOUND` is a **native Essbase financial function** in Oracle EPM Cloud (PBCS/EPBCS). It calculates the **Compound Interest** (or compounded value) of a principal amount over a specified period of time, based on a defined interest rate. It returns the total accumulated value (Principal + Interest) across a range of periods.

### Why Does This Function Exist?

Calculating simple interest (`Principal * Rate`) is easy. Calculating compound interest (where the interest earned in Period 1 earns its own interest in Period 2) is mathematically complex to write in a standard calculation script. 
If a company deposits `$1,000,000` into a treasury account earning `5%` annually, the balance at the end of Year 5 requires an exponential formula: $A = P(1 + r)^t$. 
Writing this manually in Essbase requires complex `@POWER` functions or manual cell-by-cell rolling logic (`@CALCMODE(CELL)`). `@COMPOUND` automates this entire process. You simply pass it the Principal amount, the Interest Rate, and the range of time periods, and Essbase dynamically calculates the compounded growth curve, instantly returning the accumulated value for each respective period.

### When to Use It

- **Treasury Planning**: Calculating the future value of a long-term cash deposit or bond investment over a 5-year strategic plan.
- **Debt Modeling**: Projecting the compounding growth of unpaid accrued interest on a corporate loan.
- **Inflation Modeling**: Calculating the compounded impact of a `3%` annual inflation rate on raw material costs over time.

---

## Category

**Financial & Mathematical / Interest & Growth / Essbase Native Functions**

---

## Syntax

```essbase
@COMPOUND(Principal, Rate, [XrangeList])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Principal` | Numeric / Member | ✅ Yes | The initial starting amount (e.g., `1000000` or `"Initial_Deposit"`). |
| `Rate` | Numeric / Member | ✅ Yes | The interest rate per period, expressed as a decimal (e.g., `0.05` for 5%). |
| `XrangeList` | Member Range | ❌ No  | The specific time periods over which to compound. <br>If omitted, Essbase defaults to calculating across the `Time` dimension members in the current `FIX` statement. |

---

## Return Value

**Return Type**: Numeric (Block Vector)

Returns the compounded total value (Principal + Accumulated Interest) for each period in the range.
- **Cumulative Output**: The function outputs an array of results. E.g., for `Jan, Feb, Mar`, it returns the balance at the end of Jan, the balance at the end of Feb, and the balance at the end of Mar.
- **Missing Data**: If the Principal is `#MISSING`, it evaluates as `0`, resulting in a `$0` return.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: Essbase locks onto the `Principal` value and the `Rate`.
2. **Time Series Traversal**: It identifies the `XrangeList` (e.g., `Jan:Dec`).
3. **Period 1 Calculation**: It calculates the value for the first period: $Principal \times (1 + Rate)$.
4. **Compounding Loop**: For Period 2, it takes the result of Period 1 and multiplies it by $(1 + Rate)$. It repeats this iteration for every member in the range list.
5. **Data Write**: It returns the calculated array of values into the target member block.

---

## Syntax Variants & Scenarios

### Variant 1: Fixed Rate Compounding (Default Time Range)

```essbase
/* 
   Compounds a $10,000 principal at a fixed 5% rate 
   across whatever Time periods are currently in the FIX.
*/
"Future_Value" = @COMPOUND(10000, 0.05);
```

---

## Practical Examples

### Example 1: Calculating Long-Term Treasury Growth

**Scenario**: A corporate treasury department places `$5,000,000` into a high-yield savings vehicle that pays `4%` annually. The financial plan spans 5 years (`FY24:FY28`). The script must calculate the compounded future value of that asset at the end of each year.

```essbase
FIX("Working", "Treasury_Dept", "No_Product")
    
    /* 
       1. Calculate the compounded growth.
       - Principal: 5,000,000 (Hardcoded or pulled from an account)
       - Rate: 0.04 (4% Annual)
       - Range: FY24 to FY28
    */
    "Compounded_Asset_Value" = @COMPOUND(5000000, 0.04, "FY24":"FY28");
    
    /*
       Results:
       FY24 = $5,200,000
       FY25 = $5,408,000
       FY26 = $5,624,320
       ...
    */
    
ENDFIX
```

### Example 2: Dynamic Inflation Adjustments

**Scenario**: The cost of raw steel is projected to be `$100` per unit in Jan. The FP&A team assumes a monthly inflation rate of `0.5%` (`0.005`). The script must compound the unit cost across the 12 months of the year, storing the inflated cost in each month.

```essbase
FIX("FY25", "Working", "Steel_Materials")
    
    /* 
       1. Base Cost is stored in "Base_Unit_Cost".
       2. Inflation Rate is stored in "Monthly_Inflation_Pct".
       3. We omit XrangeList, so it defaults to Jan:Dec (assuming a Time FIX).
    */
    FIX(@CHILDREN("YearTotal"))
        
        "Inflated_Unit_Cost" = @COMPOUND("Base_Unit_Cost"->"BegBalance", "Monthly_Inflation_Pct");
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Rate vs Percentage | Passing `5` instead of `0.05` | Essbase mathematical functions expect rates to be expressed as pure decimals. If you pass `5` for 5%, Essbase interprets that as `500%`, and your compounded value will explode into trillions of dollars immediately. Always divide whole percentages by 100 before passing them to the function |
| Mismatched Time Horizons | Applying a 5% Annual rate across Monthly periods | The `Rate` must match the frequency of the `XrangeList`. If your range is `Jan:Dec`, and you pass `0.05` (5% annual), Essbase will compound it by 5% *every single month*. If the range is months, you must divide the annual rate by 12: `@COMPOUND(Principal, (Rate/12), "Jan":"Dec")` |
| Misunderstanding Principal Reset | Passing a dynamic Principal | The `Principal` argument is evaluated ONCE at the start of the calculation. If you pass an account (`"Deposit"`) that has data in Jan, Feb, and Mar, Essbase generally only looks at the first period's value to start the compounding chain. If you are adding *new* deposits every month, `@COMPOUND` cannot handle it. You must use manual cell-based rolling logic for complex multi-deposit schedules |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@COMPOUNDGROWTH`](../06_Mathematical/@COMPOUNDGROWTH.md) | Calculates the pure *Growth* amount (the Interest only), rather than the total Accumulated Value (Principal + Interest) |
| [`@INTEREST`](./@INTEREST.md) | Calculates the interest paid on a declining balance loan, rather than the compounding interest on a growing asset |
| [`@POWER`](../06_Mathematical/@POWER.md) | The mathematical function `(x^y)` used if you want to manually write compounding formulas yourself |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — COMPOUND](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/compound.html)
