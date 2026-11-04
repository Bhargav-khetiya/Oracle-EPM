# @CalcMgrExcelTBILLEQ

## Overview

`@CalcMgrExcelTBILLEQ` is a **custom Calc Manager financial math function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `TBILLEQ` function directly inside an Essbase calculation script. 
It calculates the **Bond-Equivalent Yield** for a Treasury Bill (T-Bill).

### Why Does This Function Exist—

Treasury Bills are unique because they are "discounted" securities. They do not pay periodic interest. Instead, they are sold at a discount (e.g., $95) and mature at face value ($100). The quoted rate on a T-Bill is a *bank discount rate*, which is calculated based on a 360-day year. 
However, standard corporate bonds pay interest and quote their yields based on a full 365-day calendar year. If a corporate treasury wants to compare the true return of a T-Bill against the true return of a standard corporate bond, they cannot compare the quoted rates directly. The T-Bill's discount rate must be mathematically converted into a "Bond-Equivalent Yield" (BEY).
Doing this conversion manually in Essbase requires calculating the exact days between settlement and maturity, determining if it crosses a leap year, and running complex algebraic conversions. `@CalcMgrExcelTBILLEQ` offloads this entire conversion to the Java engine, returning the perfectly comparable Bond-Equivalent Yield instantly.

### When to Use It

- **Portfolio Yield Comparisons**: Normalizing the returns of short-term T-Bills so they can be directly compared against standard corporate bonds or commercial paper.
- **Treasury Reporting**: Reporting the true annualized yield (BEY) of the company's cash-sweep investments to the CFO.
- Whenever you need to migrate an Excel spreadsheet containing the `TBILLEQ` function directly into an Essbase calculation.

---

## Category

**Financial / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelTBILLEQ(settlement, maturity, discount)
```

*(Note: The parameters map 1-to-1 with the Excel function).*

---

## Parameters

All date parameters must be passed as `YYYYMMDD` integers, not Java Date objects.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settlement` | Integer | ✅ Yes | The settlement date (`YYYYMMDD`). The date the T-Bill is purchased. |
| `maturity` | Integer | ✅ Yes | The maturity date (`YYYYMMDD`). The date the T-Bill pays out. Must be > `settlement`. Must be within 1 year of settlement. |
| `discount` | Numeric | ✅ Yes | The quoted bank discount rate of the T-Bill (e.g., `0.05` for 5%). |

---

## Return Value

**Return Type**: Numeric (double-precision floating point)

Returns the Bond-Equivalent Yield (BEY) as a decimal.
- This yield will almost always be slightly *higher* than the quoted discount rate due to the 365-day conversion and compounding effects.

---

## How It Works (Behind the Scenes)

1. **Parameter Validation**: The Java engine ensures the dates are valid integers, `discount` > 0, and the maturity is less than 365 days after the settlement. (T-Bills are, by definition, short-term instruments. If the duration exceeds 1 year, the formula fails).
2. **Day-Count Math**: It calculates the exact number of days remaining (`DSM`) between the settlement and maturity dates.
3. **Yield Conversion**: It executes the standard Treasury conversion formula: `(365 * discount) / (360 - (discount * DSM))`.
4. **Return**: Passes the resulting Bond-Equivalent Yield back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Converting a 6-Month T-Bill

```essbase
/* 
   Settlement: Jan 1, 2024
   Maturity: Jun 30, 2024 (181 days remaining)
   Discount: 5% (0.05)
   Result: Calculates the Bond-Equivalent Yield. Returns ~ 0.0519 (5.19%)
*/
"Bond_Equivalent_Yield" = @CalcMgrExcelTBILLEQ(20240101, 20240630, 0.05);
```

---

## Practical Examples

### Example 1: Standardizing Portfolio Dashboards

**Scenario**: A corporate treasury dashboard lists 50 different investments. Half of them are standard corporate bonds, which report a true `"Yield_To_Maturity"`. The other half are Treasury Bills, which only report a `"Bank_Discount_Rate"`. The CFO wants a single metric called `"Standardized_Yield"` to compare them all equally.

```essbase
FIX("FY25", "Working", @LEVEL0("Investments"))
    
    /* Evaluate standard corporate bonds */
    IF(@ISMBR("Corporate_Bonds"))
        
        /* Corporate bonds already use true Yield to Maturity */
        "Standardized_Yield" = "Yield_To_Maturity";
        
    /* Evaluate Treasury Bills */
    ELSEIF(@ISMBR("Treasury_Bills"))
        
        /* T-Bills must be converted from Discount Rate to Bond-Equivalent Yield */
        IF("Maturity_Date" > "Settlement_Date")
            
            "Standardized_Yield" = @CalcMgrExcelTBILLEQ(
                "Settlement_Date", 
                "Maturity_Date", 
                "Bank_Discount_Rate"
            );
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Over 1 Year Maturity | Passing dates 3 years apart | By US Treasury definition, T-Bills have a maturity of 1 year or less (52 weeks). The `TBILLEQ` formula relies on this assumption. If the maturity date is more than 1 year past the settlement date, the function will fail and return `#MISSING` |
| Whole Number Rates | Passing `5` for Discount Rate | The `discount` parameter expects a decimal. If the rate is 5%, you must pass `0.05`. Passing `5` will cause the formula's denominator to become negative, completely destroying the calculation |
| Confusing with TBILLYIELD | Expecting the true yield | `TBILLEQ` calculates the bond-equivalent yield based on the quoted *discount rate*. If you want to calculate the true yield based on the actual *purchase price* you paid in the market, you must use `@CalcMgrExcelTBILLYIELD` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelTBILLYIELD`](./@CalcMgrExcelTBILLYIELD.md) | Calculates the Yield based on the *purchase price* rather than the discount rate |
| [`@CalcMgrExcelTBILLPRICE`](./@CalcMgrExcelTBILLPRICE.md) | Calculates the purchase Price per $100 face value of a T-Bill |
| [`@CalcMgrExcelPRICEDISC`](../12_CalcMgr_Excel_Financial/@CalcMgrExcelPRICEDISC.md) | Calculates the price of a generic discounted security (not strictly bound to the 1-year T-Bill limit) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceltbilleq.html)
