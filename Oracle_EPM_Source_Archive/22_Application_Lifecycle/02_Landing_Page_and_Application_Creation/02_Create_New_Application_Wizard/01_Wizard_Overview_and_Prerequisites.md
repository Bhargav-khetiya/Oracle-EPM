# 🚀 Path 2: Create a New Application
## Application Creation Wizard — Complete Overview

> **Navigation:** `Planning Landing Page → START button`  
> **What It Does:** Launches a multi-step wizard to create a custom Planning application  
> **Time Required:** 15–45 minutes (wizard) + post-creation configuration  
> **Reversible:** ❌ No — requires environment reset to remove

---

## 🎯 Purpose

The **START** button launches the **Application Creation Wizard** — a multi-step guided process that allows you to build a Planning application from scratch, tailored to your organization's specific requirements.

---

## 🔀 Application Types Available

When you click START, the wizard eventually asks you to choose an **Application Type**. The available types depend on your subscription (Standard vs Enterprise):

### Application Type Comparison

| Application Type | Subscription | Pre-built Content | Flexibility | Best For |
|-----------------|-------------|-------------------|-------------|----------|
| **Planning (Modules)** | Standard / Enterprise | ✅ High | Medium | Standard financial planning with best-practice modules |
| **FreeForm** | Standard / Enterprise | ❌ None | ✅ Maximum | Custom modeling, unique use cases, Essbase-like |
| **Custom (Legacy)** | Standard / Enterprise | ❌ None | High | Highly customized planning without module framework |

### Available Modules (within Planning type)

| Module | Description | Pre-built Content |
|--------|-------------|-------------------|
| **Financials** | Revenue, expense, P&L, balance sheet, cash flow planning | Forms, rules, dashboards, KPIs |
| **Workforce** | Headcount, compensation, benefits, labor cost planning | Forms, rules, dashboards, KPIs |
| **Capital** | Capital asset planning, depreciation, lifecycle management | Forms, rules, dashboards, KPIs |
| **Projects** | Project financial planning, resource allocation | Forms, rules, dashboards, KPIs |
| **Strategic Modeling** | Long-range strategic financial modeling and scenario analysis | Models, templates, what-if scenarios |
| **Sales Planning** | Revenue planning, quota setting, territory management | Forms, rules, dashboards, KPIs |

---

## 📋 Wizard Steps Summary

The wizard flows through these screens (exact order may vary by version):

```
┌─────────────────────────────────────────────────────────┐
│                    WIZARD FLOW                           │
│                                                          │
│   Step 1: General Properties                             │
│   ├── Application Name                                   │
│   ├── Description                                        │
│   └── Application Type                                   │
│          │                                                │
│          ▼                                                │
│   Step 2: Select Modules (if Planning type)              │
│   ├── ☐ Financials                                       │
│   ├── ☐ Workforce                                        │
│   ├── ☐ Capital                                          │
│   ├── ☐ Projects                                         │
│   ├── ☐ Strategic Modeling                               │
│   └── ☐ Sales Planning                                   │
│          │                                                │
│          ▼                                                │
│   Step 3: Calendar Setup                                 │
│   ├── Start Year                                         │
│   ├── End Year                                           │
│   ├── Fiscal Year Start Month                            │
│   ├── Period Type (12 months / 13 periods / Custom)      │
│   └── Weekly Distribution                                │
│          │                                                │
│          ▼                                                │
│   Step 4: Currency Configuration                         │
│   ├── Main Currency                                      │
│   ├── Multi-Currency (Yes/No)                            │
│   └── Additional Currencies                              │
│          │                                                │
│          ▼                                                │
│   Step 5: Review & Create                                │
│   ├── Summary of all settings                            │
│   └── [Create] button                                    │
│                                                          │
│   ─── OR (if FreeForm) ───                               │
│                                                          │
│   Step 2F: Cube Setup (FreeForm)                         │
│   ├── Number of Cubes                                    │
│   ├── Cube Names                                         │
│   └── Cube Types (BSO/ASO)                               │
│          │                                                │
│          ▼                                                │
│   Step 3F: Dimension Setup (FreeForm)                    │
│   ├── Account dimension mapping                          │
│   ├── Entity dimension mapping                           │
│   └── Period dimension mapping                           │
│          │                                                │
│          ▼                                                │
│   Step 4F: Review & Create (FreeForm)                    │
└─────────────────────────────────────────────────────────┘
```

---

## ⚠️ Critical Decisions (Irreversible After Creation)

> [!CAUTION]
> The following settings **CANNOT be changed** after the application is created:

| Setting | Why Irreversible | Impact |
|---------|-----------------|--------|
| **Application Name** | Used as database identifier | Cannot rename the application |
| **Start Year** | Defines the beginning of the time dimension | Cannot add earlier years |
| **Fiscal Year Start Month** | Defines period-to-quarter mapping | Affects all period calculations |
| **Multi-Currency** | Creates/omits currency dimension | Cannot add currency dimension later |
| **Application Type** | Determines fundamental architecture | Cannot switch Planning ↔ FreeForm |

> [!TIP]
> **Best Practice:** Before clicking START, document your requirements for ALL irreversible settings. Have them reviewed and approved by key stakeholders.

---

## 📊 Standard vs Enterprise Subscription Differences

| Feature | Standard | Enterprise |
|---------|----------|------------|
| Planning Modules (Financials, Workforce, Capital, Projects) | ✅ | ✅ |
| FreeForm Applications | ✅ | ✅ |
| Strategic Modeling | ❌ | ✅ |
| Sales Planning | ❌ | ✅ |
| Predictive Cash Forecasting | ❌ | ✅ |
| Advanced EDM Integration | ❌ | ✅ |
| Maximum BSO Cubes | 4 | 12 |
| Maximum ASO Cubes | 1 | 12 |
| Maximum Dimensions | 20 | 29 |
| Groovy Business Rules | ✅ | ✅ |
| Sandbox Support | ✅ | ✅ |

---

## 🔗 Detailed Step Guides

| Step | Document | Description |
|------|----------|-------------|
| Step 1 | [General Properties](./02_Step1_General_Properties.md) | Name, Description, Type |
| Step 2 | [Application Type Selection](./03_Step2_Application_Type_Selection.md) | Choosing your app type |
| Step 3 | [Calendar Setup](./04_Step3_Calendar_Setup.md) | Fiscal year and period config |
| Step 4 | [Currency Configuration](./05_Step4_Currency_Configuration.md) | Currency settings |
| Step 5 | [Review & Create](./06_Step5_Review_and_Create.md) | Final review and creation |
| Modules | [Modules Overview](../03_PreBuilt_Planning_Modules/01_Modules_Architecture_Overview.md) | All available modules |
| FreeForm | [FreeForm Overview](../04_FreeForm_Application/01_FreeForm_Architecture_and_Use_Cases.md) | FreeForm application setup |
| ← Back | [Master Index](../../00_MASTER_INDEX.md) | Return to main index |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What happens if an administrator's browser session times out while configuring Step 4 of the wizard?
**Answer:** The wizard state is kept purely in temporary browser session memory until the final **Create** button is clicked on Step 5. If the session times out (typically after 60 minutes of inactivity) or the browser is accidentally closed, all inputs are discarded and no changes are committed to the cloud database. The administrator must start over from Step 1.

### Q2: Can core architectural prerequisites (such as Calendar distribution or Multi-Currency) be altered post-creation?
**Answer:** No. Parameters configured in Steps 1 through 4 (Application Name, Calendar First Month, Period Granularity, Multi-Currency support) are **permanently immutable**. If these prerequisites are incorrectly specified, the entire application must be deleted and rebuilt from scratch.

### Q3: Does the wizard validate custom dimension names against Essbase reserved words before creation?
**Answer:** The wizard checks basic naming rules (alphanumeric characters, length constraints), but it does not catch all reserved Essbase tokens (such as CALC, ALL, DEFAULT) until the final database initialization phase. Always ensure proposed dimension names avoid Essbase formula script keywords.
