# @CalcMgrExcelYEAR

## Overview

`@CalcMgrExcelYEAR` is a **custom Calc Manager date extraction function** in Oracle EPM Cloud (PBCS/EPBCS). It perfectly replicates the behavior of the Microsoft Excel `YEAR` function directly inside an Essbase calculation script. 
It analyzes an Excel Serial Date decimal (or a Java Timestamp) and extracts strictly the **Year component**, returning it as a four-digit integer (e.g., `2024`).

### Why Does This Function Exist—

When time data is imported into EPM from external systems (like HR or ERP databases), it is almost always loaded as a continuous Excel Serial Number (e.g., `45657.0` for Dec 31, 2024) or a native Essbase `YYYYMMDD` integer (`20241231`). 
While extracting the year from a `YYYYMMDD` integer is easy using basic division (`@INT(Date / 10000)`), extracting the year from an Excel Serial Number is impossible using basic math. You cannot divide `45657` by anything to get `2024` because the serial number is a continuous day-counter starting from Jan 1, 1900, complicated by leap years.
`@CalcMgrExcelYEAR` completely resolves this. It taps into the Java calendar engine, reverses the day-count logic, and instantly extracts the exact 4-digit year, ensuring seamless cross-dimensional time mapping.

### When to Use It

- **Dynamic Cross-Dimensional Lookups**: Extracting the year from an employee's `"Hire_Date"` serial number to dynamically push their bonus accrual into the correct `FYXX` member.
- **Age Calculations**: Subtracting an employee's `"Birth_Year"` from the `"Current_Year"` to calculate their age for benefits eligibility.
- Whenever you need to migrate an Excel spreadsheet containing the `YEAR` function directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelYEAR(serial_number)
```

*(Note: The parameter maps 1-to-1 with the Excel function).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serial_number` | Numeric | ✅ Yes | The Excel Serial Date decimal to evaluate (e.g., `45657.0`), or a Java Date Object. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the 4-digit Year as an integer (typically between `1900` and `9999`).
- E.g., `45657` returns `2024`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the serial date decimal.
2. **Calendar Initialization**: It adds the decimal value to Excel's epoch baseline (Jan 1, 1900) and instantiates a highly precise Java Calendar object for that specific date.
3. **Extraction**: It calls the native Java `get(Calendar.YEAR)` method.
4. **Return**: Passes the resulting 4-digit integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Extracting from a Serial Date

```essbase
/* Assumes 45657 is Dec 31, 2024. Returns 2024. */
"Transaction_Year" = @CalcMgrExcelYEAR(45657);
```

### Variant 2: Extracting from Current Server Time

```essbase
/* Returns the current calendar year of the EPM Server (e.g., 2024) */
"Current_System_Year" = @CalcMgrExcelYEAR(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Dynamic Contract Renewal Forecasting

**Scenario**: A corporate revenue model tracks multi-year SaaS contracts. The system stores the `"Contract_Start_Date"` as an Excel Serial Number. The CFO wants to know exactly how much revenue is up for renewal in `"FY28"`. The script must extract the Year from the Start Date, add the contract length, and dynamically push the `"Renewal_Value"` into the correct future Year member.

```essbase
FIX("Working", @LEVEL0("Customer_Contracts"))
    
    IF("Contract_Start_Date" != #MISSING AND "Contract_Length_Years" > 0)
        
        /* 
           1. Extract the 4-digit year from the Excel serial date.
        */
        VAR vStartYear = @CalcMgrExcelYEAR("Contract_Start_Date");
        
        /* 
           2. Calculate the exact Renewal Year integer.
           E.g., 2024 + 4 Years = 2028.
        */
        VAR vRenewalYear = vStartYear + "Contract_Length_Years";
        
        /* 
           3. Map the value into the correct target member using an IF block.
           (In a production script, this is often handled by a custom mapping Macro,
           but standard IF logic is shown here for clarity).
        */
        IF(vRenewalYear == 2025)
            "Renewal_Pipeline"->"FY25" = "Contract_Value";
        ELSEIF(vRenewalYear == 2026)
            "Renewal_Pipeline"->"FY26" = "Contract_Value";
        /* ... continued for future years ... */
        ELSEIF(vRenewalYear == 2028)
            "Renewal_Pipeline"->"FY28" = "Contract_Value";
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Essbase YYYYMMDD Integers | `@CalcMgrExcelYEAR(20241231)` | This function explicitly expects an *Excel* Serial Date decimal. If you pass a native Essbase `YYYYMMDD` integer (like `20241231`), the Java engine thinks you are asking for a date 57,000 years in the future. It will return `57294`. If your data is already in YYYYMMDD format, do NOT use this function. Simply use native math: `@INT("Date" / 10000)` |
| Expecting an FY String | Wanting `"FY24"` | This function strictly returns a numeric integer (`2024`). It does not return strings. If your target members are named `"FY24"`, you cannot use this output directly in cross-dimensional referencing without either an `IF` mapping table or a custom macro that builds the string |
| Negative Inputs | Passing `-100` | Excel dates do not exist before Jan 1, 1900. If you pass a negative serial number, the calendar logic will fail or return `1899`, completely breaking downstream logic |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelMONTH`](./@CalcMgrExcelMONTH.md) | Extracts strictly the Month component (`1-12`) |
| [`@CalcMgrExcelDAY`](./@CalcMgrExcelDAY.md) | Extracts strictly the Day component (`1-31`) |
| [`@CalcMgrExcelToDate`](./@CalcMgrExcelToDate.md) | Converts the entire serial number into a `YYYYMMDD` integer, rather than isolating just the Year |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_excelyear.html)
