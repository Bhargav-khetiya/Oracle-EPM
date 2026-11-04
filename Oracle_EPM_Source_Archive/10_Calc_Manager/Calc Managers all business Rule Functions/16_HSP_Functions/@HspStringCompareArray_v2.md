# @HspStringCompareArray

## Overview

`@HspStringCompareArray` is a **Hyperion Planning (HSP) custom string function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It takes a single target text string and evaluates it against an entire array (list) of strings. It returns an integer indicating whether the target string exists anywhere within that array.

### Why Does This Function Exist—

In advanced conditional logic, administrators frequently need to check if a specific member belongs to a specific group. If you are calculating `"Entity_105"`, you might need to know if it belongs to the `"High_Risk_Group"`. 
Natively, you could use `@ISMBR`, but that requires the group to be defined structurally in the Essbase `.otl` file (like a UDA or a parent member). If the `"High_Risk_Group"` is actually just a text string passed as a runtime prompt (e.g., `"Entity_105, Entity_201, Entity_404"`), `@ISMBR` cannot read it.
`@HspStringCompareArray` acts as a text-based `ISMBR`. You pass it the target string (e.g., `"Entity_105"`) and the array of strings. The C-engine parses the array and checks for a perfect text match. If it finds one, it returns `0` (Success/Match), allowing the script to proceed with specific conditional logic without requiring complex outline modifications.

### When to Use It

- **Runtime Prompt Validations**: Checking if the current calculation member exists within a comma-separated list of members passed by a user at runtime.
- **Dynamic Exclusion Lists**: Storing a list of "Excluded Accounts" in a string variable, and checking if the current account matches any of them before executing an allocation.
- **Relational Integration**: Taking a massive string list returned by `@HspMbrList` and verifying if a specific dimension member exists inside it.

---

## Category

**String Processing / Comparisons & Equivalence / Custom HSP Functions**

---

## Syntax

```essbase
@HspStringCompareArray("Target_String", "String_Array_Definition")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Target_String"` | String | ✅ Yes | The explicit text string you want to look for (e.g., `"New_York"`). Must be in quotes or a string variable. |
| `"String_Array_Definition"` | String | ✅ Yes | The comma-separated list of strings you are searching within (e.g., `"New_York, Chicago, Miami"`). Must be in quotes or a variable. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer defining the match status.
- **`0` (Zero)**: The target string was found **successfully** within the array. (Note: Like `@HspStringCompare`, `0` means "Zero Differences" or "Match").
- **`1` (or Non-Zero)**: The target string was **NOT found** anywhere in the array.
- **Storage**: Because it returns a standard integer, it can be evaluated directly inside an `IF` statement.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine evaluates both inputs as text payloads.
2. **Array Parsing**: It takes the second parameter (the array) and splits it into discrete memory blocks based on commas.
3. **Sequential Scan**: It steps through the array. For each element, it performs a strict, case-sensitive ASCII comparison against the `"Target_String"`.
4. **Match & Terminate**: If it finds a perfect match, it stops immediately and returns `0`.
5. **Fail State**: If it reaches the end of the array without a match, it returns `1`.

---

## Syntax Variants & Scenarios

### Variant 1: Checking a Hardcoded Array

```essbase
/* 
   Checks if "Apple" exists in the list.
   Because it does, it returns 0.
*/
VAR vIsMatch = @HspStringCompareArray("Apple", "Banana, Apple, Orange");
```

---

## Practical Examples

### Example 1: Creating a Dynamic Exclusion Engine

**Scenario**: A corporate expense allocation pushes data to every Base Entity. However, the FP&A team has created a text variable called `vExclusionList` that contains a list of entities that should be quarantined (e.g., `"Entity_998, Entity_999"`). The script must evaluate every entity against this list and bypass the logic if a match is found.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. Define or retrieve the dynamic exclusion list.
    */
    VAR vExclusionList = "Entity_998, Entity_999";
    
    /* 
       2. Extract the name of the current Entity we are calculating.
       (e.g., "Entity_105")
    */
    VAR vCurrentEntity = @NAME(@CURRMBR("Entity"));
    
    /* 
       3. Compare the current entity against the exclusion array.
       If it is NOT in the list, it returns 1. 
       If it IS in the list, it returns 0.
    */
    VAR vMatchStatus = @HspStringCompareArray(vCurrentEntity, vExclusionList);
    
    /* 
       4. Execute logic based on the integer result.
       We only want to calculate entities that are NOT in the list (so, != 0).
    */
    IF(vMatchStatus != 0)
        
        /* Apply allocation */
        "Allocated_Expense" = "Corporate_Pool" * "Headcount_Ratio";
        
    ELSE
        
        /* The entity is quarantined. Do nothing, or log a warning. */
        VAR vLog = @CalcMgrLogMemberStrings("Entity Quarantined: ", vCurrentEntity);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Reverse Boolean Logic | `IF(Compare == 1)` | Just like standard string compares, `0` means MATCH, and `1` means NO MATCH. If you write `IF(Compare == 1)` to execute logic on the matching members, it will fire on everything *except* the matching members. Always use `== 0` for inclusion logic |
| Case Sensitivity | `"apple"` vs `"Apple"` | This function is strictly case-sensitive. If your array has `"Apple"` and you search for `"apple"`, it will return `1` (No Match). If you need case-insensitive array searching, you must use modern Java functions like `@CalcMgrHasPattern` |
| Spacing in the Array | `"A, B, C"` vs `"A,B,C"` | Legacy HSP functions can be overly sensitive to spaces trailing a comma. If you search for `"B"` in `"A, B, C"`, it might internally parse the element as `" B"`, causing a mismatch. Keep your delimited arrays clean and tightly packed |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspStringCompare`](./@HspStringCompare.md) | The singular version of this function. Compares one string directly against one other string, rather than an array |
| [`@HspMbrIndex`](./@HspMbrIndex.md) | Very similar to this function, but instead of just returning `0` (Match) or `1` (No Match), it returns the exact mathematical position where the match occurred (e.g., `2`) |
| [`@ISMBR`](../09_Boolean_Conditional/@ISMBR.md) | The native boolean equivalent, used exclusively when the array of members actually exists in the Essbase outline (rather than just being a text string) |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspstringcomparearray.html)
