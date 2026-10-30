# ENDIF

## Overview

`ENDIF` is the **mandatory closing command** for every `IF` block in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. Every `IF` statement — whether it includes `ELSEIF`, `ELSE`, or neither — must terminate with `ENDIF`. It marks the boundary where conditional execution ends and normal execution resumes.

### Why Does This Command Exist?

Essbase needs an explicit marker to know where conditional logic ends:
- Without ENDIF, nested conditions and multi-branch logic would be ambiguous
- It enables clean separation between conditional blocks and subsequent calculations
- It allows the parser to validate script structure before execution

### When to Use It

- **Every time you use IF** — there are no exceptions
- After the last branch of an IF/ELSEIF/ELSE chain
- At the correct nesting level when IF blocks are nested

---

## Category

**Calc Script Command / Flow Control / Conditional**

---

## Syntax

```essbase
IF(condition)
    /* statements */
ENDIF
```

```essbase
IF(condition)
    /* true branch */
ELSE
    /* false branch */
ENDIF
```

### Formal Syntax

```
ENDIF
```

No parameters. Closes the most recently opened, unclosed `IF` block.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| *(none)* | — | — | `ENDIF` takes no parameters. It pairs with the innermost open `IF`. |

---

## Return Value

`ENDIF` does not return a value — it is a **structural command**.

---

## How It Works (Behind the Scenes)

1. **Stack-Based Pairing**: Like ENDFIX, ENDIF uses a stack. Each IF pushes, each ENDIF pops. Mismatches cause syntax errors at parse time, before any calculation runs.

2. **Cell-Level Scope**: ENDIF ends the conditional evaluation scope. After ENDIF, the next statement executes unconditionally (or within whatever enclosing scope exists).

3. **Nesting**: Multiple nested IF blocks each need their own ENDIF. A FIX block's ENDFIX and an IF block's ENDIF are independent — you can't use ENDFIX to close an IF, or vice versa.

4. **Semicolon**: `ENDIF` can optionally include a semicolon (`ENDIF;`). Both forms are valid.

---

## Syntax Variants & Scenarios

### Variant 1: Simple IF/ENDIF

```essbase
IF(Revenue > 0)
    "Margin" = "Gross Profit" / Revenue;
ENDIF
```

### Variant 2: IF/ELSE/ENDIF

```essbase
IF(Revenue > 0)
    "Margin" = "Gross Profit" / Revenue;
ELSE
    "Margin" = 0;
ENDIF
```

### Variant 3: IF/ELSEIF/ELSE/ENDIF

```essbase
IF(@ISMBR("Revenue"))
    "Variance" = "Actual" - "Budget";
ELSEIF(@ISMBR("Expense"))
    "Variance" = "Budget" - "Actual";
ELSE
    "Variance" = 0;
ENDIF
```

### Variant 4: Nested IF Blocks

```essbase
IF(Revenue > 0)
    IF(Revenue > 1000000)
        "Tier" = 3;
    ELSEIF(Revenue > 500000)
        "Tier" = 2;
    ELSE
        "Tier" = 1;
    ENDIF
ENDIF
```
Inner ENDIF closes the tier check. Outer ENDIF closes the revenue > 0 check.

### Variant 5: IF Inside FIX

```essbase
FIX("FY25", "Working")
    IF(@UDA("Entity", "Active"))
        Revenue = Units * Price;
    ENDIF
ENDFIX
```
ENDIF closes the IF. ENDFIX closes the FIX. Don't confuse them.

---

## Practical Examples

### Example 1: Safe Division Pattern

```essbase
FIX("FY25", @DESCENDANTS("Total Entity"))
    IF("Budget" != 0 AND "Budget" != #MISSING)
        "Var_Pct" = ("Actual" - "Budget") / @ABS("Budget") * 100;
    ELSE
        "Var_Pct" = #MISSING;
    ENDIF    /* <-- ENDIF closes the Budget check */
ENDFIX       /* <-- ENDFIX closes the FIX scope */
```

### Example 2: Multi-Branch with Proper Nesting

```essbase
FIX("FY25", "Working")
    IF(@ISMBR(@DESCENDANTS("Operating Expenses")))
        IF("Actual" > "Budget" * 1.10)
            "Expense_Flag" = 3;  /* Over budget by >10% */
        ELSEIF("Actual" > "Budget")
            "Expense_Flag" = 2;  /* Over budget */
        ELSE
            "Expense_Flag" = 1;  /* Under/at budget */
        ENDIF                    /* closes inner IF */
    ENDIF                        /* closes @ISMBR IF */
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing ENDIF | Every IF needs an ENDIF — script won't run without it | Write IF/ENDIF pair first, then add logic between |
| Using ENDFIX instead of ENDIF | ENDFIX closes FIX blocks, not IF blocks | FIX→ENDFIX, IF→ENDIF — never mix them |
| Wrong nesting level | Putting ENDIF at the wrong indentation level causes logic errors | Indent carefully — each ENDIF should align with its matching IF |
| Forgetting ENDIF after ELSEIF chain | Even with ELSEIF and ELSE, you still need ENDIF at the end | The ENDIF is always required, regardless of how many branches exist |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`IF`](./IF.md) | The opening pair — every ENDIF must have a matching IF |
| [`ELSE`](./ELSE.md) | Alternative branch before ENDIF |
| [`ELSEIF`](./ELSEIF.md) | Additional conditional branch before ENDIF |
| [`ENDFIX`](./ENDFIX.md) | Closes FIX blocks — similar but different from ENDIF |
| [`ENDLOOP`](./ENDLOOP.md) | Closes LOOP blocks — similar pattern |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ENDIF](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/endif.html)
