﻿# 📊 Projects Module — Complete Master Setup Guide
## Project Financial Planning, Resource Allocation, Billing & Cross-Module Integration

> **Module:** Projects  
> **Target Cubes:** `OEP_PFP` (BSO Hybrid) + `OEP_REP` (ASO Reporting)  
> **Subscriptions Supported:** Enterprise & Standard Cloud EPM  
> **Integration Ecosystem:** Tri-directional integration with Workforce (labor rates & hours), Capital (capitalized project CapEx), and Financials (project revenue & operational expense)

---

## 🎯 Architecture Overview & Value Proposition

The **Projects** module bridges the gap between operational project management and financial planning. It enables organizations to plan revenue, expense, and resource demand across internal R&D initiatives, capital construction projects, and client-billable contracts:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PROJECTS MODULE ARCHITECTURE                          │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 📐 OPERATIONAL RESOURCE PLANNING     │ 🔗 FINANCIAL INTEGRATION (SMART PUSH)│
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Labor Demands (Employees & Jobs)   │ ➔ Labor Costs from Workforce (OEP_WFP)│
│ • Materials, Supplies & Equipment    │ ➔ Capitalized Costs ➔ Capital(OEP_CAP)│
│ • Contract Billing & Milestone Sched │ ➔ Billable Revenue ➔ Financials(P&L) │
│ • Project Health, ROI & Margin KPIs  │ ➔ Direct Expenses ➔ Financials(P&L)  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 📋 Enable Features: Complete Configuration Screen

Navigate to **Application → Configure → Projects → Enable Features**:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Enable Features: Projects                                               [ Enable ]  [ Cancel ]   │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                  │
│ 📁 Project Types:                                                                                │
│   ☑ Contract Projects (Billable Client Engagements)                                             │
│       ☑ Time and Materials Billing                                                               │
│       ☑ Fixed Price Milestone Billing                                                            │
│       ☑ Cost-Plus Contract Billing                                                               │
│                                                                                                  │
│   ☑ Capital Projects (Internal Capital Construction & Software Development)                      │
│       ☑ Direct Capitalization                                                                    │
│       ☑ CIP (Construction-in-Progress) Account Tracking                                          │
│                                                                                                  │
│   ☑ Indirect Projects (Internal Overhead, Corporate Initiatives & Training)                     │
│       ☑ Department Overhead Allocation                                                           │
│                                                                                                  │
│ 👥 Resource Allocation Planning:                                                                 │
│   ☑ Labor Resources (Employees, Generic Job Codes, External Contractors)                        │
│   ☑ Material & Supplies (Standard Bill of Materials / Non-Labor Items)                          │
│   ☑ Equipment & Machinery Usage (Hourly / Daily Rental Rates)                                    │
│                                                                                                  │
│ 🎯 Project Benefit Planning:                                                                     │
│   ☑ Financial Benefits (Projected Revenue Growth, OPEX Cost Reduction)                           │
│   ☑ Non-Financial Benefits (Strategic Alignment, Customer Satisfaction, Regulatory Compliance)  │
│                                                                                                  │
│ 🔗 External Integration:                                                                         │
│   ☑ Integration with Oracle Fusion Cloud Project Management (PPM Cloud Sync)                     │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> **Schema Permanence:**  
> Enabling project types injects permanent project dimensions and calculation rule templates into `OEP_PFP`. Plan your project accounting taxonomy before confirming enablement.

---

## 💼 Project Types & Revenue Recognition Matrix

Projects supports three distinct accounting models:

| Project Type | Billing & Accounting Model | Revenue Recognition Method | Integration Target |
|:---|:---|:---|:---|
| **Contract (Billable)** | Client engagements where time, materials, and fixed milestones are invoiced. | • **As Incurred:** Recognized when work occurs.<br>• **Percentage of Completion (PoC):** $\frac{\text{Costs to Date}}{\text{Total Estimated Costs}}$.<br>• **Milestone:** Recognized upon milestone sign-off. | Pushes billable revenue and gross margin to **Financials P&L (`OEP_FS`)**. |
| **Capital (CapEx)** | Multi-period investments (constructing buildings, building internal software). | Costs accumulate in **CIP (Construction-in-Progress)** balance sheet accounts; zero P&L hit during build phase. | Pushes accumulated capital costs to **Capital (`OEP_CAP`)** as new assets on in-service date. |
| **Indirect (Internal)** | Internal departmental projects (compliance audits, marketing campaigns, training). | Operational expense recorded as incurred; optionally allocated to cost pools. | Pushes operational expense lines to **Financials P&L (`OEP_FS`)**. |

---

## 👥 Resource Allocation Mechanics: Labor, Equipment & Materials

Resource demand drives project cost accuracy:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     PROJECT COST AGGREGATION ENGINE                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. LABOR COST = [ Assigned Hours ] × [ Fully Burdened Hourly Labor Rate ]   │
│    (Hourly rates sourced automatically from Workforce OEP_WFP module)       │
│                                                                             │
│ 2. EQUIPMENT COST = [ Machine Run Hours ] × [ Standard Equipment Rate ]     │
│                                                                             │
│ 3. MATERIAL COST = [ Bill of Materials Quantity ] × [ Standard Unit Cost ]  │
│                                                                             │
│ 4. DIRECT OVERHEAD = [ Travel & Expenses ] + [ Subcontractor Invoices ]     │
│                                                                             │
│ ➔ TOTAL PROJECT COST = Labor + Equipment + Materials + Overhead             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Pre-Built Projects Dimensions

Instantiated automatically inside the `OEP_PFP` cube:

| Dimension | Role in Cube | Hierarchy & Key Members |
|:---|:---|:---|
| **Project** | Core entity dimension | `All Projects` ➔ `Contract Projects`, `Capital Projects`, `Indirect Projects` ➔ Individual Project IDs |
| **Project Element** | Line item categorization | `Labor`, `Equipment`, `Materials`, `Overhead`, `Revenue`, `Margin` |
| **Resource Class** | Personnel and asset classification | `Labor - Employees`, `Labor - Contractors`, `Equipment`, `Materials` |
| **Stages / Tasks** | Work Breakdown Structure (WBS) | `Initiation`, `Planning`, `Execution`, `Milestone 1`, `Milestone 2`, `Closeout` |
| **Vendor** | Third-party billing tracking | Subcontractors and material suppliers |

---

## 📝 Pre-Built Data Forms & User Workflows

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│ Projects User Navigation Flow                                                           │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────────────┐   ┌─────────────────────────┐   ┌────────────────────────┐ │
│  │ 📋 Project Details      │   │ 👥 Resource Assignment  │   │ 💰 Project Billing     │ │
│  │ Project start/end dates,│   │ Assign employees, jobs, │   │ Setup milestone fees,  │ │
│  │ budget approval status  │   │ hours, and equipment    │   │ T&M billing schedules  │ │
│  └─────────────────────────┘   └─────────────────────────┘   └────────────────────────┘ │
│                                                                                         │
│  ┌─────────────────────────┐   ┌─────────────────────────┐   ┌────────────────────────┐ │
│  │ 📊 Profitability KPIs   │   │ 🎯 Benefit Realization  │   │ 🚀 Multi-Module Push   │ │
│  │ Burn rate, margin %,    │   │ Track cost savings and  │   │ Smart Push to          │ │
│  │ budget vs actuals       │   │ strategic scorecards    │   │ Financials and Capital │ │
│  └─────────────────────────┘   └─────────────────────────┘   └────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Key Forms Reference:
- **`Project Summary Dashboard`:** Executive scorecard displaying contract value, incurred cost, revenue recognized, and net margin percentage.
- **`Resource Planning Grid`:** Matrix where project managers assign named employees or generic job titles against project tasks across monthly periods.
- **`Capital Project Capitalization Form`:** Allows finance managers to mark a capital project as **"Complete"**, triggering automated transfer of CIP balances to Capital fixed assets.

---

## 🔄 Tri-Directional Cross-Module Integration

Projects is uniquely designed to communicate with three separate business cubes:

```
                  ┌──────────────────────┐
                  │ 👥 Workforce         │
                  │ (OEP_WFP)            │
                  └──────────┬───────────┘
                             │ Pull: Hourly Labor Rates & Headcount
                             ▼
┌────────────────────────────────────────────────────────┐
│                   📊 Projects (OEP_PFP)                │
└────────────┬──────────────────────────────┬────────────┘
             │ Push: Capitalized CapEx      │ Push: Project Revenue & OPEX
             ▼                              ▼
┌─────────────────────────┐   ┌──────────────────────────┐
│ 🏗️ Capital (OEP_CAP)    │   │ 💰 Financials (OEP_FS)   │
└─────────────────────────┘   └──────────────────────────┘
```

1. **Workforce ➔ Projects:** Workforce exports burdened employee and contractor labor rates to Projects, eliminating manual salary data re-entry.
2. **Projects ➔ Capital:** When Capital Projects complete, a Smart Push job transfers accumulated capitalized construction costs into `OEP_CAP` as new asset lines.
3. **Projects ➔ Financials:** Billable revenues, subcontractor expenses, and internal project overhead are synchronized directly into the corporate General Ledger P&L statement in `OEP_FS`.

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What are the core architectural differences between Contract, Capital, and Indirect projects—
**Answer:**
- **Contract Projects:** Customer-facing billable projects that generate revenue based on Time & Materials (T&M) or Fixed Price milestones.
- **Capital Projects:** Internal investment projects (e.g. constructing a manufacturing plant) where all project costs accumulate as Work-in-Progress (WIP) and monetize upon project completion into fixed assets in the Capital module.
- **Indirect Projects:** Internal overhead projects (e.g. IT software upgrades) whose costs flow directly to operating expenses in Financials.

### Q2: How does the Projects module synchronize resource allocations from Workforce and assets from Capital—
**Answer:** Projects utilizes the **Tri-Sync** pipeline:
1. Workforce planners allocate named employees to project codes (OEP_WFP $\to$ OEP_PJC).
2. Capital planners link capital asset purchase requests to project numbers (OEP_CPX $\to$ OEP_PJC).
3. Projects aggregates labor, asset, and direct expense lines to compute total project budget.
4. An automated Smart Push pushes project summaries into corporate Financials (OEP_FS).

### Q3: What happens if a project milestone billing date is pushed back by 3 months—
**Answer:** The project calculation rule recalculates project revenue cash flow schedules. When the data map Projects to Financials executes, it automatically shifts the revenue recognition and accounts receivable balances 3 months forward in the corporate P&L and Balance Sheet.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [04_Capital_Module.md](./04_Capital_Module_Master_Guide.md) |
| **Next →** | [06_Strategic_Modeling.md](./06_Strategic_Modeling_Master_Guide.md) |
| **Modules Overview** | [01_Modules_Overview.md](./01_Modules_Architecture_Overview.md) |
| **Master Index** | [00_MASTER_INDEX.md](../../00_MASTER_INDEX.md) |
