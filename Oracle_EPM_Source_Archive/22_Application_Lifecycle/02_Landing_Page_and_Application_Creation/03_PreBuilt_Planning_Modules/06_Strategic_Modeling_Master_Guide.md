# 📈 Strategic Modeling — Complete Setup Guide
## Long-Range Financial Modeling, Scenario Analysis & Valuation

> **Module:** Strategic Modeling  
> **Architecture:** Separate file-based model engine (not standard Essbase cubes)  
> **Subscription:** 🔒 Enterprise Only  
> **Integration:** Financials (strategic targets feed into operational plans)

---

## 🎯 What Strategic Modeling Provides

| Area | Description |
|------|-------------|
| **Financial Models** | Complete financial statement modeling (P&L, BS, Cash Flow) |
| **Scenario Analysis** | What-if scenarios with instant recalculation |
| **Valuation** | DCF, NPV, IRR, WACC analysis |
| **M&A Modeling** | Merger, acquisition, divestiture impact analysis |
| **Debt Scheduling** | Debt structure, refinancing, covenant compliance |
| **Long-Range Planning** | 5-20+ year strategic financial forecasts |
| **Sensitivity Analysis** | Monte Carlo simulation and sensitivity tables |

---

## 🏗️ Architecture Differences

Strategic Modeling has a **fundamentally different architecture** from other Planning modules:

| Aspect | Standard Modules | Strategic Modeling |
|--------|-----------------|-------------------|
| Storage | Essbase BSO/ASO cubes | File-based models (.alc files) |
| Interface | Standard Planning forms | Dedicated SM interface |
| Calculations | Calc Manager rules | Built-in financial logic engine |
| Scenarios | Scenario dimension member | Model-level scenarios |
| Dimensions | Shared Planning dimensions | Model-specific accounts |
| Concurrency | Multi-user forms | Model-level locking |

---

## 📋 Enable Process

### During Application Creation (Step 2)
- Check the **Strategic Modeling** checkbox
- Requires Enterprise subscription

### Post-Creation Enable
**Navigation:** `Application → Configure → Strategic Modeling → Enable Features`

| Feature | Description |
|---------|-------------|
| **Standard Models** | Pre-built financial statement models |
| **Custom Models** | Create models from scratch |
| **Scenario Manager** | Multi-scenario comparison tools |
| **Funding Options** | Debt and equity financing modeling |
| **Valuation** | DCF and comparable analysis |

---

## ⚙️ Model Configuration

### Pre-Built Model Templates

| Template | Description | Key Outputs |
|----------|-------------|-------------|
| **Standard P&L** | Income statement model | Revenue growth, margins, net income |
| **Balance Sheet** | Full balance sheet model | Assets, liabilities, equity, ratios |
| **Cash Flow** | Cash flow from operations, investing, financing | Free cash flow, ending cash |
| **3-Statement** | Linked P&L + BS + CF model | Complete financial picture |
| **Valuation** | DCF-based valuation | Enterprise value, equity value |
| **LBO** | Leveraged buyout model | Returns, debt paydown, exit value |

### Model Setup Screens

#### Account Configuration
```
┌──────────────────────────────────────────────────────────────────┐
│  Strategic Model — Account Setup                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Revenue Accounts                                                 │
│  ├── [✓] Product Revenue        Type: [Revenue    ▼]             │
│  ├── [✓] Service Revenue        Type: [Revenue    ▼]             │
│  └── [✓] Other Revenue          Type: [Revenue    ▼]             │
│                                                                   │
│  Expense Accounts                                                 │
│  ├── [✓] Cost of Goods Sold     Type: [Expense    ▼]             │
│  ├── [✓] Operating Expenses     Type: [Expense    ▼]             │
│  └── [✓] Interest Expense       Type: [Expense    ▼]             │
│                                                                   │
│  Balance Sheet Accounts                                           │
│  ├── [✓] Cash & Equivalents     Type: [Asset      ▼]             │
│  ├── [✓] Accounts Receivable    Type: [Asset      ▼]             │
│  ├── [✓] Total Debt             Type: [Liability  ▼]             │
│  └── [✓] Shareholders Equity    Type: [Equity     ▼]             │
│                                                                   │
│  [Cancel]  [Save]                                                 │
└──────────────────────────────────────────────────────────────────┘
```

#### Scenario Configuration
| Scenario | Description | Use Case |
|----------|-------------|----------|
| Base Case | Expected/most likely outcome | Primary planning scenario |
| Upside | Optimistic growth scenario | Best-case planning |
| Downside | Pessimistic/conservative | Worst-case risk assessment |
| Management | Board/management targets | Target setting |
| Custom | User-defined scenarios | Specific what-if analysis |

---

## 📊 Key KPIs and Outputs

| KPI | Calculation | Category |
|-----|-------------|----------|
| Revenue CAGR | Compound annual growth rate | Growth |
| EBITDA Margin | EBITDA / Revenue | Profitability |
| Net Income Margin | Net Income / Revenue | Profitability |
| ROE | Net Income / Equity | Returns |
| ROIC | NOPAT / Invested Capital | Returns |
| Debt/EBITDA | Total Debt / EBITDA | Leverage |
| Interest Coverage | EBITDA / Interest | Leverage |
| Free Cash Flow | CFO - CapEx | Cash |
| Enterprise Value | Equity + Debt - Cash | Valuation |
| EV/EBITDA | Enterprise Value / EBITDA | Valuation |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: Why are Strategic Modeling models stored as .alc files rather than standard Essbase cubes?
**Answer:** Strategic Modeling uses a dedicated financial modeling engine derived from Hyperion Strategic Finance (HSF). It operates on a comprehensive 3-statement linked mathematical matrix (incorporating simultaneous circular balance sheet balancing, debt revolvers, and tax loss carryforwards) that requires a different calculation engine than Essbase multidimensional block storage.

### Q2: How do you push long-range 10-year strategic targets down into operational 1-year annual budgets in OEP_FS?
**Answer:** In Application â†’ Data Maps, configure a Data Map from Strategic Modeling to the Financials cube (OEP_FS). Map strategic model accounts to operational accounts (e.g. Strategic Model Product Revenue $\to$ Financials OFS_Product Revenue). Planners run this map to seed top-down budget targets for regional operational planners.

### Q3: What is the Debt Scheduler feature, and how does it optimize corporate capital structure?
**Answer:** The Debt Scheduler models senior debt, subordinated notes, credit facilities, and equity financing. When the model projects cash deficits, it automatically draws on revolving credit lines based on predefined covenant limits. When excess cash is generated, it executes automated debt paydown schedules.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Sales Planning](./07_Sales_Planning_Master_Guide.md) |
| **← Previous** | [Projects Module](./05_Projects_Module_Master_Guide.md) |
| **← Modules Overview** | [Modules Overview](./01_Modules_Architecture_Overview.md) |
