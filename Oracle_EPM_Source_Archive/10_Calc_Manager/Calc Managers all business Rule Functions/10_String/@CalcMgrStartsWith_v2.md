# @CalcMgrStartsWith

## Overview

`@CalcMgrStartsWith` is a **custom Calc Manager string validation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a precise prefix scanner. It takes a source text string and returns a Boolean (`true` or `false`) confirming whether the string **begins exactly** with a specified sequence of target characters.

### Why Does This Function Exist?

When building dynamic logic based on account strings, descriptions, or file names, administrators frequently need to group data by its prefix. 
For example, a company might use account names like `"Exp_Travel"`, `"Exp_Meals"`, and `"Rev_Software"`. If a script needs to isolate only the Expense accounts, writing an `IF` statement checking every single account name is impossible. 
While you could use `@CalcMgrIndexOf(Account, "Exp_") == 0` to see if the string starts with the target, it requires an equality operator and is computationally slower. 
`@CalcMgrStartsWith` serves as a dedicated, lightning-fast boolean shortcut. You simply pass it the string and the target prefix (`"Exp_"`). It scans only the front of the string and instantly returns `true` or `false`. This allows you to build highly efficient routing logic based entirely on string naming conventions.

### When to Use It

- **Dynamic Routing**: Checking if a dynamically constructed cross-dimensional member string starts with `"FY"` before attempting to pass it into a Year dimension lookup.
- **Data Load Filtering**: Scanning an imported description field from a flat file and aborting the load if the text starts with `"TEST_"`.
- **Hierarchical Detection**: Evaluating if a full file path string starts with `"//Shared_Drive/Archive/"` to ensure users aren't attempting to read data from secure directories.

---

## Category

**String / Text Manipulation & Validation / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrStartsWith(text, target_prefix, ignore_case)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The full source string to be evaluated (e.g., `"Exp_Travel_NY"`). |
| `target_prefix` | String | ✅ Yes | The specific prefix sequence you are looking for (e.g., `"Exp_"`). |
| `ignore_case` | Boolean | ❌ No  | Optional flag. <br>`true` = Case-insensitive search (e.g., "eXp" matches "Exp"). <br>`false` (Default) = Strictly case-sensitive. |

---

## Return Value

**Return Type**: Boolean (`true` or `false`)

Returns `true` (evaluates to `1` in Essbase IF statements) if the text explicitly begins with the prefix sequence.
Returns `false` (`0`) if it does not.
- **Positional Strictness**: If the text contains the target sequence, but it is NOT at the very beginning (e.g., `"NY_Exp_Travel"`), this function will return `false`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text, the prefix string, and the optional case flag.
2. **Execution**: It executes the native Java `String.startsWith(prefix)` method. 
3. **Array Matching**: Unlike `IndexOf` (which scans the entire string), this function ONLY compares the first `N` characters of the text array against the `N` characters of the prefix array. This makes it exceptionally fast for processing millions of strings.
4. **Return**: Passes the resulting Boolean back to the calculation script.

---

## Syntax Variants & Scenarios

### Variant 1: Case-Insensitive Prefix Check

```essbase
/* Checks if the text starts with "err" (ignoring case). Returns true (1). */
IF(@CalcMgrStartsWith("ERROR_Line_5", "err", true))
    "Status" = -99;
ENDIF
```

---

## Practical Examples

### Example 1: Routing Data Based on Account String Prefixes

**Scenario**: A business rule processes unmapped data from a staging table. The data is stored by generic IDs (e.g., `"Source_ID"`). A text account called `"ID_Description"` contains the human-readable prefix (e.g., `"CapEx_Server_Rack"` or `"OpEx_Software"`). The script must read this prefix to decide whether to push the dollar amount into the Balance Sheet or the Income Statement.

```essbase
FIX("FY25", "Working", @LEVEL0("Unmapped_Data"))
    
    IF("Dollar_Amount" > 0 AND @ISMBR(@LIST("ID_Description")))
        
        /* 
           1. Check if the string explicitly starts with "CapEx_".
           (Using true for case-insensitivity just in case a user typed "capex_")
        */
        VAR vIsCapEx = @CalcMgrStartsWith("ID_Description", "CapEx_", true);
        
        /* 
           2. Check if the string explicitly starts with "OpEx_".
        */
        VAR vIsOpEx = @CalcMgrStartsWith("ID_Description", "OpEx_", true);
        
        /* 
           3. Route the financial data based on the boolean result.
        */
        IF(vIsCapEx)
            "Balance_Sheet_Holding" = "Dollar_Amount";
            "Dollar_Amount" = 0; /* Clear staging */
            
        ELSEIF(vIsOpEx)
            "Income_Statement_Holding" = "Dollar_Amount";
            "Dollar_Amount" = 0; /* Clear staging */
            
        ELSE
            /* String prefix is unrecognized. Do not route. Flag as error. */
            "Mapping_Error_Flag" = 1;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using it for Substrings | Expecting `"Travel_Exp"` to return `true` | This function is strictly positional. It only checks the very first characters (Index `0`). If you want to know if `"Exp"` exists *anywhere* in the string, you must use `@CalcMgrIndexOf(..., "Exp") != -1` instead |
| Passing Numbers | `@CalcMgrStartsWith(10050, "100")` | This function strictly requires a text string. If you pass a numeric Essbase account into it, the Java engine will crash. You must convert numbers to strings first using `@CalcMgrDoubleToString` if you want to perform pattern matching on numerical prefixes |
| Forgetting to use the Boolean Output | `"Target" = @CalcMgrStartsWith(...)` | Because this function returns a Boolean (`true` or `false`), it translates to `1` or `0` in standard Essbase blocks. If you assign the output directly to a target account, you will just overwrite your data with a `1`. Always use this inside an `IF` statement condition block |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrEndsWith`](./@CalcMgrEndsWith.md) | The exact opposite function. It strictly checks if the string *ends* with a specific suffix (e.g., `"v2.csv"`) |
| [`@CalcMgrIndexOf`](./@CalcMgrIndexOf.md) | Checks if a substring exists anywhere in the string, returning its exact integer position |
| [`@CalcMgrMatches`](../15_CalcMgr_Utility/@CalcMgrMatches.md) | Uses Regular Expressions to validate highly complex patterns, rather than a simple literal prefix check |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_startswith.html)
