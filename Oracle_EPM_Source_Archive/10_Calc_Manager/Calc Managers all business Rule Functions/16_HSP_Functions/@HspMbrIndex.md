# @HspMbrIndex

## Overview

`@HspMbrIndex` is a **Hyperion Planning (HSP) custom indexing function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It evaluates a specific member name against a predefined list of members and returns an **integer index (position)** representing exactly where that member sits within the list.

### Why Does This Function Exist?

In advanced array processing or dynamic matrix math, the physical location of a member within a sequence is critical. 
If an administrator generates a list of priority products (`"Prod_A"`, `"Prod_B"`, `"Prod_C"`), and the engine is currently calculating `"Prod_B"`, the script might need to know that `"Prod_B"` is the *second* item in the priority list, so it can apply a "Tier 2" discount multiplier. 
Native Essbase functions struggle with this kind of relative ordinal mapping. `@HspMbrIndex` solves this by natively scanning the provided list. It looks for the target member, and if it finds it, it returns its exact position number (e.g., `2`). This integer can then be used to dynamically select multipliers from parallel arrays or trigger specific tiered logic without writing massive, nested `IF` statements.

### When to Use It

- **Tiered Logic Execution**: Returning an integer index (1, 2, or 3) to dynamically map an entity to a Tier 1, Tier 2, or Tier 3 allocation percentage.
- **Parallel Array Mapping**: Finding the position of a member in Array A, so you can pull the corresponding data point from the exact same position in Array B.
- **Validation Checks**: Determining if a specific member *exists* within a custom list. (If the function returns `-1`, the member is not in the list, allowing the script to bypass it).

---

## Category

**Planning Extensions / Array & Index Processing / Custom HSP Functions**

---

## Syntax

```essbase
@HspMbrIndex("Member_Name", "List_Name" | "Member1, Member2, ...")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Member_Name"` | String | ✅ Yes | The explicit text name of the member you want to locate (e.g., `"Prod_B"`). |
| `List_Definition` | String | ✅ Yes | The array or comma-separated string of members you are searching within. Can be a hardcoded list (`"Prod_A, Prod_B, Prod_C"`) or a reference to an HSP-managed list. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the absolute integer position of the target member within the list.
- **1-Indexed**: The first item in the list is always `1`. The second is `2`.
- **Not Found (`-1`)**: If the member does not exist anywhere within the list, the function returns `-1`. This is frequently used as a boolean check.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine evaluates the target string and the list definition.
2. **Parsing**: It parses the list into an internal memory array, splitting it by commas.
3. **Sequential Scan**: It scans the array starting from Index 1. 
4. **Match Evaluation**: It executes a string comparison. If it finds a perfect match, it immediately stops scanning and returns the current index counter.
5. **Fail State**: If it reaches the end of the array without a match, it returns `-1`.

---

## Syntax Variants & Scenarios

### Variant 1: Finding the Position in a Hardcoded List

```essbase
/* 
   Searches for "Q3" in the provided list. 
   Returns 3.
*/
VAR vPosition = @HspMbrIndex("Q3", "Q1, Q2, Q3, Q4");
```

---

## Practical Examples

### Example 1: Dynamic Validation Routing

**Scenario**: A corporate overhead script must apply different tax rates based on regional risk tiers. The Tier 1 entities are `"NY", "CA", "TX"`. The Tier 2 entities are `"FL", "WA"`. Instead of writing endless `IF` blocks inside the block, the script converts the active member into a string and uses `@HspMbrIndex` to check if it exists in the high-risk list. If it does not return `-1`, the high-risk rate is applied.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 
       1. Extract the name of the current Entity being processed.
    */
    VAR vCurrentEntity = @NAME(@CURRMBR("Entity"));
    
    /* 
       2. Check if this entity exists in the Tier 1 High-Risk List.
       If it is "CA", this will return 2. 
       If it is "WA", this will return -1 (Not Found).
    */
    VAR vTier1Index = @HspMbrIndex(vCurrentEntity, "NY, CA, TX");
    
    /* 
       3. Route the tax logic based on the index result.
    */
    IF(vTier1Index != -1)
        
        /* The entity IS in the Tier 1 list. Apply 35% */
        "Tax_Rate" = 0.35;
        
    ELSE
        
        /* The entity is NOT in the Tier 1 list. Check Tier 2 or apply default. */
        "Tax_Rate" = 0.20;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Passing Member Objects | `@HspMbrIndex(@CURRMBR("Entity"), "A,B")` | This function requires the search target to be a text string. You CANNOT pass a native Essbase Member Object. You must wrap dynamic references in `@NAME` (e.g., `@NAME(@CURRMBR("Entity"))`) to cast them to text before executing the search |
| Spacing and Format Errors | `" NY, CA, TX "` | Legacy HSP functions are occasionally hyper-sensitive to spaces in comma-separated arrays. If you search for `"CA"`, but the array internally parses it as `" CA"` (with a leading space), it will return `-1`. Ensure your lists are cleanly formatted or use exact delimiters |
| Expecting Arrays from Native Functions | `@HspMbrIndex("USA", @CHILDREN("Global"))` | Native Essbase array generators (like `@CHILDREN`) return a native multidimensional object set, not a comma-separated text string. You cannot pipe standard Essbase relative functions directly into the second parameter of `@HspMbrIndex` unless specifically routed through list-conversion CDFs. It expects a literal string list |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspMbrList`](./@HspMbrList.md) | A companion function that can dynamically generate the text-based list required by the second parameter of `HspMbrIndex` |
| [`@NAME`](./@NAME.md) | The mandatory function used to convert Essbase Member Objects into the text strings required for the search |
| [`@ISMBR`](./@ISMBR.md) | The native, highly-optimized boolean equivalent. If you just need to know IF a member is in a list (and don't care about the index number), `IF(@ISMBR("NY", "CA", "TX"))` is drastically faster and safer than `HspMbrIndex` |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspmbrindex.html)
