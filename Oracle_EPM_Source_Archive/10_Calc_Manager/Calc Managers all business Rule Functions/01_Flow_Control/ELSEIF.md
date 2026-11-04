# ELSEIF

## Overview

`ELSEIF` adds **additional conditional branches** to an `IF` block in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. It provides a clean way to test multiple conditions sequentially without nesting multiple IF/ENDIF blocks. When the preceding IF (or ELSEIF) condition is FALSE, the next ELSEIF condition is evaluated.

### Why Does This Command Exist—

Many business rules require more than two outcomes:
- Tiered commission rates based on achievement levels
- Different tax rates for different regions
- Multiple risk categories based on variance thresholds
- Growth rate buckets based on performance tiers

Without ELSEIF, you'd need deeply nested IF/ELSE/IF/ELSE/ENDIF/ENDIF chains, which are hard to read, maintain, and debug.

### When to Use It

- When you have 3+ mutually exclusive conditions to check
- When you want to avoid deep nesting of IF blocks
- When implementing tiered logic (ranges, brackets, categories)
- When mapping members to different calculations based on attributes

---

## Category

**Calc Script Command / Flow Control / Conditional**

---

## Syntax

```essbase
IF(condition1)
    /* statements for condition1 */
ELSEIF(condition2)
    /* statements for condition2 */
ELSEIF(condition3)
    /* statements for condition3 */
ELSE
    /* default statements */
ENDIF
```

### Formal Syntax

```
IF(booleanExpression)
    calcStatements
ELSEIF(booleanExpression)
    calcStatements
[ELSEIF(booleanExpression)
    calcStatements]...
[ELSE
    calcStatements]
ENDIF
```

Where:
- Multiple ELSEIF branches can be chained
- Each ELSEIF has its own condition in parentheses
- Conditions are evaluated top-to-bottom — first TRUE wins
- ELSE (optional) follows ALL ELSEIF branches as the final fallback

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `condition` | Boolean expression | ✅ Yes | A Boolean expression that evaluates to TRUE or FALSE. Same syntax as IF conditions — supports comparison operators, Boolean functions, compound expressions with AND/OR/NOT. |

---

## Return Value

`ELSEIF` does not return a value — it defines a **conditional branch point**.

---

## How It Works (Behind the Scenes)

1. **Sequential Evaluation**: ELSEIF conditions are evaluated in order, top to bottom. The first TRUE condition wins — its block executes and ALL subsequent ELSEIF/ELSE blocks are skipped.

2. **Mutual Exclusivity**: Only ONE branch in an IF/ELSEIF/ELSE chain executes per cell. This is guaranteed — you never have two branches running for the same cell.

3. **Short-Circuit**: If the IF condition is TRUE, no ELSEIF conditions are even evaluated. This can be important for performance when you have expensive function calls in conditions.

4. **No Limit**: There is no hard limit on the number of ELSEIF branches, but for readability, more than 5-6 becomes unwieldy. Consider alternative designs (substitution variables, member formulas) for very many branches.

5. **Performance**: Each ELSEIF adds one more condition evaluation per cell. For large datasets, keeping the most common (TRUE) condition first improves performance since subsequent checks are skipped.

---

## Syntax Variants & Scenarios

### Variant 1: Three-Way Branch

```essbase
IF(Revenue > 1000000)
    "Segment" = 3;  /* Enterprise */
ELSEIF(Revenue > 100000)
    "Segment" = 2;  /* Mid-Market */
ELSE
    "Segment" = 1;  /* SMB */
ENDIF
```

### Variant 2: Member-Based Branching

```essbase
IF(@ISMBR("Salary"))
    "Forecast" = "Actual" * 1.03;
ELSEIF(@ISMBR("Bonus"))
    "Forecast" = "Salary" * 0.15;
ELSEIF(@ISMBR("Benefits"))
    "Forecast" = "Salary" * 0.25;
ELSE
    "Forecast" = "Actual";
ENDIF
```

### Variant 3: Many Tiers

```essbase
IF("Score" >= 90)
    "Rating" = 5;
ELSEIF("Score" >= 80)
    "Rating" = 4;
ELSEIF("Score" >= 70)
    "Rating" = 3;
ELSEIF("Score" >= 60)
    "Rating" = 2;
ELSE
    "Rating" = 1;
ENDIF
```

### Variant 4: UDA-Based Region Logic

```essbase
IF(@UDA("Entity", "Americas"))
    "Tax_Rate" = 0.21;
ELSEIF(@UDA("Entity", "EMEA"))
    "Tax_Rate" = 0.25;
ELSEIF(@UDA("Entity", "APAC"))
    "Tax_Rate" = 0.30;
ELSE
    "Tax_Rate" = 0.20;
ENDIF
```

---

## Practical Examples

### Example 1: Tiered Commission Calculation

**Scenario**: Sales commission rates vary based on achievement percentage.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Sales Team"))
    IF("Achievement_Pct" >= 1.50)
        "Commission" = "Revenue" * 0.20;  /* 20% for 150%+ */
    ELSEIF("Achievement_Pct" >= 1.20)
        "Commission" = "Revenue" * 0.15;  /* 15% for 120-149% */
    ELSEIF("Achievement_Pct" >= 1.00)
        "Commission" = "Revenue" * 0.10;  /* 10% for 100-119% */
    ELSEIF("Achievement_Pct" >= 0.80)
        "Commission" = "Revenue" * 0.05;  /* 5% for 80-99% */
    ELSE
        "Commission" = 0;                  /* 0% below 80% */
    ENDIF
ENDFIX
```

**What Happens**:
- For each sales team member, checks achievement from highest to lowest
- First matching tier applies — a 130% achiever gets 15%, not 10%
- Below 80% gets no commission

---

### Example 2: Account-Type Aware Forecast

```essbase
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    IF(@ISMBR(@DESCENDANTS("Revenue")))
        "Forecast" = "Actual" -> "FY24" * 1.08;
    ELSEIF(@ISMBR(@DESCENDANTS("Variable Costs")))
        "Forecast" = "Forecast" -> "Revenue" * "Cost_Ratio";
    ELSEIF(@ISMBR(@DESCENDANTS("Fixed Costs")))
        "Forecast" = "Actual" -> "FY24" * 1.03;
    ELSE
        "Forecast" = "Actual" -> "FY24";
    ENDIF
ENDFIX
```

---

### Example 3: Data Quality Scoring

```essbase
FIX("FY25", @DESCENDANTS("Total Entity"))
    VAR vCompleteness = 0;
    IF(Revenue != #MISSING AND COGS != #MISSING AND "Op_Expense" != #MISSING)
        vCompleteness = 3;
    ELSEIF(Revenue != #MISSING AND COGS != #MISSING)
        vCompleteness = 2;
    ELSEIF(Revenue != #MISSING)
        vCompleteness = 1;
    ELSE
        vCompleteness = 0;
    ENDIF
    "Data_Quality_Score" = vCompleteness;
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Overlapping conditions | `IF(x > 50) ELSEIF(x > 30)` — a value of 60 matches the first, never reaches the second | Order conditions from most restrictive to least restrictive |
| Missing parentheses | `ELSEIF condition` without `()` is a syntax error | Always use: `ELSEIF(condition)` |
| ELSEIF after ELSE | ELSE must be the LAST branch — ELSEIF cannot follow ELSE | Rearrange: all ELSEIF before ELSE |
| Too many branches | 10+ ELSEIF branches become unreadable | Consider using UDAs, substitution variables, or member formulas |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`IF`](./IF.md) | The opening conditional — ELSEIF extends it |
| [`ELSE`](./ELSE.md) | Final fallback after all ELSEIF branches |
| [`ENDIF`](./ENDIF.md) | Closes the entire IF/ELSEIF/ELSE chain |
| [`@ISMBR`](./@ISMBR.md) | Common function used in ELSEIF conditions |
| [`@UDA`](./@UDA.md) | Common function for attribute-based branching |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ELSEIF](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/elseif.html)
