# ENDLOOP

## Overview

`ENDLOOP` is the **mandatory closing command** for every `LOOP` block in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager. Every `LOOP` statement must have a matching `ENDLOOP` — without it, the calculation script will fail with a syntax error. Together, `LOOP`/`ENDLOOP` form the iteration control pair.

### Why Does This Command Exist—

Essbase uses block-structured syntax where every opening command needs a closing pair:
- `FIX` → `ENDFIX`
- `IF` → `ENDIF`
- `LOOP` → `ENDLOOP`

`ENDLOOP` marks where the repeated code block ends. When Essbase reaches ENDLOOP, it increments the loop counter and either jumps back to the start of the loop (if iterations remain) or continues past ENDLOOP (if all iterations are complete).

### When to Use It

- **Every time you use LOOP** — there are no exceptions
- At the proper nesting level when LOOP blocks are nested
- After all iterative calculation statements are complete

---

## Category

**Calc Script Command / Flow Control / Iteration**

---

## Syntax

```essbase
LOOP(count)
    /* iterative calculation statements */
ENDLOOP
```

### Formal Syntax

```
ENDLOOP
```

No parameters — `ENDLOOP` simply closes the most recently opened, unclosed `LOOP` block.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| *(none)* | — | — | `ENDLOOP` takes no parameters. It pairs with the innermost open `LOOP`. |

---

## Return Value

`ENDLOOP` does not return a value — it is a **structural command** that either triggers the next loop iteration or terminates the loop.

---

## How It Works (Behind the Scenes)

1. **Iteration Control**: When Essbase reaches ENDLOOP, it checks the loop counter against the specified count. If more iterations remain, execution jumps back to the first statement after LOOP. If all iterations are complete, execution continues with the statement following ENDLOOP.

2. **Stack-Based Pairing**: Like ENDFIX and ENDIF, ENDLOOP uses a stack. Each LOOP pushes, each ENDLOOP pops. Mismatches cause syntax errors at parse time.

3. **Commit Point**: ENDLOOP may serve as a data commit point — changes from the current iteration are flushed before the next iteration begins. This ensures each iteration sees the results of the previous one.

4. **Nesting**: For nested LOOPs, each ENDLOOP closes the innermost open LOOP. The inner loop completes all its iterations before the outer loop advances.

5. **Semicolon**: `ENDLOOP` can optionally include a semicolon (`ENDLOOP;`). Both forms are valid.

---

## Syntax Variants & Scenarios

### Variant 1: Simple LOOP/ENDLOOP

```essbase
LOOP(10)
    "Allocated_Cost" = "Total_Cost" * "Ratio";
ENDLOOP
```

### Variant 2: With FIX Inside

```essbase
LOOP(15)
    FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
        "Reciprocal_Cost" = "Direct_Cost" + "Received_Alloc";
    ENDFIX
    AGG("Entity");
ENDLOOP
```

### Variant 3: Nested Loops

```essbase
LOOP(4)          /* Outer: quarterly */
    LOOP(10)     /* Inner: convergence */
        "Balance" = "Opening" + "Net_Change";
    ENDLOOP      /* Closes inner LOOP */
ENDLOOP          /* Closes outer LOOP */
```

### Variant 4: With Aggregation After

```essbase
LOOP(20)
    FIX(@DESCENDANTS("Cost Centers"))
        "Total" = "Direct" + "Indirect";
    ENDFIX
    AGG("Cost_Center");   /* Must re-aggregate BEFORE ENDLOOP */
ENDLOOP                    /* Triggers next iteration with fresh aggregated values */
```

---

## Practical Examples

### Example 1: Reciprocal Allocation (Complete Pattern)

**Scenario**: Standard reciprocal allocation between service departments.

```essbase
/* Initialize */
FIX("FY25", "Working")
    "Allocated_Cost" = "Direct_Cost";
ENDFIX

/* Iterate until converged */
LOOP(20)
    FIX("FY25", "Working", @DESCENDANTS("Service Depts"))
        "Allocated_Cost" = "Direct_Cost" +
            @SUM("Incoming_Allocation");
    ENDFIX
    
    AGG("Department");  /* Re-aggregate before next pass */
ENDLOOP                 /* ← Checks: iteration < 20— If yes, loop again */

/* Final result is in "Allocated_Cost" after convergence */
```

**What Happens at ENDLOOP**:
- Iteration 1 completes → ENDLOOP increments counter → counter (2) ≤ 20 → jump back
- Iteration 2 completes → ENDLOOP increments counter → counter (3) ≤ 20 → jump back
- ...
- Iteration 20 completes → ENDLOOP increments counter → counter (21) > 20 → exit loop

---

### Example 2: Cash Waterfall with ENDLOOP Boundary

```essbase
LOOP(12)
    FIX("FY25", @DESCENDANTS("Total Entity"))
        "Opening" = @PRIOR("Closing", 1);
        "Closing" = "Opening" + "Inflows" - "Outflows";
    ENDFIX
ENDLOOP    /* After 12 iterations, all months' cash balances are chained */
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing ENDLOOP | Every LOOP needs an ENDLOOP — script won't compile | Write LOOP/ENDLOOP pair first, then add content |
| Using ENDFIX instead of ENDLOOP | ENDFIX closes FIX, not LOOP — wrong pairing causes error | LOOP→ENDLOOP, FIX→ENDFIX, IF→ENDIF |
| Placing AGG after ENDLOOP | If you need aggregated values in the next iteration, AGG must be INSIDE the loop, BEFORE ENDLOOP | Move AGG inside the LOOP block |
| Wrong nesting with FIX | ENDFIX for inner FIX must come before ENDLOOP | Ensure: LOOP → FIX → ENDFIX → ENDLOOP |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`LOOP`](./LOOP.md) | The opening pair — every ENDLOOP must have a matching LOOP |
| [`ENDFIX`](./ENDFIX.md) | Closes FIX blocks — don't confuse with ENDLOOP |
| [`ENDIF`](./ENDIF.md) | Closes IF blocks — similar pattern |
| [`AGG`](./AGG.md) | Often placed just before ENDLOOP to re-aggregate |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ENDLOOP](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/endloop.html)
- [Oracle Essbase Technical Reference — LOOP/ENDLOOP](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/loop_endloop.html)
