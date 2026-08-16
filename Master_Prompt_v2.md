# 🚀 ORACLE EPM 2.0 — THE MASTER PROMPT (v2)

> **Goal:** Create the ultimate, self-sustaining Oracle EPM Knowledge Base and Study Library that transforms a beginner into a job-ready techno-functional consultant within 3-6 months.
> **Scope:** Oracle Cloud EPM (EPBCS/PBCS, FreeForm), Essbase 26ai/21c, Smart View, Data Integration, EPM Automate, Groovy, and REST APIs.

---

## 1. THE 2.0 VISION & ARCHITECTURE

The 2.0 Knowledge Base is divided into two distinct but interconnected pillars:

1. **The Official Study Library (`/books/`)**
   - The authoritative source of truth.
   - Contains 53 downloaded official Oracle PDFs and 3 HTML references.
   - Categorized by strictly defined learning phases (Foundation → Planning → Essbase → Calc Manager → FreeForm → Data Integration → Automation).
   - Contains a Master Index, 3-to-6 Month Roadmap, and a strict separation of CORE vs REFERENCE.

2. **The Consultant Knowledge Base (`/01_Foundation/` to `/33_Navigation_Encyclopedia/`)**
   - 33 modules containing 332+ highly synthesized, consultant-focused markdown files.
   - Explains the *Why*, *What*, and *How* in plain English.
   - Bridges theory (from the `/books/`) to practice (real-world scenarios like the "Hotel Pvt Ltd" case study).
   - Contains interview questions, hands-on labs, and step-by-step walkthroughs.

**CRITICAL RULE:** These two pillars must endlessly cross-reference each other. When a knowledge base article discusses Business Rules, it must link to `books/04_CALCULATION_MANAGER/CORE/01_Designing_with_Calculation_Manager.pdf`. When the roadmap tells the user to study Planning, it must link to `../04_Planning/`.

---

## 2. THE CONSULTANT TRAJECTORY (3-6 MONTHS)

You must enforce this learning sequence across all content generation and study plans. 

- **Month 1:** Cloud EPM Foundation, Planning Architecture, Essbase Engine Fundamentals.
- **Month 2:** Planning Administration, Forms Design, Calculation Manager (Calc Scripts/Business Rules), Smart View.
- **Month 3:** FreeForm Architecture, Data Integration (Data Management/FDMEE), Security & Access Control.
- **Month 4:** Migration (LCM), EPM Automate CLI, Groovy Scripting for Business Rules.
- **Month 5:** REST APIs, Operations, Troubleshooting, Performance Tuning.
- **Month 6:** Functional Planning Modules (Financials, Workforce), Advanced Project Simulations, Interview Prep.

---

## 3. STRICT CONTENT GENERATION RULES

Whenever generating, rewriting, or updating `.md` files in this project, you MUST obey the following non-negotiable rules:

### A. The "Zero to Pro" Structure
Every conceptual file MUST follow this exact structure:
1. **WHY** — What real-world problem does this solve?
2. **WHAT** — Plain English definition (no jargon assumed).
3. **HOW** — Step-by-step mechanics with ASCII diagrams.
4. **SHOW ME** — Worked example using the "Hotel Pvt Ltd" scenario.
5. **MISTAKES** — Common errors and how to fix them.
6. **TEST ME** — Interview questions at Beginner, Intermediate, and Architect levels.

### B. The "Hotel Pvt Ltd" Running Example
All examples must use this scenario to bridge theory to practice:
- **Company:** "Hotel Pvt Ltd" — 5-star hotel chain across India.
- **Revenue:** ~₹26Cr/year.
- **Scale:** 5 hotels, 500 rooms total.
- Use INR (₹) for Indian context examples, USD ($) for US context examples.

### C. Formatting and Technical Integrity
- **No Broken External Links:** Remove or replace broken `oracle.com` URLs with relative links to the downloaded PDFs in `/books/`.
- **Absolute Local Cross-Referencing:** Use relative paths (e.g., `../Module/file.md` or `../../books/02_PLANNING/CORE/Administering_Planning.pdf`) rigorously.
- **ASCII over Images:** Use ASCII/mermaid diagrams, NOT external image references.
- **Copy-Paste Ready Code:** All calc scripts, MaxL, Groovy, EPM Automate, and REST API blocks must be syntactically perfect and copy-paste ready.

---

## 4. PRODUCT FOCUS & SCOPE BOUNDARIES

**Primary Focus:**
- Oracle Cloud EPM (Planning, FreeForm, Data Management)
- Essbase (specifically BSO, ASO, Hybrid, dense/sparse, calculation logic, block structure)

**Explicitly Excluded (Do Not Teach):**
- Standalone Essbase infrastructure administration (WebLogic, Linux installations).
- Essbase OCI stack deployments.
- Essbase Java API development.
- Deep server-level `essbase.cfg` tuning.
- Legacy Hyperion on-premises server configuration (unless specifically for migration contexts).

---

## 5. AGENT INSTRUCTIONS FOR FUTURE WORK

If you are an AI agent reading this prompt to continue work on the 2.0 Knowledge Base, your standing orders are:

1. **Always check `COURSE_INDEX.md` and `GLOSSARY.md`** at the root to understand the existing namespace before creating new topics.
2. **Ensure all 332 files adhere to the standards** in `.agents/AGENTS.md`. If a file lacks the "Hotel Pvt Ltd" example or the "WHY/WHAT/HOW" structure, flag it for a rewrite.
3. **Maintain the Link Integrity.** The biggest risk to this KB is link rot. Always ensure internal markdown links and PDF links are valid.
4. **Never delete knowledge.** If synthesizing or condensing, always merge the valuable insights, edge cases, and troubleshooting tips.
5. **Enforce the roadmap.** Do not allow advanced topics (like REST APIs) to contaminate foundational modules (like Cloud Setup). Keep the learning path linear and clean.
