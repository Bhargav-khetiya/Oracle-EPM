# Study Path and Learning Roadmap — Your 12-Week Plan

> **Folder:** 00_Foundation | **Audience:** Complete beginner → Architect
>
> **Provenance:** Merged from Claude `00.01_Master_Learning_Roadmap.md`, `00.02_Career_Pathways.md`, `00.04_Progress_Tracker.md`; ChatGPT `LEARNING_ROADMAP.md`; Gemini `LEARNING_ROADMAP.md`, `START_HERE.md`

---

## Choose Your Learning Track

```
┌────────────────────────────────────────────────────────────────────┐
│                    CHOOSE YOUR LEARNING TRACK                      │
└────────────────────────────────────────────────────────────────────┘
        │                          │                          │
        ▼                          ▼                          ▼
 🟢 COMPLETE BEGINNER        🟡 MID-LEVEL               🔴 SENIOR DEFENSE
 "Never touched EPM"         "Know forms/rules;          "Technical review
                              need performance            or interview soon"
                              tuning"
        │                          │                          │
        ▼                          ▼                          ▼
   Track 1: Foundation        Track 2: Engineering      Track 3: War Room
   (Weeks 1-12 below)        (Start at Week 5)         (15_Professional_Dev)
```

---

## The Master Principle: Follow the Data

```
The secret to mastering Oracle EPM is ONE principle: FOLLOW THE DATA.

  1. Where does data COME FROM?    → Finance/Business (Foundation)
  2. Where is data STORED?         → Essbase Engine (07_Essbase)
  3. How is the CONTAINER built?   → Planning App + Dimensions (08_Dimensions)
  4. How does the USER see it?     → Forms + Smart View (02_UI, 10_Smart_View)
  5. How is data CALCULATED?       → Business Rules + Calc Mgr (05_Calc_Manager)
  6. How does data GET IN/OUT?     → Data Integration + REST (06_Data_Integration)
  7. How is it SECURED?            → Security + Administration (01_Security, 04_Admin)
  8. How do you EXTEND it?         → Groovy + EPM Automate (03_Groovy, 12_EPM_Automate)
```

---

## Time Commitment

| Your Background | Weekly Hours | Total Duration |
|-----------------|-------------|----------------|
| IT professional, no finance | 15–20 hrs/week | 12 weeks |
| Finance professional, some IT | 12–15 hrs/week | 10 weeks |
| Fresh graduate | 20–25 hrs/week | 14–16 weeks |
| Experienced Hyperion consultant | 8–10 hrs/week | 6 weeks (review mode) |

---

## Week-by-Week Plan

### Weeks 1–2: The Business Brain
**Goal:** Understand WHY EPM exists and the business context

| Read | Topic |
|------|-------|
| [00_Foundation/01_What_Is_EPM.md](01_What_Is_EPM.md) | What EPM is, EPM vs ERP |
| [00_Foundation/02_EPM_Architecture.md](02_EPM_Architecture.md) | Cloud architecture, OCI |
| [00_Foundation/03_EPM_History.md](03_EPM_History.md) | Hyperion → cloud evolution |
| [02_Finance_Concepts/](../02_Finance_Concepts/00_INDEX.md) | Financial statements, P&L, Balance Sheet |

**Milestone:** Can explain what EPM is, why companies use it, and draw the architecture on a whiteboard.

### Weeks 3–4: The Engine Room
**Goal:** Understand HOW the database works

| Read | Topic |
|------|-------|
| [07_Essbase_Architecture/](../07_Essbase_Architecture/00_INDEX.md) | BSO/ASO, blocks, sparse/dense |
| [08_Dimensions_and_Metadata/](../08_Dimensions_and_Metadata/00_INDEX.md) | Dimension types, member properties |
| [11_Smart_Lists/](../11_Smart_Lists/00_INDEX.md) | Text-to-ID dropdowns |

**Milestone:** Can explain sparse vs dense, draw a cube, and describe how data is physically stored.

### Weeks 5–6: Building the Application
**Goal:** Create forms and data entry screens

| Read | Topic |
|------|-------|
| [02_User_Interface_and_Navigation/](../02_User_Interface_and_Navigation/00_INDEX.md) | Navigation flows, forms, dashboards |
| [09_EPBCS_Modules/](../09_EPBCS_Modules/00_INDEX.md) | Pre-built modules |
| [13_Action_Menus/](../13_Action_Menus/00_INDEX.md) | Context menus |

**Milestone:** Can design a planning form with proper dimensions, validation, and context menus.

### Weeks 7–8: The User Experience
**Goal:** Master calculations and security

| Read | Topic |
|------|-------|
| [05_Calc_Manager_and_Business_Rules/](../05_Calc_Manager_and_Business_Rules/00_INDEX.md) | Calc scripts, rules, functions |
| [01_Security_and_Access/](../01_Security_and_Access/00_INDEX.md) | Roles, permissions, data access |
| [03_Workflow_and_Task_Management/](../03_Workflow_and_Task_Management/00_INDEX.md) | Task lists, approvals |

**Milestone:** Can write a basic business rule and configure role-based security.

### Weeks 9–10: Logic and Automation
**Goal:** Advanced development and integration

| Read | Topic |
|------|-------|
| [03_Groovy_Scripting/](../03_Groovy_Scripting/00_INDEX.md) | Groovy in EPM |
| [06_Data_Integration_and_Exchange/](../06_Data_Integration_and_Exchange/00_INDEX.md) | Data maps, Smart Push, ETL |
| [10_Smart_View/](../10_Smart_View/00_INDEX.md) | Excel analytics, VBA |

**Milestone:** Can write Groovy rules, configure data integrations, and automate Smart View.

### Weeks 11–12: Integration and Administration
**Goal:** Production readiness

| Read | Topic |
|------|-------|
| [12_EPM_Automate/](../12_EPM_Automate/00_INDEX.md) | CLI scripting, scheduling |
| [14_Application_Lifecycle/](../14_Application_Lifecycle/00_INDEX.md) | Migration, LCM, governance |
| [04_System_Administration/](../04_System_Administration/00_INDEX.md) | Maintenance, monitoring |

**Milestone:** Can manage a production EPM environment end-to-end.

### Beyond Week 12: Architect Level

| Read | Topic |
|------|-------|
| [15_Professional_Development/](../15_Professional_Development/00_INDEX.md) | Interview prep, methodology |
| [16_Performance_Tuning/](../16_Performance_Tuning/00_INDEX.md) | Optimization |
| [17_Labs_and_Case_Studies/](../17_Labs_and_Case_Studies/00_INDEX.md) | Hands-on practice |

**Milestone:** Can design an entire EPM solution from requirements to production deployment.

---

## Mastery Levels

| Level | Description |
|-------|-------------|
| **Beginner** (Weeks 1–4) | Can explain EPM, Essbase, dimensions, and draw the architecture |
| **Consultant** (Weeks 5–8) | Can build apps, create forms, write basic rules, configure security |
| **Senior Consultant** (Weeks 9–12) | Can write Groovy, set up integrations, troubleshoot performance |
| **Architect** (Beyond) | Can design full solutions, defend architecture, handle production crises |

---

## Daily Study Routine

```
Morning (1 hour):
  📖 Read one module section
  ✍️  Take notes on key concepts

Afternoon (1 hour):
  🧠 Answer recall questions WITHOUT notes
  📝 Write down what you don't understand

Evening (30 min):
  📖 Re-read weak areas
  💬 Try to explain today's topic out loud
```

---

## Common Study Mistakes

| Mistake | Why It Hurts | Fix |
|---------|-------------|-----|
| Reading randomly | You'll learn FIX statements before dimensions | Follow this roadmap |
| Skipping finance | You'll fail every P&L interview question | Start with Foundation |
| Only reading, no practice | Reading ≠ mastery | Do the labs in 17_Labs |
| Memorizing syntax | Interviewers test understanding, not memorization | Understand the "why" |
| Skipping self-checks | You think you know it, but you don't | Answer every recall question without notes |

---

## 🧠 Self-Check

After each week, can you answer these without notes?
1. What did I learn this week?
2. Can I explain each concept to a non-technical person?
3. Can I draw the relevant architecture diagram from memory?
4. Which topics am I least confident about?

> **Remember:** Every expert was once a beginner. Follow the path, read every file, practice, and you'll be able to answer questions that 10-year EPM veterans struggle with.

