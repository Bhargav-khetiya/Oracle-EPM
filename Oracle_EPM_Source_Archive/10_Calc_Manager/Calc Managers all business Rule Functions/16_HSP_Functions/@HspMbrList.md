# @HspMbrList

## Overview

`@HspMbrList` is a **Hyperion Planning (HSP) custom array function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It dynamically retrieves the structural definition of a Smart List, substitution variable array, or relational member list from the Planning repository, and returns it as a **comma-separated text string**. 

### Why Does This Function Exist—

In EPM Cloud, administrators can create Smart Lists (dropdown menus) or custom relational Member Lists (like "Tier 1 Priority Products") inside the Web UI. These lists are stored in the relational database, not in the Essbase `.otl` outline. 
If an Essbase calculation script needs to evaluate if the currently calculating product is part of that "Priority Products" list, it cannot use native functions like `@ISMBR`, because the list doesn't technically exist in Essbase. 
`@HspMbrList` solves this by acting as a bridge. The script calls the function, passes the name of the relational list, and the function connects to the relational repository, extracts all the members assigned to that list, and returns them as a single, massive text string (e.g., `"Prod_A, Prod_B, Prod_C"`). That string can then be passed directly into indexing functions like `@HspMbrIndex` to execute the business logic.

### When to Use It

- **Smart List Validation**: Extracting the valid entries of a Smart List to ensure that a dynamically calculated metric conforms to the allowed dropdown values before writing it to a block.
- **Relational List Synchronization**: Pulling a custom list of "Target Entities" defined by a user in the Web UI so an allocation script knows exactly where to push data without hardcoding the entities in the script.
- **Dynamic Array Construction**: Providing the foundational array required by `@HspMbrIndex` or `@HspNthMbr` to execute parallel iteration logic.

---

## Category

**Planning Extensions / Array & Index Processing / Custom HSP Functions**

---

## Syntax

```essbase
@HspMbrList("List_Name_or_Type")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"List_Name_or_Type"` | String | ✅ Yes | The exact text name of the relational list or Smart List you are attempting to retrieve from the Planning repository. Must be enclosed in double quotes. |

---

## Return Value

**Return Type**: String

Returns a single, massive text string containing all the members of the requested list, separated by commas.
- **Output Format**: `"Member1, Member2, Member3"`
- **Storage Limitation**: Because the function returns a text string (which can easily exceed thousands of characters), it CANNOT be saved into a standard Essbase numeric account. It MUST be assigned to a `VAR` string variable.
- **Error State**: If the list does not exist, the function typically returns an empty string `""` or throws a relational connection error.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the function.
2. **Relational API Call**: Essbase pauses block calculation and sends a payload to the relational Planning database, asking for the contents of `"List_Name_or_Type"`.
3. **Repository Query**: The relational database queries its internal tables (like `HSP_SMART_LIST` or `HSP_MEMBER_LIST`), grabbing all the associated member IDs.
4. **String Construction**: Planning resolves those IDs to their actual Essbase member names and concatenates them into a single string with commas.
5. **Return**: The massive string is piped back across the API to the Essbase calculation thread and assigned to the local `VAR`.

---

## Syntax Variants & Scenarios

### Variant 1: Retrieving a Custom Target List

```essbase
/* 
   Retrieves the relational list of allocation targets defined in the Web UI.
   Returns: "Target_NY, Target_CA, Target_TX"
*/
VAR vTargetListStr = @HspMbrList("Alloc_Targets");
```

---

## Practical Examples

### Example 1: Extracting and Indexing a Dynamic Priority List

**Scenario**: Corporate headquarters updates a custom list in the Planning UI called `"High_Risk_Regions"` every month. An overnight allocation script calculates regional reserve balances. If a region is High Risk, they get a 10% reserve. If not, they get a 2% reserve. The script uses `@HspMbrList` to fetch whatever the *current* list is, and then uses `@HspMbrIndex` to check if the actively calculating region is on that list.

```essbase
/* 
   1. Outside the FIX statement, we query the relational database ONCE 
   to pull the list of High-Risk regions.
   (e.g., vRiskList becomes "Region_A, Region_F, Region_Z")
*/
VAR vRiskList = @HspMbrList("High_Risk_Regions");

FIX("FY25", "Working", @LEVEL0("Regions"))
    
    /* 2. Check if we actually retrieved a valid list */
    IF(@CalcMgrCompare(vRiskList, "", @_true) != 0)
        
        /* 
           3. Extract the name of the region we are currently calculating.
        */
        VAR vCurrentRegion = @NAME(@CURRMBR("Regions"));
        
        /* 
           4. Check if the current region exists inside the list we pulled.
           If it does, it returns an integer > 0.
           If it does not, it returns -1.
        */
        VAR vListPosition = @HspMbrIndex(vCurrentRegion, vRiskList);
        
        /* 
           5. Execute the business logic.
        */
        IF(vListPosition != -1)
            "Reserve_Balance" = "Total_Revenue" * 0.10;
        ELSE
            "Reserve_Balance" = "Total_Revenue" * 0.02;
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Attempting to Save to an Account | `"My_List" = @HspMbrList(...)` | **Essbase Data Cells CANNOT store text strings.** They only store numbers. If you try to assign the string `"Prod_A, Prod_B"` to a standard member, the block will reject it, writing `#MISSING` or throwing a compilation error. The string must be kept in a `VAR` memory variable |
| Overusing Inside Dense Loops | Fetching the list 10,000 times | Because this function makes a network API call to a relational database, putting it *inside* a `FIX` statement that calculates 10,000 Cost Centers will cause a Denial of Service on the environment. **ALWAYS** declare the `VAR vList = @HspMbrList(...)` at the absolute top of your script, entirely outside of any `FIX` block, so it only fetches the string once |
| Using Native Functions on the Output | `@ISMBR(vRiskList)` | You cannot pass a raw text string (`"A, B, C"`) directly into a native Essbase boolean check like `@ISMBR`. Native Essbase functions expect actual member references, not text. You MUST use string-processing CDFs (like `@HspMbrIndex` or `@CalcMgrHasPattern`) to evaluate the contents of the text string |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspMbrIndex`](./@HspMbrIndex.md) | The primary consumer of this function. `@HspMbrList` fetches the massive string, and `@HspMbrIndex` searches inside that string to find a specific member |
| [`@HspNthMbr`](./@HspNthMbr.md) | Another array-processing function that can extract the exact member name residing at a specific integer position within the string list (e.g., "Give me the 3rd member from the list") |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspmbrlist.html)
