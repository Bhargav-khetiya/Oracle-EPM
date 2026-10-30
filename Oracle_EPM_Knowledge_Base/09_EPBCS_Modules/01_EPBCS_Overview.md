# EPBCS Modules Overview — Application Types and Pre-Built Planning

> **Folder:** 09_EPBCS_Modules | **Audience:** Beginner → Architect
>
> **Provenance:** Merged from ChatGPT `EPBCS_Modules_and_Business_Processes/` (8 files); Claude `04_Planning/`; Gemini `EPBCS_Modules_and_Business_Processes/` (8 files)

---

## What Is EPBCS?

**EPBCS** (Enterprise Planning and Budgeting Cloud Service) is Oracle's enhanced planning product that includes **pre-built modules** for common planning processes. Instead of building everything from scratch, you enable modules that come with pre-configured dimensions, forms, business rules, and data flows.

**Plain language:** Think of EPBCS like buying a pre-furnished apartment vs an empty one. Custom applications = empty apartment (you design everything). EPBCS modules = pre-furnished (move in and start working, customize as needed).

---

## Application Types Comparison

| Type | Modules Available | Custom Dimensions | Best For |
|------|------------------|------------------|---------|
| **Custom** | None (build from scratch) | Unlimited | Unique requirements, full control |
| **Modules (EPBCS)** | All 5 pre-built | Limited additions | Fast implementation, standard processes |
| **FreeForm** | None | Unlimited, no Planning metadata | Pure Essbase, advanced modeling |
| **FCCS** | Consolidation-specific | Consolidation dimensions | Financial consolidation & close |

---

## The 5 Pre-Built Modules

### 1. Financials (OEP_FS) — The Core

The central module where all financial data converges.

| Aspect | Detail |
|--------|--------|
| **BSO Cube** | OEP_FS |
| **ASO Cube** | OEP_REP |
| **Purpose** | P&L, Balance Sheet, Cash Flow planning |
| **Key Features** | Revenue drivers, expense categories, financial statements, rolling forecasts |
| **Revenue Methods** | Driver-based (rate × quantity), trend-based, direct input |
| **Expense Methods** | Per-employee, percentage of revenue, direct entry |

### 2. Workforce (OEP_WFP) — People Planning

| Aspect | Detail |
|--------|--------|
| **BSO Cube** | OEP_WFP |
| **ASO Cube** | OEP_WFREP |
| **Purpose** | Headcount and compensation planning |
| **Granularity Choices** | Employee only, Job only, Employee + Job |
| **Key Features** | FTEs, salary, benefits, merit increases, new hires, transfers |
| **Dedicated Dimensions** | Property, Employee, Job, Union Code, Gender |

### 3. Capital (OEP_CPX) — Asset Planning

| Aspect | Detail |
|--------|--------|
| **BSO Cube** | OEP_CPX |
| **ASO Cube** | OEP_CPXREP |
| **Purpose** | Capital expenditure planning |
| **Key Features** | Asset lifecycle, depreciation methods, IFRS 16/ASC 842 lease accounting |
| **Dedicated Dimensions** | Asset Class, Asset Detail, Lease Asset |

### 4. Projects (OEP_PFP) — Project Planning

| Aspect | Detail |
|--------|--------|
| **BSO Cube** | OEP_PFP |
| **ASO Cube** | OEP_PFPREP |
| **Purpose** | Project financial planning |
| **Project Types** | Internal, Capital, Contract |
| **Key Features** | Labor rate cards, resource allocation, milestone billing |
| **Dedicated Dimensions** | Project, Project Element, Resource, Task |

### 5. Strategic Modeling — Long-Range Forecasting

| Aspect | Detail |
|--------|--------|
| **Engine** | Native in-memory solver (not standard Essbase) |
| **Purpose** | 5–10 year strategic forecasting |
| **Key Features** | DCF analysis, M&A modeling, debt restructuring, Monte Carlo simulation |
| **Unique** | Uses financial model files (.alc), not dimensional cubes |

---

## Cross-Module Data Flow

```
                   +-------------------------------+
                   |       STRATEGIC MODELING       |
                   |   (Long-Range 5-10 Year Plan)  |
                   +-------------------------------+
                                   |
                   Strategic boundary targets flow down
                                   v
  +------------------------+    +------------------------+
  |   WORKFORCE (OEP_WFP)  |    |    CAPITAL (OEP_CPX)   |
  | Compensation & Salaries |    |  New CapEx & Tangibles  |
  | Headcount & FTE Tracking|    |  Depreciation & Leases  |
  +------------------------+    +------------------------+
                \                          /
                 \ Payroll & Benefits     / Capitalized Assets,
                  \ Expense via Smart   /  Depreciation Expense
                   \ Push / Data Maps  /
                    v                 v
  +------------------------------------------------------------+
  |                   FINANCIALS CORE (OEP_FS)                  |
  | Revenue Modeling (Driver, Trend, Direct)                    |
  | Operating Expenses (from Workforce & Capital)               |
  | Balance Sheet & Working Capital                             |
  | Cash Flow Statements (Direct & Indirect)                    |
  +------------------------------------------------------------+
                 ^
                 | Project Labor, Asset Transfers, Billing Revenue
  +------------------------+
  |    PROJECTS (OEP_PFP)   |
  | Capital Projects (Assets)|
  | Contract Projects (Billing)|
  +------------------------+
```

---

## Beginner Metaphor

| Module | Think of It As... |
|--------|------------------|
| **Financials** | The Executive Dashboard & Bank Account — sees total numbers |
| **Workforce** | The HR Department — tracks every person's pay and benefits |
| **Capital** | The Facilities Team — tracks buildings, machines, depreciation |
| **Projects** | The Engineering/Services Team — tracks billable hours and budgets |
| **Strategic Modeling** | The CEO's Long-Range Crystal Ball — models 5-10 year scenarios |

---

## 🧠 Self-Check Questions

1. **What are the 5 EPBCS modules and their cube prefixes?**
2. **What is the difference between Custom and EPBCS Modules applications?**
3. **How does data flow from Workforce into Financials?**
4. **Which module handles depreciation calculations?**
5. **What makes Strategic Modeling different from the other 4 modules?**

> **Teach-back prompt:** Explain to a CFO why their company should use EPBCS modules instead of building a custom application from scratch. Then trace a salary expense from the Workforce module to the P&L in Financials.

---

## Oracle Sources

- [Administering Planning Modules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/)
- [Working with Planning Modules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/ufpmu/)

