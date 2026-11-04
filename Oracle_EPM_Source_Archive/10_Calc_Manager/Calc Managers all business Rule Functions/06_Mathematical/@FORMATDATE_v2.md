# @FORMATDATE

## Overview

`@FORMATDATE` is a **native Essbase string formatting function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a **native Essbase Date Integer** (a Unix epoch timestamp representing seconds since Jan 1, 1970) and converts it into a human-readable **Date String** (like `"12/31/2024"`) based on a specified formatting mask.

### Why Does This Function Exist—

Essbase mathematical functions and standard accounts rely heavily on Unix timestamp integers (e.g., `1715731200`) because numbers are computationally efficient and easy to add/subtract. However, when EPM administrators need to export this data to a flat file for a downstream system (like an HRIS or ERP), or when they need to log a date into the Job Console for an audit trail, the Unix integer is completely unreadable to humans.
`@FORMATDATE` bridges this gap natively. By passing the Unix timestamp and a format mask (e.g., `"mm/dd/yyyy"`), Essbase natively unpacks the seconds, translates them into the Gregorian calendar, and constructs a formatted text string that can be used in `@CalcMgrLogMemberStrings` or exported directly.

*Note: In modern PBCS/EPBCS environments, `@CalcMgrFormatDate` is generally preferred because it integrates seamlessly with Java Date Objects and `YYYYMMDD` integers. `@FORMATDATE` is considered legacy native functionality, strictly reserved for converting raw Unix timestamp accounts into text.*

### When to Use It

- **Job Console Logging**: Converting a project's `"Start_Date"` (stored as a Unix timestamp) into `"01-15-2024"` so it can be printed in a readable validation error log.
- **Custom Exports**: Formatting dates inside a `DATAEXPORT` block so the resulting CSV file contains human-readable dates for an external SQL database.
- **String Concatenation**: Appending the current date (via `@TODAY()`) to a unique identifier string (e.g., `"PROJ_Alpha_202412"`) for dynamic member creation or tagging.

---

## Category

**Date & Time / Native Essbase Date Math / Essbase Native Functions**

---

## Syntax

```essbase
@FORMATDATE(date, "format_string")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | Numeric | ✅ Yes | The Unix Epoch timestamp integer you want to format (e.g., `1715731200` or `@TODAY()`). |
| `"format_string"` | String | ✅ Yes | The layout mask defining how the date should look. **Must be enclosed in double quotes**. (e.g., `"mm/dd/yyyy"`, `"yyyy-mm-dd"`). |

---

## Format String Mask Rules

- `yyyy` or `yy`: Year (e.g., `2024` or `24`)
- `mm` or `m`: Month (e.g., `05` or `5`)
- `dd` or `d`: Day (e.g., `09` or `9`)
- Separators: You can use slashes (`/`), hyphens (`-`), or spaces (` `) between the masks.

---

## Return Value

**Return Type**: String

Returns a text string formatted exactly to the specifications of the mask.
- **Storage Constraints**: Because Essbase data blocks (Accounts) can *only* store numeric data, you CANNOT write the output of this function into an account (`"Date_String_Acct" = @FORMATDATE(...)` will fail or write `#MISSING`). The output MUST be consumed by another string-processing function (like a logger or an export).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: Essbase evaluates the Unix integer (seconds since 1970).
2. **Calendar Conversion**: It mathematically dissects the seconds into a Gregorian Year, Month, and Day in memory.
3. **Mask Parsing**: It reads the `"format_string"` from left to right, substituting the memory values into the mask blocks (e.g., replacing `yyyy` with `2024`).
4. **String Construction**: It concatenates the pieces and separators into a single text string.
5. **Return**: It returns the constructed string to the calculation block, passing it to the encapsulating function.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Date Formatting

```essbase
/* 
   Assumes vTimestamp represents May 15, 2024.
   Result is the string: "05/15/2024"
*/
VAR vDateStr = @FORMATDATE(vTimestamp, "mm/dd/yyyy");
```

---

## Practical Examples

### Example 1: Readable Audit Logging

**Scenario**: A compliance script checks if any `"Project_End_Date"` falls before the `"Project_Start_Date"`. If it does, it must write a highly readable error to the Job Console. The dates are stored as Unix timestamps, which are useless to the auditors reading the log. The script must convert them to text.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    IF("Project_End_Date" != #MISSING AND "Project_End_Date" < "Project_Start_Date")
        
        /* 
           1. Format the Unix timestamps into readable strings. 
           (e.g., "12/31/2024")
        */
        VAR vStartStr = @FORMATDATE("Project_Start_Date", "mm/dd/yyyy");
        VAR vEndStr = @FORMATDATE("Project_End_Date", "mm/dd/yyyy");
        
        /* 
           2. Retrieve the Project Name.
        */
        VAR vProjectName = @NAME(@CURRMBR("Projects"));
        
        /* 
           3. Log the human-readable error to the console.
        */
        VAR vLog1 = @CalcMgrLogMemberStrings("ERROR: Invalid Dates on Project -> ", vProjectName);
        VAR vLog2 = @CalcMgrLogMemberStrings("Start Date: ", vStartStr);
        VAR vLog3 = @CalcMgrLogMemberStrings("End Date: ", vEndStr);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Save to an Account | `"Formatted_Date" = @FORMATDATE(...)` | **Essbase Data Cells CANNOT store text strings.** They only store numbers. If you try to assign the string `"12/31/2024"` to a standard member, the block will reject it, usually writing `#MISSING` or throwing a compilation error. Strings must be kept in `VAR` memory arrays, exported, or logged |
| Passing YYYYMMDD Integers | `@FORMATDATE(20240515, "mm/dd/yyyy")` | This function DOES NOT understand `YYYYMMDD`. It assumes the input is Unix seconds. If you pass `20240515`, it will output a date string from the year 1970. If your data is `YYYYMMDD`, you MUST use `@CalcMgrFormatDate` or `@CalcMgrIntegerToString` instead |
| Using the Wrong Case in the Mask | `"MM/DD/YYYY"` | Historically, the native Essbase C-engine is extremely sensitive to mask casing. While some modern cloud patches forgive this, it is safest to strictly use lowercase `mm/dd/yyyy` to avoid compilation warnings |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrFormatDate`](../11_Date_Time/@CalcMgrGetFormattedDate.md) | The modern Java equivalent. Vastly superior, as it can accept actual Java Date Objects and output highly complex string layouts (including hours/minutes) |
| [`@TODAY`](./@TODAY.md) | The native Essbase function that generates the current Unix timestamp, frequently used as the input for `@FORMATDATE` |
| [`@DATEPART`](./@DATEPART.md) | The companion native function used to mathematically extract an integer (like the Year) from a timestamp, rather than converting it into a string |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — FORMATDATE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/formatdate.html)
