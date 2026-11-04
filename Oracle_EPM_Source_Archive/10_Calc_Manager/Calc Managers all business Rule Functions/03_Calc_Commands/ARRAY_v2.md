# ARRAY

## Overview

`ARRAY` declares an **array variable** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager, allowing you to store **multiple indexed values** in a single variable. Arrays are useful for lookup tables, coefficient storage, and multi-value operations within calc scripts.

### Why Does This Command Exist—

Some calculations require storing and accessing multiple related values:
- Monthly growth rates that vary by period
- Regional tax rates for allocation calculations
- Coefficient tables for statistical models
- Temporary storage for multi-step calculations
- Mapping tables for account conversions

Without arrays, you'd need individual VAR declarations for each value, making code verbose and hard to maintain.

### When to Use It

- When you need a lookup table of values indexed by position
- When storing coefficients or rates that vary by iteration
- When implementing a simple mapping or translation table
- When you need temporary multi-value storage in a calc script
- When building custom interpolation or trending calculations

---

## Category

**Calc Script Command / Variable / Array**

---

## Syntax

```essbase
ARRAY varName[size];
ARRAY varName[size] = {val1, val2, ...};
```

### Formal Syntax

```
ARRAY arrayName[dimensions] [= {initializerList}];
```

Where:
- `arrayName` — User-defined name for the array, following standard naming rules
- `dimensions` — The size of the array (number of elements)
- `initializerList` — Optional comma-separated initial values enclosed in braces

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `arrayName` | Identifier | ✅ Yes | The name of the array. Must start with a letter or underscore. Convention: prefix with `a` (e.g., `aRates`, `aWeights`). |
| `size` | Integer | ✅ Yes | The number of elements in the array. Array indices are zero-based (0 to size-1) or one-based depending on Essbase version. |
| `initialValues` | Numeric list | ❌ No | Optional initial values in braces. Number of values should match the array size. |

---

## Return Value

`ARRAY` does not return a value — it **declares and optionally initializes** an array variable.

---

## How It Works (Behind the Scenes)

1. **Memory Allocation**: ARRAY allocates memory for the specified number of elements. Each element is a double-precision floating-point number.

2. **Indexing**: Elements are accessed by index: `arrayName[0]`, `arrayName[1]`, etc. Index bounds are enforced — accessing outside the array size causes an error.

3. **Scope**: Like VAR, arrays are local to the current calc script execution. They don't persist across rule executions.

4. **Initialization**: If not explicitly initialized, array elements default to 0 (not #MISSING). Use the initializer list `= {...}` to set specific values.

5. **Performance**: Arrays are stored in memory and accessed very quickly. They're useful for avoiding repeated data lookups.

6. **Limitations**: Arrays are one-dimensional. For multi-dimensional lookups, use nested IF/ELSEIF logic or multiple arrays.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Declaration

```essbase
ARRAY aRates[12];
```
Declares a 12-element array (one per month).

### Variant 2: Declaration with Initialization

```essbase
ARRAY aGrowth[4] = {0.08, 0.06, 0.10, 0.04};
```
Q1=8%, Q2=6%, Q3=10%, Q4=4% growth rates.

### Variant 3: Assigning Values Individually

```essbase
ARRAY aWeights[3];
aWeights[0] = 0.50;
aWeights[1] = 0.30;
aWeights[2] = 0.20;
```

### Variant 4: Using Array in Calculations

```essbase
ARRAY aTaxRates[3] = {0.21, 0.25, 0.30};

IF(@UDA("Entity", "Americas"))
    "Tax" = "PreTax" * aTaxRates[0];
ELSEIF(@UDA("Entity", "EMEA"))
    "Tax" = "PreTax" * aTaxRates[1];
ELSE
    "Tax" = "PreTax" * aTaxRates[2];
ENDIF
```

---

## Practical Examples

### Example 1: Monthly Seasonal Factors

**Scenario**: Apply different seasonal adjustment factors for each month.

```essbase
ARRAY aSeasonalFactor[12] = {0.85, 0.88, 0.95, 1.00, 1.05, 1.10, 1.15, 1.12, 1.08, 1.00, 0.92, 0.90};

FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    IF(@ISMBR("Jan"))
        Revenue = "Base_Revenue" * aSeasonalFactor[0];
    ELSEIF(@ISMBR("Feb"))
        Revenue = "Base_Revenue" * aSeasonalFactor[1];
    ELSEIF(@ISMBR("Mar"))
        Revenue = "Base_Revenue" * aSeasonalFactor[2];
    /* ... continue for each month ... */
    ENDIF
ENDFIX
```

**What Happens**:
- Each month gets a different seasonal multiplier from the array
- January at 85%, June peaks at 110%, December at 90%
- Base revenue is scaled by the seasonal pattern

---

### Example 2: Tiered Rate Table

```essbase
ARRAY aThresholds[3] = {100000, 500000, 1000000};
ARRAY aRates[4] = {0.05, 0.08, 0.12, 0.15};

FIX("FY25", "Working", @DESCENDANTS("Sales Team"))
    IF(Revenue >= aThresholds[2])
        "Commission" = Revenue * aRates[3];
    ELSEIF(Revenue >= aThresholds[1])
        "Commission" = Revenue * aRates[2];
    ELSEIF(Revenue >= aThresholds[0])
        "Commission" = Revenue * aRates[1];
    ELSE
        "Commission" = Revenue * aRates[0];
    ENDIF
ENDFIX
```

---

### Example 3: Weighted Average Calculation

```essbase
ARRAY aWeights[3] = {0.60, 0.30, 0.10};

FIX("FY25", "Working")
    "Weighted_Score" = ("Current_Score" * aWeights[0]) +
                       ("Prior_Score" * aWeights[1]) +
                       ("Two_Year_Score" * aWeights[2]);
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Index out of bounds | Accessing `aRates[5]` in a size-4 array causes error | Always check: valid indices are 0 to (size-1) |
| Wrong element count in initializer | `ARRAY a[3] = {1,2,3,4}` — mismatch | Match initializer count to array size |
| Using array for member iteration | Arrays don't iterate over members | Use FIX with member functions for member iteration |
| Assuming arrays are two-dimensional | Essbase arrays are one-dimensional only | Use multiple arrays or nested IF for multi-dim lookups |
| Forgetting zero-based indexing | First element is `[0]`, not `[1]` | Remember: `ARRAY a[3]` → valid indices: 0, 1, 2 |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`VAR`](./VAR.md) | Single value variable — simpler than ARRAY |
| [`ACCUMULATEVAR`](./ACCUMULATEVAR.md) | Accumulate variable values |
| [`IF`](../01_Flow_Control/IF.md) | Used with arrays for index-based branching |
| [`LOOP`](../01_Flow_Control/LOOP.md) | Can iterate through array elements |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ARRAY](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/array.html)
