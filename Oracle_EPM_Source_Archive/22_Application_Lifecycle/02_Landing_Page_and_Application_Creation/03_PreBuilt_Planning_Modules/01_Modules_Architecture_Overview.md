﻿# 📦 Planning Modules — Complete Overview
## All Available Modules and Their Architecture

> **Context:** When creating a Planning application (not FreeForm), you can enable pre-built modules  
> **Access:** During creation (Step 2) or post-creation (Application → Configure → Enable Features)  
> **Key Rule:** Modules can be enabled incrementally but NEVER disabled once enabled

---

## 🏗️ Module Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                    PLANNING MODULES ARCHITECTURE                  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                    Shared Layer                           │    │
│  │  ┌─────────┐  ┌──────────┐  ┌─────────┐  ┌──────────┐  │    │
│  │  │ Period   │  │ Year     │  │ Scenario│  │ Version  │  │    │
│  │  │ Dimension│  │ Dimension│  │ Dim     │  │ Dimension│  │    │
│  │  └─────────┘  └──────────┘  └─────────┘  └──────────┘  │    │
│  │  ┌─────────┐  ┌──────────┐                              │    │
│  │  │ Entity  │  │ Currency │                              │    │
│  │  │ Dimension│  │ Dimension│                              │    │
│  │  └─────────┘  └──────────┘                              │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                    Module Cubes                            │    │
│  │                                                           │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐   │    │
│  │  │ OEP_FS  │  │ OEP_WFP │  │ OEP_CAP │  │ OEP_PFP  │   │    │
│  │  │ Financ. │  │ Workfrce│  │ Capital │  │ Projects │   │    │
│  │  │ (BSO)   │  │ (BSO)   │  │ (BSO)   │  │ (BSO)    │   │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └──────────┘   │    │
│  │                                                           │    │
│  │  ┌──────────────────────────────────────────────────┐    │    │
│  │  │ OEP_REP — Reporting Cube (ASO) — Shared         │    │    │
│  │  └──────────────────────────────────────────────────┘    │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │              Strategic Modeling (Separate)                │    │
│  │  ┌──────────────────────────────────────────────────┐    │    │
│  │  │ Strategic Models (own file-based architecture)    │    │    │
│  │  └──────────────────────────────────────────────────┘    │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📊 Module Comparison Matrix

| Feature | Financials | Workforce | Capital | Projects | Strategic Modeling | Sales Planning |
|---------|-----------|-----------|---------|----------|-------------------|----------------|
| **Subscription** | Std + Ent | Std + Ent | Std + Ent | Std + Ent | Enterprise | Enterprise |
| **Primary Cube** | OEP_FS | OEP_WFP | OEP_CAP | OEP_PFP | Separate | Separate |
| **Cube Type** | Hybrid BSO | Hybrid BSO | Hybrid BSO | Hybrid BSO | File-based | Hybrid BSO |
| **Pre-built Forms** | ✅ 20+ | ✅ 15+ | ✅ 10+ | ✅ 10+ | ✅ Templates | ✅ 15+ |
| **Pre-built Rules** | ✅ 15+ | ✅ 10+ | ✅ 8+ | ✅ 8+ | ✅ Built-in | ✅ 10+ |
| **Dashboards** | ✅ 5+ | ✅ 3+ | ✅ 3+ | ✅ 3+ | ✅ Scenarios | ✅ 5+ |
| **KPI Templates** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Integration** | All modules | Financials, Projects | Financials | Workforce, Financials | Financials | Financials |

---

## 🔄 Module Integration Points

```
                    ┌───────────────┐
                    │   Financials  │
                    │   (OEP_FS)    │
                    └───────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
      ┌───────────┐  ┌───────────┐  ┌───────────┐
      │ Workforce │  │  Capital  │  │ Projects  │
      │ (OEP_WFP) │  │ (OEP_CAP)│  │ (OEP_PFP) │
      └─────┬─────┘  └───────────┘  └─────┬─────┘
            │                              │
            └──────────────────────────────┘
                  Labor Data Sharing
```

### Key Integration Flows:
| From | To | Data Shared |
|------|----|-------------|
| Workforce → Financials | Compensation expense, headcount | Labor costs flow to P&L |
| Capital → Financials | Depreciation expense, asset values | CapEx flows to P&L and BS |
| Projects → Financials | Project costs and revenue | Project financials to P&L |
| Workforce ↔ Projects | Labor rates, job data | Shared resource information |
| All Modules → OEP_REP | All data | Reporting and analytics |

---

## 📋 Enable Features Screen (Post-Creation)

### Navigation: `Application → Configure → [Module Name] → Enable Features`

```
┌──────────────────────────────────────────────────────────────────┐
│  Configure > Financials > Enable Features                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Select features to enable:                                       │
│                                                                   │
│  Revenue and Gross Margin                                         │
│  ☐ Revenue Planning                                               │
│  ☐ Revenue by Product/Service                                     │
│  ☐ Gross Margin Analysis                                          │
│                                                                   │
│  Expenses                                                         │
│  ☐ Operating Expenses                                             │
│  ☐ Cost Center Budgeting                                          │
│  ☐ Driver-Based Expense                                           │
│                                                                   │
│  Financial Statements                                             │
│  ☐ Income Statement                                               │
│  ☐ Balance Sheet                                                  │
│  ☐ Cash Flow Statement                                            │
│                                                                   │
│  Advanced                                                         │
│  ☐ Rolling Forecast                                               │
│  ☐ What-If Scenarios                                              │
│                                                                   │
│  ⚠️ Features cannot be disabled once enabled                     │
│                                                                   │
│  ┌────────┐  ┌────────────┐                                      │
│  │ Cancel │  │  Enable ✓  │                                      │
│  └────────┘  └────────────┘                                      │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Detailed Module Guides

| Module | Document | Description |
|--------|----------|-------------|
| Financials | [Financials Module Guide](./02_Financials_Module_Master_Guide.md) | Complete Financials setup and configuration |
| Workforce | [Workforce Module Guide](./03_Workforce_Module_Master_Guide.md) | Complete Workforce setup and configuration |
| Capital | [Capital Module Guide](./04_Capital_Module_Master_Guide.md) | Complete Capital setup and configuration |
| Projects | [Projects Module Guide](./05_Projects_Module_Master_Guide.md) | Complete Projects setup and configuration |
| Strategic Modeling | [Strategic Modeling Guide](./06_Strategic_Modeling_Master_Guide.md) | Complete SM setup and configuration |
| Sales Planning | [Sales Planning Guide](./07_Sales_Planning_Master_Guide.md) | Complete Sales Planning setup and configuration |
| ← Back | [Wizard Overview](../02_Create_New_Application_Wizard/01_Wizard_Overview_and_Prerequisites.md) | Return to wizard overview |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: How does the shared reporting cube (OEP_REP) bridge data across Financials, Workforce, Capital, and Projects—
**Answer:** Each module has its own dedicated BSO Hybrid calculation cube (OEP_FS for Financials, OEP_WFP for Workforce, OEP_CPX for Capital, OEP_PJC for Projects). Detailed calculations occur in these specialized cubes. To provide unified executive dashboards and cross-functional P&L reporting, pre-built **Data Maps** and **Smart Push** pipelines push aggregated summary data from each BSO cube into OEP_REP, an Aggregate Storage (ASO) cube optimized for fast multi-dimensional reporting.

### Q2: Can an organization enable modules in separate phases over a multi-year implementation roadmap—
**Answer:** Yes. This is called **Progressive Feature Enablement**. You can create the application with Financials in Phase 1, deploy Workforce in Phase 2, and add Capital and Projects in Phase 3. When you enable a new module later, the system provisions the new cube and dimensions without disrupting existing operational data in already-enabled modules.

### Q3: What happens if an administrator deletes or renames a seeded module dimension like Plan Element—
**Answer:** Seeded dimensions (Plan Element, Line Item, Component) are hardcoded into the business rule templates and data forms. Renaming or deleting them causes Calc Manager rule compilation to crash with missing member errors and permanently breaks out-of-the-box data maps. Always use **Aliases** to alter user-facing labels.
