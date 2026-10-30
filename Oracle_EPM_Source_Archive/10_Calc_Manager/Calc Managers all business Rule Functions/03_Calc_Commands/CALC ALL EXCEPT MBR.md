# CALC ALL EXCEPT MBR

## Overview

`CALC ALL EXCEPT MBR` is a **native Essbase calculation command** in Oracle EPM Cloud (PBCS/EPBCS). It is an aggressive, macro-level directive that commands the Essbase calculation engine to execute a full, top-to-bottom structural aggregation (calculating all dimension trees, running all formulas, rolling up all parents)... **EXCEPT** for a specific list of defined dimension members and their descendants. 

### Why Does This Function Exist?

The `CALC ALL` command rolls up the entire database. The `CALC ALL EXCEPT DIM` command protects an entire dimension. But what if you only need to protect a *piece* of a dimension?
For example, you have an `"Entity"` dimension. You need to roll up the entire company because base-level data was just loaded. However, there is a specific branch called `"Discontinued_Operations"`. Data in this branch is frozen. You do not want the engine wasting 10 minutes aggregating the hundreds of dormant stores inside the discontinued branch. 
You cannot use `EXCEPT DIM("Entity")` because you *need* the rest of the Entity dimension to calculate. 
`CALC ALL EXCEPT MBR` solves this. You instruct the engine to roll up the entire database, but you provide a blacklist of specific members (e.g., `"Discontinued_Operations"`). The engine will aggressively aggregate the outline, but the moment it hits your blacklisted member (and all of its descendants), it skips them entirely.

### When to Use It

- **Frozen Historical Branches**: Aggregating a database but explicitly bypassing archived or discontinued branches of the hierarchy to save calculation time.
- **Top-Side Adjustments Protection**: Rolling up the base data but explicitly skipping a `"Management_Adjustments"` parent member so that custom high-level journal entries are not accidentally overwritten by the bottom-up aggregation.
- **Hybrid Sandbox Protection**: Calculating the main corporate outline but skipping a `"Sandbox"` branch that users are currently manipulating in real-time.

---

## Category

**System & Optimization / Aggregation Directives / Calculation Commands**

---

## Syntax

```essbase
CALC ALL EXCEPT MBR (Member_List);
```

*(Note: Because this is a macro command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Member_List` | List | ✅ Yes | A comma-separated list of the specific members you want to explicitly exclude from the aggregation sweep (e.g., `"Discontinued_Ops", "Sandbox"`). <br><br>**Crucial**: When you exclude a parent member, Essbase automatically excludes ALL of its descendants as well. You do not need to use `@DESCENDANTS` inside this command. |

---

## Return Value

**Return Type**: System Action (Block Aggregation)

This command does not return a value. It triggers a massive structural sweep of the database index.
- **Aggregation Execution**: It reads the outline and aggregates every block.
- **Blacklist Enforcement**: When the index scanner reaches a member specified in the `Member_List`, it terminates that specific branch calculation. It leaves the existing data in that block (and its children) completely untouched.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The engine reads the `CALC ALL EXCEPT MBR` command.
2. **Blacklist Compilation**: It registers the `Member_List` into an internal memory exclusion array.
3. **Execution**: It fires the standard `CALC ALL` C-engine routines. It calculates formulas and rolls up dense/sparse dimensions.
4. **Boundary Detection**: Every time it prepares to aggregate a parent, it checks the exclusion array. If the parent matches (e.g., `"Discontinued_Ops"`), it skips the `AGG` command for that branch and moves to the next branch.
5. **Completion**: Once the allowed branches are written to disk, it moves to the next line in the script.

---

## Syntax Variants & Scenarios

### Variant 1: Blacklisting a Dormant Branch

```essbase
/* 
   Rolls up the entire database, but completely skips the "Discontinued_Ops" 
   branch and the "Archived_Projects" branch.
*/
CALC ALL EXCEPT MBR ("Discontinued_Ops", "Archived_Projects");
```

---

## Practical Examples

### Example 1: Protecting Top-Side Management Adjustments

**Scenario**: The `"Total_Company"` entity is comprised of two children: `"Operating_Subsidiaries"` (which aggregates from Level 0 stores) and `"Top_Side_Adjustments"` (which is manually input by the CFO at Level 1). When the nightly aggregation runs, the admin wants to roll up the operating subsidiaries into the total, but they MUST NOT let the aggregation engine touch the `"Top_Side_Adjustments"` branch, or it might wipe out the CFO's manual inputs.

```essbase
/* 
   1. Fix on the current active forecast scenario.
*/
FIX("Forecast", "Working", "FY25")
    
    /* 
       2. Command the engine to roll up the entire database.
       3. We explicitly blacklist the "Top_Side_Adjustments" member.
       The engine will roll up the Operating Subsidiaries perfectly, 
       but it will completely ignore the adjustments branch, leaving 
       the CFO's data intact.
    */
    CALC ALL EXCEPT MBR ("Top_Side_Adjustments");
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Over-Complicating the List | `@DESCENDANTS("Parent")` | A very common mistake is trying to write `CALC ALL EXCEPT MBR(@DESCENDANTS("Discontinued_Ops"))`. This command does NOT accept structural selection functions like `@DESCENDANTS`. It only accepts raw member names. If you type the parent name `"Discontinued_Ops"`, Essbase inherently knows to skip the entire branch beneath it. Do not use `@` functions inside the parentheses |
| Using `@` Prefix | `@CALC ALL` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash immediately |
| Block Explosion Risk | Massive Outlines | Like `CALC ALL EXCEPT DIM`, this command is still fundamentally a `CALC ALL`. It will attempt to aggregate the entire database. If your database has 20 sparse dimensions, this will take an eternity and explode your block count. Use explicit `CALC DIM` or `AGG` commands for surgical precision in large models |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`CALC ALL EXCEPT DIM`](./CALC%20ALL%20EXCEPT%20DIM.md) | Blacklists an entire Dimension from the aggregation sweep, rather than just a specific member branch |
| [`CALC DIM`](./CALC%20DIM.md) | The surgical alternative. Explicitly declares exactly which dimensions to aggregate, providing much tighter control over performance |
| `AGG` | The modern standard for sparse-dimension aggregations, vastly outperforming `CALC` commands in large models |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — CALC ALL](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/calc_all.html)
