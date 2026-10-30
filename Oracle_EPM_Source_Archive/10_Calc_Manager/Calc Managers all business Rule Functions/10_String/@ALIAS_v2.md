# @ALIAS

## Overview

`@ALIAS` is a **member information function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **returns the alias (alternate name)** of a specified member. Every member in an Essbase outline has a unique member name, but it can also have one or more alias names stored in alias tables. `@ALIAS` retrieves these alias names.

### Why Does This Function Exist?

In EPM applications, member names are often technical codes (like `10100`, `ACCT_REV_001`, `E001`) while aliases are user-friendly labels (like `Cash`, `Total Revenue`, `New York Office`). `@ALIAS` bridges the gap between technical member names and human-readable labels, allowing you to:

- Display friendly names in reports and logs
- Build dynamic strings for messaging or logging
- Compare alias values in conditional logic
- Create user-facing output that references descriptive names

### When to Use It

- When constructing log messages or error messages that need human-readable member names
- In `@CONCATENATE` operations to build descriptive strings
- When comparing member aliases for conditional logic
- In conjunction with `@CalcMgrConcat` for building dynamic text output

---

## Category

**Member Information / String**

---

## Syntax

```essbase
@ALIAS(member [, aliasTableName])
```

### Formal Syntax Variants

```
@ALIAS(memberExpression)
@ALIAS(memberExpression, "aliasTableName")
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `member` | Member name or member expression | ✅ Yes | The member whose alias you want to retrieve. Can be a literal member name, `@CURRMBR`, or another member-resolving function. |
| `aliasTableName` | String | ❌ No | The name of the alias table to look up. If omitted, the **Default** alias table is used. PBCS/EPBCS applications typically use the "Default" alias table, but you can have multiple alias tables. |

---

## Return Value

| Condition | Returns |
|-----------|---------|
| Member has an alias in the specified table | The alias string |
| Member has no alias in the specified table | The member name itself |
| Invalid member | Error |

**Return Type**: String

---

## How It Works (Behind the Scenes)

1. **Alias Table Lookup**: Every Essbase cube maintains one or more alias tables. When you call `@ALIAS`, Essbase looks up the member in the specified (or default) alias table and returns the corresponding alias string.

2. **Default Alias Table**: If you don't specify an alias table, Essbase uses the "Default" alias table. In PBCS/EPBCS, the Default table is the most commonly used one.

3. **No Alias Fallback**: If the member doesn't have an alias in the specified table, `@ALIAS` returns the member's actual name — it does NOT return `#MISSING` or throw an error.

4. **String Context**: `@ALIAS` returns a string, which means it cannot be used directly in numeric calculations. Use it within string functions like `@CONCATENATE`, `@CalcMgrConcat`, or in conditional comparisons.

5. **Dimension Consideration**: `@ALIAS` works across all dimensions — Account, Entity, Period, Scenario, Version, and any custom dimensions.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Alias Lookup

```essbase
@ALIAS("10100")
```
Returns the alias for member `10100` (e.g., `"Cash"`).

### Variant 2: With Specific Alias Table

```essbase
@ALIAS("10100", "Long Names")
```
Returns the alias from the "Long Names" alias table.

### Variant 3: Dynamic Member with @CURRMBR

```essbase
@ALIAS(@CURRMBR("Account"))
```
Returns the alias of the current Account dimension member being processed (used inside loops or FIX blocks).

### Variant 4: Inside String Concatenation

```essbase
@CONCATENATE("Processing: ", @ALIAS(@CURRMBR("Entity")))
```
Builds a string like `"Processing: New York Office"`.

---

## Practical Examples

### Example 1: Logging Current Member Aliases

**Scenario**: Log the alias of each entity being processed for debugging.

```essbase
FIX("Actual", "FY24", "Jan")
    @DESCENDANTS("Total_Entity")(
        @CalcMgrLogStrings(@ALIAS(@CURRMBR("Entity")));
    )
ENDFIX
```

**Output in Log**:
```
New York Office
London Branch
Tokyo Regional
Sydney Operations
```

---

### Example 2: Conditional Logic Based on Alias

**Scenario**: Apply different calculation logic based on the alias of the current account.

```essbase
FIX("Actual", "FY24")
    @DESCENDANTS("Total_Accounts")(
        /* Compare the alias of the current account */
        IF(@MBRCOMPARE("EQUAL", @ALIAS(@CURRMBR("Account")), "Revenue"))
            "Growth_Rate" = 1.05;
        ELSEIF(@MBRCOMPARE("EQUAL", @ALIAS(@CURRMBR("Account")), "Expenses"))
            "Growth_Rate" = 1.03;
        ENDIF
    )
ENDFIX
```

---

### Example 3: Building User-Facing Messages

**Scenario**: Display a formatted message using @HspMessage with alias names.

```essbase
FIX("Actual", "FY24")
    @DESCENDANTS("Total_Entity")(
        IF("Revenue" > 1000000)
            @HspMessage(@CalcMgrConcat("High revenue alert for: ", @ALIAS(@CURRMBR("Entity"))));
        ENDIF
    )
ENDFIX
```

---

### Example 4: Using Multiple Alias Tables

**Scenario**: Retrieve aliases from different tables for different purposes.

```essbase
/* Get short name from Default table */
VAR shortName = @ALIAS("E001");

/* Get full description from "Long Names" table */
VAR longName = @ALIAS("E001", "Long Names");

@CalcMgrLogStrings(@CalcMgrConcat("Short: ", shortName, " | Long: ", longName));
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Using @ALIAS in arithmetic | `@ALIAS` returns a string, not a number — you can't add or multiply it | Use `@ALIAS` only in string contexts |
| Assuming all members have aliases | Not all members may have aliases defined | `@ALIAS` gracefully returns the member name if no alias exists |
| Case sensitivity in alias table names | Alias table names are case-sensitive | Use the exact case as defined in the application |
| Using in member set functions | `@ALIAS` returns a string, not a member reference — it can't be used where a member is expected | Use `@MEMBER` if you need to resolve a string to a member |
| Performance in large loops | Calling `@ALIAS` in tight loops over many members can add overhead | Minimize calls; cache in variables if reused |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@NAME`](@NAME.md) | Returns the member name (not the alias) |
| [`@CURRMBR`](../04_Member_Navigation/@CURRMBR.md) | Returns the current member — often used as input to @ALIAS |
| [`@CONCATENATE`](../18_Range_Set_Operations/@CONCATENATE.md) | String concatenation — used with @ALIAS to build strings |
| [`@MEMBER`](../04_Member_Navigation/@MEMBER.md) | Resolves a string to a member — inverse concept |
| [`@MBRCOMPARE`](@MBRCOMPARE.md) | Compares member properties — can compare aliases |
| [`@CalcMgrConcat`](../15_CalcMgr_Utility/@CalcMgrConcat.md) | Calc Manager string concatenation — modern alternative |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @ALIAS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/alias.html)
- [Oracle Essbase Technical Reference — Member Information Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/member_information_functions.html)
