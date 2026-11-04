# @HspDateToString

## Overview

`@HspDateToString` is a **Hyperion Planning (HSP) custom conversion function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It takes a **native Essbase Unix Timestamp** (an integer representing seconds since Jan 1, 1970) and mathematically converts it into a highly readable **`YYYYMMDD` formatted integer** (e.g., `20241231`).

*(Important Distinction: Despite having "ToString" in the name, this function returns a numeric **Integer** that looks like `YYYYMMDD`, not a text string. The name is a historical misnomer from early On-Premise Planning versions).*

### Why Does This Function Exist—

There are two major date paradigms in Essbase:
1. **Unix Timestamps**: This is what the native `@TODAY()` function outputs. (e.g., `1715731200`). It is highly efficient for math, but unreadable to humans, and useless in Web Forms.
2. **YYYYMMDD Integers**: This is what EPM administrators actually type into Web Forms (e.g., `20240515`), and what Planning natively prefers for Smart Lists and integer accounts.
If an administrator needs to check if a user-entered `Contract_End_Date` (stored as `YYYYMMDD`) has expired, they must compare it to `@TODAY()`. You cannot write `IF(20240515 < 1715731200)`. The units are fundamentally mismatched. 
`@HspDateToString` serves as the universal translator. By wrapping `@TODAY()` in this function, it instantly transforms the Unix timestamp into a `YYYYMMDD` integer, allowing direct, apples-to-apples comparisons with user-entered data.

*Note: In modern EPM Cloud, this function is still widely used in legacy environments, but modern Java equivalents like `@CalcMgrFormatDate` or `@CalcMgrIntegerToDate` are preferred for true cross-paradigm translations.*

### When to Use It

- **Date Validations**: Comparing a native Unix timestamp against a standard `YYYYMMDD` Web Form input to execute expiration logic.
- **Form Output Standardization**: Converting a native timestamp into `YYYYMMDD` before saving it to an account, ensuring that end-users looking at the Web Form see a readable date (e.g., `20240515`) instead of a massive `1.7B` integer.
- **Reporting Feed Prep**: Preparing data exports where downstream SQL systems expect dates to arrive in a standard 8-digit numerical format.

---

## Category

**Date & Time / Format Conversion / Custom HSP Functions**

---

## Syntax

```essbase
@HspDateToString(date_timestamp)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date_timestamp` | Numeric | ✅ Yes | The native Unix Epoch timestamp integer (e.g., `1715731200` or `@TODAY()`). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an 8-digit integer formatted as `YYYYMMDD`.
- **Not a String**: It does not return text. It returns an actual number (e.g., `20,240,515`). This is why it can be saved directly into standard Essbase Accounts (which only accept numbers).
- **Zero Input**: If you pass `0` (or an empty `#MISSING` block), it evaluates `0` as Jan 1, 1970, and returns `19700101`.

---

## How It Works (Behind the Scenes)

1. **Parameter Evaluation**: The engine locks onto the Unix integer representing seconds since 1970.
2. **Gregorian Translation**: It mathematically divides the seconds to determine the exact Year, Month, and Day.
3. **Integer Construction**: It multiplies the Year by `10000` (e.g., `2024 * 10000 = 20240000`). It multiplies the Month by `100` (`5 * 100 = 500`). It adds them all together with the Day (`20240000 + 500 + 15`).
4. **Return**: It returns the final constructed integer (`20240515`) to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Standardizing Today's Date

```essbase
/* 
   If @TODAY() returns 1715731200 (May 15, 2024).
   @HspDateToString converts it and returns 20240515.
*/
VAR vTodayYYYYMMDD = @HspDateToString(@TODAY());
```

---

## Practical Examples

### Example 1: Comparing Smart List Dates to Today

**Scenario**: A project module requires users to enter a `"Project_Deadline"` via a Smart List or Integer input (formatted as `YYYYMMDD`). A nightly batch script must evaluate all active projects. If the Deadline has passed (is less than Today), it flags the project as "Overdue" and triggers a penalty calculation.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    IF("Project_Deadline" != #MISSING)
        
        /* 
           1. @TODAY returns a massive Unix integer.
           We MUST convert it to YYYYMMDD before comparing it.
        */
        VAR vTodayConverted = @HspDateToString(@TODAY());
        
        /* 
           2. Execute the apples-to-apples comparison.
           e.g., IF (20240515 < 20240601)
        */
        IF("Project_Deadline" < vTodayConverted)
            
            /* The Deadline is older than Today. It is overdue. */
            "Project_Status_Flag" = -1;
            "Late_Penalty_Expense" = 5000;
            
        ELSE
            
            /* The Deadline is in the future. */
            "Project_Status_Flag" = 1;
            "Late_Penalty_Expense" = 0;
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding the Return Type | Expecting a Text String | Despite the name `ToString`, this function strictly returns a **Number**. If you try to concatenate the result with another text string using `@CalcMgrStringsToString`, it will likely fail or require an explicit cast. Do not treat the output as a string; treat it as an 8-digit math integer |
| Double Conversion | Passing a `YYYYMMDD` input into the function | The input MUST be a Unix timestamp. If you pass `20240515` into the function, Essbase assumes it is `20,240,515` seconds since 1970 (which translates to some date in the late 1970s) and returns a completely useless 8-digit integer like `19700822`. Never use this function on data that is already formatted as `YYYYMMDD` |
| Missing `#MISSING` Checks | Executing against empty blocks | Because Essbase treats `#MISSING` as `0`, running this function against an empty account will return `19700101` (Jan 1, 1970). If a user forgot to enter a deadline, and you compare `19700101` to Today, the script will instantly flag it as 50 years overdue and calculate massive penalties. Always wrap date logic in `IF("Account" != #MISSING)` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspDateDiff`](./@HspDateDiff.md) | The companion function used to mathematically calculate the difference between the `YYYYMMDD` integers generated by `HspDateToString` |
| [`@TODAY`](../06_Mathematical/@TODAY.md) | The native function that generates the current Unix timestamp, almost universally used as the input parameter for `HspDateToString` |
| [`@CalcMgrFormatDate`](../11_Date_Time/@CalcMgrGetFormattedDate.md) | The modern Java equivalent that actually DOES return a true text string (e.g., `"2024-05-15"`), rather than just an integer that looks like a date |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspdatetostring.html)
