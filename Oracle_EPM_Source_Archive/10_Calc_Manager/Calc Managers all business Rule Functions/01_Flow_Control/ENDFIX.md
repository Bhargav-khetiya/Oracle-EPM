# ENDFIX

## Overview

`ENDFIX` is the **mandatory closing command** for every `FIX` block in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. Every `FIX` statement must have a matching `ENDFIX` — without it, the calculation script will fail with a syntax error. Together, `FIX`/`ENDFIX` form the most fundamental structural pair in Essbase calc scripts.

### Why Does This Command Exist—

Essbase uses block-structured syntax. `FIX` opens a scoped calculation block, and `ENDFIX` tells Essbase where that scope ends. Without a clear terminator:
- The engine wouldn't know where the restricted scope ends
- Nested FIX blocks would be ambiguous
- Script parsing would be unreliable

### When to Use It

- **Every time you use FIX** — it's not optional
- After all calculation statements within a FIX block are complete
- Before starting a new FIX block at the same nesting level
- At the proper nesting level when using nested FIX blocks

---

## Category

**Calc Script Command / Flow Control / Scope**

---

## Syntax

```essbase
FIX(member1, member2, ...)
    /* calculation statements */
ENDFIX
```

### Formal Syntax

```
ENDFIX
```

No parameters — `ENDFIX` simply closes the most recently opened `FIX` block.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| *(none)* | — | — | `ENDFIX` takes no parameters. It automatically pairs with the most recently opened, unclosed `FIX` statement. |

---

## Return Value

`ENDFIX` does not return a value — it is a **structural command** that terminates a FIX scope.

---

## How It Works (Behind the Scenes)

1. **Pairing**: Essbase uses a stack-based approach. Each `FIX` pushes a scope onto the stack, and each `ENDFIX` pops the most recent scope off. If the stack is empty when `ENDFIX` is encountered, or if there are unmatched `FIX` statements at script end, a syntax error occurs.

2. **Scope Release**: When `ENDFIX` executes, the member scope established by its matching `FIX` is released. Subsequent statements operate in the scope of the enclosing FIX (if nested) or the full database scope (if at the top level).

3. **Block Commit**: In BSO, data modifications made within a FIX/ENDFIX block may be committed to disk when the ENDFIX is reached, depending on Essbase's internal buffering strategy.

4. **Nesting Rules**: ENDFIX always matches the **innermost open FIX**. For 3 nested FIX blocks, you need 3 ENDFIX statements, closing from innermost to outermost.

5. **Semicolon**: `ENDFIX` can optionally be followed by a semicolon (`ENDFIX;`). Both forms are valid — with or without the semicolon.

---

## Syntax Variants & Scenarios

### Variant 1: Simple FIX/ENDFIX Pair

```essbase
FIX("FY25", "Working")
    Revenue = Units * Price;
ENDFIX
```

### Variant 2: Nested FIX/ENDFIX

```essbase
FIX("FY25", "Working")
    FIX(@DESCENDANTS("North America"))
        Revenue = Revenue * 1.10;
    ENDFIX
    FIX(@DESCENDANTS("Europe"))
        Revenue = Revenue * 1.05;
    ENDFIX
ENDFIX
```
Three ENDFIX statements for three FIX statements — inner ones close first.

### Variant 3: Sequential FIX Blocks

```essbase
FIX("FY25", "Forecast")
    Revenue = Revenue -> "FY24" * 1.08;
ENDFIX

FIX("FY25", "Working")
    Revenue = Revenue -> "Forecast";
ENDFIX
```
Two independent FIX/ENDFIX pairs.

### Variant 4: With Semicolon

```essbase
FIX("FY25")
    Revenue = Units * Price;
ENDFIX;
```
The semicolon after ENDFIX is optional but accepted.

---

## Practical Examples

### Example 1: Standard Business Rule Structure

**Scenario**: Typical business rule with setup, calculation, and aggregation.

```essbase
/* Step 1: Calculate base data */
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    Revenue = Units * Price;
    COGS = Units * "Unit Cost";
    "Gross Margin" = Revenue - COGS;
ENDFIX

/* Step 2: Calculate derived metrics */
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    IF(Revenue != 0)
        "GM_Pct" = "Gross Margin" / Revenue * 100;
    ENDIF
ENDFIX

/* Step 3: Aggregate */
AGG("Entity");
```

---

### Example 2: Nested Blocks with Region-Specific Logic

```essbase
FIX("FY25", "Working")
    FIX(@DESCENDANTS("Americas"))
        "Tax Expense" = "Pre Tax Income" * 0.21;
    ENDFIX
    FIX(@DESCENDANTS("EMEA"))
        "Tax Expense" = "Pre Tax Income" * 0.25;
    ENDFIX
    FIX(@DESCENDANTS("APAC"))
        "Tax Expense" = "Pre Tax Income" * 0.30;
    ENDFIX
ENDFIX
```

**What Happens**: Each inner ENDFIX closes its regional scope. The outer ENDFIX closes the year/scenario scope. Tax rates differ by region.

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing ENDFIX | Script fails with "Syntax error" — every FIX needs an ENDFIX | Write FIX/ENDFIX pair first, then add content between them |
| Extra ENDFIX | More ENDFIX than FIX causes "unexpected ENDFIX" error | Count FIX and ENDFIX — they must match exactly |
| Wrong nesting order | ENDFIX closes the innermost FIX — misordering causes logic errors | Indent your code properly to visualize nesting |
| ENDFIX after ENDIF confusion | ENDFIX closes FIX, not IF — don't mix them up | FIX→ENDFIX, IF→ENDIF — use proper closing for each |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`FIX`](./FIX.md) | The opening pair — every ENDFIX must have a matching FIX |
| [`ENDIF`](./ENDIF.md) | Similar closing command for IF blocks — don't confuse with ENDFIX |
| [`ENDLOOP`](./ENDLOOP.md) | Similar closing command for LOOP blocks |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ENDFIX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/endfix.html)
- [Oracle Essbase Technical Reference — FIX/ENDFIX](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/fix_endfix.html)
