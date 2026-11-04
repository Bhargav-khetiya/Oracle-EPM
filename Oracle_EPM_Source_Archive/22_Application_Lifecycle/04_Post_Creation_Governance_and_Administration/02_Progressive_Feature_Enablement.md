﻿# 🧩 Enable Features Post-Creation — Master Guide
## Progressively Unlocking Planning Modules, Advanced Platform Capabilities & AI Tools

> **Navigation:** `Home → Application → Configure` OR `Home → Application → Overview → Actions (▼) → Enable Features`  
> **Applicability:** Module-based Planning Applications (Enterprise & Standard Subscriptions)  
> **Role Requirement:** Service Administrator  
> **Core Concept:** Incremental feature enablement allows organizations to deploy a phased roadmap without reimplementing the application

---

## 🧭 Entry Point: The Configure & Enable Features Workbench

In Oracle Cloud EPM Planning, modules do not have to be turned on simultaneously during day one. Service Administrators can enable modules and specific sub-features progressively across development phases.

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Configure Application                                                                       [ Help ❓ ] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Select a module to configure or enable features:                                                       │
│                                                                                                        │
│   ┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐                          │
│   │ 💰 Financials       │   │ 👥 Workforce        │   │ 🏗️ Capital           │                          │
│   │ Status: Enabled     │   │ Status: Not Enabled │   │ Status: Not Enabled │                          │
│   │ [Enable Features]   │   │ [Enable Features]   │   │ [Enable Features]   │                          │
│   └─────────────────────┘   └─────────────────────┘   └─────────────────────┘                          │
│                                                                                                        │
│   ┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐                          │
│   │ 📊 Projects         │   │ 📈 Strategic Model  │   │ 💼 Sales Planning   │                          │
│   │ Status: Not Enabled │   │ Status: Not Enabled │   │ Status: Not Enabled │                          │
│   │ [Enable Features]   │   │ [Enable Features]   │   │ [Enable Features]   │                          │
│   └─────────────────────┘   └─────────────────────┘   └─────────────────────┘                          │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## ⚠️ The Golden Law of Feature Enablement

> [!CAUTION]
> **IRREVERSIBLE ACTION:**  
> Once any module or sub-feature is enabled and saved, **it CANNOT be disabled, turned off, or removed!**  
> - Enabling a feature injects permanent dimension members, pre-built calculation rules, forms, and relational tables into the schema.  
> - Even if you do not use the enabled feature, its dimension members and calculation overhead remain in the application outline.  
> - **Always test feature enablement in your TEST / Sandbox instance first** and perform rigorous regression testing before applying to PRODUCTION!

---

## 💰 1. Enabling Financials Progressively

If Financials is already enabled with Revenue and Expense, you can subsequently enable Balance Sheet and Cash Flow.

**Navigation:** `Application → Configure → Financials → Actions → Enable Features`

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Enable Features: Financials                                                   [ Enable ]  [ Cancel ]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                        │
│ Revenue:                                                                                               │
│   ☑ Revenue Planning (Already Enabled)                                                                 │
│       ☑ Accounts Receivable Driver                                                                     │
│                                                                                                        │
│ Expense:                                                                                               │
│   ☑ Expense Planning (Already Enabled)                                                                 │
│                                                                                                        │
│ Balance Sheet:                                                                                         │
│   ☑ Enable Balance Sheet Planning  <-- [NEWLY CHECKED]                                                 │
│       🔘 Driver-Based Balance Sheet                                                                    │
│       🔘 Direct Entry Balance Sheet                                                                    │
│                                                                                                        │
│ Cash Flow:                                                                                             │
│   ☑ Enable Cash Flow Planning      <-- [NEWLY CHECKED]                                                 │
│       🔘 Indirect Cash Flow Method                                                                     │
│       🔘 Direct Cash Flow Method                                                                       │
│                                                                                                        │
│ Rolling Forecast & Granularity:                                                                        │
│   ☑ Rolling Forecast Planning                                                                          │
│   ☐ Weekly Planning (13-period or 52-week calendar required)                                           │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Post-Enablement Tasks for Financials:
1. Run **Database Refresh** to instantiate new Balance Sheet and Cash Flow accounts in `OEP_FS`.
2. Navigate to `Application → Configure → Financials` and run **Driver and Account Configuration** to map custom balance sheet accounts.

---

## 👥 2. Enabling Workforce Progressively

Workforce enables compensation, salary, tax, and headcount planning.

**Cube Activated:** `OEP_WFP` (BSO Hybrid) + `OEP_REP` (ASO)

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Enable Features: Workforce                                                    [ Enable ]  [ Cancel ]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                        │
│ Planning Level:                                                                                        │
│   🔘 Granular (Employee and Job)                                                                       │
│   🔘 Job Only                                                                                          │
│   🔘 Employee Only                                                                                     │
│                                                                                                        │
│ Expense Components:                                                                                    │
│   ☑ Compensation (Salary, Merit, Bonus)                                                                │
│   ☑ Additional Earnings (Overtime, Commissions)                                                        │
│   ☑ Benefits (Health, 401k, Pension)                                                                   │
│   ☑ Taxes (FICA, Medicare, State Unemployment)                                                         │
│   ☑ Non-Compensation Expenses (Travel, Equipment, Training)                                            │
│                                                                                                        │
│ Headcount & Demographics:                                                                              │
│   ☑ Headcount Planning & Transfers                                                                     │
│   ☑ Demographics (Gender, Tenure, Veteran Status, Diversity Tracking)                                  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ 3. Enabling Capital Progressively

Capital manages asset lifecycles, depreciation, lease accounting (IFRS 16 / ASC 842), and repairs.

**Cube Activated:** `OEP_CAP` (BSO Hybrid)

- **Asset Classes:** Tangible Assets (Machinery, Buildings, IT Hardware) and Intangible Assets (Software, Patents).
- **Lease Assets:** Enables calculations adhering strictly to ASC 842 / IFRS 16 lease liability and Right-of-Use (ROU) asset schedules.

---

## 📊 4. Enabling Projects Progressively

Projects manages capital projects, internal investment projects, and billable client contracts.

**Cube Activated:** `OEP_PFP` (BSO Hybrid)

- **Project Types:** Capital Projects, Indirect Projects, Contract / Billable Projects.
- **Resource Planning:** Assign employees and labor rates from Workforce directly into project tasks.

---

## 🚀 5. Advanced Platform Features Available Post-Creation

Beyond functional modules, several high-impact technical platform features can be unlocked post-creation:

### A. Convert to Hybrid BSO Architecture
- **Where:** `Application → Overview → Actions → Convert to Hybrid BSO`
- **What it does:** Converts classic Essbase Block Storage cubes to the modern Hybrid calculation engine. Sparse dynamic calculation members aggregate instantaneously in memory, slashing calculation script run times by up to 90% and reducing database disk footprints.

### B. Enable Groovy Business Rules
- **Requirement:** Enterprise Subscription (or Planning Plus).
- **Where:** Automatically enabled in Calc Manager for Enterprise subscriptions.
- **What it does:** Allows writing custom rule logic in Groovy script. Enables dynamic grid manipulation, targeted REST API execution, real-time input data validation, and sub-second calculation slices.

### C. IPM Insights & Auto-Predict (Predictive AI)
- **Where:** `Application → Overview → Actions → IPM Insights`
- **What it does:** Machine learning algorithms run continuously in the background, analyzing variance patterns, flagging human data entry anomalies, and comparing user budgets against statistical forecast algorithms.

### D. Dashboards 2.0 & Dynamic Forms
- **Where:** `Tools → Navigation Flows` & `Application → Settings`
- **What it does:** Upgrades user dashboards to high-performance Redwood visualizations, composite flex forms, and real-time chart interactions.

---

## 🛠️ Step-by-Step Execution Sequence for Feature Enablement

When rolling out any new feature in a live environment, follow this strict 6-step protocol:

```
[ Step 1: Backup ] ──► Create full LCM Snapshot ("Pre_Feature_Enablement_Backup.zip")
       │
[ Step 2: Configure ] ──► Navigate to Application → Configure → Select Module → Enable Features
       │
[ Step 3: Enable ] ──► Check desired options and click [ Enable ]
       │
[ Step 4: Refresh ] ──► Execute Database Refresh (Mandatory!)
       │
[ Step 5: Metadata ] ──► Import custom accounts, drivers, or entities for the new module
       │
[ Step 6: Deploy ] ──► Deploy Business Rules in Calc Manager & Update Security Grants
```

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Can an enabled module ever be disabled or rolled back—
**Answer:** No. Enabling a module is strictly irreversible. The physical Essbase cubes, dimension hierarchies, forms, and business rules are permanently stamped into the application schema. If a module is no longer needed, you must hide its cards in Navigation Flows, revoke security access, and clear cube data.

### Q2: What happens to existing custom dimensions and data when a new module is enabled—
**Answer:** Progressive feature enablement is non-destructive to existing data. The system provisions new cubes and dimensions alongside existing ones. If a new module introduces an overlapping dimension (e.g. `Entity`), the module integrates with the existing shared hierarchy.

### Q3: What is the recommended deployment order when rolling out modules over a multi-phase implementation—
**Answer:**
1. **Phase 1: Financials** (establishes corporate P&L, balance sheet, and chart of accounts).
2. **Phase 2: Workforce & Capital** (provides detailed operational drivers for payroll and fixed asset depreciation).
3. **Phase 3: Projects** (tri-syncs labor from Workforce and assets from Capital into project costs).
4. **Phase 4: Strategic Modeling** (integrates long-range 10-year plans with annual budgets).

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [01_Application_Settings_Overview.md](./01_Application_Settings_and_Immutability_Matrix.md) |
| **Next →** | [03_Dimension_Management.md](./03_Dimension_Management_and_Member_Properties.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |
