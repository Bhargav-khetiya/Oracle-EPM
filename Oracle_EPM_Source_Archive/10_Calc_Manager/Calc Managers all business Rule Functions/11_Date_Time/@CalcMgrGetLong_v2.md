# @CalcMgrGetLong

## Overview

`@CalcMgrGetLong` is a **custom Calc Manager numeric casting function** in Oracle EPM Cloud (PBCS/EPBCS). It takes a double-precision floating-point number (e.g., `14.95`) and violently **truncates** it into a pure **64-bit Long Integer** (e.g., `14`).

### Why Does This Function Exist—

In Java, standard `int` variables (32-bit integers) have a maximum mathematical limit of roughly `2.14 Billion`. If you try to cast `3,000,000,000` into a standard `int`, the system will trigger a catastrophic "Integer Overflow," flipping the number negative or crashing the calculation entirely.
While `@CalcMgrGetInteger` is perfectly fine for casting array indexes or dates (e.g., `20241231`), it cannot safely handle massive global enterprise identifiers, multi-billion-dollar global revenue checks, or nanosecond timestamps. 
To safely truncate massive numbers, you must cast them into a **Long Integer** (a 64-bit integer), which has a maximum limit of roughly `9 Quintillion`. `@CalcMgrGetLong` explicitly forces the Java engine to cast the double into a `long` primitive type, permanently deleting the fractional decimals while guaranteeing absolute mathematical safety for massive values.

### When to Use It

- **Massive Identifiers**: Stripping decimals off of dynamically generated 12-digit transaction IDs before pushing them to external ledgers.
- **High-Precision Timestamps**: Truncating raw Java millisecond timestamps (which are massive 13-digit integers) that accidentally acquired a decimal during Essbase floating-point operations.
- **Enterprise Scale Aggregations**: Preparing massive global revenue totals for exact integer-equality checks where standard 32-bit `GetInteger` would fail.

---

## Category

**Mathematical / Type Casting / Calc Manager Custom Functions**

---

## Syntax

```essbase
@CalcMgrGetLong(number)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `number` | Numeric | ✅ Yes | The double-precision floating-point number to be truncated (e.g., `3000000000.95`). |

---

## Return Value

**Return Type**: Numeric (Long Integer)

Returns a pure 64-bit integer.
- E.g., `3000000000.95` returns `3000000000`.
- **CRITICAL**: This function does **NOT** round. It simply truncates. If you pass `14.99`, it returns `14`. If you want rounding, you must use `@ROUND` first.

---

## How It Works (Behind the Scenes)

1. **Parameter Ingestion**: The Java engine receives the 64-bit double.
2. **Type Casting**: It executes a strict Java cast: `(long) number`. This physically strips the decimal payload from the binary memory address, while preserving the massive 64-bit memory space for the whole number.
3. **Return**: Passes the resulting 64-bit integer back to Essbase.

---

## Syntax Variants & Scenarios

### Variant 1: Pure Truncation of a Massive Number

```essbase
/* Forcefully truncates the decimal off a massive ID. Returns 4000000000. */
"Massive_Transaction_ID" = @CalcMgrGetLong(4000000000.99);
```

---

## Practical Examples

### Example 1: Dynamic Allocation of Multi-Billion Dollar Batches

**Scenario**: A massive global bank processes transaction volumes in the billions. The system loads `"Total_Transactions"` (e.g., `5,000,000,000`). The model needs to dynamically determine how many full batches of 1,000,000 were completed to apply processing fees. It divides `5B` by `1M` (resulting in `5000.5`), and then uses `GetLong` to safely strip the decimal without risking any integer overflow during intermediate calculations.

```essbase
FIX("FY25", "Working", @LEVEL0("Global_Regions"))
    
    IF("Total_Transactions" > 0)
        
        /* 
           1. Calculate the raw floating-point division.
        */
        VAR vRawBatches = "Total_Transactions" / 1000000;
        
        /* 
           2. Force the float into a strict LONG integer.
           This guarantees it strips the decimal safely, regardless of how 
           large the underlying array aggregations become.
        */
        VAR vCompletedBatches = @CalcMgrGetLong(vRawBatches);
        
        /* 
           3. Apply the fee.
        */
        "Total_Processing_Fees" = vCompletedBatches * 500;
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Expecting Rounding | Passing `4.9` and expecting `5` | `GetLong` performs absolute truncation. It simply deletes the decimal point and everything after it. `4.9` becomes `4`. `4.1` becomes `4`. If you need mathematical rounding, you MUST use `@ROUND(number, 0)` instead of this function |
| Defaulting to GetLong | Using it for small numbers like `15` | While `GetLong` will perfectly truncate the number `15.9` into `15`, it allocates 64 bits of memory to do so instead of 32 bits. If you are casting small numbers (like dates, month indexes, or array locations), it is generally more efficient to use standard `@CalcMgrGetInteger`. Reserve `GetLong` for massive enterprise metrics |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrGetLongFromString`](./@CalcMgrGetLongFromString.md) | Performs the same 64-bit integer casting, but takes a Text String (like `"3000000000"`) as the input rather than a float |
| [`@CalcMgrGetInteger`](./@CalcMgrGetInteger.md) | Casts the number into a standard 32-bit integer, which is faster and lighter but caps out at 2.14 billion |
| [`@ROUND`](../06_Mathematical/@ROUND.md) | Mathematically rounds a number up or down to the nearest integer, rather than violently truncating it |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_mgr_getlong.html)
