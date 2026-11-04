﻿# 💼 Sales Planning — Complete Master Setup Guide
## Quota Planning, Territory Management, Pipeline Forecasting & Revenue Integration

> **Module:** Sales Planning  
> **Target Cubes:** `OEP_STP` (Sales Target Planning) + `OEP_FS` (Financials Integration)  
> **Subscriptions Supported:** 🔒 Enterprise Cloud EPM Subscription Only  
> **Integration Ecosystem:** Automatically feeds top-line revenue commitments into Financials P&L (`OEP_FS`) and headcount targets into Workforce (`OEP_WFP`)

---

## 🎯 Architecture Overview & Value Proposition

**Sales Planning** aligns executive sales quotas with ground-level territory capacity. Instead of disconnected spreadsheets between sales leadership and FP&A, Sales Planning provides continuous, real-time quota allocation, pipeline analytics, and commission modeling:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      SALES PLANNING ARCHITECTURE                            │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 🎯 SALES OPERATIONS & TERRITORIES    │ 🔗 FINANCIAL PLANNING INTEGRATION    │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Executive Top-Down Quota Targets   │ ➔ Synchronizes Final Quota Targets   │
│ • Territory Hierarchies & Bandwidth  │    into Financials P&L Revenue       │
│ • Bottom-Up Sales Rep Commitments    │ ➔ Feeds Commission Expense Accruals  │
│ • Pipeline Probability Adjustments   │    into Operating Expenses (OPEX)    │
│ • Incentive Compensation Estimation  │ ➔ Aligns Sales Capacity with         │
│ • Predictive AI Attainment Forecasts │    Workforce Headcount Requisitions  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 📋 Enable Features: Complete Configuration Screen

Navigate to **Application → Configure → Sales Planning → Enable Features**:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Enable Features: Sales Planning                                         [ Enable ]  [ Cancel ]   │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                  │
│ 🎯 Quota Planning:                                                                               │
│   ☑ Enable Quota Setting & Distribution                                                          │
│       🔘 Top-Down Quota Allocation (Cascading targets from Executive to Territories)             │
│       🔘 Bottom-Up Quota Building (Aggregating territory commitments to Region)                 │
│       🔘 Hybrid / Waterfall Reconciliation                                                       │
│                                                                                                  │
│ 🗺️ Territory & Capacity Planning:                                                                │
│   ☑ Enable Territory Planning                                                                    │
│       ☑ Account Segmentation (Tier 1 Enterprise, Mid-Market, SMB)                               │
│       ☑ Geographic & Industry Vertical Mapping                                                    │
│       ☑ Sales Rep Headcount Capacity Modeling                                                    │
│                                                                                                  │
│ 📈 Advanced Sales Forecasting & Pipeline:                                                         │
│   ☑ Enable Pipeline Analytics                                                                    │
│       ☑ Probability-Weighted Pipeline Integration                                                │
│       ☑ CRM Lead & Opportunity Ingestion (Oracle CX Sales, Salesforce)                           │
│       ☑ Auto-Predict & Machine Learning Forecast Benchmarking                                    │
│                                                                                                  │
│ 💰 Incentive Compensation & Commissions:                                                         │
│   ☑ Enable Commission & Incentive Modeling                                                       │
│       ☑ Tiered Accelerator Bands                                                                 │
│       ☑ Attainment Multipliers                                                                   │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Quota Distribution Methodologies & Seasonality

Sales Planning provides three core mechanisms to push quotas from corporate goals down to quota-carrying representatives:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       QUOTA ALLOCATION METHODOLOGY                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. TOP-DOWN ALLOCATION:                                                     │
│    Executive Target ➔ Regional VP ➔ Area Director ➔ Territory Sales Rep     │
│    (Allocated via historical contribution %, TAM market size, or flat spread)│
│                                                                             │
│ 2. BOTTOM-UP AGGREGATION:                                                   │
│    Rep Commit ➔ Territory Roll-up ➔ District Roll-up ➔ Corporate Total      │
│                                                                             │
│ 3. SPREAD & SEASONALITY ENGINE:                                             │
│    • 4-4-5 / 5-4-4 / Even Period Spread                                     │
│    • Historical Seasonality (Calculated from prior 3 years of actuals)       │
│    • Manual Seasonal Weights (e.g., Q1: 15%, Q2: 20%, Q3: 25%, Q4: 40%)     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🗺️ Territory Configuration & Pipeline Stage Probabilities

Territories define coverage models. Pipeline deals are discounted using mathematical probability weighting:

| Stage Name | Seeded Win Probability % | Forecast Category | Description |
|:---|:---:|:---:|:---|
| **Prospect / Lead** | 10% | Pipeline | Initial engagement; unqualified lead |
| **Qualified Lead** | 25% | Pipeline | BANT (Budget, Authority, Need, Timeline) qualified |
| **Discovery / Solution** | 40% | Pipeline | Solution presented; RFP in review |
| **Proposal / Quote** | 60% | Best Case | Formal commercial proposal delivered |
| **Negotiation / Legal** | 80% | Commit | Redlines in progress; procurement review |
| **Verbal Commit** | 95% | Commit | Final verbal approval pending signature |
| **Closed Won** | 100% | Closed | Executed contract booked |
| **Closed Lost** | 0% | Omitted | Deal disqualified or lost to competitor |

$$\text{Weighted Pipeline Revenue} = \sum (\text{Deal Value} \times \text{Stage Probability})$$

---

## 🏗️ Pre-Built Sales Planning Dimensions

Instantiated automatically inside the `OEP_STP` cube:

| Dimension | Role in Cube | Seeded Members & Structure |
|:---|:---|:---|
| **Territory** | Hierarchical sales coverage | `Total Sales` ➔ `Americas`, `EMEA`, `APAC` ➔ `Territory_East`, `Territory_West` |
| **Sales Rep** | Quota-carrying resources | `All Reps` ➔ `Named Reps` (`Rep_001`, `Rep_002`), `Unassigned / TBH Reps` |
| **Sales Account** | Customer accounts & tiers | `Strategic Accounts`, `Enterprise Accounts`, `Mid-Market`, `Government` |
| **Sales Measure** | Quota metrics & drivers | `Base Quota`, `Adjusted Quota`, `Attainment %`, `Pipeline Amount`, `Weighted Pipeline`, `Commission Expense` |
| **Product** | Product catalog / offerings | Sourced from standard application Product dimension |

---

## 📝 Pre-Built Data Forms & User Workflows

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│ Sales Planning User Navigation Flow                                                     │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────────────┐   ┌─────────────────────────┐   ┌────────────────────────┐ │
│  │ 🎯 Quota Setting        │   │ 🗺️ Territory Assignment │   │ 📈 Pipeline Analytics  │ │
│  │ Executive target spread,│   │ Assign reps to geos and │   │ Opportunity staging,   │ │
│  │ waterfall adjustment    │   │ customer tier bands     │   │ probability weighting  │ │
│  └─────────────────────────┘   └─────────────────────────┘   └────────────────────────┘ │
│                                                                                         │
│  ┌─────────────────────────┐   ┌─────────────────────────┐   ┌────────────────────────┐ │
│  │ 🏆 Quota Attainment     │   │ 💰 Commission Modeling  │   │ 🚀 Push to Financials  │ │
│  │ Actual vs Quota gap,    │   │ Tiered accelerator math,│   │ Smart Push to          │ │
│  │ leaderboard rankings    │   │ commission accruals     │   │ Financials (OEP_FS)    │ │
│  └─────────────────────────┘   └─────────────────────────┘   └────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Essential Sales Planning Forms:
- **`Quota Allocation Grid`:** Top-down form where regional managers distribute annualized targets across sales reps.
- **`Territory Capacity Dashboard`:** Evaluates if a territory has adequate sales rep coverage to achieve quota.
- **`Sales Attainment Scorecard`:** Tracks closed-won revenue against assigned quotas in real time.
- **`Commission Estimator Form`:** Calculates payout accruals based on baseline commission rates (e.g., 5%) and attainment accelerators (e.g., 150% above quota earns 2x commission rate).

---

## 🔄 Financials P&L Integration (Smart Push)

1. Open **Application → Data Maps**.
2. Run **`Sales to Financials`** Data Map:
   - Source Cube: `OEP_STP`
   - Target Cube: `OEP_FS`
3. Synchronizes:
   - `OEP_STP.Committed Revenue` ➔ `OEP_FS.Gross Revenue (P&L)`
   - `OEP_STP.Commission Expense` ➔ `OEP_FS.Sales Commissions (OPEX P&L)`
4. Aligns sales projections with general ledger financial statements without manual exporting.

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: How does Sales Planning handle sales territory realignments without corrupting historical rep quota performance—
**Answer:** Sales Planning manages territories through effective dating and historical version snapshots. When an account or zip code is moved from Territory East to Territory Central, historical closed actuals remain locked under the prior territory hierarchy, while forward-looking quotas and pipeline opportunities re-aggregate under the new alignment.

### Q2: What is the difference between Top-Down Quota Allocation and Bottom-Up Rep Commitment—
**Answer:**
- **Top-Down:** Executive leadership assigns a macro quota target (e.g. ) to a sales VP, who waterfalls it down across directors and managers using historical seasonality or market growth drivers.
- **Bottom-Up:** Individual account executives submit their commit and stretch numbers based on deal pipeline. The module reconciles variances between top-down targets and bottom-up commitments.

### Q3: How does pipeline probability weighting link CRM opportunities with financial revenue forecasts—
**Answer:** Through Data Integration or Oracle CX connections, Sales Planning ingests CRM deal stages. Each deal stage has an assigned win probability (e.g. *Stage 3 Proposal = 50%*, *Stage 4 Negotiation = 80%*). The module calculates Probability-Weighted Pipeline ( \times \text{Deal Amount}$) and pushes the forecast to Financials to seed revenue projections.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [06_Strategic_Modeling.md](./06_Strategic_Modeling_Master_Guide.md) |
| **Modules Overview** | [01_Modules_Overview.md](./01_Modules_Architecture_Overview.md) |
| **Next Section →** | [FreeForm/01_FreeForm_Overview.md](../04_FreeForm_Application/01_FreeForm_Architecture_and_Use_Cases.md) |
| **Master Index** | [00_MASTER_INDEX.md](../../00_MASTER_INDEX.md) |
