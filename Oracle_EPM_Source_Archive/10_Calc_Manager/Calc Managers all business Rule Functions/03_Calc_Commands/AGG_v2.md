# AGG

## Overview

`AGG` is an **aggregation command** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that **rolls up data** from child members to parent members along one or more dimensions. It calculates parent values by summing (or applying the configured consolidation operator to) their children's values. It is a core command used in almost every business rule that modifies data.

### Why Does This Command Exist?

In Essbase BSO, data is stored at the **leaf level** (lowest-level members). Parent members don't automatically recalculate when leaf data changes during a calc script. After modifying leaf-level data through formulas, you must explicitly aggregate to update parents:
- Revenue → Total Revenue → Total P&L
- Entity A, Entity B → Region → Total Company
- Jan, Feb, Mar → Q1 → H1 → FY25

### When to Use It

- After any calculation that modifies leaf-level data
- At the end of a business rule to update hierarchies
- After DATACOPY or CLEARDATA operations
- After data loads to refresh parent values
- When you need to aggregate a specific dimension (not all)

---

## Category

**Calc Script Command / Aggregation**

---

## Syntax

```essbase
AGG(dimName);
AGG(dimName1, dimName2, ...);
```

### Formal Syntax

```
AGG(dimensionName [, dimensionName]...);
```

Where:
- `dimensionName` — The name of one or more dimensions to aggregate. Multiple dimensions are comma-separated and aggregated in the order specified.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `dimName` | Dimension name(s) | ✅ Yes | One or more dimension names to aggregate. Each dimension is processed in order. The consolidation operator defined in the outline (addition `+`, subtraction `-`, multiplication `*`, etc.) determines how children roll up to parents. |

---

## Return Value

`AGG` does not return a value — it **updates parent member values** by rolling up child data.

---

## How It Works (Behind the Scenes)

1. **Bottom-Up Processing**: AGG works from the bottom of the hierarchy upward. Leaf members are summed to their immediate parents, then those parents are summed to their parents, and so on up to the dimension's root member.

2. **Consolidation Operators**: The outline defines how each member consolidates to its parent: `+` (add), `-` (subtract), `*` (multiply), `/` (divide), `%` (percent), `~` (ignore/no consolidation). AGG respects these operators.

3. **Multi-Dimension AGG**: `AGG("Account", "Entity")` aggregates Account first, then Entity. The order can matter — aggregating Account first means Entity-level parents will have fully calculated account hierarchies.

4. **Block Creation**: AGG can create new upper-level blocks if they don't exist. This is necessary when leaf data was newly loaded or created by formulas.

5. **Scope with FIX**: When used inside a FIX block, AGG only aggregates within the FIX scope. However, FIX dimensions are NOT aggregated — only non-FIX dimensions can be aggregated within a FIX block.

6. **Performance**: AGG is optimized for bulk processing. It's faster than writing individual parent formulas. However, aggregating all dimensions when only one changed is wasteful — specify only the dimensions that need updating.

7. **vs. CALC DIM**: `AGG` performs only consolidation (rolling up). `CALC DIM` performs consolidation AND evaluates member formulas. Use AGG when you only need roll-up; use CALC DIM when member formulas also need to run.

---

## Syntax Variants & Scenarios

### Variant 1: Single Dimension

```essbase
AGG("Account");
```
Rolls up all Account hierarchy (leaf → subtotal → total).

### Variant 2: Multiple Dimensions

```essbase
AGG("Account", "Entity", "Period");
```
Aggregates Account, then Entity, then Period in sequence.

### Variant 3: After Calculation

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    Revenue = Units * Price;
ENDFIX

AGG("Account");
AGG("Entity");
```

### Variant 4: Inside FIX (Limited)

```essbase
FIX("FY25", "Working")
    AGG("Entity");  /* Aggregates Entity within FY25 Working */
ENDFIX
```

### Variant 5: Selective Aggregation

```essbase
/* Only aggregate the dimensions that changed */
AGG("Account");  /* Revenue accounts were recalculated */
/* Don't aggregate Entity — no entity-level changes */
```

---

## Practical Examples

### Example 1: Standard Post-Calculation Aggregation

**Scenario**: After calculating leaf-level revenue, aggregate Account and Entity hierarchies.

```essbase
/* Calculate at leaf level */
FIX("FY25", "Working", @CHILDREN("Total Entity"))
    Revenue = Units * Price;
    COGS = Units * "Unit Cost";
    "Gross Margin" = Revenue - COGS;
ENDFIX

/* Roll up the results */
AGG("Account");
AGG("Entity");
```

**What Happens**:
- FIX calculates leaf-level values only
- `AGG("Account")` rolls up: Revenue + COGS + Gross Margin → Operating Income → Total P&L
- `AGG("Entity")` rolls up: Entity A + Entity B → Region → Total Company
- All parent members now show correct values

---

### Example 2: Aggregation After Data Copy

```essbase
/* Copy Actuals to Forecast */
FIX("FY25", @DESCENDANTS("Total Entity"))
    DATACOPY "Actual" TO "Forecast";
ENDFIX

/* Apply growth */
FIX("FY25", "Forecast", @DESCENDANTS("Total Entity"))
    Revenue = Revenue * 1.08;
ENDFIX

/* Re-aggregate everything */
AGG("Account", "Entity", "Period");
```

---

### Example 3: Aggregation Inside Iterative Loop

```essbase
LOOP(15)
    FIX("FY25", "Working", @DESCENDANTS("Cost Centers"))
        "Allocated_Cost" = "Direct_Cost" + "Received_Allocation";
    ENDFIX
    AGG("Cost_Center");  /* Must re-aggregate inside loop! */
ENDLOOP
```

**Why AGG Inside LOOP**: Each iteration modifies leaf values. Without AGG, the next iteration's formulas that reference parent members would read stale values.

---

### Example 4: Dimension-Specific Aggregation

```essbase
/* Only Account hierarchy changed — save time by aggregating just Account */
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    "Gross Margin" = Revenue - COGS;
    "Operating Income" = "Gross Margin" - "OpEx";
ENDFIX

AGG("Account");  /* Only Account — Entity leaf data didn't change */
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting to AGG after calculation | Parent members show stale values in forms | Always add AGG for affected dimensions after leaf-level calculations |
| Aggregating ALL dimensions unnecessarily | AGG("dim1","dim2","dim3","dim4") when only one changed — wastes time | Only aggregate dimensions where leaf data was modified |
| AGG inside FIX for the FIX dimension | `FIX("FY25") AGG("Year") ENDFIX` doesn't work — can't aggregate a FIXed dimension | Remove the dimension from FIX if you need to aggregate it |
| AGG vs. CALC DIM confusion | AGG only rolls up; CALC DIM also evaluates member formulas | Use CALC DIM if members have formulas; AGG if you only need consolidation |
| Wrong aggregation order | Aggregating Entity before Account may give different results if formulas reference cross-entity values | Generally aggregate dense dimensions first (Account, Period), then sparse (Entity) |
| Not aggregating after CLEARDATA + reload | Clearing and reloading leaf data leaves parents stale | Always AGG after any clear + reload sequence |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CALC DIM`](./CALC%20DIM.md) | Aggregates AND evaluates member formulas |
| [`CALC ALL EXCEPT DIM`](./CALC%20ALL%20EXCEPT%20DIM.md) | Aggregates all dimensions except specified ones |
| [`FIX`](../01_Flow_Control/FIX.md) | Scopes AGG when used inside FIX |
| [`CLEARDATA`](./CLEARDATA.md) | Often precedes AGG in clear-and-recalculate patterns |
| [`LOOP`](../01_Flow_Control/LOOP.md) | AGG often appears inside LOOP for iterative allocation |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — AGG](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/agg.html)
