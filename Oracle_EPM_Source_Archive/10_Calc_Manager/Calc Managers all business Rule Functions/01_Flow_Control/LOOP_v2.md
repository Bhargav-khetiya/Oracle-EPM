# LOOP

## Overview

`LOOP` is a **repetition command** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that executes a block of calculation statements **multiple times**. It creates an iterative loop that runs the enclosed code for a specified number of iterations, enabling scenarios like iterative allocations, convergence calculations, and multi-pass processing.

### Why Does This Command Exist—

Some business calculations require multiple passes to converge on a correct answer:
- **Iterative allocations**: When departments allocate costs to each other (circular references), multiple passes are needed until values stabilize
- **Goal-seeking**: Repeatedly adjusting a value until a target is met
- **Multi-step processes**: Running the same logic across different calculation phases
- **Convergence calculations**: Financial models where outputs feed back as inputs until the delta is negligible

### When to Use It

- When you need iterative allocation processing (reciprocal allocations)
- When a calculation depends on its own output (circular logic that must converge)
- When you need to repeat a calculation a fixed number of times
- When implementing goal-seek or solver-type logic
- When processing multi-step waterfall calculations

---

## Category

**Calc Script Command / Flow Control / Iteration**

---

## Syntax

```essbase
LOOP(count)
    /* calculation statements */
ENDLOOP
```

### Formal Syntax

```
LOOP(numericExpression [, maxIterations])
    calcStatements
ENDLOOP
```

Where:
- `numericExpression` — The number of times to execute the loop body. Must evaluate to a positive integer. Can be a literal number, a variable, or an expression.
- `maxIterations` — Optional safety limit to prevent infinite loops.
- `calcStatements` — Any valid calculation statements including FIX, IF, formulas, or even nested LOOPs.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `count` | Numeric (integer) | ✅ Yes | The number of loop iterations. Must be a positive integer. Common values: 5-20 for iterative allocations, 50-100 for convergence calculations. Using very high values (1000+) can cause performance issues and may indicate a design problem. Can also be a variable: `LOOP(vIterations)`. |
| `maxIterations` | Numeric (integer) | ❌ No | Optional safety cap. If the loop would exceed this many iterations, it stops. Provides protection against runaway calculations. |

---

## Return Value

`LOOP` does not return a value — it is a **control flow command** that repeats its enclosed statements.

---

## How It Works (Behind the Scenes)

1. **Counter-Based**: LOOP maintains an internal counter that starts at 1 and increments after each iteration. When the counter exceeds the specified count, the loop terminates and execution continues after ENDLOOP.

2. **Full Pass Each Iteration**: Each loop iteration executes ALL statements in the loop body completely. This means if you have FIX blocks inside the loop, they process their full scope on every iteration.

3. **Data Visibility**: Changes made in one iteration are visible in the next iteration. This is critical for convergence — each pass can read the results of the previous pass. Essbase does not buffer or delay writes between iterations.

4. **Performance Impact**: Each iteration is a full calculation pass. A LOOP(10) with a FIX block covering 1 million cells effectively processes 10 million cell calculations. Use the minimum number of iterations needed for convergence.

5. **No Break Statement**: Unlike programming languages, Essbase's LOOP does not have a `break` or `continue` statement. The only way to exit early is to use conditional logic (IF) inside the loop to skip calculations when convergence is achieved.

6. **Nesting**: LOOPs can be nested, but this is rare and should be done cautiously. A LOOP(10) inside a LOOP(10) = 100 iterations of the inner block.

---

## Syntax Variants & Scenarios

### Variant 1: Simple Fixed Iteration

```essbase
LOOP(10)
    "Allocated_Cost" = "Total_Cost" * "Headcount" / "Total_Headcount";
ENDLOOP
```
Runs the allocation 10 times to converge.

### Variant 2: LOOP with FIX

```essbase
LOOP(5)
    FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
        "Allocated_Overhead" = "Total_Overhead" *
            ("Dept_Base" / "Total_Base");
    ENDFIX
    AGG("Entity");  /* Re-aggregate after each pass */
ENDLOOP
```

### Variant 3: LOOP with Variable Count

```essbase
VAR vIterations = 15;
LOOP(vIterations)
    "Reciprocal_Alloc" = "Service_Cost" *
        ("Usage_Hours" / "Total_Usage");
ENDLOOP
```

### Variant 4: LOOP with Convergence Check

```essbase
LOOP(50)
    FIX("FY25", @DESCENDANTS("Cost Centers"))
        VAR vPriorValue = "Allocated_Cost";
        "Allocated_Cost" = "Direct_Cost" + "Received_Allocation";
        
        /* Skip if already converged (delta < 0.01) */
        IF(@ABS("Allocated_Cost" - vPriorValue) < 0.01)
            "Allocated_Cost" = "Allocated_Cost";  /* No-op, effectively skip */
        ENDIF
    ENDFIX
    AGG("Cost_Center");
ENDLOOP
```

### Variant 5: Nested LOOP (Rare)

```essbase
LOOP(3)  /* Outer: quarterly cycle */
    LOOP(5)  /* Inner: convergence per quarter */
        "Balance" = "Opening" + "Inflows" - "Outflows";
    ENDLOOP
ENDLOOP
```

---

## Practical Examples

### Example 1: Reciprocal Cost Allocation

**Scenario**: IT and HR allocate costs to each other. IT provides services to HR, and HR provides services to IT. This creates a circular reference that requires iterative solving.

```essbase
LOOP(20)
    FIX("FY25", "Working")
        /* IT allocates to HR based on tickets */
        FIX("HR")
            "IT_Allocation" = "IT_Total_Cost" * ("HR_Tickets" / "Total_Tickets");
        ENDFIX
        
        /* HR allocates to IT based on headcount */
        FIX("IT")
            "HR_Allocation" = "HR_Total_Cost" * ("IT_Headcount" / "Total_Headcount");
        ENDFIX
        
        /* Update totals for next iteration */
        "Total_Cost" = "Direct_Cost" + "IT_Allocation" + "HR_Allocation";
    ENDFIX
ENDLOOP
```

**What Happens**:
- Iteration 1: Initial allocation based on direct costs only
- Iteration 2: Now includes received allocations from iteration 1
- Iterations 3-20: Values converge as the circular amounts get smaller each pass
- By iteration 15-20, the delta is typically negligible

---

### Example 2: Cash Flow Waterfall

**Scenario**: Calculate cash balance where each period's closing balance becomes the next period's opening balance.

```essbase
LOOP(12)  /* One iteration per month */
    FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
        "Opening_Balance" = @PRIOR("Closing_Balance", 1);
        "Closing_Balance" = "Opening_Balance" + "Cash_Inflows" - "Cash_Outflows";
    ENDFIX
ENDLOOP
```

---

### Example 3: Iterative Tax Calculation

**Scenario**: Tax depends on profit, but profit depends on tax (circular). Iterate to converge.

```essbase
LOOP(10)
    FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
        "Tax_Expense" = "Pre_Tax_Income" * 0.21;
        "Net_Income" = "Pre_Tax_Income" - "Tax_Expense";
        "Retained_Earnings" = "Prior_RE" + "Net_Income";
        /* If retained earnings affect pre-tax income, this converges */
    ENDFIX
ENDLOOP
```

---

### Example 4: Monte Carlo-Style Sensitivity

```essbase
VAR vScenario = 1;
LOOP(5)
    FIX("FY25", "Working")
        "Sensitivity_Revenue" = Revenue * (1 + (vScenario * 0.02));  /* +2%, +4%, +6%, +8%, +10% */
        "Sensitivity_Profit" = "Sensitivity_Revenue" - COGS;
    ENDFIX
    vScenario = vScenario + 1;
ENDLOOP
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Missing ENDLOOP | Every LOOP must have a matching ENDLOOP | Write LOOP/ENDLOOP pair first, add content between |
| Too many iterations | LOOP(1000) is almost always wrong — causes huge performance hit | Start with 10-20, increase only if convergence isn't reached |
| No convergence check | Without checking if values have stabilized, you waste compute on unnecessary iterations | Add IF to check delta and skip when converged |
| Forgetting to re-aggregate | After each loop iteration, parent members may be stale | Include `AGG` or `CALC DIM` inside the loop if parents are referenced |
| Modifying the loop count variable inside the loop | Changing the iteration count mid-loop has undefined behavior | Use a fixed count or a variable set before the loop |
| Using LOOP when FIX is sufficient | LOOP doesn't iterate over members — it repeats calculations | For member iteration, use FIX with member functions, not LOOP |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`ENDLOOP`](./ENDLOOP.md) | Required closing pair for LOOP |
| [`FIX`](./FIX.md) | Often used inside LOOP to scope iterations |
| [`AGG`](../03_Calc_Commands/AGG.md) | Often needed inside LOOP to re-aggregate after each pass |
| [`IF`](./IF.md) | Used inside LOOP for convergence checks |
| [`@ABS`](../06_Mathematical/@ABS.md) | Used to check convergence delta |
| [`ACCUMULATEVAR`](../03_Calc_Commands/ACCUMULATEVAR.md) | Accumulates variable across loop passes |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — LOOP](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/loop.html)
- [Oracle Essbase Technical Reference — LOOP/ENDLOOP](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/loop_endloop.html)
