# Professional Development — Index

> This section prepares you for the professional aspects of an Oracle EPM career: the techno-functional consultant role, interview preparation (120+ twisted trap questions), implementation methodology, emergency production scenarios, and career growth.

---

## Reading Order

| # | Document | What You'll Learn | Time |
|---|----------|------------------|------|
| 1 | [01_Techno_Functional_Consultant_Guide.md](01_Techno_Functional_Consultant_Guide.md) | Role definition, the functional-technical bridge, methodology | 30 min |
| 2 | [02_Interview_Preparation.md](02_Interview_Preparation.md) | 120+ twisted interview questions across all EPM topics with detailed answers | 120 min |
| 3 | [03_Implementation_Methodology.md](03_Implementation_Methodology.md) | Implementation phases, deliverables, best practices | 45 min |
| 4 | [04_Emergency_Scenarios.md](04_Emergency_Scenarios.md) | 10 production crisis war stories with step-by-step resolution | 45 min |

## What Is a Techno-Functional Consultant?

Many candidates fail reviews because they sound too purely functional (only know how to click forms) or too purely technical (only know calc scripts but don't understand GAAP/IFRS or corporate planning cycles).

A **Senior Techno-Functional Consultant** bridges both worlds:

```
FUNCTIONAL BUSINESS LANGUAGE (CFO/Planners)  ←═══→  TECHNICAL KERNEL REALITY (Essbase)

"We need to plan marketing rent by department"   ←→  Sparse Block: Entity + Department
"We need to see revenue in USD and EUR"          ←→  Triangulation & Currency Dimension
"Only approved managers can edit salaries"       ←→  Cell-Level Security + Valid Intersections
"Form save must calculate bonuses instantly"     ←→  Groovy Dynamic Micro-FIX (< 200ms)
"Consolidated reporting must be sub-second"      ←→  ASO Load Buffers & Smart Push
```

## The 3-Part Consultant Response Protocol

When answering any technical question, follow this structure:

1. **Part 1 — Functional Definition (The Business "Why"):** State the business purpose in executive terms
2. **Part 2 — Technical Architecture (The Engine "How"):** Explain what happens behind the scenes
3. **Part 3 — Pro-Tip / Tradeoff (The Architect Insight):** Share the performance trap or best practice

### Example

> **Q:** "What happens when you enable Sandboxes?"
>
> **A1 (Functional):** "Sandboxes let planners experiment with what-if scenarios without affecting the official budget."
>
> **A2 (Technical):** "Enabling Sandboxes creates the system dimension `HSP_View` with members like `BaseData`, `Sandbox_Active`. It stores user deltas as virtual block variations."
>
> **A3 (Architect):** "However, Sandboxes increase block storage overhead and complicate calc scripts. Once enabled at app creation, `HSP_View` **cannot be removed**."

## Interview Question Categories

| Category | Question Count | Topics |
|----------|---------------|--------|
| **Architecture & Essbase** | 30+ | Sparse/Dense, blocks, caches, Hybrid BSO |
| **Calc Manager & Groovy** | 30+ | Block creation bloat, FIX optimization, Groovy patterns |
| **Forms & Data Movement** | 30+ | Forms, Smart Push, ASO slices, data maps |
| **Modules & Troubleshooting** | 30+ | EPBCS modules, security, emergency scenarios |

---

> **Provenance:** Content merged from ChatGPT (`Techno_Functional_Consultant_Review_Bible/` — 8 files), Claude (`21_Interview/`, `24_Architect_Masterclass/`, `19_Implementation/`), Gemini (`Techno_Functional_Consultant_Review_Bible/` — 8 files)
