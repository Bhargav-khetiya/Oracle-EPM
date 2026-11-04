# @CalcMgrPadText

## Overview

`@CalcMgrPadText` is a **custom Calc Manager string manipulation function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as a structural formatting tool, taking a dynamically generated string and forcefully expanding it to a specific **total character length** by adding a repeating **pad character** to either the left or right side.

### Why Does This Function Exist—

When building flat-file exports for downstream ERP systems (like SAP or Oracle GL), those legacy systems often require strict "fixed-width" file formats. If the GL expects the Department ID to be exactly 10 characters long, and your Essbase department is only `"Sales"` (5 characters), the ERP system will reject the file unless you pad it with spaces to become `"Sales     "`.
Conversely, when constructing dynamic cross-dimensional target strings in Essbase, standard formatting matters. If you dynamically extract the month index `5` and try to build `"Period_5"`, but the database outline expects `"Period_05"`, the script will crash. 
`@CalcMgrPadText` solves both scenarios effortlessly. By defining the target length, the pad character (like `0` or ` `), and the direction (Left or Right), you guarantee that your strings will perfectly match the rigid dimensional structures required by EPM or external systems.

### When to Use It

- **Dynamic Member Construction**: Padding single-digit months (`5`) with a leading zero (`05`) so they can be concatenated into valid outline members (`"Period_05"`).
- **Fixed-Width File Exports**: Forcefully expanding short text accounts with trailing spaces so they align perfectly in a `.txt` data export.
- **Account Number Standardization**: Padding old legacy account numbers (e.g., `"123"`) with leading zeroes to match the new 6-digit corporate standard (`"000123"`).

---

## Category

**String / Text Manipulation & Formatting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrPadText(text, pad_length, pad_character, pad_direction)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be modified (e.g., `"5"` or `"Sales"`). |
| `pad_length` | Numeric | ✅ Yes | The **total target length** you want the final string to be (e.g., `2` or `10`). <br>*Note: This is NOT the number of characters to add. It is the total final length.* |
| `pad_character` | String | ✅ Yes | The specific character to use for padding (e.g., `"0"` or `" "`). |
| `pad_direction` | String | ✅ Yes | The direction to apply the padding. <br>Use `"l"` or `"L"` for Left padding (prefix). <br>Use `"r"` or `"R"` for Right padding (suffix). |

---

## Return Value

**Return Type**: String

Returns the fully padded text string.
- E.g., `PadText("5", 2, "0", "L")` returns `"05"`.
- **Overflow Protection**: If the original string is ALREADY longer than the `pad_length`, the function does NOT truncate the string. It safely ignores the pad request and returns the original string intact. (e.g., `PadText("123", 2, "0", "L")` returns `"123"`).

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the source string, length, character, and direction.
2. **Length Evaluation**: It checks the `length()` of the source string. If it is `>= pad_length`, it skips the operation.
3. **Delta Calculation**: It calculates how many characters are missing (e.g., `Target (10) - Current (5) = 5 missing`).
4. **Loop Injection**: It loops 5 times, concatenating the `pad_character` to either the Left or Right side of the string.
5. **Return**: Passes the finalized string back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Left-Padding with Zeros (Month Formatting)

```essbase
/* Turns "5" into "05". Turns "12" into "12". */
VAR vFormattedMonth = @CalcMgrPadText("5", 2, "0", "l");
```

### Variant 2: Right-Padding with Spaces (Fixed-Width Export)

```essbase
/* Turns "Sales" into "Sales     " (10 characters total) */
VAR vExportString = @CalcMgrPadText("Sales", 10, " ", "r");
```

---

## Practical Examples

### Example 1: Dynamic Rolling Forecast Member Generation

**Scenario**: A script uses `@CalcMgrGetMonth` to extract the current month integer (e.g., `5`). The administrator needs to dynamically copy data into `"Period_05"`. They cannot simply concatenate `"Period_"` with `"5"`, because `"Period_5"` doesn't exist in the outline. They must pad the integer with a leading zero first.

```essbase
FIX("FY25", "Working", @LEVEL0("Accounts"))
    
    /* 1. Extract the current month integer (e.g., 5) */
    VAR vMonthInt = @CalcMgrGetMonth(@CalcMgrGetCurrentDate());
    
    /* 2. Convert the pure integer into a raw string ("5") */
    VAR vMonthRawStr = @CalcMgrIntegerToString(vMonthInt);
    
    /* 
       3. Pad the string to ensure it is exactly 2 characters long.
       If it is "5", it becomes "05". 
       If it is "11", it safely remains "11".
    */
    VAR vMonthPaddedStr = @CalcMgrPadText(vMonthRawStr, 2, "0", "l");
    
    /* 4. Construct the target member ("Period_05") */
    VAR vTargetPeriod = @CONCATENATE("Period_", vMonthPaddedStr);
    
    /* 5. Execute the copy */
    FIX(@MEMBER(vTargetPeriod))
        "Forecast" = 1000;
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Misunderstanding Length | Expecting `PadText("5", 2...)` to return `"005"` | The `pad_length` parameter represents the **Total Final Length** of the string, NOT the number of zeroes you want to add. If you ask for length `2`, and the string is already `1` character long, it only adds `1` zero. If you want `"005"`, you must specify a total length of `3` |
| Passing Numbers | `@CalcMgrPadText(5, 2, ...)` | The first parameter must be a **Text String**. You cannot pad a raw mathematical number. You must use `@CalcMgrIntegerToString` first to convert the number into a string before passing it into this function |
| Wrong Direction Flag | Using `"left"` instead of `"l"` | The direction parameter strictly expects a single character: `"l"` or `"r"` (case-insensitive). If you pass the full word `"left"`, the Java engine will fail to parse the flag and the function will crash |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrFormatDouble`](./@CalcMgrFormatDouble.md) | A powerful alternative. If you are specifically formatting numbers (adding leading zeroes or decimals), `FormatDouble` is vastly superior because it handles the number-to-string conversion and the padding in a single step |
| [`@CONCATENATE`](../18_Range_Set_Operations/@CONCATENATE.md) | Used to join the newly padded string with other prefixes or suffixes |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_padtext.html)
