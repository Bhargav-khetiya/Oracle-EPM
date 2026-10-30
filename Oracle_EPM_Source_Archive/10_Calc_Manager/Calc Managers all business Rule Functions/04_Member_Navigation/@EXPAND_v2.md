# @EXPAND

## Overview

`@EXPAND` is a **native Essbase member selection function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a single parent member (or a list of members) and dynamically generates an array containing that member *and* all of its descendants (or children) down to a specified hierarchical level. 

### Why Does This Function Exist?

When building calculation scripts, it is common to target an entire branch of a hierarchy. You could write `@DESCENDANTS("Total_Expenses")`, which returns all the base accounts. But what if you want the descendants *plus* the `"Total_Expenses"` parent itself? You would have to write `"Total_Expenses", @DESCENDANTS("Total_Expenses")`. 
While this is manageable for a single member, what if you have a variable or an attribute search that returns 5 different parent members, and you need to simultaneously select *all 5 parents and all of their respective descendants*? Stringing that together manually is impossible.
`@EXPAND` solves this by natively wrapping "Member + Descendants" into a single, cohesive array command. You pass it a member (or a list/UDA), tell it how deep to go, and it automatically builds the comprehensive array, ensuring both the targets and their children are included in the `FIX` statement or function block.

### When to Use It

- **Dynamic Cross-Dimensional Rollups**: Forcing a calculation to execute on a specific parent Entity and all of its descendants simultaneously (often used when overriding default aggregation with `@CALCMODE(BOTTOMUP)`).
- **Attribute-Based Expansions**: Searching for all Regions that have the `"High_Growth"` UDA, and then automatically expanding the selection to include all the individual stores underneath those regions.
- **Reporting & Exporting**: Generating a contiguous list of a hierarchy branch (Parent followed by Children) for a `DATAEXPORT` command.

---

## Category

**Member Selection / Hierarchy Traversal / Essbase Native Functions**

---

## Syntax

```essbase
@EXPAND(memberList [, level | @CHILDREN | @DESCENDANTS])
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `memberList` | Member / Array | ✅ Yes | The target member (or list of members, or a UDA function) that serves as the starting anchor. |
| `Expansion_Rule` | Keyword / Integer | ❌ No  | Defines how deep the expansion should go. <br>- **(Omitted)**: Defaults to `@DESCENDANTS` (expands all the way down to Level 0).<br>- `@CHILDREN`: Only expands one step down (immediate children).<br>- `@DESCENDANTS`: Expands all the way down.<br>- `Integer (Level)`: Expands down to a specific Bottom-Up level (e.g., `0` for leaf nodes). |

---

## Return Value

**Return Type**: Member List (Array)

Returns a comma-separated array of members.
- **Inclusion**: The array ALWAYS includes the original `memberList` anchors. (e.g., `@EXPAND("Q1")` returns `"Q1", "Jan", "Feb", "Mar"`).
- **Empty Expansion**: If you pass a Level 0 member (which has no children), it simply returns the member itself without throwing an error.

---

## How It Works (Behind the Scenes)

1. **Anchor Resolution**: Essbase evaluates the `memberList`. If it is a single member (`"North_America"`), it sets it as the anchor. If it is a list (e.g., `@UDA("Entity", "Taxable")`), it builds an array of all matching anchors.
2. **Expansion Traversal**: It looks at the `Expansion_Rule`. 
   - If it is `@CHILDREN`, it queries the outline for the immediate children of the anchor(s).
   - If it is `@DESCENDANTS` or omitted, it walks the entire tree down to the leaves.
3. **Concatenation**: It combines the original anchors with the newly discovered children into a single, flat array.
4. **Return**: It passes the final array back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Expanding a Single Member to Descendants

```essbase
/* 
   Returns: "Total_Marketing", "Advertising", "Promotions", "Events"
*/
@EXPAND("Total_Marketing")
```

### Variant 2: Expanding a UDA List

```essbase
/* 
   Finds all parent entities tagged "European_HQ". 
   Returns those HQs PLUS all their respective child entities.
*/
@EXPAND(@UDA("Entity", "European_HQ"))
```

---

## Practical Examples

### Example 1: Efficient Parent/Child Clear Script

**Scenario**: A forecasting model allows users to run a "Clear Region" rule. The rule prompts the user for a Region (e.g., `"North_America"`). The script must clear out the data for the selected region *and* all the individual stores underneath it to ensure the consolidation is perfectly zeroed out before the user re-enters new data.

```essbase
/* 
   1. The {Selected_Region} is passed from a runtime prompt.
   2. @EXPAND takes that region and automatically builds an array 
      containing both the parent and all its descendants.
*/
FIX("FY25", "Working", @EXPAND({Selected_Region}))
    
    /* 
       3. Clear the data. 
       Because of the EXPAND, this clears the base input stores 
       AND the parent aggregation node simultaneously.
    */
    CLEARBLOCK ALL;
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using EXPAND when ILDESCENDANTS works | `@EXPAND("USA", @DESCENDANTS)` | The `@ILDESCENDANTS("USA")` function (Inclusive Level Descendants) already returns the parent and all descendants. If you are targeting a *single* hardcoded member, `@ILDESCENDANTS` is slightly faster and cleaner to read. `@EXPAND` is best utilized when you are expanding a *dynamic list* of members (like a UDA or an `@EQUAL` lookup) |
| Using integers instead of Keywords | `@EXPAND("Q1", 0)` | While valid, using a strict integer `0` forces Essbase to evaluate the outline based on Bottom-Up levels. If the hierarchy is ragged, Level 0 might not encompass all the descendants you expected. It is usually much safer and more readable to explicitly use `@EXPAND("Q1", @DESCENDANTS)` |
| Endless Expansion Loops | Using `@EXPAND` inside a dense `IF` block | Member selection functions belong in `FIX` statements. If you try to use `@EXPAND` to dynamically calculate an array inside a cell-by-cell `IF` block, Essbase will have to re-evaluate the outline thousands of times, destroying performance. Keep member selections in the `FIX` |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ILDESCENDANTS`](./@ILDESCENDANTS.md) | A streamlined, single-member function that returns a member and its descendants. (Shorthand for `@EXPAND("Member")`) |
| `@ILCHILDREN` | Returns a member and its immediate children. (Shorthand for `@EXPAND("Member", @CHILDREN)`) |
| [`@DESCENDANTS`](./@DESCENDANTS.md) | Returns ONLY the descendants, specifically EXCLUDING the parent member |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — EXPAND](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/expand.html)
