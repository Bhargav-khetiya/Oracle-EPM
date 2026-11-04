# @CalcMgrTrim

## Overview

`@CalcMgrTrim` is a **custom Calc Manager string cleansing function** in Oracle EPM Cloud (PBCS/EPBCS). It acts as an invisible character scrubber. It takes a text string and systematically **removes all leading (front) and trailing (back) white space characters**, returning a perfectly clean, tightened string.

### Why Does This Function Exist—

Invisible whitespace is one of the most common causes of silent calculation failures in EPM. If an automated flat-file integration loads data using fixed-width text columns, a department name might be loaded into Essbase as `" Sales    "`. 
To the human eye on a report, it looks fine. But if a calculation script reads that string and attempts to map data to `@MEMBER("Sales")`, Essbase will crash with an "Unknown Member" error, because `" Sales    "` does not match `"Sales"`. 
`@CalcMgrTrim` solves this instantly. By wrapping the string in this function, the Java engine snips off the invisible leading space, snips off the four trailing spaces, and returns `"Sales"`. This guarantees that string comparisons, member generations, and text length evaluations execute flawlessly regardless of how dirty the source data is.

### When to Use It

- **Data Integration Cleansing**: Scrubbing imported text fields (like Product IDs or Employee Names) to ensure rogue spaces don't ruin database matching logic.
- **Smart View Form Protection**: Trimming runtime prompt text entered by users, as users frequently accidentally hit the spacebar after typing a word.
- **Preparation for Length Evaluation**: Ensuring that `"Hello "` is evaluated as having exactly 5 characters by `@CalcMgrTextLength`, rather than 6.

---

## Category

**String / Text Manipulation & Cleansing / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrTrim(text)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | ✅ Yes | The source string to be cleansed (e.g., `"   Data   "`). |

---

## Return Value

**Return Type**: String

Returns a fully cleansed string with all leading and trailing whitespace deleted.
- **Internal Spaces Preserved**: This function ONLY targets the perimeter of the string. It explicitly preserves any spaces that exist *between* words. 
- E.g., `"  New York  "` becomes `"New York"`.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the text string.
2. **Execution**: It executes the native Java `String.trim()` method.
3. **Array Scanning**: 
   - It scans from Index `0` forward, deleting any character whose ASCII value is `<= 32` (Space, Tab, Carriage Return, Line Feed) until it hits a standard printable character.
   - It then scans from the end of the string backward, doing the same thing.
4. **Return**: It returns the cleanly trimmed string back to Essbase memory.

---

## Syntax Variants & Scenarios

### Variant 1: Cleansing User Inputs

```essbase
/* 
   Assumes a user typed " Q1_Actuals " into a prompt.
   Result: "Q1_Actuals"
*/
VAR vCleanPrompt = @CalcMgrTrim({Target_Version});
```

---

## Practical Examples

### Example 1: Dynamic Member Construction from Dirty Data

**Scenario**: A business rule reads an account called `"Imported_Location"`. The data was imported from a legacy ERP system that uses fixed-width columns, meaning every location is padded with random spaces (e.g., `"   Boston   "`). The script must cleanse the string and use it to cross-dimensionally map data to the physical Location dimension.

```essbase
FIX("FY25", "Working", @LEVEL0("Staging"))
    
    IF(@ISMBR(@LIST("Imported_Location")))
        
        /* 
           1. Scrub the perimeter of the string.
           "   Boston   " instantly becomes "Boston".
        */
        VAR vCleanLocation = @CalcMgrTrim("Imported_Location");
        
        /* 
           2. Validate that the cleansed string matches a real member in the outline.
        */
        IF(@CalcMgrIsValidMember(vCleanLocation))
            
            /* 
               3. Execute the data push. 
               (If we hadn't trimmed, this block would fail).
            */
            FIX(@MEMBER(vCleanLocation))
                "Staging_Value" = "Local_Value";
            ENDFIX
            
        ENDIF
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Internal Cleansing | `"Sales Dept"` | If a user accidentally types `"Sales  Dept"` (two spaces in the middle), `Trim` will do absolutely nothing, because the spaces are trapped between valid characters. If you need to fix internal spacing anomalies, you must use `@CalcMgrReplaceAll(text, "  ", " ")` |
| Attempting to Cleanse Numbers | `@CalcMgrTrim(10050)` | This function strictly requires a text string. If you pass a numeric Essbase account into it, the Java engine will crash. Numbers in Essbase blocks do not have "spaces" attached to them, so trimming is unnecessary |
| Hardcoded Tab Characters | Trimming Unicode Non-Breaking Spaces | The standard Java `trim()` method only targets ASCII characters `<= 32`. If the imported string contains advanced Unicode non-breaking spaces (HTML `&nbsp;`), `Trim` will not recognize them and will leave them intact. In those rare scenarios, you must use `@CalcMgrReplaceRegex` to scrub whitespace classes |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrReplaceAll`](./@CalcMgrReplaceAll.md) | Used to remove or replace spaces that exist *inside* the string, which `Trim` ignores |
| [`@CalcMgrPadText`](./@CalcMgrPadText.md) | The exact opposite function. It is used to intentionally add spaces to a string to meet fixed-width export requirements |
| [`@CalcMgrTextLength`](./@CalcMgrTextLength.md) | Should almost always be executed AFTER a `Trim` to ensure you are measuring real characters, not invisible spaces |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_trim.html)
