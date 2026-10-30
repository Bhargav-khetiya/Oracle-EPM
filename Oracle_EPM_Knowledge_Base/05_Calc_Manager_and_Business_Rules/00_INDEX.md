# Calculation Manager and Business Rules — Index

> Calculation Manager is the tool where you create, manage, and deploy all calculation logic in Oracle EPM Cloud. This section covers the Calc Manager interface, rule types, calc scripts, 400+ functions, allocation patterns, Groovy rules, system templates, and performance optimization.

---

## Reading Order

| # | Document | What You'll Learn | Time |
|---|----------|------------------|------|
| 1 | [01_Calc_Manager_Overview.md](01_Calc_Manager_Overview.md) | Interface, views, rule types, palette components, visual vs script mode | 45 min |
| 2 | [02_Business_Rules_Design.md](02_Business_Rules_Design.md) | Creating rules, FIX statements, variables, runtime prompts, deployment | 60 min |
| 3 | [03_Calculation_Functions_Reference.md](03_Calculation_Functions_Reference.md) | All function categories with syntax and examples | 45 min |
| 4 | [04_Calculations_and_Allocations.md](04_Calculations_and_Allocations.md) | Allocation templates, top-down vs bottom-up, driver-based calcs | 45 min |
| 5 | [05_Groovy_Rules.md](05_Groovy_Rules.md) | Groovy in Calc Manager, DataGridBuilder, dynamic FIX, throwVetoException | 60 min |
| 6 | [06_Troubleshooting_and_Performance.md](06_Troubleshooting_and_Performance.md) | Debugging, SET commands, bottom-up vs top-down execution, block creation | 30 min |

## Key Architecture at a Glance

```
Calc Manager UI (Visual Flowchart Canvas)
├── 8 Palette Objects:
│   ├── Formula Component (LHS = RHS assignment)
│   ├── Script Component (raw Essbase calc script)
│   ├── Condition Component (IF/ELSEIF/ELSE branching)
│   ├── Member Block Component (anchor calculations)
│   ├── Member Range Component (LOOP traversal)
│   ├── FIX Component (multidimensional slicing)
│   ├── Rule Object (sequencing unit)
│   └── RuleSet Object (parallel execution container)
│
├── 8 System Templates:
│   ├── Allocation, Allocate Level-to-Level
│   ├── Clear Data, Copy Data
│   ├── Amount/Rate, Aggregation
│   ├── Currency Conversion
│   └── Custom Design-Time Prompt
│
├── 4 Variable Scopes:
│   ├── Application, Plan Type, Rule, Global
│   └── + Substitution Variables + Runtime Prompts
│
└── 2 Rule Modes:
    ├── Visual (flowchart canvas — reversible)
    └── Script (raw text — permanent conversion if non-standard syntax)
```

## Critical Performance Facts

| Concept | Key Takeaway |
|---------|-------------|
| **Bottom-Up vs Top-Down** | Bottom-Up is 300x faster than Top-Down. Avoid sparse IF statements |
| **Block Creation Bloat** | `SET CREATEBLOCKONEQ ON` without strict FIX causes gigabyte database bloat |
| **Groovy Micro-FIX** | Slicing calc to `cell.isEdited()` cuts form save latency from 45s to 200ms |
| **Pre-Save Validation** | `throwVetoException()` rolls back dirty blocks atomically with custom HTML alerts |
| **Hybrid BSO** | Dynamic sparse calc eliminates batch `AGG` and `CALC DIM` scripts |
| **SET Commands** | Always: `CACHE HIGH`, `LOCKBLOCK HIGH`, `UPDATECALC OFF`, `AGGSPARSESEL ON` |

## Prerequisites

Before studying Calc Manager, you should understand:
- Essbase architecture (blocks, sparse/dense) → [07_Essbase_Architecture](../07_Essbase_Architecture/00_INDEX.md)
- Dimension properties → [08_Dimensions_and_Metadata](../08_Dimensions_and_Metadata/00_INDEX.md)

---

> **Provenance:** Content merged from ChatGPT (`Calc Manager/` — 30+ files), Claude (`07_Business_Rules/`, `08_Calculation_Manager/`), Gemini (`Calc Manager/` — 30+ files)
