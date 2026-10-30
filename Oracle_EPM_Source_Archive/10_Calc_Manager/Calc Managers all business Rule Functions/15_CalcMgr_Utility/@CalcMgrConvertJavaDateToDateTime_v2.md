# @CalcMgrConvertJavaDateToDateTime

## Overview

`@CalcMgrConvertJavaDateToDateTime` is a **custom Calc Manager date conversion function** in Oracle EPM Cloud (PBCS/EPBCS). It takes an internal Java `Date` object (which intrinsically holds both calendar and time data) and converts it into a massive `YYYYMMDDHHMMSS` integer format, allowing you to store a highly precise timestamp inside a standard Essbase numeric data cell.

### Why Does This Function Exist?

Essbase standard integer dates are typically `YYYYMMDD` (e.g., `20241231`), which represents the day but drops any concept of time.
However, for detailed operational models (like IT Helpdesk SLA tracking, high-frequency logistics, or system audit trails), you need to know *exactly* when an event happened down to the second.
Because Essbase does not have a native "Timestamp" data type (it only stores floating-point numbers), developers must serialize timestamps into massive integers. 
`@CalcMgrConvertJavaDateToDateTime` takes a dynamic Java Date object and formats it into a 14-digit integer (`YYYYMMDDHHMMSS`), allowing you to store full datetime precision inside a numeric database block without losing the hours, minutes, or seconds.

### When to Use It

- To stamp database records with an exact "Last Modified" audit timestamp.
- When generating detailed SLA (Service Level Agreement) compliance metrics where hours and minutes matter.
- To store the exact time a user submitted a specific business rule.
- To normalize timestamps imported from external systems (via text strings) into a numeric format that can be easily exported or reported on.

---

## Category

**Date & Time / Type Conversion / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrConvertJavaDateToDateTime(javaDate)
```

### Formal Syntax

```
@CalcMgrConvertJavaDateToDateTime(javaDateExpression)
```

Where:
- `javaDateExpression` — A serialized Java Date object (often the output of another `@CalcMgr` date function or a Business Rule variable).

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `javaDate`| Java Date | ✅ Yes | The Java Date object you wish to convert to a full datetime integer. |

---

## Return Value

**Return Type**: Integer (`YYYYMMDDHHMMSS` format)

Returns a 14-digit integer representing the precise calendar date and time.
For example, `October 25, 2024 at 14:30:45` becomes `20241025143045`.

*(Note: Because this integer is 14 digits long, it approaches the limits of standard double-precision floating point accuracy. Ensure your target accounts are configured properly so Essbase doesn't round the final digits off).*

---

## How It Works (Behind the Scenes)

1. **Object Inspection**: The function receives the serialized Java Date object.
2. **De-serialization**: The Java engine unpacks the milliseconds into a true calendar array (Year, Month, Day, Hour, Minute, Second).
3. **Formatting**: It reformats all 6 components into a single contiguous string (`"20241025143045"`), enforcing 24-hour military time to prevent AM/PM ambiguity.
4. **Integer Casting**: It casts that string into a massive 14-digit mathematical integer and returns it to the Essbase calculation engine for storage in a data cell.

---

## Syntax Variants & Scenarios

### Variant 1: Direct Variable Conversion

```essbase
/* Assume vJavaDate is a previously initialized Date object with time components */
"Creation_Timestamp_Int" = @CalcMgrConvertJavaDateToDateTime(vJavaDate);
```

### Variant 2: Stamping Current Execution Time

```essbase
/* Grabs the exact moment the script executes and formats it to 14 digits */
"Audit_Last_Run" = @CalcMgrConvertJavaDateToDateTime(@CalcMgrGetCurrentDate());
```

---

## Practical Examples

### Example 1: Full Cycle String-to-Timestamp Transformation

**Scenario**: A logistics system sends over an exact delivery timestamp as a text string (e.g., `"2024-10-25 14:30:00"`). You need to store this in Essbase as a numeric timestamp so that Smart View reports can easily sort and filter the data numerically without dealing with string attributes.

```essbase
FIX("FY25", "Actual", @LEVEL0("Shipments"))
    
    /* 1. Extract the raw string timestamp from the cube attribute */
    VAR vDeliveryStr = @ATTRIBUTESVAL("Delivery_Time_Text");
    
    IF(vDeliveryStr != "")
        
        /* 2. Convert the string to a Java Date object so it is understood by the engine */
        VAR vDeliveryJava = @CalcMgrConvertDateTimeToJavaDate(vDeliveryStr, "yyyy-MM-dd HH:mm:ss");
        
        /* 3. Convert the Java Date object into the massive 14-digit integer for storage */
        "Delivery_Timestamp_Num" = @CalcMgrConvertJavaDateToDateTime(vDeliveryJava);
        
    ENDIF
    
ENDFIX
```

---

### Example 2: Audit Trail (Who Ran What and When)

**Scenario**: You have an allocations script. Management wants an audit trail proving exactly when the allocations were last generated for each department, down to the second.

```essbase
FIX("FY25", "Working", @LEVEL0("Department"))
    
    /* Execute the heavy allocation math */
    "Allocated_Expense" = "Corporate_Pool" * "Driver_Pct";
    
    /* Stamp the exact execution time into an audit account */
    "Allocation_Last_Run_Timestamp" = @CalcMgrConvertJavaDateToDateTime(@CalcMgrGetCurrentDate());
    
ENDFIX
```
*(If run on Nov 1st, 2024 at 9:15:30 AM, the account will store `20241101091530`).*

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Scientific Notation Issues | Smart View displays `2.02411E+13` | A 14-digit integer is massive. Excel and Smart View will often default to scientific notation to display it. You must explicitly format the cell in Excel as a "Number" with 0 decimal places to see the true timestamp |
| Using the wrong converter | Using `@CalcMgrConvertJavaDateToDate` by mistake | If you use the standard converter, the output is `20241101`. The hours, minutes, and seconds are permanently deleted. You must explicitly use the `...ToDateTime` variant to keep the time data |
| Passing Strings directly | `@CalcMgrConvertJavaDateToDateTime("2024-12-31 10:00:00")` | This will fail. You cannot skip the parsing step. You must use `@CalcMgrConvertDateTimeToJavaDate` first |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrConvertJavaDateToDate`](./@CalcMgrConvertJavaDateToDate.md) | The equivalent function to use if you *want* to strip off the hours and minutes and just keep `YYYYMMDD` |
| [`@CalcMgrConvertDateTimeToJavaDate`](./@CalcMgrConvertDateTimeToJavaDate.md) | The required predecessor function that parses strings into the Java Dates consumed by this function |
| [`@CalcMgrGetCurrentDate`](../11_Date_Time/@CalcMgrGetCurrentDate.md) | Generates the exact "now" object that is frequently fed into this conversion function for audit stamping |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_convertjavadatetodatetime.html)
