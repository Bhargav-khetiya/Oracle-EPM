# @ENUMVALUE

## Overview

`@ENUMVALUE` is a **metadata function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **enumerated (numeric) value** associated with a Smart List member. Smart Lists are dropdown lists attached to Planning forms that store string labels but internally map to numeric values. `@ENUMVALUE` retrieves the underlying numeric value for a Smart List entry.

### Why Does This Function Exist?

Smart Lists are widely used in Planning forms for user-friendly dropdown selections:
- Converting dropdown selections (strings) to numeric values for calculations
- Building conditional logic based on Smart List selections
- Translating user input from forms into calculation-ready numbers
- Mapping categorical selections to calculation parameters

### When to Use It

- When you need the numeric value behind a Smart List dropdown selection
- In `IF` conditions to branch logic based on Smart List choices
- When converting form inputs to numeric values for business rules
- For mapping Smart List selections to rates, factors, or flags

---

## Category

**Metadata / Smart List / Enumeration**

---

## Syntax

```essbase
@ENUMVALUE(smartListName, memberReference)
```

### Formal Syntax

```
@ENUMVALUE(smartListDimOrName, cellOrMember)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `smartListName` | String | ✅ Yes | The Smart List name or the dimension/member containing the Smart List value. |
| `memberReference` | Reference | ✅ Yes | The cell or member from which to read the Smart List value. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Valid Smart List entry | The numeric enumeration value (integer) |
| No Smart List value | `#MISSING` or 0 |

**Return Type**: Numeric (integer)

---

## How It Works (Behind the Scenes)

1. **Smart List Mapping**: Each Smart List entry has a label (displayed to user) and a numeric ID (stored internally).
2. **Value Retrieval**: `@ENUMVALUE` reads the cell's Smart List selection and returns the associated numeric ID.
3. **Form Integration**: Users select from dropdowns on forms; `@ENUMVALUE` extracts the numeric code for calculations.

---

## Practical Examples

### Example 1: Growth Method Selection

**Smart List "GrowthMethod"**: Flat=1, Percentage=2, CAGR=3

```essbase
FIX("FY25", "Budget", @DESCENDANTS("Total_Accounts"))
    IF(@ENUMVALUE("GrowthMethod", "Method_Selection") == 1)
        /* Flat growth */
        Revenue = "Prior_Revenue" + "Flat_Amount";
    ELSEIF(@ENUMVALUE("GrowthMethod", "Method_Selection") == 2)
        /* Percentage growth */
        Revenue = "Prior_Revenue" * (1 + "Growth_Pct" / 100);
    ELSEIF(@ENUMVALUE("GrowthMethod", "Method_Selection") == 3)
        /* CAGR growth */
        Revenue = "Base_Revenue" * @POWER(1 + "CAGR_Rate", "Year_Number");
    ENDIF
ENDFIX
```

### Example 2: Allocation Method

**Smart List "AllocMethod"**: Equal=1, Revenue=2, Headcount=3

```essbase
IF(@ENUMVALUE("AllocMethod", "Alloc_Choice") == 1)
    "Allocation" = "Total" / @COUNT(@CHILDREN("Entity"));
ELSEIF(@ENUMVALUE("AllocMethod", "Alloc_Choice") == 2)
    "Allocation" = "Total" * "Rev_Share";
ELSEIF(@ENUMVALUE("AllocMethod", "Alloc_Choice") == 3)
    "Allocation" = "Total" * "HC_Share";
ENDIF
```

### Example 3: Status Flag Processing

**Smart List "Status"**: Draft=1, Submitted=2, Approved=3

```essbase
IF(@ENUMVALUE("Status", "Workflow_Status") >= 2)
    "Is_Finalized" = 1; /* Submitted or Approved */
ELSE
    "Is_Finalized" = 0; /* Draft */
ENDIF
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Wrong Smart List name | Must match the exact Smart List name defined in Planning | Verify in Planning admin under Smart Lists |
| Numeric ID mismatch | Smart List IDs are defined when creating entries — verify they match your code | Check Smart List configuration |
| Using on non-Smart-List cell | If the cell doesn't have a Smart List, returns `#MISSING` | Ensure the member/cell has a Smart List associated |
| Smart List not populated | User hasn't selected a value → returns `#MISSING` or default | Handle the empty/default case |
| Case sensitivity | Smart List names may be case-sensitive | Match exact case |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetSmartListValue`](@ENUMVALUE.md) | Gets Smart List value in Groovy/Calc Manager context |
| [`@ISMBR`](../09_Boolean_Conditional/@ISMBR.md) | Member identity check — for non-Smart-List conditions |
| [`@ISUDA`](../09_Boolean_Conditional/@ISUDA.md) | UDA check — another way to classify members |
| [`@ATTRIBUTE`](../04_Member_Navigation/@ATTRIBUTE.md) | Attribute value — for attribute-based classification |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ENUMVALUE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/enumvalue.html)
- [Oracle EPM Cloud Smart Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/smart_lists.html)
