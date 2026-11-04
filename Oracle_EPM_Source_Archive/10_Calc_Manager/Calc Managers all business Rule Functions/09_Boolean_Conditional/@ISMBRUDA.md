# @ISMBRUDA

## Overview

`@ISMBRUDA` is a **Boolean metadata function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that checks whether a specified member has a specific **User-Defined Attribute (UDA)** assigned to it. It returns `TRUE` if the member carries the named UDA, `FALSE` otherwise.

### Why Does This Function Exist—

User-Defined Attributes (UDAs) are custom tags attached to members in the outline that don't fit into standard dimension hierarchies. They are widely used to:
- Classify members by custom categories (e.g., "Controllable", "Discretionary", "Intercompany")
- Tag members for specific calculation treatments without changing the hierarchy
- Create flexible groupings that span across hierarchy branches
- Enable calculation rules that adapt based on member attributes rather than position

### When to Use It

- When you need to check if a member has a specific UDA tag
- In conditional logic to apply different calculations based on member attributes
- When UDAs are used for classification (e.g., "CAPEX" vs. "OPEX", "Headcount_Driver", etc.)
- Use `@ISMBRUDA` when you have the member reference; use `@ISUDA` for checking in the current context

---

## Category

**Boolean / Metadata / User-Defined Attribute**

---

## Syntax

```essbase
@ISMBRUDA(member, udaString)
```

### Formal Syntax

```
@ISMBRUDA(mbrName, "udaName")
```

Where:
- `mbrName` — The member to check
- `udaName` — The UDA string to test for

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name / reference | ✅ Yes | The member to check for the UDA. Can be a literal member, `@CURRMBR(dimName)`, or another member function. |
| `udaString` | String | ✅ Yes | The exact UDA string to check for. Must match the UDA exactly (case-sensitive). Enclose in double quotes. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Member has the specified UDA | `TRUE` (non-zero) |
| Member does NOT have the UDA | `FALSE` (0) |

**Return Type**: Boolean (used in `IF` conditions)

---

## How It Works (Behind the Scenes)

1. **UDA Lookup**: Essbase checks the member's metadata for the specified UDA string. UDAs are stored as tags on members in the outline.

2. **Case-Sensitive**: The UDA string comparison is typically case-sensitive. `"Controllable"` ≠ `"controllable"`.

3. **Multiple UDAs**: A member can have multiple UDAs. `@ISMBRUDA` checks for a specific one — it returns TRUE if that particular UDA is among the member's UDAs.

4. **Metadata-Only**: No data values are read. Only outline metadata is inspected.

5. **Specific Member**: Unlike `@ISUDA`, which checks the current member in context, `@ISMBRUDA` takes an explicit member parameter, allowing you to check any member.

---

## Syntax Variants & Scenarios

### Variant 1: Check Current Member

```essbase
IF(@ISMBRUDA(@CURRMBR("Account"), "Controllable"))
    /* Account has the "Controllable" UDA */
ENDIF
```

### Variant 2: Check Specific Member

```essbase
IF(@ISMBRUDA("Travel_Expense", "Discretionary"))
    "Flag" = 1;
ENDIF
```

### Variant 3: Check Parent Member's UDA

```essbase
IF(@ISMBRUDA(@MBRPARENT(@CURRMBR("Entity")), "Intercompany"))
    /* Parent entity is tagged as Intercompany */
ENDIF
```

---

## Practical Examples

### Example 1: Controllable vs. Non-Controllable Expenses

**Scenario**: Apply different budget rules based on whether an account is tagged as "Controllable."

```essbase
FIX("FY25", "Budget", @DESCENDANTS("Total_Expenses"))
    IF(@ISMBRUDA(@CURRMBR("Account"), "Controllable"))
        @CURRMBR("Account") = @CURRMBR("Account") -> "FY24" -> "Actual" * (1 + "Inflation_Rate");
    ELSE
        @CURRMBR("Account") = @CURRMBR("Account") -> "FY24" -> "Actual"; /* Fixed cost — no growth */
    ENDIF
ENDFIX
```

---

### Example 2: Intercompany Elimination

**Scenario**: Eliminate revenue for entities tagged with "Intercompany" UDA.

```essbase
FIX("FY24", "Actual", @DESCENDANTS("Total_Entity"))
    IF(@ISMBRUDA(@CURRMBR("Entity"), "Intercompany"))
        "IC_Elimination" = -1 * "Revenue";
    ENDIF
ENDFIX
```

---

### Example 3: Headcount-Driven Accounts

**Scenario**: Calculate compensation accounts that are tagged as "Headcount_Driver."

```essbase
FIX("FY25", "Budget", @DESCENDANTS("Total_Compensation"))
    IF(@ISMBRUDA(@CURRMBR("Account"), "Headcount_Driver"))
        @CURRMBR("Account") = "Headcount" * "Per_Head_Rate";
    ENDIF
ENDFIX
```

---

### Example 4: CAPEX vs. OPEX Treatment

**Scenario**: Apply different depreciation rules based on CAPEX/OPEX classification.

```essbase
FIX("FY24", @DESCENDANTS("Total_Accounts"))
    IF(@ISMBRUDA(@CURRMBR("Account"), "CAPEX"))
        "Depreciation" = @CURRMBR("Account") / "Useful_Life";
    ELSEIF(@ISMBRUDA(@CURRMBR("Account"), "OPEX"))
        "Depreciation" = 0; /* Fully expensed */
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Case mismatch | UDA comparison is case-sensitive | Ensure exact case match with the UDA defined in the outline |
| UDA not defined | If the UDA string doesn't exist in the outline, always returns FALSE | Verify UDA exists in the outline |
| Confusing with `@ISUDA` | `@ISUDA` checks the current member implicitly. `@ISMBRUDA` takes an explicit member. | Use `@ISMBRUDA` when checking a specific member; `@ISUDA` for current context |
| Confusing with `@ISATTRIBUTE` | Attributes and UDAs are different concepts. Attributes are dimension-based; UDAs are tags. | Use `@ISATTRIBUTE` for attribute dimensions; `@ISMBRUDA` for UDA tags |
| Spaces in UDA names | UDA names with spaces must match exactly, including spaces | Double-check the UDA string in the outline |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISUDA`](./@ISUDA.md) | Checks UDA on the current member (no explicit member parameter) |
| [`@UDA`](./@UDA.md) | Returns members that have a specific UDA — member set function |
| [`@ISATTRIBUTE`](./@ISATTRIBUTE.md) | Checks attribute dimension membership (different from UDA) |
| [`@ISMBRWITHATTR`](./@ISMBRWITHATTR.md) | Checks if a member has a specific attribute value |
| [`@ISMBR`](./@ISMBR.md) | Checks member identity — different from attribute checking |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ISMBRUDA](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/ismbruda.html)
- [Oracle Essbase Technical Reference — @ISMBRUDA](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calculation_function_reference.html)
