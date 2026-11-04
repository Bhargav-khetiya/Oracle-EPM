# @LIKE

## Overview

`@LIKE` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a powerful string-pattern matching engine, allowing administrators to dynamically select an array of dimension members based entirely on wildcard text patterns within their member names or aliases, rather than their physical outline hierarchy.

### Why Does This Function Exist—

In legacy systems or poorly designed outlines, member names often contain embedded intelligence (e.g., Cost Centers might be named `"CC_100_NY"`, `"CC_200_BOS"`, `"CC_300_NY"`). 
If an administrator needs to execute a calculation on all "New York" cost centers, but they do NOT share a common parent in the hierarchy (i.e., they are scattered across different divisions), standard hierarchy functions like `@DESCENDANTS` or `@SIBLINGS` are completely useless. 
You *could* manually list all the NY cost centers, but that breaks the moment a new one is added. 
`@LIKE` solves this by treating member names as searchable text. By passing a wildcard string (e.g., `"*_NY"`), the Essbase compiler scans the entire dimension, extracts every member name that ends with `_NY`, and dynamically bundles them into a calculation array. This provides immense flexibility for querying unstructured or naming-convention-driven dimensions.

### When to Use It

- **Cross-Hierarchy Grouping**: Selecting members that share a common naming convention but reside in completely different branches of the dimensional tree.
- **Prefix/Suffix Targeting**: Isolating all temporary holding buckets (e.g., all members starting with `"TBD_"`) to clear them out before a consolidation cycle.
- **Attribute Workarounds**: Emulating UDA (User-Defined Attribute) behavior by querying naming patterns when real UDAs haven't been implemented in the `.otl` yet.

---

## Category

**Member Selection / String & Pattern Matching / Essbase Native Functions**

---

## Syntax

```essbase
@LIKE(pattern_string [, mbrName])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern_string` | String | ✅ Yes | The text pattern you are searching for, enclosed in quotes. Must contain at least one wildcard.<br>- `*` (Asterisk): Matches any number of characters.<br>- `—` (Question Mark): Matches exactly ONE character. |
| `mbrName` | Member | ❌ No  | A specific parent member to restrict the search. If provided, `@LIKE` will only search the descendants of this member. If omitted, it searches the entire database globally. |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of all members whose names (or aliases) match the provided wildcard pattern.
- **Empty Result**: If no members in the database (or under the restricted parent) match the text pattern, the function returns an empty set. When used in a `FIX` statement, the `FIX` safely bypasses execution.
- **Global Sweep**: If `mbrName` is omitted, the engine has to scan every single member in every single dimension to find matches. This can be slow in massive applications.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The compiler reads the `pattern_string` (e.g., `"Exp_*"`).
2. **Boundary Setup**: If a `mbrName` is provided, it restricts the search area. Otherwise, it prepares a global sweep.
3. **Pattern Scan**: It iterates through the target members, pulling their physical string names and aliases.
4. **Wildcard Evaluation**: It performs a standard C-level Regex/Wildcard string comparison on each member.
5. **Array Assembly**: Every member that returns a positive match is appended to an internal list.
6. **Return**: The final concatenated array is returned to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Prefix Matching (Global)

```essbase
/* 
   Finds EVERY member in the entire application that starts with "Proj_".
   Returns: "Proj_101", "Proj_A", "Proj_Hold"
*/
@LIKE("Proj_*")
```

### Variant 2: Constrained Search (Targeted)

```essbase
/* 
   Finds members ending in "_Adj" ONLY if they exist 
   somewhere underneath the "Total_Revenue" parent.
*/
@LIKE("*_Adj", "Total_Revenue")
```

---

## Practical Examples

### Example 1: Clearing Temporary Transfer Accounts

**Scenario**: A massive intercompany elimination script uses temporary holding accounts to calculate balances before pushing them to the final ledger. All of these temporary accounts were strictly named with the prefix `"Temp_Xfer_"`. At the end of the month, the script must ensure every single one of these accounts is zeroed out. They are scattered across the Account dimension. 

```essbase
/* 
   1. The FIX statement uses @LIKE to dynamically find all the accounts.
   We constrain the search to the "Account" dimension to speed up the scan.
*/
FIX("FY25", "Working", "No_Entity", @LIKE("Temp_Xfer_*", "Account"))
    
    /* 
       2. Zero out the data.
       Because of @LIKE, this will clear "Temp_Xfer_Rev", "Temp_Xfer_Exp", etc.,
       no matter where they sit in the account tree.
    */
    CLEARBLOCK ALL;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Performance Overhead | Global `*` Sweeps | If you use `@LIKE("*_Adj")` without providing a target parent dimension, Essbase has to extract the string name of *every single member in the entire application* (Accounts, Entities, Products, Projects) and check it. In a 500,000-member application, this will drastically slow down compilation time. ALWAYS provide the dimension name (e.g., `"Entity"`) as the second parameter to constrain the search |
| Case Sensitivity | `"proj_*"` vs `"Proj_*"` | Depending on the specific EPM Cloud patch and underlying OS, wildcard matches can sometimes be case-sensitive. If you search for `"proj_*"`, it might completely miss `"Proj_101"`. To be safe, always match the exact casing of your standard naming conventions |
| Using it inside `IF` Statements | `IF(@LIKE("*A*") == "B")` | This function generates an array of members. It is a Member Selection function. You cannot use it inside a standard Boolean `IF` statement. If you need to check if the *current* calculating member matches a pattern, you must use the boolean function `@ISMBRWITHATTR` or use a custom Java string comparison |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@MATCH`](./@MATCH.md) | An older alias/legacy version of the exact same function. `@LIKE` and `@MATCH` generally perform identical wildcard array selections |
| [`@UDA`](./@UDA.md) | The structural alternative. Instead of relying on string patterns, UDAs allow you to tag scattered members with a specific metadata flag (e.g., "Is_Temp"), which is significantly faster to query than doing text sweeps |
| [`@CONCAT`](./@CONCAT.md) | A string function often used to dynamically *build* member names, whereas `@LIKE` is used to *search* for them |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — LIKE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/like.html)
