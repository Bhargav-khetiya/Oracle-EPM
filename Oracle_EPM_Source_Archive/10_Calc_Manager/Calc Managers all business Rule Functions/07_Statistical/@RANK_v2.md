# @RANK

## Overview

`@RANK` is a **statistical function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns the **rank** (position) of a specific value within a specified set of values. It is commonly used for performance comparisons, tiering, and sorting members based on their data values.

### Why Does This Function Exist—

Business analysis frequently relies on ranking to identify top and bottom performers:
- Ranking sales regions from highest revenue to lowest.
- Tiering products into quartiles or deciles based on volume.
- Identifying the top 10 most profitable customers for targeted marketing.
- Building bonus calculations where payout depends on relative performance (e.g., top 3 regions get a multiplier).

### When to Use It

- To assign a ranking number (1, 2, 3...) to members based on a measure.
- When applying tiered logic (e.g., "If Rank <= 5, then...").
- In reporting cubes to provide a dynamic "Rank" metric alongside actual values.

---

## Category

**Statistical / Ranking**

---

## Syntax

```essbase
@RANK(value, rangeList [, ASC | DESC] [, SKIPNONE | SKIPMISSING | SKIPZERO | SKIPBOTH])
```

### Formal Syntax

```
@RANK(valueExpression, memberRange, [sortOrder], [skipOption])
```

Where:
- `valueExpression` — The specific value to be ranked (usually a member or `@CURRMBR` reference).
- `memberRange` — The list of members to rank against (e.g., `@CHILDREN("Total Entity")`).
- `sortOrder` — (Optional) `DESC` (default, highest value = rank 1) or `ASC` (lowest value = rank 1).
- `skipOption` — (Optional) How to handle missing/zero values. Default is `SKIPNONE`.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | Numeric/Member | ✅ Yes | The value to find the rank for. Usually, this is the measure you are evaluating, e.g., `"Revenue"`. |
| `rangeList` | Member list | ✅ Yes | The group of members to compare the value against. E.g., `@SIBLINGS(@CURRMBR("Entity"))` or `@CHILDREN("North_America")`. |
| `sortOrder` | Keyword | ❌ No | `DESC` (descending, highest = 1) or `ASC` (ascending, lowest = 1). Defaults to `DESC`. |
| `skipOption`| Keyword | ❌ No | `SKIPNONE` (default, missing treated as 0), `SKIPMISSING` (ignores missing values in ranking), `SKIPZERO` (ignores zeros), `SKIPBOTH` (ignores both). |

---

## Return Value

**Return Type**: Numeric (Integer)

Returns an integer representing the rank of the value within the range. 
- If multiple members have the exact same value, they receive the same rank (a tie), and the next value receives the subsequent rank (e.g., 1, 2, 2, 4).
- If the value is skipped based on `skipOption`, it returns `#MISSING`.

---

## How It Works (Behind the Scenes)

1. **Array Construction**: `@RANK` collects all the values for the members defined in the `rangeList`.
2. **Filtering**: It removes any values specified by the `skipOption` (e.g., throwing out `#MISSING` or `0`).
3. **Sorting**: It sorts the remaining array internally based on the `sortOrder`.
4. **Ranking**: It compares the `value` parameter against this sorted array and returns its 1-based index position.

---

## Syntax Variants & Scenarios

### Variant 1: Basic Descending Rank (Top Performer = 1)

```essbase
"Sales_Rank" = @RANK(Revenue, @CHILDREN("Total Entity"));
/* Defaults to DESC, SKIPNONE */
```

### Variant 2: Ascending Rank (Lowest Expense = 1)

```essbase
"Expense_Rank" = @RANK("OpEx", @CHILDREN("Total Entity"), ASC);
```

### Variant 3: Ignoring Missing and Zero Data

```essbase
"Profit_Rank" = @RANK("Net_Income", @CHILDREN("Total Entity"), DESC, SKIPBOTH);
```

---

## Practical Examples

### Example 1: Ranking Sales Regions

**Scenario**: Rank the performance of all regions under "Total Geography" based on Revenue.

```essbase
FIX("FY25", "Working", @CHILDREN("Total Geography"))
    "Revenue_Rank" = @RANK(Revenue, @CHILDREN("Total Geography"), DESC, SKIPBOTH);
ENDFIX
```

**What Happens**: 
- If NA=100, EU=150, APAC=80:
  - EU Rank = 1
  - NA Rank = 2
  - APAC Rank = 3

---

### Example 2: Tiered Bonus Multiplier

**Scenario**: The top 3 performing sales reps get a 1.5x bonus multiplier.

```essbase
FIX("FY25", "Working", @CHILDREN("Sales_Reps"))
    VAR vRank = @RANK("Sales", @CHILDREN("Sales_Reps"), DESC, SKIPMISSING);
    
    IF(vRank > 0 AND vRank <= 3)
        "Bonus_Multiplier" = 1.5;
    ELSE
        "Bonus_Multiplier" = 1.0;
    ENDIF
ENDFIX
```

---

### Example 3: Percentile / Quartile Tiering

**Scenario**: Place entities into Quartiles based on their rank.

```essbase
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    VAR vRank = @RANK(Revenue, @CHILDREN("Total Entity"), DESC, SKIPBOTH);
    VAR vTotalCount = @COUNT(SKIPBOTH, @CHILDREN("Total Entity"));
    
    IF(vRank > 0 AND vTotalCount > 0)
        VAR vPercentile = vRank / vTotalCount;
        
        IF(vPercentile <= 0.25)
            "Quartile" = 1; /* Top 25% */
        ELSEIF(vPercentile <= 0.50)
            "Quartile" = 2;
        ELSEIF(vPercentile <= 0.75)
            "Quartile" = 3;
        ELSE
            "Quartile" = 4;
        ENDIF
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not handling `#MISSING` | Default is `SKIPNONE`, so missing values are treated as zero and will be ranked at the bottom | Use `SKIPMISSING` or `SKIPBOTH` to exclude inactive members from the ranking pool |
| Ranking across levels | `@RANK(Rev, @DESCENDANTS("Entity"))` mixes parents and children, meaning parents will always take the top ranks | Only rank peers against peers: use `@CHILDREN` or `@SIBLINGS` |
| Overwriting during calc | If you rank based on a measure that is currently being calculated, the array may be unstable | Rank based on fully calculated/aggregated source measures |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@COUNT`](../06_Mathematical/@COUNT.md) | Useful for finding the total number of members to calculate percentiles |
| [`@MAX`](../06_Mathematical/@MAX.md) | Finds the #1 ranked value |
| [`@MIN`](../06_Mathematical/@MIN.md) | Finds the last ranked value |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @RANK](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/rank.html)
