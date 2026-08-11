# Creating and Running an EPM Center of Excellence — Complete Markdown Edition

> **Original PDF:** `Creating_and_Running_an_EPM_Center_of_Excellence.pdf` | **Folder:** Level 1 (Beginner & Foundations)  
> **Purpose:** Definitive Markdown guide on building an Oracle EPM Center of Excellence (CoE), enterprise governance frameworks, change management, and patching governance.

---

## Table of Contents
1. [What is an EPM Center of Excellence (CoE)?](#what-is-coe)
2. [The 4 Core Pillars of an EPM CoE](#core-pillars)
3. [CoE Roles & Organizational Hierarchy](#roles-and-hierarchy)
4. [Patching Governance & Monthly Update Lifecycle](#patching-governance)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. What is an EPM Center of Excellence (CoE)? <a name="what-is-coe"></a>

An **EPM Center of Excellence (CoE)** is a unified cross-functional committee of business leaders, financial architects, and IT specialists responsible for overseeing cloud adoption, governance, security standards, and continuous enhancement of Oracle EPM Cloud applications across the enterprise.

---

## 2. The 4 Core Pillars of an EPM CoE <a name="core-pillars"></a>

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THE 4 PILLARS OF AN EPM CoE                     │
├──────────────────────┬──────────────────────────┬──────────────────────┤
│ 1. Strategic Align   │ 2. Technical Governance  │ 3. Change Enablement │
│    & Roadmap         │    & Standards           │    & Training        │
├──────────────────────┼──────────────────────────┼──────────────────────┤
│ • Prioritizes module │ • Enforces naming rules  │ • Onboards new teams │
│   rollouts           │ • Controls EDMCS sync    │ • Manages UAT signoff│
│ • ROI tracking       │ • Manages security groups│ • Monthly newsletters│
└──────────────────────┴──────────────────────────┴──────────────────────┘
```

---

## 3. CoE Roles & Organizational Hierarchy <a name="roles-and-hierarchy"></a>

| CoE Role | Typical Corporate Title | Key Responsibilities |
| :--- | :--- | :--- |
| **Executive Sponsor** | CFO / VP of FP&A | Approves capital budget, enforces cross-departmental mandate, resolves executive escalation. |
| **CoE Lead / Product Owner** | Lead EPM Architect | Owns technical backlog, architectural design, multi-pod integration, and Oracle SR management. |
| **Business Champion** | Senior FP&A Manager | Defines functional planning requirements, validates calculation accuracy, leads end-user testing. |
| **Security & Access Lead** | IT Security Administrator | Manages IDCS/AD groups, enforces Segregation of Duties (SoD), monitors audit logs. |

---

## 4. Patching Governance & Monthly Update Lifecycle <a name="patching-governance"></a>

Oracle pushes updates on the **first Friday (Test/Dev pods)** and **third Friday (Production pods)** of every month. The CoE manages the 14-day validation window:

```
[FIRST FRIDAY] -> Oracle applies patch to Test/Dev Pods
       │
       ▼ (Days 1 - 5)
[AUTOMATED REGRESSION TESTING] -> Run EPM Automate test suite & check calculation accuracy
       │
       ▼ (Days 6 - 10)
[BUSINESS UAT & SIGN-OFF] -> FP&A Champions verify critical forms, reports, and Data Maps
       │
       ▼ (THIRD FRIDAY)
[PRODUCTION DEPLOYMENT] -> Oracle applies patch to Production Pods during Daily Maintenance
```

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`00_Foundation/06_CoE_and_Governance_Deep_Reference.md`** — Core CoE charter and operational model.
- **`18_Production_Support/01_Production_Support_Guide.md`** — Monthly patching checklists and backup governance.
- **`24_Architect_Masterclass/01_The_Springboard_and_Settings_Map.md`** — Daily Maintenance window setup.
