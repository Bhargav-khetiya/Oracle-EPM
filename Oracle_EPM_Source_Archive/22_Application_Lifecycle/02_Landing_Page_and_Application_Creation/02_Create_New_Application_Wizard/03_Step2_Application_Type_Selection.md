﻿# 🚀 Step 2: Application Type & Module Selection
## Choosing Between Planning Types and Enabling Modules

> **Wizard Step:** 2 of 5  
> **Screen Title:** "Setup" or "Select Features"  
> **Navigation:** `START → Step 1 (General) → Step 2 (Type/Modules)`  
> **Previous:** Step 1 — General Properties  
> **Next:** Step 3 — Calendar Setup

---

## 📸 Screen Layout (Planning Type Selected)

When "Planning" is selected as Application Type in Step 1, this screen appears:

```
┌──────────────────────────────────────────────────────────────────┐
│  Create Application                                    Step 2/5  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Set Up                                                           │
│  ──────                                                           │
│                                                                   │
│  Select the features to enable for your application:              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │                                                          │     │
│  │  ☐  Financials                                           │     │
│  │     Revenue, expense, income statement, balance sheet,   │     │
│  │     cash flow planning                                   │     │
│  │                                                          │     │
│  │  ☐  Workforce                                            │     │
│  │     Headcount, compensation, benefits planning           │     │
│  │                                                          │     │
│  │  ☐  Capital                                              │     │
│  │     Capital asset planning and lifecycle management      │     │
│  │                                                          │     │
│  │  ☐  Projects                                             │     │
│  │     Project financial planning and resource allocation   │     │
│  │                                                          │     │
│  │  ☐  Strategic Modeling          (Enterprise only)        │     │
│  │     Long-range financial modeling and scenario analysis  │     │
│  │                                                          │     │
│  │  ☐  Sales Planning              (Enterprise only)        │     │
│  │     Revenue planning, quota setting, sales forecasting  │     │
│  │                                                          │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
│  Note: You can enable additional features later from              │
│  Application > Configure > Enable Features                        │
│                                                                   │
│  ┌────────┐  ┌────────┐  ┌────────┐                             │
│  │ Cancel │  │  Back  │  │  Next  │                             │
│  └────────┘  └────────┘  └────────┘                             │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📝 Module Selection — Detailed Reference

### Module 1: Financials ☐

| Property | Details |
|----------|---------|
| **Checkbox Label** | "Financials" |
| **Subscription** | Standard + Enterprise |
| **Can Enable Later** | ✅ Yes |
| **Can Disable After Enabling** | ❌ No — permanent once enabled |
| **Pre-built Content** | Forms, dashboards, business rules, KPIs |

**What Financials Provides:**
| Component | Description |
|-----------|-------------|
| Revenue Planning | Revenue line items with driver-based calculations |
| Expense Planning | Operating expense budgeting by cost center |
| Income Statement | Full P&L statement with auto-aggregation |
| Balance Sheet | Balance sheet accounts and reconciliation |
| Cash Flow | Cash flow forecasting and management |
| Rolling Forecast | Continuous rolling forecast capability |

**Cubes Created When Enabled:**
| Cube | Type | Purpose |
|------|------|---------|
| OEP_FS | BSO (Hybrid) | Financial Statement planning data |
| OEP_REP | ASO | Reporting and aggregation |

**Dimensions Auto-Created:**
| Dimension | Type | Key Members |
|-----------|------|-------------|
| Account | Account | OFS_Revenue, OFS_COGS, OFS_OpEx, OFS_NetIncome |
| Entity | Entity | No Entity (you add your own) |
| Scenario | Scenario | OEP_Plan, OEP_Forecast, OEP_Actual |
| Version | Version | OEP_Working, OEP_Final |
| Period | Period | BegBalance, Jan–Dec, Q1–Q4, YearTotal |
| Year | Year | Based on your calendar settings |
| Currency | Currency | Based on your currency settings |
| Product | Custom (optional) | User-defined |
| Line Item | Custom | Revenue/Expense line items |

---

### Module 2: Workforce ☐

| Property | Details |
|----------|---------|
| **Checkbox Label** | "Workforce" |
| **Subscription** | Standard + Enterprise |
| **Can Enable Later** | ✅ Yes |
| **Can Disable After Enabling** | ❌ No |
| **Pre-built Content** | Forms, dashboards, rules, compensation templates |

**What Workforce Provides:**
| Component | Description |
|-----------|-------------|
| Headcount Planning | Plan positions and FTE by department |
| Compensation Planning | Salary, bonus, merit increase planning |
| Benefits Planning | Health, retirement, other benefits |
| Tax Planning | Employer-side payroll taxes |
| New Hire Planning | Planning for new positions and hires |
| Transfer/Termination | Employee movement and attrition |

**Planning Approaches:**
| Approach | Description | Best For |
|----------|-------------|----------|
| **Position-based** | Plan by individual position/employee | Detailed, small-medium organizations |
| **Job-based** | Plan by job code/role with headcount | High-level, large organizations |
| **Hybrid** | Combination of both approaches | Complex organizations |

**Cubes Created:**
| Cube | Type | Purpose |
|------|------|---------|
| OEP_WFP | BSO (Hybrid) | Workforce planning input |
| OEP_REP | ASO | Reporting (shared with Financials) |

**Key Dimensions Added:**
| Dimension | Purpose |
|-----------|---------|
| Employee | Individual employees or positions |
| Job | Job codes / roles |
| Compensation Element | Salary, bonus, benefits, taxes |
| Position | Organizational positions |

---

### Module 3: Capital ☐

| Property | Details |
|----------|---------|
| **Checkbox Label** | "Capital" |
| **Subscription** | Standard + Enterprise |
| **Can Enable Later** | ✅ Yes |
| **Can Disable After Enabling** | ❌ No |
| **Pre-built Content** | Forms, approval workflows, asset templates |

**What Capital Provides:**
| Component | Description |
|-----------|-------------|
| Asset Request | Request and justify new capital assets |
| Asset Lifecycle | Track assets through full lifecycle |
| Depreciation Planning | Calculate depreciation across methods |
| Disposal/Retirement | Plan for asset disposal |
| Transfer/Impairment | Asset transfers and impairment tracking |
| Impact Analysis | Impact on cash flow, P&L, and balance sheet |

**Depreciation Methods Supported:**
| Method | Description |
|--------|-------------|
| Straight Line | Equal depreciation over useful life |
| Declining Balance | Accelerated depreciation |
| Double Declining | Double the straight-line rate |
| Sum of Years Digits | Accelerated based on remaining life |
| Units of Production | Based on actual usage/output |

**Cubes Created:**
| Cube | Type | Purpose |
|------|------|---------|
| OEP_CAP | BSO (Hybrid) | Capital planning input |
| OEP_REP | ASO | Reporting (shared) |

---

### Module 4: Projects ☐

| Property | Details |
|----------|---------|
| **Checkbox Label** | "Projects" |
| **Subscription** | Standard + Enterprise |
| **Can Enable Later** | ✅ Yes |
| **Can Disable After Enabling** | ❌ No |
| **Pre-built Content** | Forms, project templates, resource allocation |

**What Projects Provides:**
| Component | Description |
|-----------|-------------|
| Project Planning | Plan project revenue and expenses |
| Resource Planning | Allocate resources (labor, material, equipment) |
| Project Types | Contract, Capital, Indirect projects |
| Integration | Sync with Oracle Fusion Project Management |
| Billing | Project billing and revenue recognition |

**Project Types:**
| Type | Description | Revenue Recognition |
|------|-------------|-------------------|
| Contract | Client-facing projects | Yes — billable |
| Capital | Internal capital projects | No — capitalized |
| Indirect | Overhead/internal projects | No — expensed |

**Cubes Created:**
| Cube | Type | Purpose |
|------|------|---------|
| OEP_PFP | BSO (Hybrid) | Project financial planning |
| OEP_REP | ASO | Reporting (shared) |

**Key Dimensions Added:**
| Dimension | Purpose |
|-----------|---------|
| Project | Individual projects |
| Resource Class | Labor, Material, Equipment |
| Project Type | Contract, Capital, Indirect |

---

### Module 5: Strategic Modeling ☐ *(Enterprise Only)*

| Property | Details |
|----------|---------|
| **Checkbox Label** | "Strategic Modeling" |
| **Subscription** | 🔒 Enterprise Only |
| **Can Enable Later** | ✅ Yes |
| **Can Disable After Enabling** | ❌ No |
| **Pre-built Content** | Financial models, scenario templates |

**What Strategic Modeling Provides:**
| Component | Description |
|-----------|-------------|
| Financial Models | Balance sheet, P&L, cash flow modeling |
| Scenario Analysis | What-if scenarios with instant results |
| Valuation | DCF, NPV, IRR analysis |
| M&A Modeling | Merger and acquisition impact analysis |
| Debt Scheduling | Debt structure and refinancing scenarios |
| Long-Range Planning | 5-10+ year strategic financial plans |

> [!NOTE]
> Strategic Modeling uses a different architecture than standard Planning modules. It creates its own model structures that are linked to but separate from the standard Planning cubes.

---

### Module 6: Sales Planning ☐ *(Enterprise Only)*

| Property | Details |
|----------|---------|
| **Checkbox Label** | "Sales Planning" |
| **Subscription** | 🔒 Enterprise Only |
| **Can Enable Later** | ✅ Yes |
| **Can Disable After Enabling** | ❌ No |
| **Pre-built Content** | Quota templates, territory forms, pipeline dashboards |

**What Sales Planning Provides:**
| Component | Description |
|-----------|-------------|
| Quota Planning | Set and distribute sales quotas |
| Territory Planning | Define and manage sales territories |
| Account Segmentation | Segment accounts by size, industry |
| Pipeline Analysis | Sales pipeline tracking and forecasting |
| Sales Forecasting | Revenue forecasting from sales data |
| Incentive Compensation | Commission and bonus planning |

---

## 🔘 Selection Rules

| Rule | Description |
|------|-------------|
| **Minimum Selection** | You can select **zero** modules (creates a "Custom/blank" Planning app) |
| **Maximum Selection** | You can select **all** modules simultaneously |
| **Module Independence** | Most modules can be enabled independently of others |
| **Shared Infrastructure** | All modules share the same Reporting (ASO) cube |
| **Integration Points** | Workforce ↔ Projects (shared labor data), Capital ↔ Financials (depreciation impacts) |

### Common Module Combinations:
| Combination | Use Case |
|-------------|----------|
| Financials only | Basic financial planning and budgeting |
| Financials + Workforce | Financial planning with headcount integration |
| Financials + Capital | Financial planning with asset management |
| Financials + Workforce + Capital | Comprehensive operational planning |
| All modules | Full enterprise-wide planning platform |
| None (Custom) | Fully custom application design |

---

## 🔘 Buttons on This Screen

| Button | Location | Action |
|--------|----------|--------|
| **Cancel** | Bottom-left | Cancels wizard, returns to Landing Page |
| **Back** | Bottom-center | Returns to Step 1 (General Properties) |
| **Next** | Bottom-right | Proceeds to Step 3 (Calendar Setup) |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Can an application created as "Standard Planning" be upgraded to "Enterprise Planning Modules" later—
**Answer:** Yes. If your organization holds an Enterprise EPM subscription, you can progressively enable pre-built business modules (Financials, Workforce, Capital, Projects, Strategic Modeling) post-creation via Application → Configure → Enable Features.

### Q2: Can an application created with Planning Modules be converted to FreeForm, or vice versa—
**Answer:** No. Standard Planning / Modules enforce the 6 mandatory dimensions (Account, Entity, Period, Year, Scenario, Version). FreeForm is schema-free Essbase without mandatory dimensions. This structural boundary is permanent and cannot be crossed post-creation without an environment reset.

### Q3: What is the architectural impact of selecting "FreeForm" on Step 2—
**Answer:** FreeForm skips the standard Calendar and Currency setup steps entirely. Instead, the wizard prompts you to define custom cubes (BSO/ASO) and allows you to import an existing Essbase .otl outline file directly from on-premises systems.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Step 3: Calendar Setup](./04_Step3_Calendar_Setup.md) |
| **← Previous** | [Step 1: General Properties](./02_Step1_General_Properties.md) |
| **Modules Detail →** | [Modules Overview](../03_PreBuilt_Planning_Modules/01_Modules_Architecture_Overview.md) |
| **FreeForm Path →** | [FreeForm Overview](../04_FreeForm_Application/01_FreeForm_Architecture_and_Use_Cases.md) |
