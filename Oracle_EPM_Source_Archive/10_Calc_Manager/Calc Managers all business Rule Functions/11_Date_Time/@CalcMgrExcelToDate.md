# @CalcMgrExcelToDate

## Overview

`@CalcMgrExcelToDate` is a **custom Calc Manager date conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It bridges the gap between Oracle's native `YYYYMMDD` integer date format and the legacy Microsoft Excel Serial Date/Time format. 
It analyzes a massive decimal that Excel uses to track time (e.g., `45657.0`) and securely converts it into an Essbase-friendly integer (e.g., `20241231`) that can be used in native Date-Time math functions or member naming conventions.

### Why Does This Function Exist?

Microsoft Excel tracks time very uniquely: `Day 1` is January 1, 1900. Every single day since then adds `1.0` to the serial number. For example, December 31, 2024 is exactly `45,657` days after Jan 1, 1900, so Excel stores it internally as `45657.0`. 
Essbase does not use this system. Essbase and Calc Manager typically prefer `YYYYMMDD` format (`20241231`) because it is human-readable, chronologically sortable as a pure integer, and easy to parse. 
If an administrator loads raw unformatted Excel data directly into Essbase via a flat file or Smart View integration, all the dates might arrive as meaningless `45657` decimals. 
`@CalcMgrExcelToDate` completely resolves this formatting collision. It takes the incoming Excel decimal, parses the calendar logic in Java, and instantly spits out a clean `YYYYMMDD` integer, ensuring the data is instantly usable by downstream EPM logic.

### When to Use It

- **Data Integration & ETL**: Cleaning up raw Excel data loads where dates arrived as unformatted serial numbers.
- **Member Naming**: Translating Excel dates into valid Essbase member names (e.g., mapping `45657` to the member `"20241231"`).
- Whenever you need to migrate an Excel spreadsheet containing serial date math directly into an Essbase calculation.

---

## Category

**Date & Time / Excel Equivalents / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrExcelToDate(serial_number)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serial_number` | Numeric | ✅ Yes | The Excel Serial Date decimal to evaluate (e.g., `45657.0`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the date formatted as a `YYYYMMDD` integer.
- E.g., `45657.0` returns `20241231`.
- Note: This function entirely ignores the *time* component (the fractional decimals like `.75`). It purely returns the `YYYYMMDD` date. If you need the time preserved, you must use a different conversion path or `@CalcMgrExcelToDateTime` (if available in your specific patch level).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the decimal.
2. **Calendar Offset**: It adds the decimal value to Excel's epoch baseline (January 1, 1900). 
3. **Format Extraction**: It instantiates a Java Calendar object for the exact resulting day. It extracts the Year, Month, and Day.
4. **Integer Construction**: It mathematically constructs the integer: `(Year * 10000) + (Month * 100) + Day`.
5. **Return**: Passes the resulting `YYYYMMDD` integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Parsing Raw Excel Load Data

```essbase
/* Assume 'Raw_Excel_Date' contains 45657. Returns 20241231. */
"Cleaned_Essbase_Date" = @CalcMgrExcelToDate("Raw_Excel_Date");
```

---

## Practical Examples

### Example 1: Creating a Valid Date Key for Cross-Dimensional Mapping

**Scenario**: A company loads daily sales logs from an external POS system via an automated Excel dump. The date arrives as a serial number in the `"Transaction_Date_Raw"` account (e.g., `45657`). To push this data into the correct Time dimension member (e.g., `"Jan_01_2024"`), the script must convert the serial number into a `YYYYMMDD` integer, and then use native substring logic to map it.

```essbase
FIX("FY25", "Working", "Sales_Transactions")
    
    IF("Transaction_Date_Raw" != #MISSING)
        
        /* 
           1. Convert the Excel Serial Number into YYYYMMDD.
           e.g., 45657 becomes 20241231.
        */
        "Clean_Date_Integer" = @CalcMgrExcelToDate("Transaction_Date_Raw");
        
        /* 
           2. Extract the Month and Day using native modulo/division.
        */
        VAR vMonth = @INT(( "Clean_Date_Integer" - (@INT("Clean_Date_Integer"/10000) * 10000) ) / 100);
        
        /* 3. Execute downstream mapping logic... */
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Essbase Dates | `@CalcMgrExcelToDate(20241231)` | This function explicitly expects an *Excel* Serial Date decimal. If you pass a native Essbase `YYYYMMDD` integer (like `20241231`), the Java engine thinks you are asking for 20 million days after Jan 1, 1900. It will calculate a date in the year 57,000 AD, returning a completely useless integer |
| Expecting Time Data | Complaining the output dropped the time | `ToDate` strictly constructs a `YYYYMMDD` integer. It intentionally truncates the fractional decimal that represents time. If you pass `45657.75` (6:00 PM), it will still return `20241231` |
| Negative Inputs | Passing `-100` | Excel dates do not exist before Jan 1, 1900. If you pass a negative serial number, the function will likely fail or return `#MISSING` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrExcelDATE`](./@CalcMgrExcelDATE.md) | The inverse logic: Creates an Excel Serial Date decimal from individual Year, Month, and Day integers |
| [`@CalcMgrExcelDAY`](./@CalcMgrExcelDAY.md) | Extracts strictly the Day (`1-31`) from an Excel Serial Date decimal |
| [`@CalcMgrExcelYEAR`](./@CalcMgrExcelYEAR.md) | Extracts strictly the Year (`1900-9999`) from an Excel Serial Date decimal |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_exceltodate.html)
