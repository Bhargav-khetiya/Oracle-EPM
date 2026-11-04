# @HspOffsetIdx

## Overview

`@HspOffsetIdx` is a **Hyperion Planning (HSP) custom indexing function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It serves as an advanced sequence locator. Given a starting index integer, a text string array (list), and a target member, this function dynamically calculates the **mathematical distance (offset)** between the start of the array and the location of the target member.

### Why Does This Function Exist—

When executing parallel array iteration, you often need to move back and forth across a sequence. If an administrator is evaluating a list of 12 months (`"Jan, Feb, Mar, Apr..."`), and they know the current calculation is running on `"Mar"` (which is Index 3), they might need to mathematically find how many steps it takes to reach `"Oct"`.
Instead of manually writing an iterative C-loop to count the steps, `@HspOffsetIdx` calculates the distance natively. You give it the array, tell it where you currently are (or where to start counting), and ask it to find `"Oct"`. It returns the integer offset (the number of steps). This offset can then be used in `SHIFT` logic or to jump directly to corresponding data in a parallel array.

### When to Use It

- **Relative Sequence Jumping**: Calculating exactly how many steps exist between a "Start Phase" and an "End Phase" in a custom array of project lifecycle milestones.
- **Dynamic Lags/Leads**: Finding the exact integer distance between the current dimension member and a target dimension member to feed into an `@SHIFT` or `@PRIOR` function dynamically.
- **Parallel Validations**: Checking if a specific target member exists *after* a certain index point in a list (if the offset is returned, it exists downstream).

---

## Category

**Planning Extensions / Array & Index Processing / Custom HSP Functions**

---

## Syntax

```essbase
@HspOffsetIdx(Start_Index, "Target_Member", "List_Name" | "Member1, Member2, ...")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Start_Index` | Numeric | ✅ Yes | The mathematical position in the list where the engine should begin counting from (e.g., `1` to start at the beginning, or `3` to start from the 3rd item). |
| `"Target_Member"` | String | ✅ Yes | The explicit text name of the member you want to locate (e.g., `"Oct"`). |
| `List_Definition` | String | ✅ Yes | The array or comma-separated string of members you are searching within. Can be a hardcoded list or a dynamic string variable. |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns the absolute integer offset (distance) between the `Start_Index` and the `Target_Member`.
- **Match Math**: If `Start_Index` is 1, and the target is at position 3, the offset is typically `2` (meaning 2 steps forward). *(Note: Legacy versions of this function occasionally return the absolute index rather than the delta. Always test behavior in your specific environment patch).*
- **Not Found (`-1`)**: If the `Target_Member` does not exist in the list (or does not exist *after* the `Start_Index`), the function returns `-1`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The engine evaluates the target string, the starting index, and parses the list definition into memory.
2. **Jump to Start**: It bypasses all elements in the array prior to the `Start_Index`.
3. **Sequential Scan**: It begins scanning forward from that anchor point.
4. **Distance Tally**: It increments an internal counter for every item it passes.
5. **Match & Return**: When it hits a perfect text match on `"Target_Member"`, it stops and returns the internal counter (the offset distance) to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Finding Distance in a List

```essbase
/* 
   Starts at index 1 ("Q1"). Looks for "Q4".
   Distance is 3 steps. Returns 3.
*/
VAR vDistance = @HspOffsetIdx(1, "Q4", "Q1, Q2, Q3, Q4");
```

---

## Practical Examples

### Example 1: Dynamic Rolling Averages based on Phase Milestones

**Scenario**: A construction model has 5 phases: `"Planning, Foundation, Framing, Interior, Closeout"`. Expenses are incurred continuously. When the project hits `"Interior"`, the script must calculate a rolling average of all expenses incurred *since* `"Planning"`. To do this, it needs to know exactly how many phases exist between Planning and Interior so it can pass that number into an `@MOVAVG` function.

```essbase
FIX("FY25", "Working", @LEVEL0("Projects"))
    
    /* 
       1. Define the Phase array.
    */
    VAR vPhaseList = "Planning, Foundation, Framing, Interior, Closeout";
    
    /* 
       2. Find the absolute index of the Starting Phase (Planning).
       (This will return 1).
    */
    VAR vStartIndex = @HspMbrIndex("Planning", vPhaseList);
    
    /* 
       3. Extract the active Phase the project is currently sitting in.
       (e.g., "Interior")
    */
    VAR vCurrentPhase = @NAME(@CURRMBR("Phase"));
    
    /* 
       4. Calculate the offset distance between Planning and Interior.
       (It will start at 1, step over Foundation and Framing, and hit Interior.
       Returns 3).
    */
    VAR vOffset = @HspOffsetIdx(vStartIndex, vCurrentPhase, vPhaseList);
    
    /* 
       5. If the offset is valid (>= 0), use that dynamic offset integer 
       to calculate the Moving Average across exactly that many phases.
    */
    IF(vOffset > 0)
        "Phase_Avg_Expense" = @MOVAVG("Total_Expense", vOffset);
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Negative Start Indexes | `@HspOffsetIdx(-2, "Q1", List)` | The `Start_Index` must be a valid, positive position within the boundaries of the array (e.g., `1` through `N`). You cannot pass negative numbers or `0` (since arrays are 1-indexed). Doing so will cause the function to fail or return `-1` |
| Passing Member Objects | `@HspOffsetIdx(1, @CURRMBR("Entity"), ...)` | The Target parameter MUST be a text string. You cannot pass native Essbase Member Objects. Wrap any dynamic member pointers in `@NAME` (e.g., `@NAME(@CURRMBR("Entity"))`) to cast them to text before searching |
| Ignoring `-1` Returns | Using the output without validation | If the target member is not found, the function returns `-1`. If you pipe `-1` directly into another array function (like `@HspNthMbr(Offset, List)`), the engine will attempt to look up Index `-1`, causing an Out of Bounds crash. Always validate `IF(Offset != -1)` before using the result |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@HspMbrIndex`](./@HspMbrIndex.md) | Finds the absolute integer position of a member, rather than the relative distance (offset) from a starting point |
| [`@HspNthMbr`](./@HspNthMbr.md) | Extracts the string name of a member at a specific position, often used in conjunction with offset math to pull corresponding array items |
| [`@CalcMgrSortList`](./@CalcMgrSortList.md) | The modern Java equivalent for managing lists, though calculating offsets is usually handled via custom Java loop logic rather than a dedicated offset function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspoffsetidx.html)
