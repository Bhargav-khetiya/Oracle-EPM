# Calc Manager Overview — Interface, Views, and Rule Architecture

> **Folder:** 05_Calc_Manager_and_Business_Rules | **Audience:** Beginner → Architect
>
> **Provenance:** Merged from ChatGPT `Calc Manager/Calculations_and_Allocations/` (30+ files); Claude `07_Business_Rules/`, `08_Calculation_Manager/`; Gemini `Calc Manager/Calculations_and_Allocations/` (30+ files)

---

## What Is Calculation Manager?

**Calculation Manager** (Calc Manager) is the tool where you create, manage, and deploy all business calculation logic in Oracle EPM Cloud. Think of it as the workshop where business rules are built.

**Plain language:** When a user saves a form and the system automatically calculates bonuses, currency conversions, or allocations — that's a business rule running. Calc Manager is where you create those rules.

---

## The Interface — Visual Canvas vs Script Mode

Calc Manager offers two ways to write rules:

| Mode | How It Works | Best For |
|------|-------------|----------|
| **Visual Mode** | Drag-and-drop flowchart canvas with palette objects | Beginners, simple rules, collaboration |
| **Script Mode** | Raw text editor for Essbase calc script syntax | Complex rules, advanced optimization |

> **Warning:** Converting a rule to Script mode is **permanent** if you use non-standard syntax. The rule cannot be converted back to Visual mode.

---

## System Views

| View | What You See |
|------|-------------|
| **System View** | All databases, rules, templates, variables across the application |
| **Database View** | Rules and components for a specific plan type (cube) |
| **Custom View** | User-created organizational folders |
| **Deployment View** | Rules and rule sets deployed to the Planning application |

---

## The 8 Palette Objects

In Visual mode, you build rules by dragging palette objects onto the canvas:

| # | Object | Purpose | Essbase Equivalent |
|---|--------|---------|-------------------|
| 1 | **Formula** | LHS = RHS assignment | `"Member" = expression;` |
| 2 | **Script** | Raw Essbase calc script block | Inline script fragment |
| 3 | **Condition** | IF / ELSEIF / ELSE branching | `IF...ELSEIF...ELSE...ENDIF` |
| 4 | **Member Block** | Anchor calculation for a specific member | `"Member"(expression);` |
| 5 | **Member Range** | Loop through member range | `@RANGE / @LOOP` traversal |
| 6 | **FIX** | Scope limiter — the MOST critical object | `FIX(...) ... ENDFIX` |
| 7 | **Rule** | A complete calculation unit | Named rule object |
| 8 | **RuleSet** | Container for sequential/parallel rule execution | Rule sequencing |

---

## The FIX Component — Most Critical Object

FIX defines the **multidimensional boundary** (data slice) for calculations. It instructs Essbase which physical data blocks to process.

```
Without FIX: Essbase processes ALL 500,000 blocks → 45 seconds
With FIX:    Essbase processes only 450 matching blocks → 0.12 seconds
```

### How FIX Works

```
FIX ("Plan", "FY25", "Working", "Sales_East", @LEVMBRS("Product", 0))
  "Revenue" = "Revenue" * 1.10;
ENDFIX

Step 1: Essbase evaluates the FIX criteria against the Index file (.IND)
Step 2: Only 450 blocks match the criteria
Step 3: Only those 450 blocks are loaded into Data Cache
Step 4: Calculation runs ONLY on those blocks
Step 5: 499,550 unmatched blocks are NEVER touched
```

### Sparse vs Dense in FIX

| Dimension Type in FIX | Effect |
|----------------------|--------|
| **Sparse dimension** | Reduces which BLOCKS are loaded from disk (major I/O savings) |
| **Dense dimension** | Reduces which CELLS within blocks are modified (minor savings) |

> **Best Practice:** Always FIX on specific sparse members. Never leave Scenario, Version, or Year unconstrained.

---

## Variables and Runtime Prompts

### Variable Scopes

| Scope | Visibility | Use Case |
|-------|-----------|----------|
| **Global** | All applications, all plan types | Company-wide settings |
| **Application** | All plan types in the application | App-level defaults |
| **Plan Type** | Specific plan type only | Cube-specific parameters |
| **Rule** | Single rule only | Local working variables |

### Runtime Prompts (RTPs)

When a rule runs, it can ask the user for input:

```
/* Runtime Prompt: Ask user which scenario to calculate */
FIX ({RTP_Scenario}, {RTP_Year})
  "Revenue" = "Revenue" * 1.10;
ENDFIX
```

### Substitution Variables

Global variables that administrators set and all rules can reference:

```
/* Example: &CurrYear = "FY26", &CurrMonth = "Oct" */
FIX ("Budget", &CurrYear, @LEVMBRS("Entity", 0))
  "Revenue" = "Revenue"->prior(Period);
ENDFIX
```

---

## System Templates — Pre-Built Calculation Patterns

| Template | Purpose |
|----------|---------|
| **Allocation** | Distribute amounts from a source to targets using a driver |
| **Allocate Level-to-Level** | Cascading waterfall allocations between hierarchy levels |
| **Clear Data** | Physical (`CLEARBLOCK`) or logical (`CLEARDATA`) data clearing |
| **Copy Data** | Block-level `DATACOPY` vs cell-by-cell assignment |
| **Amount/Rate** | Driver-based modeling (Volume × Rate) |
| **Aggregation** | `CALC DIM` vs `AGG` — Hourglass principle compliance |
| **Currency Conversion** | P&L vs Balance Sheet rates, rate tables, triangulation |
| **Custom DTP** | Building custom wizards with Design-Time Prompts |

---

## Rule Deployment and Lifecycle

```
Create Rule → Validate → Deploy → Attach to Form/Action Menu → Test → Production

1. VALIDATE: Compiler checks syntax, member names, variable references
2. DEPLOY: Makes the rule available in Planning application
3. ATTACH: Link to a form (on save/on load) or action menu
4. TEST: Run with representative data in non-production environment
```

---

## 🧠 Self-Check Questions

1. **What are the 8 palette objects in Calc Manager?**
2. **What is the difference between Visual and Script mode?**
3. **Why is the FIX component the most critical object?**
4. **What happens if you FIX on a sparse dimension vs a dense dimension?**
5. **What are the four variable scopes?**
6. **What is a Runtime Prompt and when would you use one?**

> **Teach-back prompt:** Explain to a new developer why every calculation should start with a FIX statement. Then describe what happens inside Essbase when a FIX statement is evaluated.

---

## What's Next?

→ [02_Business_Rules_Design.md](02_Business_Rules_Design.md) — Creating rules, FIX patterns, variables, deployment

