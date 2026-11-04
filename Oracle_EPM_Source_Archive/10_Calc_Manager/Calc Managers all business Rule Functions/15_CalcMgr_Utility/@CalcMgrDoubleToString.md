# @CalcMgrDoubleToString

## Overview

`@CalcMgrDoubleToString` is a **custom Calc Manager string conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a raw mathematical number (e.g., `1234.56`) and converts it directly into a literal Text String (`"1234.56"`).

### Why Does This Function Exist—

Essbase natively handles numbers perfectly. However, the Calc Manager Custom Function library allows you to perform advanced string manipulation—building dynamic URLs, assembling email logs, concatenating dynamic member names, or appending flags to text memory buckets.
The string concatenation engine (`@CalcMgrConcat`) strictly requires Text Strings. If you try to concatenate the word `"Exception_Amount_"` with the raw numeric value `500` directly, the engine will crash because it does not know how to merge text and math.
`@CalcMgrDoubleToString` safely strips the mathematical properties away from the number, freezing the digits into a literal text string that can be freely appended, logged, or exported.

### When to Use It

- When appending a calculated numeric result into a human-readable audit log or error message.
- When dynamically constructing a member name that requires a number (e.g., concatenating `"Tier_"` with the number `1` to target `"Tier_1"`).
- When passing numeric data out of an Essbase block and into a Groovy script expecting a string payload.

---

## Category

**String / Type Conversion / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrDoubleToString(value)
```

### Formal Syntax

```
@CalcMgrDoubleToString(numericExpression)
```

Where:
- `numericExpression` — The raw number or data account you want to convert to text.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value`   | Numeric| ✅ Yes | The number to convert. Can be a hardcoded number (`150`), a variable, or a pointer to a numeric Essbase account. |

---

## Return Value

**Return Type**: String

Returns a literal text string representing the exact digits of the number.
*(Note: Because Essbase natively uses double-precision floating-point numbers, an integer like `15` will frequently be converted into the string `"15.0"`. See the Gotchas section).*

---

## How It Works (Behind the Scenes)

1. **Extraction**: The function retrieves the raw floating-point number from the Essbase engine.
2. **Java Casting**: It passes the number into the Java `Double.toString()` method.
3. **Rendering**: Java converts the numeric value into an array of characters.
4. **Return Generation**: It returns the resulting text string to the Essbase calculation engine, typically to be assigned to a `VAR` for concatenation.

---

## Syntax Variants & Scenarios

### Variant 1: Converting an Account Value

```essbase
/* Assuming "Exception_Value" is 500, this returns the string "500.0" */
VAR vNumberAsText = @CalcMgrDoubleToString("Exception_Value");
```

### Variant 2: Immediate Concatenation

```essbase
/* Yields "Threshold is 1000.0" */
VAR vLog = @CalcMgrConcat("Threshold is ", @CalcMgrDoubleToString(1000));
```

---

## Practical Examples

### Example 1: Building a Dynamic Target Member Name

**Scenario**: You have an allocations script. Entities are assigned a specific "Tier" level from 1 to 5. The Tier is stored as a number in a data account called `"Assigned_Tier"`. You need to calculate the allocation by multiplying the entity's revenue by a specific rate stored in members named `"Rate_Tier_1"`, `"Rate_Tier_2"`, etc. You must convert the numeric tier into a string to build the member name.

```essbase
FIX("FY25", "Working", @LEVEL0("Entity"))
    
    /* 1. Check if the entity has an assigned tier (e.g., the number 3) */
    IF("Assigned_Tier" != #MISSING)
        
        /* 2. Convert the number 3 to the string "3" */
        /* Note: We wrap it in @TRUNC to ensure it is exactly 3, not 3.1415, 
           though Essbase handles integers fairly well here. */
        VAR vTierStr = @CalcMgrDoubleToString(@TRUNC("Assigned_Tier"));
        
        /* 3. Build the target string: "Rate_Tier_3" */
        VAR vTargetName = @CalcMgrConcat("Rate_Tier_", vTierStr);
        
        /* 4. Use @MEMBER to point the calculation to the dynamic rate */
        "Allocation_Expense" = "Revenue" * @MEMBER(vTargetName);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Creating a Detailed Error Log

**Scenario**: If an account goes negative, you want to log the exact dollar amount of the violation into a memory bucket so it can be emailed out by the system administrator.

```essbase
FIX("FY25", "Working", @LEVEL0("CostCenter"))
    
    IF("Net_Cash" < 0)
        
        /* 1. Convert the numeric cash shortfall to a string */
        VAR vCashStr = @CalcMgrDoubleToString("Net_Cash");
        
        /* 2. Build the log: "CostCenter violated cash minimum by: -15000.0" */
        VAR vCCName = @NAME(@CURRMBR("CostCenter"));
        VAR vPart1 = @CalcMgrConcat(vCCName, " violated cash minimum by: ");
        VAR vFinalLog = @CalcMgrConcat(vPart1, vCashStr);
        
        /* 3. Append to the global log (adding a comma for readability) */
        VAR vDummy = @CalcMgrCounterAddText("Cash_Violations", @CalcMgrConcat(vFinalLog, ", "));
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| The `.0` Decimal Artifact | `DoubleToString(15)` outputs `"15.0"` | Because Essbase treats all numbers as doubles, Java's `Double.toString()` often automatically appends a `.0` to whole integers. If you are building member names (e.g., trying to build `"Tier_1"` but getting `"Tier_1.0"`), this will break your script. You must either truncate it carefully, or better yet, use `@CalcMgrDecimalFormat` to enforce zero decimal places |
| Ugly Output | `"Your revenue is 15000000.4533221"` | This function performs a brute-force conversion of the raw digits. It does not add commas, currency symbols, or round the decimals nicely. If you are preparing a log for human eyes, you should almost always use `@CalcMgrDecimalFormat(value, "#,##0.00")` instead |
| Trying to do math with the result | `vString * 1.5` | The output is a String. Essbase cannot multiply a text string. Conversion to string should be the final step before logging or concatenation |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrDoubleFromString`](./@CalcMgrDoubleFromString.md) | The exact reverse operation (takes a text string containing digits and converts it into a raw number for math) |
| [`@CalcMgrDecimalFormat`](./@CalcMgrDecimalFormat.md) | The superior alternative to this function if you care about how the number *looks* (allows commas, rounding, and prefixes) |
| [`@CalcMgrConcat`](./@CalcMgrConcat.md) | The most common destination for the string output of this function |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_doubletostring.html)
