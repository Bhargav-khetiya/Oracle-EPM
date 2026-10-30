# Business Rules Design — Complete Guide

> **Section:** 05 — Calc Manager and Business Rules  
> **File:** 02 — Business Rules Design  
> **Difficulty:** Beginner → Advanced  
> **Prerequisites:** [01_Calc_Manager_Overview](./01_Calc_Manager_Overview.md)

---

## What Are Business Rules?

A **business rule** is a saved calculation that you build in Calculation Manager, deploy to your application, and run to compute data in the Essbase cube. Think of it as a recipe: you define the ingredients (which members), the instructions (formulas), and the scope (which slice of data), then Oracle executes it.

There are two types:
- **Calc Script rules** — written in the Essbase calculation language (FIX, IF, formulas)
- **Groovy rules** — written in Groovy (a Java-based language with EPM-specific APIs)

This guide focuses on Calc Script rules. For Groovy, see [03_Groovy_Scripting](../03_Groovy_Scripting/).

---

## The FIX Statement — Most Important Concept

The FIX statement defines the **scope** of your calculation. It tells Essbase exactly which data blocks to load from disk. Everything outside the FIX is ignored.

### Why It Matters

Without a FIX, Essbase processes **every block** in the database. With a well-designed FIX, it processes only the blocks you need.

```
Example:
  Database has 500,000 sparse blocks on disk.
  
  FIX("Budget", "FY26", "Working", "Sales_East", @LEVMBRS("Product", 0))
  → Essbase evaluates the outline index
  → Only 450 blocks match
  → Only those 450 blocks are loaded into memory
  → 499,550 blocks are NEVER touched
  → Execution: 0.12 seconds vs 45 seconds without FIX
```

### FIX Syntax

```
FIX("member1", "member2", @function("Dimension"))
    /* calculations go here */
ENDFIX
```

### Sparse vs Dense Dimensions in FIX

| Dimension Type | Effect in FIX | Performance Impact |
|---------------|---------------|-------------------|
| **Sparse** (Entity, Scenario, Version, Year) | Filters which **blocks** are loaded from disk | **Major** — directly reduces I/O |
| **Dense** (Account, Period) | Filters which **cells within blocks** are calculated | Moderate — blocks still load |

> [!TIP]
> Always FIX on sparse dimensions first. Fixing on `"Budget"` (Scenario — sparse) eliminates entire blocks. Fixing on `"Jan"` (Period — dense) only narrows within already-loaded blocks.

### Nested FIX Statements

You can nest FIX statements for different calculation logic within different scopes:

```
FIX("FY26", "Budget")                    /* Outer: global context */
  FIX(@LEVMBRS("Entity", 0))             /* Inner: leaf entities only */
    "Net_Income" = "Revenue" - "Expense";
  ENDFIX
ENDFIX
```

The Calculation Manager compiler automatically merges adjacent nested FIX statements into a single composite FIX for optimal performance.

### The Empty FIX Trap

If a member selection returns **zero members**, the behavior depends on the Essbase version:

| Version | Behavior |
|---------|----------|
| **EPM Cloud (current)** | Safely skips the calculation and logs a message |
| **Legacy On-Premises (pre-11.1.2.4)** | Strips the constraint and runs against ALL data — potentially corrupting the database |

**Always validate** that UDAs and dynamic member queries return at least one member before deploying rules. [Oracle Documented — legacy behavior]

---

## Rule Components on the Canvas

When you build a rule in Calculation Manager's visual designer, you drag components onto a canvas:

### Core Components

| Component | Purpose | Icon |
|-----------|---------|------|
| **FIX** | Define calculation scope (data slice) | Grid/filter icon |
| **Formula** | Write the actual calculation | fx icon |
| **Script** | Write free-form calc script | Text icon |
| **Condition (IF)** | Branch logic | Diamond icon |
| **Loop** | Repeat calculations | Circular arrow |
| **Member Range** | Iterate over members | List icon |

### Variables and Prompts

**Substitution Variables** are server-side named values that administrators change centrally:

```
Variable: CurrYear = "FY26"
Variable: CurrMonth = "Oct"

Usage in rule:
FIX(&CurrYear, &CurrMonth)
    "Revenue" = "Revenue" * 1.05;
ENDFIX
```

When the year rolls, the admin updates `CurrYear` to `FY27` — every rule using `&CurrYear` automatically picks up the change.

**Runtime Prompts (RTPs)** ask the user for input when the rule launches:

```
FIX({RTP_Entity}, {RTP_Scenario}, &CurrYear)
    "Revenue" = "Revenue" * (1 + {RTP_GrowthRate} / 100);
ENDFIX
```

When launched, the user sees a prompt: "Select Entity", "Select Scenario", "Enter Growth Rate."

| Feature | Substitution Variable | Runtime Prompt |
|---------|----------------------|----------------|
| Set by | Administrator | End user at launch time |
| Scope | Application-wide or plan-type specific | Per rule execution |
| Syntax | `&VarName` | `{RTP_Name}` |
| Use case | Values that change infrequently | User-driven selections |

---

## SET Commands — Controlling the Calculation Engine

SET commands configure how Essbase executes your rule:

| Command | Purpose | Common Values |
|---------|---------|--------------|
| `SET UPDATECALC OFF` | Recalculate all cells, not just changed ones | OFF for seeding, ON for incremental |
| `SET CREATEBLOCKONEQ ON` | Create new sparse blocks when a formula assigns a non-missing value | ON when seeding new data |
| `SET CREATENONMISSINGBLK ON` | Create blocks when source data exists | ON for DATACOPY operations |
| `SET AGGMISSG ON` | Include #MISSING values in aggregation | ON or OFF depending on logic |
| `SET CALCPARALLEL n` | Enable parallel calculation with n threads | 2–8 (more isn't always better) |
| `SET CALCTASKDIMS n` | Number of dimensions for parallel task splitting | Usually 1 or 2 |
| `SET LOCKBLOCK ON/OFF` | Lock blocks during calculation | ON for data integrity |
| `SET FRMLBOTTOMUP ON` | Force bottom-up formula calculation | ON when parent formulas depend on children |

> [!WARNING]
> `SET CREATEBLOCKONEQ ON` can dramatically increase database size if misused. Only enable it within targeted FIX statements, and turn it OFF immediately after.

---

## Common Calculation Patterns

### Pattern 1: Simple P&L Calculation

```
FIX("Budget", "Working", &CurrYear, @LEVMBRS("Entity", 0))
    "Net_Income" = "Revenue" - "Expense";
    IF("Revenue" <> 0)
        "Profit_Margin" = "Net_Income" / "Revenue" * 100;
    ENDIF
ENDFIX
```

### Pattern 2: Growth-Rate Seeding (Copy Actual → Budget with Growth)

```
SET UPDATECALC OFF;
SET CREATEBLOCKONEQ ON;

FIX("Budget", "Working", &NextYear, @LEVMBRS("Entity", 0))
    "Revenue"(
        "Revenue" = "Revenue" -> "Actual" -> &CurrYear * 1.05;
    )
ENDFIX

SET CREATEBLOCKONEQ OFF;
```

### Pattern 3: Data Copy

```
SET CREATENONMISSINGBLK ON;

DATACOPY "Actual" -> "&CurrYear"
    TO "Budget" -> "&NextYear";

SET CREATENONMISSINGBLK OFF;
```

### Pattern 4: Aggregation

```
FIX("Budget", "Working", &CurrYear)
    AGG("Entity");
    AGG("Product");
ENDFIX
```

### Pattern 5: Allocation (Top-Down Distribution)

```
FIX("Budget", "Working", &CurrYear)
    @ALLOCATE("Corporate_Overhead" -> "Total_Entity",
        ACROSS @LEVMBRS("Entity", 0),
        BASIS "Revenue",
        SPREAD PROPORTIONAL,
        ROUNDMETHOD NOROUND,
        ERRORMETHOD NOOP);
ENDFIX
```

---

## System Templates

Calculation Manager provides pre-built templates for common operations. These save development time and follow Oracle best practices:

| Template | Purpose |
|----------|---------|
| **Allocation** | Distribute parent values to children based on a driver |
| **Clear Data** | Remove data from specified intersections |
| **Copy Data** | Copy data between members with mappings |
| **Consolidation** | Aggregate data up the hierarchy |
| **Custom Calculation** | User-defined formula template |
| **Amortization** | Spread a value across periods |
| **Currency Conversion** | Apply exchange rates |

---

## Rule Deployment and Execution

### Lifecycle

```
Create → Validate → Save → Deploy → Test → Launch
```

| Step | What Happens |
|------|-------------|
| **Create** | Build on the canvas or write script |
| **Validate** | Compiler checks syntax and member names |
| **Save** | Stores in Calculation Manager repository |
| **Deploy** | Publishes to the application (users can run it) |
| **Test** | Run with test data to verify results |
| **Launch** | Execute from a form, rule launcher, or EPM Automate |

### Where Rules Can Be Launched From

1. **Forms** — as "Run on Save" rules or from a menu
2. **Rule Launcher** — Navigator → Rules
3. **EPM Automate** — `epmautomate runbusinessrule "RuleName"`
4. **REST API** — `POST /applications/{app}/plantypes/{pt}/rules/{rule}`
5. **Groovy** — embedded calc script execution
6. **Task Lists** — as a step in a workflow

### Rulesets — Running Multiple Rules Together

A **Ruleset** groups multiple business rules to run in sequence or parallel:

```
Ruleset: Monthly_Close
  ├── Rule 1: Clear_Target_Data       (runs first)
  ├── Rule 2: Seed_Budget             (runs after Rule 1)
  ├── Rule 3: Calculate_Revenue       (parallel with Rule 4)
  ├── Rule 4: Calculate_Expense       (parallel with Rule 3)
  └── Rule 5: Aggregate_All           (runs after Rules 3 & 4)
```

---

## Troubleshooting Business Rules

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Rule runs but no data changes | FIX scope too narrow or wrong members | Check FIX members, verify data exists |
| Rule creates too many blocks | `SET CREATEBLOCKONEQ ON` too broad | Narrow the FIX, turn OFF after use |
| Rule very slow | Missing FIX on sparse dimensions | Always FIX on Scenario, Version, Year |
| "Member not found" error | Typo or undeployed member | Check member name spelling in outline |
| Unexpected #MISSING results | `SET AGGMISSG` setting wrong | Review SET commands |
| Rule overwrites existing data | Cross-dimensional reference (`->`) syntax wrong | Verify source/target members |

---

## Quick Recall

1. **What does a FIX statement control?** → Which data blocks Essbase loads from disk for the calculation.
2. **Sparse vs dense in FIX — which matters more for performance?** → Sparse — it controls block-level I/O.
3. **What does `SET CREATEBLOCKONEQ ON` do?** → Creates new sparse blocks when a formula writes a non-missing value.
4. **Difference between substitution variables and runtime prompts?** → Sub vars are admin-set and application-wide; RTPs are user-provided at rule launch.
5. **What is a Ruleset?** → A group of rules that run in a defined sequence or in parallel.

**Teach-back prompt:** Explain to a colleague why a business rule that works for one scenario might run extremely slowly when the FIX statement is removed.

---

## Source Provenance

| Source | Files |
|--------|-------|
| ChatGPT | `Calc Manager/02_Palette_Objects_Deep_Dive/06_FIX_Component.md`, `Calculations_and_Allocations/04_Variables_and_Prompts/`, `03_System_Templates_Deep_Dive/` |
| Claude | `08_Calculation_Manager/08.01-08.06` |
| Gemini | `Calc Manager/` (mirrors ChatGPT structure) |
| Oracle | [Designing with Calculation Manager](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/) |

