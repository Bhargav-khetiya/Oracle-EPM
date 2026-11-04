﻿# 💰 Financials Module — Complete Setup Guide
## Revenue, Expense, P&L, Balance Sheet, Cash Flow Planning

> **Module:** Financials  
> **Cube:** OEP_FS (BSO Hybrid) + OEP_REP (ASO Shared)  
> **Subscription:** Standard + Enterprise  
> **Enable:** During creation (Step 2) or post-creation (Application → Configure → Financials → Enable Features)

---

## 🎯 What Financials Module Provides

The Financials module is the **core module** for financial planning and budgeting. It provides pre-built content for:

| Area | Components |
|------|-----------|
| **Revenue Planning** | Revenue by product, service, geography with driver-based calculations |
| **Expense Planning** | OpEx budgeting by cost center with driver-based expense planning |
| **Income Statement** | Full P&L with automated rollups and variance analysis |
| **Balance Sheet** | Asset, liability, equity planning with auto-balancing |
| **Cash Flow** | Direct/indirect cash flow planning and forecasting |
| **Rolling Forecast** | Continuous rolling forecast beyond traditional budget cycles |

---

## 🔧 Setup Process

### Phase 1: Enable Features

**Navigation:** `Application → Configure → Financials → Enable Features`

#### Available Features to Enable:

| # | Feature | Description | Recommended |
|---|---------|-------------|-------------|
| 1 | **Revenue Planning** | Revenue line items and drivers | ✅ Yes (most implementations) |
| 2 | **Gross Margin** | COGS and gross margin analysis | ✅ Yes |
| 3 | **Operating Expenses** | OpEx planning by cost center | ✅ Yes |
| 4 | **Income Statement** | Full P&L structure | ✅ Yes |
| 5 | **Balance Sheet** | Balance sheet accounts | ✅ If needed |
| 6 | **Cash Flow** | Cash flow statement | ✅ If needed |
| 7 | **Rolling Forecast** | Rolling forecast periods | Optional |
| 8 | **Custom Drivers** | User-defined driver calculations | Optional |

> [!WARNING]
> **Once a feature is enabled, it CANNOT be disabled.** Enable only features you currently need. You can enable additional features later.

---

### Phase 2: Map/Rename Dimensions

When enabling features for the first time, you may be prompted to map dimensions:

```
┌──────────────────────────────────────────────────────────────────┐
│  Map Dimensions                                                   │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Map or rename the following dimensions for Financials:           │
│                                                                   │
│  Module Dimension     →  Your Dimension Name                      │
│  ──────────────────────────────────────                           │
│  Account              →  [Account          ]                      │
│  Entity               →  [Entity           ]                      │
│  Product              →  [Product          ]  (custom)            │
│  Line Item            →  [Revenue_Drivers  ]  (custom)            │
│                                                                   │
│  ☐ Use as new dimension                                           │
│  ○ Map to existing dimension                                      │
│                                                                   │
│  ┌────────┐  ┌────────────┐                                      │
│  │ Cancel │  │   Apply    │                                      │
│  └────────┘  └────────────┘                                      │
└──────────────────────────────────────────────────────────────────┘
```

| Option | Description |
|--------|-------------|
| **Use as new dimension** | Creates a brand new dimension with the module's default structure |
| **Map to existing dimension** | Maps to a dimension already in your app (if you have custom dims) |
| **Rename** | Change the dimension name to match your organization's terminology |

---

### Phase 3: Configure Financials Settings

**Navigation:** `Application → Configure → Financials`

#### Configuration Tasks:

| # | Task | Screen | Description |
|---|------|--------|-------------|
| 1 | **Planning and Forecast Preparation** | Configure → Financials | Set planning cycle parameters |
| 2 | **Chart of Accounts** | Configure → Financials → Accounts | Set up account hierarchy |
| 3 | **Entity Setup** | Configure → Financials → Entities | Configure organizational structure |
| 4 | **Exchange Rate Type** | Configure → Financials → Currency | Set rate types (Average/Ending) |
| 5 | **Custom Members** | Configure → Financials → Custom | Add custom dimension members |
| 6 | **Driver Configuration** | Configure → Financials → Drivers | Configure calculation drivers |

#### Planning and Forecast Preparation Screen:

```
┌──────────────────────────────────────────────────────────────────┐
│  Planning and Forecast Preparation                                │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Plan                                                             │
│  ────                                                             │
│  Plan Start Year:       [▼ FY24       ]                           │
│  Plan Start Period:     [▼ January    ]                           │
│  Plan End Year:         [▼ FY25       ]                           │
│  Plan End Period:       [▼ December   ]                           │
│  Granularity:           [▼ Monthly    ]                           │
│                                                                   │
│  Forecast                                                         │
│  ────────                                                         │
│  Forecast Start Year:   [▼ FY24       ]                           │
│  Forecast Start Period: [▼ July       ]                           │
│  Forecast End Year:     [▼ FY25       ]                           │
│  Forecast End Period:   [▼ June       ]                           │
│  Granularity:           [▼ Monthly    ]                           │
│                                                                   │
│  ┌────────┐  ┌────────────┐                                      │
│  │ Cancel │  │   Save     │                                      │
│  └────────┘  └────────────┘                                      │
└──────────────────────────────────────────────────────────────────┘
```

**Granularity Options:**
| Option | Description |
|--------|-------------|
| Monthly | Plan/forecast at monthly level |
| Quarterly | Plan/forecast at quarterly level |
| Yearly | Plan/forecast at yearly level (summary only) |

---

### Phase 4: Account Setup

#### Pre-built Account Hierarchy (Financials Module):

```
OFS_Total Account
├── OFS_Net Revenue
│   ├── OFS_Gross Revenue
│   │   ├── OFS_Product Revenue
│   │   ├── OFS_Service Revenue
│   │   └── OFS_Other Revenue
│   └── OFS_Discounts & Allowances
├── OFS_Cost of Goods Sold
│   ├── OFS_Direct Materials
│   ├── OFS_Direct Labor
│   └── OFS_Manufacturing Overhead
├── OFS_Gross Margin
├── OFS_Operating Expenses
│   ├── OFS_Salaries & Wages
│   ├── OFS_Employee Benefits
│   ├── OFS_Travel & Entertainment
│   ├── OFS_Marketing & Advertising
│   ├── OFS_Rent & Facilities
│   ├── OFS_Depreciation & Amortization
│   ├── OFS_Professional Services
│   └── OFS_Other Operating Expense
├── OFS_Operating Income (EBIT)
├── OFS_Interest Expense
├── OFS_Pre-Tax Income
├── OFS_Income Tax
└── OFS_Net Income
```

---

### Phase 5: Refresh Database

**Navigation:** `Application → Configure → Actions → Refresh Database`

> [!IMPORTANT]
> After ANY configuration changes, you MUST refresh the database. This rebuilds the Essbase outline and recalculates aggregations.

```
┌──────────────────────────────────────────────┐
│  Refresh Database                             │
│                                               │
│  Select cubes to refresh:                     │
│  ☑ OEP_FS (Financials)                       │
│  ☑ OEP_REP (Reporting)                       │
│                                               │
│  Options:                                     │
│  ☑ Create/Refresh Essbase outline             │
│  ☐ Full restructure                           │
│                                               │
│  [Cancel]  [Refresh]                          │
└──────────────────────────────────────────────┘
```

---

## 📝 Pre-Built Forms (Financials)

| Form | Purpose | Key Dimensions |
|------|---------|---------------|
| Revenue Input | Enter revenue data by product/service | Account × Period × Entity |
| Expense Budget | Enter operating expenses by department | Account × Period × Entity |
| P&L Summary | View income statement | Account × Period (read-only) |
| Balance Sheet | Enter/view balance sheet | Account × Period × Entity |
| Cash Flow | Cash flow planning | Account × Period × Entity |
| Variance Analysis | Budget vs Actual comparison | Account × Scenario × Period |
| Driver Dashboard | KPI and driver entry | Drivers × Period × Entity |

---

## 🧮 Pre-Built Business Rules (Financials)

| Rule | Type | Description | Triggered By |
|------|------|-------------|-------------|
| OFS_Revenue_Calc | Calculation | Calculates revenue from drivers | Revenue forms |
| OFS_Expense_Rollup | Aggregation | Rolls up expense categories | Expense forms |
| OFS_GM_Calc | Calculation | Calculates gross margin | Revenue/COGS forms |
| OFS_OpIncome_Calc | Calculation | Calculates operating income | P&L forms |
| OFS_NetIncome_Calc | Calculation | Calculates net income | P&L forms |
| OFS_Spread | Data movement | Spreads annual values to months | Budget forms |
| OFS_Copy_Actual | Data movement | Copies actual to forecast seed | Admin action |
| OFS_Currency_Trans | Currency | Translates currencies | System/admin |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the technical difference between Driver-Based Revenue Planning and Direct Entry in Financials—
**Answer:**
- **Driver-Based:** Calculates revenue dynamically using business drivers: $\text{Revenue} = \text{Volume} \times \text{Average Selling Price (ASP)}$. Planners enter drivers, and the system executes Calc Manager rules to compute gross revenue and discounts.
- **Direct Entry:** Planners directly input currency numbers into account intersections.
Both approaches can coexist within the same application by configuring the Plan Element dimension (OFS_Direct Input vs OFS_Calculated).

### Q2: How does Rolling Forecast work in Financials, and how do you update the forecast horizon without rebuilding forms—
**Answer:** Rolling Forecast leverages **Rolling Forecast Ranges** configured in Application → Configure → Financials → Rolling Forecast Setup. You define the number of historical actual periods (e.g. trailing 12 months) and future forecast periods (e.g. forward 18 months). By updating the **Current Period** substitution variable (&CurMo), forms automatically roll forward dynamically, shifting the boundary between Actuals and Forecast without any manual form modifications.

### Q3: Can custom corporate expense accounts be created outside the seeded OFS_Operating Expenses hierarchy—
**Answer:** Yes. You can add custom parent and child accounts. However, best practice is to place custom expense accounts under the seeded parent OFS_Operating Expenses (or map them via shared members). Placing accounts outside the seeded tree prevents them from rolling into the out-of-the-box Income Statement forms, KPI ratios, and cash flow integration rules.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Workforce Module](./03_Workforce_Module_Master_Guide.md) |
| **← Previous** | [Modules Overview](./01_Modules_Architecture_Overview.md) |
| **← Back to Index** | [Master Index](../../00_MASTER_INDEX.md) |
